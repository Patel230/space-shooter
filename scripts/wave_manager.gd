class_name WaveManager extends Node
## Drives enemy spawning in escalating waves. Emits signals so the main
## controller can react without tight coupling. Fully data-driven via Cfg.

signal wave_cleared
signal enemy_spawned(enemy: Enemy)
signal enemy_fired(pos: Vector2, dir: Vector2)

@onready var _timer: Timer = $SpawnTimer
@onready var _pause_timer: Timer = $PauseTimer

var _wave: int = 0
var _to_spawn: int = 0
var _alive: int = 0
var _base_interval: float = Cfg.WAVE_SPAWN_INTERVAL
var _player: Node2D = null
var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var _active: bool = false


func _ready() -> void:
	_timer.timeout.connect(_on_spawn_tick)
	_pause_timer.timeout.connect(_on_pause_end)


func start(player: Node2D) -> void:
	_player = player
	_wave = 0
	_active = true
	_begin_next_wave()


func stop() -> void:
	_active = false
	_timer.stop()
	_pause_timer.stop()


func register_enemy() -> void:
	_alive += 1


func unregister_enemy() -> void:
	_alive -= 1
	_check_wave_cleared()


func _begin_next_wave() -> void:
	_wave += 1
	Game.set_wave(_wave)
	_to_spawn = Cfg.WAVE_BASE_SIZE + _wave * Cfg.WAVE_SIZE_PER_WAVE
	_alive = 0
	_base_interval = maxf(Cfg.WAVE_SPAWN_INTERVAL_MIN,
			Cfg.WAVE_SPAWN_INTERVAL - _wave * Cfg.WAVE_SPAWN_INTERVAL_DECAY)
	_timer.wait_time = _base_interval
	_timer.start()
	var galaxy_name: String = GalaxyBackground.GALAXIES[(_wave - 1) % GalaxyBackground.GALAXIES.size()].name
	var wave_text := "Wave %d - %s" % [_wave, galaxy_name]
	var color: Color = Palette.WAVE_BANNER_COLORS[(_wave - 1) % Palette.WAVE_BANNER_COLORS.size()]
	if _wave > 1:
		SignalBus.shake_requested.emit(5.0, 0.25)
	SignalBus.banner_requested.emit(wave_text, color)


func _on_spawn_tick() -> void:
	if _to_spawn <= 0:
		_timer.stop()
		return
	_spawn_enemy()
	_to_spawn -= 1
	_timer.wait_time = randf_range(_base_interval * 0.6, _base_interval * 1.3)
	_timer.start()


func _spawn_enemy() -> void:
	var e: Enemy = _enemy_scene.instantiate()
	e.position = Vector2(Responsive.random_x(), -70.0)
	var hp := _roll_hp()
	var speed := Cfg.ENEMY_SPEED_BASE + _wave * Cfg.ENEMY_SPEED_PER_WAVE + randf_range(-20.0, 30.0)
	var interval := maxf(1.2, Cfg.ENEMY_SHOOT_INTERVAL - _wave * 0.15)
	e.setup(speed, hp, interval, _player)
	e.died.connect(_on_enemy_died)
	e.escaped.connect(unregister_enemy)
	e.fired.connect(_on_enemy_fired)
	register_enemy()
	enemy_spawned.emit(e)


func _on_enemy_died(pos: Vector2) -> void:
	unregister_enemy()
	SignalBus.enemy_killed.emit(pos, Cfg.ENEMY_SCORE + Game.wave)


func _on_enemy_fired(pos: Vector2, dir: Vector2) -> void:
	enemy_fired.emit(pos, dir)


func _roll_hp() -> int:
	if _wave >= 6 and randf() < 0.15:
		return 3
	if _wave >= 3 and randf() < 0.35:
		return 2
	return 1


func _check_wave_cleared() -> void:
	if not _active or _to_spawn > 0 or _alive > 0:
		return
	wave_cleared.emit()
	_pause_timer.start(Cfg.WAVE_INTERMISSION)


func _on_pause_end() -> void:
	if _active:
		_begin_next_wave()
