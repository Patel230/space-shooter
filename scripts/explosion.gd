class_name Explosion extends Node2D
## Self-removing GPU particle burst with vibrant colors and shockwave ring.

@onready var _particles: GPUParticles2D = $Particles
var _ring_color: Color = Color(1.0, 0.8, 0.4)
var _ring_progress: float = 0.0
var _ring_duration: float = 0.35


func _ready() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 140.0
	mat.initial_velocity_max = 320.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.2
	mat.scale_max = 3.2
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = _make_ramp()
	mat.color_ramp = ramp_tex
	_particles.process_material = mat
	_particles.amount = 42
	_particles.lifetime = 0.6
	_particles.explosiveness = 1.0
	_particles.one_shot = true
	_particles.emitting = true
	_particles.finished.connect(queue_free)
	# Shockwave ring animation
	var ring_tween := create_tween()
	ring_tween.tween_property(self, "_ring_progress", 1.0, _ring_duration)


func _make_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.2, 1.1, 0.9))
	ramp.add_point(0.15, Palette.EXPLOSION_CORE)
	ramp.add_point(0.35, Palette.EXPLOSION_MID)
	ramp.add_point(0.65, Color(1.0, 0.4, 0.15, 0.9))
	ramp.add_point(0.85, Color(0.9, 0.2, 0.1, 0.6))
	ramp.set_color(1, Palette.EXPLOSION_END)
	ramp.set_offset(1, 1.0)
	return ramp


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _ring_progress < 1.0:
		var radius: float = _ring_progress * 60.0
		var alpha: float = (1.0 - _ring_progress) * 0.6
		var thickness: float = 3.0 + _ring_progress * 2.0
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32,
			Color(_ring_color.r, _ring_color.g, _ring_color.b, alpha), thickness, true)
