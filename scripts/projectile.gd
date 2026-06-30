class_name Projectile extends Area2D
## Directional projectile with configurable trail and impact particles.
## Configure via exported vars or override in subclass _ready().

@export var trail_direction: Vector3 = Vector3(0, 1, 0)
@export var trail_spread: float = 15.0
@export var trail_vel_min: float = 30.0
@export var trail_vel_max: float = 60.0
@export var trail_scale_min: float = 0.6
@export var trail_scale_max: float = 1.4
@export var trail_amount: int = 16
@export var trail_lifetime: float = 0.3
@export var trail_color_0: Color = Color(0.4, 0.8, 1.0, 1.0)
@export var trail_color_0_5: Color = Color(0.6, 0.9, 1.0, 0.6)
@export var trail_color_1: Color = Color(0.8, 1.0, 1.0, 0.0)

@export var sprite_glow: Color = Color(1.2, 1.2, 1.4)

@export var hit_group: String = "enemies"


@export var impact_amount: int = 12
@export var impact_lifetime: float = 0.25
@export var impact_vel_min: float = 80.0
@export var impact_vel_max: float = 150.0
@export var impact_scale_min: float = 0.8
@export var impact_scale_max: float = 1.8
@export var impact_color_0: Color = Color(0.5, 0.9, 1.0, 1.0)
@export var impact_color_0_5: Color = Color(0.7, 1.0, 1.0, 0.7)
@export var impact_color_1: Color = Color(0.9, 1.0, 1.0, 0.0)

var direction: Vector2 = Vector2.UP
var speed: float = Cfg.BULLET_SPEED
## Override in subclasses to define what happens on a successful hit.
var hit_action: Callable


## Cache shared GradientTexture1D resources by color triple so every bullet
## doesn't allocate a new GPU texture.
static var _grad_cache: Dictionary = {}


static func _get_shared_gradient(c0: Color, c05: Color, c1: Color) -> GradientTexture1D:
	var key := "%s|%s|%s" % [c0.to_html(), c05.to_html(), c1.to_html()]
	if _grad_cache.has(key):
		return _grad_cache[key]
	var gradient := Gradient.new()
	gradient.set_color(0, c0)
	gradient.add_point(0.5, c05)
	gradient.set_color(1, c1)
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	_grad_cache[key] = tex
	return tex


func launch(dir: Vector2, spd: float = -1.0) -> void:
	direction = dir.normalized()
	if spd > 0.0:
		speed = spd
	rotation = direction.angle() + PI * 0.5


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_setup_trail()
	_setup_glow()


func _setup_trail() -> void:
	var trail: GPUParticles2D = $Trail
	if not trail:
		return
	var mat := ParticleProcessMaterial.new()
	mat.direction = trail_direction
	mat.spread = trail_spread
	mat.initial_velocity_min = trail_vel_min
	mat.initial_velocity_max = trail_vel_max
	mat.gravity = Vector3.ZERO
	mat.scale_min = trail_scale_min
	mat.scale_max = trail_scale_max
	mat.color_ramp = _get_shared_gradient(trail_color_0, trail_color_0_5, trail_color_1)
	trail.process_material = mat
	trail.amount = trail_amount
	trail.lifetime = trail_lifetime
	trail.local_coords = false
	trail.emitting = true


func _setup_glow() -> void:
	var sprite: Sprite2D = $Sprite2D
	if sprite:
		sprite.modulate = sprite_glow


func _process(delta: float) -> void:
	position += direction * speed * delta
	_cull_if_offscreen()


func _on_hit(area: Area2D) -> void:
	if area.is_in_group(hit_group):
		_spawn_impact()
		if hit_action:
			hit_action.call(area)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	_on_hit(area)


func _spawn_impact() -> void:
	var impact := GPUParticles2D.new()
	impact.global_position = global_position
	impact.z_index = 5
	impact.one_shot = true
	impact.explosiveness = 1.0
	impact.amount = impact_amount
	impact.lifetime = impact_lifetime
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = impact_vel_min
	mat.initial_velocity_max = impact_vel_max
	mat.gravity = Vector3.ZERO
	mat.scale_min = impact_scale_min
	mat.scale_max = impact_scale_max
	mat.color_ramp = _get_shared_gradient(impact_color_0, impact_color_0_5, impact_color_1)
	impact.process_material = mat
	_add_to_fx_container(impact)
	impact.emitting = true
	impact.finished.connect(impact.queue_free)


func _add_to_fx_container(node: Node) -> void:
	var fx := get_tree().get_first_node_in_group("fx_container")
	if fx:
		fx.add_child(node)
	else:
		get_tree().root.add_child(node)


func _cull_if_offscreen() -> void:
	var vp := Responsive.get_viewport_rect().size
	var m := Cfg.PROJECTILE_CULL_MARGIN
	if position.y < -m or position.y > vp.y + m \
			or position.x < -m or position.x > vp.x + m:
		queue_free()
