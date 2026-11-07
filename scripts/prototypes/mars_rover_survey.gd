extends Node3D

signal site_scanned(site_id: String)
## Child-friendly Mars surface survey prototype.
## Uses a small, pinned CC0 asset subset when staged by CI; procedural fallbacks
## keep the scene runnable in a source checkout without the optional asset pack.

const SAVE_PATH := "user://mars_rover_survey_prototype.json"
const MarsLandscapeBuilder = preload("res://scripts/prototypes/mars_landscape_builder.gd")
const SAVE_VERSION := 1
const MOVE_SPEED := 3.4
const SCAN_DISTANCE := 2.45
const ASSET_ROOT := "res://assets/vendor/kaykit_space_base_bits"

@export var persistence_enabled := true
@export var allow_return_to_sana := true
@export var create_local_world_environment := true
@export var embedded_found_site_ids := PackedStringArray()

const ASSET_PATHS := {
	"basemodule_A": ASSET_ROOT + "/basemodule_A.gltf",
	"lander_A": ASSET_ROOT + "/lander_A.gltf",
	"landingpad_small": ASSET_ROOT + "/landingpad_small.gltf",
	"rocks_A": ASSET_ROOT + "/rocks_A.gltf",
	"rocks_B": ASSET_ROOT + "/rocks_B.gltf",
	"solarpanel": ASSET_ROOT + "/solarpanel.gltf",
	"spacetruck": ASSET_ROOT + "/spacetruck.gltf",
	"structure_low": ASSET_ROOT + "/structure_low.gltf"
}

const SURVEY_SITES := {
	"layered_rock": {
		"title": "الصخرة ذات الطبقات",
		"hint": "اقترب من العلامة الذهبية ثم افحص شكل الطبقات.",
		"observation": "سجّلنا اختلافاً واضحاً بين طبقات الصخرة. الصورة وحدها لا تكفي لتحديد سبب تكوّنها.",
		"position": Vector3(-5.2, 0.0, 0.2),
		"accent": Color(0.93, 0.62, 0.34)
	},
	"sand_ripples": {
		"title": "تموّجات الرمال",
		"hint": "اقترب من العلامة الزرقاء وافحص اتجاه الخطوط.",
		"observation": "سجّلنا نمطاً متكرراً على السطح. سنقارن اتجاه الخطوط بملاحظات مواقع أخرى قبل الاستنتاج.",
		"position": Vector3(3.2, 0.0, -2.7),
		"accent": Color(0.34, 0.78, 0.94)
	},
	"crater_rim": {
		"title": "حافة الفوّهة",
		"hint": "اقترب من العلامة البنفسجية وافحص شكل الحافة.",
		"observation": "وثّقنا شكل الحافة من زاوية واحدة. نحتاج صوراً إضافية قبل تحديد كيفية تشكّلها.",
		"position": Vector3(6.2, 0.0, 4.8),
		"accent": Color(0.70, 0.62, 0.96)
	}
}

var _state: Dictionary = {}
var _rover: CharacterBody3D
var _camera: Camera3D
var _status_label: Label
var _nearby_label: Label
var _scan_button: Button
var _feedback_label: Label
var _touch := {"up": false, "down": false, "left": false, "right": false}
var _nearby_site_id := ""
var _loaded_assets: Dictionary = {}


func _ready() -> void:
	_state = _load_state() if persistence_enabled else {"version": SAVE_VERSION, "found_site_ids": Array(embedded_found_site_ids)}
	_build_environment()
	_build_outpost()
	_build_survey_sites()
	_build_rover()
	_build_camera()
	_build_hud()
	_update_nearby_site()
	_update_status()


func _process(delta: float) -> void:
	if is_instance_valid(_rover) and is_instance_valid(_camera):
		_update_camera(delta)
		_update_nearby_site()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_rover):
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

	if bool(_touch.get("left", false)):
		horizontal -= 1.0
	if bool(_touch.get("right", false)):
		horizontal += 1.0
	if bool(_touch.get("up", false)):
		vertical -= 1.0
	if bool(_touch.get("down", false)):
		vertical += 1.0

	var direction := Vector3(horizontal, 0.0, vertical)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var target_velocity := Vector3(direction.x * MOVE_SPEED, 0.0, direction.z * MOVE_SPEED)
	_rover.velocity = _rover.velocity.move_toward(target_velocity,10.5*delta)
	_rover.move_and_slide()
	_rover.global_position.x = clampf(_rover.global_position.x, -11.0, 11.0)
	_rover.global_position.z = clampf(_rover.global_position.z, -8.0, 8.0)
	if direction.length_squared() > 0.01:
		_rover.rotation.y = atan2(direction.x, direction.z)


func get_site_ids() -> PackedStringArray:
	return PackedStringArray(SURVEY_SITES.keys())


func get_found_site_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for site_id in _state.get("found_site_ids", []):
		result.append(str(site_id))
	return result


func get_scan_progress() -> int:
	return get_found_site_ids().size()


func is_survey_completed() -> bool:
	return get_scan_progress() == SURVEY_SITES.size()


func get_rover() -> CharacterBody3D:
	return _rover


func get_site_position(site_id: String) -> Vector3:
	if not SURVEY_SITES.has(site_id):
		return Vector3.ZERO
	return SURVEY_SITES[site_id]["position"]


func get_loaded_asset_ids() -> PackedStringArray:
	return PackedStringArray(_loaded_assets.keys())


func scan_site(site_id: String) -> bool:
	if not SURVEY_SITES.has(site_id) or not is_instance_valid(_rover):
		return false

	var site: Dictionary = SURVEY_SITES[site_id]
	var site_position: Vector3 = site["position"]
	var rover_flat := Vector3(_rover.global_position.x, 0.0, _rover.global_position.z)
	if rover_flat.distance_to(site_position) > SCAN_DISTANCE:
		_feedback_label.text = "اقترب أكثر من موقع الملاحظة حتى يعمل الماسح."
		return false

	var found: Array = _state.get("found_site_ids", [])
	if found.has(site_id):
		_feedback_label.text = "هذا الموقع موجود بالفعل في سجل الرحلة."
		return false

	found.append(site_id)
	_state["found_site_ids"] = found
	if persistence_enabled and not _save_state():
		found.erase(site_id)
		_state["found_site_ids"] = found
		_feedback_label.text = "تعذّر حفظ الملاحظة. لم نحتسبها، ويمكنك المحاولة مجدداً."
		_update_status()
		return false

	site_scanned.emit(site_id)
	_feedback_label.text = str(site["observation"])
	if is_survey_completed():
		_feedback_label.text += "\nاكتملت المواقع الثلاثة! يمكنك العودة إلى سفينة سَنا وعرض سجل الملاحظات."
	return true


func scan_nearby_site() -> bool:
	if _nearby_site_id.is_empty():
		_feedback_label.text = "اقترب من إحدى العلامات حتى تتمكن من الفحص."
		return false
	return scan_site(_nearby_site_id)


func _build_environment() -> void:
	if create_local_world_environment:
		var world := WorldEnvironment.new()
		var environment := Environment.new()
		MarsLandscapeBuilder.configure_atmosphere(environment)
		world.environment = environment
		add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sunlight.light_energy = 1.05
	sunlight.shadow_enabled = false
	add_child(sunlight)

	MarsLandscapeBuilder.populate(self, "rover")


func _build_outpost() -> void:
	_place_kit_asset("landingpad_small", Vector3(-7.0, 0.02, -5.2), 2.6)
	_place_kit_asset("lander_A", Vector3(-7.0, 0.08, -5.2), 2.2)
	_place_kit_asset("basemodule_A", Vector3(7.0, 0.0, -5.2), 2.0)
	_place_kit_asset("structure_low", Vector3(9.4, 0.0, -4.0), 1.8)
	_place_kit_asset("solarpanel", Vector3(6.6, 0.0, -2.9), 2.0)
	_place_kit_asset("spacetruck", Vector3(3.3, 0.0, -6.5), 1.8)
	_place_kit_asset("rocks_A", Vector3(-8.3, 0.0, 2.0), 2.4)
	_place_kit_asset("rocks_B", Vector3(9.2, 0.0, 3.2), 2.5)


func _place_kit_asset(asset_id: String, world_position: Vector3, uniform_scale: float) -> Node3D:
	var model_path := str(ASSET_PATHS.get(asset_id, ""))
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		var packed_scene := ResourceLoader.load(model_path) as PackedScene
		if packed_scene != null:
			var instance := packed_scene.instantiate() as Node3D
			if instance != null:
				instance.position = world_position
				instance.scale = Vector3.ONE * uniform_scale
				add_child(instance)
				_loaded_assets[asset_id] = true
				return instance

	# A visible fallback keeps editor checkouts usable when CI-only assets are absent.
	var fallback := Node3D.new()
	fallback.name = "Fallback_" + asset_id
	fallback.position = world_position
	add_child(fallback)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 0.8, 1.0)
	body.mesh = mesh
	body.material_override = _make_material(Color(0.25, 0.37, 0.43), Color(0.06, 0.16, 0.20), 0.55)
	fallback.add_child(body)
	return fallback


func _build_survey_sites() -> void:
	for site_id in SURVEY_SITES:
		var site: Dictionary = SURVEY_SITES[site_id]
		var marker := Node3D.new()
		marker.name = "SurveySite_" + str(site_id)
		marker.position = site["position"]
		add_child(marker)

		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.75
		ring_mesh.outer_radius = 0.86
		ring.mesh = ring_mesh
		ring.rotation_degrees.x = 90.0
		ring.position.y = 0.08
		ring.material_override = _make_material(site["accent"], site["accent"], 0.45)
		marker.add_child(ring)

		var beacon := MeshInstance3D.new()
		var beacon_mesh := SphereMesh.new()
		beacon_mesh.radius = 0.20
		beacon_mesh.height = 0.40
		beacon.mesh = beacon_mesh
		beacon.position.y = 0.65
		beacon.material_override = _make_material(site["accent"], site["accent"], 0.35)
		marker.add_child(beacon)

		var label := Label3D.new()
		label.text = str(site["title"])
		label.position = Vector3(0.0, 1.35, 0.0)
		label.font = preload("res://assets/fonts/NotoSansArabic[wdth,wght].ttf")
		label.font_size = 34
		label.pixel_size = 0.006
		label.modulate = Color(0.98, 0.96, 0.90)
		label.text_direction = TextServer.DIRECTION_RTL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.outline_size = 5
		label.outline_modulate = Color(0.16, 0.07, 0.04, 0.95)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.add_child(label)

		if site_id == "layered_rock":
			_place_kit_asset("rocks_A", marker.position + Vector3(1.1, 0.0, 0.0), 1.7)
		elif site_id == "sand_ripples":
			_add_ripple_lines(marker)
		else:
			_add_crater_rim(marker)


func _add_ripple_lines(parent: Node3D) -> void:
	for index in range(5):
		var line := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.9, 0.035, 0.08)
		line.mesh = mesh
		line.position = Vector3(0.0, 0.025 + float(index) * 0.006, -0.45 + float(index) * 0.22)
		line.rotation_degrees.y = -13.0
		line.material_override = _make_material(Color(0.69, 0.39, 0.23), Color(0.0, 0.0, 0.0), 0.95)
		parent.add_child(line)


func _add_crater_rim(parent: Node3D) -> void:
	var rim := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.8
	mesh.outer_radius = 1.05
	rim.mesh = mesh
	rim.rotation_degrees.x = 90.0
	rim.position.y = 0.02
	rim.material_override = _make_material(Color(0.32, 0.16, 0.12), Color(0.0, 0.0, 0.0), 1.0)
	parent.add_child(rim)
	_place_kit_asset("rocks_B", parent.position + Vector3(-1.0, 0.0, -0.7), 1.5)


func _build_rover() -> void:
	_rover = CharacterBody3D.new()
	_rover.name = "SanaSurveyRover"
	_rover.position = Vector3(0.0, 0.0, 6.0)

	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(1.15, 0.65, 1.45)
	collision.shape = collision_shape
	collision.position.y = 0.42
	_rover.add_child(collision)

	_add_rover_box(_rover, Vector3(0.0, 0.48, 0.0), Vector3(0.92, 0.34, 1.25), Color(0.18, 0.30, 0.36))
	_add_rover_box(_rover, Vector3(0.0, 0.74, -0.12), Vector3(0.66, 0.08, 0.78), Color(0.10, 0.25, 0.38))
	_add_rover_box(_rover, Vector3(0.0, 1.03, -0.42), Vector3(0.12, 0.56, 0.12), Color(0.68, 0.73, 0.75))
	_add_rover_box(_rover, Vector3(0.0, 1.34, -0.42), Vector3(0.34, 0.23, 0.24), Color(0.82, 0.65, 0.35))
	_add_rover_box(_rover, Vector3(-0.78, 0.70, 0.0), Vector3(0.66, 0.07, 0.86), Color(0.10, 0.25, 0.38))
	_add_rover_box(_rover, Vector3(0.78, 0.70, 0.0), Vector3(0.66, 0.07, 0.86), Color(0.10, 0.25, 0.38))
	_add_rover_box(_rover, Vector3(0.0, 1.52, -0.42), Vector3(0.44, 0.07, 0.34), Color(0.91, 0.72, 0.43))
	for side in [-1.0, 1.0]:
		for axle in [-0.43, 0.0, 0.43]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.22
			wheel_mesh.bottom_radius = 0.22
			wheel_mesh.height = 0.16
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(side * 0.56, 0.25, axle)
			wheel.rotation_degrees.z = 90.0
			wheel.material_override = _make_material(Color(0.12, 0.14, 0.16), Color(0.0, 0.0, 0.0), 0.95)
			_rover.add_child(wheel)
	add_child(_rover)


func _add_rover_box(parent: Node3D, local_position: Vector3, size: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = local_position
	part.material_override = _make_material(color, Color(0.0, 0.0, 0.0), 0.45)
	parent.add_child(part)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "MarsSurveyCamera"
	_camera.current = true
	_camera.fov = 52.0
	add_child(_camera)
	_update_camera(1.0)


func _update_camera(delta:float) -> void:
	if not is_instance_valid(_rover):
		return
	var desired_position := _rover.global_position+Vector3(0.0,10.8,10.2)
	var follow_weight := 1.0-exp(-7.5*maxf(delta,0.0))
	_camera.global_position = _camera.global_position.lerp(desired_position,follow_weight)
	var focus := _rover.global_position+Vector3(0.0,0.35,-0.55)
	_camera.look_at(focus,Vector3.UP)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MarsSurveyInterface"
	layer.layer = 20
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = preload("res://themes/arabic_theme.tres")
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var header := PanelContainer.new()
	header.anchor_left = 0.025
	header.anchor_top = 0.025
	header.anchor_right = 0.40
	header.anchor_bottom = 0.22
	header.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	header_content.add_theme_constant_override("separation", 3)
	header.add_child(header_content)
	header_content.add_child(_new_label("بعثة الروفر الحمراء", 23, Color(0.98, 0.95, 0.90), true))
	var instruction := _new_label("تجوّل بين مواقع الملاحظة الثلاثة وسجّل ما تراه.", 15, Color(0.86, 0.83, 0.78))
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_content.add_child(instruction)
	if allow_return_to_sana:
		var back_button := _new_button("العودة إلى سفينة سَنا", Callable(self, "_return_to_sana"), Vector2(0.0, 40.0))
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		header_content.add_child(back_button)

	var status_panel := PanelContainer.new()
	status_panel.anchor_left = 0.62
	status_panel.anchor_top = 0.025
	status_panel.anchor_right = 0.975
	status_panel.anchor_bottom = 0.14
	status_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(status_panel)
	_status_label = _new_label("", 16, Color(0.98, 0.91, 0.78), true)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_panel.add_child(_status_label)

	_nearby_label = _new_label("اقترب من إحدى العلامات", 16, Color(1.0, 0.85, 0.57), true)
	_nearby_label.anchor_left = 0.43
	_nearby_label.anchor_top = 0.16
	_nearby_label.anchor_right = 0.975
	_nearby_label.anchor_bottom = 0.23
	_nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_nearby_label)

	var feedback_panel := PanelContainer.new()
	feedback_panel.anchor_left = 0.31
	feedback_panel.anchor_top = 0.84
	feedback_panel.anchor_right = 0.77
	feedback_panel.anchor_bottom = 0.975
	feedback_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(feedback_panel)
	_feedback_label = _new_label("لا يوجد مؤقت. خذ وقتك في الاستكشاف.", 14, Color(0.85, 0.89, 0.91))
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	feedback_panel.add_child(_feedback_label)

	_build_touch_controls(root)


func _build_touch_controls(root: Control) -> void:
	var dpad := PanelContainer.new()
	dpad.anchor_left = 0.025
	dpad.anchor_top = 0.66
	dpad.anchor_right = 0.235
	dpad.anchor_bottom = 0.975
	dpad.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(dpad)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
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

	_scan_button = _new_button("افحص الموقع", Callable(self, "_on_scan_pressed"), Vector2(190.0, 66.0))
	_scan_button.anchor_left = 0.79
	_scan_button.anchor_top = 0.84
	_scan_button.anchor_right = 0.975
	_scan_button.anchor_bottom = 0.96
	_scan_button.disabled = true
	root.add_child(_scan_button)


func _add_dpad_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(50.0, 46.0)
	parent.add_child(spacer)


func _add_dpad_button(parent: GridContainer, caption: String, action: String) -> void:
	var button := _new_button(caption, Callable(), Vector2(50.0, 46.0))
	button.button_down.connect(func() -> void: _touch[action] = true)
	button.button_up.connect(func() -> void: _touch[action] = false)
	parent.add_child(button)


func _new_button(caption: String, callback: Callable, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.93))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.23, 0.12, 0.09), Color(0.69, 0.39, 0.24)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.32, 0.17, 0.12), Color(0.89, 0.58, 0.34)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.40, 0.22, 0.14), Color(0.96, 0.72, 0.43)))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.075, 0.06, 0.94)
	style.border_color = Color(0.62, 0.35, 0.24, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _new_label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.text_direction = Control.TEXT_DIRECTION_AUTO
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.025, 0.9))
		label.add_theme_constant_override("outline_size", 1)
	return label


func _update_nearby_site() -> void:
	if not is_instance_valid(_rover) or not is_instance_valid(_scan_button):
		return
	_nearby_site_id = ""
	var nearest_distance := SCAN_DISTANCE
	var rover_flat := Vector3(_rover.global_position.x, 0.0, _rover.global_position.z)
	var found: Array = _state.get("found_site_ids", [])
	for site_id in SURVEY_SITES:
		if found.has(site_id):
			continue
		var site_position: Vector3 = SURVEY_SITES[site_id]["position"]
		var distance := rover_flat.distance_to(site_position)
		if distance < nearest_distance:
			nearest_distance = distance
			_nearby_site_id = str(site_id)

	_scan_button.disabled = _nearby_site_id.is_empty()
	if _nearby_site_id.is_empty():
		_nearby_label.text = "اقترب من إحدى العلامات حتى تتمكن من الفحص."
	else:
		var site: Dictionary = SURVEY_SITES[_nearby_site_id]
		_nearby_label.text = str(site["title"]) + " — " + str(site["hint"])


func _on_scan_pressed() -> void:
	scan_nearby_site()


func _update_status() -> void:
	if is_instance_valid(_status_label):
		_status_label.text = "مواقع الملاحظة: %d / %d" % [get_scan_progress(), SURVEY_SITES.size()]


func _return_to_sana() -> void:
	_touch = {"up": false, "down": false, "left": false, "right": false}
	get_tree().change_scene_to_file("res://scenes/prototypes/sana_hub_prototype.tscn")


func _make_material(color: Color, emission: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission != Color(0.0, 0.0, 0.0):
		material.emission_enabled = true
		material.emission = emission
	return material


func _load_state() -> Dictionary:
	var defaults := {"version": SAVE_VERSION, "found_site_ids": []}
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
	var raw_found: Variant = parsed.get("found_site_ids", [])
	if raw_found is Array:
		for site_id in raw_found:
			var normalized := str(site_id)
			if SURVEY_SITES.has(normalized) and not result["found_site_ids"].has(normalized):
				result["found_site_ids"].append(normalized)
	return result


func _save_state() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save Mars rover survey progress.")
		return false
	file.store_string(JSON.stringify(_state))
	file.close()
	_update_status()
	return true
