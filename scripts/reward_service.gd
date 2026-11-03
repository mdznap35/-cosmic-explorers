extends RefCounted
## Idempotent local reward ledger. The exported snapshot is designed for SaveService.

signal reward_unlocked(reward_id: String)

const STATE_VERSION := 1
const ContentRegistry = preload("res://scripts/content_registry.gd")

var _rewards: Dictionary = {}
var _unlocked: Dictionary = {}


func configure(bundle: Dictionary, saved_state: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = ContentRegistry.validate_bundle(bundle)
	if not errors.is_empty():
		return errors

	_rewards.clear()
	for reward_value in bundle.get("rewards", []):
		var reward: Dictionary = reward_value
		_rewards[str(reward.get("id", ""))] = reward.duplicate(true)

	restore_state(saved_state)
	return errors


func unlock_for_mission(mission_id: String) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for reward_id in _rewards:
		var reward: Dictionary = _rewards[reward_id]
		var unlock: Dictionary = reward.get("unlock", {})
		if str(unlock.get("mission_id", "")) != mission_id:
			continue
		if str(unlock.get("event_id", "")) != "mission.completed":
			continue
		if _unlocked.has(reward_id) and not bool(reward.get("repeatable", false)):
			continue

		_unlocked[reward_id] = true
		newly_unlocked.append(str(reward_id))
		reward_unlocked.emit(str(reward_id))

	return newly_unlocked


func has_reward(reward_id: String) -> bool:
	return _unlocked.has(reward_id)


func get_unlocked_ids() -> Array[String]:
	var result: Array[String] = []
	for reward_id in _unlocked:
		result.append(str(reward_id))
	result.sort()
	return result


func get_reward(reward_id: String) -> Dictionary:
	if not _rewards.has(reward_id):
		return {}
	return _rewards[reward_id].duplicate(true)


func export_state() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"unlocked_reward_ids": get_unlocked_ids()
	}


func restore_state(state: Dictionary) -> void:
	_unlocked.clear()
	if int(state.get("version", 0)) != STATE_VERSION:
		return
	var raw_ids: Variant = state.get("unlocked_reward_ids", [])
	if not (raw_ids is Array):
		return
	for reward_id_value in raw_ids:
		var reward_id := str(reward_id_value)
		if _rewards.has(reward_id):
			_unlocked[reward_id] = true
