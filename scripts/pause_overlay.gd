extends CanvasLayer
## Pause overlay with Resume, Restart, and Quit buttons.

signal resume_requested
signal restart_requested
signal menu_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	layer = 50

	var panel := Panel.new()
	panel.size = Vector2(400, 380)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	bg.corner_radius_top_left = 16
	bg.corner_radius_top_right = 16
	bg.corner_radius_bottom_right = 16
	bg.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.5, 0.95, 0.85))
	vb.add_child(title)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(200, 2)
	sep.color = Color(0.3, 0.6, 0.7, 0.3)
	sep.size = Vector2(200, 2)
	vb.add_child(sep)

	var resume := Button.new()
	resume.text = "Resume"
	_style_button(resume)
	resume.pressed.connect(func(): resume_requested.emit())
	vb.add_child(resume)

	var restart := Button.new()
	restart.text = "Restart"
	_style_button(restart)
	restart.pressed.connect(func(): restart_requested.emit())
	vb.add_child(restart)

	var quit := Button.new()
	quit.text = "Main Menu"
	_style_button(quit)
	quit.pressed.connect(func(): menu_requested.emit())
	vb.add_child(quit)

	var shake_btn := Button.new()
	shake_btn.text = "Screen Shake: ON" if Game.screen_shake else "Screen Shake: OFF"
	_style_button_small(shake_btn)
	shake_btn.pressed.connect(func():
		Game.toggle_screen_shake()
		shake_btn.text = "Screen Shake: ON" if Game.screen_shake else "Screen Shake: OFF"
	)
	vb.add_child(shake_btn)

	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vb.add_child(hint)

	add_child(panel)

	# Center after first frame so viewport size is valid
	await get_tree().process_frame
	panel.position = (get_viewport().get_visible_rect().size - panel.size) * 0.5


func _style_button(b: Button) -> void:
	b.custom_minimum_size = Vector2(240, 48)
	b.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.2, 0.6)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.3, 0.6, 0.7, 0.4)
	var hovered := normal.duplicate()
	hovered.bg_color = Color(0.15, 0.25, 0.35, 0.8)
	hovered.border_color = Color(0.5, 0.9, 1.0, 0.7)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hovered)


func _style_button_small(b: Button) -> void:
	b.custom_minimum_size = Vector2(180, 36)
	b.add_theme_font_size_override("font_size", 16)


func appear() -> void:
	visible = true


func disappear() -> void:
	visible = false
