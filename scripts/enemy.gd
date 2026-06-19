extends Area2D

signal killed(score_value: int, pos: Vector2)

const MIN_SPEED := 100.0
const MAX_SPEED := 200.0
const SHOOT_INTERVAL_MIN := 2.0
const SHOOT_INTERVAL_MAX := 5.0
const ENEMY_BULLET_SCENE := preload("res://scenes/enemy_bullet.tscn")

var speed := 150.0
var hp := 1
var score_value := 100

@onready var shoot_timer := $ShootTimer
@onready var sprite := $Sprite2D

var enemy_textures := [
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack5.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue5.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen5.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Enemies/enemyRed5.png"),
]


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = enemy_textures.pick_random()
	speed = randf_range(MIN_SPEED, MAX_SPEED)
	score_value = randi_range(50, 150)
	hp = 1 if score_value < 100 else 2

	if randf() < 0.5:
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start(randf_range(SHOOT_INTERVAL_MIN, SHOOT_INTERVAL_MAX))


func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		shoot_timer.stop()
		killed.emit(score_value, global_position)
		queue_free()


func _on_shoot_timer_timeout() -> void:
	var bullet := ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2(0, 20)
	get_tree().current_scene.add_child(bullet)
	shoot_timer.start(randf_range(SHOOT_INTERVAL_MIN, SHOOT_INTERVAL_MAX))
