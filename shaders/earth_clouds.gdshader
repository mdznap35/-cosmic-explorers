shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never;

uniform vec4 cloud_color : source_color = vec4(0.88, 0.94, 1.0, 1.0);
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
	for (int i = 0; i < 4; i++) {
		value += noise2(p) * amplitude;
		p = p * 2.02 + vec2(13.7, 8.3);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 flowing_uv = vec2(UV.x + animation_time * 0.0018, UV.y);
	float broad = fbm(flowing_uv * vec2(18.0, 9.0));
	float detail = fbm(flowing_uv * vec2(52.0, 28.0));
	float wisps = fbm(flowing_uv * vec2(88.0, 42.0));
	float cloud_field = broad * 0.68 + detail * 0.23 + wisps * 0.09;
	float coverage = smoothstep(0.48, 0.70, cloud_field);
	float soft_edges = smoothstep(0.40, 0.78, cloud_field);
	ALBEDO = cloud_color.rgb * (0.90 + detail * 0.13);
	ROUGHNESS = 0.96;
	SPECULAR = 0.08;
	ALPHA = clamp(coverage * soft_edges * 0.68, 0.0, 0.52);
}
