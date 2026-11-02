extends SceneTree

const PlanetBody = preload("res://scripts/planet_body.gd")
const PlanetCatalog = preload("res://scripts/planet_catalog.gd")

const SHADERS := [
	"res://shaders/planet_surface.gdshader",
	"res://shaders/saturn_rings.gdshader",
	"res://shaders/earth_atmosphere.gdshader",
	"res://shaders/earth_clouds.gdshader",
	"res://shaders/sun_corona.gdshader"
]


func _initialize() -> void:
	var errors: Array[String] = []

	for shader_path in SHADERS:
		if not ResourceLoader.exists(shader_path):
			errors.append("Missing visual shader: " + shader_path)
			continue
		var shader_resource: Resource = load(shader_path)
		if not (shader_resource is Shader):
			errors.append("Visual shader did not load as a Shader resource: " + shader_path)

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
