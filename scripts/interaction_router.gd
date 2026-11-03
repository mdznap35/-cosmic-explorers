extends RefCounted
## Routes allow-listed gameplay events from world interactions to mission systems.
## Payloads are data-only; they cannot invoke methods or execute scripts.

signal interaction_received(event_id: String, payload: Dictionary)

var _allowed_event_ids: Dictionary = {}


func configure(bundle: Dictionary) -> Array[String]:
	_allowed_event_ids.clear()
	var missions: Variant = bundle.get("missions", [])
	if not (missions is Array):
		return ["Mission data must be an array before interactions can be routed."]

	for mission_value in missions:
		if not (mission_value is Dictionary):
			continue
		var objectives: Variant = mission_value.get("objectives", [])
		if not (objectives is Array):
			continue
		for objective_value in objectives:
			if not (objective_value is Dictionary):
				continue
			var event_id := str(objective_value.get("event_id", "")).strip_edges()
			if not event_id.is_empty():
				_allowed_event_ids[event_id] = true

	if _allowed_event_ids.is_empty():
		return ["No allow-listed interaction events were found in mission content."]
	return []


func publish(event_id: String, payload: Dictionary = {}) -> bool:
	if not _allowed_event_ids.has(event_id):
		return false
	if not _is_safe_value(payload, 0):
		return false
	interaction_received.emit(event_id, payload.duplicate(true))
	return true


func is_event_allowed(event_id: String) -> bool:
	return _allowed_event_ids.has(event_id)


func get_allowed_event_ids() -> Array[String]:
	var result: Array[String] = []
	for event_id in _allowed_event_ids:
		result.append(str(event_id))
	result.sort()
	return result


func _is_safe_value(value: Variant, depth: int) -> bool:
	if depth > 4:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item in value:
				if not _is_safe_value(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not (key is String) or not _is_safe_value(value[key], depth + 1):
					return false
			return true
		_:
			return false
