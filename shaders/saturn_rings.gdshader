shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, unshaded;

uniform vec4 ring_color : source_color = vec4(0.78, 0.69, 0.53, 1.0);
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

void fragment() {
	float radial = UV.x;
	float angular = UV.y;
	float fine_bands = 0.5 + 0.5 * sin(radial * 175.0 + noise2(vec2(angular * 13.0, radial * 35.0)) * 3.2);
	float broad_bands = 0.5 + 0.5 * sin(radial * 39.0 + noise2(vec2(angular * 6.0, radial * 11.0)) * 2.0);
	float grain = noise2(vec2(angular * 95.0 + animation_time * 0.002, radial * 260.0));
	float opacity = mix(0.20, 0.72, smoothstep(0.12, 0.88, fine_bands));
	opacity *= 0.76 + broad_bands * 0.24;
	opacity *= 0.84 + grain * 0.16;

	// A broad Cassini-like division and several narrow gaps break up the ring plane.
	float cassini_gap = smoothstep(0.018, 0.048, abs(radial - 0.585));
	float inner_gap = smoothstep(0.006, 0.018, abs(radial - 0.285));
	float outer_gap = smoothstep(0.008, 0.022, abs(radial - 0.825));
	float edge_fade = smoothstep(0.0, 0.025, radial) * (1.0 - smoothstep(0.97, 1.0, radial));
	opacity *= cassini_gap * inner_gap * outer_gap * edge_fade;

	vec3 tint = mix(ring_color.rgb * 0.70, ring_color.rgb * 1.10, broad_bands);
	ALBEDO = tint;
	ALPHA = clamp(opacity * ring_color.a, 0.0, 0.82);
}
