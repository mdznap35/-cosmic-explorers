shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_never, unshaded;

uniform vec4 corona_color : source_color = vec4(1.0, 0.37, 0.08, 1.0);
uniform float intensity = 0.24;
uniform float animation_time = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += noise2(p) * amplitude;
		p = p * 2.05 + vec2(11.1, 6.4);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, 2.1);
	float filaments = fbm(vec2(UV.x * 24.0 + animation_time * 0.018, UV.y * 13.0));
	float pulses = 0.72 + 0.28 * sin(UV.x * 41.0 + filaments * 5.0 + animation_time * 0.8);
	float strength = rim * (0.42 + filaments * 0.88) * pulses;
	vec3 tint = mix(corona_color.rgb * 0.72, vec3(1.0, 0.69, 0.24), filaments * 0.45);
	ALBEDO = tint;
	EMISSION = tint * (intensity * 2.2);
	ALPHA = clamp(strength * intensity, 0.0, 0.42);
}
