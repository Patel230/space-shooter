class_name GalaxyBackground extends ColorRect
## Animated procedural space galaxy background with 10 galaxy types.
## Features: rotating spiral arms, pulsing nebula clouds, shooting stars,
## dust lanes, twinkling star fields, and smooth galaxy transitions per wave.

const GALAXIES: Array = [
	{"name": "Aurora Nebula", "bg": Color(0.01, 0.02, 0.05), "nebula": [Color(0.05, 0.3, 0.4), Color(0.1, 0.5, 0.6), Color(0.0, 0.2, 0.35)], "star": Color(0.6, 0.95, 1.0), "core": Color(0.15, 0.6, 0.8), "dust": Color(0.02, 0.1, 0.15)},
	{"name": "Crimson Vortex", "bg": Color(0.05, 0.01, 0.02), "nebula": [Color(0.4, 0.08, 0.05), Color(0.6, 0.15, 0.08), Color(0.25, 0.05, 0.03)], "star": Color(1.0, 0.7, 0.6), "core": Color(0.8, 0.2, 0.15), "dust": Color(0.15, 0.03, 0.02)},
	{"name": "Golden Spiral", "bg": Color(0.04, 0.03, 0.01), "nebula": [Color(0.35, 0.25, 0.05), Color(0.5, 0.35, 0.1), Color(0.2, 0.15, 0.03)], "star": Color(1.0, 0.9, 0.6), "core": Color(0.7, 0.5, 0.15), "dust": Color(0.12, 0.08, 0.02)},
	{"name": "Violet Cosmos", "bg": Color(0.03, 0.01, 0.05), "nebula": [Color(0.25, 0.05, 0.4), Color(0.4, 0.1, 0.55), Color(0.15, 0.03, 0.25)], "star": Color(0.85, 0.7, 1.0), "core": Color(0.5, 0.15, 0.7), "dust": Color(0.08, 0.02, 0.15)},
	{"name": "Emerald Expanse", "bg": Color(0.01, 0.04, 0.02), "nebula": [Color(0.05, 0.3, 0.12), Color(0.1, 0.45, 0.2), Color(0.03, 0.2, 0.08)], "star": Color(0.7, 1.0, 0.8), "core": Color(0.15, 0.6, 0.3), "dust": Color(0.02, 0.1, 0.05)},
	{"name": "Sapphire Drift", "bg": Color(0.01, 0.02, 0.06), "nebula": [Color(0.05, 0.1, 0.4), Color(0.1, 0.2, 0.55), Color(0.03, 0.05, 0.25)], "star": Color(0.6, 0.8, 1.0), "core": Color(0.15, 0.3, 0.7), "dust": Color(0.02, 0.05, 0.15)},
	{"name": "Rose Quartz", "bg": Color(0.05, 0.02, 0.03), "nebula": [Color(0.4, 0.1, 0.2), Color(0.55, 0.15, 0.3), Color(0.25, 0.05, 0.12)], "star": Color(1.0, 0.8, 0.85), "core": Color(0.7, 0.2, 0.4), "dust": Color(0.15, 0.04, 0.06)},
	{"name": "Arctic Halo", "bg": Color(0.02, 0.03, 0.04), "nebula": [Color(0.15, 0.2, 0.3), Color(0.25, 0.3, 0.4), Color(0.1, 0.15, 0.2)], "star": Color(0.95, 0.98, 1.0), "core": Color(0.3, 0.4, 0.5), "dust": Color(0.05, 0.08, 0.12)},
	{"name": "Solar Flare", "bg": Color(0.04, 0.02, 0.0), "nebula": [Color(0.4, 0.2, 0.03), Color(0.55, 0.3, 0.05), Color(0.25, 0.12, 0.02)], "star": Color(1.0, 0.85, 0.5), "core": Color(0.8, 0.4, 0.1), "dust": Color(0.12, 0.06, 0.01)},
	{"name": "Indigo Rift", "bg": Color(0.02, 0.01, 0.04), "nebula": [Color(0.1, 0.05, 0.3), Color(0.15, 0.08, 0.4), Color(0.05, 0.03, 0.2)], "star": Color(0.65, 0.6, 1.0), "core": Color(0.2, 0.15, 0.5), "dust": Color(0.05, 0.02, 0.12)},
]

var _galaxy_idx: int = 0
var _time: float = 0.0
var _nebula_seeds: Array = []
var _star_seeds: Array = []
var _spiral_stars: Array = []
var _shooting_stars: Array = []
var _dust_seeds: Array = []
var _prev_nebula_seeds: Array = []
var _prev_star_seeds: Array = []
var _prev_spiral_stars: Array = []
var _prev_dust_seeds: Array = []
var _blend: float = 1.0
var _prev_galaxy_idx: int = 0
var _grad_tex: GradientTexture2D
var _prev_grad_tex: GradientTexture2D
var _shoot_timer: float = 0.0
var _last_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	_seed_galaxy()
	_build_gradient()
	_last_size = get_viewport_rect().size
	SignalBus.wave_changed.connect(_on_wave_changed)
	get_viewport().size_changed.connect(_on_viewport_resize)


func _on_viewport_resize() -> void:
	var new_size := get_viewport_rect().size
	if _last_size.x > 0.0 and _last_size.y > 0.0 and new_size.x > 0.0 and new_size.y > 0.0:
		var ratio := Vector2(new_size.x / _last_size.x, new_size.y / _last_size.y)
		for s: Dictionary in _nebula_seeds:
			s.pos *= ratio
		for s: Dictionary in _star_seeds:
			s.pos *= ratio
		for s: Dictionary in _dust_seeds:
			s.pos *= ratio
	_build_gradient()
	_last_size = new_size


func _seed_galaxy() -> void:
	var size := get_viewport_rect().size
	# Nebula clouds - larger, drifting
	_nebula_seeds.clear()
	for i in 5:
		_nebula_seeds.append({
			"pos": Vector2(randf() * size.x, randf() * size.y),
			"radius": randf_range(size.x * 0.2, size.x * 0.5),
			"color_idx": i % 3,
			"drift": Vector2(randf_range(-8, 8), randf_range(-4, 4)),
			"pulse_phase": randf() * TAU,
			"pulse_speed": randf_range(0.3, 0.8),
		})
	# Spiral arm stars - rotate around galactic core
	_spiral_stars.clear()
	for i in 60:
		var angle: float = randf() * TAU
		var dist: float = randf_range(30.0, size.x * 0.45)
		_spiral_stars.append({
			"angle": angle,
			"dist": dist,
			"size": randf_range(0.8, 2.5),
			"brightness": randf_range(0.4, 1.0),
			"rot_speed": randf_range(0.05, 0.15),
		})
	# Distant twinkling background stars
	_star_seeds.clear()
	for i in 120:
		_star_seeds.append({
			"pos": Vector2(randf() * size.x, randf() * size.y),
			"size": randf_range(0.5, 2.0),
			"phase": randf() * TAU,
			"speed": randf_range(1.5, 4.0),
		})
	# Dust lane particles
	_dust_seeds.clear()
	for i in 40:
		_dust_seeds.append({
			"pos": Vector2(randf() * size.x, randf() * size.y),
			"size": randf_range(1.0, 3.0),
			"drift": Vector2(randf_range(-3, 3), randf_range(-2, 2)),
			"alpha": randf_range(0.05, 0.15),
		})


func _build_gradient() -> void:
	_grad_tex = _make_gradient(_galaxy_idx)


func _make_gradient(idx: int) -> GradientTexture2D:
	var g: Dictionary = GALAXIES[idx]
	var grad := Gradient.new()
	grad.set_color(0, g.bg)
	grad.add_point(0.4, g.bg * 1.8)
	grad.add_point(0.7, g.bg * 1.2)
	grad.set_color(1, g.bg * 0.3)
	grad.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = 64
	tex.fill = 0
	return tex


func _on_wave_changed(wave: int) -> void:
	var new_idx: int = (wave - 1) % GALAXIES.size()
	if new_idx == _galaxy_idx:
		return
	_prev_galaxy_idx = _galaxy_idx
	_galaxy_idx = new_idx
	_prev_grad_tex = _grad_tex
	# Snapshot current seeds so the previous galaxy keeps its own geometry while
	# fading out.
	_prev_nebula_seeds = _nebula_seeds.duplicate(true)
	_prev_star_seeds = _star_seeds.duplicate(true)
	_prev_spiral_stars = _spiral_stars.duplicate(true)
	_prev_dust_seeds = _dust_seeds.duplicate(true)
	_seed_galaxy()
	_build_gradient()
	_blend = 0.0
	var t := create_tween()
	t.tween_property(self, "_blend", 1.0, 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	_time += delta
	# Rotate spiral stars
	for star: Dictionary in _spiral_stars:
		star.angle += star.rot_speed * delta
	for star: Dictionary in _prev_spiral_stars:
		star.angle += star.rot_speed * delta
	# Update shooting stars
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_spawn_shooting_star()
		_shoot_timer = randf_range(1.5, 4.0)
	for i in range(_shooting_stars.size() - 1, -1, -1):
		var ss: Dictionary = _shooting_stars[i]
		ss.pos += ss.vel * delta
		ss.life -= delta
		if ss.life <= 0.0:
			_shooting_stars.remove_at(i)
	queue_redraw()


func _spawn_shooting_star() -> void:
	var size := get_viewport_rect().size
	var g: Dictionary = GALAXIES[_galaxy_idx]
	var start_x := randf() * size.x
	var angle := randf_range(PI * 0.6, PI * 0.9) # diagonal downward
	var speed := randf_range(600.0, 900.0)
	_shooting_stars.append({
		"pos": Vector2(start_x, -20.0),
		"vel": Vector2(cos(angle), sin(angle)) * speed,
		"life": 1.2,
		"max_life": 1.2,
		"color": g.star,
	})


func _draw() -> void:
	var size := get_viewport_rect().size
	_draw_galaxy(size, _galaxy_idx, _grad_tex, _blend,
			_nebula_seeds, _spiral_stars, _star_seeds, _dust_seeds)
	if _blend < 1.0 and _prev_grad_tex:
		_draw_galaxy(size, _prev_galaxy_idx, _prev_grad_tex, 1.0 - _blend,
				_prev_nebula_seeds, _prev_spiral_stars, _prev_star_seeds, _prev_dust_seeds)
	_draw_shooting_stars()


func _draw_shooting_stars() -> void:
	var g: Dictionary = GALAXIES[_galaxy_idx]
	for ss: Dictionary in _shooting_stars:
		var life_t: float = ss.life / ss.max_life
		var c: Color = ss.color
		var trail_end: Vector2 = ss.pos - ss.vel.normalized() * 60.0
		for i in 8:
			var t: float = float(i) / 8.0
			var tp: Vector2 = ss.pos.lerp(trail_end, t)
			draw_circle(tp, 2.0 - t * 1.5,
					Color(c.r, c.g, c.b, life_t * (1.0 - t) * 0.6))
		draw_circle(ss.pos, 3.0, Color(c.r, c.g, c.b, life_t))


func _draw_galaxy(size: Vector2, idx: int, grad_tex: GradientTexture2D, alpha: float,
		nebula: Array, spiral: Array, stars: Array, dust: Array) -> void:
	if alpha <= 0.0:
		return
	var g: Dictionary = GALAXIES[idx]
	var core_pos := Vector2(size.x * 0.5, size.y * 0.32)
	# 1. Base gradient
	if grad_tex:
		draw_texture_rect(grad_tex, Rect2(0, 0, size.x, size.y), false)
	# 2. Dust lanes (slow drifting particles)
	var dust_color: Color = g.dust
	for d: Dictionary in dust:
		var dp: Vector2 = d.pos + d.drift * _time * 0.2
		dp.x = fposmod(dp.x, size.x + 20) - 10
		dp.y = fposmod(dp.y, size.y + 20) - 10
		draw_circle(dp, d.size, Color(dust_color.r, dust_color.g, dust_color.b, d.alpha * alpha))
	# 3. Pulsing nebula clouds
	for cloud: Dictionary in nebula:
		var pos: Vector2 = cloud.pos + cloud.drift * _time * 0.3
		pos.x = fposmod(pos.x, size.x + 200) - 100
		pos.y = fposmod(pos.y, size.y + 200) - 100
		var pulse := 0.8 + sin(_time * cloud.pulse_speed + cloud.pulse_phase) * 0.2
		var radius: float = cloud.radius * pulse
		var color: Color = g.nebula[cloud.color_idx]
		for i in 6:
			var layer_a: float = 1.0 - float(i) / 6.0
			draw_circle(pos, radius * (0.12 + i * 0.16),
					Color(color.r, color.g, color.b, 0.05 * layer_a * alpha * pulse))
	# 4. Galactic core - pulsing bright center
	var core_pulse := 0.85 + sin(_time * 0.7) * 0.15
	for i in 14:
		var a: float = 1.0 - float(i) / 14.0
		draw_circle(core_pos, (20.0 + i * 20.0) * core_pulse,
				Color(g.core.r, g.core.g, g.core.b, 0.06 * a * alpha * core_pulse))
	# 5. Spiral arm stars - rotating around core
	for star: Dictionary in spiral:
		var sp: Vector2 = core_pos + Vector2(cos(star.angle), sin(star.angle)) * star.dist
		draw_circle(sp, star.size,
				Color(g.star.r, g.star.g, g.star.b, star.brightness * alpha))
	# 6. Distant twinkling stars
	for star: Dictionary in stars:
		var twinkle: float = 0.4 + sin(_time * star.speed + star.phase) * 0.6
		draw_circle(star.pos, star.size,
				Color(g.star.r, g.star.g, g.star.b, (0.3 + twinkle * 0.7) * alpha))
