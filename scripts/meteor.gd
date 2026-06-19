extends Area2D

signal killed(score_value: int, pos: Vector2)

const SCORE_VALUE := 50
const SPEED_MIN   := 80.0
const SPEED_MAX   := 160.0
const HP          := 3

var hp: int = HP
var speed: float = 100.0
var spin: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D

var _textures: Array = [
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_big1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_big2.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_big3.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_big4.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_big1.png"),
	preload("res://art/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_big2.png"),
]


func _ready() -> void:
	add_to_group("meteors")
	sprite.texture = _textures.pick_random()
	speed = randf_range(SPEED_MIN, SPEED_MAX)
	spin  = randf_range(0.5, 2.0) * (1.0 if randf() > 0.5 else -1.0)


func _process(delta: float) -> void:
	position.y += speed * delta
	rotation   += spin * delta
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.04)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if hp <= 0:
		killed.emit(SCORE_VALUE, global_position)
		queue_free()
