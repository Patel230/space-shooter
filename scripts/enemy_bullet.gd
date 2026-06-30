extends Projectile
## Enemy-fired bullet. Damages the player on contact.

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_hit"):
			area.take_hit()
		queue_free()
