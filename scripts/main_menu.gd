class_name MainMenu extends CanvasLayer
## Title screen with glowing animated title, volume slider, and smooth transitions.
## Warm gold/amber/magenta color palette.

signal start_requested

const TITLE_GLOW_A := Color(0.3, 0.95, 0.85)
const TITLE_GLOW_B := Color(0.65, 1.0, 0.95)

@onready var _high: Label = $Panel/VBox/HighScoreLabel
@onready var _play: Button = $Panel/VBox/PlayButton
@onready var _title: Label = $Panel/VBox/TitleLabel
@onready var _panel: Panel = $Panel
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeRow/VolumeSlider
@onready var _volume_percent: Label = $Panel/VBox/VolumeRow/VolumePercent
var _glow_tween: Tween


func _ready() -> void:
	_play.pressed.connect(func(): start_requested.emit())
	SignalBus.high_score_changed.connect(func(h): _high.text = "High Score: %d" % h)
	_high.text = "High Score: %d" % Game.high_score
	_volume_slider.value = Game.volume * 100.0
	_volume_percent.text = "%d%%" % int(Game.volume * 100.0)
	_volume_slider.value_changed.connect(_on_volume_changed)


func _on_volume_changed(value: float) -> void:
	_volume_percent.text = "%d%%" % int(value)
	Game.set_volume(value / 100.0)


func _start_glow() -> void:
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_title, "modulate", TITLE_GLOW_A, 1.4)
	_glow_tween.tween_property(_title, "modulate", TITLE_GLOW_B, 1.4)


func appear() -> void:
	show()
	_play.grab_focus()
	_start_glow()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear() -> void:
	if _glow_tween:
		_glow_tween.kill()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.22)
	t.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.22)
	t.finished.connect(hide)
