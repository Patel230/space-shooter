class_name Projectile extends Area2D
## Base class for all directional projectiles (player bullets, enemy bullets).
## Subclasses set collision layers/masks in their scene and override
## `_on_hit(area)` to define target behaviour.

var direction: Vector2 = Vector2.UP
var speed: float = Cfg.BULLET_SPEED


## Initialize trajectory. Call right after instantiate().
func launch(dir: Vector2, spd: float = -1.0) -> void:
	direction = dir.normalized()
	if spd > 0.0:
		speed = spd
	rotation = direction.angle() + PI * 0.5


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta
	_cull_if_offscreen()


## Override in subclasses to react to a collision.
func _on_hit(_area: Area2D) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	_on_hit(area)


func _cull_if_offscreen() -> void:
	var vp := Responsive.get_viewport_rect().size
	var m := 48.0
	if position.y < -m or position.y > vp.y + m \
			or position.x < -m or position.x > vp.x + m:
		queue_free()
