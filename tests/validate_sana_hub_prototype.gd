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

	var correct_route := ["moon_relay", "sana_station", "mars_rover"]
	for relay_id in correct_route:
		if not hub.submit_relay_node(relay_id):
			_errors.append("The expected relay node should be accepted: " + relay_id)

	if hub.get_relay_progress() != 3:
		_errors.append("The completed relay should record all three steps.")
	if not hub.is_relay_completed():
		_errors.append("The completed relay activity must be persisted.")

	hub.queue_free()
	await process_frame

	var resumed_hub = HubScene.instantiate()
	resumed_hub.enable_gameplay_bridge = false
	root.add_child(resumed_hub)
	await process_frame

	if not resumed_hub.is_relay_completed():
		_errors.append("A new hub instance must restore relay completion.")
	if not resumed_hub.get_visited_station_ids().has("bridge"):
		_errors.append("A new hub instance must restore visited stations.")

	resumed_hub.queue_free()
	await process_frame
	_remove_test_save()

	if _errors.is_empty():
		print("PASS: Sana Hub scene, five stations, relay ordering, gentle retry, local persistence, and restore.")
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
