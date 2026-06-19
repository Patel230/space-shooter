extends Area2D

signal hit
signal died

const SPEED := 400.0
const PLAY_WIDTH := 720.0
const SHOOT_COOLDOWN := 0.2
const INVULNERABILITY_TIME := 1.5
const POWERUP_DURATION := 5.0

var can_shoot := true
var invulnerable := false
var invul_tween: Tween = null
var bullet_pool: Node = null

var _touch_id: int = -1
var _touch_position: Vector2 = Vector2.ZERO

var _rapid_fire_active: bool = false
var _double_shot_active: bool = false
var _rapid_fire_timer: Timer
var _double_shot_timer: Timer

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer := $ShootTimer
@onready var invulnerability_timer := $InvulnerabilityTimer
@onready var muzzle := $Muzzle
@onready var shoot_sound := $ShootSound

var ship_textures := {
	1: preload("res://art/kenney_space-shooter-remastered/PNG/playerShip2_blue.png"),
	2: preload("res://art/kenney_space-shooter-remastered/PNG/playerShip1_blue.png"),
	3: preload("res://art/kenney_space-shooter-remastered/PNG/playerShip3_blue.png"),
}

var damage_textures := {
	1: {
		1: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip2_damage1.png"),
		2: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip2_damage2.png"),
		3: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip2_damage3.png"),
	},
	2: {
		1: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip1_damage1.png"),
		2: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip1_damage2.png"),
		3: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip1_damage3.png"),
	},
	3: {
		1: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip3_damage1.png"),
		2: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip3_damage2.png"),
		3: preload("res://art/kenney_space-shooter-remastered/PNG/Damage/playerShip3_damage3.png"),
	},
}


func _ready() -> void:
	add_to_group("player")
	sprite.texture = ship_textures[global.chosen_ship]
	shoot_sound.stream = preload("res://art/kenney_space-shooter-remastered/Bonus/sfx_laser2.ogg")
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	area_entered.connect(_on_area_entered)
	_rapid_fire_timer = _make_timer(POWERUP_DURATION, _on_rapid_fire_end)
	_double_shot_timer = _make_timer(POWERUP_DURATION, _on_double_shot_end)


func _make_timer(wait: float, callback: Callable) -> Timer:
	var t := Timer.new()
	t.wait_time = wait
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t


func _input(event: InputEvent) -> void:
	if global.state != global.GameState.PLAYING:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_position = event.position
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_touch_position = event.position


func _process(delta: float) -> void:
	if global.state != global.GameState.PLAYING:
		return

	var vp   := get_viewport_rect()
	var half: Vector2 = Vector2(sprite.texture.get_size()) * sprite.scale / 2.0

	# Confine the ship to the centred 720-wide play column (the rest of a wide
	# viewport is background only). Height always fills the viewport.
	var col_x: float = max(0.0, (vp.size.x - PLAY_WIDTH) / 2.0)
	var min_p := Vector2(col_x + half.x, half.y)
	var max_p := Vector2(col_x + PLAY_WIDTH - half.x, vp.size.y - half.y)

	if _touch_id != -1:
		position = _touch_position.clamp(min_p, max_p)
		if can_shoot:
			_shoot()
	else:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		position += input * SPEED * delta
		position  = position.clamp(min_p, max_p)
		if Input.is_action_pressed("shoot") and can_shoot:
			_shoot()


func _on_area_entered(area: Area2D) -> void:
	if invulnerable:
		return
	if area.is_in_group("enemies") or area.is_in_group("meteors"):
		_hit()
	elif area.is_in_group("enemy_bullets"):
		area.queue_free()
		_hit()


func _shoot() -> void:
	can_shoot = false
	var cooldown := SHOOT_COOLDOWN * (0.5 if _rapid_fire_active else 1.0)
	shoot_timer.start(cooldown)
	if bullet_pool:
		if _double_shot_active:
			bullet_pool.acquire(muzzle.global_position + Vector2(-16, 0))
			bullet_pool.acquire(muzzle.global_position + Vector2(16, 0))
		else:
			bullet_pool.acquire(muzzle.global_position)
	if not global.mute:
		shoot_sound.play()


func apply_powerup(type: int) -> void:
	match type:
		PowerUp.Type.SHIELD:
			global.lives = min(global.lives + 1, 3)
			_update_damage()
		PowerUp.Type.RAPID_FIRE:
			_rapid_fire_active = true
			_rapid_fire_timer.start()
		PowerUp.Type.DOUBLE_SHOT:
			_double_shot_active = true
			_double_shot_timer.start()


func _on_rapid_fire_end() -> void:
	_rapid_fire_active = false


func _on_double_shot_end() -> void:
	_double_shot_active = false


func _hit() -> void:
	global.lives -= 1
	_update_damage()
	hit.emit()

	if global.lives <= 0:
		died.emit()
		return

	_start_invulnerability()


func _update_damage() -> void:
	if global.lives >= 3:
		sprite.texture = ship_textures[global.chosen_ship]
	elif global.lives == 2:
		sprite.texture = damage_textures[global.chosen_ship][1]
	elif global.lives == 1:
		sprite.texture = damage_textures[global.chosen_ship][2]


func _start_invulnerability() -> void:
	invulnerable = true
	invulnerability_timer.start(INVULNERABILITY_TIME)

	if invul_tween:
		invul_tween.kill()
	invul_tween = create_tween()
	invul_tween.set_loops()
	invul_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	invul_tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


func _on_invulnerability_timeout() -> void:
	if invul_tween:
		invul_tween.kill()
		invul_tween = null
	sprite.modulate.a = 1.0
	invulnerable = false
	_check_current_overlaps()


func _check_current_overlaps() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") or area.is_in_group("meteors"):
			_hit()
			return
		elif area.is_in_group("enemy_bullets"):
			area.queue_free()
			_hit()
			return


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
