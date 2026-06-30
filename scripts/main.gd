class_name Main extends Node2D
## Top-level controller. Orchestrates the state machine, screen-shake, VFX,
## bullet spawning, and powerup drops. Entities communicate via signals only.

const HIT_STOP_DURATION := 0.04

@onready var _world: Node2D = $Play
@onready var _player: Player = $Play/Player
@onready var _bullets: Node2D = $Play/Bullets
@onready var _enemy_bullets: Node2D = $Play/EnemyBullets
@onready var _enemies: Node2D = $Play/Enemies
@onready var _explosions: Node2D = $Play/Explosions
@onready var _powerups: Node2D = $Play/Powerups
@onready var _popups: Node2D = $Play/Popups
@onready var _wave_mgr: WaveManager = $Play/WaveManager

@onready var _hud: HUD = $HUD
@onready var _menu: MainMenu = $MainMenu
@onready var _gameover: GameOverScreen = $GameOverScreen

@onready var _sfx_explosion: AudioStreamPlayer = $SFX/Explosion
@onready var _sfx_hit: AudioStreamPlayer = $SFX/Hit
@onready var _sfx_powerup: AudioStreamPlayer = $SFX/Powerup
@onready var _sfx_gameover: AudioStreamPlayer = $SFX/GameOver

var _shake_tween: Tween
var _hit_stop_timer: Timer


func _ready() -> void:
	_hit_stop_timer = Timer.new()
	_hit_stop_timer.one_shot = true
	_hit_stop_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hit_stop_timer)
	_connect_signals()
	_show_menu()


func _connect_signals() -> void:
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.player_hit.connect(_on_player_hit)
	SignalBus.powerup_collected.connect(_on_powerup)
	SignalBus.shake_requested.connect(_shake)
	SignalBus.state_changed.connect(_on_state_changed)
	_menu.start_requested.connect(_start_game)
	_gameover.restart_requested.connect(_start_game)
	_gameover.menu_requested.connect(_show_menu)
	_player.fired.connect(_on_player_fired)
	_wave_mgr.enemy_spawned.connect(_on_enemy_spawned)
	_wave_mgr.enemy_fired.connect(_on_enemy_fired)
	_wave_mgr.wave_cleared.connect(_on_wave_cleared)


# --- State transitions ---

func _start_game() -> void:
	_clear_world()
	Game.start_run()
	_player.reset()
	_player.visible = true
	_player.set_process(true)
	_player.set_process_input(true)
	_menu.disappear()
	_gameover.disappear()
	_wave_mgr.start(_player)


func _show_menu() -> void:
	_wave_mgr.stop()
	_clear_world()
	_player.visible = false
	_player.set_process(false)
	_player.set_process_input(false)
	_gameover.disappear()
	_menu.appear()
	Game.set_state(Game.State.MENU)


func _on_state_changed(state: int) -> void:
	if state == Game.State.GAME_OVER:
		_wave_mgr.stop()
		_player.visible = false
		_play(_sfx_gameover)
		_gameover.appear()


# --- Signal handlers ---

func _on_enemy_spawned(enemy: Enemy) -> void:
	_enemies.add_child(enemy)


func _on_player_fired(pos: Vector2, dir: Vector2) -> void:
	var b := preload("res://scenes/bullet.tscn").instantiate()
	b.launch(dir)
	b.global_position = pos
	_bullets.add_child(b)


func _on_enemy_fired(pos: Vector2, dir: Vector2) -> void:
	var b := preload("res://scenes/enemy_bullet.tscn").instantiate()
	b.launch(dir, Cfg.ENEMY_BULLET_SPEED)
	b.global_position = pos
	_enemy_bullets.add_child(b)


func _on_enemy_killed(pos: Vector2, score_value: int) -> void:
	_spawn_explosion(pos, false)
	_spawn_score_popup(pos, score_value)
	_play(_sfx_explosion)
	_do_hit_stop()
	if randf() < Cfg.POWERUP_DROP_CHANCE:
		_spawn_powerup(pos)


func _on_wave_cleared() -> void:
	SignalBus.banner_requested.emit("Wave Cleared!")


func _on_player_hit() -> void:
	_play(_sfx_hit)


func _on_player_died() -> void:
	_spawn_explosion(_player.global_position, true)
	_shake(Cfg.SHAKE_DEATH_AMOUNT, Cfg.SHAKE_DEATH_DURATION)
	_do_hit_stop(0.12)


func _on_powerup(_type: int) -> void:
	_play(_sfx_powerup)


# --- VFX helpers ---

func _spawn_explosion(pos: Vector2, big: bool) -> void:
	var ex: Explosion = preload("res://scenes/explosion.tscn").instantiate()
	ex.global_position = pos
	if big:
		ex.scale = Vector2(1.8, 1.8)
	_explosions.add_child(ex)


func _spawn_score_popup(pos: Vector2, value: int) -> void:
	var label := Label.new()
	label.text = "+%d" % value
	# Clamp popup position to stay on-screen
	var vp := Responsive.get_viewport_rect().size
	var px: float = clampf(pos.x + randf_range(-20, 20), 20.0, vp.x - 60.0)
	var py: float = clampf(pos.y - 10, 20.0, vp.y - 40.0)
	label.position = Vector2(px, py)
	label.z_index = 10
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Palette.POPUP_COLOR)
	_popups.add_child(label)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position:y", label.position.y - 60, 0.8)
	t.tween_property(label, "modulate:a", 0.0, 0.8)
	t.finished.connect(label.queue_free)


func _spawn_powerup(pos: Vector2) -> void:
	var types: Array = [
		Player.PowerType.RAPID_FIRE,
		Player.PowerType.TRIPLE_SHOT,
		Player.PowerType.SHIELD,
	]
	var t: int = types.pick_random()
	var p: Powerup = preload("res://scenes/powerup.tscn").instantiate()
	p.setup(t, Player.powerup_texture(t))
	p.global_position = pos
	_powerups.add_child(p)


func _shake(amount: float, duration: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := 6
	for i in steps:
		var decay := 1.0 - float(i) / float(steps)
		_shake_tween.tween_property(
			_world, "position",
			Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * decay,
			duration / float(steps))
	_shake_tween.tween_property(_world, "position", Vector2.ZERO, duration / float(steps))


func _do_hit_stop(duration: float = HIT_STOP_DURATION) -> void:
	get_tree().paused = true
	_hit_stop_timer.start(duration)
	_hit_stop_timer.timeout.connect(func(): get_tree().paused = false, CONNECT_ONE_SHOT)


func _play(stream: AudioStreamPlayer) -> void:
	if not Game.mute:
		stream.play()


func _clear_world() -> void:
	for node in [_enemies, _explosions, _powerups, _popups, _bullets, _enemy_bullets]:
		for c in node.get_children():
			c.queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				Game.toggle_mute()
			KEY_ESCAPE:
				if Game.get_state() == Game.State.PLAYING:
					_show_menu()
			KEY_ENTER, KEY_KP_ENTER:
				if Game.get_state() in [Game.State.MENU, Game.State.GAME_OVER]:
					_start_game()
