extends Area2D

const SPEED := 800.0

var has_hit := false

@onready var sprite := $Sprite2D


func _ready() -> void:
	sprite.texture = preload("res://art/kenney_space-shooter-remastered/PNG/Lasers/laserGreen11.png")
	area_entered.connect(_on_area_entered)
	visible = false
	set_process(false)


func activate() -> void:
	has_hit = false
	visible = true
	set_process(true)


func deactivate() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	position.y -= SPEED * delta
	if position.y < -50:
		deactivate()


func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	if not (area.is_in_group("enemies") or area.is_in_group("meteors")):
		return
	area.take_damage(1)
	has_hit = true
	deactivate()
