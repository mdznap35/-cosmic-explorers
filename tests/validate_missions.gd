extends SceneTree

const MissionCatalog = preload("res://scripts/mission_catalog.gd")


func _initialize() -> void:
	var errors: Array[String] = []
	var questions: Array = MissionCatalog.get_questions()
	var ids: Dictionary = {}

	if questions.size() != 9:
		errors.append("The first mission must include exactly one question for the Sun and each of the eight planets.")

	for question in questions:
		var question_id := str(question.get("id", ""))
		if question_id.is_empty() or ids.has(question_id):
			errors.append("Mission question IDs must be present and unique.")
		else:
			ids[question_id] = true

		var prompt := str(question.get("prompt", ""))
		var options: Variant = question.get("options", [])
		var correct_index := int(question.get("correct_index", -1))
		if prompt.is_empty():
			errors.append(question_id + " has no prompt.")
		if not (options is Array) or options.size() != 3:
			errors.append(question_id + " must have exactly three simple answer choices.")
		elif correct_index < 0 or correct_index >= options.size():
			errors.append(question_id + " has an invalid correct answer index.")
		elif str(options[correct_index]).is_empty():
			errors.append(question_id + " has an empty correct answer.")
		if str(question.get("explanation", "")).is_empty():
			errors.append(question_id + " needs a learning explanation.")
		if not str(question.get("source_url", "")).begins_with("https://science.nasa.gov/"):
			errors.append(question_id + " needs a primary NASA source URL.")

	if errors.is_empty():
		print("PASS: mission question IDs, answer choices, explanations, and NASA provenance.")
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)
