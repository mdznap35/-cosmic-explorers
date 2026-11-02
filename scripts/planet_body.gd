extends Node3D

const PLANET_SHADER = preload("res://shaders/planet_surface.gdshader")

var _data: Dictionary = {}
var _surface: MeshInstance3D
var _moon_pivot: Node3D
var _motion_enabled := true


func configure(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_build_surface()
	_build_pick_area()

	var planet_id := str(_data.get("id", ""))
	if planet_id == "earth":
		_build_atmosphere()
		_build_moon()
	elif planet_id == "saturn":
		_build_rings()
	elif planet_id == "sun":
		_build_sun_glow()


func _process(delta: float) -> void:
	if not _motion_enabled:
		return
	if _surface != null:
		_surface.rotate_y(float(_data.get("spin_speed", 0.1)) * delta)
	if _moon_pivot != null:
		_moon_pivot.rotate_y(delta * 0.72)


func set_motion_enabled(enabled: bool) -> void:
	_motion_enabled = enabled


func _build_surface() -> void:
	var radius := float(_data.get("radius", 0.4))
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 32

	_surface = MeshInstance3D.new()
	_surface.name = "PlanetSurface"
	_surface.mesh = sphere
	_surface.material_override = _make_surface_material()
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_surface)


func _make_surface_material() -> Material:
	var base: Color = _data.get("color", Color.WHITE)
	var accent: Color = _data.get("accent", base.lightened(0.18))
	var planet_id := str(_data.get("id", ""))
	var surface_types := {
		"mercury": 0,
		"venus": 1,
		"earth": 2,
		"mars": 3,
		"jupiter": 4,
		"saturn": 5,
		"uranus": 6,
		"neptune": 7,
		"sun": 8
	}

	var material := ShaderMaterial.new()
	material.shader = PLANET_SHADER
	material.set_shader_parameter("surface_type", int(surface_types.get(planet_id, 0)))
	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("glow_strength", 1.45 if planet_id == "sun" else 0.0)
	return material


func _build_pick_area() -> void:
	var hit_body := StaticBody3D.new()
	hit_body.name = "CelestialTouchTarget"
	hit_body.collision_layer = 1
	hit_body.collision_mask = 0
	hit_body.set_meta("planet_id", str(_data.get("id", "")))

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(float(_data.get("radius", 0.4)) * 1.65, 0.34)
	collision.shape = sphere
	hit_body.add_child(collision)
	add_child(hit_body)


func _build_atmosphere() -> void:
	var radius := float(_data.get("radius", 0.39))
	var sphere := SphereMesh.new()
	sphere.radius = radius * 1.055
	sphere.height = radius * 2.11
	sphere.radial_segments = 40
	sphere.rings = 28

	var atmosphere := StandardMaterial3D.new()
	atmosphere.albedo_color = Color(0.22, 0.66, 1.0, 0.16)
	atmosphere.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	atmosphere.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	atmosphere.cull_mode = BaseMaterial3D.CULL_FRONT

	var shell := MeshInstance3D.new()
	shell.name = "EarthAtmosphere"
	shell.mesh = sphere
	shell.material_override = atmosphere
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shell)


func _build_moon() -> void:
	_moon_pivot = Node3D.new()
	_moon_pivot.name = "MoonOrbit"
	add_child(_moon_pivot)

	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 0.105
	moon_mesh.height = 0.21
	moon_mesh.radial_segments = 24
	moon_mesh.rings = 16

	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_color = Color(0.72, 0.75, 0.79)
	moon_material.roughness = 0.96

	var moon := MeshInstance3D.new()
	moon.name = "TheMoon"
	moon.mesh = moon_mesh
	moon.material_override = moon_material
	moon.position = Vector3(0.0, 0.0, 0.78)
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_moon_pivot.add_child(moon)


func _build_rings() -> void:
	var radius := float(_data.get("radius", 0.73))
	var inner_radius := radius * 1.28
	var outer_radius := radius * 2.05
	var segments := 128
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for index in range(segments):
		var angle_a := TAU * float(index) / float(segments)
		var angle_b := TAU * float(index + 1) / float(segments)
		var base_index := vertices.size()
		var inner_a := Vector3(cos(angle_a) * inner_radius, 0.0, sin(angle_a) * inner_radius)
		var outer_a := Vector3(cos(angle_a) * outer_radius, 0.0, sin(angle_a) * outer_radius)
		var outer_b := Vector3(cos(angle_b) * outer_radius, 0.0, sin(angle_b) * outer_radius)
		var inner_b := Vector3(cos(angle_b) * inner_radius, 0.0, sin(angle_b) * inner_radius)
		vertices.append_array(PackedVector3Array([inner_a, outer_a, outer_b, inner_b]))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([
			Vector2(0.0, float(index) / segments),
			Vector2(1.0, float(index) / segments),
			Vector2(1.0, float(index + 1) / segments),
			Vector2(0.0, float(index + 1) / segments)
		]))
		indices.append_array(PackedInt32Array([
			base_index, base_index + 1, base_index + 2,
			base_index, base_index + 2, base_index + 3
		]))

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var ring_mesh := ArrayMesh.new()
	ring_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.82, 0.72, 0.54, 0.84)
	ring_material.roughness = 0.95
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mesh.surface_set_material(0, ring_material)

	var rings := MeshInstance3D.new()
	rings.name = "SaturnRings"
	rings.mesh = ring_mesh
	rings.rotation_degrees = Vector3(26.0, 0.0, 9.0)
	rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rings)


func _build_sun_glow() -> void:
	var radius := float(_data.get("radius", 1.18))
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = radius * 1.18
	halo_mesh.height = radius * 2.36
	halo_mesh.radial_segments = 40
	halo_mesh.rings = 24

	var halo_material := StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.albedo_color = Color(1.0, 0.34, 0.06, 0.16)
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.cull_mode = BaseMaterial3D.CULL_FRONT

	var halo := MeshInstance3D.new()
	halo.name = "SunCorona"
	halo.mesh = halo_mesh
	halo.material_override = halo_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
