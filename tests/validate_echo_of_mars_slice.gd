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
	if not slice.is_opening_cinematic_active():
		_errors.append("A fresh signal-stage visit must begin with the skippable cinematic prologue.")
	var opening_panel := slice.find_child("OpeningCinematicPanel", true, false) as PanelContainer
	if opening_panel == null or not opening_panel.visible:
		_errors.append("The cinematic prologue must expose its visible story panel.")
	if slice.perform_action("signal:one"):
		_errors.append("Gameplay actions must stay gated during the cinematic prologue.")
	if not slice.skip_opening_cinematic():
		_errors.append("The player must be able to skip the cinematic prologue.")
	if slice.is_opening_cinematic_active():
		_errors.append("Skipping the prologue must immediately release the scene.")
	if not slice.dismiss_current_dialogue():
		_errors.append("Skipping the cinematic must enter the authored prologue dialogue.")
	if not slice.get_action_ids().has("signal:one"):
		_errors.append("The first signal inspection must become available after the prologue.")
	var world_environment_node := slice.get_node_or_null("EchoWorldEnvironment") as WorldEnvironment
	if world_environment_node == null or world_environment_node.environment == null:
		_errors.append("The story slice must expose its shared world environment.")
	elif world_environment_node.environment.background_mode != Environment.BG_COLOR:
		_errors.append("Sana's opening ship stage must keep its deep-space background.")
	if slice.get_character_ids().size() != 3:
		_errors.append("The slice must expose all three character profiles.")
	if slice.get_loaded_asset_ids().size() < 2:
		_errors.append("The opening scene should instantiate the pinned KayKit subset.")
	var loaded_scene_assets: PackedStringArray = slice.get_loaded_asset_ids()
	for station_asset in ["kenney:floor", "kenney:computer", "kenney:table-display-planet"]:
		if not loaded_scene_assets.has(station_asset):
			_errors.append("The Sana bridge must use staged Kenney modular assets: " + station_asset)
	var signal_display := slice.get_node_or_null("EchoWorld/EchoSignalDisplay") as Node3D
	if signal_display == null:
		_errors.append("The opening bridge must build the dedicated Echo signal hologram.")
	else:
		var mars_globe := signal_display.get_node_or_null("MarsGlobe") as MeshInstance3D
		if mars_globe == null:
			_errors.append("The opening hologram must include a Mars globe.")
		else:
			var globe_material := mars_globe.material_override as StandardMaterial3D
			if globe_material == null or globe_material.albedo_texture == null:
				_errors.append("The Mars hologram must use the staged, attributed Mars surface texture.")
		var pulse_rings := signal_display.find_children("EchoPulseRing_*", "MeshInstance3D", true, false)
		if pulse_rings.size() != 3:
			_errors.append("The opening signal must visualize exactly three synchronized echo rings.")
	var signal_waveform := slice.get_node_or_null("EchoWorld/EchoSignalWaveform") as MultiMeshInstance3D
	if signal_waveform == null or signal_waveform.multimesh == null:
		_errors.append("The opening display must include the repeated signal waveform.")
	else:
		if signal_waveform.multimesh.instance_count != 96:
			_errors.append("The repeated signal waveform must render three 32-bar traces in one MultiMesh.")
		var waveform_mesh := signal_waveform.multimesh
		var first_trace := waveform_mesh.get_instance_transform(5).basis.y.length()
		var second_trace := waveform_mesh.get_instance_transform(37).basis.y.length()
		var third_trace := waveform_mesh.get_instance_transform(69).basis.y.length()
		if not (is_equal_approx(first_trace, second_trace) and is_equal_approx(second_trace, third_trace)):
			_errors.append("All three echo traces must carry the same waveform pattern.")
		var hit_areas := signal_waveform.find_children("SignalRowHitArea_*", "Area3D", true, false)
		if hit_areas.size() != 3:
			_errors.append("Each echo trace must expose its own 3D touch target.")
		for row in range(3):
			var hit_area := signal_waveform.get_node_or_null("SignalRowHitArea_%02d" % (row + 1)) as Area3D
			if hit_area == null:
				_errors.append("Missing 3D touch target for signal row %d." % (row + 1))
				continue
			if not hit_area.input_ray_pickable or hit_area.collision_layer == 0:
				_errors.append("Signal row %d must be ray-pickable on an active collision layer." % (row + 1))
			var hit_shape := hit_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if hit_shape == null or not (hit_shape.shape is BoxShape3D):
				_errors.append("Signal row %d must provide a box hit target." % (row + 1))
			if hit_area.get_signal_connection_list("input_event").size() != 1:
				_errors.append("Signal row %d must route input to its own inspection action." % (row + 1))
	if slice.perform_action("not-a-real-action"):
		_errors.append("Unknown actions must be rejected.")
	if slice.perform_action("inspect_signal"):
		_errors.append("The opening signal cannot be confirmed before all three pulses are inspected.")
	for row in range(3):
		var signal_id := ["one", "two", "three"][row]
		if not slice.get_action_ids().has("signal:" + signal_id):
			_errors.append("Each uninspected pulse must expose its own action: " + signal_id)
		var hit_area := slice.get_node_or_null("EchoWorld/EchoSignalWaveform/SignalRowHitArea_%02d" % (row + 1)) as Area3D
		if hit_area != null:
			var input_event: InputEvent
			if row == 1:
				var mouse_click := InputEventMouseButton.new()
				mouse_click.button_index = MOUSE_BUTTON_LEFT
				mouse_click.pressed = true
				input_event = mouse_click
			else:
				var screen_touch := InputEventScreenTouch.new()
				screen_touch.pressed = true
				input_event = screen_touch
			hit_area.input_event.emit(null, input_event, Vector3.ZERO, Vector3.UP, 0)
		else:
			_errors.append("The signal row hit target must be present before it can be touched.")
		if not slice.get_signal_pulses_inspected().has(signal_id):
			_errors.append("Touching signal row must inspect " + signal_id)
		if slice.get_stage_index() != 0:
			_errors.append("Inspecting an individual pulse must not skip the comparison stage.")
		if not slice.get_signal_pulses_inspected().has(signal_id):
			_errors.append("The inspected pulse must be recorded: " + signal_id)
	if not slice.get_action_ids().has("inspect_signal"):
		_errors.append("The comparison action must unlock only after all three pulses.")
	if slice.get_action_ids().has("signal:one") or slice.get_action_ids().has("signal:two") or slice.get_action_ids().has("signal:three"):
		_errors.append("Already-inspected pulses must disappear from the pending actions.")
	if not slice.perform_action("inspect_signal"):
		_errors.append("The player must be able to compare the three inspected pulses.")
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
		var active_world_environments := slice.find_children("*", "WorldEnvironment", true, false)
		if active_world_environments.size() != 1:
			_errors.append("The embedded rover must reuse the story's single WorldEnvironment.")
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
	for role_id in ["reem","salim"]:
		if not slice.perform_action("role:" + role_id):
			_errors.append("Character-specific action failed: " + role_id)
	var team_root := slice.get_node_or_null("EchoWorld")
	if team_root == null:
		_errors.append("The story slice must expose its world root for visual validation.")
	else:
		for actor_name in ["ReemExplorer", "SalimExplorer", "LuluCompanion"]:
			if team_root.get_node_or_null(actor_name) == null:
				_errors.append("The team scene must instantiate its expressive character rig: " + actor_name)
			elif team_root.get_node(actor_name).get_node_or_null("AnimatedBody") == null:
				_errors.append("The character rig must contain a separately animated body: " + actor_name)
			elif actor_name != "LuluCompanion" and team_root.get_node(actor_name).get_node("AnimatedBody").get_node_or_null("HeadPivot") == null:
				_errors.append("The explorer rig must have an independently animated head pivot: " + actor_name)
	if not slice.perform_action("role:lulu"):
		_errors.append("Character-specific action failed: lulu")
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
	await process_frame

	# Exercise the version-1 migration path: older saves do not contain the
	# signal_pulses_inspected field, while new inspections must survive reload.
	var migration_save_path := "user://echo_of_mars_vertical_slice_v1.json"
	var migration_save_absolute := ProjectSettings.globalize_path(migration_save_path)
	var migration_backup_absolute := ProjectSettings.globalize_path(migration_save_path + ".bak")
	if FileAccess.file_exists(migration_save_path):
		DirAccess.remove_absolute(migration_save_absolute)
	if FileAccess.file_exists(migration_save_path + ".bak"):
		DirAccess.remove_absolute(migration_backup_absolute)
	var legacy_save := FileAccess.open(migration_save_path, FileAccess.WRITE)
	if legacy_save == null:
		_errors.append("The save migration test could not create its isolated legacy fixture.")
	else:
		legacy_save.store_string(JSON.stringify({
			"version": 1,
			"mission_state": {},
			"reward_state": {},
			"stage_index": 0,
			"landing_site_id": "rocky"
		}))
		legacy_save.close()
		var migrated_slice = SliceScene.instantiate()
		migrated_slice.use_persistent_save = true
		root.add_child(migrated_slice)
		await process_frame
		if not migrated_slice.is_ready_for_play():
			_errors.append("A version-1 save without pulse data must still initialize.")
		elif not migrated_slice.get_signal_pulses_inspected().is_empty():
			_errors.append("A legacy save without pulse data must default to an empty inspection list.")
		elif not migrated_slice.perform_action("signal:one"):
			_errors.append("A migrated legacy save must accept and persist its first pulse inspection.")
		migrated_slice.free()
		await process_frame
		var resumed_slice = SliceScene.instantiate()
		resumed_slice.use_persistent_save = true
		root.add_child(resumed_slice)
		await process_frame
		if not resumed_slice.is_ready_for_play():
			_errors.append("The updated version-1 save must initialize after reload.")
		elif not resumed_slice.get_signal_pulses_inspected().has("one"):
			_errors.append("The newly inspected pulse must survive save/reload.")
		elif resumed_slice.get_action_ids().has("signal:one"):
			_errors.append("A pulse already saved as inspected must not reappear as pending after reload.")
		resumed_slice.free()
		await process_frame
	if FileAccess.file_exists(migration_save_path):
		DirAccess.remove_absolute(migration_save_absolute)
	if FileAccess.file_exists(migration_save_path + ".bak"):
		DirAccess.remove_absolute(migration_backup_absolute)

	if _errors.is_empty():
		print("PASS: Echo of Mars content, event routing, roster, embedded rover, dialogue, relay puzzle, completion and reward.")
		quit(0)
		return
	_fail_and_quit()

func _fail_and_quit() -> void:
	for error in _errors:
		push_error(error)
	quit(1)
