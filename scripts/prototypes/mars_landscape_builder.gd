extends RefCounted
## Shared, deterministic Mars landscape generator for the story slice and rover survey.
## Generated meshes are deliberately lightweight and require no external runtime assets.

const GRID_STEPS := 32
const TERRAIN_HALF_WIDTH := 18.0
const TERRAIN_HALF_DEPTH := 14.0

static func configure_atmosphere(environment: Environment) -> void:
	if environment == null:
		return
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.035, 0.045, 0.095, 1.0)
	sky_material.sky_horizon_color = Color(0.48, 0.205, 0.145, 1.0)
	sky_material.ground_bottom_color = Color(0.095, 0.045, 0.055, 1.0)
	sky_material.ground_horizon_color = Color(0.35, 0.125, 0.095, 1.0)
	sky_material.sun_angle_max = 12.0
	sky_material.sun_curve = 0.18
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.43, 0.32, 1.0)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.53, 0.24, 0.17, 1.0)
	environment.fog_density = 0.0035

static func populate(parent: Node3D, profile: String = "cinematic") -> Dictionary:
	if parent == null:
		return {"mesh_instances": 0, "formations": 0, "boulders": 0}
	var terrain := MeshInstance3D.new()
	terrain.name = "MarsTerrain"
	terrain.mesh = _build_terrain_mesh()
	terrain.position.y = -0.10
	terrain.material_override = _vertex_material(0.96)
	parent.add_child(terrain)

	var formations := [
		{"name": "Mesa_West", "position": Vector3(-15.0, -0.08, -10.5), "radius": 4.3, "height": 7.2, "seed": 2},
		{"name": "Mesa_Crown", "position": Vector3(0.0, -0.08, -17.0), "radius": 5.2, "height": 8.8, "seed": 5},
		{"name": "Mesa_East", "position": Vector3(15.0, -0.08, -11.0), "radius": 4.5, "height": 6.8, "seed": 8},
		{"name": "Mesa_Southwest", "position": Vector3(-15.5, -0.08, 8.0), "radius": 3.5, "height": 4.8, "seed": 11},
		{"name": "Mesa_Southeast", "position": Vector3(15.0, -0.08, 8.5), "radius": 3.8, "height": 5.4, "seed": 14}
	]
	for spec in formations:
		_add_mesa(parent, spec)

	var boulder_count := _add_boulder_clusters(parent)
	_add_sun_disc(parent)
	return {
		"mesh_instances": 1 + formations.size() + boulder_count + 1,
		"formations": formations.size(),
		"boulders": boulder_count,
		"profile": profile
	}

static func _build_terrain_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z_index in range(GRID_STEPS):
		var z0 := lerpf(-TERRAIN_HALF_DEPTH, TERRAIN_HALF_DEPTH, float(z_index) / float(GRID_STEPS))
		var z1 := lerpf(-TERRAIN_HALF_DEPTH, TERRAIN_HALF_DEPTH, float(z_index + 1) / float(GRID_STEPS))
		for x_index in range(GRID_STEPS):
			var x0 := lerpf(-TERRAIN_HALF_WIDTH, TERRAIN_HALF_WIDTH, float(x_index) / float(GRID_STEPS))
			var x1 := lerpf(-TERRAIN_HALF_WIDTH, TERRAIN_HALF_WIDTH, float(x_index + 1) / float(GRID_STEPS))
			var p00 := _terrain_point(x0, z0)
			var p10 := _terrain_point(x1, z0)
			var p01 := _terrain_point(x0, z1)
			var p11 := _terrain_point(x1, z1)
			var avg_height := (p00.y + p10.y + p01.y + p11.y) * 0.25
			surface.set_color(_terrain_color(x0, z0, avg_height))
			surface.add_vertex(p00)
			surface.add_vertex(p01)
			surface.add_vertex(p11)
			surface.add_vertex(p00)
			surface.add_vertex(p11)
			surface.add_vertex(p10)
	surface.generate_normals()
	return surface.commit()

static func _terrain_point(x: float, z: float) -> Vector3:
	return Vector3(x, _terrain_height(x, z), z)

static func _terrain_height(x: float, z: float) -> float:
	return 0.075 * sin(x * 0.31 + z * 0.12) + 0.052 * cos(z * 0.43 - x * 0.17) + 0.028 * sin((x + z) * 0.68)

static func _terrain_color(x: float, z: float, height: float) -> Color:
	var variation := 0.018 * sin(x * 0.7 + z * 0.37)
	var warm := clampf((height + 0.16) * 0.45 + variation, 0.0, 0.12)
	return Color(0.365 + warm, 0.145 + warm * 0.40, 0.092 + warm * 0.25, 1.0)

static func _add_mesa(parent: Node3D, spec: Dictionary) -> void:
	var mesa := MeshInstance3D.new()
	mesa.name = str(spec["name"])
	mesa.position = spec["position"]
	mesa.mesh = _build_mesa_mesh(float(spec["radius"]), float(spec["height"]), int(spec["seed"]))
	mesa.material_override = _vertex_material(0.98)
	parent.add_child(mesa)

static func _build_mesa_mesh(base_radius: float, height: float, seed_value: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 11
	var height_fractions := [0.0, 0.18, 0.43, 0.72, 1.0]
	var radius_factors := [1.0, 0.96, 0.79, 0.88, 0.60]
	var rings: Array = []
	for ring_index in range(height_fractions.size()):
		var ring := PackedVector3Array()
		for segment in range(segments):
			var angle := TAU * float(segment) / float(segments)
			var wobble := 1.0 + 0.085 * sin(angle * 3.0 + float(seed_value) * 0.71) + 0.035 * cos(angle * 5.0 + float(seed_value))
			var radius := base_radius * float(radius_factors[ring_index]) * wobble
			ring.append(Vector3(cos(angle) * radius, height * float(height_fractions[ring_index]), sin(angle) * radius))
		rings.append(ring)

	var strata := [
		Color(0.31, 0.115, 0.085, 1.0),
		Color(0.43, 0.165, 0.115, 1.0),
		Color(0.52, 0.225, 0.145, 1.0),
		Color(0.38, 0.145, 0.105, 1.0)
	]
	for ring_index in range(rings.size() - 1):
		var lower: PackedVector3Array = rings[ring_index]
		var upper: PackedVector3Array = rings[ring_index + 1]
		var band_color: Color = strata[ring_index % strata.size()]
		for segment in range(segments):
			var next_segment := (segment + 1) % segments
			surface.set_color(band_color)
			surface.add_vertex(lower[segment])
			surface.add_vertex(upper[segment])
			surface.add_vertex(upper[next_segment])
			surface.add_vertex(lower[segment])
			surface.add_vertex(upper[next_segment])
			surface.add_vertex(lower[next_segment])
	var top_ring: PackedVector3Array = rings[rings.size() - 1]
	var top_center := Vector3(0.0, height, 0.0)
	for segment in range(segments):
		var next_segment := (segment + 1) % segments
		surface.set_color(Color(0.58, 0.275, 0.175, 1.0))
		surface.add_vertex(top_center)
		surface.add_vertex(top_ring[next_segment])
		surface.add_vertex(top_ring[segment])
	surface.generate_normals()
	return surface.commit()

static func _add_boulder_clusters(parent: Node3D) -> int:
	var clusters := [
		Vector3(-11.8, 0.0, -1.0),
		Vector3(11.7, 0.0, -2.5),
		Vector3(-12.2, 0.0, 5.5),
		Vector3(12.4, 0.0, 5.7),
		Vector3(-8.5, 0.0, -9.0),
		Vector3(8.3, 0.0, -9.5)
	]
	var count := 0
	for cluster_index in range(clusters.size()):
		var center: Vector3 = clusters[cluster_index]
		for stone_index in range(3):
			var stone := MeshInstance3D.new()
			stone.name = "Boulder_%02d_%02d" % [cluster_index + 1, stone_index + 1]
			var mesh := SphereMesh.new()
			mesh.radius = 0.58
			mesh.height = 0.92
			mesh.radial_segments = 9
			mesh.rings = 5
			stone.mesh = mesh
			var offset_x := (float(stone_index) - 1.0) * 0.62
			var offset_z := 0.26 if stone_index == 1 else -0.18
			stone.position = center + Vector3(offset_x, 0.15 + float(stone_index % 2) * 0.12, offset_z)
			stone.rotation_degrees = Vector3(float(stone_index * 7), float(cluster_index * 31 + stone_index * 19), float(stone_index * 5 - 4))
			var scale_value := 0.72 + float((cluster_index + stone_index) % 3) * 0.24
			stone.scale = Vector3(scale_value * 1.2, scale_value * 0.82, scale_value)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.34 + float(stone_index) * 0.025, 0.155 + float(cluster_index % 2) * 0.025, 0.105, 1.0)
			material.roughness = 0.98
			stone.material_override = material
			parent.add_child(stone)
			count += 1
	return count

static func _add_sun_disc(parent: Node3D) -> void:
	var sun := MeshInstance3D.new()
	sun.name = "MarsSunDisc"
	var mesh := SphereMesh.new()
	mesh.radius = 2.25
	mesh.height = 4.5
	mesh.radial_segments = 16
	mesh.rings = 8
	sun.mesh = mesh
	sun.position = Vector3(-16.0, 12.0, -27.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.66, 0.39, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.30, 0.105, 1.0)
	material.roughness = 1.0
	sun.material_override = material
	parent.add_child(sun)

static func _vertex_material(roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = roughness
	return material
