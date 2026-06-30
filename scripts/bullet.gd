extends Projectile
## Player-fired bullet with colorful trail and impact particles.

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _trail: GPUParticles2D = $Trail


func _ready() -> void:
	super._ready()
	_setup_trail()
	_setup_glow()


func _setup_trail() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.6
	mat.scale_max = 1.4
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.4, 0.8, 1.0, 1.0))
	gradient.add_point(0.5, Color(0.6, 0.9, 1.0, 0.6))
	gradient.set_color(1, Color(0.8, 1.0, 1.0, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	_trail.process_material = mat
	_trail.amount = 16
	_trail.lifetime = 0.3
	_trail.local_coords = false
	_trail.emitting = true


func _setup_glow() -> void:
	_sprite.modulate = Color(1.2, 1.2, 1.4)


func _on_hit(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_spawn_impact()
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()


func _spawn_impact() -> void:
	var impact := GPUParticles2D.new()
	impact.global_position = global_position
	impact.z_index = 5
	impact.one_shot = true
	impact.explosiveness = 1.0
	impact.amount = 12
	impact.lifetime = 0.25
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 150.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.8
	mat.scale_max = 1.8
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.5, 0.9, 1.0, 1.0))
	gradient.add_point(0.5, Color(0.7, 1.0, 1.0, 0.7))
	gradient.set_color(1, Color(0.9, 1.0, 1.0, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	impact.process_material = mat
	get_tree().root.add_child(impact)
	impact.emitting = true
	impact.finished.connect(impact.queue_free)
