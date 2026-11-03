extends RefCounted
## Data-driven playable character selection and ability lookup.

const VALID_CORE_IDS := ["reem", "salim", "lulu"]

var _characters: Dictionary = {}
var _selected_character_id := "reem"


func configure(bundle: Dictionary, preferred_character_id: String = "reem") -> Array[String]:
	var errors: Array[String] = []
	_characters.clear()
	var entries: Variant = bundle.get("characters", [])
	if not (entries is Array):
		return ["Character profiles must be an array."]

	for entry_value in entries:
		if not (entry_value is Dictionary):
			errors.append("Character profile must be an object.")
			continue
		var entry: Dictionary = entry_value
		var character_id := str(entry.get("id", ""))
		if character_id.is_empty() or _characters.has(character_id):
			errors.append("Character profile has a missing or duplicate ID.")
			continue
		_characters[character_id] = entry.duplicate(true)

	for character_id in VALID_CORE_IDS:
		if not _characters.has(character_id):
			errors.append("Missing core character: " + character_id)

	if not errors.is_empty():
		return errors

	_selected_character_id = preferred_character_id if _characters.has(preferred_character_id) else "reem"
	return []


func get_character_ids() -> Array[String]:
	var ids: Array[String] = []
	for character_id in _characters:
		ids.append(str(character_id))
	ids.sort_custom(_sort_by_selection_order)
	return ids


func get_selected_character_id() -> String:
	return _selected_character_id


func get_selected_character() -> Dictionary:
	return get_character(_selected_character_id)


func get_character(character_id: String) -> Dictionary:
	if not _characters.has(character_id):
		return {}
	return _characters[character_id].duplicate(true)


func select_character(character_id: String) -> bool:
	if not _characters.has(character_id):
		return false
	_selected_character_id = character_id
	return true


func has_ability(character_id: String, ability_id: String) -> bool:
	if not _characters.has(character_id) or ability_id.strip_edges().is_empty():
		return false
	var abilities: Variant = _characters[character_id].get("abilities", [])
	return abilities is Array and abilities.has(ability_id)


func selected_character_has_ability(ability_id: String) -> bool:
	return has_ability(_selected_character_id, ability_id)


func _sort_by_selection_order(left: String, right: String) -> bool:
	var left_order := int(_characters[left].get("selection_order", 999))
	var right_order := int(_characters[right].get("selection_order", 999))
	if left_order == right_order:
		return left < right
	return left_order < right_order
