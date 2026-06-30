extends Projectile
## Enemy bullet. Orange trail, damages player on hit.

func _ready() -> void:
	trail_direction = Vector3(0, -1, 0)
	trail_spread = 18.0
	trail_vel_min = 25.0
	trail_vel_max = 50.0
	trail_scale_min = 0.5
	trail_scale_max = 1.2
	trail_amount = 14
	trail_lifetime = 0.28
	trail_color_0 = Color(1.0, 0.4, 0.2, 1.0)
	trail_color_0_5 = Color(1.0, 0.6, 0.3, 0.7)
	trail_color_1 = Color(1.0, 0.8, 0.4, 0.0)

	sprite_glow = Color(1.3, 1.1, 1.0)

	hit_group = "player"
	impact_amount = 10
	impact_lifetime = 0.22
	impact_vel_min = 70.0
	impact_vel_max = 130.0
	impact_scale_min = 0.7
	impact_scale_max = 1.5
	impact_color_0 = Color(1.0, 0.5, 0.2, 1.0)
	impact_color_0_5 = Color(1.0, 0.7, 0.3, 0.8)
	impact_color_1 = Color(1.0, 0.9, 0.5, 0.0)

	hit_action = func(area: Area2D) -> void:
		if area.has_method("take_hit"):
			area.take_hit()

	super._ready()
