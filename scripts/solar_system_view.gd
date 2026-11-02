extends Node3D

signal planet_tapped(planet_id: String)

const PlanetBody = preload("res://scripts/planet_body.gd")
const PlanetCatalog = preload("res://scripts/planet_catalog.gd")
const OrbitMath = preload("res://scripts/orbit_math.gd")

var _catalog: Array = []
var _planet_nodes: Dictionary = {}
var _orbit_pivots: Dictionary = {}
var _planet_radii: Dictionary = {}
var _camera: Camera3D
var _focused_id := ""

var _camera_distance := 37.2
var _camera_yaw := 0.0
var _camera_pitch := 0.63
var _camera_tween: Tween

var _screen_touch_active := false
var _screen_touch_moved := false
var _mouse_drag_active := false
var _mouse_drag_moved := false


func configure(planets: Array) -> void:
	_catalog = planets.duplicate(true)


func _ready() -> void:
	_create_environment()
	_create_camera()
	_create_lighting()
	_create_stars()
	_create_sun()
	_create_planets()
	_update_camera_transform()


func _process(delta: float) -> void:
	for planet in _catalog:
		var planet_id := str(planet["id"])
		var pivot: Node3D = _orbit_pivots.get(planet_id)
		if pivot != null:
			pivot.rotation.y = OrbitMath.advance_angle(
				pivot.rotation.y,
				float(planet.get("orbit_speed", 0.1)),
				delta
			)
	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_screen_touch_active = true
			_screen_touch_moved = false
		else:
			if _screen_touch_active and not _screen_touch_moved:
				_try_pick(event.position)
			_screen_touch_active = false
	elif event is InputEventScreenDrag and _screen_touch_active:
		if event.relative.length_squared() > 1.0:
			_screen_touch_moved = true
			_rotate_camera(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_drag_active = true
			_mouse_drag_moved = false
		else:
			if _mouse_drag_active and not _mouse_drag_moved:
				_try_pick(event.position)
			_mouse_drag_active = false
	elif event is InputEventMouseMotion and _mouse_drag_active:
		if event.relative.length_squared() > 4.0:
			_mouse_drag_moved = true
			_rotate_camera(event.relative)


func _create_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.008, 0.016, 0.052)
	sky_material.sky_horizon_color = Color(0.025, 0.07, 0.16)
	sky_material.ground_bottom_color = Color(0.005, 0.009, 0.028)
	sky_material.ground_horizon_color = Color(0.015, 0.028, 0.065)
	sky.sky_material = sky_material

	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.42, 0.62)
	environment.ambient_light_energy = 0.42
	world.environment = environment
	add_child(world)


func _create_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "ExplorerCamera"
	_camera.fov = 43.0
	_camera.near = 0.1
	_camera.far = 180.0
	_camera.current = true
	add_child(_camera)


func _create_lighting() -> void:
	var sun_light := OmniLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_color = Color(1.0, 0.82, 0.65)
	sun_light.light_energy = 1.55
	sun_light.omni_range = 42.0
	sun_light.shadow_enabled = false
	add_child(sun_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "SoftSpaceFill"
	fill_light.light_color = Color(0.28, 0.42, 0.72)
	fill_light.light_energy = 0.22
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(-32.0, 24.0, 0.0)
	add_child(fill_light)


func _create_stars() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	star_mesh.radial_segments = 6
	star_mesh.rings = 4

	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(0.66, 0.82, 1.0)
	star_material.emission_enabled = true
	star_material.emission = Color(0.26, 0.40, 0.72)
	star_material.emission_energy_multiplier = 0.7
	star_mesh.material = star_material

	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = star_mesh
	multi_mesh.instance_count = 300

	var random := RandomNumberGenerator.new()
	random.seed = 20261102
	for index in range(multi_mesh.instance_count):
		var direction := Vector3(
			random.randf_range(-1.0, 1.0),
			random.randf_range(-0.8, 0.8),
			random.randf_range(-1.0, 1.0)
		).normalized()
		var distance := random.randf_range(31.0, 58.0)
		var scale := random.randf_range(0.45, 1.25)
		var transform := Transform3D(
			Basis.IDENTITY.scaled(Vector3.ONE * scale),
			direction * distance
		)
		multi_mesh.set_instance_transform(index, transform)

	var stars := MultiMeshInstance3D.new()
	stars.name = "StarField"
	stars.multimesh = multi_mesh
	add_child(stars)


func _create_sun() -> void:
	var sun := PlanetBody.new()
	sun.name = "Sun"
	sun.configure(PlanetCatalog.get_sun())
	add_child(sun)
	_planet_nodes["sun"] = sun
	_planet_radii["sun"] = float(PlanetCatalog.get_sun().get("radius", 1.18))


func _create_planets() -> void:
	for planet in _catalog:
		var planet_id := str(planet["id"])
		var distance := float(planet["distance"])
		_create_orbit_line(distance, planet_id)

		var pivot := Node3D.new()
		pivot.name = "Orbit_" + planet_id
		add_child(pivot)

		var body = PlanetBody.new()
		body.name = "Planet_" + planet_id
		body.configure(planet)
		body.position = Vector3(distance, 0.0, 0.0)
		pivot.add_child(body)

		_orbit_pivots[planet_id] = pivot
		_planet_nodes[planet_id] = body
		_planet_radii[planet_id] = float(planet["radius"])


func _create_orbit_line(distance: float, planet_id: String) -> void:
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color(0.30, 0.59, 0.90, 0.23)
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_material.no_depth_test = true

	var immediate := ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, line_material)
	var segments := 128
	for index in range(segments + 1):
		var angle := TAU * float(index) / float(segments)
		immediate.surface_add_vertex(Vector3(
			cos(angle) * distance,
			-0.045,
			sin(angle) * distance
		))
	immediate.surface_end()

	var line := MeshInstance3D.new()
	line.name = "OrbitLine_" + planet_id
	line.mesh = immediate
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)


func _camera_target_position() -> Vector3:
	if _focused_id != "" and _planet_nodes.has(_focused_id):
		var target: Node3D = _planet_nodes[_focused_id]
		return target.global_position
	return Vector3.ZERO


func _update_camera_transform() -> void:
	if _camera == null:
		return
	var target := _camera_target_position()
	var horizontal_distance := cos(_camera_pitch) * _camera_distance
	var offset := Vector3(
		sin(_camera_yaw) * horizontal_distance,
		sin(_camera_pitch) * _camera_distance,
		cos(_camera_yaw) * horizontal_distance
	)
	_camera.global_position = target + offset
	_camera.look_at(target, Vector3.UP)


func _try_pick(screen_position: Vector2) -> void:
	if _camera == null or not is_inside_tree():
		return

	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 180.0
	)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider: Object = hit.get("collider")
	if collider != null and collider.has_meta("planet_id"):
		planet_tapped.emit(str(collider.get_meta("planet_id")))


func focus_on_planet(planet_id: String) -> void:
	if not _planet_nodes.has(planet_id):
		return

	_focused_id = planet_id
	var radius := float(_planet_radii.get(planet_id, 0.4))
	var desired_distance := clampf(radius * 7.6, 5.0, 11.0)
	_tween_camera(desired_distance, 0.28, 0.0)


func reset_camera() -> void:
	_focused_id = ""
	_tween_camera(37.2, 0.63, 0.0)


func zoom_by(amount: float) -> void:
	_kill_camera_tween()
	_camera_distance = OrbitMath.clamp_camera_distance(_camera_distance * (1.0 - amount))
	_update_camera_transform()


func _rotate_camera(relative: Vector2) -> void:
	_kill_camera_tween()
	_camera_yaw = fposmod(_camera_yaw - relative.x * 0.006, TAU)
	_camera_pitch = clampf(_camera_pitch + relative.y * 0.006, -0.32, 1.28)
	_update_camera_transform()


func _tween_camera(distance: float, pitch: float, yaw: float) -> void:
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(self, "_camera_distance", distance, 0.72)
	_camera_tween.parallel().tween_property(self, "_camera_pitch", pitch, 0.72)
	_camera_tween.parallel().tween_property(self, "_camera_yaw", yaw, 0.72)


func _kill_camera_tween() -> void:
	if _camera_tween != null and _camera_tween.is_running():
		_camera_tween.kill()
