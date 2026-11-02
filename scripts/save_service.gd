extends RefCounted

const SAVE_PATH := "user://cosmic_explorers_progress.json"
const SAVE_VERSION := 2


static func _default_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"discovered": [],
		"missions_completed": 0,
		"best_mission_score": 0,
		"last_mission_score": 0
	}


static func _load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_state()

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary):
		return _default_state()

	var old_version := int(parsed.get("version", 0))
	if old_version < 1 or old_version > SAVE_VERSION:
		return _default_state()

	# Version 1 only stored discovered planets. Preserve that progress on migration.
	var state := _default_state()
	var raw_discovered: Variant = parsed.get("discovered", [])
	if raw_discovered is Array:
		var valid_ids := ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]
		for planet_id in raw_discovered:
			if planet_id is String and valid_ids.has(planet_id) and not state["discovered"].has(planet_id):
				state["discovered"].append(planet_id)

	state["missions_completed"] = maxi(0, int(parsed.get("missions_completed", 0)))
	state["best_mission_score"] = maxi(0, int(parsed.get("best_mission_score", 0)))
	state["last_mission_score"] = maxi(0, int(parsed.get("last_mission_score", 0)))
	return state


static func _write_state(state: Dictionary) -> bool:
	state["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to write local explorer progress.")
		return false
	file.store_string(JSON.stringify(state))
	return true


static func load_discovered() -> Array[String]:
	var discovered: Array[String] = []
	var state := _load_state()
	for value in state.get("discovered", []):
		if value is String and not discovered.has(value):
			discovered.append(value)
	return discovered


static func mark_discovered(planet_id: String) -> Array[String]:
	var state := _load_state()
	var valid_ids := ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]
	if valid_ids.has(planet_id) and not state["discovered"].has(planet_id):
		state["discovered"].append(planet_id)
	_write_state(state)
	return load_discovered()


static func get_mission_stats() -> Dictionary:
	var state := _load_state()
	return {
		"completed": int(state.get("missions_completed", 0)),
		"best_score": int(state.get("best_mission_score", 0)),
		"last_score": int(state.get("last_mission_score", 0))
	}


static func record_mission_result(score: int, total: int) -> Dictionary:
	var state := _load_state()
	var safe_total := maxi(0, total)
	var safe_score := clampi(score, 0, safe_total)
	state["missions_completed"] = int(state.get("missions_completed", 0)) + 1
	state["last_mission_score"] = safe_score
	state["best_mission_score"] = maxi(int(state.get("best_mission_score", 0)), safe_score)
	_write_state(state)
	return get_mission_stats()
