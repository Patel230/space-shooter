extends Node

enum GameState { MENU, PLAYING, GAME_OVER }

signal state_changed(new_state: int)

var _state: int = GameState.MENU
var state: int:
	get:
		return _state
	set(value):
		_state = value
		state_changed.emit(value)

var score: int = 0
var high_score: int = 0
var lives: int = 3
var chosen_ship: int = 1
var combo: int = 1
var max_combo: int = 4

var _mute: bool = false
var mute: bool:
	get:
		return _mute
	set(value):
		_mute = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0 if value else 0.0)

const SAVE_PATH := "user://save_data.json"


func _ready() -> void:
	_setup_input_map()
	_load_data()


func _setup_input_map() -> void:
	_add_key_action("move_left",  [KEY_LEFT,  KEY_A])
	_add_key_action("move_right", [KEY_RIGHT, KEY_D])
	_add_key_action("move_up",    [KEY_UP,    KEY_W])
	_add_key_action("move_down",  [KEY_DOWN,  KEY_S])
	_add_key_action("shoot",      [KEY_SPACE])


func _add_key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key_code in keys:
		var event := InputEventKey.new()
		event.keycode = key_code
		InputMap.action_add_event(action, event)


func reset_values() -> void:
	score = 0
	lives = 3
	combo = 1
	state = GameState.MENU
	# chosen_ship and mute are preferences — not reset between sessions


func check_high_score() -> void:
	if score > high_score:
		high_score = score
	save_data()


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"high_score": high_score,
			"mute": _mute,
			"chosen_ship": chosen_ship,
		}))
		file.close()


func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_migrate_legacy_save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	if parsed.has("high_score"):
		var hs = parsed["high_score"]
		if hs is float or hs is int:
			high_score = int(hs)
	if parsed.has("mute") and parsed["mute"] is bool:
		# Set _mute directly to avoid triggering save during load
		_mute = parsed["mute"]
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0 if _mute else 0.0)
	if parsed.has("chosen_ship"):
		var cs = parsed["chosen_ship"]
		if (cs is float or cs is int) and int(cs) >= 1 and int(cs) <= 3:
			chosen_ship = int(cs)


func _migrate_legacy_save() -> void:
	var legacy_path := "user://highscore.save"
	if not FileAccess.file_exists(legacy_path):
		return
	var file := FileAccess.open(legacy_path, FileAccess.READ)
	if not file:
		return
	var value = file.get_var(false)
	file.close()
	if value is int:
		high_score = value
		save_data()
