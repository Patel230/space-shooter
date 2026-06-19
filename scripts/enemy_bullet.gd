extends Area2D

const SPEED := 350.0

@onready var sprite := $Sprite2D


func _ready() -> void:
	add_to_group("enemy_bullets")
	sprite.texture = preload("res://art/kenney_space-shooter-remastered/PNG/Lasers/laserRed11.png")


func _process(delta: float) -> void:
	position.y += SPEED * delta

	var vp := get_viewport_rect()
	if position.y > vp.size.y + 50:
		queue_free()
