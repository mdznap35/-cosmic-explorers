extends Node3D
## Guided, child-friendly lunar outpost builder using a pinned CC0 KayKit subset.
## All construction is optional, forgiving, offline, and checkpointed locally.

const SAVE_PATH := "user://lunar_outpost_builder.json"
const SAVE_VERSION := 1
const ASSET_ROOT := "res://assets/vendor/kaykit_space_base_bits"
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
const BUILD_SEQUENCE := [
	"landing_zone",
	"habitat",
	"solar_array",
	"communications_module"
]
const COMPONENT_DATA := {
	"landing_zone": {
		"title": "منصة الهبوط",
		"asset": "landingpad_small",
		"position": Vector3(-5.4, 0.02, -2.8),
		"scale": 2.8,
		"feedback": "أصبحت لدينا منطقة واضحة وآمنة لهبوط المركبات."
	},
	"habitat": {
		"title": "وحدة السكن",
		"asset": "basemodule_A",
		"position": Vector3(0.0, 0.0, -2.8),
		"scale": 2.3,
		"feedback": "أضفنا وحدة يمكن أن تضم أدوات الفريق ومساحة العمل."
	},
	"solar_array": {
		"title": "ألواح الطاقة الشمسية",
		"asset": "solarpanel",
		"position": Vector3(5.0, 0.0, -2.8),
		"scale": 2.8,
		"feedback": "تساعد الألواح الشمسية على تحويل ضوء الشمس إلى طاقة كهربائية."
	},
	"communications_module": {
		"title": "وحدة الاتصال",
		"asset": "structure_low",
		"position": Vector3(0.0, 0.0, 3.1),
		"scale": 2.3,
		"feedback": "أصبحت القاعدة تملك نقطة مخصصة لمعدات الاتصال."
	}
}
const COMPONENT_ORDER_HINTS := {
	"landing_zone": "ابدأ بمنصة الهبوط حتى نحدد مكان وصول المركبات.",
	"habitat": "بعد تجهيز منطقة الهبوط، أضف وحدة السكن والعمل.",
	"solar_array": "الآن جهّز مصدراً للطاقة باستخدام الألواح الشمسية.",
	"communications_module": "أخيراً أضف وحدة الاتصال لربط القاعدة بفريق سَنا."
}

var _state: Dictionary = {}
var _loaded_assets: Dictionary = {}
var _placed_nodes: Dictionary = {}
var _progress_label: Label
var _feedback_label: Label
var _component_buttons: Dictionary = {}


func _ready() -> void:
	_state = _load_state()
	_build_environment()
	_build_lunar_site()
	_build_decorative_assets()
	_restore_placed_components()
	_build_camera()
	_build_interface()
	_update_interface()


func get_required_component_ids() -> PackedStringArray:
	return PackedStringArray(BUILD_SEQUENCE)


func get_placed_component_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for component_id in _state.get("placed_component_ids", []):
		result.append(str(component_id))
	return result


func get_build_progress() -> int:
	return get_placed_component_ids().size()


func is_base_complete() -> bool:
	return get_build_progress() == BUILD_SEQUENCE.size()


func get_loaded_asset_ids() -> PackedStringArray:
	return PackedStringArray(_loaded_assets.keys())


func place_component(component_id: String) -> bool:
	if not COMPONENT_DATA.has(component_id) or is_base_complete():
		return false
	var placed: Array = _state.get("placed_component_ids", [])
	if placed.has(component_id):
		_set_feedback("هذه الوحدة مركّبة بالفعل. يمكنك اختيار الوحدة التالية.")
		return false

	var expected_id: String = BUILD_SEQUENCE[get_build_progress()]
	if component_id != expected_id:
		_set_feedback(str(COMPONENT_ORDER_HINTS[expected_id]))
		return false

	var component: Dictionary = COMPONENT_DATA[component_id]
	var instance := _place_asset(
		str(component["asset"]),
		component["position"],
		float(component["scale"]),
		"Built_" + component_id
	)
	_placed_nodes[component_id] = instance
	placed.append(component_id)
	_state["placed_component_ids"] = placed
	if not _save_state():
		placed.erase(component_id)
		_state["placed_component_ids"] = placed
		_placed_nodes.erase(component_id)
		instance.queue_free()
		_set_feedback("تعذّر حفظ البناء. لم نحتسب هذه الخطوة، ويمكنك المحاولة مجدداً.")
		_update_interface()
		return false

	if is_base_complete():
		_set_feedback("اكتمل بناء القاعدة القمرية! أصبحت جاهزة لاستقبال فريق سَنا.")
	else:
		_set_feedback(str(component["feedback"]) + "\n" + str(COMPONENT_ORDER_HINTS[BUILD_SEQUENCE[get_build_progress()]]))
	_update_interface()
	return true


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.045, 0.105)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.70, 0.88)
	environment.ambient_light_energy = 0.9
	world.environment = environment
	add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = false
	add_child(sunlight)


func _build_lunar_site() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(24.0, 19.0)
	ground.mesh = ground_mesh
	ground.position.y = -0.06
	ground.material_override = _material(Color(0.30, 0.32, 0.38), Color(0.0, 0.0, 0.0), 0.98)
	add_child(ground)

	for index in range(9):
		var ridge := MeshInstance3D.new()
		var ridge_mesh := SphereMesh.new()
		ridge_mesh.radius = 1.0
		ridge_mesh.height = 1.5
		ridge.mesh = ridge_mesh
		ridge.scale = Vector3(1.7 + float(index % 3) * 0.55, 0.85 + float(index % 2) * 0.3, 0.8)
		ridge.position = Vector3(-13.0 + float(index) * 3.2, -0.05, -10.0 - float(index % 2) * 1.2)
		ridge.material_override = _material(Color(0.22, 0.24, 0.30), Color(0.0, 0.0, 0.0), 1.0)
		add_child(ridge)

	for component_id in BUILD_SEQUENCE:
		var component: Dictionary = COMPONENT_DATA[component_id]
		_add_build_marker(component_id, component["position"])


func _add_build_marker(component_id: String, marker_position: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "BuildMarker_" + component_id
	marker.position = marker_position
	add_child(marker)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.72
	ring_mesh.outer_radius = 0.82
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	ring.position.y = 0.06
	ring.material_override = _material(Color(0.28, 0.76, 0.96), Color(0.08, 0.32, 0.52), 0.4)
	marker.add_child(ring)

	var label := Label3D.new()
	label.text = str(COMPONENT_DATA[component_id]["title"])
	label.position.y = 1.35
	label.font = preload("res://assets/fonts/NotoSansArabic[wdth,wght].ttf")
	label.font_size = 30
	label.pixel_size = 0.006
	label.text_direction = TextServer.DIRECTION_RTL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.96, 0.97, 1.0)
	label.outline_size = 5
	label.outline_modulate = Color(0.06, 0.08, 0.14, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.add_child(label)


func _build_decorative_assets() -> void:
	_place_asset("lander_A", Vector3(-9.0, 0.0, 5.0), 2.0, "ArrivalLander")
	_place_asset("spacetruck", Vector3(8.0, 0.0, 5.0), 1.8, "UtilityRover")
	_place_asset("rocks_A", Vector3(-10.0, 0.0, -1.0), 2.0, "MoonRocksA")
	_place_asset("rocks_B", Vector3(10.0, 0.0, -1.0), 2.0, "MoonRocksB")


func _restore_placed_components() -> void:
	for component_id in BUILD_SEQUENCE:
		if not _state.get("placed_component_ids", []).has(component_id):
			continue
		var component: Dictionary = COMPONENT_DATA[component_id]
		_placed_nodes[component_id] = _place_asset(
			str(component["asset"]),
			component["position"],
			float(component["scale"]),
			"Built_" + component_id
		)


func _place_asset(asset_id: String, world_position: Vector3, uniform_scale: float, instance_name: String) -> Node3D:
	var model_path := str(ASSET_PATHS.get(asset_id, ""))
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		var packed_scene := ResourceLoader.load(model_path) as PackedScene
		if packed_scene != null:
			var instance := packed_scene.instantiate() as Node3D
			if instance != null:
				instance.name = instance_name
				instance.position = world_position
				instance.scale = Vector3.ONE * uniform_scale
				add_child(instance)
				_loaded_assets[asset_id] = true
				return instance

	var fallback := Node3D.new()
	fallback.name = "Fallback_" + instance_name
	fallback.position = world_position
	add_child(fallback)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 0.9, 1.2)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(Color(0.36, 0.48, 0.62), Color(0.05, 0.12, 0.22), 0.65)
	fallback.add_child(mesh_instance)
	return fallback


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "LunarOutpostCamera"
	camera.current = true
	camera.fov = 48.0
	add_child(camera)
	camera.position = Vector3(0.0, 16.0, 21.0)
	camera.look_at(Vector3(0.0, 0.0, -0.2), Vector3.UP)


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = preload("res://themes/arabic_theme.tres")
	layer.add_child(root)

	var header := PanelContainer.new()
	header.anchor_left = 0.025
	header.anchor_top = 0.025
	header.anchor_right = 0.43
	header.anchor_bottom = 0.25
	header.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	header_content.add_theme_constant_override("separation", 5)
	header.add_child(header_content)

	var title := _new_label("ورشة سليم: بناء القاعدة القمرية", 21, Color(0.96, 0.97, 1.0), true)
	header_content.add_child(title)
	var description := _new_label("جهّز موقع الهبوط، ثم ابنِ المأوى والطاقة والاتصال. لا يوجد وقت محدد ولا خسارة للتقدم.", 14, Color(0.80, 0.87, 0.95))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_content.add_child(description)
	var back_button := _new_button("العودة إلى سَنا", Callable(self, "_return_to_sana"), Vector2(0.0, 40.0))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_content.add_child(back_button)

	var build_panel := PanelContainer.new()
	build_panel.anchor_left = 0.68
	build_panel.anchor_top = 0.20
	build_panel.anchor_right = 0.975
	build_panel.anchor_bottom = 0.82
	build_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(build_panel)

	var build_content := VBoxContainer.new()
	build_content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	build_content.add_theme_constant_override("separation", 7)
	build_panel.add_child(build_content)

	_progress_label = _new_label("", 17, Color(1.0, 0.82, 0.48), true)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_content.add_child(_progress_label)

	for component_id in BUILD_SEQUENCE:
		var button := _new_button(
			str(COMPONENT_DATA[component_id]["title"]),
			func() -> void: place_component(component_id),
			Vector2(0.0, 52.0)
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_content.add_child(button)
		_component_buttons[component_id] = button

	_feedback_label = _new_label("", 15, Color(0.72, 0.88, 0.97))
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_feedback_label.anchor_left = 0.27
	_feedback_label.anchor_top = 0.86
	_feedback_label.anchor_right = 0.975
	_feedback_label.anchor_bottom = 0.985
	root.add_child(_feedback_label)


func _update_interface() -> void:
	if is_instance_valid(_progress_label):
		if is_base_complete():
			_progress_label.text = "اكتملت القاعدة القمرية!"
		else:
			var next_id: String = BUILD_SEQUENCE[get_build_progress()]
			_progress_label.text = "مراحل البناء: %d / %d\nالخطوة التالية: %s" % [
				get_build_progress(),
				BUILD_SEQUENCE.size(),
				str(COMPONENT_DATA[next_id]["title"])
			]
	for component_id in _component_buttons:
		var button: Button = _component_buttons[component_id]
		button.disabled = get_placed_component_ids().has(component_id)


func _return_to_sana() -> void:
	get_tree().change_scene_to_file("res://scenes/prototypes/sana_hub_prototype.tscn")


func _set_feedback(message: String) -> void:
	if is_instance_valid(_feedback_label):
		_feedback_label.text = message


func _new_button(caption: String, callback: Callable, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.16, 0.27), Color(0.22, 0.55, 0.78)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.22, 0.35), Color(0.38, 0.72, 0.92)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.13, 0.29, 0.43), Color(0.52, 0.82, 0.96)))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _new_label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.text_direction = Control.TEXT_DIRECTION_AUTO
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.11, 0.9))
		label.add_theme_constant_override("outline_size", 1)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.14, 0.94)
	style.border_color = Color(0.22, 0.52, 0.72, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _material(color: Color, emission: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission != Color(0.0, 0.0, 0.0):
		material.emission_enabled = true
		material.emission = emission
	return material


func _load_state() -> Dictionary:
	var defaults := {"version": SAVE_VERSION, "placed_component_ids": []}
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
	var raw_placed: Variant = parsed.get("placed_component_ids", [])
	if raw_placed is Array:
		for component_id in BUILD_SEQUENCE:
			if raw_placed.has(component_id):
				result["placed_component_ids"].append(component_id)
	return result


func _save_state() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save lunar outpost builder progress.")
		return false
	file.store_string(JSON.stringify(_state))
	file.close()
	return true
