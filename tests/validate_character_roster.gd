extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const CharacterRoster = preload("res://scripts/character_roster.gd")


func _initialize() -> void:
	_run_character_roster_tests()


func _run_character_roster_tests() -> void:
	var errors: Array[String] = []
	var bundle: Dictionary = ContentRegistry.load_bundle()
	errors.append_array(ContentRegistry.validate_bundle(bundle))

	var roster = CharacterRoster.new()
	errors.append_array(roster.configure(bundle, "lulu"))
	if roster.get_character_ids() != ["reem", "salim", "lulu"]:
		errors.append("Core characters must be returned in authored selection order.")
	if roster.get_selected_character_id() != "lulu":
		errors.append("A valid saved character preference must be selected.")
	if not roster.selected_character_has_ability("narrow_path_crawl"):
		errors.append("Lulu must expose the narrow-path ability.")
	if not roster.has_ability("salim", "rover_programming"):
		errors.append("Salim must expose the rover-programming ability.")
	if not roster.has_ability("reem", "photo_documentation"):
		errors.append("Reem must expose the photo-documentation ability.")
	if roster.select_character("unknown"):
		errors.append("Unknown characters must not be selectable.")
	if roster.get_selected_character_id() != "lulu":
		errors.append("A rejected selection must not change the active character.")
	if not roster.select_character("reem") or roster.get_selected_character_id() != "reem":
		errors.append("A valid character switch must update the active character.")
	if roster.has_ability("unknown", "field_observation"):
		errors.append("Unknown character IDs must not expose abilities.")

	if errors.is_empty():
		print("PASS: character profiles, deterministic roster order, selection, abilities, and invalid IDs.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)
