class_name MainMenu extends CanvasLayer
## Welcome screen: landscape hero layout with ship carousel + stat bars.

signal start_requested

@onready var _panel: Panel = $Center/Panel
@onready var _title: Label = $Center/Panel/Outer/TitleLabel
@onready var _sub: Label = $Center/Panel/Outer/SubLabel
@onready var _choose_label: Label = $Center/Panel/Outer/Body/LeftCol/ChooseShipLabel
@onready var _left_btn: Button = $Center/Panel/Outer/Body/LeftCol/ShipRow/LeftBtn
@onready var _right_btn: Button = $Center/Panel/Outer/Body/LeftCol/ShipRow/RightBtn
@onready var _ship_frame: Panel = $Center/Panel/Outer/Body/LeftCol/ShipRow/ShipFrame
@onready var _ship_glow: ColorRect = $Center/Panel/Outer/Body/LeftCol/ShipRow/ShipFrame/ShipGlow
@onready var _ship_preview: TextureRect = $Center/Panel/Outer/Body/LeftCol/ShipRow/ShipFrame/ShipPreview
@onready var _ship_name: Label = $Center/Panel/Outer/Body/LeftCol/ShipNameLabel
@onready var _ship_desc: Label = $Center/Panel/Outer/Body/LeftCol/ShipDescLabel
@onready var _speed_bar: ProgressBar = $Center/Panel/Outer/Body/RightCol/StatsBox/SpeedRow/SpeedBar
@onready var _fire_bar: ProgressBar = $Center/Panel/Outer/Body/RightCol/StatsBox/FireRow/FireBar
@onready var _lives_bar: ProgressBar = $Center/Panel/Outer/Body/RightCol/StatsBox/LivesRow/LivesBar
@onready var _shots_value: Label = $Center/Panel/Outer/Body/RightCol/StatsBox/ShotsRow/ShotsValue
@onready var _high: Label = $Center/Panel/Outer/Body/RightCol/HighScoreLabel
@onready var _play: Button = $Center/Panel/Outer/Body/RightCol/PlayButton
@onready var _vol_row: HBoxContainer = $Center/Panel/Outer/Footer/VolumeRow
@onready var _vol_slider: HSlider = $Center/Panel/Outer/Footer/VolumeRow/VolumeSlider
@onready var _vol_pct: Label = $Center/Panel/Outer/Footer/VolumeRow/VolumePercent
@onready var _fx_label: Label = $Center/Panel/Outer/Footer/FxRow/FxLabel
@onready var _fx_button: Button = $Center/Panel/Outer/Footer/FxRow/FxButton
@onready var _hint: Label = $Center/Panel/Outer/Footer/HintLabel
const _PostFX := preload("res://scripts/post_fx.gd")
const _SFX_CLICK := preload("res://art/kenney_ui-pack/Sounds/click-a.ogg")
const _SFX_HOVER := preload("res://art/kenney_ui-pack/Sounds/switch-a.ogg")
@onready var _body: BoxContainer = $Center/Panel/Outer/Body
@onready var _left_col: VBoxContainer = $Center/Panel/Outer/Body/LeftCol
@onready var _right_col: VBoxContainer = $Center/Panel/Outer/Body/RightCol
@onready var _ship_row: HBoxContainer = $Center/Panel/Outer/Body/LeftCol/ShipRow

# Aspect ratio below which the body collapses into a single column.
const NARROW_ASPECT := 1.05

var _glow_tween: Tween
var _hover_tween: Tween
var _pulse_tween: Tween
var _ship_idx: int = 0
var _ship_tween: Tween

const SHIP_SPEED_MIN := 300.0
const SHIP_SPEED_MAX := 600.0
const SHIP_COOLDOWN_FAST := 0.10
const SHIP_COOLDOWN_SLOW := 0.32


func _ready() -> void:
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)
	_play.pressed.connect(func():
		_play_ui_sfx(_SFX_CLICK)
		start_requested.emit()
	)
	_play.mouse_entered.connect(_on_play_hover)
	_play.mouse_exited.connect(_on_play_unhover)
	_left_btn.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); _prev_ship())
	_right_btn.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); _next_ship())
	_left_btn.mouse_entered.connect(_hover_sfx)
	_right_btn.mouse_entered.connect(_hover_sfx)
	SignalBus.high_score_changed.connect(func(h): _high.text = "HIGH SCORE  %d" % h)
	_high.text = "HIGH SCORE  %d" % Game.high_score
	_vol_slider.value = Game.volume * 100.0
	_vol_pct.text = "%d%%" % int(Game.volume * 100.0)
	_vol_slider.value_changed.connect(_on_volume_changed)
	_fx_button.text = _PostFX.preset_name(Game.fx_preset)
	_fx_button.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); _cycle_fx_preset())
	_fx_button.mouse_entered.connect(_hover_sfx)
	_ship_idx = Cfg.SHIP_ORDER.find(Game.selected_ship)
	if _ship_idx < 0: _ship_idx = 1
	_update_ship_display()


func _apply_layout() -> void:
	_apply_font_scale()
	_apply_orientation()


func _apply_orientation() -> void:
	# Stack vertically when the panel is narrower than it is tall (phones in
	# portrait, narrow browser windows). The HBoxContainer still arranges its
	# children left-to-right in code, but vertical_layout swaps the layout
	# direction.
	var vp := Responsive.get_viewport_rect().size
	var narrow := vp.x / maxf(vp.y, 1.0) < NARROW_ASPECT
	_body.vertical = narrow
	# Tighter ship frame on narrow screens so it doesn't dominate the column.
	var s := Responsive.ui_scale()
	var frame_size := 150.0 if narrow else 190.0
	_ship_frame.custom_minimum_size = Vector2(frame_size, frame_size) * s
	_ship_row.custom_minimum_size.y = (170.0 if narrow else 200.0) * s
	# On portrait, give arrows a square hit box; on landscape keep them tall.
	var arrow_h := 80.0 if narrow else 110.0
	_left_btn.custom_minimum_size = Vector2(56, arrow_h) * s
	_right_btn.custom_minimum_size = Vector2(56, arrow_h) * s


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_title.add_theme_font_size_override("font_size", maxi(34, int(56 * s)))
	_sub.add_theme_font_size_override("font_size", maxi(13, int(18 * s)))
	_high.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))
	_play.add_theme_font_size_override("font_size", maxi(22, int(32 * s)))
	_hint.add_theme_font_size_override("font_size", maxi(11, int(14 * s)))
	_vol_pct.add_theme_font_size_override("font_size", maxi(16, int(20 * s)))
	_fx_label.add_theme_font_size_override("font_size", maxi(14, int(18 * s)))
	_fx_button.add_theme_font_size_override("font_size", maxi(14, int(18 * s)))
	_choose_label.add_theme_font_size_override("font_size", maxi(13, int(18 * s)))
	_ship_name.add_theme_font_size_override("font_size", maxi(20, int(28 * s)))
	_ship_desc.add_theme_font_size_override("font_size", maxi(12, int(16 * s)))
	_left_btn.add_theme_font_size_override("font_size", maxi(26, int(36 * s)))
	_right_btn.add_theme_font_size_override("font_size", maxi(26, int(36 * s)))


func _on_volume_changed(value: float) -> void:
	_vol_pct.text = "%d%%" % int(value)
	Game.set_volume(value / 100.0)


func _cycle_fx_preset() -> void:
	var next := (Game.fx_preset + 1) % 4
	Game.set_fx_preset(next)
	_fx_button.text = _PostFX.preset_name(next)


func _on_play_hover() -> void:
	_hover_sfx()
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(_play, "scale", Vector2(1.04, 1.04), 0.12).set_ease(Tween.EASE_OUT)

func _on_play_unhover() -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(_play, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)


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


func _prev_ship() -> void:
	_ship_idx = (_ship_idx - 1 + Cfg.SHIP_ORDER.size()) % Cfg.SHIP_ORDER.size()
	_update_ship_display(true)

func _next_ship() -> void:
	_ship_idx = (_ship_idx + 1) % Cfg.SHIP_ORDER.size()
	_update_ship_display(true)


func _update_ship_display(animate: bool = false) -> void:
	var ship_type: int = Cfg.SHIP_ORDER[_ship_idx]
	var def: Dictionary = Cfg.SHIP_DEFS[ship_type]
	Game.set_selected_ship(ship_type)
	_ship_preview.texture = def.texture
	_ship_name.text = def.name
	_ship_name.modulate = def.color
	_ship_desc.text = def.desc

	var ship_color: Color = def.color
	_ship_glow.color = Color(ship_color.r, ship_color.g, ship_color.b, 0.22)
	_speed_bar.modulate = ship_color
	_fire_bar.modulate = ship_color
	_lives_bar.modulate = ship_color
	_shots_value.modulate = ship_color

	var speed_pct := remap(def.speed, SHIP_SPEED_MIN, SHIP_SPEED_MAX, 25.0, 100.0)
	var fire_pct := remap(def.cooldown, SHIP_COOLDOWN_SLOW, SHIP_COOLDOWN_FAST, 25.0, 100.0)
	var lives_pct := clampf(float(def.lives) / 5.0 * 100.0, 20.0, 100.0)
	_speed_bar.value = clampf(speed_pct, 10.0, 100.0)
	_fire_bar.value = clampf(fire_pct, 10.0, 100.0)
	_lives_bar.value = lives_pct
	_shots_value.text = "TRIPLE" if def.triple else "SINGLE"

	if animate and _ship_tween:
		_ship_tween.kill()
	if animate:
		_ship_preview.scale = Vector2(0.65, 0.65)
		_ship_preview.modulate.a = 0.3
		_ship_tween = create_tween().set_parallel(true)
		_ship_tween.tween_property(_ship_preview, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_ship_tween.tween_property(_ship_preview, "modulate:a", 1.0, 0.22)


func _start_animations() -> void:
	if _glow_tween: _glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_title, "modulate", Color(0.75, 1.0, 0.95, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	if _pulse_tween: _pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_ship_glow, "modulate:a", 1.4, 1.8).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_ship_glow, "modulate:a", 0.8, 1.8).set_trans(Tween.TRANS_SINE)


func appear() -> void:
	show()
	_apply_layout()
	_update_ship_display()
	if _glow_tween: _glow_tween.kill()
	if _pulse_tween: _pulse_tween.kill()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.94, 0.94)

	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_start_animations)
	t.chain().tween_callback(func():
		_play.grab_focus()
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
	)


func disappear() -> void:
	if _glow_tween: _glow_tween.kill()
	if _pulse_tween: _pulse_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.2)
	t.finished.connect(hide)
