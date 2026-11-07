extends Node3D
## Offline-first flagship story slice; reuses validated project systems and the staged KayKit subset.

const ContentRegistry = preload("res://scripts/content_registry.gd")
const MissionDirector = preload("res://scripts/mission_director.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")
const CharacterRoster = preload("res://scripts/character_roster.gd")
const InteractionRouter = preload("res://scripts/interaction_router.gd")
const RewardService = preload("res://scripts/reward_service.gd")
const RoverScene = preload("res://scenes/prototypes/mars_rover_survey.tscn")
const MarsLandscapeBuilder = preload("res://scripts/prototypes/mars_landscape_builder.gd")

const MISSION_ID := "mission.mars.echo_of_mars"
const SAVE_PATH := "user://echo_of_mars_vertical_slice_v1.json"
const SAVE_VERSION := 1
const STAGE_NAMES := ["الإشارة الغامضة","مختبر سَنا","اختيار موقع الهبوط","استكشاف سطح المريخ","الصورة الثانية","قدرات الفريق","مقارنة النبضات","محطة الترحيل","تأكيد الاستلام","صفحة جديدة في الأطلس"]
const OPENING_CARDS := [
	{
		"eyebrow": "مهمة استكشاف جديدة  /  أُفُق-1",
		"title": "إشارة عبر الصمت",
		"copy": "في هدوء المدار، التقطت سفينة سَنا إشارة قديمة عادت بثلاث نبضات."
	},
	{
		"eyebrow": "تحليل أولي  /  مرقاب",
		"title": "ثلاث نبضات، ودليل واحد",
		"copy": "لا نملك تفسيراً مؤكداً بعد. سنحفظ كل عينة ونفحص تفاصيلها قبل أن نستنتج."
	},
	{
		"eyebrow": "مهمتك تبدأ الآن",
		"title": "استمع إلى الإشارة",
		"copy": "افحص النبضات واحدةً تلو الأخرى، ثم قارنها مع الفريق. كل اكتشاف سيبقى محفوظاً."
	}
]
const STAGE_DESCRIPTIONS := [
	"وصلت ثلاث نبضات من أُفُق-1. افحصها قبل أن نقرر ماذا تعني.",
	"جهّز أدوات الرصد والتحليل والخريطة، واترك الاستنتاج مفتوحاً.",
	"اختر نقطة آمنة للهبوط. لكل مسار زاوية مختلفة على الوادي.",
	"قد الروفر بين مواقع الملاحظة الثلاثة وسجّل ما تراه.",
	"التقط صورة من زاويتين. الصورة الواضحة ليست دائماً القصة كاملة.",
	"بدّل بين ريم وسليم ولولو، واستعمل قدرة كل واحد منهم في مكانها.",
	"قارن الحزم الثلاث. انتبه إلى شكل الرسالة، لا إلى وقت وصولها فقط.",
	"أعد الطاقة والاتجاه والمشبك إلى أماكنها من دون مسح السجل.",
	"أرسل تأكيد الاستلام، ثم راجع ما تعلمه الفريق.",
	"اكتملت الرحلة. أُضيفت صفحة جديدة إلى أطلس الضوء."
]
const KAYKIT_ROOT := "res://assets/vendor/kaykit_space_base_bits"
const KENNEY_STATION_ROOT := "res://assets/vendor/kenney_space_station_kit"
const KENNEY_AUDIO_ROOT := "res://assets/audio/kenney_interface_sounds"
const KENNEY_STATION_MODELS := {
	"floor": KENNEY_STATION_ROOT + "/floor.glb",
	"floor-panel": KENNEY_STATION_ROOT + "/floor-panel.glb",
	"wall": KENNEY_STATION_ROOT + "/wall.glb",
	"wall-corner": KENNEY_STATION_ROOT + "/wall-corner.glb",
	"wall-window": KENNEY_STATION_ROOT + "/wall-window.glb",
	"wall-door": KENNEY_STATION_ROOT + "/wall-door.glb",
	"door-single": KENNEY_STATION_ROOT + "/door-single.glb",
	"computer": KENNEY_STATION_ROOT + "/computer.glb",
	"display-wall-wide": KENNEY_STATION_ROOT + "/display-wall-wide.glb",
	"table-display-planet": KENNEY_STATION_ROOT + "/table-display-planet.glb",
	"table-inset": KENNEY_STATION_ROOT + "/table-inset.glb",
	"chair": KENNEY_STATION_ROOT + "/chair.glb",
	"rail": KENNEY_STATION_ROOT + "/rail.glb",
	"pipe": KENNEY_STATION_ROOT + "/pipe.glb",
	"structure": KENNEY_STATION_ROOT + "/structure.glb",
	"container": KENNEY_STATION_ROOT + "/container.glb",
	"wall-switch": KENNEY_STATION_ROOT + "/wall-switch.glb",
	"wall-pillar": KENNEY_STATION_ROOT + "/wall-pillar.glb"
}
const KENNEY_AUDIO_PATHS := {
	"click": KENNEY_AUDIO_ROOT + "/click_001.wav",
	"open": KENNEY_AUDIO_ROOT + "/open_001.wav",
	"confirm": KENNEY_AUDIO_ROOT + "/bong_001.wav"
}
const KAYKIT_MODELS := {
	"basemodule_A": KAYKIT_ROOT + "/basemodule_A.gltf",
	"lander_A": KAYKIT_ROOT + "/lander_A.gltf",
	"landingpad_small": KAYKIT_ROOT + "/landingpad_small.gltf",
	"rocks_A": KAYKIT_ROOT + "/rocks_A.gltf",
	"rocks_B": KAYKIT_ROOT + "/rocks_B.gltf",
	"solarpanel": KAYKIT_ROOT + "/solarpanel.gltf",
	"spacetruck": KAYKIT_ROOT + "/spacetruck.gltf",
	"structure_low": KAYKIT_ROOT + "/structure_low.gltf"
}
const LANDING_SITES := {
	"plateau": {"title":"الهضبة الهادئة","position":Vector3(-7.0,0.0,4.0),"accent":Color(0.98,0.72,0.40)},
	"rocky": {"title":"الممر الصخري","position":Vector3(0.0,0.0,6.0),"accent":Color(0.47,0.82,0.96)},
	"low_ridge": {"title":"الحافة المنخفضة","position":Vector3(7.0,0.0,3.0),"accent":Color(0.76,0.66,0.98)}
}
const ROLE_ABILITIES := {"reem":"photo_documentation","salim":"device_repair","lulu":"hidden_trace_detection"}
const ROLE_LABELS := {"reem":"ريم — ثبتي الصورة","salim":"سليم — افحص وحدة الاتصال","lulu":"لولو — اكشف العلامة الصغيرة"}
const SIGNAL_ACTION_LABELS := {"one":"افحص النبضة الأولى","two":"افحص النبضة الثانية","three":"افحص النبضة الثالثة"}
const SIGNAL_FEEDBACK := {
	"one":"سُجّلت النبضة الأولى. احتفظنا بشكلها ووقت وصولها للمقارنة.",
	"two":"سُجّلت النبضة الثانية. لاحظ موضع العلامة الصغيرة قبل الاستنتاج.",
	"three":"اكتملت العينات الثلاث. أصبحت المقارنة متاحة الآن."
}
const RELAY_LABELS := {"power":"توصيل الطاقة — سليم","align":"توجيه الطبق — ريم","clip":"تثبيت المشبك — لولو"}

@export var use_persistent_save := true

var _bundle: Dictionary = {}
var _mission_director
var _dialogue_director
var _character_roster
var _interaction_router
var _reward_service
var _last_event_result: Dictionary = {}
var _initialized := false
var _initialization_errors: Array[String] = []
var _stage_index := 0
var _landing_site_id := "rocky"
var _rover_scanned_ids: Array[String] = []
var _signal_pulses_inspected: Array[String] = []
var _photo_one_done := false
var _photo_two_done := false
var _role_actions_done: Array[String] = []
var _lulu_mark_found := false
var _matched_packets: Array[String] = []
var _relay_components: Array[String] = []
var _selected_character_id := "reem"
var _loaded_asset_ids: Array[String] = []
var _world_root: Node3D
var _camera: Camera3D
var _world_environment: Environment
var _station_scene_cache: Dictionary = {}
var _audio_stream_cache: Dictionary = {}
var _ui_sfx_player: AudioStreamPlayer
var _camera_tween: Tween
var _has_camera_pose := false
var _rover_instance
var _hud_root: Control
var _title_label: Label
var _objective_label: Label
var _progress_label: Label
var _feedback_label: Label
var _selected_label: Label
var _action_box: VBoxContainer
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_text: Label
var _dialogue_choices: VBoxContainer
var _dialogue_director_active := false
var _opening_cinematic_active := false
var _opening_panel: PanelContainer
var _opening_eyebrow: Label
var _opening_title: Label
var _opening_copy: Label

func _exit_tree() -> void:
	# Release scene-owned runtime resources explicitly during scene teardown.
	if _camera_tween != null and is_instance_valid(_camera_tween) and _camera_tween.is_running():
		_camera_tween.kill()
	_camera_tween = null
	if is_instance_valid(_ui_sfx_player):
		_ui_sfx_player.stop()
		_ui_sfx_player.stream = null
	_ui_sfx_player = null
	_audio_stream_cache.clear()
	_station_scene_cache.clear()
	_world_environment = null
	_world_root = null
	_camera = null

func _ready() -> void:
	_bundle = ContentRegistry.load_bundle()
	_initialization_errors = ContentRegistry.validate_bundle(_bundle)
	if not _initialization_errors.is_empty():
		_fail_initialization(_initialization_errors)
		return
	var snapshot := _load_snapshot() if use_persistent_save else _default_snapshot()
	_mission_director = MissionDirector.new()
	var errors: Array[String] = _mission_director.configure(_bundle, snapshot.get("mission_state", {}))
	if not errors.is_empty():
		_fail_initialization(errors)
		return
	_reward_service = RewardService.new()
	errors = _reward_service.configure(_bundle, snapshot.get("reward_state", {}))
	if not errors.is_empty():
		_fail_initialization(errors)
		return
	_dialogue_director = DialogueDirector.new()
	errors = _dialogue_director.configure(_bundle)
	if not errors.is_empty():
		_fail_initialization(errors)
		return
	_character_roster = CharacterRoster.new()
	errors = _character_roster.configure(_bundle, str(snapshot.get("selected_character_id", "reem")))
	if not errors.is_empty():
		_fail_initialization(errors)
		return
	_interaction_router = InteractionRouter.new()
	errors = _interaction_router.configure(_bundle)
	if not errors.is_empty():
		_fail_initialization(errors)
		return
	_interaction_router.interaction_received.connect(_on_interaction_received)
	_restore_extra_state(snapshot)
	if _mission_director.is_mission_completed(MISSION_ID):
		_stage_index = 9
	elif _mission_director.get_active_mission_id().is_empty():
		if not _mission_director.start_mission(MISSION_ID):
			_fail_initialization(["تعذّر بدء مهمة صدى المريخ."])
			return
	_build_world_shell()
	_build_hud()
	_initialized = true
	_set_stage_visual(_stage_index)
	if _stage_index == 0 and _signal_pulses_inspected.is_empty():
		_start_opening_cinematic()
	if use_persistent_save and not FileAccess.file_exists(SAVE_PATH):
		_save_snapshot()

func _process(_delta: float) -> void:
	if _stage_index != 3 or not is_instance_valid(_rover_instance):
		return
	var found: PackedStringArray = _rover_instance.call("get_found_site_ids")
	for site_id in found:
		if not _rover_scanned_ids.has(str(site_id)):
			_on_rover_site_scanned(str(site_id))

func _unhandled_input(event: InputEvent) -> void:
	if not _opening_cinematic_active or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		if skip_opening_cinematic():
			get_viewport().set_input_as_handled()

func _fail_initialization(errors: Array[String]) -> void:
	_initialization_errors.append_array(errors)
	push_error("Echo of Mars initialization failed: " + "; ".join(errors))
	_build_minimal_error_hud()

func is_ready_for_play() -> bool:
	return _initialized and _initialization_errors.is_empty()

func get_initialization_errors() -> Array[String]:
	return _initialization_errors.duplicate()

func get_stage_index() -> int:
	return _stage_index

func is_opening_cinematic_active() -> bool:
	return _opening_cinematic_active

func skip_opening_cinematic() -> bool:
	if not _opening_cinematic_active:
		return false
	if _camera_tween != null and is_instance_valid(_camera_tween) and _camera_tween.is_running():
		_camera_tween.kill()
	_finish_opening_cinematic()
	return true

func get_stage_id() -> String:
	return STAGE_NAMES[_stage_index] if _stage_index >= 0 and _stage_index < STAGE_NAMES.size() else ""

func get_stage_ids() -> PackedStringArray:
	return PackedStringArray(STAGE_NAMES)

func get_rover_instance() -> Variant:
	return _rover_instance

func get_rover_scanned_ids() -> PackedStringArray:
	return PackedStringArray(_rover_scanned_ids)

func get_loaded_asset_ids() -> PackedStringArray:
	return PackedStringArray(_loaded_asset_ids)

func get_signal_pulses_inspected() -> PackedStringArray:
	return PackedStringArray(_signal_pulses_inspected)

func get_character_ids() -> Array[String]:
	return _character_roster.get_character_ids() if _character_roster != null else []

func get_selected_character_id() -> String:
	return _selected_character_id

func is_mission_completed() -> bool:
	return _mission_director != null and _mission_director.is_mission_completed(MISSION_ID)

func has_completion_reward() -> bool:
	return _reward_service != null and _reward_service.has_reward("reward.badge.echo_signal_detective")

func get_mission_progress() -> Dictionary:
	return _mission_director.get_mission_progress(MISSION_ID) if _mission_director != null else {}

func get_action_ids() -> PackedStringArray:
	var result := PackedStringArray()
	match _stage_index:
		0:
			for signal_id in ["one", "two", "three"]:
				if not _signal_pulses_inspected.has(signal_id):
					result.append("signal:" + signal_id)
			if _signal_pulses_inspected.size() == 3:
				result.append("inspect_signal")
		1: result.append("calibrate_tools")
		2: result.append_array(["landing:plateau","landing:rocky","landing:low_ridge"])
		3:
			if _rover_scanned_ids.size() >= 3: result.append("continue_to_photos")
		4:
			if not _photo_one_done: result.append("photo:angle_one")
			if not _photo_two_done: result.append("photo:angle_two")
		5:
			for id in ["reem","salim","lulu"]:
				if not _role_actions_done.has(id): result.append("role:" + id)
		6:
			for id in ["packet:one","packet:two","packet:three"]:
				if not _matched_packets.has(id): result.append(id)
		7:
			for id in ["power","align","clip"]:
				if not _relay_components.has(id): result.append("relay:" + id)
		8: result.append("send_acknowledgement")
	return result

func perform_action(action_id: String) -> bool:
	if not is_ready_for_play() or action_id.strip_edges().is_empty() or _dialogue_director_active or _opening_cinematic_active:
		return false
	_play_ui_sound("click")
	match _stage_index:
		0:
			if action_id.begins_with("signal:"):
				var signal_id := action_id.trim_prefix("signal:")
				if not ["one", "two", "three"].has(signal_id) or _signal_pulses_inspected.has(signal_id):
					return false
				_signal_pulses_inspected.append(signal_id)
				if not _save_snapshot():
					_signal_pulses_inspected.erase(signal_id)
					_feedback_label.text = "تعذّر حفظ هذه العينة. حاول فحصها مرة أخرى."
					return false
				_highlight_signal_trace(signal_id)
				_feedback_label.text = SIGNAL_FEEDBACK[signal_id]
				_play_ui_sound("open")
				_refresh_actions()
				return true
			if action_id != "inspect_signal" or _signal_pulses_inspected.size() != 3:
				return false
			if not _commit_events([{"id":"echo.signal.inspected","amount":1}],1): return false
			_after_stage_change("dialogue.echo.signal")
			return true
		1:
			if action_id != "calibrate_tools": return false
			if not _commit_events([{"id":"echo.tools.calibrated","amount":1}],2): return false
			_after_stage_change("")
			return true
		2:
			if not action_id.begins_with("landing:"): return false
			var site_id := action_id.trim_prefix("landing:")
			if not LANDING_SITES.has(site_id): return false
			var old_site := _landing_site_id
			_landing_site_id = site_id
			if not _commit_events([{"id":"echo.landing.chosen","amount":1}],3):
				_landing_site_id = old_site
				return false
			_after_stage_change("")
			return true
		3:
			if action_id != "continue_to_photos" or _rover_scanned_ids.size() < 3: return false
			var old_stage := _stage_index
			_stage_index = 4
			if not _save_snapshot():
				_stage_index = old_stage
				_feedback_label.text = "تعذّر حفظ الانتقال. بقيت في منطقة المسح."
				return false
			_set_stage_visual(4)
			return true
		4:
			if action_id == "photo:angle_one" and not _photo_one_done:
				_photo_one_done = true
				if not _commit_events([{"id":"echo.photo.angle_one","amount":1}]):
					_photo_one_done = false
					return false
				_feedback_label.text = "حُفظت الصورة الأولى. نحتاج زاوية مختلفة."
				_refresh_progress()
				_refresh_actions()
				return true
			if action_id == "photo:angle_two" and not _photo_two_done:
				_photo_two_done = true
				var next_stage := 5 if _photo_one_done else -1
				if not _commit_events([{"id":"echo.photo.angle_two","amount":1}],next_stage):
					_photo_two_done = false
					return false
				if next_stage == 5:
					_after_stage_change("dialogue.echo.photo")
				else:
					_feedback_label.text = "حُفظت الصورة الثانية. التقط الصورة الأولى أيضاً."
					_refresh_actions()
				return true
			return false
		5:
			if not action_id.begins_with("role:"): return false
			var character_id := action_id.trim_prefix("role:")
			if not ROLE_ABILITIES.has(character_id) or _role_actions_done.has(character_id): return false
			if not _character_roster.select_character(character_id): return false
			if not _character_roster.has_ability(character_id,str(ROLE_ABILITIES[character_id])): return false
			_selected_character_id = character_id
			_role_actions_done.append(character_id)
			var events: Array[Dictionary] = [{"id":"echo.team.role_action","amount":1}]
			if character_id == "lulu":
				_lulu_mark_found = true
				events.append({"id":"echo.lulu.mark_found","amount":1})
			var roles_complete := _role_actions_done.size() == 3 and _lulu_mark_found
			if not _commit_events(events,6 if roles_complete else -1):
				_role_actions_done.erase(character_id)
				if character_id == "lulu": _lulu_mark_found = false
				return false
			if roles_complete:
				_after_stage_change("dialogue.echo.lulu")
			else:
				_feedback_label.text = ROLE_LABELS[character_id] + " — تم تسجيل مساهمة هذه الشخصية."
				_refresh_stage()
			return true
		6:
			if not action_id.begins_with("packet:") or _matched_packets.has(action_id): return false
			_matched_packets.append(action_id)
			if _matched_packets.size() == 3:
				if not _commit_events([{"id":"echo.signal.packet_matched","amount":1}],7):
					_matched_packets.erase(action_id)
					return false
				_after_stage_change("")
			else:
				if not _save_snapshot():
					_matched_packets.erase(action_id)
					return false
				_feedback_label.text = "حُفظت هذه النبضة للمقارنة. افحص الأخريين."
				_refresh_stage()
			return true
		7:
			if not action_id.begins_with("relay:"): return false
			var component_id := action_id.trim_prefix("relay:")
			if not RELAY_LABELS.has(component_id) or _relay_components.has(component_id): return false
			var character_id := str({"power":"salim","align":"reem","clip":"lulu"}[component_id])
			if not _character_roster.select_character(character_id): return false
			_selected_character_id = character_id
			_relay_components.append(component_id)
			var next_relay_stage := 8 if _relay_components.size() == 3 else -1
			if not _commit_events([{"id":"echo.relay.component_ready","amount":1}],next_relay_stage):
				_relay_components.erase(component_id)
				return false
			if next_relay_stage == 8:
				_after_stage_change("dialogue.echo.relay")
			else:
				_feedback_label.text = RELAY_LABELS[component_id] + " — اكتمل هذا الجزء."
				_refresh_stage()
			return true
		8:
			if action_id != "send_acknowledgement": return false
			if not _commit_events([{"id":"echo.acknowledgement.sent","amount":1}],9): return false
			_after_stage_change("dialogue.echo.closure")
			return true
	return false

func dismiss_current_dialogue() -> bool:
	if _dialogue_director == null or not _dialogue_director.is_active(): return false
	_dialogue_director.skip()
	_dialogue_director_active = false
	if is_instance_valid(_dialogue_panel): _dialogue_panel.visible = false
	_refresh_actions()
	return true

func _on_interaction_received(event_id: String, payload: Dictionary) -> void:
	if _mission_director == null:
		_last_event_result = {"accepted":false}
		return
	_last_event_result = _mission_director.record_event(event_id,maxi(1,int(payload.get("amount",1))))

func _commit_events(events: Array[Dictionary], next_stage: int = -1) -> bool:
	var old_mission: Dictionary = _mission_director.export_state()
	var old_rewards: Dictionary = _reward_service.export_state()
	var old_stage := _stage_index
	for entry in events:
		_last_event_result.clear()
		var event_id := str(entry.get("id",""))
		var amount := maxi(1,int(entry.get("amount",1)))
		if not _interaction_router.publish(event_id,{"amount":amount}) or not bool(_last_event_result.get("accepted",false)):
			_mission_director.restore_state(old_mission)
			_reward_service.restore_state(old_rewards)
			_stage_index = old_stage
			_feedback_label.text = "لم تُسجّل الخطوة. بقي تقدم الرحلة السابق محفوظاً."
			return false
		if bool(_last_event_result.get("mission_completed",false)):
			_reward_service.unlock_for_mission(MISSION_ID)
	if next_stage >= 0:
		_stage_index = next_stage
	if not _save_snapshot():
		_mission_director.restore_state(old_mission)
		_reward_service.restore_state(old_rewards)
		_stage_index = old_stage
		_feedback_label.text = "تعذّر حفظ الخطوة. لم نفقد التقدم السابق؛ حاول مجدداً."
		return false
	return true

func _on_rover_site_scanned(site_id: String) -> void:
	if site_id.is_empty() or _rover_scanned_ids.has(site_id): return
	_rover_scanned_ids.append(site_id)
	if not _commit_events([{"id":"echo.rover.site_scanned","amount":1}]):
		_rover_scanned_ids.erase(site_id)
		return
	_play_ui_sound("confirm")
	_feedback_label.text = "سُجلت ملاحظة ميدانية %d من 3." % _rover_scanned_ids.size()
	_refresh_progress()
	_refresh_actions()

func _after_stage_change(dialogue_id: String) -> void:
	_play_ui_sound("confirm")
	_set_stage_visual(_stage_index)
	_refresh_stage()
	if not dialogue_id.is_empty():
		_open_dialogue(dialogue_id)
	else:
		_feedback_label.text = "تم حفظ التقدم. تابع عندما تكون جاهزاً."
		_refresh_actions()

func _set_stage_visual(stage_index: int) -> void:
	_stage_index = clampi(stage_index,0,9)
	_unmount_rover_scene()
	if _stage_index == 3:
		_mount_rover_scene()
	else:
		_build_stage_environment(_stage_index)
		_camera.make_current()
	_refresh_stage()

func _refresh_stage() -> void:
	if not is_instance_valid(_title_label): return
	_title_label.text = "صدى المريخ  •  " + STAGE_NAMES[_stage_index]
	_objective_label.text = STAGE_DESCRIPTIONS[_stage_index]
	if _stage_index == 3 and _rover_scanned_ids.size() < 3:
		_feedback_label.text = "قد الروفر إلى علامات الملاحظة الثلاثة ثم افحصها."
	elif _stage_index == 9:
		_feedback_label.text = "اكتملت الرحلة. أُضيفت شارة «محقق صدى المريخ»."
	_selected_label.text = "الشخصية المختارة: " + str(_character_roster.get_selected_character().get("name_ar","ريم"))
	_refresh_progress()
	_refresh_actions()

func _refresh_progress() -> void:
	if not is_instance_valid(_progress_label): return
	var progress: Dictionary = _mission_director.get_mission_progress(MISSION_ID)
	var counts: Dictionary = progress.get("objectives",{})
	var total := 0
	var completed := 0
	for value in _find_mission().get("objectives",[]):
		if not (value is Dictionary): continue
		var objective: Dictionary = value
		if not bool(objective.get("required",false)): continue
		var id := str(objective.get("id",""))
		var target := maxi(1,int(objective.get("target_count",1)))
		total += target
		completed += mini(target,int(counts.get(id,0)))
	_progress_label.text = "تقدم الرحلة  %d / %d" % [completed,total]

func _refresh_actions() -> void:
	if not is_instance_valid(_action_box): return
	for child in _action_box.get_children(): child.free()
	if _stage_index == 3:
		_action_box.visible = _rover_scanned_ids.size() >= 3
		if _action_box.visible: _add_action_button("اكتملت الملاحظات — تابع","continue_to_photos")
		return
	if _stage_index == 9:
		_action_box.visible = false
		return
	_action_box.visible = true
	match _stage_index:
		0:
			for signal_id in ["one", "two", "three"]:
				if not _signal_pulses_inspected.has(signal_id):
					_add_action_button(SIGNAL_ACTION_LABELS[signal_id], "signal:" + signal_id)
			if _signal_pulses_inspected.size() == 3:
				_add_action_button("قارن النبضات وتابع", "inspect_signal")
			_selected_label.text = "نبضات فُحصت: %d / 3" % _signal_pulses_inspected.size()
		1: _add_action_button("عاير أدوات المختبر","calibrate_tools")
		2:
			_add_action_button("الهضبة الهادئة","landing:plateau")
			_add_action_button("الممر الصخري","landing:rocky")
			_add_action_button("الحافة المنخفضة","landing:low_ridge")
		4:
			for id in get_action_ids():
				_add_action_button("التقط الصورة من " + ("الزاوية الأولى" if id.ends_with("one") else "الزاوية الثانية"),id)
		5:
			for id in get_action_ids():
				_add_action_button(ROLE_LABELS.get(id.trim_prefix("role:"),id),id)
			_selected_label.text = "مساهمات الفريق: %d / 3" % _role_actions_done.size()
		6:
			var packet_names := {"packet:one":"النبضة الأولى","packet:two":"النبضة الثانية","packet:three":"النبضة الثالثة"}
			for id in get_action_ids(): _add_action_button("قارن " + str(packet_names.get(id,id)),id)
			_selected_label.text = "الحزم التي فُحصت: %d / 3" % _matched_packets.size()
		7:
			for id in get_action_ids(): _add_action_button(RELAY_LABELS.get(id.trim_prefix("relay:"),id),id)
			_selected_label.text = "أجزاء المحطة: %d / 3" % _relay_components.size()
		8: _add_action_button("إرسال تأكيد الاستلام","send_acknowledgement")

func _build_world_shell() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "EchoWorldEnvironment"
	_world_environment = Environment.new()
	_configure_space_atmosphere()
	world_environment.environment = _world_environment
	add_child(world_environment)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48.0,-28.0,0.0)
	key_light.light_energy = 1.05
	key_light.shadow_enabled = true
	add_child(key_light)
	_world_root = Node3D.new()
	_world_root.name = "EchoWorld"
	add_child(_world_root)
	_camera = Camera3D.new()
	_camera.name = "EchoCamera"
	_camera.current = true
	_camera.fov = 52.0
	add_child(_camera)
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.name = "KenneyInterfaceAudio"
	_ui_sfx_player.volume_db = -9.0
	add_child(_ui_sfx_player)

func _configure_space_atmosphere() -> void:
	if _world_environment == null:
		return
	_world_environment.background_mode = Environment.BG_COLOR
	_world_environment.background_color = Color(0.012, 0.022, 0.052, 1.0)
	_world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_world_environment.ambient_light_color = Color(0.48, 0.55, 0.68, 1.0)
	_world_environment.ambient_light_energy = 0.8
	_world_environment.fog_enabled = false
	_world_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

func _build_stage_environment(stage_index: int) -> void:
	if stage_index >= 4 and stage_index <= 8:
		MarsLandscapeBuilder.configure_atmosphere(_world_environment)
	else:
		_configure_space_atmosphere()
	for child in _world_root.get_children(): child.free()
	_loaded_asset_ids.clear()
	match stage_index:
		0:
			_build_sana_environment()
			_build_echo_signal_display()
		1,2,9: _build_sana_environment()
		4:
			_build_mars_canyon_environment()
			_build_photo_markers()
		5:
			_build_mars_canyon_environment()
			_build_team_figures()
		6:
			_build_mars_canyon_environment()
			_build_signal_panels()
		7,8: _build_relay_environment()
		_: _build_sana_environment()

func _build_sana_environment() -> void:
	_add_box(_world_root,Vector3(0,-0.38,0),Vector3(24,0.5,18),Color(0.025,0.055,0.085),0.42)
	for z_index in range(4):
		for x_index in range(6):
			_add_station_asset("floor",Vector3(-10.0+float(x_index)*4.0,-0.08,-6.0+float(z_index)*4.0),Vector3.ONE)
	for x_index in range(6):
		var wall_id := "wall-window" if x_index == 1 or x_index == 4 else "wall"
		_add_station_asset(wall_id,Vector3(-10.0+float(x_index)*4.0,2.0,-8.0),Vector3.ONE)
	for z_index in range(4):
		var z := -6.0+float(z_index)*4.0
		_add_station_asset("wall",Vector3(-12.0,2.0,z),Vector3.ONE,Vector3(0.0,90.0,0.0))
		_add_station_asset("wall",Vector3(12.0,2.0,z),Vector3.ONE,Vector3(0.0,-90.0,0.0))
	_add_station_asset("wall-corner",Vector3(-12.0,2.0,-8.0),Vector3.ONE)
	_add_station_asset("wall-corner",Vector3(12.0,2.0,-8.0),Vector3.ONE,Vector3(0.0,-90.0,0.0))
	_add_station_asset("display-wall-wide",Vector3(0.0,2.1,-7.35),Vector3(1.18,0.92,0.92))
	_add_station_asset("table-display-planet",Vector3(0.0,0.02,-1.2),Vector3.ONE*0.92)
	_add_station_asset("computer",Vector3(-7.2,0.0,-4.2),Vector3.ONE*0.82)
	_add_station_asset("computer",Vector3(7.2,0.0,-4.2),Vector3.ONE*0.82,Vector3(0.0,180.0,0.0))
	_add_station_asset("chair",Vector3(-7.2,0.0,-2.3),Vector3.ONE*0.86)
	_add_station_asset("chair",Vector3(7.2,0.0,-2.3),Vector3.ONE*0.86,Vector3(0.0,180.0,0.0))
	_add_station_asset("table-inset",Vector3(-7.2,0.0,3.5),Vector3.ONE*0.9)
	_add_station_asset("container",Vector3(8.8,0.0,4.8),Vector3.ONE*0.78)
	_add_station_asset("wall-switch",Vector3(-11.72,1.55,0.0),Vector3.ONE*0.82,Vector3(0.0,90.0,0.0))
	_add_station_asset("pipe",Vector3(10.5,0.15,5.8),Vector3.ONE*0.88,Vector3(0.0,90.0,0.0))
	_add_station_asset("rail",Vector3(0.0,0.02,6.7),Vector3(1.35,0.82,0.82))
	_add_asset("basemodule_A",Vector3(-9.0,0.0,4.9),Vector3.ONE*0.55)
	_add_asset("solarpanel",Vector3(9.6,0.0,4.2),Vector3.ONE*0.56)
	_add_torus(_world_root,Vector3(0.0,1.15,-1.2),1.25,Color(0.20,0.72,0.92))
	for index in range(18):
		var x := -8.5+float(index)*1.0
		_add_sphere(_world_root,Vector3(x,4.0+sin(float(index))*0.18,-7.65),0.028+float(index%3)*0.012,Color(0.38,0.73,0.94,0.62))
	_set_camera_pose(Vector3(0.0,7.2,14.8),Vector3(0.0,1.2,-1.2),0.95)

func _build_echo_signal_display() -> void:
	var display_root := Node3D.new()
	display_root.name = "EchoSignalDisplay"
	display_root.position = Vector3(0.0, 0.0, -1.2)
	_world_root.add_child(display_root)

	_add_cylinder(display_root, Vector3(0.0, 1.47, 0.0), 0.62, 0.12, Color(0.035, 0.12, 0.17))
	_add_torus(display_root, Vector3(0.0, 1.56, 0.0), 0.68, Color(0.16, 0.72, 0.88))
	var globe := MeshInstance3D.new()
	globe.name = "MarsGlobe"
	var globe_mesh := SphereMesh.new()
	globe_mesh.radius = 0.91
	globe_mesh.height = 1.82
	globe_mesh.radial_segments = 48
	globe_mesh.rings = 24
	globe.mesh = globe_mesh
	globe.position = Vector3(0.0, 2.63, 0.0)
	var globe_material := StandardMaterial3D.new()
	globe_material.albedo_color = Color(0.82, 0.72, 0.64)
	globe_material.roughness = 0.82
	globe_material.emission_enabled = true
	globe_material.emission = Color(0.12, 0.035, 0.018)
	var mars_texture := ResourceLoader.load("res://assets/planetary_textures/mars.jpg") as Texture2D
	if mars_texture != null:
		globe_material.albedo_texture = mars_texture
	globe.material_override = globe_material
	display_root.add_child(globe)

	var orbit_colors := [
		Color(0.20, 0.82, 0.96),
		Color(0.98, 0.69, 0.39),
		Color(0.48, 0.69, 0.98)
	]
	var orbit_radii := [1.18, 1.37, 1.56]
	for index in range(3):
		var pulse_ring := MeshInstance3D.new()
		pulse_ring.name = "EchoPulseRing_%02d" % (index + 1)
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = float(orbit_radii[index]) * 0.985
		ring_mesh.outer_radius = float(orbit_radii[index])
		pulse_ring.mesh = ring_mesh
		pulse_ring.position = Vector3(0.0, 2.63, 0.0)
		pulse_ring.rotation = Vector3(
			deg_to_rad(58.0 + float(index) * 17.0),
			deg_to_rad(float(index) * 41.0),
			deg_to_rad(16.0 - float(index) * 13.0)
		)
		pulse_ring.material_override = _make_material(
			orbit_colors[index],
			orbit_colors[index] * 0.72,
			0.24
		)
		display_root.add_child(pulse_ring)
		var pulse_tween := pulse_ring.create_tween().set_loops()
		pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_interval(float(index) * 0.19)
		pulse_tween.tween_property(pulse_ring, "scale", Vector3.ONE * 1.10, 1.35 + float(index) * 0.18)
		pulse_tween.tween_property(pulse_ring, "scale", Vector3.ONE, 1.35 + float(index) * 0.18)

	var orbit_pivot := Node3D.new()
	orbit_pivot.name = "SignalOrbitPivot"
	orbit_pivot.position = Vector3(0.0, 2.63, 0.0)
	display_root.add_child(orbit_pivot)
	var signal_beacon := _add_sphere(
		orbit_pivot,
		Vector3(1.12, 0.0, 0.0),
		0.075,
		Color(0.98, 0.82, 0.49),
		1.8,
		0.18
	)
	signal_beacon.name = "SignalBeacon"
	var orbit_tween := orbit_pivot.create_tween().set_loops()
	orbit_tween.set_trans(Tween.TRANS_LINEAR)
	orbit_tween.tween_property(orbit_pivot, "rotation:y", TAU, 8.5).from(0.0)

	var globe_spin := globe.create_tween().set_loops()
	globe_spin.set_trans(Tween.TRANS_LINEAR)
	globe_spin.tween_property(globe, "rotation:y", TAU, 28.0).from(0.0)

	_build_echo_signal_waveform()
	for signal_id in _signal_pulses_inspected:
		_highlight_signal_trace(signal_id, false)
	_set_camera_pose(Vector3(0.0, 6.2, 12.8), Vector3(0.0, 2.25, -3.3), 1.45)

func _build_echo_signal_waveform() -> void:
	# Three identical traces make the repeated transmission legible before the reveal.
	var waveform := MultiMeshInstance3D.new()
	waveform.name = "EchoSignalWaveform"
	waveform.position = Vector3(0.0, 2.62, -6.68)
	waveform.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bars := BoxMesh.new()
	bars.size = Vector3(0.085, 0.46, 0.045)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = bars
	multimesh.instance_count = 96
	var heights := [
		0.18, 0.22, 0.30, 0.46, 0.76, 0.91, 0.68, 0.39,
		0.24, 0.18, 0.22, 0.34, 0.59, 0.86, 0.73, 0.42,
		0.25, 0.18, 0.20, 0.29, 0.48, 0.77, 0.94, 0.66,
		0.38, 0.23, 0.18, 0.20, 0.27, 0.19, 0.15, 0.12
	]
	var trace_colors := [
		Color(0.25, 0.84, 0.96),
		Color(0.39, 0.67, 0.98),
		Color(0.98, 0.72, 0.43)
	]
	for row in range(3):
		for column in range(32):
			var bar_height := float(heights[column])
			var bar_x := -3.12 + float(column) * 0.201
			var row_base := -float(row) * 0.54
			var transform_basis := Basis.IDENTITY.scaled(Vector3(1.0, bar_height, 1.0))
			var bar_transform := Transform3D(
				transform_basis,
				Vector3(bar_x, row_base + 0.23 * bar_height, 0.0)
			)
			var instance_id := row * 32 + column
			multimesh.set_instance_transform(instance_id, bar_transform)
			multimesh.set_instance_color(instance_id, trace_colors[row])
		var trace_marker := _add_sphere(
			waveform,
			Vector3(3.42, -float(row) * 0.54, 0.0),
			0.045,
			trace_colors[row],
			0.8,
			0.24
		)
		trace_marker.name = "EchoTraceMarker_%02d" % (row + 1)

		var signal_id: String = str(["one", "two", "three"][row])
		var hit_area := Area3D.new()
		hit_area.name = "SignalRowHitArea_%02d" % (row + 1)
		hit_area.input_ray_pickable = true
		hit_area.collision_layer = 1
		hit_area.collision_mask = 0
		hit_area.position = Vector3(0.0, -float(row) * 0.54 + 0.23, 0.0)
		var hit_shape := CollisionShape3D.new()
		hit_shape.name = "CollisionShape3D"
		var hit_box := BoxShape3D.new()
		hit_box.size = Vector3(7.25, 0.44, 0.42)
		hit_shape.shape = hit_box
		hit_area.add_child(hit_shape)
		hit_area.input_event.connect(_on_signal_row_input.bind(signal_id))
		waveform.add_child(hit_area)
	waveform.multimesh = multimesh
	var waveform_material := StandardMaterial3D.new()
	waveform_material.vertex_color_use_as_albedo = true
	waveform_material.emission_enabled = true
	waveform_material.emission = Color(0.12, 0.22, 0.28)
	waveform_material.roughness = 0.28
	waveform.material_override = waveform_material
	_world_root.add_child(waveform)

func _highlight_signal_trace(signal_id: String, animate_marker: bool = true) -> void:
	var row_lookup := {"one": 0, "two": 1, "three": 2}
	if not row_lookup.has(signal_id):
		return
	var waveform := _world_root.get_node_or_null("EchoSignalWaveform") as MultiMeshInstance3D
	if waveform == null or waveform.multimesh == null:
		return
	var row := int(row_lookup[signal_id])
	for column in range(32):
		waveform.multimesh.set_instance_color(row * 32 + column, Color(0.98, 0.91, 0.68))
	var marker := waveform.get_node_or_null("EchoTraceMarker_%02d" % (row + 1)) as MeshInstance3D
	if marker == null:
		return
	if animate_marker:
		var pulse := marker.create_tween()
		pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(marker, "scale", Vector3.ONE * 1.9, 0.17)
		pulse.tween_property(marker, "scale", Vector3.ONE, 0.28)
	else:
		marker.scale = Vector3.ONE * 1.35

func _on_signal_row_input(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int, signal_id: String) -> void:
	var activate := false
	if event is InputEventScreenTouch:
		activate = event.pressed
	elif event is InputEventMouseButton:
		activate = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if activate:
		perform_action("signal:" + signal_id)

func _build_mars_canyon_environment() -> void:
	MarsLandscapeBuilder.populate(_world_root, "cinematic")
	for i in range(16):
		var angle := TAU*float(i)/16.0
		var radius := 5.5+float(i%4)*2.0
		var location := Vector3(cos(angle)*radius,0,sin(angle)*radius-1.0)
		_add_asset("rocks_A" if i%2==0 else "rocks_B",location,Vector3.ONE*(0.55+float(i%3)*0.25))
	_add_asset("landingpad_small",Vector3(-8,0,7),Vector3.ONE*0.82)
	_add_asset("spacetruck",Vector3(8,0,7),Vector3.ONE*0.62)
	for value in LANDING_SITES.values():
		var p: Vector3 = value["position"]
		_add_torus(_world_root,p+Vector3(0,0.05,0),0.92,value["accent"])
	_set_camera_pose(Vector3(0.0,15.5,21.0),Vector3(0.0,0.6,-2.0),1.05)

func _build_photo_markers() -> void:
	_add_torus(_world_root,Vector3(-5,0.06,1.5),1.05,Color(0.98,0.78,0.43))
	_add_torus(_world_root,Vector3(5,0.06,-1.5),1.05,Color(0.30,0.77,0.97))
	_add_box(_world_root,Vector3(-5,1,1.5),Vector3(0.35,1.7,0.35),Color(0.12,0.24,0.31))
	_add_box(_world_root,Vector3(5,1,-1.5),Vector3(0.35,1.7,0.35),Color(0.12,0.24,0.31))

func _build_team_figures() -> void:
	_build_explorer_character("ReemExplorer", Vector3(-5.0, 0.0, 2.0), Color(0.22, 0.61, 0.76), Color(0.91, 0.72, 0.43), "reem")
	_build_explorer_character("SalimExplorer", Vector3(0.0, 0.0, 2.0), Color(0.82, 0.55, 0.24), Color(0.35, 0.76, 0.70), "salim")
	_build_lulu_companion(Vector3(5.0, 0.0, 2.0))
	_set_camera_pose(Vector3(0.0, 4.7, 8.6), Vector3(0.0, 1.25, 2.0), 1.25)

func _build_explorer_character(node_name: String, position: Vector3, suit_color: Color, trim_color: Color, character_id: String) -> void:
	var actor := Node3D.new()
	actor.name = node_name
	actor.position = position
	_world_root.add_child(actor)
	_add_cylinder(actor, Vector3(0.0, 0.13, 0.0), 0.98, 0.20, Color(0.035, 0.075, 0.105))
	_add_torus(actor, Vector3(0.0, 0.12, 0.0), 0.72, trim_color)
	var body := Node3D.new()
	body.name = "AnimatedBody"
	actor.add_child(body)
	_add_capsule(body, Vector3(0.0, 1.12, 0.0), 0.37, 1.08, suit_color)
	_add_box(body, Vector3(0.0, 1.10, 0.365), Vector3(0.43, 0.26, 0.08), trim_color, 0.32)
	_add_box(body, Vector3(0.0, 0.78, -0.31), Vector3(0.48, 0.52, 0.22), Color(0.12, 0.19, 0.25), 0.62)
	_add_box(body, Vector3(0.0, 1.10, -0.40), Vector3(0.58, 0.68, 0.24), Color(0.10, 0.17, 0.23), 0.68)
	_add_box(body, Vector3(0.0, 1.12, 0.414), Vector3(0.25, 0.19, 0.055), Color(0.07, 0.14, 0.19), 0.28)
	var chest_status := _add_sphere(body, Vector3(0.0, 1.12, 0.45), 0.055, trim_color, 0.38, 0.22)
	chest_status.name = "SuitStatusLight"
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 1.76, 0.0)
	body.add_child(head_pivot)
	_add_sphere(head_pivot, Vector3(0.0, 0.17, 0.0), 0.34, Color(0.91, 0.77, 0.64), 0.0, 0.42)
	_add_sphere(head_pivot, Vector3(0.0, 0.20, 0.275), 0.235, Color(0.12, 0.25, 0.34), 0.16, 0.18)
	_add_box(head_pivot, Vector3(0.0, -0.07, 0.26), Vector3(0.27, 0.055, 0.045), trim_color, 0.25)
	_add_box(body, Vector3(-0.43, 1.48, 0.0), Vector3(0.20, 0.24, 0.22), trim_color, 0.34)
	_add_box(body, Vector3(0.43, 1.48, 0.0), Vector3(0.20, 0.24, 0.22), trim_color, 0.34)
	_add_box(body, Vector3(-0.22, 0.72, 0.31), Vector3(0.16, 0.13, 0.08), Color(0.20, 0.30, 0.36), 0.38)
	_add_box(body, Vector3(0.22, 0.72, 0.31), Vector3(0.16, 0.13, 0.08), Color(0.20, 0.30, 0.36), 0.38)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmLeft" if side < 0.0 else "ArmRight"
		arm.position = Vector3(side * 0.43, 1.48, 0.0)
		body.add_child(arm)
		_add_capsule(arm, Vector3(0.0, -0.31, 0.0), 0.105, 0.68, suit_color)
		_add_sphere(arm, Vector3(0.0, -0.66, 0.02), 0.12, trim_color)
		_add_box(arm, Vector3(0.0, -0.48, 0.11), Vector3(0.18, 0.16, 0.09), Color(0.09, 0.17, 0.22), 0.28)
		var boot := _add_capsule(body, Vector3(side * 0.19, 0.36, 0.035), 0.13, 0.55, Color(0.12, 0.19, 0.25))
		boot.rotation_degrees.z = side * -4.0
	var badge := _add_sphere(body, Vector3(0.24, 1.25, 0.37), 0.085, trim_color, 0.18, 0.24)
	badge.name = "MissionBadge"
	var idle := actor.create_tween().set_loops()
	idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(body, "position:y", 0.045, 1.35).from(0.0)
	idle.tween_property(body, "position:y", 0.0, 1.35)
	var left_arm := body.get_node("ArmLeft") as Node3D
	var right_arm := body.get_node("ArmRight") as Node3D
	var gesture := actor.create_tween().set_loops()
	gesture.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	gesture.tween_property(left_arm, "rotation:z", deg_to_rad(-9.0), 1.8).from(0.0)
	gesture.tween_property(left_arm, "rotation:z", 0.0, 1.8)
	gesture.tween_interval(0.35)
	gesture.tween_property(right_arm, "rotation:z", deg_to_rad(9.0), 1.8).from(0.0)
	gesture.tween_property(right_arm, "rotation:z", 0.0, 1.8)
	var head_tween := actor.create_tween().set_loops()
	head_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	head_tween.tween_property(head_pivot, "rotation:y", deg_to_rad(4.0 if character_id == "reem" else -3.0), 2.1).from(0.0)
	head_tween.tween_property(head_pivot, "rotation:y", deg_to_rad(-4.0 if character_id == "reem" else 3.0), 2.1)
	var status_tween := actor.create_tween().set_loops()
	status_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	status_tween.tween_property(chest_status, "scale", Vector3.ONE * 1.18, 0.85).from(Vector3.ONE)
	status_tween.tween_property(chest_status, "scale", Vector3.ONE, 0.85)

func _build_lulu_companion(position: Vector3) -> void:
	var actor := Node3D.new()
	actor.name = "LuluCompanion"
	actor.position = position
	_world_root.add_child(actor)
	_add_torus(actor, Vector3(0.0, 0.12, 0.0), 0.72, Color(0.66, 0.80, 0.52))
	var body := Node3D.new()
	body.name = "AnimatedBody"
	actor.add_child(body)
	_add_sphere(body, Vector3(0.0, 0.62, 0.0), 0.58, Color(0.55, 0.70, 0.54), 0.0, 0.72)
	_add_sphere(body, Vector3(0.0, 0.92, 0.16), 0.46, Color(0.65, 0.42, 0.25), 0.0, 0.58)
	for side in [-1.0, 1.0]:
		var ear := _add_capsule(body, Vector3(side * 0.22, 1.34, 0.05), 0.065, 0.54, Color(0.72, 0.82, 0.67))
		ear.rotation_degrees.z = side * -13.0
		_add_sphere(body, Vector3(side * 0.18, 1.03, 0.55), 0.105, Color(0.98, 0.96, 0.85))
		_add_sphere(body, Vector3(side * 0.18, 1.03, 0.635), 0.045, Color(0.10, 0.20, 0.24))
	_add_sphere(body, Vector3(0.0, 0.80, 0.56), 0.075, Color(0.20, 0.29, 0.31))
	for side in [-1.0, 1.0]:
		for offset in [-0.28, 0.28]:
			_add_capsule(body, Vector3(side * 0.31, 0.22, offset), 0.075, 0.36, Color(0.39, 0.54, 0.40))
	var sensor := _add_sphere(body, Vector3(0.0, 1.48, 0.05), 0.12, Color(0.45, 0.86, 0.95), 0.7, 0.2)
	sensor.name = "SignalSensor"
	var idle := actor.create_tween().set_loops()
	idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(body, "position:y", 0.055, 1.05).from(0.0)
	idle.tween_property(body, "position:y", 0.0, 1.05)
	var scan := actor.create_tween().set_loops()
	scan.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scan.tween_property(sensor, "scale", Vector3.ONE * 1.22, 0.7).from(Vector3.ONE)
	scan.tween_property(sensor, "scale", Vector3.ONE, 0.7)

func _add_capsule(parent: Node3D, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = position
	part.material_override = _make_material(color, Color.BLACK, 0.48)
	parent.add_child(part)
	return part

func _build_signal_panels() -> void:
	_add_station_asset("display-wall-wide",Vector3(0.0,1.65,-4.2),Vector3(1.4,1.05,0.9))
	for index in range(3):
		var x := -5.0+float(index)*5.0
		_add_station_asset("computer",Vector3(x,0.0,0.8),Vector3.ONE*0.64,Vector3(0.0,180.0,0.0))
		_add_torus(_world_root,Vector3(x,2.55,-3.76),0.48,Color(0.27,0.75,0.92))
		_add_sphere(_world_root,Vector3(x,3.15,-3.78),0.09,Color(0.95,0.77,0.40),0.42)

func _build_relay_environment() -> void:
	_build_mars_canyon_environment()
	_add_station_asset("structure",Vector3(0.0,0.0,-2.2),Vector3.ONE*0.88)
	_add_station_asset("display-wall-wide",Vector3(0.0,1.4,-3.6),Vector3(0.85,0.82,0.82))
	_add_station_asset("computer",Vector3(-2.5,0.0,-1.6),Vector3.ONE*0.68)
	_add_station_asset("computer",Vector3(2.5,0.0,-1.6),Vector3.ONE*0.68,Vector3(0.0,180.0,0.0))
	_add_station_asset("table-inset",Vector3(0.0,0.0,0.7),Vector3.ONE*0.74)
	_add_cylinder(_world_root,Vector3(0,3.1,-2),0.22,3.1,Color(0.62,0.69,0.72))
	_add_torus(_world_root,Vector3(0,4.5,-2),1.55,Color(0.20,0.75,0.95))
	_add_asset("solarpanel",Vector3(-4.7,0,-2),Vector3.ONE*0.68)
	_add_asset("structure_low",Vector3(4.5,0,-2),Vector3.ONE*0.72)
	_set_camera_pose(Vector3(0.0,10.0,17.5),Vector3(0.0,2.0,-2.0),0.9)

func _mount_rover_scene() -> void:
	if is_instance_valid(_rover_instance): return
	_rover_instance = RoverScene.instantiate()
	_rover_instance.set("persistence_enabled",false)
	_rover_instance.set("allow_return_to_sana",false)
	_rover_instance.set("create_local_world_environment",false)
	_rover_instance.set("embedded_found_site_ids",PackedStringArray(_rover_scanned_ids))
	MarsLandscapeBuilder.configure_atmosphere(_world_environment)
	_rover_instance.name = "EmbeddedMarsRoverSurvey"
	add_child(_rover_instance)
	if _rover_instance.has_signal("site_scanned"):
		_rover_instance.connect("site_scanned",Callable(self,"_on_rover_site_scanned"))
	_feedback_label.text = "قد الروفر إلى مواقع الملاحظة الثلاثة. يمكن التوقف في أي وقت."
	_refresh_progress()
	_refresh_actions()

func _unmount_rover_scene() -> void:
	if is_instance_valid(_rover_instance): _rover_instance.queue_free()
	_rover_instance = null

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EchoOfMarsHUD"
	layer.layer = 40
	add_child(layer)
	_hud_root = Control.new()
	_hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_root.theme = preload("res://themes/arabic_theme.tres")
	_hud_root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(_hud_root)

	var header := PanelContainer.new()
	header.anchor_left=0.02
	header.anchor_top=0.02
	header.anchor_right=0.49
	header.anchor_bottom=0.22
	header.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.055,0.095,0.94),Color(0.20,0.65,0.80)))
	_hud_root.add_child(header)
	var hc := VBoxContainer.new()
	hc.layout_direction=Control.LAYOUT_DIRECTION_RTL
	hc.add_theme_constant_override("separation",4)
	header.add_child(hc)
	_title_label=_new_label("صدى المريخ",22,Color(0.96,0.98,1),true)
	hc.add_child(_title_label)
	_objective_label=_new_label("",14,Color(0.77,0.88,0.96))
	_objective_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hc.add_child(_objective_label)
	_feedback_label=_new_label("خذ وقتك. لا يوجد مؤقت.",13,Color(1.0,0.82,0.53))
	_feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hc.add_child(_feedback_label)

	var status:=PanelContainer.new()
	status.anchor_left=0.61
	status.anchor_top=0.02
	status.anchor_right=0.98
	status.anchor_bottom=0.14
	status.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.055,0.095,0.94),Color(0.20,0.65,0.80)))
	_hud_root.add_child(status)
	var sc:=VBoxContainer.new()
	sc.layout_direction=Control.LAYOUT_DIRECTION_RTL
	status.add_child(sc)
	_progress_label=_new_label("",16,Color(0.98,0.84,0.59),true)
	sc.add_child(_progress_label)
	_selected_label=_new_label("الشخصية المختارة: ريم",12,Color(0.76,0.88,0.95))
	sc.add_child(_selected_label)

	var action_panel:=PanelContainer.new()
	action_panel.anchor_left=0.70
	action_panel.anchor_top=0.20
	action_panel.anchor_right=0.98
	action_panel.anchor_bottom=0.74
	action_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.055,0.095,0.94),Color(0.20,0.65,0.80)))
	_hud_root.add_child(action_panel)
	_action_box=VBoxContainer.new()
	_action_box.layout_direction=Control.LAYOUT_DIRECTION_RTL
	_action_box.add_theme_constant_override("separation",8)
	action_panel.add_child(_action_box)

	_dialogue_panel=PanelContainer.new()
	_dialogue_panel.anchor_left=0.23
	_dialogue_panel.anchor_top=0.72
	_dialogue_panel.anchor_right=0.77
	_dialogue_panel.anchor_bottom=0.98
	_dialogue_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.055,0.095,0.97),Color(0.90,0.67,0.34)))
	_hud_root.add_child(_dialogue_panel)
	var dc:=VBoxContainer.new()
	dc.layout_direction=Control.LAYOUT_DIRECTION_RTL
	dc.add_theme_constant_override("separation",5)
	_dialogue_panel.add_child(dc)
	_dialogue_speaker=_new_label("",15,Color(0.98,0.82,0.51),true)
	dc.add_child(_dialogue_speaker)
	_dialogue_text=_new_label("",16,Color(0.94,0.97,1))
	_dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dc.add_child(_dialogue_text)
	_dialogue_choices=VBoxContainer.new()
	_dialogue_choices.layout_direction=Control.LAYOUT_DIRECTION_RTL
	dc.add_child(_dialogue_choices)
	_dialogue_panel.visible=false
	_build_opening_panel()

func _build_opening_panel() -> void:
	_opening_panel = PanelContainer.new()
	_opening_panel.name = "OpeningCinematicPanel"
	_opening_panel.anchor_left = 0.16
	_opening_panel.anchor_top = 0.70
	_opening_panel.anchor_right = 0.84
	_opening_panel.anchor_bottom = 0.975
	_opening_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.035, 0.064, 0.97), Color(0.30, 0.76, 0.91)))
	_hud_root.add_child(_opening_panel)
	var content := VBoxContainer.new()
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_theme_constant_override("separation", 4)
	_opening_panel.add_child(content)
	_opening_eyebrow = _new_label("", 11, Color(0.38, 0.83, 0.96), true)
	content.add_child(_opening_eyebrow)
	_opening_title = _new_label("", 23, Color(0.98, 0.94, 0.83), true)
	content.add_child(_opening_title)
	_opening_copy = _new_label("", 15, Color(0.80, 0.89, 0.96))
	_opening_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_opening_copy)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 2)
	content.add_child(spacer)
	var skip_button := _new_button("تجاوز المقدمة", 36)
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	skip_button.pressed.connect(skip_opening_cinematic)
	content.add_child(skip_button)
	_opening_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_opening_panel.visible = false

func _set_opening_card(index: int) -> void:
	if index < 0 or index >= OPENING_CARDS.size():
		return
	var card: Dictionary = OPENING_CARDS[index]
	if index > 0:
		_play_ui_sound("confirm")
	_opening_eyebrow.text = str(card.get("eyebrow", ""))
	_opening_title.text = str(card.get("title", ""))
	_opening_copy.text = str(card.get("copy", ""))

func _camera_transform(position: Vector3, focus: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(focus - position, Vector3.UP), position)

func _apply_camera_transition(weight: float, start_transform: Transform3D, end_transform: Transform3D) -> void:
	if not is_instance_valid(_camera):
		return
	var origin := start_transform.origin.lerp(end_transform.origin, weight)
	var basis := start_transform.basis.orthonormalized().slerp(end_transform.basis.orthonormalized(), weight)
	_camera.global_transform = Transform3D(basis, origin)

func _start_opening_cinematic() -> void:
	if not is_instance_valid(_opening_panel) or not is_instance_valid(_camera):
		return
	_opening_cinematic_active = true
	_play_ui_sound("click")
	var action_panel := _action_box.get_parent() as Control
	if action_panel != null:
		action_panel.visible = false
	_set_opening_card(0)
	_opening_panel.visible = true
	_opening_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var wide := _camera_transform(Vector3(-8.8, 8.0, 17.2), Vector3(0.0, 1.5, -1.2))
	var reveal := _camera_transform(Vector3(-3.8, 5.8, 11.6), Vector3(0.0, 2.55, -1.2))
	var close := _camera_transform(Vector3(0.0, 4.9, 8.7), Vector3(0.0, 2.65, -1.2))
	var settle := _camera_transform(Vector3(0.0, 6.2, 12.8), Vector3(0.0, 2.25, -3.3))
	_camera.global_transform = wide
	_camera.make_current()
	if _camera_tween != null and is_instance_valid(_camera_tween) and _camera_tween.is_running():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_opening_panel, "modulate", Color.WHITE, 0.45)
	_camera_tween.tween_method(Callable(self, "_apply_camera_transition").bind(wide, reveal), 0.0, 1.0, 1.7)
	_camera_tween.tween_interval(0.85)
	_camera_tween.tween_property(_opening_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.22)
	_camera_tween.tween_callback(Callable(self, "_set_opening_card").bind(1))
	_camera_tween.tween_property(_opening_panel, "modulate", Color.WHITE, 0.32)
	_camera_tween.tween_method(Callable(self, "_apply_camera_transition").bind(reveal, close), 0.0, 1.0, 1.65)
	_camera_tween.tween_interval(0.85)
	_camera_tween.tween_property(_opening_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.22)
	_camera_tween.tween_callback(Callable(self, "_set_opening_card").bind(2))
	_camera_tween.tween_property(_opening_panel, "modulate", Color.WHITE, 0.32)
	_camera_tween.tween_method(Callable(self, "_apply_camera_transition").bind(close, settle), 0.0, 1.0, 1.2)
	_camera_tween.tween_interval(0.65)
	_camera_tween.tween_property(_opening_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.28)
	_camera_tween.tween_callback(_finish_opening_cinematic)

func _finish_opening_cinematic() -> void:
	if not _opening_cinematic_active:
		return
	_opening_cinematic_active = false
	_camera_tween = null
	if is_instance_valid(_opening_panel):
		_opening_panel.visible = false
		_opening_panel.modulate = Color.WHITE
	if is_instance_valid(_action_box):
		var action_panel := _action_box.get_parent() as Control
		if action_panel != null:
			action_panel.visible = true
	_feedback_label.text = "وصلت الإشارة من أُفُق-1. افحص النبضات الثلاث قبل المقارنة."
	_refresh_actions()
	if _stage_index == 0 and _signal_pulses_inspected.is_empty():
		_open_dialogue("dialogue.prologue.signal")

func _open_dialogue(dialogue_id:String) -> void:
	_play_ui_sound("open")
	if not _dialogue_director.start_dialogue(dialogue_id):
		_feedback_label.text="تعذّر فتح الحوار. يمكنك متابعة المهمة."
		return
	_dialogue_director_active=true
	_dialogue_panel.visible=true
	_render_dialogue_node()

func _render_dialogue_node() -> void:
	for child in _dialogue_choices.get_children(): child.free()
	var dialogue_id: String = _dialogue_director.get_active_dialogue_id()
	var speaker_id:="mirqab"
	for entry in _bundle.get("dialogues",[]):
		if str(entry.get("id",""))==dialogue_id:
			speaker_id=str(entry.get("speaker_id","mirqab"))
			break
	var names:={"reem":"ريم","salim":"سليم","lulu":"لولو","mirqab":"مرقاب"}
	_dialogue_speaker.text=str(names.get(speaker_id,"الفريق"))
	_dialogue_text.text=_dialogue_director.get_current_text()
	var choices:Array=_dialogue_director.get_choices()
	if not choices.is_empty():
		for i in range(choices.size()):
			var choice:Dictionary=choices[i]
			var b:=_new_button(str(choice.get("text_ar","تابع")),42)
			b.pressed.connect(_choose_dialogue_choice.bind(i))
			_dialogue_choices.add_child(b)
	else:
		var next_button:=_new_button("تابع",42)
		next_button.pressed.connect(_advance_dialogue)
		_dialogue_choices.add_child(next_button)
	var skip_button:=_new_button("تجاوز الحوار",34)
	skip_button.pressed.connect(dismiss_current_dialogue)
	_dialogue_choices.add_child(skip_button)

func _choose_dialogue_choice(index:int) -> void:
	if _dialogue_director.choose(index):
		if _dialogue_director.is_active(): _render_dialogue_node()
		else:
			_dialogue_director_active=false
			_dialogue_panel.visible=false
			_refresh_actions()

func _advance_dialogue() -> void:
	if _dialogue_director.advance():
		if _dialogue_director.is_active(): _render_dialogue_node()
		else:
			_dialogue_director_active=false
			_dialogue_panel.visible=false
			_refresh_actions()

func _add_action_button(caption:String,action_id:String) -> void:
	var b:=_new_button(caption,48)
	b.pressed.connect(perform_action.bind(action_id))
	_action_box.add_child(b)

func _new_button(caption:String,height:float) -> Button:
	var b:=Button.new()
	b.text=caption
	b.custom_minimum_size=Vector2(0,height)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",Color(0.96,0.98,1))
	b.add_theme_stylebox_override("normal",_button_style(Color(0.07,0.20,0.30),Color(0.22,0.70,0.86)))
	b.add_theme_stylebox_override("hover",_button_style(Color(0.09,0.29,0.40),Color(0.40,0.82,0.94)))
	b.add_theme_stylebox_override("pressed",_button_style(Color(0.15,0.25,0.31),Color(0.98,0.74,0.40)))
	return b

func _new_label(value:String,size:int,color:Color,bold:bool=false) -> Label:
	var label:=Label.new()
	label.text=value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	if bold:
		label.add_theme_color_override("font_outline_color",Color(0.01,0.025,0.05,0.8))
		label.add_theme_constant_override("outline_size",1)
	return label

func _panel_style(background:Color,border:Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=background
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=10
	style.content_margin_bottom=10
	return style

func _button_style(background:Color,border:Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=background
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=6
	style.content_margin_bottom=6
	return style

func _add_box(parent:Node3D,position:Vector3,size:Vector3,color:Color,roughness:float=0.55) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	part.mesh=mesh
	part.position=position
	part.material_override=_make_material(color,Color.BLACK,roughness)
	parent.add_child(part)
	return part

func _add_sphere(parent:Node3D,position:Vector3,radius:float,color:Color,emission:float=0.0,roughness:float=0.5) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2.0
	part.mesh=mesh
	part.position=position
	var glow:=color*emission if emission>0.0 else Color.BLACK
	part.material_override=_make_material(color,glow,roughness)
	parent.add_child(part)
	return part

func _add_cylinder(parent:Node3D,position:Vector3,radius:float,height:float,color:Color) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	part.mesh=mesh
	part.position=position
	part.material_override=_make_material(color,Color.BLACK,0.65)
	parent.add_child(part)
	return part

func _add_torus(parent:Node3D,position:Vector3,radius:float,color:Color) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=TorusMesh.new()
	mesh.inner_radius=radius*0.91
	mesh.outer_radius=radius
	part.mesh=mesh
	part.position=position
	part.rotation_degrees.x=90.0
	part.material_override=_make_material(color,color*0.28,0.35)
	parent.add_child(part)
	return part

func _add_asset(asset_id:String,position:Vector3,scale_value:Vector3) -> bool:
	if not KAYKIT_MODELS.has(asset_id): return false
	var path:=str(KAYKIT_MODELS[asset_id])
	if not ResourceLoader.exists(path): return false
	var packed:PackedScene=load(path)
	if packed==null: return false
	var instance=packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		return false
	instance.position=position
	instance.scale=scale_value
	_world_root.add_child(instance)
	if not _loaded_asset_ids.has(asset_id): _loaded_asset_ids.append(asset_id)
	return true


func _add_station_asset(asset_id:String,position:Vector3,scale_value:Vector3=Vector3.ONE,rotation_value:Vector3=Vector3.ZERO) -> bool:
	if not KENNEY_STATION_MODELS.has(asset_id):
		return false
	var model_path := str(KENNEY_STATION_MODELS[asset_id])
	if not _station_scene_cache.has(asset_id):
		if not ResourceLoader.exists(model_path):
			return false
		var loaded := ResourceLoader.load(model_path) as PackedScene
		if loaded == null:
			return false
		_station_scene_cache[asset_id] = loaded
	var packed:PackedScene = _station_scene_cache[asset_id]
	var instance:Node = packed.instantiate()
	var spatial := instance as Node3D
	if spatial == null:
		instance.free()
		return false
	spatial.position = position
	spatial.scale = scale_value
	spatial.rotation_degrees = rotation_value
	_world_root.add_child(spatial)
	var loaded_id := "kenney:" + asset_id
	if not _loaded_asset_ids.has(loaded_id):
		_loaded_asset_ids.append(loaded_id)
	return true

func _set_camera_pose(target_position:Vector3,target_focus:Vector3,duration:float=0.9) -> void:
	if not is_instance_valid(_camera):
		return
	var target_basis := Basis.looking_at(target_focus-target_position,Vector3.UP)
	if not _has_camera_pose:
		_camera.global_transform = Transform3D(target_basis,target_position)
		_has_camera_pose = true
		return
	if _camera_tween != null and _camera_tween.is_running():
		_camera_tween.kill()
	var start_transform := _camera.global_transform
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_method(Callable(self,"_apply_camera_pose").bind(start_transform,target_basis,target_position),0.0,1.0,maxf(0.08,duration))

func _apply_camera_pose(weight:float,start_transform:Transform3D,target_basis:Basis,target_position:Vector3) -> void:
	if not is_instance_valid(_camera):
		return
	var blended_origin := start_transform.origin.lerp(target_position,weight)
	var blended_basis := start_transform.basis.orthonormalized().slerp(target_basis,weight)
	_camera.global_transform = Transform3D(blended_basis,blended_origin)

func _play_ui_sound(sound_id:String) -> void:
	# Headless validation imports audio separately; avoid creating playback instances
	# when no audio output device exists, which otherwise leaves engine-owned handles.
	if DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(_ui_sfx_player) or not KENNEY_AUDIO_PATHS.has(sound_id):
		return
	if not _audio_stream_cache.has(sound_id):
		var stream_path := str(KENNEY_AUDIO_PATHS[sound_id])
		if not ResourceLoader.exists(stream_path):
			return
		var loaded_stream := ResourceLoader.load(stream_path) as AudioStream
		if loaded_stream == null:
			return
		_audio_stream_cache[sound_id] = loaded_stream
	_ui_sfx_player.stream = _audio_stream_cache[sound_id]
	_ui_sfx_player.play()

func _make_material(color:Color,emission:Color,roughness:float) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness
	if emission!=Color.BLACK:
		material.emission_enabled=true
		material.emission=emission
	return material

func _default_snapshot() -> Dictionary:
	return {"version":SAVE_VERSION,"mission_state":{},"reward_state":{},"stage_index":0,"landing_site_id":"rocky","rover_scanned_ids":[],"signal_pulses_inspected":[],"photo_one_done":false,"photo_two_done":false,"role_actions_done":[],"lulu_mark_found":false,"matched_packets":[],"relay_components":[],"selected_character_id":"reem"}

func _load_snapshot() -> Dictionary:
	var defaults:=_default_snapshot()
	if not FileAccess.file_exists(SAVE_PATH): return defaults
	var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if file==null: return defaults
	var parsed:Variant=JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or int(parsed.get("version",0))!=SAVE_VERSION: return defaults
	var snapshot:=defaults.duplicate(true)
	for key in ["mission_state","reward_state"]:
		var value:Variant=parsed.get(key,{})
		if value is Dictionary: snapshot[key]=value.duplicate(true)
	snapshot["stage_index"]=clampi(int(parsed.get("stage_index",0)),0,9)
	var landing:=str(parsed.get("landing_site_id","rocky"))
	snapshot["landing_site_id"]=landing if LANDING_SITES.has(landing) else "rocky"
	snapshot["rover_scanned_ids"]=_clean_ids(parsed.get("rover_scanned_ids",[]),["layered_rock","sand_ripples","crater_rim"])
	snapshot["signal_pulses_inspected"]=_clean_ids(parsed.get("signal_pulses_inspected",[]),["one","two","three"])
	snapshot["photo_one_done"]=bool(parsed.get("photo_one_done",false))
	snapshot["photo_two_done"]=bool(parsed.get("photo_two_done",false))
	snapshot["role_actions_done"]=_clean_ids(parsed.get("role_actions_done",[]),["reem","salim","lulu"])
	snapshot["lulu_mark_found"]=bool(parsed.get("lulu_mark_found",false))
	snapshot["matched_packets"]=_clean_ids(parsed.get("matched_packets",[]),["packet:one","packet:two","packet:three"])
	snapshot["relay_components"]=_clean_ids(parsed.get("relay_components",[]),["power","align","clip"])
	var selected:=str(parsed.get("selected_character_id","reem"))
	snapshot["selected_character_id"]=selected if ["reem","salim","lulu"].has(selected) else "reem"
	return snapshot

func _restore_extra_state(snapshot:Dictionary) -> void:
	_stage_index=clampi(int(snapshot.get("stage_index",0)),0,9)
	var landing:=str(snapshot.get("landing_site_id","rocky"))
	_landing_site_id=landing if LANDING_SITES.has(landing) else "rocky"
	_rover_scanned_ids=_clean_ids(snapshot.get("rover_scanned_ids",[]),["layered_rock","sand_ripples","crater_rim"])
	_signal_pulses_inspected=_clean_ids(snapshot.get("signal_pulses_inspected",[]),["one","two","three"])
	_photo_one_done=bool(snapshot.get("photo_one_done",false))
	_photo_two_done=bool(snapshot.get("photo_two_done",false))
	_role_actions_done=_clean_ids(snapshot.get("role_actions_done",[]),["reem","salim","lulu"])
	_lulu_mark_found=bool(snapshot.get("lulu_mark_found",false))
	_matched_packets=_clean_ids(snapshot.get("matched_packets",[]),["packet:one","packet:two","packet:three"])
	_relay_components=_clean_ids(snapshot.get("relay_components",[]),["power","align","clip"])
	_selected_character_id=str(snapshot.get("selected_character_id","reem"))

func _clean_ids(raw:Variant,allowed:Array) -> Array[String]:
	var result:Array[String]=[]
	if raw is Array:
		for value in raw:
			var item:=str(value)
			if allowed.has(item) and not result.has(item): result.append(item)
	return result

func _save_snapshot() -> bool:
	if not use_persistent_save: return true
	var snapshot:Dictionary={
		"version":SAVE_VERSION,
		"mission_state":_mission_director.export_state(),
		"reward_state":_reward_service.export_state(),
		"stage_index":_stage_index,
		"landing_site_id":_landing_site_id,
		"rover_scanned_ids":_rover_scanned_ids.duplicate(),
		"signal_pulses_inspected":_signal_pulses_inspected.duplicate(),
		"photo_one_done":_photo_one_done,
		"photo_two_done":_photo_two_done,
		"role_actions_done":_role_actions_done.duplicate(),
		"lulu_mark_found":_lulu_mark_found,
		"matched_packets":_matched_packets.duplicate(),
		"relay_components":_relay_components.duplicate(),
		"selected_character_id":_selected_character_id
	}
	var temp_path:=SAVE_PATH+".tmp"
	var file:=FileAccess.open(temp_path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var write_error:=file.get_error()
	file.close()
	if write_error!=OK: return false
	var final_abs:=ProjectSettings.globalize_path(SAVE_PATH)
	var temp_abs:=ProjectSettings.globalize_path(temp_path)
	var backup_abs:=ProjectSettings.globalize_path(SAVE_PATH+".bak")
	var had_previous:=FileAccess.file_exists(SAVE_PATH)
	if had_previous:
		if FileAccess.file_exists(SAVE_PATH+".bak"): DirAccess.remove_absolute(backup_abs)
		if DirAccess.rename_absolute(final_abs,backup_abs)!=OK:
			DirAccess.remove_absolute(temp_abs)
			return false
	if DirAccess.rename_absolute(temp_abs,final_abs)!=OK:
		if had_previous: DirAccess.rename_absolute(backup_abs,final_abs)
		DirAccess.remove_absolute(temp_abs)
		return false
	if had_previous and FileAccess.file_exists(SAVE_PATH+".bak"): DirAccess.remove_absolute(backup_abs)
	return true

func _build_minimal_error_hud() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var panel:=PanelContainer.new()
	panel.position=Vector2(24,24)
	panel.custom_minimum_size=Vector2(600,220)
	layer.add_child(panel)
	var label:=Label.new()
	label.text="تعذّر تهيئة تجربة صدى المريخ:\n"+"\n".join(_initialization_errors)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)

func _find_mission() -> Dictionary:
	for entry in _bundle.get("missions",[]):
		if str(entry.get("id",""))==MISSION_ID: return entry.duplicate(true)
	return {}
