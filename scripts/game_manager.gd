extends Node2D

signal game_over_requested

var player_scene    := preload("res://scenes/player.tscn")
var enemy_scene     := preload("res://scenes/enemy.tscn")
var explosion_scene := preload("res://scenes/explosion.tscn")
var _powerup_scene  := preload("res://scenes/powerup.tscn")
var _meteor_scene   := preload("res://scenes/meteor.tscn")

var player_instance: Area2D = null
var spawn_timer    := 0.0
var spawn_interval := 1.5
var screen_size    := Vector2()
# Gameplay is confined to a centred column of the design width; _col_x is its
# left edge in screen space (0 unless the window is wider than the design).
const PLAY_WIDTH := 720.0
var _col_x: float = 0.0

# Wave / progression
var enemies_killed: int = 0
var current_wave: int   = 1
var _wave_pause_timer: float = 0.0
const WAVE_SIZE       := 10
const WAVE_PAUSE_TIME := 3.0

# Meteor spawning
var _meteor_timer: float = 0.0
const METEOR_BASE_INTERVAL := 9.0

# HUD extras
var _life_icons: Array[Sprite2D] = []
var _combo_label: Label = null
var _wave_label: Label = null
var _wave_announce_tween: Tween = null

@onready var player_container := $PlayerContainer
@onready var enemy_container  := $Enemies
@onready var score_label      := $HUD/ScoreValue
@onready var pause_overlay    := $PauseOverlay
@onready var resume_button    := $PauseOverlay/ButtonResume/ButtonResume

var sfx_kill: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_gameover: AudioStreamPlayer
var sfx_powerup: AudioStreamPlayer
var bullet_pool: BulletPool = null
var _meteor_container: Node2D = null
var _shake_tween: Tween = null


func _ready() -> void:
	screen_size = get_viewport_rect().size
	$HUD/ScoreIcon.texture = preload("res://art/kenney_space-shooter-remastered/PNG/Effects/star1.png")
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	resume_button.pressed.connect(_unpause)
	_setup_audio()
	_setup_bullet_pool()
	_setup_meteor_container()
	_setup_hud_extras()


func _on_viewport_resized() -> void:
	# With the "expand" aspect the viewport fills the window. Gameplay is kept in
	# a centred 720-wide column; _col_x is the column's left edge in screen space.
	screen_size = get_viewport_rect().size
	_col_x = max(0.0, (screen_size.x - PLAY_WIDTH) / 2.0)
	# Centre the HUD (score left / lives right) within the column.
	$HUD.position.x = _col_x
	# Pause overlay dims the whole window, but its text/button stay column-centred.
	pause_overlay.position = Vector2.ZERO
	pause_overlay.size = screen_size
	($PauseOverlay/Label as Control).position.x = 160.0 + _col_x
	($PauseOverlay/ButtonResume as Node2D).position.x = _col_x
	# Keep the player inside the new bounds; it re-clamps each frame, but snap it
	# now so it never appears off-screen after a resize.
	if is_instance_valid(player_instance):
		var max_y: float = min(player_instance.position.y, screen_size.y - 100)
		player_instance.position.y = max_y


func _setup_audio() -> void:
	sfx_kill    = _make_player(preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_zap.ogg"))
	sfx_hit     = _make_player(preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_shieldDown.ogg"))
	sfx_gameover = _make_player(preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_lose.ogg"))
	sfx_powerup = _make_player(preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_shieldUp.ogg"))


func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p


func _setup_bullet_pool() -> void:
	bullet_pool = BulletPool.new()
	add_child(bullet_pool)


func _setup_meteor_container() -> void:
	_meteor_container = Node2D.new()
	_meteor_container.name = "Meteors"
	add_child(_meteor_container)


func _setup_hud_extras() -> void:
	# Hide original single-icon lives display
	$HUD/LivesIcon.visible = false
	$HUD/LivesValue.visible = false

	# Create 3 individual life icons (33x26 px each, scale=1)
	var life_tex := preload("res://art/kenney_space-shooter-remastered/PNG/UI/playerLife1_blue.png")
	for i in 3:
		var icon := Sprite2D.new()
		icon.texture = life_tex
		icon.position = Vector2(612 + i * 36, 30)
		$HUD.add_child(icon)
		_life_icons.append(icon)

	# Combo label — upper center of HUD
	_combo_label = Label.new()
	_combo_label.position = Vector2(240, 6)
	_combo_label.size = Vector2(240, 40)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1, 1.0))
	_combo_label.add_theme_font_size_override("font_size", 22)
	_combo_label.visible = false
	$HUD.add_child(_combo_label)

	# Wave announcement — mid-screen, starts transparent
	_wave_label = Label.new()
	_wave_label.position = Vector2(0, 520)
	_wave_label.size = Vector2(720, 100)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 52)
	_wave_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	add_child(_wave_label)


# ─── Main loop ───────────────────────────────────────────────────────────────

func start_game() -> void:
	_cleanup_all()
	_reset_state()
	_spawn_player()
	_update_hud()


func _process(delta: float) -> void:
	if global.state != global.GameState.PLAYING:
		return
	_spawn_enemies(delta)
	_spawn_meteors(delta)


func _reset_state() -> void:
	spawn_timer        = 0.0
	spawn_interval     = 1.5
	enemies_killed     = 0
	current_wave       = 1
	_wave_pause_timer  = 0.0
	_meteor_timer      = 0.0
	global.score  = 0
	global.lives  = 3
	global.combo  = 1
	global.state  = global.GameState.PLAYING
	_hide_wave_label()


func _cleanup_all() -> void:
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
		player_instance = null
	for child in enemy_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
		child.queue_free()
	if _meteor_container:
		for child in _meteor_container.get_children():
			child.queue_free()
	for pu in get_tree().get_nodes_in_group("powerups"):
		pu.queue_free()
	if bullet_pool:
		bullet_pool.deactivate_all()
	for bullet in get_tree().get_nodes_in_group("enemy_bullets"):
		bullet.queue_free()


# ─── Spawning ────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	player_instance = player_scene.instantiate()
	player_instance.bullet_pool = bullet_pool
	player_container.add_child(player_instance)
	player_instance.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	player_instance.hit.connect(_on_player_hit)
	player_instance.died.connect(_on_player_died)


func _spawn_enemies(delta: float) -> void:
	if _wave_pause_timer > 0:
		_wave_pause_timer -= delta
		return
	spawn_timer += delta
	if spawn_timer < spawn_interval:
		return
	spawn_timer = 0.0
	spawn_interval = max(0.4, spawn_interval - 0.02)

	var enemy := enemy_scene.instantiate()
	enemy_container.add_child(enemy)
	enemy.position = Vector2(randf_range(_col_x + 60, _col_x + PLAY_WIDTH - 60), -50)
	enemy.killed.connect(_on_enemy_killed)


func _spawn_meteors(delta: float) -> void:
	_meteor_timer += delta
	var interval: float = max(4.5, METEOR_BASE_INTERVAL - (current_wave - 1) * 0.5)
	if _meteor_timer < interval:
		return
	_meteor_timer = 0.0
	var meteor := _meteor_scene.instantiate()
	_meteor_container.add_child(meteor)
	meteor.position = Vector2(randf_range(_col_x + 50, _col_x + PLAY_WIDTH - 50), -80)
	meteor.killed.connect(_on_meteor_killed)


func _spawn_powerup(pos: Vector2) -> void:
	var roll := randf()
	var pu := _powerup_scene.instantiate() as PowerUp
	if roll < 0.20:
		pu.type = PowerUp.Type.SHIELD
	elif roll < 0.55:
		pu.type = PowerUp.Type.RAPID_FIRE
	else:
		pu.type = PowerUp.Type.DOUBLE_SHOT
	pu.position = pos
	pu.collected.connect(_on_powerup_collected)
	add_child(pu)


func _spawn_explosion(pos: Vector2) -> void:
	var explosion := explosion_scene.instantiate()
	explosion.position = pos
	add_child(explosion)


# ─── Event handlers ──────────────────────────────────────────────────────────

func _on_enemy_killed(score_value: int, pos: Vector2) -> void:
	global.score += score_value * global.combo
	global.combo  = min(global.combo + 1, global.max_combo)
	enemies_killed += 1
	_update_hud()
	_spawn_explosion(pos)
	_shake_screen(4.0, 0.15)
	if not global.mute:
		sfx_kill.play()
	if randf() < 0.30:
		_spawn_powerup(pos)
	if enemies_killed > 0 and enemies_killed % WAVE_SIZE == 0:
		_advance_wave()


func _on_meteor_killed(score_value: int, pos: Vector2) -> void:
	global.score += score_value * global.combo
	_update_hud()
	_spawn_explosion(pos)
	_shake_screen(3.0, 0.1)
	if not global.mute:
		sfx_kill.play()


func _on_powerup_collected(type: int) -> void:
	if player_instance and is_instance_valid(player_instance):
		player_instance.apply_powerup(type)
	_update_hud()
	if not global.mute:
		sfx_powerup.play()


func _on_player_hit() -> void:
	global.combo = 1
	_update_hud()
	_shake_screen(8.0, 0.3)
	if not global.mute:
		sfx_hit.play()


func _on_player_died() -> void:
	global.state = global.GameState.GAME_OVER
	global.check_high_score()
	_update_hud()
	_hide_wave_label()
	_shake_screen(12.0, 0.5)
	if not global.mute:
		sfx_gameover.play()
	_cleanup_all()
	game_over_requested.emit()


# ─── Wave progression ─────────────────────────────────────────────────────────

func _advance_wave() -> void:
	current_wave     += 1
	global.score     += current_wave * 200
	_wave_pause_timer = WAVE_PAUSE_TIME
	_update_hud()
	_show_wave_announcement()


func _hide_wave_label() -> void:
	if _wave_announce_tween and _wave_announce_tween.is_running():
		_wave_announce_tween.kill()
	if _wave_label:
		_wave_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))


func _show_wave_announcement() -> void:
	if not _wave_label:
		return
	_wave_label.text = "WAVE  %d" % current_wave
	if _wave_announce_tween and _wave_announce_tween.is_running():
		_wave_announce_tween.kill()
	_wave_announce_tween = create_tween()
	_wave_announce_tween.tween_method(
		func(a: float) -> void: _wave_label.add_theme_color_override("font_color", Color(1, 1, 1, a)),
		0.0, 1.0, 0.4
	)
	_wave_announce_tween.tween_interval(1.8)
	_wave_announce_tween.tween_method(
		func(a: float) -> void: _wave_label.add_theme_color_override("font_color", Color(1, 1, 1, a)),
		1.0, 0.0, 0.6
	)


# ─── HUD ─────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	score_label.text = str(global.score)
	for i in _life_icons.size():
		_life_icons[i].visible = i < global.lives
	if global.combo > 1:
		_combo_label.visible = true
		_combo_label.text    = "x%d COMBO" % global.combo
	else:
		_combo_label.visible = false


# ─── Screen shake ─────────────────────────────────────────────────────────────

func _shake_screen(intensity: float, duration: float) -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
		get_parent().position = Vector2.ZERO
	var target := get_parent()
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	_shake_tween.tween_property(target, "position", offset, duration * 0.3)
	_shake_tween.tween_property(target, "position", Vector2.ZERO, duration * 0.7)


# ─── Pause ───────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_toggle_pause()


func _toggle_pause() -> void:
	if global.state != global.GameState.PLAYING:
		return
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_overlay.visible = paused


func _unpause() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
