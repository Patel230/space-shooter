class_name Enemy extends Area2D
## Enemy ship with HP, sine drift, and aimed shooting at the player.
## Emits died/escaped/fired so external systems own lifecycle + bullet spawning.

signal died(pos: Vector2)
signal escaped
signal fired(pos: Vector2, dir: Vector2)

const ENEMY_TEXTURES: Array = [
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png"),
]

@export var max_hp: int = 1
@export var speed: float = Cfg.ENEMY_SPEED_BASE
@export var shoot_interval: float = Cfg.ENEMY_SHOOT_INTERVAL

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _shoot_timer: Timer = $ShootTimer

var hp: int = 1
var _player_ref: Node2D = null
var _flash_tween: Tween


func setup(p_speed: float, p_hp: int, p_interval: float, player: Node2D) -> void:
	speed = p_speed
	max_hp = p_hp
	hp = p_hp
	shoot_interval = p_interval
	_player_ref = player


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_sprite.texture = ENEMY_TEXTURES.pick_random()
	# Color tint based on HP
	if max_hp >= 3:
		_sprite.modulate = Color(1.1, 0.8, 0.8)
	elif max_hp == 2:
		_sprite.modulate = Color(1.0, 1.0, 0.9)
	_shoot_timer.wait_time = randf_range(shoot_interval * 0.5, shoot_interval * 1.5)
	_shoot_timer.timeout.connect(_on_shoot)
	_shoot_timer.start()
	# Entrance animation: scale-in + fade-in with rotation
	_sprite.scale = Vector2(0.1, 0.1)
	_sprite.modulate.a = 0.0
	_sprite.rotation = randf_range(-PI, PI)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_sprite, "scale", Vector2(1.5, 1.5), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "modulate:a", 1.0, 0.25)
	t.tween_property(_sprite, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	position.y += speed * delta
	position.x += sin(position.y * 0.012) * Cfg.ENEMY_DRIFT_AMPLITUDE * delta
	# Tilt sprite based on horizontal drift direction
	_sprite.rotation = sin(position.y * 0.012) * 0.3
	if position.y > Responsive.get_viewport_rect().size.y + 80.0:
		escaped.emit()
		queue_free()


func take_damage(amount: int) -> void:
	hp -= amount
	_flash()
	if hp <= 0:
		died.emit(global_position)
		queue_free()


func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	# Colorful flash based on HP
	var flash_color := Color(3.0, 3.0, 3.0, 1.0) if hp > 1 else Color(3.5, 2.0, 1.5, 1.0)
	_sprite.modulate = flash_color
	_sprite.scale = Vector2(1.65, 1.65)
	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	_flash_tween.tween_property(_sprite, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shoot() -> void:
	if not is_instance_valid(_player_ref):
		return
	var dir := (_player_ref.global_position - global_position).normalized()
	fired.emit(_muzzle.global_position, dir)
