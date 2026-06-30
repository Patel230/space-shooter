class_name Powerup extends Area2D
## Floating collectible with colorful glow, particles, and bounce animation.

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _glow_particles: GPUParticles2D = $GlowParticles
var power_type: int = 0
var _pending_tex: Texture2D = null
var _base_y: float = 0.0
var _time: float = 0.0


func setup(type: int, tex: Texture2D) -> void:
	power_type = type
	_pending_tex = tex


func _ready() -> void:
	add_to_group("powerups")
	area_entered.connect(_on_area_entered)
	if _pending_tex:
		_sprite.texture = _pending_tex
	_base_y = position.y
	_setup_particles()
	_setup_animations()


func _setup_particles() -> void:
	var color := _get_powerup_color()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 35.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.8
	mat.scale_max = 1.6
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.8))
	gradient.add_point(0.5, Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.5))
	gradient.set_color(1, Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	_glow_particles.process_material = mat
	_glow_particles.amount = 20
	_glow_particles.lifetime = 0.6
	_glow_particles.emitting = true


func _setup_animations() -> void:
	var color := _get_powerup_color()
	var bright := Color(color.r * 1.4, color.g * 1.4, color.b * 1.4)
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "modulate", bright, 0.35)
	t.tween_property(_sprite, "modulate", color, 0.35)
	# Scale pulse
	var scale_t := create_tween().set_loops()
	scale_t.tween_property(_sprite, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
	scale_t.tween_property(_sprite, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)


func _get_powerup_color() -> Color:
	match power_type:
		Player.PowerType.RAPID_FIRE:
			return Color(0.4, 0.8, 1.0)
		Player.PowerType.TRIPLE_SHOT:
			return Color(1.0, 0.9, 0.3)
		Player.PowerType.SHIELD:
			return Color(1.0, 0.4, 0.5)
		_:
			return Color.WHITE


func _process(delta: float) -> void:
	_time += delta
	position.y += Cfg.POWERUP_SPEED * delta
	var bounce := sin(_time * 3.5) * 8.0
	_sprite.position.y = bounce
	_sprite.rotation += Cfg.POWERUP_SPIN * delta
	if position.y > Responsive.get_viewport_rect().size.y + 40.0:
		queue_free()


func apply_to(player: Player) -> void:
	_spawn_collect_burst()
	player.apply_powerup(power_type)
	queue_free()


func _spawn_collect_burst() -> void:
	var burst := GPUParticles2D.new()
	burst.global_position = global_position
	burst.z_index = 10
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 0.4
	var color := _get_powerup_color()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.0
	mat.scale_max = 2.2
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0))
	gradient.add_point(0.5, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	burst.process_material = mat
	get_tree().root.add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)


func _on_area_entered(area: Area2D) -> void:
	if Game.get_state() != Game.State.PLAYING:
		return
	if area.is_in_group("player") and area.has_method("apply_powerup"):
		apply_to(area)
