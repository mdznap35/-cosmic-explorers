extends SceneTree

const RouteScene = preload("res://scenes/prototypes/lunar_rover_route_planner.tscn")
const SAVE_PATH := "user://lunar_rover_routes.json"
const LEVEL_ONE_SOLUTION := ["right", "right", "up", "up", "up", "up", "right", "right"]
const LEVEL_TWO_SOLUTION := ["up", "up", "right", "right", "right", "right", "up", "up"]
const LEVEL_THREE_SOLUTION := ["up", "up", "right", "right", "up", "down", "right", "right", "down", "up", "up", "up"]

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_remove_test_save()
	var route = RouteScene.instantiate()
	root.add_child(route)
	await process_frame

	if route.get_level_ids().size() != 3:
		_errors.append("The lunar rover route planner must expose three levels.")
	if route.add_command("teleport"):
		_errors.append("Unknown movement commands must be rejected.")
	if route.execute_program():
		_errors.append("An empty command program must not complete a route.")

	route.add_command("left")
	if route.execute_program():
		_errors.append("A route leaving the grid must be rejected.")
	route.clear_commands()

	for command_id in LEVEL_ONE_SOLUTION:
		if not route.add_command(command_id):
			_errors.append("Could not add a valid level-one command: " + command_id)
	if not route.execute_program():
		_errors.append("The first route should collect its sample and reach the base.")
	if not route.get_completed_level_ids().has("route_01"):
		_errors.append("The first route completion should be saved.")

	if not route.next_level() or route.get_current_level_id() != "route_02":
		_errors.append("The planner should advance to the second unlocked route.")
	for command_id in LEVEL_TWO_SOLUTION:
		route.add_command(command_id)
	if not route.execute_program():
		_errors.append("The second route should navigate around rocks and collect its sample.")

	route.queue_free()
	await process_frame

	var resumed = RouteScene.instantiate()
	root.add_child(resumed)
	await process_frame
	if resumed.get_completed_level_ids().size() != 2 or resumed.get_current_level_id() != "route_03":
		_errors.append("A new planner instance must restore the two completed routes and unlock the third.")

	for command_id in LEVEL_THREE_SOLUTION:
		resumed.add_command(command_id)
	if not resumed.execute_program() or not resumed.is_all_levels_completed():
		_errors.append("The final route should collect both samples and return to Sana.")
	if resumed.add_command("up"):
		_errors.append("The planner must not accept commands after all routes are completed.")

	resumed.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: lunar rover route planner, command validation, obstacle/bounds rejection, three sample routes, progression and save/restore.")
		quit(0)
		return
	for error in _errors:
		push_error(error)
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
