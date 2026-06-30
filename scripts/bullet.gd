extends Projectile
## Player bullet. Blue trail, damages enemies on hit.

func _ready() -> void:
	hit_action = func(area: Area2D) -> void:
		if area.has_method("take_damage"):
			area.take_damage(1)
	super._ready()
