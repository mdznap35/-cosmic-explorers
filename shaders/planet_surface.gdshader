shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 accent_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform int surface_type = 0;
uniform float glow_strength = 0.0;

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
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	float broad_noise = fbm(uv * vec2(10.0, 5.0));
	float detail_noise = fbm(uv * vec2(34.0, 18.0));
	float warp = fbm(uv * vec2(7.0, 13.0) + vec2(3.1, 8.7));
	vec3 color = base_color.rgb;

	if (surface_type == 0) {
		// Mercury: old, cratered, mineral-grey ground.
		float craters = fbm(uv * vec2(48.0, 25.0));
		float small_craters = fbm(uv * vec2(92.0, 48.0));
		float relief = smoothstep(0.24, 0.78, craters) * 0.72
			+ smoothstep(0.42, 0.82, small_craters) * 0.18;
		color = mix(base_color.rgb * 0.58, accent_color.rgb, relief);
	} else if (surface_type == 1) {
		// Venus: thick golden cloud decks and soft turbulent bands.
		float clouds = sin((uv.y + (warp - 0.5) * 0.08) * 49.0
			+ sin(uv.x * 12.0) * 2.2 + detail_noise * 1.8);
		float cloud_mix = smoothstep(-0.85, 0.9, clouds + broad_noise * 0.75);
		color = mix(base_color.rgb * 0.78, accent_color.rgb, cloud_mix * 0.82);
	} else if (surface_type == 2) {
		// Earth: blue oceans, irregular green land masses, and high cloud wisps.
		float continents = fbm(uv * vec2(12.0, 6.0) + vec2(1.7, 3.3));
		float coast = smoothstep(0.43, 0.57, continents + (detail_noise - 0.5) * 0.14);
		vec3 ocean = base_color.rgb * (0.78 + broad_noise * 0.25);
		vec3 land = mix(accent_color.rgb * 0.58, accent_color.rgb, detail_noise);
		color = mix(ocean, land, coast);
		float clouds = smoothstep(0.69, 0.83, fbm(uv * vec2(34.0, 18.0) + vec2(0.4, 1.6)));
		color = mix(color, vec3(0.88, 0.94, 1.0), clouds * 0.23);
	} else if (surface_type == 3) {
		// Mars: rusty deserts, darker mineral regions, and pale polar caps.
		float terrain = fbm(uv * vec2(19.0, 10.0));
		float minerals = fbm(uv * vec2(58.0, 30.0));
		float dark_regions = smoothstep(0.52, 0.74, terrain);
		color = mix(base_color.rgb * 0.57, accent_color.rgb, minerals * 0.48 + 0.18);
		color = mix(color, base_color.rgb * 0.52, dark_regions * 0.3);
		float polar = smoothstep(0.075, 0.0, min(uv.y, 1.0 - uv.y));
		color = mix(color, vec3(0.91, 0.81, 0.69), polar * 0.74);
	} else if (surface_type == 4 || surface_type == 5) {
		// Jupiter and Saturn: atmospheric bands with moving turbulence.
		float band_wave = sin((uv.y + (warp - 0.5) * 0.045) * 78.0
			+ sin(uv.x * 8.0) * 1.4 + detail_noise * 1.1);
		float band_mix = smoothstep(-0.32, 0.4, band_wave);
		color = mix(base_color.rgb * 0.72, accent_color.rgb, band_mix * 0.78);
		color *= 0.86 + broad_noise * 0.22;
		if (surface_type == 4) {
			vec2 storm_pos = (uv - vec2(0.73, 0.63)) * vec2(1.0, 2.8);
			float storm = 1.0 - smoothstep(0.075, 0.17, length(storm_pos));
			color = mix(color, vec3(0.68, 0.24, 0.15), storm * 0.76);
		}
	} else if (surface_type == 6) {
		// Uranus: quiet turquoise atmosphere with restrained bands.
		float bands = sin(uv.y * 30.0 + sin(uv.x * 5.0) * 0.7 + detail_noise);
		color = mix(base_color.rgb * 0.82, accent_color.rgb, smoothstep(-0.7, 0.8, bands) * 0.43);
	} else if (surface_type == 7) {
		// Neptune: deep blue bands, turbulent details, and a darker storm.
		float bands = sin((uv.y + (warp - 0.5) * 0.035) * 52.0 + detail_noise * 2.0);
		color = mix(base_color.rgb * 0.72, accent_color.rgb, smoothstep(-0.45, 0.6, bands) * 0.65);
		vec2 storm_pos = (uv - vec2(0.39, 0.55)) * vec2(1.0, 2.3);
		float storm = 1.0 - smoothstep(0.05, 0.13, length(storm_pos));
		color = mix(color, vec3(0.055, 0.13, 0.39), storm * 0.42);
	} else if (surface_type == 8) {
		// Sun: warm, moving convection-like surface detail.
		float flame = fbm(uv * vec2(13.0, 29.0) + vec2(TIME * 0.035, -TIME * 0.08));
		float hot_cells = fbm(uv * vec2(39.0, 46.0) + vec2(-TIME * 0.025, TIME * 0.04));
		color = mix(base_color.rgb * 0.68, accent_color.rgb, smoothstep(0.28, 0.78, flame));
		color = mix(color, vec3(1.0, 0.91, 0.48), smoothstep(0.66, 0.9, hot_cells) * 0.38);
		EMISSION = color * glow_strength;
	}

	ALBEDO = color;
	ROUGHNESS = 0.92;
}
