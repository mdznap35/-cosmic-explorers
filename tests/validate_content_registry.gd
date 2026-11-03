extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")


func _initialize() -> void:
	call_deferred("_run_content_registry_tests")


func _run_content_registry_tests() -> void:
	var bundle: Dictionary = ContentRegistry.load_bundle()
	var errors: Array[String] = ContentRegistry.validate_bundle(bundle)

	if int(bundle.get("schema_version", 0)) != ContentRegistry.SCHEMA_VERSION:
		errors.append("The content bundle schema version is incorrect.")
	if not bundle.get("chapters", []) is Array or bundle.get("chapters", []).size() != 3:
		errors.append("Expected the prologue, Moon, and Mars chapters.")
	if not bundle.get("missions", []) is Array or bundle.get("missions", []).size() != 4:
		errors.append("Expected four first-slice missions.")
	if not bundle.get("science_cards", []) is Array or bundle.get("science_cards", []).size() != 4:
		errors.append("Expected four source-backed science cards.")
	if not bundle.get("dialogues", []) is Array or bundle.get("dialogues", []).size() != 2:
		errors.append("Expected two scripted dialogue sequences.")
	if not bundle.get("rewards", []) is Array or bundle.get("rewards", []).size() != 4:
		errors.append("Expected four first-slice rewards.")

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

	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return

	print("PASS: content bundle loading, schema, IDs, references, science provenance, dialogue graph, and negative cases.")
	quit(0)


func _contains_fragment(errors: Array[String], fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false
