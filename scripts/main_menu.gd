class_name MainMenu extends CanvasLayer
## Compact, animated title screen. Auto-sized panel, floating title glow,
## staggered entrance, button hover scale. Fully responsive font scaling.

signal start_requested

@onready var _high: Label = $Center/Panel/VBox/HighScoreLabel
@onready var _play: Button = $Center/Panel/VBox/PlayButton
@onready var _title: Label = $Center/Panel/VBox/TitleLabel
@onready var _sub: Label = $Center/Panel/VBox/SubLabel
@onready var _panel: Panel = $Center/Panel
@onready var _vol_slider: HSlider = $Center/Panel/VBox/VolumeRow/VolumeSlider
@onready var _vol_pct: Label = $Center/Panel/VBox/VolumeRow/VolumePercent
@onready var _hint: Label = $Center/Panel/VBox/HintLabel
@onready var _vol_row: HBoxContainer = $Center/Panel/VBox/VolumeRow

var _glow_tween: Tween
var _float_tween: Tween
var _hover_tween: Tween


func _ready() -> void:
	_apply_font_scale()
	_play.pressed.connect(func(): start_requested.emit())
	_play.mouse_entered.connect(_on_play_hover)
	_play.mouse_exited.connect(_on_play_unhover)
	SignalBus.high_score_changed.connect(func(h): _high.text = "High Score: %d" % h)
	_high.text = "High Score: %d" % Game.high_score
	_vol_slider.value = Game.volume * 100.0
	_vol_pct.text = "%d%%" % int(Game.volume * 100.0)
	_vol_slider.value_changed.connect(_on_volume_changed)


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_title.add_theme_font_size_override("font_size", maxi(20, int(34 * s)))
	_sub.add_theme_font_size_override("font_size", maxi(10, int(14 * s)))
	_high.add_theme_font_size_override("font_size", maxi(12, int(18 * s)))
	_play.add_theme_font_size_override("font_size", maxi(14, int(20 * s)))
	_hint.add_theme_font_size_override("font_size", maxi(9, int(11 * s)))
	_vol_pct.add_theme_font_size_override("font_size", maxi(9, int(12 * s)))


func _on_volume_changed(value: float) -> void:
	_vol_pct.text = "%d%%" % int(value)
	Game.set_volume(value / 100.0)


func _on_play_hover() -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(_play, "scale", Vector2(1.06, 1.06), 0.12).set_ease(Tween.EASE_OUT)

func _on_play_unhover() -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(_play, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)


func _start_animations() -> void:
	# Title glow pulse
	if _glow_tween: _glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_title, "modulate", Palette.MENU_TITLE, 1.6)
	_glow_tween.tween_property(_title, "modulate", Palette.MENU_TITLE_GLOW, 1.6)

	# Subtle floating title
	if _float_tween: _float_tween.kill()
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(_title, "position:y", _title.position.y - 3, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(_title, "position:y", _title.position.y, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func appear() -> void:
	show()
	_play.grab_focus()
	_apply_font_scale()
	_start_animations()
	# Staggered entrance: panel + each element slides up + fades in
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	# Start all children invisible
	var children := [_title, _sub, _high, _play, _vol_row, _hint]
	for c in children:
		c.modulate.a = 0.0
		c.position.y += 12

	var t := create_tween()
	# Panel slides in first
	t.tween_property(_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Then children stagger in
	for i in children.size():
		t.tween_callback(func(): pass)
		t.tween_interval(0.06)
		t.parallel().tween_property(children[i], "modulate:a", 1.0, 0.25)
		t.parallel().tween_property(children[i], "position:y", children[i].position.y - 12, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear() -> void:
	if _glow_tween: _glow_tween.kill()
	if _float_tween: _float_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.2)
	t.finished.connect(hide)
