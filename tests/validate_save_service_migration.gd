extends SceneTree

const SaveService = preload("res://scripts/save_service.gd")


func _initialize() -> void:
	_run_save_migration_tests()


func _run_save_migration_tests() -> void:
	var errors: Array[String] = []
	var original_state: Dictionary = SaveService._load_state()

	var version_one := SaveService.migrate_state({
		"version": 1,
		"discovered": ["mars", "unknown", "mars"]
	})
	if version_one.get("discovered", []) != ["mars"]:
		errors.append("Version 1 migration must preserve valid unique planet discoveries.")
	if int(version_one.get("version", 0)) != SaveService.SAVE_VERSION:
		errors.append("Migrated saves must use the current version.")
	var legacy_mission_runtime: Variant = version_one.get("mission_runtime", {})
	if not (legacy_mission_runtime is Dictionary) or not legacy_mission_runtime.is_empty():
		errors.append("Legacy saves must receive an empty mission runtime snapshot.")

	var version_four := SaveService.migrate_state({
		"version": 4,
		"discovered": ["earth", "mars"],
		"missions_completed": 7,
		"best_mission_score": 8,
		"last_mission_score": 6,
		"guided_expeditions_completed": 3,
		"guided_expedition_stage": 5
	})
	if version_four.get("discovered", []) != ["earth", "mars"]:
		errors.append("Version 4 migration must preserve discovered planets.")
	if int(version_four.get("missions_completed", -1)) != 7:
		errors.append("Version 4 migration must preserve mission statistics.")
	if int(version_four.get("guided_expedition_stage", -1)) != 5:
		errors.append("Version 4 migration must preserve guided expedition progress.")
	if version_four.get("reward_runtime", {}) != {}:
		errors.append("Version 4 migration must initialize an empty reward ledger.")

	var version_five := SaveService.migrate_state({
		"version": 5,
		"discovered": ["venus"],
		"mission_runtime": {
			"version": 1,
			"active_mission_id": "mission.mars.rover_survey",
			"progress": {"mission.mars.rover_survey": {"objective.mars.choose_site": 1}},
			"completed_mission_ids": []
		},
		"reward_runtime": {
			"version": 1,
			"unlocked_reward_ids": ["reward.badge.mars_field_detective"]
		}
	})
	if version_five.get("mission_runtime", {}).get("active_mission_id", "") != "mission.mars.rover_survey":
		errors.append("Version 5 migration must preserve the active mission snapshot.")
	if version_five.get("reward_runtime", {}).get("unlocked_reward_ids", []) != ["reward.badge.mars_field_detective"]:
		errors.append("Version 5 migration must preserve unlocked rewards.")

	var future_version := SaveService.migrate_state({"version": SaveService.SAVE_VERSION + 1, "discovered": ["mars"]})
	if future_version.get("discovered", []) != []:
		errors.append("Unknown future save versions must not be misread as current data.")

	# Exercise a real local write/read round-trip, then restore the runner's original save.
	var mission_snapshot := {
		"version": 1,
		"active_mission_id": "mission.moon.light_reflection",
		"progress": {"mission.moon.light_reflection": {"objective.moon.rotate_light": 1}},
		"completed_mission_ids": ["mission.prologue.signal"]
	}
	var reward_snapshot := {
		"version": 1,
		"unlocked_reward_ids": ["reward.sticker.first_signal"]
	}
	if not SaveService.save_gameplay_runtime(mission_snapshot, reward_snapshot):
		errors.append("Gameplay runtime snapshots should be written to local save storage.")
	else:
		var loaded := SaveService.load_gameplay_runtime()
		if not _deep_equal(loaded.get("mission", {}), mission_snapshot):
			errors.append("Mission runtime snapshot must survive a disk round-trip.")
		if not _deep_equal(loaded.get("rewards", {}), reward_snapshot):
			errors.append("Reward runtime snapshot must survive a disk round-trip.")

	if not SaveService._write_state(original_state):
		errors.append("The test must restore the save file that existed before it ran.")

func _deep_equal(left: Variant, right: Variant) -> bool:
	if typeof(left) == TYPE_DICTIONARY and typeof(right) == TYPE_DICTIONARY:
		if left.size() != right.size():
			return false
		for key in left:
			if not right.has(key) or not _deep_equal(left[key], right[key]):
				return false
		return true

	if typeof(left) == TYPE_ARRAY and typeof(right) == TYPE_ARRAY:
		if left.size() != right.size():
			return false
		for index in range(left.size()):
			if not _deep_equal(left[index], right[index]):
				return false
		return true

	var left_is_number := typeof(left) == TYPE_INT or typeof(left) == TYPE_FLOAT
	var right_is_number := typeof(right) == TYPE_INT or typeof(right) == TYPE_FLOAT
	if left_is_number and right_is_number:
		return is_equal_approx(float(left), float(right))

	return left == right

	if errors.is_empty():
		print("PASS: save v1-v5 migration, legacy progress preservation, gameplay snapshot persistence, and disk round-trip.")
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)
