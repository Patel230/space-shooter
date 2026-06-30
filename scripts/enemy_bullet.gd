extends Projectile
## Enemy-fired bullet with colorful red/orange trail.

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _trail: GPUParticles2D = $Trail


func _ready() -> void:
	super._ready()
	_setup_trail()
	_setup_glow()


func _setup_trail() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 18.0
	mat.initial_velocity_min = 25.0
	mat.initial_velocity_max = 50.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.4, 0.2, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.6, 0.3, 0.7))
	gradient.set_color(1, Color(1.0, 0.8, 0.4, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	_trail.process_material = mat
	_trail.amount = 14
	_trail.lifetime = 0.28
	_trail.local_coords = false
	_trail.emitting = true


func _setup_glow() -> void:
	_sprite.modulate = Color(1.3, 1.1, 1.0)


func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player"):
		_spawn_impact()
		if area.has_method("take_hit"):
			area.take_hit()
		queue_free()


func _spawn_impact() -> void:
	var impact := GPUParticles2D.new()
	impact.global_position = global_position
	impact.z_index = 5
	impact.one_shot = true
	impact.explosiveness = 1.0
	impact.amount = 10
	impact.lifetime = 0.22
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = 70.0
	mat.initial_velocity_max = 130.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.7
	mat.scale_max = 1.5
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.5, 0.2, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.7, 0.3, 0.8))
	gradient.set_color(1, Color(1.0, 0.9, 0.5, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	impact.process_material = mat
	get_tree().root.add_child(impact)
	impact.emitting = true
	impact.finished.connect(impact.queue_free)
