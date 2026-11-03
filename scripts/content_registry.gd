extends RefCounted
## Loads and validates versioned, offline-first game content.
## Content data is declarative: it cannot execute arbitrary GDScript.

const SCHEMA_VERSION := 1
const CONTENT_FILES := {
	"chapters": "chapters.json",
	"characters": "characters.json",
	"missions": "missions.json",
	"science_cards": "science_cards.json",
	"dialogues": "dialogues.json",
	"rewards": "rewards.json"
}
const CHARACTER_IDS := ["reem", "salim", "lulu"]
const CERTAINTY_VALUES := ["established_fact", "evidence", "active_hypothesis", "fictional_worldbuilding"]


static func load_bundle(base_path: String = "res://data/content") -> Dictionary:
	var bundle := {
		"schema_version": SCHEMA_VERSION,
		"chapters": [],
		"characters": [],
		"missions": [],
		"science_cards": [],
		"dialogues": [],
		"rewards": [],
		"load_errors": []
	}
	var load_errors: Array[String] = []

	for content_kind in CONTENT_FILES:
		var kind := str(content_kind)
		var file_path := base_path + "/" + str(CONTENT_FILES[content_kind])
		if not FileAccess.file_exists(file_path):
			load_errors.append("Missing content file: " + file_path)
			continue

		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			load_errors.append("Unable to open content file: " + file_path)
			continue

		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if not (parsed is Dictionary):
			load_errors.append("Content root must be a JSON object: " + file_path)
			continue

		if int(parsed.get("schema_version", -1)) != SCHEMA_VERSION:
			load_errors.append("Unsupported schema version in " + file_path)
			continue

		var entries: Variant = parsed.get("entries", null)
		if not (entries is Array):
			load_errors.append("Content entries must be an array: " + file_path)
			continue

		bundle[kind] = entries

	bundle["load_errors"] = load_errors
	return bundle


static func validate_bundle(bundle: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var load_errors: Variant = bundle.get("load_errors", [])
	if load_errors is Array:
		for load_error in load_errors:
			errors.append(str(load_error))

	var indexes: Dictionary = {}
	for content_kind in CONTENT_FILES:
		var kind := str(content_kind)
		var entries: Variant = bundle.get(kind, null)
		if not (entries is Array):
			errors.append("Missing content array: " + kind)
			indexes[kind] = {}
			continue

		var index: Dictionary = {}
		for entry in entries:
			if not (entry is Dictionary):
				errors.append(kind + " contains a non-object entry.")
				continue
			var entry_id := str(entry.get("id", "")).strip_edges()
			if entry_id.is_empty():
				errors.append(kind + " contains an entry without an id.")
				continue
			if index.has(entry_id):
				errors.append("Duplicate " + kind + " id: " + entry_id)
			else:
				index[entry_id] = entry
		indexes[kind] = index

	var characters: Dictionary = indexes.get("characters", {})
	var chapters: Dictionary = indexes.get("chapters", {})
	var missions: Dictionary = indexes.get("missions", {})
	var science_cards: Dictionary = indexes.get("science_cards", {})
	var dialogues: Dictionary = indexes.get("dialogues", {})
	var rewards: Dictionary = indexes.get("rewards", {})

	if characters.size() < 3:
		errors.append("The content bundle needs the three core character profiles.")
	for character_id in characters:
		var character: Dictionary = characters[character_id]
		if str(character.get("name_ar", "")).strip_edges().is_empty():
			errors.append(str(character_id) + " needs an Arabic character name.")
		if str(character.get("role_ar", "")).strip_edges().is_empty():
			errors.append(str(character_id) + " needs a gameplay role.")
		var abilities: Variant = character.get("abilities", [])
		if not (abilities is Array) or abilities.is_empty():
			errors.append(str(character_id) + " needs at least one gameplay ability.")
		else:
			var ability_ids: Dictionary = {}
			for ability_value in abilities:
				var ability_id := str(ability_value).strip_edges()
				if ability_id.is_empty() or ability_ids.has(ability_id):
					errors.append(str(character_id) + " has a missing or duplicate ability.")
				else:
					ability_ids[ability_id] = true
		if str(character.get("controller_type", "")).strip_edges().is_empty():
			errors.append(str(character_id) + " needs a controller_type.")

	for chapter_id in chapters:
		var chapter: Dictionary = chapters[chapter_id]
		if str(chapter.get("title_ar", "")).strip_edges().is_empty():
			errors.append(str(chapter_id) + " needs an Arabic title.")
		var mission_ids: Variant = chapter.get("mission_ids", [])
		if not (mission_ids is Array):
			errors.append(str(chapter_id) + " mission_ids must be an array.")
			continue
		for mission_id in mission_ids:
			if not missions.has(str(mission_id)):
				errors.append(str(chapter_id) + " references missing mission: " + str(mission_id))

	for mission_id in missions:
		var mission: Dictionary = missions[mission_id]
		if not chapters.has(str(mission.get("chapter_id", ""))):
			errors.append(str(mission_id) + " references a missing chapter.")
		if str(mission.get("title_ar", "")).strip_edges().is_empty():
			errors.append(str(mission_id) + " needs an Arabic title.")
		if not characters.has(str(mission.get("primary_character_id", ""))):
			errors.append(str(mission_id) + " has an unknown primary character.")

		var objectives: Variant = mission.get("objectives", [])
		var required_objectives := 0
		var objective_ids: Dictionary = {}
		if not (objectives is Array) or objectives.is_empty():
			errors.append(str(mission_id) + " needs at least one objective.")
		else:
			for objective in objectives:
				if not (objective is Dictionary):
					errors.append(str(mission_id) + " contains an invalid objective.")
					continue
				var objective_id := str(objective.get("id", ""))
				if objective_id.is_empty() or objective_ids.has(objective_id):
					errors.append(str(mission_id) + " has a missing or duplicate objective id.")
				else:
					objective_ids[objective_id] = true
				if bool(objective.get("required", false)):
					required_objectives += 1
				if str(objective.get("event_id", "")).strip_edges().is_empty():
					errors.append(str(mission_id) + "/" + objective_id + " needs an event_id.")
		if required_objectives == 0:
			errors.append(str(mission_id) + " needs at least one required objective.")

		var card_ids: Variant = mission.get("science_card_ids", [])
		if not (card_ids is Array):
			errors.append(str(mission_id) + " science_card_ids must be an array.")
		else:
			for card_id in card_ids:
				if not science_cards.has(str(card_id)):
					errors.append(str(mission_id) + " references missing science card: " + str(card_id))

		var dialogue_ids: Variant = mission.get("dialogue_ids", [])
		if not (dialogue_ids is Array):
			errors.append(str(mission_id) + " dialogue_ids must be an array.")
		else:
			for dialogue_id in dialogue_ids:
				if not dialogues.has(str(dialogue_id)):
					errors.append(str(mission_id) + " references missing dialogue: " + str(dialogue_id))

		var reward_ids: Variant = mission.get("reward_ids", [])
		if not (reward_ids is Array):
			errors.append(str(mission_id) + " reward_ids must be an array.")
		else:
			for reward_id in reward_ids:
				if not rewards.has(str(reward_id)):
					errors.append(str(mission_id) + " references missing reward: " + str(reward_id))

	for card_id in science_cards:
		var card: Dictionary = science_cards[card_id]
		if str(card.get("title_ar", "")).strip_edges().is_empty():
			errors.append(str(card_id) + " needs an Arabic title.")
		if str(card.get("child_text_ar", "")).strip_edges().is_empty():
			errors.append(str(card_id) + " needs child-facing text.")
		if not CERTAINTY_VALUES.has(str(card.get("certainty", ""))):
			errors.append(str(card_id) + " has an unsupported certainty label.")
		var source: Variant = card.get("source", {})
		if not (source is Dictionary):
			errors.append(str(card_id) + " needs a source object.")
		else:
			var source_url := str(source.get("url", ""))
			var checked_on := str(source.get("checked_on", ""))
			if not source_url.begins_with("https://"):
				errors.append(str(card_id) + " needs an HTTPS source URL.")
			if checked_on.length() != 10 or checked_on.substr(4, 1) != "-" or checked_on.substr(7, 1) != "-":
				errors.append(str(card_id) + " needs checked_on in YYYY-MM-DD form.")

	for dialogue_id in dialogues:
		var dialogue: Dictionary = dialogues[dialogue_id]
		_validate_dialogue(str(dialogue_id), dialogue, errors, characters)

	for reward_id in rewards:
		var reward: Dictionary = rewards[reward_id]
		if str(reward.get("title_ar", "")).strip_edges().is_empty():
			errors.append(str(reward_id) + " needs an Arabic title.")
		var unlock: Variant = reward.get("unlock", {})
		if not (unlock is Dictionary):
			errors.append(str(reward_id) + " needs an unlock object.")
		elif not missions.has(str(unlock.get("mission_id", ""))):
			errors.append(str(reward_id) + " references a missing unlock mission.")

	return errors


static func _validate_dialogue(dialogue_id: String, dialogue: Dictionary, errors: Array[String], characters: Dictionary) -> void:
	var speaker_id := str(dialogue.get("speaker_id", ""))
	if not characters.has(speaker_id) and speaker_id != "mirqab":
		errors.append(dialogue_id + " has an unknown speaker.")

	var nodes: Variant = dialogue.get("nodes", {})
	if not (nodes is Dictionary) or nodes.is_empty():
		errors.append(dialogue_id + " needs a non-empty nodes object.")
		return

	var start_node := str(dialogue.get("start_node", ""))
	if not nodes.has(start_node):
		errors.append(dialogue_id + " references a missing start node.")
		return

	var pending: Array[String] = [start_node]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var node_id: String = pending.pop_back()
		if visited.has(node_id):
			continue
		visited[node_id] = true

		var node_value: Variant = nodes.get(node_id, null)
		if not (node_value is Dictionary):
			errors.append(dialogue_id + " has an invalid node: " + node_id)
			continue

		var node: Dictionary = node_value
		var destinations: Array[String] = []
		if node.has("next"):
			var next_id := str(node.get("next", ""))
			if next_id != "end":
				destinations.append(next_id)

		var choices: Variant = node.get("choices", [])
		if not (choices is Array):
			errors.append(dialogue_id + "/" + node_id + " choices must be an array.")
		else:
			for choice in choices:
				if not (choice is Dictionary):
					errors.append(dialogue_id + "/" + node_id + " contains an invalid choice.")
					continue
				if str(choice.get("text_ar", "")).strip_edges().is_empty():
					errors.append(dialogue_id + "/" + node_id + " contains a choice without text.")
				var choice_next := str(choice.get("next", ""))
				if choice_next.is_empty():
					errors.append(dialogue_id + "/" + node_id + " contains a choice without a destination.")
				elif choice_next != "end":
					destinations.append(choice_next)

		if str(node.get("text_ar", "")).strip_edges().is_empty():
			errors.append(dialogue_id + "/" + node_id + " needs Arabic dialogue text.")
		if destinations.is_empty() and not bool(node.get("terminal", false)):
			errors.append(dialogue_id + "/" + node_id + " must lead somewhere or be terminal.")

		for destination in destinations:
			if not nodes.has(destination):
				errors.append(dialogue_id + "/" + node_id + " points to missing node: " + destination)
			else:
				pending.append(destination)

	for node_key in nodes:
		if not visited.has(str(node_key)):
			errors.append(dialogue_id + " contains an unreachable dialogue node: " + str(node_key))
