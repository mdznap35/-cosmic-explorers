extends RefCounted
## Coordinates content, mission progression, reward unlocks, and local save snapshots.
## UI scenes call this service; content data never executes arbitrary GDScript.

signal mission_started(mission_id: String)
signal objective_progressed(mission_id: String, objective_id: String, current: int, target: int)
signal mission_completed(mission_id: String, unlocked_reward_ids: Array)
signal reward_unlocked(reward_id: String)
signal persistence_failed(reason: String)

const ContentRegistry = preload("res://scripts/content_registry.gd")
const MissionDirector = preload("res://scripts/mission_director.gd")
const RewardService = preload("res://scripts/reward_service.gd")
const SaveService = preload("res://scripts/save_service.gd")

var _bundle: Dictionary = {}
var _mission_director
var _reward_service
var _initialized := false
var _initialization_errors: Array[String] = []


func initialize() -> Array[String]:
	_initialized = false
	_initialization_errors.clear()

	_bundle = ContentRegistry.load_bundle()
	_initialization_errors = ContentRegistry.validate_bundle(_bundle)
	if not _initialization_errors.is_empty():
		return _initialization_errors.duplicate()

	var saved_runtime: Dictionary = SaveService.load_gameplay_runtime()
	_mission_director = MissionDirector.new()
	var mission_errors: Array[String] = _mission_director.configure(
		_bundle,
		saved_runtime.get("mission", {})
	)
	_initialization_errors.append_array(mission_errors)

	_reward_service = RewardService.new()
	var reward_errors: Array[String] = _reward_service.configure(
		_bundle,
		saved_runtime.get("rewards", {})
	)
	_initialization_errors.append_array(reward_errors)

	if not _initialization_errors.is_empty():
		_mission_director = null
		_reward_service = null
		return _initialization_errors.duplicate()

	_mission_director.objective_progressed.connect(_on_objective_progressed)
	_reward_service.reward_unlocked.connect(_on_reward_unlocked)
	_initialized = true
	return []


func is_initialized() -> bool:
	return _initialized


func get_initialization_errors() -> Array[String]:
	return _initialization_errors.duplicate()


func start_mission(mission_id: String) -> Dictionary:
	if not _initialized:
		return _not_ready_result()
	var accepted: bool = _mission_director.start_mission(mission_id)
	if not accepted:
		return {
			"accepted": false,
			"persisted": false,
			"error": "Mission could not start. Check its ID or close the active mission first."
		}

	mission_started.emit(mission_id)
	var persisted := _persist_runtime()
	return {
		"accepted": true,
		"persisted": persisted,
		"error": "" if persisted else "Mission started in memory, but local progress could not be saved."
	}


func cancel_active_mission() -> bool:
	if not _initialized:
		return false
	_mission_director.cancel_active_mission()
	return _persist_runtime()


func record_event(event_id: String, amount: int = 1) -> Dictionary:
	if not _initialized:
		return _not_ready_result()
	var completed_mission_id: String = _mission_director.get_active_mission_id()
	var result: Dictionary = _mission_director.record_event(event_id, amount)
	if not bool(result.get("accepted", false)):
		result["persisted"] = false
		return result

	var unlocked_reward_ids: Array[String] = []
	if bool(result.get("mission_completed", false)) and bool(result.get("first_completion", false)):
		unlocked_reward_ids = _reward_service.unlock_for_mission(completed_mission_id)

	result["mission_id"] = completed_mission_id
	result["unlocked_reward_ids"] = unlocked_reward_ids
	var persisted := _persist_runtime()
	result["persisted"] = persisted
	if bool(result.get("mission_completed", false)):
		mission_completed.emit(completed_mission_id, unlocked_reward_ids)
	return result


func get_active_mission_id() -> String:
	if not _initialized:
		return ""
	return _mission_director.get_active_mission_id()


func get_mission_progress(mission_id: String) -> Dictionary:
	if not _initialized:
		return {}
	return _mission_director.get_mission_progress(mission_id)


func is_mission_completed(mission_id: String) -> bool:
	return _initialized and _mission_director.is_mission_completed(mission_id)


func get_unlocked_reward_ids() -> Array[String]:
	if not _initialized:
		return []
	return _reward_service.get_unlocked_ids()


func get_reward(reward_id: String) -> Dictionary:
	if not _initialized:
		return {}
	return _reward_service.get_reward(reward_id)


func _persist_runtime() -> bool:
	if not _initialized:
		return false
	var mission_state: Dictionary = _mission_director.export_state()
	var reward_state: Dictionary = _reward_service.export_state()
	var saved := SaveService.save_gameplay_runtime(mission_state, reward_state)
	if not saved:
		persistence_failed.emit("Unable to write mission and reward progress to local storage.")
	return saved


func _on_objective_progressed(
	mission_id: String,
	objective_id: String,
	current: int,
	target: int
) -> void:
	objective_progressed.emit(mission_id, objective_id, current, target)


func _on_reward_unlocked(reward_id: String) -> void:
	reward_unlocked.emit(reward_id)


func _not_ready_result() -> Dictionary:
	return {
		"accepted": false,
		"persisted": false,
		"error": "GameplayRuntime has not been initialized."
	}
