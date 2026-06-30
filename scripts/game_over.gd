class_name GameOverScreen extends CanvasLayer
## Compact game-over overlay with staggered entrance, record pulse, button hover.
## Fully responsive font scaling.

signal restart_requested
signal menu_requested

@onready var _score: Label = $Center/Panel/VBox/ScoreLabel
@onready var _high: Label = $Center/Panel/VBox/HighScoreLabel
@onready var _restart: Button = $Center/Panel/VBox/RestartButton
@onready var _menu: Button = $Center/Panel/VBox/TitleButton
@onready var _panel: Panel = $Center/Panel
@onready var _record: Label = $Center/Panel/VBox/NewRecord
@onready var _title: Label = $Center/Panel/VBox/TitleLabel

var _record_tween: Tween
var _hover_tween: Tween


func _ready() -> void:
	_restart.pressed.connect(func(): restart_requested.emit())
	_menu.pressed.connect(func(): menu_requested.emit())
	_restart.mouse_entered.connect(func(): _btn_hover(_restart))
	_restart.mouse_exited.connect(func(): _btn_unhover(_restart))
	_menu.mouse_entered.connect(func(): _btn_hover(_menu))
	_menu.mouse_exited.connect(func(): _btn_unhover(_menu))


func _btn_hover(b: Button) -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(b, "scale", Vector2(1.06, 1.06), 0.1).set_ease(Tween.EASE_OUT)

func _btn_unhover(b: Button) -> void:
	if _hover_tween: _hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(b, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_title.add_theme_font_size_override("font_size", maxi(26, int(38 * s)))
	_score.add_theme_font_size_override("font_size", maxi(18, int(26 * s)))
	_high.add_theme_font_size_override("font_size", maxi(15, int(22 * s)))
	_record.add_theme_font_size_override("font_size", maxi(14, int(20 * s)))
	_restart.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))
	_menu.add_theme_font_size_override("font_size", maxi(16, int(22 * s)))


func appear() -> void:
	_apply_font_scale()
	_score.text = "Score: %d" % Game.score
	var is_record: bool = Game.score >= Game.high_score and Game.score > 0
	_high.text = "High Score: %d" % Game.high_score
	_record.visible = is_record
	if _record_tween: _record_tween.kill()
	show()
	# Staggered entrance
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var children := [_title, _score, _high]
	var orig_y: Array = []
	for c in children:
		orig_y.append(c.position.y)
		c.modulate.a = 0.0
		c.position.y += 10
	if is_record:
		orig_y.append(_record.position.y)
		_record.modulate.a = 0.0
		_record.position.y += 10
		children.append(_record)
	# Buttons always visible
	_restart.modulate.a = 0.0
	_menu.modulate.a = 0.0
	orig_y.append(_restart.position.y)
	orig_y.append(_menu.position.y)
	_restart.position.y += 10
	_menu.position.y += 10
	children.append(_restart)
	children.append(_menu)

	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in children.size():
		t.tween_interval(0.07)
		t.parallel().tween_property(children[i], "modulate:a", 1.0, 0.25)
		t.parallel().tween_property(children[i], "position:y", orig_y[i], 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Record pulse + focus after entrance
	t.chain().tween_callback(func():
		if is_record:
			_start_record_pulse()
		_restart.grab_focus()
		# Safety: ensure everything visible
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		for c in children:
			c.modulate.a = 1.0
	)


func disappear() -> void:
	if _record_tween: _record_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.parallel().tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.2)
	t.finished.connect(hide)


func _start_record_pulse() -> void:
	if _record_tween: _record_tween.kill()
	_record.modulate = Color(0.5, 1.0, 0.4, 0)
	_record.scale = Vector2(0.6, 0.6)
	_record_tween = create_tween()
	_record_tween.set_parallel(true)
	_record_tween.tween_property(_record, "modulate:a", 1.0, 0.35)
	_record_tween.tween_property(_record, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_record_tween.chain().tween_property(_record, "modulate", Palette.GAMEOVER_RECORD_GLOW, 0.5)
	_record_tween.chain().tween_property(_record, "modulate", Palette.GAMEOVER_RECORD, 0.5)
	_record_tween.set_loops()
