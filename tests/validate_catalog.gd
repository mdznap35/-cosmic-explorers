extends SceneTree

const PlanetCatalog = preload("res://scripts/planet_catalog.gd")
const OrbitMath = preload("res://scripts/orbit_math.gd")


func _initialize() -> void:
	var errors: Array[String] = []
	var planets: Array = PlanetCatalog.get_all()
	var ids: Dictionary = {}
	var previous_period := 0.0

	if planets.size() != 8:
		errors.append("Expected exactly eight major planets.")

	for planet in planets:
		var planet_id := str(planet.get("id", ""))
		if planet_id.is_empty():
			errors.append("A planet is missing its stable id.")
		elif ids.has(planet_id):
			errors.append("Duplicate planet id: " + planet_id)
		else:
			ids[planet_id] = true

		if str(planet.get("name", "")).is_empty():
			errors.append(planet_id + " is missing its Arabic name.")
		if str(planet.get("english", "")).is_empty():
			errors.append(planet_id + " is missing its English identifier.")
		if float(planet.get("distance", 0.0)) <= 0.0:
			errors.append(planet_id + " has an invalid visual orbit distance.")
		if float(planet.get("radius", 0.0)) <= 0.0:
			errors.append(planet_id + " has an invalid visual radius.")
		if float(planet.get("period_days", 0.0)) <= previous_period:
			errors.append("Orbital periods must increase in planet order.")
		previous_period = float(planet.get("period_days", 0.0))
		if not (planet.get("facts", []) is Array) or planet.get("facts", []).size() < 2:
			errors.append(planet_id + " needs at least two learning facts.")

	var sun := PlanetCatalog.get_sun()
	if sun.is_empty() or str(sun.get("id", "")) != "sun":
		errors.append("The Sun must be a separate star entry.")
	if float(sun.get("distance", -1.0)) != 0.0:
		errors.append("The Sun must be at the visual origin.")
	if sun.get("facts", []).size() < 2:
		errors.append("The Sun needs its own learning facts.")

	var earth := PlanetCatalog.get_planet("earth")
	if earth.is_empty():
		errors.append("Earth must exist in the catalog.")
	elif not str(earth.get("description", "")).contains("حتى الآن"):
		errors.append("Earth life statement must preserve scientific uncertainty.")

	if not PlanetCatalog.get_planet("pluto").is_empty():
		errors.append("Dwarf planets belong in a separate future catalog.")

	var quarter_orbit := OrbitMath.position_for(2.0, PI * 0.5)
	if absf(quarter_orbit.x) > 0.0001 or absf(quarter_orbit.z - 2.0) > 0.0001:
		errors.append("OrbitMath.position_for failed the quarter-orbit check.")

	var next_angle := OrbitMath.advance_angle(0.0, 1.0, 1.0)
	if absf(next_angle - 1.0) > 0.0001:
		errors.append("OrbitMath.advance_angle failed the basic step check.")

	if absf(OrbitMath.clamp_camera_distance(0.2) - 1.2) > 0.0001:
		errors.append("Camera distance lower bound failed.")
	if absf(OrbitMath.clamp_camera_distance(2.0) - 2.0) > 0.0001:
		errors.append("Camera distance should preserve valid close focus distances.")

	if errors.is_empty():
		print("PASS: 8-planet catalog, stable IDs, facts, period order, and orbit math.")
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)
