extends Node2D

@onready var start_screen     := $CanvasLayer/startScreen
@onready var choose_screen    := $CanvasLayer/chooseScreen
@onready var ingame_screen    := $CanvasLayer/ingameScreen
@onready var game_over_screen := $CanvasLayer/gameOverScreen
@onready var game_manager     := $CanvasLayer/ingameScreen/GameManager
@onready var ships            := $CanvasLayer/chooseScreen/ships
@onready var high_score_label := $CanvasLayer/gameOverScreen/HighScoreValue
@onready var mute_label_on    := $CanvasLayer/ingameScreen/ButtonMute/NinePatchRect/LabelOn
@onready var mute_label_off   := $CanvasLayer/ingameScreen/ButtonMute/NinePatchRect/LabelOff

var _fader: ColorRect
var _click_sfx: AudioStreamPlayer
var _transition_tween: Tween = null

# ─── Responsive layout ───────────────────────────────────────────────────────
# The design is authored at 720x1280. With the "expand" stretch aspect the
# viewport grows to fill the window in whichever dimension is proportionally
# larger, so there are never black bars. The background fills the whole window
# (via a camera zoom), while all menu content is kept inside a centred 720-wide
# column and re-anchored vertically so buttons stay near the bottom.
const DESIGN_W := 720.0
const DESIGN_H := 1280.0

# Menu screen containers — shifting them horizontally centres every child in the
# play column without breaking the buttons (they are Control nodes).
const _SCREEN_PATHS := [
	"CanvasLayer/startScreen",
	"CanvasLayer/chooseScreen",
	"CanvasLayer/gameOverScreen",
	"CanvasLayer/ingameScreen/ButtonMute",
]
# Node2D button wrappers whose children use fixed child offsets: shifting the
# wrapper keeps the element at the same proportional vertical position.
const _WRAP_ANCHORS := {
	"CanvasLayer/startScreen/ButtonPlay": 934.0,
	"CanvasLayer/chooseScreen/ButtonChoose": 934.0,
	"CanvasLayer/chooseScreen/ButtonShipOne": 715.0,
	"CanvasLayer/chooseScreen/ButtonShipTwo": 717.0,
	"CanvasLayer/chooseScreen/ButtonShipThree": 711.0,
	"CanvasLayer/gameOverScreen/ButtonMenu": 934.0,
}
# Node2D nodes whose own position is the visual y (set directly to base * scale).
const _ABS_ANCHORS := {
	"CanvasLayer/startScreen/Sprite2D": 516.0,
	"CanvasLayer/chooseScreen/ships": 442.0,
}


func _apply_layout() -> void:
	var vp := get_viewport_rect().size
	if _fader:
		_fader.position = Vector2.ZERO
		_fader.size = vp
	var sy := vp.y / DESIGN_H
	var col_x: float = max(0.0, (vp.x - DESIGN_W) / 2.0)

	# Fill the background: zoom the world camera so the starfield covers the whole
	# viewport (only affects world-space art, not the CanvasLayer gameplay/UI).
	var cam := get_node_or_null("../Camera2D") as Camera2D
	if cam:
		var z: float = max(vp.x / DESIGN_W, vp.y / DESIGN_H)
		cam.zoom = Vector2(z, z)

	# Centre every menu screen in the play column.
	for path in _SCREEN_PATHS:
		var s := get_node_or_null(path) as Node2D
		if s:
			s.position.x = col_x

	for path in _WRAP_ANCHORS:
		var n := get_node_or_null(path) as Node2D
		if n:
			n.position.y = (sy - 1.0) * float(_WRAP_ANCHORS[path])
	for path in _ABS_ANCHORS:
		var n := get_node_or_null(path) as Node2D
		if n:
			n.position.y = float(_ABS_ANCHORS[path]) * sy
	var hs := get_node_or_null("CanvasLayer/gameOverScreen/HighScoreValue") as Control
	if hs:
		hs.position.y = 580.0 * sy


func _ready() -> void:
	# Full-screen black fade overlay — rendered on top of all screens
	_fader = ColorRect.new()
	_fader.color = Color(0, 0, 0, 0)
	_fader.position = Vector2.ZERO
	_fader.size = get_viewport_rect().size
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.z_index = 10
	$CanvasLayer.add_child(_fader)

	# UI click sound
	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = preload("res://art/kenney_ui-pack/Sounds/click-a.ogg")
	add_child(_click_sfx)

	_update_ship_preview()
	game_manager.game_over_requested.connect(_on_game_over)

	# Re-anchor menu elements to the current viewport and on every resize.
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()

	# Reflect persisted mute state in button label
	mute_label_on.visible  = not global.mute
	mute_label_off.visible = global.mute


func _transition(from: Node, to: Node, on_switch: Callable = Callable()) -> void:
	if _transition_tween and _transition_tween.is_running():
		return
	_transition_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_transition_tween.tween_property(_fader, "color:a", 1.0, 0.15)
	_transition_tween.tween_callback(func():
		from.visible = false
		to.visible   = true
		if on_switch.is_valid():
			on_switch.call()
	)
	_transition_tween.tween_property(_fader, "color:a", 0.0, 0.2)


func _play_click() -> void:
	if not global.mute:
		_click_sfx.play()


func _on_button_play_pressed() -> void:
	_play_click()
	_transition(start_screen, choose_screen)


func _on_button_ship_one_pressed() -> void:
	_play_click()
	global.chosen_ship = 1
	_update_ship_preview()


func _on_button_ship_two_pressed() -> void:
	_play_click()
	global.chosen_ship = 2
	_update_ship_preview()


func _on_button_ship_three_pressed() -> void:
	_play_click()
	global.chosen_ship = 3
	_update_ship_preview()


func _on_button_choose_pressed() -> void:
	_play_click()
	_transition(choose_screen, ingame_screen, game_manager.start_game)


func _on_button_mute_pressed() -> void:
	global.mute = not global.mute
	mute_label_on.visible  = not global.mute
	mute_label_off.visible = global.mute
	global.save_data()


func _on_button_menu_pressed() -> void:
	_play_click()
	_transition(game_over_screen, start_screen, func():
		global.reset_values()
		_update_ship_preview()
	)


func _on_game_over() -> void:
	high_score_label.text = "Score: %d   High Score: %d" % [global.score, global.high_score]
	_transition(ingame_screen, game_over_screen)


func _update_ship_preview() -> void:
	ships.get_node("shipOne").visible   = global.chosen_ship == 1
	ships.get_node("shipTwo").visible   = global.chosen_ship == 2
	ships.get_node("shipThree").visible = global.chosen_ship == 3
