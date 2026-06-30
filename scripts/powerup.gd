class_name Powerup extends Area2D
## Floating collectible. Type + texture assigned at spawn; applied in _ready()
## to avoid accessing @onready vars before the node enters the tree.

@onready var _sprite: Sprite2D = $Sprite2D
var power_type: int = 0
var _pending_tex: Texture2D = null


func setup(type: int, tex: Texture2D) -> void:
	power_type = type
	_pending_tex = tex


func _ready() -> void:
	add_to_group("powerups")
	area_entered.connect(_on_area_entered)
	if _pending_tex:
		_sprite.texture = _pending_tex
	# Gentle glow pulse
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "modulate", Color(1.3, 1.3, 1.3), 0.4)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.4)


func _process(delta: float) -> void:
	position.y += Cfg.POWERUP_SPEED * delta
	_sprite.rotation += Cfg.POWERUP_SPIN * delta
	if position.y > Responsive.get_viewport_rect().size.y + 40.0:
		queue_free()


func apply_to(player: Player) -> void:
	player.apply_powerup(power_type)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") and area.has_method("apply_powerup"):
		apply_to(area)
