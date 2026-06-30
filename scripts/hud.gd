class_name HUD extends CanvasLayer
## Responsive heads-up display with juicy feedback: score pop, color flashes,
## animated banners, and combo system. Warm, vibrant color palette.

@onready var _score: Label = $ScoreLabel
@onready var _lives: Label = $LivesLabel
@onready var _wave: Label = $WaveLabel
@onready var _banner: Label = $Banner
@onready var _mute: Label = $MuteLabel
@onready var _combo: Label = $ComboLabel
var _banner_tween: Tween
var _score_tween: Tween
var _lives_tween: Tween
var _wave_tween: Tween
var _combo_tween: Tween
var _combo_count: int = 0
var _combo_timer: float = 0.0

const COMBO_TIMEOUT := 2.0


func _ready() -> void:
	SignalBus.score_changed.connect(_on_score_changed)
	SignalBus.lives_changed.connect(_on_lives_changed)
	SignalBus.wave_changed.connect(_on_wave_changed)
	SignalBus.banner_requested.connect(_show_banner)
	SignalBus.mute_changed.connect(func(m): _mute.visible = m)
	_mute.visible = Game.mute
	_combo.visible = false


func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_hide_combo()


func _on_score_changed(s: int) -> void:
	_score.text = "SCORE: %d" % s
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	_show_combo()
	if _score_tween:
		_score_tween.kill()
	_score.scale = Vector2(1.3, 1.3)
	_score.modulate = Palette.SCORE_FLASH
	_score_tween = create_tween()
	_score_tween.set_parallel(true)
	_score_tween.tween_property(_score, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(_score, "modulate", Palette.SCORE_COLOR, 0.2)


func _on_lives_changed(l: int) -> void:
	_lives.text = "LIVES: %d" % l
	if _lives_tween:
		_lives_tween.kill()
	_lives.scale = Vector2(1.4, 1.4)
	if l <= 1:
		_lives.modulate = Palette.LIVES_DANGER
		_lives_tween = create_tween().set_loops(3)
		_lives_tween.tween_property(_lives, "modulate:a", 0.3, 0.15)
		_lives_tween.tween_property(_lives, "modulate:a", 1.0, 0.15)
		_lives_tween.chain().tween_property(_lives, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_lives.modulate = Palette.LIVES_COLOR
		_lives_tween = create_tween()
		_lives_tween.tween_property(_lives, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_wave_changed(w: int) -> void:
	_wave.text = "WAVE: %d" % w
	if _wave_tween:
		_wave_tween.kill()
	_wave.scale = Vector2(1.3, 1.3)
	_wave.modulate = Palette.WAVE_FLASH
	_wave_tween = create_tween().set_parallel(true)
	_wave_tween.tween_property(_wave, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wave_tween.tween_property(_wave, "modulate", Palette.WAVE_COLOR, 0.3)


func _show_combo() -> void:
	if _combo_count < 3:
		return
	_combo.text = "x%d COMBO!" % _combo_count
	_combo.visible = true
	_combo.modulate = Palette.COMBO_COLORS[(_combo_count - 3) % Palette.COMBO_COLORS.size()]
	if _combo_tween:
		_combo_tween.kill()
	_combo.scale = Vector2(1.5, 1.5)
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_combo() -> void:
	_combo_count = 0
	if _combo_tween:
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "modulate:a", 0.0, 0.3)
	_combo_tween.finished.connect(func(): _combo.visible = false; _combo.modulate.a = 1.0)


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.show()
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate = Color(Palette.BANNER_COLOR.r, Palette.BANNER_COLOR.g, Palette.BANNER_COLOR.b, 0.0)
	_banner.scale = Vector2(0.7, 0.7)
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.4)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.chain().tween_property(_banner, "scale", Vector2(1.2, 1.2), 0.4)
	_banner_tween.finished.connect(_banner.hide)
