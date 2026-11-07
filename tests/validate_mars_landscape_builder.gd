extends SceneTree

const MarsLandscapeBuilder = preload("res://scripts/prototypes/mars_landscape_builder.gd")

var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var environment := Environment.new()
	MarsLandscapeBuilder.configure_atmosphere(environment)
	if environment.background_mode != Environment.BG_SKY or environment.sky == null:
		_errors.append("Mars atmosphere must configure a procedural sky.")
	var metrics: Dictionary = MarsLandscapeBuilder.populate(world, "test")
	var terrain := world.get_node_or_null("MarsTerrain") as MeshInstance3D
	if terrain == null or terrain.mesh == null:
		_errors.append("Mars landscape must contain a generated terrain mesh.")
	else:
		if terrain.mesh.get_surface_count() != 1:
			_errors.append("Terrain must expose exactly one surface.")
		var arrays: Array = terrain.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if vertices.size() < 1500:
			_errors.append("Terrain mesh must contain a useful, non-flat grid.")
	if int(metrics.get("formations", 0)) < 5:
		_errors.append("Mars landscape must generate five horizon formations.")
	if int(metrics.get("boulders", 0)) < 12:
		_errors.append("Mars landscape must generate enough landmark rocks.")
	if world.get_node_or_null("MarsSunDisc") == null:
		_errors.append("Mars landscape must include a warm horizon sun disc.")
	if _errors.is_empty():
		print("PASS: shared Mars terrain, atmosphere, layered mesas, boulders and sun disc.")
		world.free()
		quit(0)
		return
	for message in _errors:
		push_error(message)
	world.free()
	quit(1)
