extends SceneTree

const SurveyScene = preload("res://scenes/prototypes/mars_rover_survey.tscn")
const SAVE_PATH := "user://mars_rover_survey_prototype.json"
const EXPECTED_SITES := ["layered_rock", "sand_ripples", "crater_rim"]
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
	call_deferred("_run_survey_tests")


func _run_survey_tests() -> void:
	_remove_test_save()
	var survey = SurveyScene.instantiate()
	root.add_child(survey)
	await process_frame

	var site_ids: PackedStringArray = survey.get_site_ids()
	if site_ids.size() != EXPECTED_SITES.size():
		_errors.append("The Mars survey must expose exactly three stable observation sites.")
	for site_id in EXPECTED_SITES:
		if not site_ids.has(site_id):
			_errors.append("Missing Mars survey site: " + site_id)

	var loaded_assets: PackedStringArray = survey.get_loaded_asset_ids()
	for asset_id in EXPECTED_ASSETS:
		if not loaded_assets.has(asset_id):
			_errors.append("Pinned KayKit sample asset did not load: " + asset_id)

	if survey.scan_site("unknown_site"):
		_errors.append("The survey must reject unknown site IDs.")
	if survey.scan_site("layered_rock"):
		_errors.append("A site outside scan range must not be recorded.")

	var rover: CharacterBody3D = survey.get_rover()
	if not is_instance_valid(rover):
		_errors.append("The survey must create a controllable rover.")
	else:
		rover.global_position = survey.get_site_position("layered_rock")
		if not survey.scan_site("layered_rock"):
			_errors.append("The first in-range site should be recorded.")
		rover.global_position = survey.get_site_position("sand_ripples")
		if not survey.scan_site("sand_ripples"):
			_errors.append("The second in-range site should be recorded.")

	if survey.get_scan_progress() != 2 or survey.is_survey_completed():
		_errors.append("Two site scans should persist as a partial checkpoint.")

	survey.queue_free()
	await process_frame

	var resumed = SurveyScene.instantiate()
	root.add_child(resumed)
	await process_frame
	if resumed.get_scan_progress() != 2 or resumed.is_survey_completed():
		_errors.append("A new survey scene must restore the partial checkpoint.")

	var resumed_rover: CharacterBody3D = resumed.get_rover()
	if is_instance_valid(resumed_rover):
		resumed_rover.global_position = resumed.get_site_position("crater_rim")
		if not resumed.scan_site("crater_rim"):
			_errors.append("The final observation site should be accepted after resuming.")
		if resumed.scan_site("crater_rim"):
			_errors.append("A previously recorded site must not be counted twice.")

	if not resumed.is_survey_completed() or resumed.get_scan_progress() != 3:
		_errors.append("The survey should complete after all three sites are recorded.")

	resumed.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: Mars rover movement scene, eight staged CC0 props, three survey sites, range checks, partial checkpoint, resume, and duplicate protection.")
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
