extends SceneTree

const HubScene = preload("res://scenes/prototypes/sana_hub_prototype.tscn")
const SAVE_PATH := "user://sana_hub_prototype.json"
const EXPECTED_STATIONS := [
	"bridge",
	"workshop",
	"laboratory",
	"observatory",
	"lulu_nook"
]

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_sana_hub_tests")


func _run_sana_hub_tests() -> void:
	_remove_test_save()
	var hub = HubScene.instantiate()
	hub.enable_gameplay_bridge = false
	root.add_child(hub)
	await process_frame

	var station_ids: PackedStringArray = hub.get_station_ids()
	if station_ids.size() != EXPECTED_STATIONS.size():
		_errors.append("The hub must expose exactly five named stations.")
	for expected_id in EXPECTED_STATIONS:
		if not station_ids.has(expected_id):
			_errors.append("The hub is missing station: " + expected_id)

	if not hub.interact_station("bridge"):
		_errors.append("The bridge station should be interactable.")
	if not hub.get_visited_station_ids().has("bridge"):
		_errors.append("Visiting the bridge should persist the station visit.")

	if not hub.start_relay_activity():
		_errors.append("The relay activity should start.")
	if hub.submit_relay_node("mars_rover"):
		_errors.append("An out-of-order relay selection must not advance the puzzle.")
	if hub.get_relay_progress() != 0:
		_errors.append("An incorrect relay selection must not change progress.")

	var first_relay_steps := ["moon_relay", "sana_station"]
	for relay_id in first_relay_steps:
		if not hub.submit_relay_node(relay_id):
			_errors.append("The expected relay checkpoint should be accepted: " + relay_id)

	if hub.get_relay_progress() != 2 or hub.is_relay_completed():
		_errors.append("The relay should preserve its partial two-step checkpoint.")

	hub.queue_free()
	await process_frame

	var resumed_hub = HubScene.instantiate()
	resumed_hub.enable_gameplay_bridge = false
	root.add_child(resumed_hub)
	await process_frame

	if resumed_hub.is_relay_completed() or resumed_hub.get_relay_progress() != 2:
		_errors.append("A new hub instance must restore the partial Relay checkpoint.")
	if not resumed_hub.get_visited_station_ids().has("bridge"):
		_errors.append("A new hub instance must restore visited stations.")
	if not resumed_hub.start_relay_activity() or not resumed_hub.submit_relay_node("mars_rover"):
		_errors.append("The resumed Relay activity should accept the final destination.")
	if not resumed_hub.is_relay_completed():
		_errors.append("The Relay activity should be complete after the final destination.")

	if not resumed_hub.interact_station("workshop"):
		_errors.append("The workshop should launch the CubeSat builder.")
	if resumed_hub.select_cubesat_part("science_camera"):
		_errors.append("The CubeSat builder must reject an out-of-order component.")
	if resumed_hub.get_cubesat_progress() != 0:
		_errors.append("A rejected CubeSat component must not change progress.")

	var first_cubesat_steps := ["central_bus", "solar_panels"]
	for part_id in first_cubesat_steps:
		if not resumed_hub.select_cubesat_part(part_id):
			_errors.append("The expected CubeSat checkpoint should be accepted: " + part_id)
	if resumed_hub.get_cubesat_progress() != 2:
		_errors.append("The CubeSat should save its partial two-component checkpoint.")

	resumed_hub.queue_free()
	await process_frame

	var final_hub = HubScene.instantiate()
	final_hub.enable_gameplay_bridge = false
	root.add_child(final_hub)
	await process_frame
	if final_hub.get_cubesat_progress() != 2 or final_hub.is_cubesat_built():
		_errors.append("A new hub instance must restore the partial CubeSat checkpoint.")
	if not final_hub.interact_station("workshop"):
		_errors.append("The workshop should reopen the CubeSat builder.")
	for part_id in ["communication_antenna", "science_camera"]:
		if not final_hub.select_cubesat_part(part_id):
			_errors.append("The resumed CubeSat should accept: " + part_id)
	if not final_hub.is_cubesat_built() or final_hub.get_cubesat_progress() != 4:
		_errors.append("The CubeSat should complete after the final two components.")

	final_hub.queue_free()
	await process_frame

	var restored_hub = HubScene.instantiate()
	restored_hub.enable_gameplay_bridge = false
	root.add_child(restored_hub)
	await process_frame
	if not restored_hub.is_cubesat_built() or restored_hub.get_cubesat_progress() != 4:
		_errors.append("A fresh hub instance must restore the completed CubeSat.")
	if not restored_hub.is_relay_completed() or restored_hub.get_relay_progress() != 3:
		_errors.append("A fresh hub instance must restore the completed Relay activity.")

	var lulu_star_ids: PackedStringArray = restored_hub.get_lulu_star_ids()
	if lulu_star_ids.size() != 5:
		_errors.append("Lulu's hidden-star hunt must expose five unique stars.")
	if not restored_hub.interact_station("lulu_nook"):
		_errors.append("Lulu's nook should launch the hidden-star hunt.")
	if restored_hub.collect_lulu_star("star_not_in_catalog"):
		_errors.append("The hidden-star hunt must reject unknown star IDs.")
	for index in range(2):
		if not restored_hub.collect_lulu_star(lulu_star_ids[index]):
			_errors.append("The first hidden-star checkpoints should be collectable.")
	if restored_hub.get_lulu_found_star_ids().size() != 2 or restored_hub.is_lulu_hunt_completed():
		_errors.append("The hunt should preserve its partial two-star checkpoint.")

	restored_hub.queue_free()
	await process_frame

	var lulu_resume_hub = HubScene.instantiate()
	lulu_resume_hub.enable_gameplay_bridge = false
	root.add_child(lulu_resume_hub)
	await process_frame
	if lulu_resume_hub.get_lulu_found_star_ids().size() != 2 or lulu_resume_hub.is_lulu_hunt_completed():
		_errors.append("A new hub instance must restore the partial Lulu star hunt.")
	if not lulu_resume_hub.start_lulu_hunt():
		_errors.append("The hidden-star hunt should resume from its saved checkpoint.")
	for index in range(2, lulu_star_ids.size()):
		if not lulu_resume_hub.collect_lulu_star(lulu_star_ids[index]):
			_errors.append("The remaining hidden star should be collectable.")
	if not lulu_resume_hub.is_lulu_hunt_completed():
		_errors.append("Finding all five stars should complete Lulu's activity.")

	lulu_resume_hub.queue_free()
	await process_frame

	var final_restore_hub = HubScene.instantiate()
	final_restore_hub.enable_gameplay_bridge = false
	root.add_child(final_restore_hub)
	await process_frame
	if not final_restore_hub.is_lulu_hunt_completed() or final_restore_hub.get_lulu_found_star_ids().size() != 5:
		_errors.append("A fresh hub instance must restore the completed Lulu hunt.")
	final_restore_hub.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: Sana Hub scene, five stations, Relay, CubeSat, Lulu hidden-star hunt, partial checkpoints, and multi-session restore.")
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
