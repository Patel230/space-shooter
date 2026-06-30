class_name Explosion extends Node2D
## Self-removing GPU particle burst. scale set by spawner for big/small blasts.

@onready var _particles: GPUParticles2D = $Particles


func _ready() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 280.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.0
	mat.scale_max = 2.6
	# Rich explosion: bright core fades to ember
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = _make_ramp()
	mat.color_ramp = ramp_tex
	_particles.process_material = mat
	_particles.amount = 36
	_particles.lifetime = 0.55
	_particles.explosiveness = 1.0
	_particles.one_shot = true
	_particles.emitting = true
	_particles.finished.connect(queue_free)


func _make_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Palette.EXPLOSION_CORE)
	ramp.add_point(0.3, Palette.EXPLOSION_MID)
	ramp.add_point(0.7, Color(0.9, 0.3, 0.1, 0.8))
	ramp.set_color(1, Palette.EXPLOSION_END)
	ramp.set_offset(1, 1.0)
	return ramp
