extends SceneTree

const PlanetBody = preload("res://scripts/planet_body.gd")
const PlanetCatalog = preload("res://scripts/planet_catalog.gd")

const PLANET_TEXTURES := [
	"res://assets/planetary_textures/sun.jpg",
	"res://assets/planetary_textures/mercury.jpg",
	"res://assets/planetary_textures/venus.jpg",
	"res://assets/planetary_textures/earth.jpg",
	"res://assets/planetary_textures/mars.jpg",
	"res://assets/planetary_textures/jupiter.jpg",
	"res://assets/planetary_textures/saturn.jpg",
	"res://assets/planetary_textures/uranus.jpg",
	"res://assets/planetary_textures/neptune.jpg"
]

const SHADERS := [
	"res://shaders/planet_surface.gdshader",
	"res://shaders/saturn_rings.gdshader",
	"res://shaders/earth_atmosphere.gdshader",
	"res://shaders/earth_clouds.gdshader",
	"res://shaders/sun_corona.gdshader"
]


func _initialize() -> void:
	var errors: Array[String] = []
	for body_data in PlanetCatalog.get_all():
		_validate_body_texture_binding(body_data, errors)
	_validate_body_texture_binding(PlanetCatalog.get_sun(), errors)

	for texture_path in PLANET_TEXTURES:
		if not ResourceLoader.exists(texture_path):
			errors.append("Missing staged planetary texture: " + texture_path)
			continue
		var texture_resource: Resource = load(texture_path)
		if not (texture_resource is Texture2D):
			errors.append("Planetary map did not load as Texture2D: " + texture_path)

	var surface_shader_source := FileAccess.get_file_as_string("res://shaders/planet_surface.gdshader")
	if not surface_shader_source.contains("uniform sampler2D albedo_texture") or not surface_shader_source.contains("use_albedo_texture"):
		errors.append("Planet surface shader must expose the real-map texture controls.")

	for shader_path in SHADERS:
		if not ResourceLoader.exists(shader_path):
			errors.append("Missing visual shader: " + shader_path)
			continue
		var shader_resource: Resource = load(shader_path)
		if not (shader_resource is Shader):
			errors.append("Visual shader did not load as a Shader resource: " + shader_path)

	# Guard against misspelled shader properties: headless loading is not a GPU compile.
	var planet_shader_source := FileAccess.get_file_as_string("res://shaders/planet_surface.gdshader")
	if planet_shader_source.contains("trough"):
		errors.append("Planet surface shader contains an unexpected 'trough' identifier.")
	if not planet_shader_source.contains("float rough = 0.88;") or not planet_shader_source.contains("ROUGHNESS = rough;"):
		errors.append("Planet surface shader roughness declaration and output must stay connected.")

	var earth := PlanetBody.new()
	earth.configure(PlanetCatalog.get_planet("earth"))
	if earth.find_child("EarthAtmosphere", true, false) == null:
		errors.append("Earth atmosphere layer was not created.")
	if earth.find_child("EarthCloudLayer", true, false) == null:
		errors.append("Earth cloud layer was not created.")
	if earth.find_child("TheMoon", true, false) == null:
		errors.append("The Moon visual body was not created.")
	earth.free()

	var saturn := PlanetBody.new()
	saturn.configure(PlanetCatalog.get_planet("saturn"))
	if saturn.find_child("SaturnRings", true, false) == null:
		errors.append("Saturn ring system was not created.")
	saturn.free()

	var sun := PlanetBody.new()
	sun.configure(PlanetCatalog.get_sun())
	if sun.find_child("SunCorona", true, false) == null:
		errors.append("The inner solar corona was not created.")
	if sun.find_child("SunOuterGlow", true, false) == null:
		errors.append("The outer solar glow was not created.")
	sun.free()

	if errors.is_empty():
		print("PASS: planetary surface, ring, atmosphere, cloud, and corona resources.")
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)

func _validate_body_texture_binding(body_data: Dictionary, errors: Array[String]) -> void:
	var body := PlanetBody.new()
	body.configure(body_data)
	var surface := body.find_child("PlanetSurface", true, false) as MeshInstance3D
	if surface == null:
		errors.append("Planet surface is missing for body: " + str(body_data.get("id", "unknown")))
	else:
		var material := surface.material_override as ShaderMaterial
		if material == null:
			errors.append("Planet surface material is missing for body: " + str(body_data.get("id", "unknown")))
		elif material.get_shader_parameter("use_albedo_texture") != true:
			errors.append("Licensed albedo map was not bound for body: " + str(body_data.get("id", "unknown")))
		elif not (material.get_shader_parameter("albedo_texture") is Texture2D):
			errors.append("Licensed albedo map binding is not a Texture2D for body: " + str(body_data.get("id", "unknown")))
	body.free()
