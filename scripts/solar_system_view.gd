extends Node3D

signal planet_tapped(planet_id: String)

const PlanetBody = preload("res://scripts/planet_body.gd")
const OrbitMath = preload("res://scripts/orbit_math.gd")

var _catalog: Array = []
var _planet_nodes: Dictionary = {}
var _orbit_pivots: Dictionary = {}
var _planet_radii: Dictionary = {}
var _camera: Camera3D
var _focused_id := ""
var _camera_tween: Tween
var _camera_start := Vector3(0.0, 22.0, 30.0)


func configure(planets: Array) -> void:
	_catalog = planets.duplicate(true)


func _ready() -> void:
	_create_environment()
	_create_camera()
	_create_lighting()
	_create_stars()
	_create_sun()
	_create_planets()


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

	if _focused_id != "" and _planet_nodes.has(_focused_id):
		var target: Node3D = _planet_nodes[_focused_id]
		_camera.look_at(target.global_position, Vector3.UP)
	elif _camera != null:
		_camera.look_at(Vector3.ZERO, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_try_pick(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_pick(event.position)


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
	_camera.position = _camera_start
	_camera.current = true
	add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)


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
	sun.configure({
		"id": "sun",
		"radius": 1.18,
		"color": Color(1.0, 0.53, 0.13),
		"accent": Color(1.0, 0.78, 0.32),
		"spin_speed": 0.035
	})
	add_child(sun)


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
	add_child(line)


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
	var body: Node3D = _planet_nodes[planet_id]
	var radius := float(_planet_radii.get(planet_id, 0.4))
	var desired_position := body.global_position + Vector3(
		0.0,
		maxf(radius * 2.8, 1.25),
		maxf(radius * 6.0, 2.9)
	)
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "global_position", desired_position, 0.72)


func reset_camera() -> void:
	_focused_id = ""
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC)
	_camera_tween.set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "position", _camera_start, 0.78)


func zoom_by(amount: float) -> void:
	if _camera == null:
		return
	var target := Vector3.ZERO
	if _focused_id != "" and _planet_nodes.has(_focused_id):
		target = (_planet_nodes[_focused_id] as Node3D).global_position
	var offset := _camera.global_position - target
	var current_distance := offset.length()
	if current_distance < 0.01:
		return
	var next_distance := OrbitMath.clamp_camera_distance(current_distance * (1.0 - amount))
	_camera.global_position = target + offset.normalized() * next_distance


func _kill_camera_tween() -> void:
	if _camera_tween != null and _camera_tween.is_running():
		_camera_tween.kill()
