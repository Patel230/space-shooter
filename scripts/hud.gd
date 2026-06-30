class_name HUD extends CanvasLayer
## Compact, responsive HUD with juicy feedback: score pop, rolling counter,
## color flashes, animated banners, combo system. Scales fonts to viewport.

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
var _displayed_score: int = 0

const COMBO_TIMEOUT := 2.0


func _ready() -> void:
	_apply_font_scale()
	get_viewport().size_changed.connect(_apply_font_scale)
	SignalBus.score_changed.connect(_on_score_changed)
	SignalBus.lives_changed.connect(_on_lives_changed)
	SignalBus.wave_changed.connect(_on_wave_changed)
	SignalBus.banner_requested.connect(_show_banner)
	SignalBus.mute_changed.connect(func(m): _mute.visible = m)
	SignalBus.state_changed.connect(_on_state_changed)
	_mute.visible = Game.mute
	_combo.visible = false
	_banner.visible = false
	_apply_state_visibility(Game.get_state())


func _on_state_changed(state: int) -> void:
	_apply_state_visibility(state)


func _apply_state_visibility(state: int) -> void:
	# Hide the gameplay HUD on menu / game-over screens, but keep the mute
	# indicator available across all states.
	var playing := state == Game.State.PLAYING
	_score.visible = playing
	_wave.visible = playing
	_lives.visible = playing
	if playing:
		# Snap the rolling counter so a restart doesn't carry over the previous
		# run's displayed score.
		_displayed_score = Game.score
		_score.text = "SCORE: %d" % _displayed_score
	else:
		_combo.visible = false
		_combo_count = 0
		_combo_timer = 0.0
		_kill_all_banner_tweens()
		_banner.visible = false


func _kill_all_banner_tweens() -> void:
	if _banner_tween:
		_banner_tween.kill()
		_banner_tween = null


func _apply_font_scale() -> void:
	var s := Responsive.ui_scale()
	_score.add_theme_font_size_override("font_size", maxi(18, int(26 * s)))
	_wave.add_theme_font_size_override("font_size", maxi(18, int(26 * s)))
	_lives.add_theme_font_size_override("font_size", maxi(18, int(26 * s)))
	_combo.add_theme_font_size_override("font_size", maxi(18, int(26 * s)))
	_banner.add_theme_font_size_override("font_size", maxi(28, int(42 * s)))
	_mute.add_theme_font_size_override("font_size", maxi(12, int(18 * s)))


func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_hide_combo()
	# Rolling score counter
	if _displayed_score < Game.score:
		var diff := Game.score - _displayed_score
		var step := maxi(1, int(diff * 12 * delta))
		_displayed_score = mini(_displayed_score + step, Game.score)
		_score.text = "SCORE: %d" % _displayed_score


func _on_score_changed(s: int) -> void:
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	_show_combo()
	if _score_tween: _score_tween.kill()
	_score.scale = Vector2(1.35, 1.35)
	_score.modulate = Palette.SCORE_FLASH
	_score_tween = create_tween()
	_score_tween.set_parallel(true)
	_score_tween.tween_property(_score, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(_score, "modulate", Palette.SCORE_COLOR, 0.2)
	# Add a slight rotation wiggle
	_score.rotation = 0.08
	_score_tween.tween_property(_score, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_lives_changed(l: int) -> void:
	_lives.text = "LIVES: %d" % l
	if _lives_tween: _lives_tween.kill()
	_lives.scale = Vector2(1.3, 1.3)
	if l <= 1:
		_lives.modulate = Palette.LIVES_DANGER
		_lives_tween = create_tween().set_loops(3)
		_lives_tween.tween_property(_lives, "modulate:a", 0.3, 0.12)
		_lives_tween.tween_property(_lives, "modulate:a", 1.0, 0.12)
		_lives_tween.chain().tween_property(_lives, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_lives.modulate = Palette.LIVES_COLOR
		_lives_tween = create_tween()
		_lives_tween.tween_property(_lives, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_wave_changed(w: int) -> void:
	_wave.text = "WAVE: %d" % w
	if _wave_tween: _wave_tween.kill()
	_wave.scale = Vector2(1.25, 1.25)
	_wave.modulate = Palette.WAVE_FLASH
	_wave_tween = create_tween().set_parallel(true)
	_wave_tween.tween_property(_wave, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wave_tween.tween_property(_wave, "modulate", Palette.WAVE_COLOR, 0.25)


func _show_combo() -> void:
	if _combo_count < 3:
		return
	_combo.text = "x%d COMBO!" % _combo_count
	_combo.visible = true
	_combo.modulate = Palette.COMBO_COLORS[(_combo_count - 3) % Palette.COMBO_COLORS.size()]
	if _combo_tween: _combo_tween.kill()
	_combo.scale = Vector2(1.4, 1.4)
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_combo() -> void:
	_combo_count = 0
	if _combo_tween: _combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "modulate:a", 0.0, 0.25)
	_combo_tween.finished.connect(func(): _combo.visible = false; _combo.modulate.a = 1.0)


func _show_banner(text: String, color: Color = Palette.BANNER_COLOR) -> void:
	# Banners only make sense while playing — drop late emits arriving during
	# state transitions.
	if Game.get_state() != Game.State.PLAYING:
		return
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	# Subtle shadow that matches the banner color for a glow effect.
	var shadow := Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.8)
	_banner.add_theme_color_override("font_shadow_color", shadow)
	_banner.show()
	if _banner_tween: _banner_tween.kill()
	_banner.modulate = Color(1, 1, 1, 0.0)
	_banner.scale = Vector2(0.7, 0.7)
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.2)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.35)
	_banner_tween.chain().tween_property(_banner, "scale", Vector2(1.15, 1.15), 0.35)
	_banner_tween.finished.connect(_banner.hide)
