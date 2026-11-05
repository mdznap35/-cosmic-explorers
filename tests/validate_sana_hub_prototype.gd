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
	if not hub.has_method("get_station_ids"):
		_errors.append("The Sana Hub scene script must load before feature tests can continue.")
		push_error(_errors[_errors.size() - 1])
		quit(1)
		return
	hub.enable_gameplay_bridge = false
	root.add_child(hub)
	await process_frame

	if hub.get_reused_asset_model_count() < 8:
		_errors.append("All eight pinned KayKit CC0 models must be available in the Sana Hub.")
	if hub.get_loaded_reused_prop_ids().size() < 6:
		_errors.append("Sana Hub should instantiate reusable KayKit props across its five stations.")
	if not hub.has_method("start_lunar_outpost_activity"):
		_errors.append("The workshop hub must expose the lunar outpost activity entry point.")
	if not ResourceLoader.exists("res://scenes/prototypes/lunar_outpost_builder.tscn"):
		_errors.append("The linked lunar outpost builder scene must be available.")
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

	# Reem's observatory produces PNG thumbnails and saves its local photo album.
	if final_restore_hub.get_observatory_target_ids().size() != 3:
		_errors.append("The observatory must expose three stable celestial targets.")
	if not final_restore_hub.interact_station("observatory"):
		_errors.append("The observatory station should open Reem's photo activity.")
	if final_restore_hub.capture_observation("unknown_target"):
		_errors.append("The observatory must reject unknown target IDs.")
	if not final_restore_hub.capture_observation("moon"):
		_errors.append("The first observatory photo should be captured.")
	if final_restore_hub.capture_observation("moon"):
		_errors.append("The same observatory target must not be captured twice.")
	if not FileAccess.file_exists(final_restore_hub.get_observatory_photo_path("moon")):
		_errors.append("A captured observatory photo must exist as a local PNG file.")
	if not final_restore_hub.capture_observation("mars"):
		_errors.append("The second observatory photo should be captured.")
	if final_restore_hub.get_observatory_progress() != 2 or final_restore_hub.is_observatory_complete():
		_errors.append("The observatory should preserve a partial two-photo checkpoint.")

	final_restore_hub.queue_free()
	await process_frame

	var observatory_resume_hub = HubScene.instantiate()
	observatory_resume_hub.enable_gameplay_bridge = false
	root.add_child(observatory_resume_hub)
	await process_frame
	if observatory_resume_hub.get_observatory_progress() != 2:
		_errors.append("A new hub instance must restore the partial observatory album.")
	if not observatory_resume_hub.interact_station("observatory"):
		_errors.append("The observatory album should reopen after resuming.")
	if not observatory_resume_hub.capture_observation("saturn"):
		_errors.append("The resumed observatory should accept the final target.")
	if not observatory_resume_hub.is_observatory_complete():
		_errors.append("All three observatory targets should complete the photo album.")
	if not FileAccess.file_exists(observatory_resume_hub.get_observatory_photo_path("saturn")):
		_errors.append("The Saturn thumbnail should be written to the local album.")
	observatory_resume_hub.queue_free()
	await process_frame

	# A version 1 save must migrate without discarding earlier checkpoints.
	_write_save_state({
		"version": 1,
		"visited_station_ids": ["bridge", "observatory"],
		"relay_progress": 1,
		"relay_activity_completed": false,
		"cubesat_step": 2,
		"cubesat_built": false,
		"lulu_found_star_ids": ["star_bridge"],
		"lulu_hunt_completed": false
	})
	var migrated_hub = HubScene.instantiate()
	migrated_hub.enable_gameplay_bridge = false
	root.add_child(migrated_hub)
	await process_frame
	if migrated_hub.get_relay_progress() != 1 or migrated_hub.get_cubesat_progress() != 2:
		_errors.append("Save v1 migration must preserve Relay and CubeSat checkpoints.")
	if migrated_hub.get_lulu_found_star_ids().size() != 1:
		_errors.append("Save v1 migration must preserve Lulu's partial hunt.")
	if migrated_hub.get_observatory_progress() != 0:
		_errors.append("Save v1 migration must initialize the new photo album as empty.")
	migrated_hub.queue_free()
	await process_frame
	_remove_test_save()

	# Simulate a storage failure and make sure no activity reports unsaved progress.
	var failure_hub = HubScene.instantiate()
	failure_hub.enable_gameplay_bridge = false
	root.add_child(failure_hub)
	await process_frame
	failure_hub.set_save_failure_simulation_for_testing(true)
	if not failure_hub.interact_station("bridge"):
		_errors.append("The bridge should remain usable while persistence is unavailable.")
	if failure_hub.get_visited_station_ids().has("bridge"):
		_errors.append("A station visit must not count when its save fails.")
	if failure_hub.submit_relay_node("moon_relay") or failure_hub.get_relay_progress() != 0:
		_errors.append("Relay progress must roll back when the checkpoint cannot be saved.")
	if not failure_hub.interact_station("workshop"):
		_errors.append("The workshop should remain usable while persistence is unavailable.")
	if failure_hub.select_cubesat_part("central_bus") or failure_hub.get_cubesat_progress() != 0:
		_errors.append("CubeSat progress must roll back when the checkpoint cannot be saved.")
	if not failure_hub.start_lulu_hunt():
		_errors.append("Lulu's hunt should remain open while persistence is unavailable.")
	var failed_star_id := str(failure_hub.get_lulu_star_ids()[0])
	if failure_hub.collect_lulu_star(failed_star_id) or failure_hub.get_lulu_found_star_ids().size() != 0:
		_errors.append("Lulu's star must not count when its checkpoint cannot be saved.")
	if not failure_hub._secret_star_nodes.has(failed_star_id):
		_errors.append("A star must remain visible when its collection save fails.")
	failure_hub.queue_free()
	await process_frame
	_remove_test_save()

	# A fresh instance must still see the last persisted state, then accept retries.
	var recovery_hub = HubScene.instantiate()
	recovery_hub.enable_gameplay_bridge = false
	root.add_child(recovery_hub)
	await process_frame
	if recovery_hub.get_visited_station_ids().size() != 0 or recovery_hub.get_relay_progress() != 0:
		_errors.append("A new hub instance must not restore any rejected station or Relay progress.")
	if recovery_hub.get_cubesat_progress() != 0 or recovery_hub.get_lulu_found_star_ids().size() != 0:
		_errors.append("A new hub instance must not restore any rejected CubeSat or Lulu progress.")
	if not recovery_hub.interact_station("bridge") or not recovery_hub.submit_relay_node("moon_relay"):
		_errors.append("Relay should accept a retry after storage becomes available.")
	if not recovery_hub.interact_station("workshop") or not recovery_hub.select_cubesat_part("central_bus"):
		_errors.append("CubeSat should accept a retry after storage becomes available.")
	if not recovery_hub.start_lulu_hunt() or not recovery_hub.collect_lulu_star(failed_star_id):
		_errors.append("Lulu should accept the same star after storage becomes available.")
	recovery_hub.queue_free()
	await process_frame
	var recovery_check_hub = HubScene.instantiate()
	recovery_check_hub.enable_gameplay_bridge = false
	root.add_child(recovery_check_hub)
	await process_frame
	if recovery_check_hub.get_relay_progress() != 1 or recovery_check_hub.get_cubesat_progress() != 1:
		_errors.append("Successful retries must persist Relay and CubeSat checkpoints.")
	if recovery_check_hub.get_lulu_found_star_ids().size() != 1:
		_errors.append("A successful Lulu retry must persist the collected star.")
	recovery_check_hub.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: Sana Hub stations, pinned KayKit CC0 props, Relay, CubeSat, Lulu hunt, Reem PNG photo album, save migration, partial checkpoints, multi-session restore, and failed-save rollback/retry.")
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)


func _write_save_state(state: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_errors.append("Unable to create a save fixture for migration testing.")
		return
	file.store_string(JSON.stringify(state))
	file.close()


func _remove_test_save() -> void:
	var absolute_save_path := ProjectSettings.globalize_path(SAVE_PATH)
	if DirAccess.dir_exists_absolute(absolute_save_path):
		DirAccess.remove_absolute(absolute_save_path)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_save_path)
	var album := DirAccess.open("user://observatory_album")
	if album != null:
		for file_name in album.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://observatory_album/" + file_name))
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://observatory_album"))
