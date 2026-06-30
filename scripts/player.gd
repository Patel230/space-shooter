class_name Player extends Area2D
## Player ship. Responsive: keyboard on desktop, drag-to-move + auto-fire
## on touch devices. Communicates through signals - no direct scene path refs.

enum PowerType { RAPID_FIRE, TRIPLE_SHOT, SHIELD }

signal fired(pos: Vector2, dir: Vector2)

const _TEXTURES := {
	PowerType.RAPID_FIRE: preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupBlue_bolt.png"),
	PowerType.TRIPLE_SHOT: preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_star.png"),
	PowerType.SHIELD: preload("res://art/kenney_space-shooter-remastered/PNG/Power-ups/powerupRed_shield.png"),
}

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _muzzle: Marker2D = $Muzzle
@onready var _cooldown: Timer = $Cooldown
@onready var _invuln: Timer = $InvulnTimer
@onready var _sfx: AudioStreamPlayer = $ShootSound

var _can_shoot: bool = true
var _rapid: bool = false
var _triple: bool = false
var _touch_id: int = -1
var _rapid_timer: Timer
var _triple_timer: Timer
var _invuln_tween: Tween
var _ship_speed: float = Cfg.PLAYER_SPEED
var _base_cooldown: float = Cfg.SHOOT_COOLDOWN


func _ready() -> void:
	add_to_group("player")
	_cooldown.timeout.connect(func(): _can_shoot = true)
	_invuln.timeout.connect(_on_invuln_end)
	area_entered.connect(_on_area_entered)
	_rapid_timer = _make_one_shot_timer(_on_rapid_end)
	_triple_timer = _make_one_shot_timer(_on_triple_end)
	_setup_trail()


func reset() -> void:
	# Apply selected ship stats
	var ship: Dictionary = Cfg.SHIP_DEFS[Game.selected_ship]
	_sprite.texture = ship.texture
	_ship_speed = ship.speed
	_base_cooldown = ship.cooldown
	_triple = ship.triple
	_can_shoot = true
	_rapid = false
	_touch_id = -1
	_rapid_timer.stop()
	_triple_timer.stop()
	_cooldown.stop()
	_invuln.stop()
	if _invuln_tween:
		_invuln_tween.kill()
		_invuln_tween = null
	_sprite.modulate = Color.WHITE
	position = Responsive.player_start()


# --- Input ---

func _input(event: InputEvent) -> void:
	if Game.get_state() != Game.State.PLAYING:
		return
	_handle_touch(event)
	_handle_mouse_drag(event)


func _handle_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var half := _sprite.get_rect().size * _sprite.scale * 0.5
		position = Responsive.clamp_to_screen(event.position, half)


func _handle_mouse_drag(event: InputEvent) -> void:
	# Desktop browsers have no touch but DO emit mouse events.
	# Track the mouse when held-down and move the ship to the cursor.
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_touch_id = 1 if event.pressed else -1
			if event.pressed:
				var half := _sprite.get_rect().size * _sprite.scale * 0.5
				position = Responsive.clamp_to_screen(event.position, half)
	elif _touch_id == 1 and event is InputEventMouseMotion:
		var half := _sprite.get_rect().size * _sprite.scale * 0.5
		position = Responsive.clamp_to_screen(event.position, half)


func _process(delta: float) -> void:
	if Game.get_state() != Game.State.PLAYING:
		return
	# Keyboard works on every platform (desktop browsers, desktops, web on
	# devices with bluetooth keyboards).
	_move_keyboard(delta)
	var want_shoot := _touch_id != -1 \
			or Input.is_action_pressed("shoot")
	if want_shoot and _can_shoot:
		_shoot()


func _move_keyboard(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += dir * _ship_speed * delta
	var half := _sprite.get_rect().size * _sprite.scale * 0.5
	position = Responsive.clamp_to_screen(position, half)


# --- Combat ---

func _shoot() -> void:
	_can_shoot = false
	_cooldown.start(Cfg.RAPID_COOLDOWN if _rapid else _base_cooldown)
	var base := _muzzle.global_position
	if _triple:
		fired.emit(base + Vector2(-14, 0), Vector2.UP.rotated(-0.18))
		fired.emit(base, Vector2.UP)
		fired.emit(base + Vector2(14, 0), Vector2.UP.rotated(0.18))
	else:
		fired.emit(base, Vector2.UP)
	_muzzle_flash()
	if not Game.mute:
		_sfx.play()


# --- Collisions ---

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(99)
		take_hit()


# --- Damage ---

func take_hit() -> void:
	if not _invuln.is_stopped():
		return
	Game.lose_life()
	SignalBus.player_hit.emit()
	SignalBus.shake_requested.emit(Cfg.SHAKE_HIT_AMOUNT, Cfg.SHAKE_HIT_DURATION)
	if Game.lives <= 0:
		SignalBus.player_died.emit()
		set_process(false)
		set_process_input(false)
		return
	_invuln.start(Cfg.INVULN_TIME)
	if _invuln_tween:
		_invuln_tween.kill()
	_invuln_tween = create_tween().set_loops()
	_invuln_tween.tween_property(_sprite, "modulate:a", 0.25, 0.1)
	_invuln_tween.tween_property(_sprite, "modulate:a", 1.0, 0.1)


func apply_powerup(type: int) -> void:
	SignalBus.powerup_collected.emit(type)
	match type:
		PowerType.RAPID_FIRE:
			_rapid = true
			_rapid_timer.start(Cfg.POWERUP_DURATION)
		PowerType.TRIPLE_SHOT:
			_triple = true
			_triple_timer.start(Cfg.POWERUP_DURATION)
		PowerType.SHIELD:
			Game.gain_life()


# --- Internals ---

func _make_one_shot_timer(cb: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(cb)
	add_child(t)
	return t


func _setup_trail() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 110.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.6
	mat.scale_max = 1.3
	var gradient := Gradient.new()
	gradient.set_color(0, Palette.PLAYER_TRAIL)
	gradient.add_point(0.5, Color(1.0, 0.9, 0.5, 0.6))
	gradient.set_color(1, Color(1.0, 1.0, 0.7, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	var trail: GPUParticles2D = $Trail
	trail.process_material = mat
	trail.amount = 28
	trail.lifetime = 0.45
	trail.local_coords = false
	trail.emitting = true


func _muzzle_flash() -> void:
	_sprite.scale = Vector2(2.2, 2.2)
	var color := Color(1.3, 1.3, 1.5)
	_sprite.modulate = color
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_sprite, "scale", Vector2(2, 2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.12)


func _on_invuln_end() -> void:
	if _invuln_tween:
		_invuln_tween.kill()
		_invuln_tween = null
	_sprite.modulate.a = 1.0


func _on_rapid_end() -> void:
	_rapid = false


func _on_triple_end() -> void:
	_triple = false


static func powerup_texture(type: int) -> Texture2D:
	return _TEXTURES.get(type)
