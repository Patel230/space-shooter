class_name HUD extends CanvasLayer
## Responsive heads-up display. Binds to SignalBus for live updates.
## All elements use anchors so the layout adapts to any screen size.

@onready var _score: Label = $ScoreLabel
@onready var _lives: Label = $LivesLabel
@onready var _wave: Label = $WaveLabel
@onready var _banner: Label = $Banner
@onready var _mute: Label = $MuteLabel
var _banner_tween: Tween


func _ready() -> void:
	SignalBus.score_changed.connect(func(s): _score.text = "Score: %d" % s)
	SignalBus.lives_changed.connect(func(l): _lives.text = "Lives: %d" % l)
	SignalBus.wave_changed.connect(func(w): _wave.text = "Wave: %d" % w)
	SignalBus.banner_requested.connect(_show_banner)
	SignalBus.mute_changed.connect(func(m): _mute.visible = m)
	_mute.visible = Game.mute


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.show()
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(1.2)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.finished.connect(_banner.hide)
