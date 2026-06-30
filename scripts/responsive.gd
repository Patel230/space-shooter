class_name Responsive
## Static helpers for cross-platform responsive layout.
## Works on macOS, Linux, Android, iPhone and Web by reading the live
## viewport rect and detecting touch capability at runtime.

const TOUCH_PLATFORMS := ["Android", "iOS", "Web"]


static func get_viewport_rect() -> Rect2:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.get_root():
		return tree.get_root().get_visible_rect()
	return Rect2(0, 0, Cfg.BASE_WIDTH, Cfg.BASE_HEIGHT)


## True when the current platform is primarily touch-driven.
static func is_touch_device() -> bool:
	return OS.get_name() in TOUCH_PLATFORMS


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
