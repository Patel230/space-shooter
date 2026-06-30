class_name GameOverScreen extends CanvasLayer
## Game-over overlay with dramatic colors, new record indicator, and smooth transitions.

signal restart_requested
signal menu_requested

@onready var _score: Label = $Panel/VBox/ScoreLabel
@onready var _high: Label = $Panel/VBox/HighScoreLabel
@onready var _restart: Button = $Panel/VBox/RestartButton
@onready var _menu: Button = $Panel/VBox/TitleButton
@onready var _panel: Panel = $Panel
@onready var _record: Label = $Panel/VBox/NewRecord
var _record_tween: Tween


func _ready() -> void:
	_restart.pressed.connect(func(): restart_requested.emit())
	_menu.pressed.connect(func(): menu_requested.emit())


func appear() -> void:
	_score.text = "Score: %d" % Game.score
	var is_record: bool = Game.score >= Game.high_score and Game.score > 0
	if is_record:
		_high.text = "High Score: %d" % Game.high_score
		_record.visible = true
		_start_record_pulse()
	else:
		_high.text = "High Score: %d" % Game.high_score
		_record.visible = false
	show()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_restart.grab_focus()


func disappear() -> void:
	if _record_tween:
		_record_tween.kill()
	hide()


func _start_record_pulse() -> void:
	if _record_tween:
		_record_tween.kill()
	_record.modulate = Color(0.55, 1.0, 0.35, 0)
	_record.scale = Vector2(0.5, 0.5)
	_record_tween = create_tween()
	_record_tween.set_parallel(true)
	_record_tween.tween_property(_record, "modulate:a", 1.0, 0.4)
	_record_tween.tween_property(_record, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_record_tween.chain().tween_property(_record, "modulate", Color(0.3, 1.0, 0.2), 0.5)
	_record_tween.chain().tween_property(_record, "modulate", Color(0.55, 1.0, 0.35), 0.5)
	_record_tween.set_loops()
