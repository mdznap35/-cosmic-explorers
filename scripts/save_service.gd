extends RefCounted

const SAVE_PATH := "user://cosmic_explorers_progress.json"
const SAVE_VERSION := 6


static func _default_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"discovered": [],
		"missions_completed": 0,
		"best_mission_score": 0,
		"last_mission_score": 0,
		"guided_expeditions_completed": 0,
		"guided_expedition_stage": 0,
		"mission_runtime": {},
		"reward_runtime": {},
		"selected_character_id": "reem"
	}


static func migrate_state(parsed: Variant) -> Dictionary:
	if not (parsed is Dictionary):
		return _default_state()

	var old_version := int(parsed.get("version", 0))
	if old_version < 1 or old_version > SAVE_VERSION:
		return _default_state()

	# Rebuild a known-good shape and copy only fields understood by this save version.
	var state := _default_state()
	var raw_discovered: Variant = parsed.get("discovered", [])
	if raw_discovered is Array:
		var valid_ids := ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]
		for planet_id in raw_discovered:
			if planet_id is String and valid_ids.has(planet_id) and not state["discovered"].has(planet_id):
				state["discovered"].append(planet_id)

	var selected_character_id := str(parsed.get("selected_character_id", "reem"))
	if ["reem", "salim", "lulu"].has(selected_character_id):
		state["selected_character_id"] = selected_character_id

	state["missions_completed"] = maxi(0, int(parsed.get("missions_completed", 0)))
	state["best_mission_score"] = maxi(0, int(parsed.get("best_mission_score", 0)))
	state["last_mission_score"] = maxi(0, int(parsed.get("last_mission_score", 0)))
	state["guided_expeditions_completed"] = maxi(0, int(parsed.get("guided_expeditions_completed", 0)))
	state["guided_expedition_stage"] = clampi(int(parsed.get("guided_expedition_stage", 0)), 0, 8)

	var mission_runtime: Variant = parsed.get("mission_runtime", {})
	if mission_runtime is Dictionary:
		state["mission_runtime"] = mission_runtime.duplicate(true)
	var reward_runtime: Variant = parsed.get("reward_runtime", {})
	if reward_runtime is Dictionary:
		state["reward_runtime"] = reward_runtime.duplicate(true)

	return state


static func _load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_state()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_state()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return migrate_state(parsed)


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



static func get_guided_expedition_count() -> int:
	return maxi(0, int(_load_state().get("guided_expeditions_completed", 0)))


static func get_guided_expedition_stage() -> int:
	return clampi(int(_load_state().get("guided_expedition_stage", 0)), 0, 8)


static func set_guided_expedition_stage(stage_index: int) -> int:
	var state := _load_state()
	state["guided_expedition_stage"] = clampi(stage_index, 0, 8)
	_write_state(state)
	return int(state["guided_expedition_stage"])


static func record_guided_expedition_completed() -> int:
	var state := _load_state()
	state["guided_expeditions_completed"] = maxi(0, int(state.get("guided_expeditions_completed", 0))) + 1
	state["guided_expedition_stage"] = 0
	_write_state(state)
	return get_guided_expedition_count()


static func load_gameplay_runtime() -> Dictionary:
	var state := _load_state()
	return {
		"mission": state.get("mission_runtime", {}).duplicate(true),
		"rewards": state.get("reward_runtime", {}).duplicate(true)
	}


static func save_gameplay_runtime(mission_state: Dictionary, reward_state: Dictionary) -> bool:
	var state := _load_state()
	state["mission_runtime"] = mission_state.duplicate(true)
	state["reward_runtime"] = reward_state.duplicate(true)
	return _write_state(state)


static func load_selected_character_id() -> String:
	return str(_load_state().get("selected_character_id", "reem"))


static func save_selected_character_id(character_id: String) -> bool:
	if not ["reem", "salim", "lulu"].has(character_id):
		return false
	var state := _load_state()
	state["selected_character_id"] = character_id
	return _write_state(state)
