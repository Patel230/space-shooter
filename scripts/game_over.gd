class_name GameOverScreen extends CanvasLayer
## Compact game-over overlay with staggered entrance, record pulse, button hover.
## Fully responsive font scaling.

const _SFX_CLICK := preload("res://art/kenney_ui-pack/Sounds/click-b.ogg")
const _SFX_HOVER := preload("res://art/kenney_ui-pack/Sounds/switch-b.ogg")

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
var _entrance_tween: Tween


func _ready() -> void:
	_restart.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); restart_requested.emit())
	_menu.pressed.connect(func(): _play_ui_sfx(_SFX_CLICK); menu_requested.emit())
	_restart.mouse_entered.connect(func(): _hover_sfx(); _btn_hover(_restart))
	_restart.mouse_exited.connect(func(): _btn_unhover(_restart))
	_menu.mouse_entered.connect(func(): _hover_sfx(); _btn_hover(_menu))
	_menu.mouse_exited.connect(func(): _btn_unhover(_menu))
	get_viewport().size_changed.connect(_apply_font_scale)


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
	var is_record: bool = Game.last_run_is_record
	_high.text = "High Score: %d" % Game.high_score
	_record.visible = is_record
	if is_record:
		# Start hidden so the pulse entrance can animate it in cleanly.
		_record.modulate = Color(0.5, 1.0, 0.4, 0)
		_record.scale = Vector2(0.6, 0.6)
	# Let the layout settle so VBoxContainer positions are final before we
	# snapshot them for the entrance animation.
	await get_tree().process_frame
	# Cancel any in-flight tweens so a rapid game-over → restart → game-over
	# cycle doesn't leave nodes mid-animation.
	if _record_tween: _record_tween.kill()
	if _entrance_tween: _entrance_tween.kill()
	# Snapshot current layout positions (must happen AFTER layout has settled).
	var orig_positions: Dictionary = {}
	var children_to_animate: Array[Control] = [_title, _score, _high, _restart, _menu]
	for c in children_to_animate:
		orig_positions[c] = c.position.y
	show()
	# Staggered entrance — panel first
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	for c in children_to_animate:
		c.modulate.a = 0.0
		c.position.y = orig_positions[c] + 10

	_entrance_tween = create_tween()
	_entrance_tween.tween_property(_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	_entrance_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in children_to_animate.size():
		var c: Control = children_to_animate[i]
		_entrance_tween.tween_interval(0.07)
		_entrance_tween.parallel().tween_property(c, "modulate:a", 1.0, 0.25)
		_entrance_tween.parallel().tween_property(c, "position:y", orig_positions[c], 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Record label handled separately with its own pulse entrance.
	if is_record:
		_entrance_tween.chain().tween_callback(_start_record_pulse)
	# Focus after entrance
	_entrance_tween.chain().tween_callback(func():
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		for c in children_to_animate:
			c.modulate.a = 1.0
			c.position.y = orig_positions[c]
		_restart.grab_focus()
	)


func disappear() -> void:
	if _record_tween: _record_tween.kill()
	if _entrance_tween: _entrance_tween.kill()
	if _hover_tween: _hover_tween.kill()
	if not visible:
		return
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
