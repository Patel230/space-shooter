class_name Starfield extends Node2D
## Multi-layer parallax starfield with colorful variety, depth, and streaking.
## 3 layers: distant (slow, dim, twinkle), mid (medium), near (fast, streaks).

const LAYER_CONFIGS := [
	{"count": 60, "speed_min": 15.0, "speed_max": 50.0, "size_min": 0.5, "size_max": 1.2, "alpha_min": 0.2, "alpha_max": 0.5, "streak": false},
	{"count": 35, "speed_min": 50.0, "speed_max": 120.0, "size_min": 1.0, "size_max": 2.0, "alpha_min": 0.4, "alpha_max": 0.8, "streak": false},
	{"count": 20, "speed_min": 120.0, "speed_max": 240.0, "size_min": 1.5, "size_max": 3.0, "alpha_min": 0.6, "alpha_max": 1.0, "streak": true},
]

const STAR_COLORS := [
	Color(0.6, 0.8, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 0.9, 0.6),
	Color(0.8, 0.7, 1.0),
	Color(0.5, 1.0, 0.9),
	Color(1.0, 0.8, 0.7),
]

var _layers: Array = []


func _ready() -> void:
	_populate()
	get_viewport().size_changed.connect(_populate)


func _populate() -> void:
	var size := Responsive.get_viewport_rect().size
	_layers.clear()
	for cfg in LAYER_CONFIGS:
		var stars: Array = []
		for i in cfg.count:
			stars.append({
				"pos": Vector2(randf() * size.x, randf() * size.y),
				"speed": randf_range(cfg.speed_min, cfg.speed_max),
				"size": randf_range(cfg.size_min, cfg.size_max),
				"alpha": randf_range(cfg.alpha_min, cfg.alpha_max),
				"color": STAR_COLORS.pick_random(),
				"twinkle_phase": randf() * TAU,
				"twinkle_speed": randf_range(2.0, 5.0),
			})
		_layers.append({"streak": cfg.streak, "stars": stars})


func _process(delta: float) -> void:
	var size := Responsive.get_viewport_rect().size
	for layer in _layers:
		for star: Dictionary in layer.stars:
			star.pos.y += star.speed * delta
			if star.pos.y > size.y + 20.0:
				star.pos.y = -20.0
				star.pos.x = randf() * size.x
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for layer in _layers:
		var streak: bool = layer.streak
		for star: Dictionary in layer.stars:
			var twinkle := 0.7 + sin(t * star.twinkle_speed + star.twinkle_phase) * 0.3
			var c: Color = star.color
			var a: float = star.alpha * twinkle
			if streak:
				var streak_len: float = star.speed * 0.04
				draw_line(star.pos, Vector2(star.pos.x, star.pos.y - streak_len),
						Color(c.r, c.g, c.b, a * 0.5), star.size)
			draw_circle(star.pos, star.size, Color(c.r, c.g, c.b, a))
