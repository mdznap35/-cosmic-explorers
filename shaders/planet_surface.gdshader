shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 accent_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform int surface_type = 0;
uniform float glow_strength = 0.0;
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
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

vec2 crater_field(vec2 p) {
	vec2 cell = floor(p);
	float basin = 0.0;
	float rim = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 id = cell + neighbor;
			vec2 center = neighbor + vec2(
				hash21(id + vec2(12.4, 7.1)),
				hash21(id + vec2(48.7, 21.3))
			);
			float radius = mix(0.20, 0.45, hash21(id + vec2(91.7, 17.3)));
			float distance_to_center = length(fract(p) - center);
			basin = max(basin, 1.0 - smoothstep(radius * 0.48, radius, distance_to_center));
			float rim_line = abs(distance_to_center - radius);
			rim = max(rim, 1.0 - smoothstep(0.018, 0.065, rim_line));
		}
	}
	return vec2(basin, rim);
}

void fragment() {
	vec2 uv = UV;
	float broad_noise = fbm(uv * vec2(10.0, 5.0));
	float detail_noise = fbm(uv * vec2(34.0, 18.0));
	float warp = fbm(uv * vec2(7.0, 13.0) + vec2(3.1, 8.7));
	float drift = animation_time;
	vec3 color = base_color.rgb;
	float rough = 0.88;
	float specular_level = 0.22;

	if (surface_type == 0 || surface_type == 9) {
		// Mercury and the Moon: overlapping impact basins and raised crater rims.
		float density = surface_type == 9 ? 29.0 : 38.0;
		vec2 craters = crater_field(uv * vec2(density, density * 0.52));
		float mineral = fbm(uv * vec2(72.0, 38.0));
		color = mix(base_color.rgb * 0.48, accent_color.rgb * 0.88, craters.x * 0.62 + mineral * 0.20);
		color = mix(color, accent_color.rgb * 1.13, craters.y * 0.36);
		color *= 0.88 + broad_noise * 0.18;
		rough = 0.96;
	} else if (surface_type == 1) {
		// Venus: dense golden cloud decks with broad, turbulent atmospheric bands.
		float flow = fbm(uv * vec2(8.0, 16.0) + vec2(drift * 0.018, -drift * 0.025));
		float clouds = sin((uv.y + (warp - 0.5) * 0.085) * 52.0
			+ sin(uv.x * 13.0 + flow) * 2.6 + detail_noise * 2.0);
		float cloud_mix = smoothstep(-0.82, 0.92, clouds + broad_noise * 0.68);
		color = mix(base_color.rgb * 0.70, accent_color.rgb, cloud_mix * 0.90);
		color *= 0.92 + flow * 0.12;
		rough = 0.82;
	} else if (surface_type == 2) {
		// Earth: irregular continents, oceans, polar ice, and cloud-shadow variation.
		float continents = fbm(uv * vec2(14.0, 7.0) + vec2(1.7, 3.3));
		float coast = smoothstep(0.42, 0.59, continents + (detail_noise - 0.5) * 0.12);
		vec3 ocean = base_color.rgb * (0.72 + broad_noise * 0.32);
		vec3 land = mix(accent_color.rgb * 0.48, accent_color.rgb, detail_noise);
		float terrain = fbm(uv * vec2(52.0, 26.0));
		land *= 0.82 + terrain * 0.36;
		color = mix(ocean, land, coast);
		float polar = smoothstep(0.82, 0.96, abs(uv.y - 0.5) * 2.0);
		color = mix(color, vec3(0.84, 0.91, 0.96), polar * 0.68);
		rough = 0.76;
	} else if (surface_type == 3) {
		// Mars: oxidized terrain, dark basaltic regions, fine ridges, and polar frost.
		float terrain = fbm(uv * vec2(19.0, 10.0));
		float minerals = fbm(uv * vec2(62.0, 32.0));
		float ridges = fbm(uv * vec2(96.0, 44.0));
		float dark_regions = smoothstep(0.50, 0.75, terrain);
		color = mix(base_color.rgb * 0.48, accent_color.rgb, minerals * 0.54 + 0.16);
		color = mix(color, base_color.rgb * 0.46, dark_regions * 0.42);
		color *= 0.90 + ridges * 0.22;
		float polar = 1.0 - smoothstep(0.0, 0.055, min(uv.y, 1.0 - uv.y));
		color = mix(color, vec3(0.91, 0.84, 0.77), polar * 0.78);
		rough = 0.97;
	} else if (surface_type == 4) {
		// Jupiter: layered zonal cloud belts, flowing turbulence, and the Great Red Spot.
		float flow = fbm(uv * vec2(12.0, 24.0) + vec2(drift * 0.015, -drift * 0.026));
		float bands = sin((uv.y + (warp - 0.5) * 0.052) * 88.0
			+ sin(uv.x * 9.0 + flow * 2.0) * 1.8 + detail_noise * 1.4);
		float band_mix = smoothstep(-0.38, 0.42, bands);
		color = mix(base_color.rgb * 0.65, accent_color.rgb, band_mix * 0.84);
		color *= 0.83 + broad_noise * 0.25;
		vec2 storm_pos = (uv - vec2(0.73, 0.63)) * vec2(1.0, 2.5);
		float storm_edge = length(storm_pos) + (fbm(uv * vec2(42.0, 25.0)) - 0.5) * 0.035;
		float storm = 1.0 - smoothstep(0.085, 0.19, storm_edge);
		float storm_swirl = sin(atan(storm_pos.y, storm_pos.x) * 9.0 + flow * 4.0);
		vec3 storm_color = mix(vec3(0.40, 0.105, 0.075), vec3(0.83, 0.39, 0.22), 0.5 + storm_swirl * 0.18);
		color = mix(color, storm_color, storm * 0.92);
		rough = 0.78;
		specular_level = 0.30;
	} else if (surface_type == 5) {
		// Saturn: softer ochre bands, fine atmospheric ribbons, and subtle polar haze.
		float flow = fbm(uv * vec2(10.0, 21.0) + vec2(drift * 0.012, -drift * 0.018));
		float bands = sin((uv.y + (warp - 0.5) * 0.025) * 96.0
			+ sin(uv.x * 7.0 + flow) * 1.1 + detail_noise);
		float band_mix = smoothstep(-0.52, 0.62, bands);
		color = mix(base_color.rgb * 0.72, accent_color.rgb, band_mix * 0.67);
		color *= 0.91 + broad_noise * 0.16;
		float polar_haze = smoothstep(0.72, 0.97, abs(uv.y - 0.5) * 2.0);
		color = mix(color, accent_color.rgb * 1.04, polar_haze * 0.20);
		rough = 0.86;
	} else if (surface_type == 6) {
		// Uranus: cool methane-blue atmosphere and restrained, broad bands.
		float bands = sin(uv.y * 37.0 + sin(uv.x * 5.0) * 0.72 + detail_noise * 0.8);
		float haze = fbm(uv * vec2(6.0, 12.0));
		color = mix(base_color.rgb * 0.78, accent_color.rgb, smoothstep(-0.72, 0.82, bands) * 0.48);
		color *= 0.93 + haze * 0.12;
		rough = 0.82;
	} else if (surface_type == 7) {
		// Neptune: deeper cloud belts, fast-flowing texture, and a dark storm system.
		float flow = fbm(uv * vec2(11.0, 23.0) + vec2(drift * 0.022, -drift * 0.035));
		float bands = sin((uv.y + (warp - 0.5) * 0.04) * 58.0 + detail_noise * 2.2 + flow);
		color = mix(base_color.rgb * 0.66, accent_color.rgb, smoothstep(-0.48, 0.65, bands) * 0.74);
		vec2 storm_pos = (uv - vec2(0.39, 0.55)) * vec2(1.0, 2.3);
		float storm = 1.0 - smoothstep(0.05, 0.15, length(storm_pos));
		color = mix(color, vec3(0.025, 0.075, 0.22), storm * 0.52);
		rough = 0.80;
	} else if (surface_type == 8) {
		// Sun: animated convection cells and bright granular hot spots.
		float flame = fbm(uv * vec2(15.0, 30.0) + vec2(drift * 0.028, -drift * 0.06));
		float cells = fbm(uv * vec2(44.0, 52.0) + vec2(-drift * 0.035, drift * 0.045));
		float granulation = smoothstep(0.35, 0.76, cells);
		color = mix(base_color.rgb * 0.56, accent_color.rgb, smoothstep(0.25, 0.78, flame));
		color = mix(color, vec3(1.0, 0.91, 0.52), granulation * 0.44);
		EMISSION = color * glow_strength;
		rough = 0.55;
		specular_level = 0.08;
	}

	ALBEDO = color;
	ROUGHNESS = rough;
	SPECULAR = specular_level;
}
