shader_type spatial;
render_mode blend_add, cull_back, depth_draw_never, unshaded;

uniform vec4 atmosphere_color : source_color = vec4(0.20, 0.62, 1.0, 1.0);
uniform float intensity = 0.42;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.35);
	float soft_halo = smoothstep(0.06, 0.95, rim);
	vec3 glow = atmosphere_color.rgb * (0.72 + soft_halo * 0.55);
	ALBEDO = glow;
	EMISSION = glow * intensity;
	ALPHA = clamp(soft_halo * intensity, 0.0, 0.48);
}
