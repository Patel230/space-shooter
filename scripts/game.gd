extends Node
## Global game state, persistence and settings singleton.
##
## Autoload name: Game

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

const SAVE_PATH := "user://space_shooter_save.json"

var _state: State = State.MENU
var score: int = 0
var lives: int = 3
var _max_lives: int = 3
var wave: int = 0
var high_score: int = 0
var mute: bool = false
var volume: float = 0.7
var selected_ship: int = Cfg.ShipType.FIGHTER
var fx_preset: int = 2  # PostFX.Preset.ARCADE
var screen_shake: bool = true
var last_run_is_record: bool = false


func _ready() -> void:
	_ensure_input_map()
	_load_save()
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.enemy_killed.connect(_on_enemy_killed)


func _ensure_input_map() -> void:
	# Input actions are defined in project.godot [input] section.
	# This is a fallback: add any that are missing at runtime.
	_ensure_key_action("move_left",  [KEY_LEFT,  KEY_A])
	_ensure_key_action("move_right", [KEY_RIGHT, KEY_D])
	_ensure_key_action("move_up",    [KEY_UP,    KEY_W])
	_ensure_key_action("move_down",  [KEY_DOWN,  KEY_S])
	_ensure_key_action("shoot",      [KEY_SPACE])
	_ensure_joy_axis("move_left",  JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis("move_right", JOY_AXIS_LEFT_X,  1.0)
	_ensure_joy_axis("move_up",    JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis("move_down",  JOY_AXIS_LEFT_Y,  1.0)
	_ensure_joy_button("shoot", JOY_BUTTON_A)


func _ensure_key_action(action: String, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key_code: Key in keys:
		if _action_has_key(action, key_code):
			continue
		var event := InputEventKey.new()
		event.keycode = key_code
		InputMap.action_add_event(action, event)


func _ensure_joy_axis(action: String, axis: int, sign_val: float) -> void:
	if not InputMap.has_action(action):
		return
	if _action_has_joy_motion(action, axis, sign_val):
		return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = sign_val
	InputMap.action_add_event(action, event)


func _ensure_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	if _action_has_joy_button(action, button):
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _action_has_key(action: String, key_code: Key) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.keycode == key_code:
			return true
	return false


func _action_has_joy_motion(action: String, axis: int, sign_val: float) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion and e.axis == axis and signf(e.axis_value) == signf(sign_val):
			return true
	return false


func _action_has_joy_button(action: String, button: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and e.button_index == button:
			return true
	return false


func get_state() -> State:
	return _state


func set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	# When leaving PLAYING or PAUSED to GAME_OVER, ensure the tree is unpaused
	# so the game-over screen animation runs.
	if new_state == State.GAME_OVER:
		get_tree().paused = false
	if new_state == State.MENU:
		get_tree().paused = false
	SignalBus.state_changed.emit(new_state)


func start_run() -> void:
	score = 0
	var ship_def: Dictionary = Cfg.SHIP_DEFS[selected_ship]
	lives = ship_def.lives
	_max_lives = ship_def.lives
	wave = 0
	SignalBus.score_changed.emit(score)
	SignalBus.lives_changed.emit(lives)
	SignalBus.wave_changed.emit(wave)
	set_state(State.PLAYING)


func add_score(amount: int) -> void:
	score = maxi(0, score + amount)
	SignalBus.score_changed.emit(score)


func lose_life() -> void:
	lives = maxi(0, lives - 1)
	SignalBus.lives_changed.emit(lives)


func gain_life() -> void:
	lives = mini(_max_lives, lives + 1)
	SignalBus.lives_changed.emit(lives)


func set_wave(n: int) -> void:
	wave = n
	SignalBus.wave_changed.emit(wave)


func _on_player_died() -> void:
	if get_state() != State.PLAYING:
		return
	last_run_is_record = score > high_score and score > 0
	if last_run_is_record:
		high_score = score
		_save()
		SignalBus.high_score_changed.emit(high_score)
	set_state(State.GAME_OVER)


func _on_enemy_killed(_pos: Vector2, score_value: int) -> void:
	add_score(score_value)


func toggle_mute() -> void:
	mute = not mute
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, mute)
	SignalBus.mute_changed.emit(mute)
	_save_deferred()


func set_volume(vol: float) -> void:
	volume = clampf(vol, 0.0, 1.0)
	Music.set_volume(volume)
	SignalBus.volume_changed.emit(volume)
	_save_deferred()


func set_fx_preset(idx: int) -> void:
	fx_preset = clampi(idx, 0, 3)
	SignalBus.fx_preset_changed.emit(fx_preset)
	_save_deferred()


func toggle_screen_shake() -> void:
	screen_shake = not screen_shake
	SignalBus.screen_shake_changed.emit(screen_shake)
	_save_deferred()


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	if parsed.has("high_score") and (parsed["high_score"] is float or parsed["high_score"] is int):
		high_score = int(parsed["high_score"])
	if parsed.has("mute") and parsed["mute"] is bool:
		mute = parsed["mute"]
		var idx := AudioServer.get_bus_index("Master")
		if idx >= 0:
			AudioServer.set_bus_mute(idx, mute)
	if parsed.has("volume") and (parsed["volume"] is float or parsed["volume"] is int):
		volume = clampf(float(parsed["volume"]), 0.0, 1.0)
	if parsed.has("fx_preset") and (parsed["fx_preset"] is float or parsed["fx_preset"] is int):
		fx_preset = clampi(int(parsed["fx_preset"]), 0, 3)
	if parsed.has("selected_ship") and (parsed["selected_ship"] is float or parsed["selected_ship"] is int):
		selected_ship = clampi(int(parsed["selected_ship"]), 0, Cfg.SHIP_DEFS.size() - 1)
	if parsed.has("screen_shake") and parsed["screen_shake"] is bool:
		screen_shake = parsed["screen_shake"]


func set_selected_ship(idx: int) -> void:
	var clamped := clampi(idx, 0, Cfg.SHIP_DEFS.size() - 1)
	if clamped == selected_ship:
		return
	selected_ship = clamped
	_save_deferred()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"high_score": high_score,
			"mute": mute,
			"volume": volume,
			"fx_preset": fx_preset,
			"selected_ship": selected_ship,
			"screen_shake": screen_shake,
		}))
		f.close()


# Throttled save to avoid disk hitches when settings change rapidly (e.g. dragging volume slider).
var _save_pending: bool = false

func _save_deferred() -> void:
	if _save_pending:
		return
	_save_pending = true
	get_tree().create_timer(0.25).timeout.connect(_flush_save)


func _flush_save() -> void:
	_save_pending = false
	_save()
