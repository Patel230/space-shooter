shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
// Full-screen post-processing for the space shooter.
// Effects (each controllable by an intensity uniform):
//   * Vignette - dark corner fade
//   * Scanlines - CRT horizontal lines
//   * Film grain - animated noise
//   * Chromatic aberration - RGB channel separation toward edges
//   * Color tint - global hue shift toward a configurable color
//
// All inputs are clamped 0..1. Setting all to 0.0 produces a pass-through.

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count : hint_range(50.0, 1200.0) = 480.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.08;
uniform float aberration_strength : hint_range(0.0, 0.02) = 0.003;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.45, 0.85, 1.0, 1.0);
uniform float time_seed = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);

	// Chromatic aberration - sample R/B offset toward edges
	vec3 col;
	if (aberration_strength > 0.0001) {
		float dist = length(centered);
		vec2 dir = centered * aberration_strength * dist * 2.0;
		col.r = texture(SCREEN_TEXTURE, uv - dir).r;
		col.g = texture(SCREEN_TEXTURE, uv).g;
		col.b = texture(SCREEN_TEXTURE, uv + dir).b;
	} else {
		col = texture(SCREEN_TEXTURE, uv).rgb;
	}

	// Color tint - lerp toward the tint color
	if (tint_strength > 0.0001) {
		col = mix(col, col * tint_color.rgb * 1.6, tint_strength);
	}

	// Scanlines - horizontal sin wave darkening
	if (scanline_strength > 0.0001) {
		float lines = sin(uv.y * scanline_count * 3.14159);
		col *= 1.0 - scanline_strength * (0.5 - 0.5 * lines);
	}

	// Film grain - per-pixel animated noise
	if (grain_strength > 0.0001) {
		float n = hash21(uv * (1.0 / SCREEN_PIXEL_SIZE) + vec2(time_seed));
		col += (n - 0.5) * grain_strength;
	}

	// Vignette - radial dark fade
	if (vignette_strength > 0.0001) {
		float vig = smoothstep(0.85, 0.2, length(centered));
		col *= mix(1.0, vig, vignette_strength);
	}

	COLOR = vec4(col, 1.0);
}
