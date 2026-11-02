extends Node3D

const PLANET_SHADER = preload("res://shaders/planet_surface.gdshader")
const SATURN_RING_SHADER = preload("res://shaders/saturn_rings.gdshader")
const EARTH_ATMOSPHERE_SHADER = preload("res://shaders/earth_atmosphere.gdshader")
const EARTH_CLOUDS_SHADER = preload("res://shaders/earth_clouds.gdshader")
const SUN_CORONA_SHADER = preload("res://shaders/sun_corona.gdshader")

var _data: Dictionary = {}
var _surface: MeshInstance3D
var _cloud_layer: MeshInstance3D
var _moon_pivot: Node3D
var _ring_material: ShaderMaterial
var _sun_corona: MeshInstance3D
var _sun_outer_glow: MeshInstance3D
var _motion_enabled := true
var _animation_clock := 0.0


func configure(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_build_surface()
	_build_pick_area()

	var body_id := str(_data.get("id", ""))
	if body_id == "earth":
		_build_atmosphere()
		_build_cloud_layer()
		_build_moon()
	elif body_id == "saturn":
		_build_rings()
	elif body_id == "sun":
		_build_sun_glow()


func _process(delta: float) -> void:
	if not _motion_enabled:
		return

	_animation_clock += delta
	if _surface != null:
		_surface.rotate_y(float(_data.get("spin_speed", 0.1)) * delta)
		_update_shader_clock(_surface)
	if _cloud_layer != null:
		_cloud_layer.rotate_y(delta * 0.012)
		_update_shader_clock(_cloud_layer)
	if _moon_pivot != null:
		_moon_pivot.rotate_y(delta * 0.72)
	if _ring_material != null:
		_ring_material.set_shader_parameter("animation_time", _animation_clock)
	if _sun_corona != null:
		_update_shader_clock(_sun_corona)
	if _sun_outer_glow != null:
		_update_shader_clock(_sun_outer_glow)


func set_motion_enabled(enabled: bool) -> void:
	_motion_enabled = enabled


func _update_shader_clock(mesh_instance: MeshInstance3D) -> void:
	var material := mesh_instance.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("animation_time", _animation_clock)


func _build_surface() -> void:
	var radius := float(_data.get("radius", 0.4))
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 56
	sphere.rings = 40

	_surface = MeshInstance3D.new()
	_surface.name = "PlanetSurface"
	_surface.mesh = sphere
	_surface.material_override = _make_surface_material(_data)
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_surface)


func _make_surface_material(body_data: Dictionary) -> ShaderMaterial:
	var base: Color = body_data.get("color", Color.WHITE)
	var accent: Color = body_data.get("accent", base.lightened(0.18))
	var body_id := str(body_data.get("id", ""))
	var surface_types := {
		"mercury": 0,
		"venus": 1,
		"earth": 2,
		"mars": 3,
		"jupiter": 4,
		"saturn": 5,
		"uranus": 6,
		"neptune": 7,
		"sun": 8,
		"moon": 9
	}

	var material := ShaderMaterial.new()
	material.shader = PLANET_SHADER
	material.set_shader_parameter("surface_type", int(surface_types.get(body_id, 9)))
	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("glow_strength", 1.35 if body_id == "sun" else 0.0)
	material.set_shader_parameter("animation_time", _animation_clock)
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
	sphere.radius = radius * 1.075
	sphere.height = radius * 2.15
	sphere.radial_segments = 48
	sphere.rings = 32

	var material := ShaderMaterial.new()
	material.shader = EARTH_ATMOSPHERE_SHADER
	material.set_shader_parameter("atmosphere_color", Color(0.20, 0.62, 1.0, 1.0))
	material.set_shader_parameter("intensity", 0.40)

	var shell := MeshInstance3D.new()
	shell.name = "EarthAtmosphere"
	shell.mesh = sphere
	shell.material_override = material
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shell)


func _build_cloud_layer() -> void:
	var radius := float(_data.get("radius", 0.39))
	var sphere := SphereMesh.new()
	sphere.radius = radius * 1.018
	sphere.height = radius * 2.036
	sphere.radial_segments = 48
	sphere.rings = 32

	var material := ShaderMaterial.new()
	material.shader = EARTH_CLOUDS_SHADER
	material.set_shader_parameter("cloud_color", Color(0.88, 0.94, 1.0, 1.0))
	material.set_shader_parameter("animation_time", _animation_clock)

	_cloud_layer = MeshInstance3D.new()
	_cloud_layer.name = "EarthCloudLayer"
	_cloud_layer.mesh = sphere
	_cloud_layer.material_override = material
	_cloud_layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cloud_layer)


func _build_moon() -> void:
	_moon_pivot = Node3D.new()
	_moon_pivot.name = "MoonOrbit"
	add_child(_moon_pivot)

	var moon_data := {
		"id": "moon",
		"radius": 0.105,
		"color": Color(0.62, 0.65, 0.69),
		"accent": Color(0.88, 0.89, 0.91)
	}
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 0.105
	moon_mesh.height = 0.21
	moon_mesh.radial_segments = 32
	moon_mesh.rings = 20

	var moon := MeshInstance3D.new()
	moon.name = "TheMoon"
	moon.mesh = moon_mesh
	moon.material_override = _make_surface_material(moon_data)
	moon.position = Vector3(0.0, 0.0, 0.78)
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_moon_pivot.add_child(moon)


func _build_rings() -> void:
	var radius := float(_data.get("radius", 0.73))
	var inner_radius := radius * 1.28
	var outer_radius := radius * 2.08
	var segments := 192
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

	_ring_material = ShaderMaterial.new()
	_ring_material.shader = SATURN_RING_SHADER
	_ring_material.set_shader_parameter("ring_color", Color(0.82, 0.73, 0.58, 1.0))
	_ring_material.set_shader_parameter("animation_time", _animation_clock)
	ring_mesh.surface_set_material(0, _ring_material)

	var rings := MeshInstance3D.new()
	rings.name = "SaturnRings"
	rings.mesh = ring_mesh
	rings.rotation_degrees = Vector3(26.0, 0.0, 9.0)
	rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rings)


func _build_sun_glow() -> void:
	var radius := float(_data.get("radius", 1.18))

	var inner_mesh := SphereMesh.new()
	inner_mesh.radius = radius * 1.23
	inner_mesh.height = radius * 2.46
	inner_mesh.radial_segments = 48
	inner_mesh.rings = 32

	var inner_material := ShaderMaterial.new()
	inner_material.shader = SUN_CORONA_SHADER
	inner_material.set_shader_parameter("corona_color", Color(1.0, 0.37, 0.08, 1.0))
	inner_material.set_shader_parameter("intensity", 0.23)
	inner_material.set_shader_parameter("animation_time", _animation_clock)

	_sun_corona = MeshInstance3D.new()
	_sun_corona.name = "SunCorona"
	_sun_corona.mesh = inner_mesh
	_sun_corona.material_override = inner_material
	_sun_corona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sun_corona)

	var outer_mesh := SphereMesh.new()
	outer_mesh.radius = radius * 1.39
	outer_mesh.height = radius * 2.78
	outer_mesh.radial_segments = 40
	outer_mesh.rings = 28

	var outer_material := ShaderMaterial.new()
	outer_material.shader = SUN_CORONA_SHADER
	outer_material.set_shader_parameter("corona_color", Color(1.0, 0.22, 0.035, 1.0))
	outer_material.set_shader_parameter("intensity", 0.10)
	outer_material.set_shader_parameter("animation_time", _animation_clock)

	_sun_outer_glow = MeshInstance3D.new()
	_sun_outer_glow.name = "SunOuterGlow"
	_sun_outer_glow.mesh = outer_mesh
	_sun_outer_glow.material_override = outer_material
	_sun_outer_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sun_outer_glow)
