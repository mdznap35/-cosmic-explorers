extends SceneTree

const BuilderScene = preload("res://scenes/prototypes/lunar_outpost_builder.tscn")
const SAVE_PATH := "user://lunar_outpost_builder.json"
const EXPECTED_COMPONENTS := [
	"landing_zone",
	"habitat",
	"solar_array",
	"communications_module"
]
const EXPECTED_ASSETS := [
	"basemodule_A",
	"lander_A",
	"landingpad_small",
	"rocks_A",
	"rocks_B",
	"solarpanel",
	"spacetruck",
	"structure_low"
]

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_builder_tests")


func _run_builder_tests() -> void:
	_remove_test_save()
	var builder = BuilderScene.instantiate()
	root.add_child(builder)
	await process_frame

	if builder.get_required_component_ids() != PackedStringArray(EXPECTED_COMPONENTS):
		_errors.append("The lunar builder must expose four stable construction component IDs.")
	if builder.place_component("habitat"):
		_errors.append("The builder must reject out-of-order placement without penalty.")
	if not builder.place_component("landing_zone"):
		_errors.append("The landing zone should be placeable as the first component.")
	if builder.get_build_progress() != 1 or builder.is_base_complete():
		_errors.append("The first construction step should be saved as partial progress.")

	builder.queue_free()
	await process_frame

	var resumed = BuilderScene.instantiate()
	root.add_child(resumed)
	await process_frame
	if resumed.get_build_progress() != 1:
		_errors.append("A new builder scene must restore the partial construction checkpoint.")
	if not resumed.get_placed_component_ids().has("landing_zone"):
		_errors.append("The restored checkpoint must retain the landing zone.")

	for component_id in EXPECTED_COMPONENTS.slice(1):
		if not resumed.place_component(component_id):
			_errors.append("Could not place the expected construction component: " + component_id)

	var loaded: PackedStringArray = resumed.get_loaded_asset_ids()
	for asset_id in EXPECTED_ASSETS:
		if not loaded.has(asset_id):
			_errors.append("Pinned CC0 model did not load after its placement/decorative use: " + asset_id)
	if resumed.place_component("solar_array"):
		_errors.append("A completed component must not be counted twice.")
	if not resumed.is_base_complete() or resumed.get_build_progress() != EXPECTED_COMPONENTS.size():
		_errors.append("The lunar outpost should complete after all four components are placed.")

	resumed.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: lunar outpost builder, eight pinned CC0 models, four construction steps, ordering, checkpoint restore, completion and duplicate protection.")
		quit(0)
		return
	for error in _errors:
		push_error(error)
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
