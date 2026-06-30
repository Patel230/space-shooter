class_name PostFX extends CanvasLayer
## Full-screen post-processing overlay. Cycles through 4 presets and persists
## the choice via Game.fx_preset.

const SHADER := preload("res://shaders/post_fx.gdshader")

enum Preset { OFF, SUBTLE, ARCADE, CINEMATIC }

const PRESET_NAMES := {
	Preset.OFF: "OFF",
	Preset.SUBTLE: "SUBTLE",
	Preset.ARCADE: "ARCADE",
	Preset.CINEMATIC: "CINEMATIC",
}

const PRESETS := {
	Preset.OFF: {
		"vignette": 0.0, "scanline": 0.0, "scanline_count": 480.0,
		"grain": 0.0, "aberration": 0.0,
		"tint": 0.0, "tint_color": Color(1, 1, 1),
	},
	Preset.SUBTLE: {
		"vignette": 0.35, "scanline": 0.0, "scanline_count": 480.0,
		"grain": 0.04, "aberration": 0.0,
		"tint": 0.0, "tint_color": Color(1, 1, 1),
	},
	Preset.ARCADE: {
		"vignette": 0.5, "scanline": 0.22, "scanline_count": 540.0,
		"grain": 0.09, "aberration": 0.0045,
		"tint": 0.0, "tint_color": Color(1, 1, 1),
	},
	Preset.CINEMATIC: {
		"vignette": 0.55, "scanline": 0.06, "scanline_count": 720.0,
		"grain": 0.12, "aberration": 0.006,
		"tint": 0.35, "tint_color": Color(0.45, 0.75, 1.0),
	},
}

var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 100
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	# BackBufferCopy ensures SCREEN_TEXTURE has fresh content for the
	# overlay's canvas_item shader (required on gl_compatibility / web).
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	apply_preset(Game.fx_preset)
	SignalBus.fx_preset_changed.connect(apply_preset)
	set_process(true)


func _process(_delta: float) -> void:
	# Animate the grain
	_mat.set_shader_parameter("time_seed", Time.get_ticks_msec() * 0.001)


func apply_preset(idx: int) -> void:
	var p: Dictionary = PRESETS.get(idx, PRESETS[Preset.OFF])
	_mat.set_shader_parameter("vignette_strength", p.vignette)
	_mat.set_shader_parameter("scanline_strength", p.scanline)
	_mat.set_shader_parameter("scanline_count", p.scanline_count)
	_mat.set_shader_parameter("grain_strength", p.grain)
	_mat.set_shader_parameter("aberration_strength", p.aberration)
	_mat.set_shader_parameter("tint_strength", p.tint)
	_mat.set_shader_parameter("tint_color", p.tint_color)


static func preset_name(idx: int) -> String:
	return PRESET_NAMES.get(idx, "?")
