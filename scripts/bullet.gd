extends Projectile
## Player-fired bullet. Damages enemies on contact.

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()
