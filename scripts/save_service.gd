extends RefCounted

const SAVE_PATH := "user://cosmic_explorers_progress.json"
const SAVE_VERSION := 1


static func load_discovered() -> Array[String]:
	var discovered: Array[String] = []
	if not FileAccess.file_exists(SAVE_PATH):
		return discovered

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary):
		return discovered

	if int(parsed.get("version", 0)) != SAVE_VERSION:
		return discovered

	var raw_values: Variant = parsed.get("discovered", [])
	if not (raw_values is Array):
		return discovered

	for value in raw_values:
		if value is String and not discovered.has(value):
			discovered.append(value)
	return discovered


static func mark_discovered(planet_id: String) -> Array[String]:
	var discovered := load_discovered()
	if not discovered.has(planet_id):
		discovered.append(planet_id)

	var payload := {
		"version": SAVE_VERSION,
		"discovered": discovered
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload))
	return discovered
