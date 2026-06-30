class_name Responsive
## Static helpers for cross-platform responsive layout and font scaling.
## Works on macOS, Linux, Android, iPhone and Web.

const TOUCH_PLATFORMS := ["Android", "iOS", "Web"]
const BASE_WIDTH := 720.0
const BASE_HEIGHT := 1280.0


static func get_viewport_rect() -> Rect2:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.get_root():
		return tree.get_root().get_visible_rect()
	return Rect2(0, 0, BASE_WIDTH, BASE_HEIGHT)


## True when the current platform is primarily touch-driven.
static func is_touch_device() -> bool:
	return OS.get_name() in TOUCH_PLATFORMS


## Scale factor based on viewport vs base design resolution.
## Returns ~1.0 at 720x1280, scales down on smaller screens, up on larger.
static func ui_scale() -> float:
	var vp := get_viewport_rect().size
	# Use the smaller dimension ratio so text fits on narrow screens
	var sx := vp.x / BASE_WIDTH
	var sy := vp.y / BASE_HEIGHT
	var s := minf(sx, sy)
	# Clamp to reasonable bounds
	return clampf(s, 0.55, 1.8)


## Scaled font size: base_size adjusted for viewport.
static func font_size(base: int) -> int:
	return maxi(10, int(float(base) * ui_scale()))


## Clamp a position so a sprite of `half_size` stays fully on-screen.
static func clamp_to_screen(pos: Vector2, half_size: Vector2) -> Vector2:
	var size := get_viewport_rect().size
	return pos.clamp(half_size, size - half_size)


## Player spawn position, anchored to bottom-center of the screen.
static func player_start() -> Vector2:
	var size := get_viewport_rect().size
	return Vector2(size.x * 0.5, size.y * Cfg.PLAYER_START_Y_RATIO)


## Random x within horizontal margins.
static func random_x(margin: float = 70.0) -> float:
	var size := get_viewport_rect().size
	return randf_range(margin, size.x - margin)
