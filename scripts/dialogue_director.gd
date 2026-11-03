extends RefCounted
## Runtime interpreter for validated, declarative dialogue graphs.
## Dialogue data can select nodes but cannot execute arbitrary code.

signal dialogue_started(dialogue_id: String)
signal dialogue_node_changed(dialogue_id: String, node_id: String, node: Dictionary)
signal dialogue_finished(dialogue_id: String)

var _dialogues: Dictionary = {}
var _active_dialogue_id := ""
var _current_node_id := ""
var _finished := true


func configure(bundle: Dictionary) -> Array[String]:
	_dialogues.clear()
	var entries: Variant = bundle.get("dialogues", [])
	if not (entries is Array):
		return ["Dialogue content must be an array."]
	for entry_value in entries:
		if not (entry_value is Dictionary):
			return ["Dialogue content contains a non-object entry."]
		var entry: Dictionary = entry_value
		var dialogue_id := str(entry.get("id", ""))
		if dialogue_id.is_empty() or _dialogues.has(dialogue_id):
			return ["Dialogue content contains a missing or duplicate ID."]
		_dialogues[dialogue_id] = entry.duplicate(true)
	return []


func start_dialogue(dialogue_id: String) -> bool:
	if not _dialogues.has(dialogue_id):
		return false
	var dialogue: Dictionary = _dialogues[dialogue_id]
	var start_node := str(dialogue.get("start_node", ""))
	var nodes: Variant = dialogue.get("nodes", {})
	if not (nodes is Dictionary) or not nodes.has(start_node):
		return false
	_active_dialogue_id = dialogue_id
	_current_node_id = start_node
	_finished = false
	dialogue_started.emit(dialogue_id)
	_emit_current_node()
	return true


func is_active() -> bool:
	return not _finished and not _active_dialogue_id.is_empty()


func is_finished() -> bool:
	return _finished


func get_active_dialogue_id() -> String:
	return _active_dialogue_id if is_active() else ""


func get_current_node_id() -> String:
	return _current_node_id if is_active() else ""


func get_current_node() -> Dictionary:
	if not is_active():
		return {}
	var dialogue: Dictionary = _dialogues[_active_dialogue_id]
	var nodes: Dictionary = dialogue.get("nodes", {})
	var node: Variant = nodes.get(_current_node_id, {})
	return node.duplicate(true) if node is Dictionary else {}


func get_current_text() -> String:
	return str(get_current_node().get("text_ar", ""))


func get_choices() -> Array:
	var choices: Variant = get_current_node().get("choices", [])
	return choices.duplicate(true) if choices is Array else []


func choose(choice_index: int) -> bool:
	if not is_active():
		return false
	var choices := get_choices()
	if choice_index < 0 or choice_index >= choices.size():
		return false
	var choice: Dictionary = choices[choice_index]
	return _move_to(str(choice.get("next", "")))


func advance() -> bool:
	if not is_active():
		return false
	var node := get_current_node()
	if bool(node.get("terminal", false)):
		_finish()
		return true
	if not node.has("next"):
		return false
	return _move_to(str(node.get("next", "")))


func skip() -> bool:
	if not is_active():
		return false
	_finish()
	return true


func restart() -> bool:
	if _active_dialogue_id.is_empty() or not _dialogues.has(_active_dialogue_id):
		return false
	return start_dialogue(_active_dialogue_id)


func _move_to(next_node_id: String) -> bool:
	if next_node_id == "end":
		_finish()
		return true
	var dialogue: Dictionary = _dialogues.get(_active_dialogue_id, {})
	var nodes: Dictionary = dialogue.get("nodes", {})
	if not nodes.has(next_node_id):
		return false
	_current_node_id = next_node_id
	_emit_current_node()
	return true


func _emit_current_node() -> void:
	dialogue_node_changed.emit(_active_dialogue_id, _current_node_id, get_current_node())


func _finish() -> void:
	var finished_id := _active_dialogue_id
	_finished = true
	_current_node_id = ""
	dialogue_finished.emit(finished_id)
