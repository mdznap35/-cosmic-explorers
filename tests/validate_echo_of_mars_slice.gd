extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")
const CharacterRoster = preload("res://scripts/character_roster.gd")
const InteractionRouter = preload("res://scripts/interaction_router.gd")
const MissionDirector = preload("res://scripts/mission_director.gd")
const RewardService = preload("res://scripts/reward_service.gd")
const SliceScene = preload("res://scenes/prototypes/echo_of_mars_vertical_slice.tscn")

var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bundle: Dictionary = ContentRegistry.load_bundle()
	_errors.append_array(ContentRegistry.validate_bundle(bundle))
	var mission_director = MissionDirector.new()
	_errors.append_array(mission_director.configure(bundle))
	var dialogue_director = DialogueDirector.new()
	_errors.append_array(dialogue_director.configure(bundle))
	var roster = CharacterRoster.new()
	_errors.append_array(roster.configure(bundle, "reem"))
	var router = InteractionRouter.new()
	_errors.append_array(router.configure(bundle))
	var rewards = RewardService.new()
	_errors.append_array(rewards.configure(bundle))
	if not _errors.is_empty():
		_fail_and_quit()
		return

	var mission: Dictionary = {}
	for entry in bundle.get("missions", []):
		if str(entry.get("id", "")) == "mission.mars.echo_of_mars":
			mission = entry
			break
	if mission.is_empty() or mission.get("objectives", []).size() != 11:
		_errors.append("Echo of Mars must expose the 11 authored objectives.")
	if mission.get("dialogue_ids", []).size() != 5:
		_errors.append("Echo of Mars must reference all five authored dialogue graphs.")
	for dialogue_id in mission.get("dialogue_ids", []):
		if not dialogue_director.start_dialogue(str(dialogue_id)):
			_errors.append("A story dialogue could not start: " + str(dialogue_id))
		else:
			dialogue_director.skip()
	for event_id in [
		"echo.signal.inspected","echo.tools.calibrated","echo.landing.chosen",
		"echo.rover.site_scanned","echo.photo.angle_one","echo.photo.angle_two",
		"echo.team.role_action","echo.lulu.mark_found","echo.signal.packet_matched",
		"echo.relay.component_ready","echo.acknowledgement.sent"
	]:
		if not router.is_event_allowed(event_id):
			_errors.append("Mission event is not allow-listed: " + event_id)

	if not mission_director.start_mission("mission.mars.echo_of_mars"):
		_errors.append("Echo of Mars mission should start in an isolated mission director.")
	var events := [
		"echo.signal.inspected","echo.tools.calibrated","echo.landing.chosen",
		"echo.rover.site_scanned","echo.rover.site_scanned","echo.rover.site_scanned",
		"echo.photo.angle_one","echo.photo.angle_two",
		"echo.team.role_action","echo.team.role_action","echo.team.role_action",
		"echo.lulu.mark_found","echo.signal.packet_matched",
		"echo.relay.component_ready","echo.relay.component_ready","echo.relay.component_ready",
		"echo.acknowledgement.sent"
	]
	for event_id in events:
		var result: Dictionary = mission_director.record_event(event_id)
		if not bool(result.get("accepted", false)):
			_errors.append("Mission director rejected a story event: " + event_id)
			break
	if not mission_director.is_mission_completed("mission.mars.echo_of_mars"):
		_errors.append("The mission must complete only after every required objective.")
	else:
		for reward_id in rewards.unlock_for_mission("mission.mars.echo_of_mars"):
			if reward_id != "reward.badge.echo_signal_detective":
				_errors.append("Unexpected completion reward: " + reward_id)
		if not rewards.has_reward("reward.badge.echo_signal_detective"):
			_errors.append("The completion badge should unlock once.")
		if not rewards.unlock_for_mission("mission.mars.echo_of_mars").is_empty():
			_errors.append("Reward unlock must be idempotent.")

	var slice = SliceScene.instantiate()
	slice.use_persistent_save = false
	root.add_child(slice)
	await process_frame
	if not slice.is_ready_for_play():
		_errors.append("The Echo of Mars scene must initialize using validated project services.")
		_fail_and_quit()
		return
	if slice.get_stage_index() != 0:
		_errors.append("A fresh slice must begin at the signal stage.")
	var world_environment_node := slice.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment_node == null or world_environment_node.environment == null:
		_errors.append("The story slice must expose its shared world environment.")
	elif world_environment_node.environment.background_mode != Environment.BG_COLOR:
		_errors.append("Sana's opening ship stage must keep its deep-space background.")
	if slice.get_character_ids().size() != 3:
		_errors.append("The slice must expose all three character profiles.")
	if slice.get_loaded_asset_ids().size() < 2:
		_errors.append("The opening scene should instantiate the pinned KayKit subset.")
	if slice.perform_action("not-a-real-action"):
		_errors.append("Unknown actions must be rejected.")
	if not slice.perform_action("inspect_signal"):
		_errors.append("The player must be able to inspect the opening signal.")
	slice.dismiss_current_dialogue()
	if slice.get_stage_index() != 1:
		_errors.append("Inspecting the signal should advance to the laboratory.")
	if not slice.perform_action("calibrate_tools"):
		_errors.append("The player must be able to calibrate the tools.")
	if not slice.perform_action("landing:rocky"):
		_errors.append("A valid landing site must be selectable.")
	await process_frame
	if slice.get_stage_index() != 3 or slice.get_rover_instance() == null:
		_errors.append("Landing selection must instantiate the existing rover scene.")
	else:
		var rover_scene = slice.get_rover_instance()
		var rover: CharacterBody3D = rover_scene.call("get_rover")
		for site_id in ["layered_rock","sand_ripples","crater_rim"]:
			rover.global_position = rover_scene.call("get_site_position",site_id)
			if not bool(rover_scene.call("scan_site",site_id)):
				_errors.append("Embedded rover could not record site: " + site_id)
			await process_frame
		if slice.get_rover_scanned_ids().size() != 3:
			_errors.append("All rover discoveries must be routed to the mission.")
		if not slice.perform_action("continue_to_photos"):
			_errors.append("Three rover observations should unlock photo comparison.")
		var story_terrain := slice.get_node_or_null("EchoWorld/MarsTerrain") as MeshInstance3D
		if story_terrain == null:
			_errors.append("The story's Mars stage must instantiate the shared generated terrain.")
		if world_environment_node != null and world_environment_node.environment != null:
			if world_environment_node.environment.background_mode != Environment.BG_SKY:
				_errors.append("Mars story stages must switch to the Mars procedural atmosphere.")

	if not slice.perform_action("photo:angle_one"):
		_errors.append("The first viewpoint photo should be recordable.")
	if not slice.perform_action("photo:angle_two"):
		_errors.append("The second viewpoint photo should be recordable.")
	slice.dismiss_current_dialogue()
	for role_id in ["reem","salim","lulu"]:
		if not slice.perform_action("role:" + role_id):
			_errors.append("Character-specific action failed: " + role_id)
	slice.dismiss_current_dialogue()
	for packet_id in ["packet:one","packet:two","packet:three"]:
		if not slice.perform_action(packet_id):
			_errors.append("Signal packet comparison failed: " + packet_id)
	for component_id in ["power","align","clip"]:
		if not slice.perform_action("relay:" + component_id):
			_errors.append("Relay component action failed: " + component_id)
	slice.dismiss_current_dialogue()
	if slice.get_stage_index() != 8:
		_errors.append("Repairing the relay must unlock acknowledgement.")
	if not slice.perform_action("send_acknowledgement"):
		_errors.append("Acknowledgement should complete the story mission.")
	if not slice.is_mission_completed() or not slice.has_completion_reward():
		_errors.append("Completing the playable slice must unlock its reward.")
	if world_environment_node != null and world_environment_node.environment != null:
		if world_environment_node.environment.background_mode != Environment.BG_COLOR:
			_errors.append("Returning to Sana must restore the deep-space atmosphere.")
	if slice.get_node_or_null("EchoWorld/MarsTerrain") != null:
		_errors.append("Returning to Sana must clear the Mars terrain from the story stage.")

	slice.free()
	if _errors.is_empty():
		print("PASS: Echo of Mars content, event routing, roster, embedded rover, dialogue, relay puzzle, completion and reward.")
		quit(0)
		return
	_fail_and_quit()

func _fail_and_quit() -> void:
	for error in _errors:
		push_error(error)
	quit(1)
