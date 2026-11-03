extends RefCounted
## Event-driven mission progression. Persistence is exposed as a versioned snapshot.
## The host SaveService can store this snapshot without coupling missions to UI scenes.

signal mission_started(mission_id: String)
signal objective_progressed(mission_id: String, objective_id: String, current: int, target: int)
signal mission_completed(mission_id: String, reward_ids: Array)

const STATE_VERSION := 1
const ContentRegistry = preload("res://scripts/content_registry.gd")

var _missions: Dictionary = {}
var _active_mission_id := ""
var _progress: Dictionary = {}
var _completed_missions: Dictionary = {}


func configure(bundle: Dictionary, saved_state: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = ContentRegistry.validate_bundle(bundle)
	if not errors.is_empty():
		return errors

	_missions.clear()
	for mission_value in bundle.get("missions", []):
		var mission: Dictionary = mission_value
		_missions[str(mission.get("id", ""))] = mission.duplicate(true)

	restore_state(saved_state)
	return errors


func start_mission(mission_id: String) -> bool:
	if not _missions.has(mission_id) or not _active_mission_id.is_empty():
		return false

	var mission: Dictionary = _missions[mission_id]
	var already_completed := _completed_missions.has(mission_id)
	if already_completed and not bool(mission.get("replayable", false)):
		return false

	# A replay starts clean, while the completed flag remains to prevent duplicate rewards.
	if not _progress.has(mission_id) or already_completed:
		_progress[mission_id] = _make_empty_progress(mission)

	_active_mission_id = mission_id
	mission_started.emit(mission_id)
	return true


func cancel_active_mission() -> void:
	# Progress remains in the snapshot and can be resumed later.
	_active_mission_id = ""


func record_event(event_id: String, amount: int = 1) -> Dictionary:
	if _active_mission_id.is_empty() or event_id.strip_edges().is_empty() or amount <= 0:
		return {"accepted": false, "mission_completed": false, "reward_ids": []}

	var active_id := _active_mission_id
	var mission: Dictionary = _missions[active_id]
	var progress: Dictionary = _progress.get(active_id, {})
	var objectives: Array = mission.get("objectives", [])
	var changed := false
	var newly_completed: Array[String] = []

	for objective_value in objectives:
		if not (objective_value is Dictionary):
			continue
		var objective: Dictionary = objective_value
		if str(objective.get("event_id", "")) != event_id:
			continue

		var objective_id := str(objective.get("id", ""))
		if objective_id.is_empty():
			continue
		var target := maxi(1, int(objective.get("target_count", 1)))
		var current := clampi(int(progress.get(objective_id, 0)), 0, target)
		var updated := mini(target, current + amount)
		if updated == current:
			continue

		progress[objective_id] = updated
		changed = true
		objective_progressed.emit(active_id, objective_id, updated, target)
		if updated >= target:
			newly_completed.append(objective_id)

	_progress[active_id] = progress
	if not changed:
		return {
			"accepted": false,
			"mission_completed": false,
			"newly_completed_objectives": [],
			"reward_ids": []
		}

	var required_complete := true
	for objective_value in objectives:
		if not (objective_value is Dictionary):
			continue
		var objective: Dictionary = objective_value
		if not bool(objective.get("required", false)):
			continue
		var objective_id := str(objective.get("id", ""))
		var target := maxi(1, int(objective.get("target_count", 1)))
		if int(progress.get(objective_id, 0)) < target:
			required_complete = false
			break

	if not required_complete:
		return {
			"accepted": true,
			"mission_completed": false,
			"newly_completed_objectives": newly_completed,
			"reward_ids": []
		}

	var first_completion := not _completed_missions.has(active_id)
	_completed_missions[active_id] = true
	_active_mission_id = ""

	var reward_ids: Array[String] = []
	if first_completion:
		for reward_id in mission.get("reward_ids", []):
			reward_ids.append(str(reward_id))

	mission_completed.emit(active_id, reward_ids)
	return {
		"accepted": true,
		"mission_completed": true,
		"first_completion": first_completion,
		"newly_completed_objectives": newly_completed,
		"reward_ids": reward_ids
	}


func get_active_mission_id() -> String:
	return _active_mission_id


func is_mission_completed(mission_id: String) -> bool:
	return _completed_missions.has(mission_id)


func get_mission_progress(mission_id: String) -> Dictionary:
	if not _missions.has(mission_id):
		return {}
	var mission: Dictionary = _missions[mission_id]
	var saved_progress: Dictionary = _progress.get(mission_id, _make_empty_progress(mission))
	return {
		"mission_id": mission_id,
		"active": _active_mission_id == mission_id,
		"completed": _completed_missions.has(mission_id),
		"objectives": saved_progress.duplicate(true)
	}


func export_state() -> Dictionary:
	var progress_copy: Dictionary = {}
	for mission_id in _progress:
		var mission_progress: Variant = _progress[mission_id]
		if mission_progress is Dictionary:
			progress_copy[str(mission_id)] = mission_progress.duplicate(true)

	var completed_ids: Array[String] = []
	for mission_id in _completed_missions:
		completed_ids.append(str(mission_id))

	return {
		"version": STATE_VERSION,
		"active_mission_id": _active_mission_id,
		"progress": progress_copy,
		"completed_mission_ids": completed_ids
	}


func restore_state(state: Dictionary) -> void:
	_active_mission_id = ""
	_progress.clear()
	_completed_missions.clear()
	if int(state.get("version", 0)) != STATE_VERSION:
		return

	var raw_completed: Variant = state.get("completed_mission_ids", [])
	if raw_completed is Array:
		for mission_id_value in raw_completed:
			var mission_id := str(mission_id_value)
			if _missions.has(mission_id):
				_completed_missions[mission_id] = true

	var raw_progress: Variant = state.get("progress", {})
	if raw_progress is Dictionary:
		for mission_id in _missions:
			if not raw_progress.has(mission_id):
				continue
			var raw_mission_progress: Variant = raw_progress[mission_id]
			if not (raw_mission_progress is Dictionary):
				continue

			var mission: Dictionary = _missions[mission_id]
			var clean_progress := _make_empty_progress(mission)
			for objective_value in mission.get("objectives", []):
				if not (objective_value is Dictionary):
					continue
				var objective: Dictionary = objective_value
				var objective_id := str(objective.get("id", ""))
				if raw_mission_progress.has(objective_id):
					var target := maxi(1, int(objective.get("target_count", 1)))
					clean_progress[objective_id] = clampi(int(raw_mission_progress[objective_id]), 0, target)
			_progress[mission_id] = clean_progress

	var restored_active := str(state.get("active_mission_id", ""))
	if _missions.has(restored_active) and _progress.has(restored_active):
		var mission: Dictionary = _missions[restored_active]
		if not (_completed_missions.has(restored_active) and not bool(mission.get("replayable", false))):
			_active_mission_id = restored_active


func _make_empty_progress(mission: Dictionary) -> Dictionary:
	var progress: Dictionary = {}
	for objective_value in mission.get("objectives", []):
		if not (objective_value is Dictionary):
			continue
		var objective: Dictionary = objective_value
		var objective_id := str(objective.get("id", ""))
		if not objective_id.is_empty():
			progress[objective_id] = 0
	return progress
