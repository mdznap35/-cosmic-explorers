extends Node3D
## Standalone, offline-first graybox for the first playable ship hub.
## The solar-system main scene is intentionally left untouched.

const ContentRegistry = preload("res://scripts/content_registry.gd")
const GameplayRuntime = preload("res://scripts/gameplay_runtime.gd")
const InteractionRouter = preload("res://scripts/interaction_router.gd")

const SAVE_PATH := "user://sana_hub_prototype.json"
const SAVE_VERSION := 2
const ALBUM_DIR := "user://observatory_album"
const KAYKIT_ASSET_ROOT := "res://assets/vendor/kaykit_space_base_bits"
const KAYKIT_ASSET_PATHS := {
	"basemodule_A": KAYKIT_ASSET_ROOT + "/basemodule_A.gltf",
	"lander_A": KAYKIT_ASSET_ROOT + "/lander_A.gltf",
	"landingpad_small": KAYKIT_ASSET_ROOT + "/landingpad_small.gltf",
	"rocks_A": KAYKIT_ASSET_ROOT + "/rocks_A.gltf",
	"rocks_B": KAYKIT_ASSET_ROOT + "/rocks_B.gltf",
	"solarpanel": KAYKIT_ASSET_ROOT + "/solarpanel.gltf",
	"spacetruck": KAYKIT_ASSET_ROOT + "/spacetruck.gltf",
	"structure_low": KAYKIT_ASSET_ROOT + "/structure_low.gltf"
}
const MOVE_SPEED := 4.0
const GRAVITY := 18.0
const INTERACTION_DISTANCE := 2.6

const STATION_IDS := [
	"bridge",
	"workshop",
	"laboratory",
	"observatory",
	"lulu_nook"
]
const RELAY_SEQUENCE := [
	"moon_relay",
	"sana_station",
	"mars_rover"
]
const RELAY_LABELS := {
	"moon_relay": "قمر الاتصال",
	"sana_station": "محطة سَنا",
	"mars_rover": "مركبة الروفر"
}
const CUBESAT_SEQUENCE := [
	"central_bus",
	"solar_panels",
	"communication_antenna",
	"science_camera"
]
const CUBESAT_LABELS := {
	"central_bus": "الهيكل المركزي",
	"solar_panels": "ألواح الطاقة الشمسية",
	"communication_antenna": "هوائي الاتصال",
	"science_camera": "كاميرا الملاحظة"
}
const LULU_STAR_POSITIONS := {
	"star_bridge": Vector3(0.9, 0.92, -1.8),
	"star_workshop": Vector3(-8.7, 0.92, 0.1),
	"star_lab": Vector3(-4.8, 1.12, 0.4),
	"star_observatory": Vector3(5.6, 0.92, -4.1),
	"star_corridor": Vector3(8.7, 0.92, 3.8)
}
const OBSERVATORY_TARGET_IDS := ["moon", "mars", "saturn"]
const OBSERVATORY_TARGETS := {
	"moon": {
		"title": "القمر",
		"caption": "وثّقنا تضاريس القمر وظلال الفوهات في لقطة رصد جديدة.",
		"base_color": Color(0.67, 0.70, 0.74)
	},
	"mars": {
		"title": "المريخ",
		"caption": "حُفظت لقطة لسطح المريخ المحمر؛ يرتبط لونه في كثير من الغبار والصخور بأكاسيد الحديد.",
		"base_color": Color(0.76, 0.31, 0.19)
	},
	"saturn": {
		"title": "زحل",
		"caption": "وثّقنا زحل وحلقاته الواسعة في سجل المرصد.",
		"base_color": Color(0.83, 0.69, 0.43)
	}
}

const STATION_DATA := {
	"bridge": {
		"title": "جسر القيادة",
		"hint": "وصّل رسالة مرقاب إلى مركبة الروفر.",
		"description": "هنا يختار الفريق الوجهة ويتابع الإشارات. جرّب لعبة توجيه الرسالة."
	},
	"workshop": {
		"title": "ورشة سليم",
		"hint": "مساحة تجهيز وبناء المركبات.",
		"description": "في الورشة يجهّز سليم الأدوات، ويرتب وحدات القمر المصغّر، ويتأكد من جاهزية الروفر."
	},
	"laboratory": {
		"title": "مختبر مرقاب",
		"hint": "انطلق بمركبة المسح إلى سطح المريخ.",
		"description": "جرّب قيادة الروفر وسجّل ثلاث ملاحظات مختلفة. لاحظ أولاً، ثم استنتج بحذر."
	},
	"observatory": {
		"title": "مرصد ريم",
		"hint": "راقب السماء وسجل الصور.",
		"description": "يتيح المرصد تكبير الأجرام وملاحظة الضوء والظلال وحفظ صور الرحلات."
	},
	"lulu_nook": {
		"title": "ركن لولو",
		"hint": "مكان صغير للأسرار والمرح.",
		"description": "يحب لولو اكتشاف الزوايا الصغيرة وترتيب مقتنيات الرحلة. سنضيف هنا نشاط البحث عن النجوم المخفية في دفعة لاحقة."
	}
}

@export var enable_gameplay_bridge := true

var _player: CharacterBody3D
var _camera: Camera3D
var _hud: Control
var _status_label: Label
var _nearby_label: Label
var _interaction_button: Button
var _modal_panel: PanelContainer
var _modal_content: VBoxContainer
var _relay_progress_label: Label
var _relay_feedback_label: Label
var _relay_buttons: Array[Button] = []
var _cubesat_progress_label: Label
var _cubesat_feedback_label: Label
var _cubesat_buttons: Array[Button] = []
var _lulu_hunt_feedback_label: Label
var _observatory_progress_label: Label
var _observatory_feedback_label: Label
var _observatory_preview: TextureRect
var _observatory_buttons: Array[Button] = []
var _observatory_feedback := ""
var _observatory_active := false

var _loaded_reused_prop_ids: Array[String] = []

var _stations: Dictionary = {}
var _secret_star_nodes: Dictionary = {}
var _nearby_secret_star_id := ""
var _touch_keys: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}
var _nearby_station_id := ""
var _modal_active := false
var _relay_progress := 0
var _relay_feedback := ""
var _cubesat_display_added := false
var _lulu_hunt_active := false
var _state: Dictionary = {}

var _interaction_router
var _gameplay_runtime
var _gameplay_bridge_ready := false


func _ready() -> void:
	_state = _load_state()
	_relay_progress = clampi(int(_state.get("relay_progress", 0)), 0, RELAY_SEQUENCE.size())
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	_setup_gameplay_bridge()
	_update_nearby_station()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		return
	_update_camera()
	_update_nearby_station()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if _modal_active:
		_player.velocity = Vector3.ZERO
		return

	var horizontal := 0.0
	var vertical := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		horizontal -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		horizontal += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		vertical -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		vertical += 1.0

	if bool(_touch_keys.get("left", false)):
		horizontal -= 1.0
	if bool(_touch_keys.get("right", false)):
		horizontal += 1.0
	if bool(_touch_keys.get("up", false)):
		vertical -= 1.0
	if bool(_touch_keys.get("down", false)):
		vertical += 1.0

	var direction := Vector3(horizontal, 0.0, vertical)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	_player.velocity.x = direction.x * MOVE_SPEED
	_player.velocity.z = direction.z * MOVE_SPEED
	if not _player.is_on_floor():
		_player.velocity.y -= GRAVITY * delta
	else:
		_player.velocity.y = 0.0

	_player.move_and_slide()
	_player.global_position.x = clampf(_player.global_position.x, -10.4, 10.4)
	_player.global_position.z = clampf(_player.global_position.z, -6.5, 6.5)

	if direction.length_squared() > 0.01:
		_player.rotation.y = atan2(direction.x, direction.z)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and is_instance_valid(_modal_panel):
			_close_modal()
			return
		if _modal_active:
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			interact_with_nearest_station()


# Public surface used by the headless acceptance test and future UI integration.
func get_station_ids() -> PackedStringArray:
	return PackedStringArray(STATION_IDS)


func get_visited_station_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for station_id in _state.get("visited_station_ids", []):
		result.append(str(station_id))
	return result


func get_reused_asset_model_count() -> int:
	var available_count := 0
	for model_path in KAYKIT_ASSET_PATHS.values():
		if ResourceLoader.exists(str(model_path)):
			available_count += 1
	return available_count


func get_loaded_reused_prop_ids() -> PackedStringArray:
	return PackedStringArray(_loaded_reused_prop_ids)


func get_observatory_target_ids() -> PackedStringArray:
	return PackedStringArray(OBSERVATORY_TARGET_IDS)


func get_observatory_photo_ids() -> PackedStringArray:
	return PackedStringArray(_state.get("observatory_photo_ids", []))


func get_observatory_progress() -> int:
	return get_observatory_photo_ids().size()


func is_observatory_complete() -> bool:
	return get_observatory_progress() == OBSERVATORY_TARGET_IDS.size()


func get_observatory_photo_path(target_id: String) -> String:
	if not OBSERVATORY_TARGETS.has(target_id):
		return ""
	return ALBUM_DIR.path_join(target_id + ".png")


func start_observatory_activity() -> bool:
	_observatory_feedback = "اختر جرماً سماوياً لالتقاط صورة بأسلوب المرصد."
	_show_observatory_panel()
	return true


func capture_observation(target_id: String) -> bool:
	if not _observatory_active or not OBSERVATORY_TARGETS.has(target_id):
		return false
	var photos: Array = _state.get("observatory_photo_ids", [])
	if photos.has(target_id):
		_observatory_feedback = "هذه الصورة محفوظة بالفعل في ألبوم ريم."
		_refresh_observatory_panel()
		return false
	if not _save_observatory_thumbnail(target_id):
		_observatory_feedback = "تعذّر إنشاء الصورة. لم نحتسب هذه اللقطة."
		_refresh_observatory_panel()
		return false
	photos.append(target_id)
	_state["observatory_photo_ids"] = photos
	if not _save_state():
		photos.erase(target_id)
		_state["observatory_photo_ids"] = photos
		var photo_path := get_observatory_photo_path(target_id)
		if FileAccess.file_exists(photo_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(photo_path))
		_observatory_feedback = "تعذّر حفظ التقدم. يمكنك المحاولة مجدداً."
		_refresh_observatory_panel()
		return false
	_observatory_feedback = str(OBSERVATORY_TARGETS[target_id]["caption"])
	_refresh_observatory_panel()
	return true


func get_relay_progress() -> int:
	return _relay_progress


func is_relay_completed() -> bool:
	return bool(_state.get("relay_activity_completed", false))


func get_cubesat_progress() -> int:
	return clampi(int(_state.get("cubesat_step", 0)), 0, CUBESAT_SEQUENCE.size())


func is_cubesat_built() -> bool:
	return bool(_state.get("cubesat_built", false))


func get_lulu_star_ids() -> PackedStringArray:
	return PackedStringArray(LULU_STAR_POSITIONS.keys())


func get_lulu_found_star_ids() -> PackedStringArray:
	return PackedStringArray(_state.get("lulu_found_star_ids", []))


func is_lulu_hunt_completed() -> bool:
	return bool(_state.get("lulu_hunt_completed", false))


func start_lulu_hunt() -> bool:
	if is_lulu_hunt_completed():
		_show_info_panel("أسرار لولو", "لقد عثرت على كل النجوم الخمس! عاد ضوؤها إلى خريطة السفينة.", "يمكنك العودة إلى الاستكشاف متى شئت.")
		return true
	_lulu_hunt_active = true
	_show_lulu_hunt_panel()
	return true


func collect_lulu_star(star_id: String) -> bool:
	if not _lulu_hunt_active or not LULU_STAR_POSITIONS.has(star_id):
		return false
	var found_ids: Array = _state.get("lulu_found_star_ids", [])
	if found_ids.has(star_id):
		return false
	found_ids.append(star_id)
	_state["lulu_found_star_ids"] = found_ids
	if _secret_star_nodes.has(star_id):
		var star: Node3D = _secret_star_nodes[star_id]
		if is_instance_valid(star):
			star.queue_free()
		_secret_star_nodes.erase(star_id)
	if found_ids.size() >= LULU_STAR_POSITIONS.size():
		_state["lulu_hunt_completed"] = true
		_lulu_hunt_active = false
		if is_instance_valid(_lulu_hunt_feedback_label):
			_lulu_hunt_feedback_label.text = "وجدت كل النجوم! أحسنت يا مستكشف!"
	_save_state()
	if is_instance_valid(_lulu_hunt_feedback_label) and not is_lulu_hunt_completed():
		_refresh_lulu_hunt_panel()
	return true


func start_cubesat_activity() -> bool:
	_show_cubesat_panel()
	return true

func start_lunar_outpost_activity() -> bool:
	_close_modal()
	var scene_result := get_tree().change_scene_to_file("res://scenes/prototypes/lunar_outpost_builder.tscn")
	if scene_result != OK:
		push_warning("Unable to open the lunar outpost builder.")
		return false
	return true


func select_cubesat_part(part_id: String) -> bool:
	var current_step := get_cubesat_progress()
	if current_step >= CUBESAT_SEQUENCE.size():
		return false
	var expected_id: String = CUBESAT_SEQUENCE[current_step]
	if part_id != expected_id:
		if is_instance_valid(_cubesat_feedback_label):
			_cubesat_feedback_label.text = "لنبدأ بالهيكل المركزي، ثم نضيف الطاقة والاتصال والكاميرا. لا مشكلة، جرّب مجدداً."
		return false

	current_step += 1
	_state["cubesat_step"] = current_step
	if current_step >= CUBESAT_SEQUENCE.size():
		_state["cubesat_built"] = true
	_save_state()
	if is_cubesat_built():
		_add_cubesat_display()
	_refresh_cubesat_panel()
	return true


func is_gameplay_bridge_ready() -> bool:
	return _gameplay_bridge_ready


func start_relay_activity() -> bool:
	_relay_progress = clampi(int(_state.get("relay_progress", 0)), 0, RELAY_SEQUENCE.size())
	_relay_feedback = "تابع من المحطة التالية في مسار الاتصال."
	if _relay_progress == 0:
		_relay_feedback = "ابدأ من قمر الاتصال، ثم محطة سَنا، ثم مركبة الروفر."
	_show_relay_panel()
	return true


func submit_relay_node(relay_id: String) -> bool:
	if not _modal_active or _relay_progress >= RELAY_SEQUENCE.size():
		return false

	var expected_id: String = RELAY_SEQUENCE[_relay_progress]
	if relay_id != expected_id:
		_relay_feedback = "ليست هذه المحطة التالية. اتبع مسار الرسالة من المصدر إلى الوجهة."
		_refresh_relay_panel()
		return false

	_relay_progress += 1
	_state["relay_progress"] = _relay_progress
	if _relay_progress >= RELAY_SEQUENCE.size():
		_state["relay_activity_completed"] = true
		_relay_feedback = "وصلت الرسالة إلى الروفر! أحسنت تنظيم مسار الاتصال."
		_publish_gameplay_event("signal.interacted", {"activity_id": "activity.relay_message"})
	else:
		_relay_feedback = "ممتاز! انتقلت الرسالة إلى المحطة التالية."
	_save_state()
	_refresh_relay_panel()
	return true


func interact_with_nearest_station() -> bool:
	if _lulu_hunt_active and not _nearby_secret_star_id.is_empty():
		return collect_lulu_star(_nearby_secret_star_id)
	if _nearby_station_id.is_empty():
		return false
	return interact_station(_nearby_station_id)


func interact_station(station_id: String) -> bool:
	if not STATION_DATA.has(station_id):
		return false

	var visited: Array = _state.get("visited_station_ids", [])
	var first_visit := not visited.has(station_id)
	if first_visit:
		visited.append(station_id)
		_state["visited_station_ids"] = visited
		_save_state()
		_publish_gameplay_event("ship.room.visited", {"station_id": station_id})

	if station_id == "bridge":
		start_relay_activity()
		return true
	if station_id == "workshop":
		start_cubesat_activity()
		return true
	if station_id == "lulu_nook":
		start_lulu_hunt()
		return true
	if station_id == "observatory":
		return start_observatory_activity()
	if station_id == "laboratory":
		var scene_result := get_tree().change_scene_to_file("res://scenes/prototypes/mars_rover_survey.tscn")
		if scene_result != OK:
			push_warning("Unable to open the Mars rover survey prototype.")
			return false
		return true

	var station: Dictionary = STATION_DATA[station_id]
	_show_info_panel(
		str(station.get("title", "")),
		str(station.get("description", "")),
		str(station.get("hint", ""))
	)
	return true


func _build_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.018, 0.055)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.55, 0.82)
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key_light.light_energy = 1.1
	key_light.shadow_enabled = false
	add_child(key_light)

	var floor_body := StaticBody3D.new()
	floor_body.name = "HubFloorCollision"
	floor_body.position = Vector3(0.0, -0.16, 0.0)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(22.0, 0.3, 14.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(22.0, 14.0)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.015
	floor_mesh.material_override = _make_material(Color(0.025, 0.065, 0.12), Color(0.02, 0.11, 0.18), 0.25)
	add_child(floor_mesh)

	# A light, procedural navigation grid keeps the graybox readable on mobile.
	for index in range(-10, 11):
		_add_box(
			"GridX_%d" % index,
			Vector3(float(index), 0.006, 0.0),
			Vector3(0.012, 0.008, 13.6),
			Color(0.08, 0.19, 0.26)
		)
	for index in range(-6, 7):
		_add_box(
			"GridZ_%d" % index,
			Vector3(0.0, 0.007, float(index)),
			Vector3(21.5, 0.008, 0.012),
			Color(0.08, 0.19, 0.26)
		)

	# The walls are deliberately low and open so the child can read the whole hub.
	_add_box("RearWall", Vector3(0.0, 1.4, -7.0), Vector3(22.0, 2.8, 0.25), Color(0.035, 0.09, 0.16))
	_add_box("LeftWall", Vector3(-11.0, 1.4, 0.0), Vector3(0.25, 2.8, 14.0), Color(0.035, 0.09, 0.16))
	_add_box("RightWall", Vector3(11.0, 1.4, 0.0), Vector3(0.25, 2.8, 14.0), Color(0.035, 0.09, 0.16))
	_add_box("FrontRail", Vector3(0.0, 0.55, 7.0), Vector3(22.0, 1.1, 0.18), Color(0.035, 0.09, 0.16))

	# Windows and a small star field are authored as low-cost primitives.
	for window_index in range(5):
		var window_x := -8.0 + float(window_index) * 4.0
		_add_box(
			"Window_%d" % window_index,
			Vector3(window_x, 1.8, -6.82),
			Vector3(2.7, 1.4, 0.04),
			Color(0.025, 0.16, 0.29),
			Color(0.04, 0.34, 0.52)
		)
	_add_star_field()

	_create_station("bridge", Vector3(0.0, 0.0, -0.5), Color(0.20, 0.72, 0.96))
	_create_station("workshop", Vector3(-7.0, 0.0, -3.5), Color(1.0, 0.62, 0.24))
	_create_station("laboratory", Vector3(-3.3, 0.0, -4.8), Color(0.38, 0.88, 0.74))
	_create_station("observatory", Vector3(4.0, 0.0, -4.8), Color(0.63, 0.62, 1.0))
	_create_station("lulu_nook", Vector3(8.0, 0.0, -2.5), Color(0.94, 0.72, 0.42))
	_build_lulu_secret_stars()


func _place_reusable_prop(
	parent: Node3D,
	prop_id: String,
	asset_id: String,
	local_position: Vector3,
	uniform_scale: float,
	rotation_y_degrees: float = 0.0
) -> bool:
	var model_path := str(KAYKIT_ASSET_PATHS.get(asset_id, ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return false
	var packed_scene := ResourceLoader.load(model_path) as PackedScene
	if packed_scene == null:
		push_warning("Pinned KayKit model could not be loaded: " + model_path)
		return false
	var instance := packed_scene.instantiate() as Node3D
	if instance == null:
		push_warning("Pinned KayKit model root is not Node3D: " + model_path)
		return false
	instance.name = "Reused_" + prop_id
	instance.position = local_position
	instance.scale = Vector3.ONE * uniform_scale
	instance.rotation_degrees.y = rotation_y_degrees
	parent.add_child(instance)
	if not _loaded_reused_prop_ids.has(prop_id):
		_loaded_reused_prop_ids.append(prop_id)
	return true


func _build_lulu_secret_stars() -> void:
	_secret_star_nodes.clear()
	var found_ids: Array = _state.get("lulu_found_star_ids", [])
	for star_id in LULU_STAR_POSITIONS:
		if found_ids.has(star_id):
			continue
		var star := Node3D.new()
		star.name = str(star_id)
		star.position = LULU_STAR_POSITIONS[star_id]
		add_child(star)

		var core := MeshInstance3D.new()
		var core_mesh := SphereMesh.new()
		core_mesh.radius = 0.15
		core_mesh.height = 0.30
		core.mesh = core_mesh
		core.material_override = _make_material(Color(1.0, 0.84, 0.34), Color(0.92, 0.52, 0.10), 0.2)
		star.add_child(core)

		var vertical_ray := MeshInstance3D.new()
		var vertical_mesh := BoxMesh.new()
		vertical_mesh.size = Vector3(0.055, 0.48, 0.055)
		vertical_ray.mesh = vertical_mesh
		vertical_ray.material_override = _make_material(Color(1.0, 0.94, 0.67), Color(0.96, 0.70, 0.18), 0.25)
		star.add_child(vertical_ray)

		var horizontal_ray := MeshInstance3D.new()
		var horizontal_mesh := BoxMesh.new()
		horizontal_mesh.size = Vector3(0.48, 0.055, 0.055)
		horizontal_ray.mesh = horizontal_mesh
		horizontal_ray.material_override = vertical_ray.material_override
		star.add_child(horizontal_ray)

		var halo := MeshInstance3D.new()
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 0.22
		halo_mesh.outer_radius = 0.26
		halo.mesh = halo_mesh
		halo.rotation_degrees.x = 90.0
		halo.material_override = _make_material(Color(0.95, 0.70, 0.22), Color(0.90, 0.42, 0.08), 0.28)
		star.add_child(halo)

		_secret_star_nodes[star_id] = star


func _add_star_field() -> void:
	for index in range(26):
		var x := -9.5 + float((index * 7) % 19)
		var y := 1.1 + float((index * 3) % 3) * 0.38
		var star := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		star.mesh = sphere
		star.position = Vector3(x, y, -6.68)
		star.material_override = _make_material(Color(0.56, 0.82, 1.0), Color(0.25, 0.48, 0.8), 0.6)
		add_child(star)


func _create_station(station_id: String, station_position: Vector3, accent: Color) -> void:
	var station := Node3D.new()
	station.name = "Station_" + station_id
	station.position = station_position
	add_child(station)
	_stations[station_id] = station

	var base_mesh := MeshInstance3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 1.12
	base.bottom_radius = 1.28
	base.height = 0.22
	base.radial_segments = 28
	base_mesh.mesh = base
	base_mesh.position.y = 0.13
	base_mesh.material_override = _make_material(Color(0.045, 0.10, 0.17), accent, 0.28)
	station.add_child(base_mesh)

	_add_station_box(station, Vector3(0.0, 0.78, 0.0), Vector3(1.25, 1.05, 0.72), Color(0.055, 0.12, 0.19))
	_add_station_box(station, Vector3(0.0, 1.18, -0.39), Vector3(0.96, 0.62, 0.08), accent, accent)
	_add_station_box(station, Vector3(-0.62, 0.35, 0.30), Vector3(0.22, 0.50, 0.22), accent)
	_add_station_box(station, Vector3(0.62, 0.35, 0.30), Vector3(0.22, 0.50, 0.22), accent)

	var title_label := Label3D.new()
	title_label.text = str(STATION_DATA[station_id].get("title", station_id))
	title_label.position = Vector3(0.0, 2.1, 0.0)
	title_label.font = preload("res://assets/fonts/NotoSansArabic[wdth,wght].ttf")
	title_label.font_size = 38
	title_label.pixel_size = 0.006
	title_label.modulate = Color(0.91, 0.96, 1.0)
	title_label.text_direction = TextServer.DIRECTION_RTL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.outline_size = 6
	title_label.outline_modulate = Color(0.015, 0.035, 0.075, 0.95)
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(title_label)

	match station_id:
		"bridge":
			_add_planet_orbit_display(station, accent)
		"workshop":
			for tool_index in range(3):
				_add_station_box(
					station,
					Vector3(-0.62 + float(tool_index) * 0.62, 1.52, 0.52),
					Vector3(0.28, 0.18, 0.25),
					accent
				)
		"laboratory":
			_add_lab_glass(station, Vector3(-0.42, 1.55, 0.55), accent)
			_add_lab_glass(station, Vector3(0.42, 1.55, 0.55), Color(0.45, 0.78, 1.0))
		"observatory":
			_add_telescope(station, accent)
		"lulu_nook":
			_add_lulu_shell(station, accent)

	# Reuse the eight already-pinned CC0 KayKit models across the ship.
	# They are small exhibits/props; the existing procedural station geometry
	# continues to define navigation and acts as a safe fallback.
	match station_id:
		"bridge":
			_place_reusable_prop(station, "bridge_module", "basemodule_A", Vector3(0.0, 0.16, -1.12), 0.22)
			_place_reusable_prop(station, "bridge_relay_unit", "structure_low", Vector3(0.92, 0.10, -0.72), 0.28)
		"workshop":
			_place_reusable_prop(station, "workshop_rover", "spacetruck", Vector3(0.0, 0.18, -1.18), 0.30)
			_place_reusable_prop(station, "workshop_solar_panel", "solarpanel", Vector3(0.90, 0.12, 0.58), 0.28)
		"laboratory":
			_place_reusable_prop(station, "lab_lander", "lander_A", Vector3(-0.76, 0.12, -0.82), 0.25)
			_place_reusable_prop(station, "lab_sample_module", "basemodule_A", Vector3(0.82, 0.12, -0.82), 0.19)
		"observatory":
			_place_reusable_prop(station, "observatory_solar_array", "solarpanel", Vector3(0.82, 0.12, -0.62), 0.24)
			_place_reusable_prop(station, "observatory_rock_sample", "rocks_A", Vector3(-0.82, 0.10, -0.65), 0.26)
		"lulu_nook":
			_place_reusable_prop(station, "lulu_rock_garden_a", "rocks_A", Vector3(-0.62, 0.10, -0.62), 0.24)
			_place_reusable_prop(station, "lulu_rock_garden_b", "rocks_B", Vector3(0.62, 0.10, -0.62), 0.24)

	if station_id == "workshop" and is_cubesat_built():
		_add_cubesat_display()


func _add_cubesat_display() -> void:
	if _cubesat_display_added:
		return
	var station: Node3D = _stations.get("workshop")
	if not is_instance_valid(station):
		return
	var satellite := Node3D.new()
	satellite.name = "CompletedCubeSatDisplay"
	satellite.position = Vector3(0.0, 1.55, -0.62)
	station.add_child(satellite)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.46, 0.46, 0.46)
	body.mesh = body_mesh
	body.material_override = _make_material(Color(0.72, 0.78, 0.84), Color(0.24, 0.42, 0.56), 0.28)
	satellite.add_child(body)

	for side in [-1.0, 1.0]:
		var panel := MeshInstance3D.new()
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(0.55, 0.035, 0.38)
		panel.mesh = panel_mesh
		panel.position = Vector3(side * 0.5, 0.0, 0.0)
		panel.material_override = _make_material(Color(0.10, 0.24, 0.52), Color(0.10, 0.24, 0.52), 0.25)
		satellite.add_child(panel)

	var antenna := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.025
	antenna_mesh.bottom_radius = 0.025
	antenna_mesh.height = 0.42
	antenna.mesh = antenna_mesh
	antenna.position = Vector3(0.0, 0.36, 0.0)
	antenna.material_override = _make_material(Color(0.92, 0.74, 0.40), Color(0.65, 0.45, 0.18), 0.3)
	satellite.add_child(antenna)

	var camera_sensor := MeshInstance3D.new()
	var sensor_mesh := BoxMesh.new()
	sensor_mesh.size = Vector3(0.18, 0.16, 0.14)
	camera_sensor.mesh = sensor_mesh
	camera_sensor.position = Vector3(0.0, -0.10, 0.29)
	camera_sensor.material_override = _make_material(Color(0.12, 0.22, 0.32), Color(0.12, 0.30, 0.58), 0.2)
	satellite.add_child(camera_sensor)
	_cubesat_display_added = true


func _add_planet_orbit_display(station: Node3D, accent: Color) -> void:
	for index in range(3):
		var planet := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18 - float(index) * 0.025
		sphere.height = sphere.radius * 2.0
		planet.mesh = sphere
		planet.position = Vector3(-0.48 + float(index) * 0.48, 1.72, 0.55)
		var planet_color := accent if index == 0 else Color(0.94, 0.62, 0.34) if index == 1 else Color(0.38, 0.78, 0.64)
		planet.material_override = _make_material(planet_color, planet_color, 0.35)
		station.add_child(planet)


func _add_lab_glass(station: Node3D, local_position: Vector3, accent: Color) -> void:
	var vessel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.13
	cylinder.bottom_radius = 0.20
	cylinder.height = 0.48
	vessel.mesh = cylinder
	vessel.position = local_position
	vessel.material_override = _make_material(Color(0.45, 0.84, 0.95, 0.65), accent, 0.3)
	station.add_child(vessel)


func _add_telescope(station: Node3D, accent: Color) -> void:
	var telescope := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.12
	cylinder.bottom_radius = 0.16
	cylinder.height = 1.0
	telescope.mesh = cylinder
	telescope.position = Vector3(0.0, 1.46, 0.56)
	telescope.rotation_degrees.x = 65.0
	telescope.material_override = _make_material(Color(0.14, 0.20, 0.32), accent, 0.25)
	station.add_child(telescope)


func _add_lulu_shell(station: Node3D, accent: Color) -> void:
	var shell := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.40
	sphere.height = 0.8
	shell.mesh = sphere
	shell.position = Vector3(0.0, 1.34, 0.58)
	shell.scale = Vector3(1.0, 0.82, 0.68)
	shell.material_override = _make_material(Color(0.72, 0.45, 0.24), accent, 0.35)
	station.add_child(shell)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.19
	capsule.height = 0.66
	body.mesh = capsule
	body.position = Vector3(0.0, 0.96, 0.16)
	body.material_override = _make_material(Color(0.70, 0.79, 0.48), accent, 0.25)
	station.add_child(body)


func _add_station_box(
	station: Node3D,
	local_position: Vector3,
	size: Vector3,
	color: Color,
	emission_color: Color = Color(0.0, 0.0, 0.0)
) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = local_position
	mesh_instance.material_override = _make_material(color, emission_color, 0.22)
	station.add_child(mesh_instance)


func _add_box(
	node_name: String,
	world_position: Vector3,
	size: Vector3,
	color: Color,
	emission_color: Color = Color(0.0, 0.0, 0.0)
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = world_position
	mesh_instance.material_override = _make_material(color, emission_color, 0.2)
	add_child(mesh_instance)


func _make_material(color: Color, emission_color: Color, roughness: float = 0.5) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_color.a > 0.0 and emission_color != Color(0.0, 0.0, 0.0):
		material.emission_enabled = true
		material.emission = emission_color
	return material


func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.name = "PrototypeExplorer"
	_player.position = Vector3(0.0, 0.0, 5.4)

	var shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.28
	capsule_shape.height = 1.35
	shape.shape = capsule_shape
	shape.position.y = 0.76
	_player.add_child(shape)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 1.35
	body.mesh = capsule
	body.position.y = 0.76
	body.material_override = _make_material(Color(0.18, 0.60, 0.83), Color(0.16, 0.42, 0.72), 0.3)
	_player.add_child(body)

	var helmet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.30
	sphere.height = 0.60
	helmet.mesh = sphere
	helmet.position = Vector3(0.0, 1.48, 0.0)
	helmet.material_override = _make_material(Color(0.74, 0.88, 0.96), Color(0.22, 0.40, 0.58), 0.18)
	_player.add_child(helmet)
	add_child(_player)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "SanaHubCamera"
	_camera.current = true
	_camera.fov = 54.0
	add_child(_camera)
	_update_camera()


func _update_camera() -> void:
	if not is_instance_valid(_player):
		return
	_camera.global_position = _player.global_position + Vector3(0.0, 10.5, 10.0)
	_camera.look_at(_player.global_position + Vector3(0.0, 0.55, -0.6), Vector3.UP)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "SanaHubHUD"
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.theme = preload("res://themes/arabic_theme.tres")
	_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	var layer := CanvasLayer.new()
	layer.name = "SanaHubInterface"
	layer.layer = 20
	add_child(layer)
	layer.add_child(_hud)

	var header := PanelContainer.new()
	header.anchor_left = 0.025
	header.anchor_top = 0.025
	header.anchor_right = 0.52
	header.anchor_bottom = 0.21
	header.add_theme_stylebox_override("panel", _panel_style())
	_hud.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	header_content.add_theme_constant_override("separation", 2)
	header.add_child(header_content)

	var title := _new_label("سفينة سَنا", 25, Color(0.95, 0.98, 1.0), true)
	header_content.add_child(title)
	var subtitle := _new_label("تجوّل بين المحطات الخمس، واقترب من أي محطة لتتفاعل معها.", 15, Color(0.68, 0.82, 0.94))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_content.add_child(subtitle)
	var return_button := _new_button(
		"العودة إلى معرض التجارب",
		Callable(self, "_return_to_solar_system"),
		Vector2(0.0, 42.0)
	)
	return_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_content.add_child(return_button)

	var status_panel := PanelContainer.new()
	status_panel.anchor_left = 0.56
	status_panel.anchor_top = 0.025
	status_panel.anchor_right = 0.975
	status_panel.anchor_bottom = 0.13
	status_panel.add_theme_stylebox_override("panel", _panel_style())
	_hud.add_child(status_panel)
	_status_label = _new_label("", 15, Color(0.72, 0.91, 1.0), true)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_panel.add_child(_status_label)

	_nearby_label = _new_label("اقترب من محطة لعرض التفاعل", 16, Color(1.0, 0.82, 0.52), true)
	_nearby_label.anchor_left = 0.54
	_nearby_label.anchor_top = 0.15
	_nearby_label.anchor_right = 0.975
	_nearby_label.anchor_bottom = 0.22
	_nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(_nearby_label)

	_build_touch_controls()
	_update_status()


func _build_touch_controls() -> void:
	var dpad := PanelContainer.new()
	dpad.anchor_left = 0.025
	dpad.anchor_top = 0.66
	dpad.anchor_right = 0.22
	dpad.anchor_bottom = 0.975
	dpad.add_theme_stylebox_override("panel", _panel_style())
	_hud.add_child(dpad)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.add_theme_constant_override("margin_left", 6)
	grid.add_theme_constant_override("margin_top", 6)
	dpad.add_child(grid)

	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "↑", "up")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "←", "left")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "→", "right")
	_add_dpad_spacer(grid)
	_add_dpad_button(grid, "↓", "down")
	_add_dpad_spacer(grid)

	_interaction_button = _new_button("تفاعل", _on_interaction_button_pressed, Vector2(174.0, 66.0))
	_interaction_button.anchor_left = 0.80
	_interaction_button.anchor_top = 0.84
	_interaction_button.anchor_right = 0.975
	_interaction_button.anchor_bottom = 0.96
	_interaction_button.disabled = true
	_hud.add_child(_interaction_button)


func _add_dpad_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(52.0, 48.0)
	parent.add_child(spacer)


func _add_dpad_button(parent: GridContainer, caption: String, direction_key: String) -> void:
	var button := _new_button(caption, Callable(), Vector2(52.0, 48.0))
	button.button_up.connect(func() -> void: _touch_keys[direction_key] = false)
	button.button_down.connect(func() -> void: _touch_keys[direction_key] = true)
	parent.add_child(button)


func _new_button(caption: String, callback: Callable, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.15, 0.25), Color(0.20, 0.48, 0.68)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.22, 0.34), Color(0.38, 0.70, 0.88)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.30, 0.40), Color(0.45, 0.78, 0.92)))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _on_interaction_button_pressed() -> void:
	interact_with_nearest_station()


func _return_to_solar_system() -> void:
	get_tree().change_scene_to_file("res://scenes/prototypes/showcase_app.tscn")


func _update_nearby_station() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_interaction_button):
		return
	var closest_id := ""
	var closest_distance := INTERACTION_DISTANCE
	for station_id in STATION_IDS:
		var station: Node3D = _stations.get(station_id)
		if not is_instance_valid(station):
			continue
		var distance := _player.global_position.distance_to(station.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_id = station_id

	_nearby_station_id = closest_id
	_nearby_secret_star_id = ""
	var closest_star_distance := 1.45
	if _lulu_hunt_active:
		for star_id in _secret_star_nodes:
			var star: Node3D = _secret_star_nodes[star_id]
			if not is_instance_valid(star):
				continue
			var star_distance := _player.global_position.distance_to(star.global_position)
			if star_distance < closest_star_distance:
				closest_star_distance = star_distance
				_nearby_secret_star_id = str(star_id)

	_interaction_button.disabled = (_nearby_secret_star_id.is_empty() and closest_id.is_empty()) or _modal_active
	if not _nearby_secret_star_id.is_empty():
		_nearby_label.text = "وجدت نجمة مخفية! اضغط «اجمع النجمة»"
		_interaction_button.text = "اجمع النجمة"
	elif closest_id.is_empty():
		_nearby_label.text = "اقترب من محطة لعرض التفاعل"
		_interaction_button.text = "تفاعل"
	else:
		var station_data: Dictionary = STATION_DATA[closest_id]
		_nearby_label.text = str(station_data.get("title", "")) + " — " + str(station_data.get("hint", ""))
		_interaction_button.text = "تفاعل"


func _show_info_panel(title_text: String, body_text: String, hint_text: String) -> void:
	_open_modal(title_text)
	var body := _new_label(body_text, 19, Color(0.82, 0.90, 0.97))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0.0, 104.0)
	_modal_content.add_child(body)

	var hint := _new_label(hint_text, 16, Color(0.42, 0.82, 0.94), true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(hint)
	_add_close_button()


func _show_observatory_panel() -> void:
	_open_modal("مرصد ريم — ألبوم الصور")
	_observatory_active = true
	var introduction := _new_label(
		"وجّه عدسة المرصد إلى جرم من القائمة، ثم احفظ لقطة رصد مرسومة داخل اللعبة. يمكنك العودة وإكمال الألبوم لاحقاً.",
		17,
		Color(0.82, 0.90, 0.97)
	)
	introduction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(introduction)

	_observatory_progress_label = _new_label("", 17, Color(1.0, 0.79, 0.42), true)
	_observatory_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_modal_content.add_child(_observatory_progress_label)

	_observatory_feedback_label = _new_label(_observatory_feedback, 15, Color(0.48, 0.85, 0.94))
	_observatory_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_observatory_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_observatory_feedback_label.custom_minimum_size = Vector2(0.0, 46.0)
	_modal_content.add_child(_observatory_feedback_label)

	_observatory_preview = TextureRect.new()
	_observatory_preview.custom_minimum_size = Vector2(0.0, 172.0)
	_observatory_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_observatory_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_modal_content.add_child(_observatory_preview)

	_observatory_buttons.clear()
	for target_id in OBSERVATORY_TARGET_IDS:
		var selected_id := str(target_id)
		var target_title := str(OBSERVATORY_TARGETS[selected_id]["title"])
		var button := _new_button(
			"التقط صورة: " + target_title,
			func() -> void: capture_observation(selected_id),
			Vector2(0.0, 48.0)
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_modal_content.add_child(button)
		_observatory_buttons.append(button)

	_add_close_button()
	_refresh_observatory_panel()


func _refresh_observatory_panel() -> void:
	if not is_instance_valid(_observatory_progress_label) or not is_instance_valid(_observatory_feedback_label):
		return
	var progress := get_observatory_progress()
	_observatory_progress_label.text = "صور الألبوم: %d / %d" % [progress, OBSERVATORY_TARGET_IDS.size()]
	if is_observatory_complete():
		_observatory_progress_label.text = "اكتمل ألبوم المرصد!"
		_observatory_feedback_label.text = "أحسنت! أصبحت الصور الثلاث محفوظة في دفتر اكتشافات ريم."
	else:
		_observatory_feedback_label.text = _observatory_feedback
	var photo_ids := get_observatory_photo_ids()
	for index in range(_observatory_buttons.size()):
		var target_id := OBSERVATORY_TARGET_IDS[index]
		_observatory_buttons[index].disabled = photo_ids.has(target_id)

	if is_instance_valid(_observatory_preview):
		_observatory_preview.texture = null
		if not photo_ids.is_empty():
			var photo_path := get_observatory_photo_path(str(photo_ids[photo_ids.size() - 1]))
			if FileAccess.file_exists(photo_path):
				var photo_image := Image.load_from_file(photo_path)
				if photo_image != null and not photo_image.is_empty():
					_observatory_preview.texture = ImageTexture.create_from_image(photo_image)


func _save_observatory_thumbnail(target_id: String) -> bool:
	if not OBSERVATORY_TARGETS.has(target_id):
		return false
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ALBUM_DIR))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return false
	var image := _render_observatory_thumbnail(target_id)
	if image == null or image.is_empty():
		return false
	return image.save_png(ProjectSettings.globalize_path(get_observatory_photo_path(target_id))) == OK


func _render_observatory_thumbnail(target_id: String) -> Image:
	const IMAGE_SIZE := 256
	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	var target: Dictionary = OBSERVATORY_TARGETS[target_id]
	var base_color: Color = target["base_color"]
	var target_seed := OBSERVATORY_TARGET_IDS.find(target_id) + 1
	var moon_craters := [
		Vector3(-0.42, -0.18, 0.15),
		Vector3(0.31, -0.36, 0.12),
		Vector3(0.16, 0.34, 0.10),
		Vector3(-0.10, 0.06, 0.08)
	]
	for y in range(IMAGE_SIZE):
		for x in range(IMAGE_SIZE):
			var nx := (float(x) - 128.0) / 82.0
			var ny := (float(y) - 128.0) / 82.0
			var radius_squared := nx * nx + ny * ny
			var pixel_color := Color(0.012, 0.025, 0.075)
			var star_hash := (x * 73 + y * 151 + x * y * 7 + target_seed * 31) % 997
			if star_hash < 5:
				pixel_color = Color(0.68, 0.84, 1.0)
			if target_id == "saturn":
				var ring_radius := sqrt(nx * nx + (ny / 0.36) * (ny / 0.36))
				if ring_radius > 0.94 and ring_radius < 1.62:
					var band := sin(ring_radius * 58.0) * 0.045
					pixel_color = Color(0.77 + band, 0.62 + band, 0.38 + band)
			if radius_squared <= 1.0:
				var light_depth := sqrt(maxf(0.0, 1.0 - radius_squared))
				var light_amount := clampf(0.40 - nx * 0.24 - ny * 0.30 + light_depth * 0.62, 0.12, 1.0)
				var surface_noise := sin(nx * 19.0 + float(target_seed)) * cos(ny * 23.0) * 0.035
				var shade := clampf(light_amount + surface_noise, 0.08, 1.0)
				pixel_color = Color(base_color.r * shade, base_color.g * shade, base_color.b * shade)
				if target_id == "moon":
					for crater in moon_craters:
						var crater_distance := Vector2(nx - crater.x, ny - crater.y).length()
						if crater_distance < crater.z:
							var crater_shade := 0.72 + crater_distance * 0.9
							pixel_color = Color(pixel_color.r * crater_shade, pixel_color.g * crater_shade, pixel_color.b * crater_shade)
				elif target_id == "mars":
					var ridge := sin(nx * 13.0 + ny * 5.0) * cos(ny * 17.0) * 0.10
					pixel_color = Color(
						clampf(pixel_color.r + ridge, 0.0, 1.0),
						clampf(pixel_color.g + ridge * 0.30, 0.0, 1.0),
						clampf(pixel_color.b + ridge * 0.14, 0.0, 1.0)
					)
			image.set_pixel(x, y, pixel_color)
	return image


func _show_relay_panel() -> void:
	_open_modal("لعبة رسالة مرقاب")
	_modal_active = true
	var introduction := _new_label(
		"رتّب محطات الاتصال حتى تصل رسالة الرحلة إلى الروفر. لا توجد عقوبة على المحاولة؛ جرّب وتعلّم.",
		18,
		Color(0.82, 0.90, 0.97)
	)
	introduction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(introduction)

	_relay_progress_label = _new_label("", 17, Color(1.0, 0.79, 0.42), true)
	_relay_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_modal_content.add_child(_relay_progress_label)

	_relay_feedback_label = _new_label("", 16, Color(0.48, 0.85, 0.94))
	_relay_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_relay_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_relay_feedback_label.custom_minimum_size = Vector2(0.0, 48.0)
	_modal_content.add_child(_relay_feedback_label)

	_relay_buttons.clear()
	for relay_id in ["moon_relay", "sana_station", "mars_rover"]:
		var button := _new_button(
			str(RELAY_LABELS[relay_id]),
			func() -> void: submit_relay_node(relay_id),
			Vector2(0.0, 56.0)
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_modal_content.add_child(button)
		_relay_buttons.append(button)

	_add_close_button()
	_refresh_relay_panel()


func _refresh_relay_panel() -> void:
	if not is_instance_valid(_relay_progress_label) or not is_instance_valid(_relay_feedback_label):
		return
	_relay_progress_label.text = "المحطة %d من %d" % [mini(_relay_progress + 1, RELAY_SEQUENCE.size()), RELAY_SEQUENCE.size()]
	_relay_feedback_label.text = _relay_feedback
	var finished := _relay_progress >= RELAY_SEQUENCE.size()
	if finished:
		_relay_progress_label.text = "اكتملت الرسالة"
	for button in _relay_buttons:
		button.disabled = finished


func _show_lulu_hunt_panel() -> void:
	_open_modal("أسرار لولو")
	var intro := _new_label(
		"لولو أخفى خمس نجوم صغيرة في السفينة! تجوّل وابحث عن لمعانها. اقترب من النجمة واضغط «اجمع النجمة».",
		18,
		Color(0.82, 0.90, 0.97)
	)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(intro)

	_lulu_hunt_feedback_label = _new_label("", 16, Color(1.0, 0.82, 0.42), true)
	_lulu_hunt_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lulu_hunt_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(_lulu_hunt_feedback_label)
	_refresh_lulu_hunt_panel()
	_add_close_button()


func _refresh_lulu_hunt_panel() -> void:
	if not is_instance_valid(_lulu_hunt_feedback_label):
		return
	var found_ids: Array = _state.get("lulu_found_star_ids", [])
	var count: int = found_ids.size()
	_lulu_hunt_feedback_label.text = "النجوم التي وجدتها: %d / %d" % [count, LULU_STAR_POSITIONS.size()]


func _show_cubesat_panel() -> void:
	_open_modal("ورشة القمر المصغّر")
	_modal_active = true
	var introduction := _new_label(
		"ساعد سليم في بناء قمر مصغّر. أضف الهيكل، ثم ألواح الطاقة، فالهوائي، وأخيراً كاميرا الملاحظة.",
		18,
		Color(0.82, 0.90, 0.97)
	)
	introduction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_content.add_child(introduction)

	_cubesat_progress_label = _new_label("", 17, Color(1.0, 0.79, 0.42), true)
	_cubesat_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_modal_content.add_child(_cubesat_progress_label)

	_cubesat_feedback_label = _new_label("", 16, Color(0.48, 0.85, 0.94))
	_cubesat_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cubesat_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cubesat_feedback_label.custom_minimum_size = Vector2(0.0, 48.0)
	_modal_content.add_child(_cubesat_feedback_label)

	_cubesat_buttons.clear()
	for part_id in CUBESAT_SEQUENCE:
		var button := _new_button(
			str(CUBESAT_LABELS[part_id]),
			func() -> void: select_cubesat_part(part_id),
			Vector2(0.0, 54.0)
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_modal_content.add_child(button)
		_cubesat_buttons.append(button)

	var lunar_builder_button := _new_button(
		"بناء القاعدة القمرية",
		Callable(self, "start_lunar_outpost_activity"),
		Vector2(0.0, 54.0)
	)
	lunar_builder_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(lunar_builder_button)

	_add_close_button()
	_refresh_cubesat_panel()


func _refresh_cubesat_panel() -> void:
	if not is_instance_valid(_cubesat_progress_label) or not is_instance_valid(_cubesat_feedback_label):
		return
	var progress := get_cubesat_progress()
	if is_cubesat_built():
		_cubesat_progress_label.text = "اكتمل القمر المصغّر!"
		_cubesat_feedback_label.text = "رائع! أصبح القمر جاهزاً للعرض في ورشة سليم."
	else:
		_cubesat_progress_label.text = "الوحدات المركّبة: %d / %d" % [progress, CUBESAT_SEQUENCE.size()]
		_cubesat_feedback_label.text = "الوحدة التالية: " + str(CUBESAT_LABELS[CUBESAT_SEQUENCE[progress]])
	for index in range(_cubesat_buttons.size()):
		_cubesat_buttons[index].disabled = index < progress or is_cubesat_built()


func _open_modal(title_text: String) -> void:
	_close_modal()
	_modal_active = true
	_modal_panel = PanelContainer.new()
	_modal_panel.anchor_left = 0.18
	_modal_panel.anchor_top = 0.17
	_modal_panel.anchor_right = 0.82
	_modal_panel.anchor_bottom = 0.83
	_modal_panel.add_theme_stylebox_override("panel", _panel_style())
	_hud.add_child(_modal_panel)

	_modal_content = VBoxContainer.new()
	_modal_content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_modal_content.add_theme_constant_override("separation", 10)
	_modal_panel.add_child(_modal_content)

	var title := _new_label(title_text, 24, Color(0.95, 0.98, 1.0), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_modal_content.add_child(title)


func _add_close_button() -> void:
	var close_button := _new_button("العودة إلى السفينة", func() -> void: _close_modal(), Vector2(0.0, 50.0))
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(close_button)


func _close_modal() -> void:
	_modal_active = false
	_observatory_active = false
	_touch_keys = {"up": false, "down": false, "left": false, "right": false}
	_lulu_hunt_feedback_label = null
	_observatory_progress_label = null
	_observatory_feedback_label = null
	_observatory_preview = null
	_observatory_buttons.clear()
	_relay_buttons.clear()
	_relay_progress_label = null
	_relay_feedback_label = null
	_cubesat_buttons.clear()
	_cubesat_progress_label = null
	_cubesat_feedback_label = null
	if is_instance_valid(_modal_panel):
		_modal_panel.queue_free()
	_modal_panel = null


func _update_status() -> void:
	if not is_instance_valid(_status_label):
		return
	var visited_stations: Array = _state.get("visited_station_ids", [])
	var visited_count: int = visited_stations.size()
	var lulu_found_ids: Array = _state.get("lulu_found_star_ids", [])
	var lulu_found_count: int = lulu_found_ids.size()
	var relay_text := "رسالة مرقاب: مكتملة" if is_relay_completed() else "رسالة مرقاب: بانتظار التوصيل"
	var cubesat_text := "القمر المصغّر: جاهز" if is_cubesat_built() else "القمر المصغّر: قيد البناء"
	var lulu_text := "نجوم لولو: %d / %d" % [lulu_found_count, LULU_STAR_POSITIONS.size()]
	var photo_text := "صور ريم: %d / %d" % [get_observatory_progress(), OBSERVATORY_TARGET_IDS.size()]
	_status_label.text = "المحطات: %d / %d • %s • %s • %s • %s" % [
		visited_count,
		STATION_IDS.size(),
		relay_text,
		cubesat_text,
		photo_text,
		lulu_text
	]


func _publish_gameplay_event(event_id: String, payload: Dictionary) -> void:
	if not _gameplay_bridge_ready or _interaction_router == null:
		return
	_interaction_router.publish(event_id, payload)


func _on_interaction_received(event_id: String, _payload: Dictionary) -> void:
	if _gameplay_runtime == null:
		return
	if _gameplay_runtime.get_active_mission_id().is_empty():
		return
	var result: Dictionary = _gameplay_runtime.record_event(event_id)
	if bool(result.get("accepted", false)) and bool(result.get("persisted", false)):
		_update_status()


func _setup_gameplay_bridge() -> void:
	if not enable_gameplay_bridge:
		return

	var bundle: Dictionary = ContentRegistry.load_bundle()
	var content_errors: Array[String] = ContentRegistry.validate_bundle(bundle)
	if not content_errors.is_empty():
		push_warning("Sana Hub content bridge skipped: " + "; ".join(content_errors))
		return

	_interaction_router = InteractionRouter.new()
	var router_errors: Array[String] = _interaction_router.configure(bundle)
	if not router_errors.is_empty():
		push_warning("Sana Hub interaction router skipped: " + "; ".join(router_errors))
		_interaction_router = null
		return

	_gameplay_runtime = GameplayRuntime.new()
	var runtime_errors: Array[String] = _gameplay_runtime.initialize()
	if not runtime_errors.is_empty():
		push_warning("Sana Hub gameplay bridge skipped: " + "; ".join(runtime_errors))
		_gameplay_runtime = null
		_interaction_router = null
		return

	_interaction_router.interaction_received.connect(_on_interaction_received)
	_gameplay_bridge_ready = true

	# Offer the prologue only when the player has no other active mission.
	# An existing active mission is never replaced by opening this prototype.
	if _gameplay_runtime.get_active_mission_id().is_empty():
		if not _gameplay_runtime.is_mission_completed("mission.prologue.signal"):
			_gameplay_runtime.start_mission("mission.prologue.signal")


func _load_state() -> Dictionary:
	var defaults := {
		"version": SAVE_VERSION,
		"visited_station_ids": [],
		"relay_progress": 0,
		"relay_activity_completed": false,
		"cubesat_step": 0,
		"cubesat_built": false,
		"lulu_found_star_ids": [],
		"lulu_hunt_completed": false,
		"observatory_photo_ids": []
	}
	if not FileAccess.file_exists(SAVE_PATH):
		return defaults

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return defaults
	var stored_version := int(parsed.get("version", 0))
	if stored_version < 1 or stored_version > SAVE_VERSION:
		return defaults

	# Version 1 saves predate the observatory album. Preserve existing progress.
	var result: Dictionary = defaults.duplicate(true)
	var raw_visited: Variant = parsed.get("visited_station_ids", [])
	if raw_visited is Array:
		for station_id in raw_visited:
			if STATION_IDS.has(str(station_id)) and not result["visited_station_ids"].has(str(station_id)):
				result["visited_station_ids"].append(str(station_id))
	result["relay_progress"] = clampi(int(parsed.get("relay_progress", 0)), 0, RELAY_SEQUENCE.size())
	result["relay_activity_completed"] = result["relay_progress"] == RELAY_SEQUENCE.size() or bool(parsed.get("relay_activity_completed", false))
	if result["relay_activity_completed"]:
		result["relay_progress"] = RELAY_SEQUENCE.size()
	result["cubesat_step"] = clampi(int(parsed.get("cubesat_step", 0)), 0, CUBESAT_SEQUENCE.size())
	result["cubesat_built"] = result["cubesat_step"] == CUBESAT_SEQUENCE.size()
	var raw_lulu_stars: Variant = parsed.get("lulu_found_star_ids", [])
	if raw_lulu_stars is Array:
		for star_id in raw_lulu_stars:
			if LULU_STAR_POSITIONS.has(str(star_id)) and not result["lulu_found_star_ids"].has(str(star_id)):
				result["lulu_found_star_ids"].append(str(star_id))
	result["lulu_hunt_completed"] = result["lulu_found_star_ids"].size() == LULU_STAR_POSITIONS.size()
	var raw_observatory_photos: Variant = parsed.get("observatory_photo_ids", [])
	if raw_observatory_photos is Array:
		for target_id in raw_observatory_photos:
			var normalized_id := str(target_id)
			if OBSERVATORY_TARGETS.has(normalized_id) and not result["observatory_photo_ids"].has(normalized_id):
				result["observatory_photo_ids"].append(normalized_id)
	return result


func _save_state() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save the Sana Hub prototype progress.")
		return false
	file.store_string(JSON.stringify(_state))
	file.close()
	_update_status()
	return true


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.045, 0.09, 0.97)
	style.border_color = Color(0.18, 0.48, 0.68, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _new_label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.text_direction = Control.TEXT_DIRECTION_AUTO
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.8))
		label.add_theme_constant_override("outline_size", 1)
	return label
