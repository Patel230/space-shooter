class_name PauseOverlay extends CanvasLayer
## Compact pause overlay matching the game-over screen's card style.

const _SFX_CLICK := preload("res://art/kenney_ui-pack/Sounds/click-b.ogg")
const _SFX_HOVER := preload("res://art/kenney_ui-pack/Sounds/switch-b.ogg")

signal resume_requested
signal restart_requested
signal menu_requested

@onready var _panel: Panel = $Center/Panel
@onready var _title: Label = $Center/Panel/VBox/TitleLabel
@onready var _resume: Button = $Center/Panel/VBox/ResumeButton
@onready var _restart: Button = $Center/Panel/VBox/RestartButton
@onready var _menu: Button = $Center/Panel/VBox/MenuButton
@onready var _shake: Button = $Center/Panel/VBox/ShakeButton
@onready var _hint: Label = $Center/Panel/VBox/HintLabel

var _hover_tween: Tween
var _entrance_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 50
	_resume.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); resume_requested.emit())
	_restart.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); restart_requested.emit())
	_menu.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); menu_requested.emit())
	for b in [_resume, _restart, _menu]:
		b.mouse_entered.connect(func(): _hover_sfx(); _btn_hover(b))
		b.mouse_exited.connect(func(): _btn_unhover(b))
	_shake.pressed.connect(func():
		_play_ui_sfx(_SFX_CLICK)
		Game.toggle_screen_shake()
		_update_shake_text()
	)
	get_viewport().size_changed.connect(_apply_font_scale)


func _btn_hover(b: Button) -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(b, "scale", Vector2(1.06, 1.06), 0.1).set_ease(Tween.EASE_OUT)

func _btn_unhover(b: Button) -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(b, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)


func _update_shake_text() -> void:
	_shake.text = "SCREEN SHAKE: ON" if Game.screen_shake else "SCREEN SHAKE: OFF"


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_title.add_theme_font_size_override("font_size", maxi(24, int(34 * s)))
	_resume.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))
	_restart.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))
	_menu.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))
	_shake.add_theme_font_size_override("font_size", maxi(12, int(15 * s)))
	_hint.add_theme_font_size_override("font_size", maxi(11, int(13 * s)))
	var half := Vector2(320, 430) * 0.5 * clampf(s, 0.8, 1.6)
	_panel.offset_left = -half.x
	_panel.offset_top = -half.y
	_panel.offset_right = half.x
	_panel.offset_bottom = half.y


func appear() -> void:
	_apply_font_scale()
	_update_shake_text()
	var children: Array[Control] = [_title, _resume, _restart, _menu, _shake, _hint]
	# CanvasLayer starts hidden — show() must happen before layout settles,
	# or VBoxContainer positions aren't finalized when we snapshot them.
	show()
	_panel.modulate.a = 0.0
	for c in children:
		c.modulate.a = 0.0
	await get_tree().process_frame
	if _entrance_tween: _entrance_tween.kill()
	var orig_positions: Dictionary = {}
	for c in children:
		orig_positions[c] = c.position.y
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.9, 0.9)
	for c in children:
		c.position.y = orig_positions[c] + 10

	_entrance_tween = create_tween()
	_entrance_tween.tween_property(_panel, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	_entrance_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in children.size():
		var c: Control = children[i]
		_entrance_tween.tween_interval(0.04)
		_entrance_tween.parallel().tween_property(c, "modulate:a", 1.0, 0.2)
		_entrance_tween.parallel().tween_property(c, "position:y", orig_positions[c], 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.chain().tween_callback(func():
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		for c in children:
			c.modulate.a = 1.0
			c.position.y = orig_positions[c]
		_resume.grab_focus()
	)


func disappear() -> void:
	if _entrance_tween: _entrance_tween.kill()
	if _hover_tween: _hover_tween.kill()
	if not visible:
		return
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.15)
	t.parallel().tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.15)
	t.finished.connect(hide)


func _hover_sfx() -> void:
	_play_ui_sfx(_SFX_HOVER)


func _play_ui_sfx(stream: AudioStream) -> void:
	if Game.mute:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(maxf(0.0001, Game.volume))
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
