extends SceneTree

const GameplayRuntime = preload("res://scripts/gameplay_runtime.gd")
const SaveService = preload("res://scripts/save_service.gd")


func _initialize() -> void:
	_run_gameplay_runtime_integration_tests()


func _run_gameplay_runtime_integration_tests() -> void:
	var errors: Array[String] = []
	var original_state: Dictionary = SaveService._load_state()

	# Start with a clean game-runtime snapshot while preserving the runner's other save fields.
	if not SaveService.save_gameplay_runtime({}, {}):
		errors.append("The integration test could not initialize empty gameplay snapshots.")
		_restore_and_finish(original_state, errors)
		return

	var runtime = GameplayRuntime.new()
	var init_errors: Array[String] = runtime.initialize()
	errors.append_array(init_errors)
	if not errors.is_empty():
		_restore_and_finish(original_state, errors)
		return

	var start_result: Dictionary = runtime.start_mission("mission.mars.rover_survey")
	if not bool(start_result.get("accepted", false)) or not bool(start_result.get("persisted", false)):
		errors.append("Starting a mission must persist its active state.")
		_restore_and_finish(original_state, errors)
		return

	runtime.record_event("mars.site.selected")
	runtime.record_event("scanner.sample_recorded")
	var completion: Dictionary = runtime.record_event("scanner.sample_recorded")
	if not bool(completion.get("mission_completed", false)):
		errors.append("The Mars mission must complete through the integrated runtime.")
	if not bool(completion.get("persisted", false)):
		errors.append("The completed mission and reward snapshot must persist.")
	if not _has_value(completion.get("unlocked_reward_ids", []), "reward.badge.mars_field_detective"):
		errors.append("The integrated runtime must unlock the configured Mars badge.")

	var saved_runtime: Dictionary = SaveService.load_gameplay_runtime()
	var mission_snapshot: Dictionary = saved_runtime.get("mission", {})
	var reward_snapshot: Dictionary = saved_runtime.get("rewards", {})
	if not mission_snapshot.get("completed_mission_ids", []).has("mission.mars.rover_survey"):
		errors.append("The completed Mars mission must be written to the save file.")
	if not reward_snapshot.get("unlocked_reward_ids", []).has("reward.badge.mars_field_detective"):
		errors.append("The Mars reward must be written to the save file.")

	var resumed_runtime = GameplayRuntime.new()
	var resume_errors: Array[String] = resumed_runtime.initialize()
	errors.append_array(resume_errors)
	if not resumed_runtime.is_mission_completed("mission.mars.rover_survey"):
		errors.append("A new runtime instance must restore the completed mission.")
	if not resumed_runtime.get_unlocked_reward_ids().has("reward.badge.mars_field_detective"):
		errors.append("A new runtime instance must restore the unlocked reward.")

	# Replay is allowed, but the first-completion reward stays unique.
	var replay_start: Dictionary = resumed_runtime.start_mission("mission.mars.rover_survey")
	if not bool(replay_start.get("accepted", false)):
		errors.append("The completed replayable mission should be startable again.")
	resumed_runtime.record_event("mars.site.selected")
	resumed_runtime.record_event("scanner.sample_recorded")
	var replay_completion: Dictionary = resumed_runtime.record_event("scanner.sample_recorded")
	if not bool(replay_completion.get("mission_completed", false)):
		errors.append("The replayed integrated mission should complete.")
	if not replay_completion.get("unlocked_reward_ids", []).is_empty():
		errors.append("The integrated replay must not issue the first-completion reward again.")

	_restore_and_finish(original_state, errors)


func _has_value(values: Array, expected: String) -> bool:
	for value in values:
		if str(value) == expected:
			return true
	return false


func _restore_and_finish(original_state: Dictionary, errors: Array[String]) -> void:
	if not SaveService._write_state(original_state):
		errors.append("The integration test could not restore the original local save.")
	if errors.is_empty():
		print("PASS: integrated content, mission events, reward unlocks, disk persistence, process-style restore, and replay idempotency.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)
