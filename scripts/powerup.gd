class_name PowerUp extends Area2D

signal collected(type: int)

enum Type { SHIELD, RAPID_FIRE, DOUBLE_SHOT }

const SPEED := 130.0
const SPIN  := 1.8

var type: int = Type.SHIELD

@onready var sprite: Sprite2D = $Sprite2D

var _textures: Dictionary = {
	Type.SHIELD:      preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_shield.png"),
	Type.RAPID_FIRE:  preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupGreen_bolt.png"),
	Type.DOUBLE_SHOT: preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_star.png"),
}


func _ready() -> void:
	add_to_group("powerups")
	sprite.texture = _textures[type]
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position.y += SPEED * delta
	rotation   += SPIN  * delta
	if position.y > get_viewport_rect().size.y + 60:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collected.emit(type)
		queue_free()
