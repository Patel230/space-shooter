class_name MainMenu extends CanvasLayer
## Welcome screen with ship selection carousel, animated title, volume slider.
## Staggered entrance, button hover, responsive font scaling.

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
@onready var _left_btn: Button = $Center/Panel/VBox/ShipRow/LeftBtn
@onready var _right_btn: Button = $Center/Panel/VBox/ShipRow/RightBtn
@onready var _ship_preview: TextureRect = $Center/Panel/VBox/ShipRow/ShipPreview
@onready var _ship_name: Label = $Center/Panel/VBox/ShipNameLabel
@onready var _ship_desc: Label = $Center/Panel/VBox/ShipDescLabel
@onready var _ship_stats: Label = $Center/Panel/VBox/ShipStatsLabel
@onready var _ship_row: HBoxContainer = $Center/Panel/VBox/ShipRow
@onready var _choose_label: Label = $Center/Panel/VBox/ChooseShipLabel

var _glow_tween: Tween
var _float_tween: Tween
var _hover_tween: Tween
var _ship_idx: int = 0
var _ship_tween: Tween


func _ready() -> void:
	_apply_font_scale()
	_play.pressed.connect(func(): start_requested.emit())
	_play.mouse_entered.connect(_on_play_hover)
	_play.mouse_exited.connect(_on_play_unhover)
	_left_btn.pressed.connect(_prev_ship)
	_right_btn.pressed.connect(_next_ship)
	SignalBus.high_score_changed.connect(func(h): _high.text = "High Score: %d" % h)
	_high.text = "High Score: %d" % Game.high_score
	_vol_slider.value = Game.volume * 100.0
	_vol_pct.text = "%d%%" % int(Game.volume * 100.0)
	_vol_slider.value_changed.connect(_on_volume_changed)
	_ship_idx = Cfg.SHIP_ORDER.find(Game.selected_ship)
	if _ship_idx < 0: _ship_idx = 1
	_update_ship_display()


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_title.add_theme_font_size_override("font_size", maxi(24, int(40 * s)))
	_sub.add_theme_font_size_override("font_size", maxi(11, int(16 * s)))
	_high.add_theme_font_size_override("font_size", maxi(13, int(18 * s)))
	_play.add_theme_font_size_override("font_size", maxi(16, int(24 * s)))
	_hint.add_theme_font_size_override("font_size", maxi(10, int(12 * s)))
	_vol_pct.add_theme_font_size_override("font_size", maxi(10, int(14 * s)))
	_choose_label.add_theme_font_size_override("font_size", maxi(14, int(20 * s)))
	_ship_name.add_theme_font_size_override("font_size", maxi(16, int(24 * s)))
	_ship_desc.add_theme_font_size_override("font_size", maxi(10, int(14 * s)))
	_ship_stats.add_theme_font_size_override("font_size", maxi(10, int(13 * s)))
	_left_btn.add_theme_font_size_override("font_size", maxi(16, int(24 * s)))
	_right_btn.add_theme_font_size_override("font_size", maxi(16, int(24 * s)))


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


func _prev_ship() -> void:
	_ship_idx = (_ship_idx - 1 + Cfg.SHIP_ORDER.size()) % Cfg.SHIP_ORDER.size()
	_update_ship_display(true)

func _next_ship() -> void:
	_ship_idx = (_ship_idx + 1) % Cfg.SHIP_ORDER.size()
	_update_ship_display(true)


func _update_ship_display(animate: bool = false) -> void:
	var ship_type: int = Cfg.SHIP_ORDER[_ship_idx]
	var def: Dictionary = Cfg.SHIP_DEFS[ship_type]
	Game.selected_ship = ship_type
	_ship_preview.texture = def.texture
	_ship_name.text = def.name
	_ship_name.modulate = def.color
	_ship_desc.text = def.desc
	var speed_label := "Fast" if def.speed > 500 else ("Medium" if def.speed > 380 else "Slow")
	var fire_label := "Rapid" if def.cooldown < 0.15 else ("Normal" if def.cooldown < 0.25 else "Slow")
	var shots_label := "Triple" if def.triple else "Single"
	_ship_stats.text = "Speed: %s  |  Fire: %s  |  Shots: %s  |  Lives: %d" % [speed_label, fire_label, shots_label, def.lives]
	if animate and _ship_tween:
		_ship_tween.kill()
	if animate:
		_ship_preview.scale = Vector2(0.6, 0.6)
		_ship_preview.modulate.a = 0.3
		_ship_tween = create_tween().set_parallel(true)
		_ship_tween.tween_property(_ship_preview, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_ship_tween.tween_property(_ship_preview, "modulate:a", 1.0, 0.2)


func _start_animations() -> void:
	if _glow_tween: _glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_title, "modulate", Palette.MENU_TITLE, 1.6)
	_glow_tween.tween_property(_title, "modulate", Palette.MENU_TITLE_GLOW, 1.6)

	if _float_tween: _float_tween.kill()
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(_title, "position:y", _title.position.y - 3, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(_title, "position:y", _title.position.y, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func appear() -> void:
	show()
	_apply_font_scale()
	_update_ship_display()
	if _glow_tween: _glow_tween.kill()
	if _float_tween: _float_tween.kill()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var children := [_title, _sub, _choose_label, _ship_row, _ship_name, _ship_desc, _ship_stats, _high, _play, _vol_row, _hint]
	var orig_y: Array = []
	for c in children:
		orig_y.append(c.position.y)
		c.modulate.a = 0.0
		c.position.y += 12

	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in children.size():
		t.tween_interval(0.05)
		t.parallel().tween_property(children[i], "modulate:a", 1.0, 0.22)
		t.parallel().tween_property(children[i], "position:y", orig_y[i], 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_start_animations)
	t.chain().tween_callback(func():
		_play.grab_focus()
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		for c in children:
			c.modulate.a = 1.0
	)


func disappear() -> void:
	if _glow_tween: _glow_tween.kill()
	if _float_tween: _float_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.2)
	t.finished.connect(hide)
