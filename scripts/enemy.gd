class_name Enemy extends Area2D
## Enemy ship with configurable behavior: drifter (sine + aimed), diver (dive +
## no shoot), weaver (zig-zag + spread).
## Emits died/escaped/fired so external systems own lifecycle + bullet spawning.

enum Behavior { DRIFTER, DIVER, WEAVER }

signal died(pos: Vector2)
signal escaped
signal fired(pos: Vector2, dir: Vector2)

const ENEMY_TEXTURES: Array[Texture2D] = [
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png"),
]

const DIVER_TEXTURES: Array[Texture2D] = [
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack2.png"),
]

const WEAVER_TEXTURES: Array[Texture2D] = [
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack4.png"),
]

@export var max_hp: int = 1
@export var speed: float = Cfg.ENEMY_SPEED_BASE
@export var shoot_interval: float = Cfg.ENEMY_SHOOT_INTERVAL

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _shoot_timer: Timer = $ShootTimer

var hp: int = 1
var _dead: bool = false
var _player_ref: Node2D = null
var _flash_tween: Tween
var _rest_color: Color = Color.WHITE
var behavior: Behavior = Behavior.DRIFTER
# Diver tracks the player X it locked onto at spawn.
var _dive_target_x: float = 0.0
# Weaver oscillation state.
var _weave_time: float = 0.0
var _weave_dir: float = 1.0


func setup(p_speed: float, p_hp: int, p_interval: float, player: Node2D) -> void:
	speed = p_speed
	max_hp = p_hp
	hp = p_hp
	shoot_interval = p_interval
	_player_ref = player
	# Assign behavior based on wave progression (set externally via set_behavior).
	behavior = Behavior.DRIFTER


func set_behavior(b: Behavior) -> void:
	behavior = b


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	# Pick texture based on behavior
	match behavior:
		Behavior.DIVER:
			_sprite.texture = DIVER_TEXTURES.pick_random()
			_dive_target_x = _player_ref.global_position.x if is_instance_valid(_player_ref) else position.x
			_shoot_timer.stop()
		Behavior.WEAVER:
			_sprite.texture = WEAVER_TEXTURES.pick_random()
		_:
			_sprite.texture = ENEMY_TEXTURES.pick_random()
	if behavior != Behavior.DIVER:
		_shoot_timer.wait_time = randf_range(shoot_interval * 0.5, shoot_interval * 1.5)
		_shoot_timer.timeout.connect(_on_shoot)
		_shoot_timer.start()
	# Color tint based on HP
	if max_hp >= 3:
		_rest_color = Color(1.1, 0.8, 0.8)
	elif max_hp == 2:
		_rest_color = Color(1.0, 1.0, 0.9)
	_sprite.modulate = _rest_color
	# Entrance animation: scale-in + fade-in with rotation
	_sprite.scale = Vector2(0.1, 0.1)
	_sprite.modulate.a = 0.0
	_sprite.rotation = randf_range(-PI, PI)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_sprite, "scale", Vector2(1.5, 1.5), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "modulate:a", 1.0, 0.25)
	t.tween_property(_sprite, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if behavior == Behavior.DIVER:
		# Diver also lunges horizontally toward target during entrance.
		t.parallel().tween_property(self, "position:x", _dive_target_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	if _dead:
		return
	match behavior:
		Behavior.DRIFTER:
			_drift_process(delta)
		Behavior.DIVER:
			_dive_process(delta)
		Behavior.WEAVER:
			_weave_process(delta)


func _drift_process(delta: float) -> void:
	position.y += speed * delta
	position.x += sin(position.y * Cfg.ENEMY_DRIFT_FREQUENCY) * Cfg.ENEMY_DRIFT_AMPLITUDE * delta
	_sprite.rotation = sin(position.y * Cfg.ENEMY_DRIFT_FREQUENCY) * Cfg.ENEMY_DRIFT_TILT
	_check_escape()


func _dive_process(delta: float) -> void:
	# Diver: fast vertical, slight tracking toward player
	position.y += speed * 1.5 * delta
	if is_instance_valid(_player_ref):
		_dive_target_x = move_toward(_dive_target_x, _player_ref.global_position.x, 60.0 * delta)
	position.x = move_toward(position.x, _dive_target_x, 120.0 * delta)
	_sprite.rotation = 0.0
	_check_escape()


func _weave_process(delta: float) -> void:
	# Weaver: fast, zig-zag horizontal
	position.y += speed * 1.2 * delta
	_weave_time += delta * 3.0
	position.x += sin(_weave_time) * 200.0 * delta
	var vp_w := Responsive.get_viewport_rect().size.x
	position.x = clampf(position.x, 30.0, vp_w - 30.0)
	_sprite.rotation = cos(_weave_time) * 0.4
	_check_escape()


func _check_escape() -> void:
	if position.y > Responsive.get_viewport_rect().size.y + Cfg.OFFSCREEN_MARGIN:
		_dead = true
		escaped.emit()
		queue_free()


func take_damage(amount: int) -> void:
	if _dead or amount <= 0:
		return
	hp -= amount
	_flash()
	if hp <= 0:
		_dead = true
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		died.emit(global_position)
		queue_free()


func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	var flash_color := Color(3.0, 3.0, 3.0, 1.0) if hp > 1 else Color(3.5, 2.0, 1.5, 1.0)
	_sprite.modulate = flash_color
	_sprite.scale = Vector2(1.65, 1.65)
	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	_flash_tween.tween_property(_sprite, "modulate", _rest_color, 0.12)
	_flash_tween.tween_property(_sprite, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shoot() -> void:
	if _dead:
		return
	if not is_instance_valid(_player_ref):
		return
	_shoot_timer.wait_time = randf_range(shoot_interval * 0.5, shoot_interval * 1.5)
	match behavior:
		Behavior.WEAVER:
			# Spread shot: three bullets in a fan.
			var dir := (_player_ref.global_position - global_position).normalized()
			fired.emit(_muzzle.global_position, dir)
			fired.emit(_muzzle.global_position, dir.rotated(0.15))
			fired.emit(_muzzle.global_position, dir.rotated(-0.15))
		_:
			var dir := (_player_ref.global_position - global_position).normalized()
			fired.emit(_muzzle.global_position, dir)
