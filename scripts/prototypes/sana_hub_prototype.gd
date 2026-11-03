extends Node3D
## Standalone, offline-first graybox for the first playable ship hub.
## The solar-system main scene is intentionally left untouched.

const ContentRegistry = preload("res://scripts/content_registry.gd")
const GameplayRuntime = preload("res://scripts/gameplay_runtime.gd")
const InteractionRouter = preload("res://scripts/interaction_router.gd")

const SAVE_PATH := "user://sana_hub_prototype.json"
const SAVE_VERSION := 1
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
		"hint": "نفحص العينات ونرتب الأدلة.",
		"description": "الملاحظة ليست هي الاستنتاج. في المختبر نسجل ما رأيناه، ثم نبحث عما يمكن أن يعنيه."
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

var _stations: Dictionary = {}
var _touch_keys: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}
var _nearby_station_id := ""
var _relay_active := false
var _relay_progress := 0
var _relay_feedback := ""
var _state: Dictionary = {}

var _interaction_router
var _gameplay_runtime
var _gameplay_bridge_ready := false


func _ready() -> void:
	_state = _load_state()
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
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			interact_with_nearest_station()
		elif event.keycode == KEY_ESCAPE and is_instance_valid(_modal_panel):
			_close_modal()


# Public surface used by the headless acceptance test and future UI integration.
func get_station_ids() -> PackedStringArray:
	return PackedStringArray(STATION_IDS)


func get_visited_station_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for station_id in _state.get("visited_station_ids", []):
		result.append(str(station_id))
	return result


func get_relay_progress() -> int:
	return _relay_progress


func is_relay_completed() -> bool:
	return bool(_state.get("relay_activity_completed", false))


func is_gameplay_bridge_ready() -> bool:
	return _gameplay_bridge_ready


func start_relay_activity() -> bool:
	_relay_progress = 0
	_relay_feedback = "ابدأ من قمر الاتصال، ثم محطة سَنا، ثم مركبة الروفر."
	_show_relay_panel()
	return true


func submit_relay_node(relay_id: String) -> bool:
	if not _relay_active or _relay_progress >= RELAY_SEQUENCE.size():
		return false

	var expected_id: String = RELAY_SEQUENCE[_relay_progress]
	if relay_id != expected_id:
		_relay_feedback = "ليست هذه المحطة التالية. اتبع مسار الرسالة من المصدر إلى الوجهة."
		_refresh_relay_panel()
		return false

	_relay_progress += 1
	if _relay_progress >= RELAY_SEQUENCE.size():
		_state["relay_activity_completed"] = true
		_save_state()
		_relay_feedback = "وصلت الرسالة إلى الروفر! أحسنت تنظيم مسار الاتصال."
		_publish_gameplay_event("signal.interacted", {"activity_id": "activity.relay_message"})
	else:
		_relay_feedback = "ممتاز! انتقلت الرسالة إلى المحطة التالية."
	_refresh_relay_panel()
	return true


func interact_with_nearest_station() -> bool:
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
	title_label.font_size = 38
	title_label.pixel_size = 0.006
	title_label.modulate = Color(0.91, 0.96, 1.0)
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
	header.anchor_bottom = 0.18
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
	_interaction_button.disabled = closest_id.is_empty() or _relay_active
	if closest_id.is_empty():
		_nearby_label.text = "اقترب من محطة لعرض التفاعل"
	else:
		var station_data: Dictionary = STATION_DATA[closest_id]
		_nearby_label.text = str(station_data.get("title", "")) + " — " + str(station_data.get("hint", ""))


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


func _show_relay_panel() -> void:
	_open_modal("لعبة رسالة مرقاب")
	_relay_active = true
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


func _open_modal(title_text: String) -> void:
	_close_modal()
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
	_relay_active = false
	_relay_buttons.clear()
	_relay_progress_label = null
	_relay_feedback_label = null
	if is_instance_valid(_modal_panel):
		_modal_panel.queue_free()
	_modal_panel = null


func _update_status() -> void:
	if not is_instance_valid(_status_label):
		return
	var visited_count := _state.get("visited_station_ids", []).size()
	var relay_text := "رسالة مرقاب: مكتملة" if is_relay_completed() else "رسالة مرقاب: بانتظار التوصيل"
	_status_label.text = "المحطات المستكشفة: %d / %d   •   %s" % [
		visited_count,
		STATION_IDS.size(),
		relay_text
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
		"relay_activity_completed": false
	}
	if not FileAccess.file_exists(SAVE_PATH):
		return defaults

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or int(parsed.get("version", 0)) != SAVE_VERSION:
		return defaults

	var result: Dictionary = defaults.duplicate(true)
	var raw_visited: Variant = parsed.get("visited_station_ids", [])
	if raw_visited is Array:
		for station_id in raw_visited:
			if STATION_IDS.has(str(station_id)) and not result["visited_station_ids"].has(str(station_id)):
				result["visited_station_ids"].append(str(station_id))
	result["relay_activity_completed"] = bool(parsed.get("relay_activity_completed", false))
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
