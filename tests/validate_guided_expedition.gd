extends SceneTree

const GuidedExpeditionCatalog = preload("res://scripts/guided_expedition_catalog.gd")
const PlanetCatalog = preload("res://scripts/planet_catalog.gd")


func _initialize() -> void:
	var errors: Array[String] = []
	var stages: Array = GuidedExpeditionCatalog.get_stages()
	var planets: Array = PlanetCatalog.get_all()
	var seen: Dictionary = {}

	if stages.size() != 8:
		errors.append("The guided expedition must contain exactly eight planet-discovery stages.")
	if planets.size() != 8:
		errors.append("The planet catalog must contain exactly eight major planets.")

	for index in range(mini(stages.size(), planets.size())):
		var stage: Dictionary = stages[index]
		var planet_id := str(stage.get("planet_id", ""))
		if planet_id.is_empty() or seen.has(planet_id):
			errors.append("Guided stages must have unique, stable planet IDs.")
		else:
			seen[planet_id] = true

		if planet_id != str(planets[index].get("id", "")):
			errors.append("Guided stages must follow the catalog's Sun-outward planet order.")
		if str(stage.get("clue", "")).is_empty():
			errors.append(planet_id + " needs a short discovery clue.")

		var planet: Dictionary = PlanetCatalog.get_planet(planet_id)
		if planet.is_empty():
			errors.append("Guided stage references an unknown planet: " + planet_id)
		elif not str(planet.get("source_url", "")).begins_with("https://science.nasa.gov/"):
			errors.append(planet_id + " must retain its primary science source.")

	if errors.is_empty():
		print("PASS: eight guided discovery stages, catalog order, and NASA source linkage.")
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)
