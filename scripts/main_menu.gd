class_name MainMenu extends CanvasLayer
## Title screen with Godot 4.7 branding, glowing animated title and smooth
## enter/exit transitions. Emits start_requested.

signal start_requested

const GODOT_CYAN := Color(0.45, 0.85, 1, 1)

@onready var _high: Label = $Panel/VBox/HighScoreLabel
@onready var _play: Button = $Panel/VBox/PlayButton
@onready var _title: Label = $Panel/VBox/TitleLabel
@onready var _panel: Panel = $Panel
var _glow_tween: Tween


func _ready() -> void:
	_play.pressed.connect(func(): start_requested.emit())
	SignalBus.high_score_changed.connect(func(h): _high.text = "High Score: %d" % h)
	_high.text = "High Score: %d" % Game.high_score


func _start_glow() -> void:
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_title, "modulate", GODOT_CYAN, 1.2)
	_glow_tween.tween_property(_title, "modulate", Color.WHITE, 1.2)


func appear() -> void:
	show()
	_play.grab_focus()
	_start_glow()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "modulate:a", 1.0, 0.3)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear() -> void:
	if _glow_tween:
		_glow_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.2)
	t.finished.connect(hide)
