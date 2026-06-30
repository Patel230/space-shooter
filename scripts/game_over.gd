class_name GameOverScreen extends CanvasLayer
## Game-over overlay with smooth enter transition. Emits restart/menu signals.

signal restart_requested
signal menu_requested

@onready var _score: Label = $Panel/VBox/ScoreLabel
@onready var _high: Label = $Panel/VBox/HighScoreLabel
@onready var _restart: Button = $Panel/VBox/RestartButton
@onready var _menu: Button = $Panel/VBox/TitleButton
@onready var _panel: Panel = $Panel


func _ready() -> void:
	_restart.pressed.connect(func(): restart_requested.emit())
	_menu.pressed.connect(func(): menu_requested.emit())


func appear() -> void:
	_score.text = "Score: %d" % Game.score
	_high.text = "High Score: %d" % Game.high_score
	show()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "modulate:a", 1.0, 0.35)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_restart.grab_focus()


func disappear() -> void:
	hide()
