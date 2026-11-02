extends SceneTree

const GuidedExpeditionCatalog = preload("res://scripts/guided_expedition_catalog.gd")
const PlanetCatalog = preload("res://scripts/planet_catalog.gd")
const SaveService = preload("res://scripts/save_service.gd")
const UIController = preload("res://scripts/ui_controller.gd")


func _initialize() -> void:
	call_deferred("_run_guided_expedition_test")


func _run_guided_expedition_test() -> void:
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

	if not errors.is_empty():
		_finish_with_errors(errors)
		return

	# Exercise the real UI flow, including a wrong choice, a correct discovery,
	# its planet fact, and the next-stage transition for all eight planets.
	var previous_count := SaveService.get_guided_expedition_count()
	var interface := UIController.new()
	interface.configure(planets, [], PlanetCatalog.get_sun())
	root.add_child(interface)
	await process_frame

	SaveService.set_guided_expedition_stage(4)
	interface._start_guided_expedition()
	if interface._guide_index != 4:
		errors.append("The guided expedition must resume from its saved planet stage.")
	interface._close_guided_expedition()
	interface._start_guided_expedition()
	if interface._guide_index != 4:
		errors.append("Closing and reopening the route must preserve its current stage.")
	SaveService.set_guided_expedition_stage(0)
	interface._start_guided_expedition()
	if not interface._guide_active or not interface._guide_panel.visible:
		errors.append("Starting the guided expedition must open its active panel.")

	for stage in stages:
		var target_id := str(stage.get("planet_id", ""))
		var wrong_id := "venus" if target_id != "venus" else "mercury"
		interface.show_planet(wrong_id, [])
		if interface._guide_waiting_next:
			errors.append(target_id + " incorrectly advanced after a wrong selection.")
		if interface._guide_fact_label.visible:
			errors.append(target_id + " displayed a discovery fact before the correct planet was found.")

		interface.show_planet(target_id, [])
		if not interface._guide_waiting_next:
			errors.append(target_id + " did not unlock after the correct selection.")
		var facts: Array = PlanetCatalog.get_planet(target_id).get("facts", [])
		if facts.is_empty() or not interface._guide_fact_label.visible or not interface._guide_fact_label.text.contains(str(facts[0])):
			errors.append(target_id + " did not reveal its catalog learning fact.")
		if not interface._guide_advance_button.visible:
			errors.append(target_id + " did not expose the next-stage action.")
		interface._on_guided_expedition_advance()

	if not interface._guide_completed or interface._guide_active:
		errors.append("Completing all eight planets must close the active route and show its completion state.")
	if SaveService.get_guided_expedition_count() != previous_count + 1:
		errors.append("Completing the route must persist exactly one guided-expedition completion.")
	if SaveService.get_guided_expedition_stage() != 0:
		errors.append("Completing the route must reset the saved stage for the next replay.")
	if not interface._guide_fact_label.visible or not interface._guide_fact_label.text.contains("تم حفظ إنجازك"):
		errors.append("The completion panel must confirm that progress was saved locally.")

	# Opening the replay action must not count a second completion.
	interface._on_guided_expedition_advance()
	if not interface._guide_active or SaveService.get_guided_expedition_count() != previous_count + 1:
		errors.append("Replaying the route must not increment completion before it is finished again.")

	interface._close_guided_expedition()
	if interface._guide_panel.visible or interface._guide_active:
		errors.append("Closing the guided expedition must leave its panel hidden and inactive.")
	interface.queue_free()

	if errors.is_empty():
		print("PASS: guided route UI, wrong/correct choices, eight planet facts, replay, and local completion persistence.")
		quit(0)
		return
	_finish_with_errors(errors)


func _finish_with_errors(errors: Array[String]) -> void:
	for error in errors:
		push_error(error)
	quit(1)
