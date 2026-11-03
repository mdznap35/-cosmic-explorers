extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")

var _node_changes: Array[String] = []
var _finished_ids: Array[String] = []


func _initialize() -> void:
	_run_dialogue_tests()


func _run_dialogue_tests() -> void:
	var errors: Array[String] = []
	var bundle: Dictionary = ContentRegistry.load_bundle()
	errors.append_array(ContentRegistry.validate_bundle(bundle))
	var director = DialogueDirector.new()
	errors.append_array(director.configure(bundle))
	director.dialogue_node_changed.connect(_on_node_changed)
	director.dialogue_finished.connect(_on_dialogue_finished)

	if not director.start_dialogue("dialogue.prologue.signal"):
		errors.append("The prologue dialogue should start.")
	if director.get_current_node_id() != "notice" or director.get_choices().size() != 2:
		errors.append("The prologue opening node should expose its two choices.")
	if not director.choose(1) or director.get_current_node_id() != "identify":
		errors.append("Selecting a dialogue choice should advance to its target node.")
	if not director.advance() or director.get_current_node_id() != "team":
		errors.append("A linear dialogue node should advance to the next node.")
	if not director.advance() or not director.is_finished():
		errors.append("A terminal node should finish the dialogue.")
	if _finished_ids != ["dialogue.prologue.signal"]:
		errors.append("Dialogue completion should be emitted exactly once.")

	if not director.start_dialogue("dialogue.mars.first_sample"):
		errors.append("The Mars dialogue should start.")
	if not director.choose(1) or director.get_current_node_id() != "magnify":
		errors.append("The alternate magnify branch should be reachable.")
	if not director.advance() or director.get_current_node_id() != "iron":
		errors.append("The magnify branch should rejoin the shared explanation.")
	if not director.advance() or director.get_current_node_id() != "evidence":
		errors.append("The dialogue should advance to the evidence explanation.")
	if not director.skip() or not director.is_finished():
		errors.append("The dialogue should be skippable.")
	if director.choose(0):
		errors.append("Choices must be rejected after the dialogue has ended.")
	if director.start_dialogue("dialogue.missing"):
		errors.append("Unknown dialogue IDs must not start.")

	if errors.is_empty():
		print("PASS: branching dialogue, linear advance, terminal completion, skip, and invalid state rejection.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)


func _on_node_changed(_dialogue_id: String, node_id: String, _node: Dictionary) -> void:
	_node_changes.append(node_id)


func _on_dialogue_finished(dialogue_id: String) -> void:
	_finished_ids.append(dialogue_id)
