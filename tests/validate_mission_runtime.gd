extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")
const MissionDirector = preload("res://scripts/mission_director.gd")
const RewardService = preload("res://scripts/reward_service.gd")


func _initialize() -> void:
	call_deferred("_run_mission_runtime_tests")


func _run_mission_runtime_tests() -> void:
	var errors: Array[String] = []
	var bundle: Dictionary = ContentRegistry.load_bundle()

	var mission_director = MissionDirector.new()
	var mission_setup_errors: Array[String] = mission_director.configure(bundle)
	errors.append_array(mission_setup_errors)

	var reward_service = RewardService.new()
	var reward_setup_errors: Array[String] = reward_service.configure(bundle)
	errors.append_array(reward_setup_errors)

	if not mission_director.start_mission("mission.mars.rover_survey"):
		errors.append("The Mars survey mission should start.")
		_finish(errors)
		return

	var site_result: Dictionary = mission_director.record_event("mars.site.selected")
	if bool(site_result.get("mission_completed", false)):
		errors.append("The mission must not complete after only choosing a survey site.")

	var first_scan: Dictionary = mission_director.record_event("scanner.sample_recorded")
	if bool(first_scan.get("mission_completed", false)):
		errors.append("The two-sample objective must not complete after one scan.")

	var second_scan: Dictionary = mission_director.record_event("scanner.sample_recorded")
	if not bool(second_scan.get("mission_completed", false)):
		errors.append("The Mars survey should complete after its required objectives.")
	if not bool(second_scan.get("first_completion", false)):
		errors.append("The first successful completion must be identified.")
	if not _has_value(second_scan.get("reward_ids", []), "reward.badge.mars_field_detective"):
		errors.append("The first completion must report the configured mission reward.")

	# The optional photo objective was intentionally skipped and must not block completion.
	if not mission_director.is_mission_completed("mission.mars.rover_survey"):
		errors.append("Completed mission state must be queryable.")

	var unlocked := reward_service.unlock_for_mission("mission.mars.rover_survey")
	if not _has_value(unlocked, "reward.badge.mars_field_detective"):
		errors.append("The reward service must unlock the Mars badge.")
	if not reward_service.unlock_for_mission("mission.mars.rover_survey").is_empty():
		errors.append("A non-repeatable reward must not be granted twice.")

	# Save a partially completed Moon mission and restore it into a new director.
	if not mission_director.start_mission("mission.moon.light_reflection"):
		errors.append("A second mission should start after the first one completes.")
	mission_director.record_event("moon.light_source_moved")
	var saved_mission_state: Dictionary = mission_director.export_state()
	var resumed_director = MissionDirector.new()
	errors.append_array(resumed_director.configure(bundle, saved_mission_state))
	if resumed_director.get_active_mission_id() != "mission.moon.light_reflection":
		errors.append("The active mission should resume from the exported snapshot.")
	var resumed_result: Dictionary = resumed_director.record_event("moon.illuminated_side_observed")
	if not bool(resumed_result.get("mission_completed", false)):
		errors.append("A resumed mission should complete after its remaining required objective.")

	# Reward state must round-trip and ignore IDs removed from a future content version.
	var saved_reward_state: Dictionary = reward_service.export_state()
	saved_reward_state["unlocked_reward_ids"].append("reward.removed_in_future")
	var resumed_rewards = RewardService.new()
	errors.append_array(resumed_rewards.configure(bundle, saved_reward_state))
	if not resumed_rewards.has_reward("reward.badge.mars_field_detective"):
		errors.append("Unlocked rewards must survive state export and restore.")
	if resumed_rewards.has_reward("reward.removed_in_future"):
		errors.append("Unknown reward IDs must be ignored during restore.")

	# The original director still has the Moon mission active; explicitly leave it
	# before asking that same director to replay Mars.
	mission_director.cancel_active_mission()

	# Replaying a completed replayable mission must not issue its one-time reward again.
	if not mission_director.start_mission("mission.mars.rover_survey"):
		errors.append("The completed replayable Mars mission should be replayable.")
	mission_director.record_event("mars.site.selected")
	mission_director.record_event("scanner.sample_recorded")
	var replay_result: Dictionary = mission_director.record_event("scanner.sample_recorded")
	if not bool(replay_result.get("mission_completed", false)):
		errors.append("The replayed Mars mission should finish.")
	if bool(replay_result.get("first_completion", true)) or not replay_result.get("reward_ids", []).is_empty():
		errors.append("Replaying a mission must not reissue its first-completion reward.")

	# Unknown events and inactive mission events must not mutate progress.
	mission_director.cancel_active_mission()
	var inactive_result: Dictionary = mission_director.record_event("scanner.sample_recorded")
	if bool(inactive_result.get("accepted", false)):
		errors.append("Events without an active mission must be ignored.")

	_finish(errors)


func _has_value(values: Array, expected: String) -> bool:
	for value in values:
		if str(value) == expected:
			return true
	return false


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("PASS: mission events, required/optional objectives, replay, idempotent rewards, and state round-trip.")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)
