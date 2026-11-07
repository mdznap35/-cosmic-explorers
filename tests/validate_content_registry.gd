extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")

const REQUIRED_CONTENT_IDS := {
	"characters": ["reem", "salim", "lulu"],
	"chapters": ["chapter.prologue", "chapter.moon", "chapter.mars"],
	"missions": [
		"mission.prologue.signal",
		"mission.moon.light_reflection",
		"mission.mars.rover_survey",
		"mission.mars.evidence_sort",
		"mission.mars.echo_of_mars"
	],
	"science_cards": [
		"science.moon.reflected_light",
		"science.moon.phases",
		"science.mars.iron_oxide",
		"science.mars.water_evidence"
	],
	"dialogues": [
		"dialogue.prologue.signal",
		"dialogue.mars.first_sample",
		"dialogue.echo.signal",
		"dialogue.echo.photo",
		"dialogue.echo.lulu",
		"dialogue.echo.relay",
		"dialogue.echo.closure"
	],
	"rewards": [
		"reward.sticker.first_signal",
		"reward.badge.moon_friend",
		"reward.badge.mars_field_detective",
		"reward.sticker.evidence_detective",
		"reward.badge.echo_signal_detective"
	]
}


func _initialize() -> void:
	call_deferred("_run_content_registry_tests")


func _run_content_registry_tests() -> void:
	var bundle: Dictionary = ContentRegistry.load_bundle()
	var errors: Array[String] = ContentRegistry.validate_bundle(bundle)

	if int(bundle.get("schema_version", 0)) != ContentRegistry.SCHEMA_VERSION:
		errors.append("The content bundle schema version is incorrect.")

	for content_kind in REQUIRED_CONTENT_IDS:
		var entries: Variant = bundle.get(content_kind, [])
		if not (entries is Array):
			errors.append("The " + content_kind + " content must be an array.")
			continue
		var available_ids := {}
		for entry in entries:
			if entry is Dictionary:
				available_ids[str(entry.get("id", ""))] = true
		for required_id in REQUIRED_CONTENT_IDS[content_kind]:
			if not available_ids.has(required_id):
				errors.append("The " + content_kind + " content is missing required id: " + required_id)

	var duplicate_bundle: Dictionary = bundle.duplicate(true)
	var duplicate_mission: Dictionary = duplicate_bundle["missions"][0].duplicate(true)
	duplicate_bundle["missions"].append(duplicate_mission)
	var duplicate_errors: Array[String] = ContentRegistry.validate_bundle(duplicate_bundle)
	if not _contains_fragment(duplicate_errors, "Duplicate missions id"):
		errors.append("The validator must reject duplicate mission IDs.")

	var broken_reference_bundle: Dictionary = bundle.duplicate(true)
	broken_reference_bundle["missions"][0]["chapter_id"] = "chapter.missing"
	var broken_reference_errors: Array[String] = ContentRegistry.validate_bundle(broken_reference_bundle)
	if not _contains_fragment(broken_reference_errors, "references a missing chapter"):
		errors.append("The validator must reject broken chapter references.")

	var broken_dialogue_bundle: Dictionary = bundle.duplicate(true)
	broken_dialogue_bundle["dialogues"][0]["nodes"]["notice"]["choices"][0]["next"] = "node.not_found"
	var broken_dialogue_errors: Array[String] = ContentRegistry.validate_bundle(broken_dialogue_bundle)
	if not _contains_fragment(broken_dialogue_errors, "points to missing node"):
		errors.append("The validator must reject broken dialogue links.")

	var broken_character_bundle: Dictionary = bundle.duplicate(true)
	broken_character_bundle["missions"][0]["primary_character_id"] = "character.unknown"
	var broken_character_errors: Array[String] = ContentRegistry.validate_bundle(broken_character_bundle)
	if not _contains_fragment(broken_character_errors, "unknown primary character"):
		errors.append("The validator must reject missions assigned to unknown characters.")

	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return

	print("PASS: content bundle loading, required content IDs, schema, references, science provenance, dialogue graph, and negative cases.")
	quit(0)


func _contains_fragment(errors: Array[String], fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false
