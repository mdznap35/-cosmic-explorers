extends Control

signal planet_selected(planet_id: String)
signal zoom_requested(amount: float)
signal reset_requested
signal motion_requested(enabled: bool)

const MissionOverlay = preload("res://scripts/mission_overlay.gd")

const PANEL := Color(0.025, 0.055, 0.12, 0.96)
const PANEL_LIGHT := Color(0.045, 0.092, 0.17, 0.98)
const CYAN := Color(0.38, 0.83, 0.97)
const CYAN_SOFT := Color(0.19, 0.52, 0.72)
const GOLD := Color(1.0, 0.75, 0.40)
const TEXT_MAIN := Color(0.95, 0.975, 1.0)
const TEXT_MUTED := Color(0.69, 0.78, 0.90)
const TEXT_QUIET := Color(0.48, 0.61, 0.76)

var _catalog: Array = []
var _sun_data: Dictionary = {}
var _discovered: Array = []
var _selected_id := "earth"
var _details_open := false
var _planet_buttons: Dictionary = {}
var _name_label: Label
var _english_label: Label
var _classification_label: Label
var _headline_label: Label
var _description_label: Label
var _facts_box: VBoxContainer
var _progress_label: Label
var _progress_bar: ProgressBar
var _details_button: Button
var _motion_button: Button
var _accent_strip: ColorRect
var _mission_overlay: Control
var _welcome_overlay: Control
var _motion_enabled := true


func configure(planets: Array, discovered: Array, sun_data: Dictionary = {}) -> void:
	_catalog = planets.duplicate(true)
	_sun_data = sun_data.duplicate(true)
	_discovered = discovered.duplicate()


func _ready() -> void:
	theme = preload("res://themes/arabic_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_exploration_ui()
	_mission_overlay = MissionOverlay.new()
	add_child(_mission_overlay)
	_build_welcome_overlay()
	show_planet(_selected_id, _discovered)


func _build_exploration_ui() -> void:
	_build_header()
	_build_information_station()
	_build_world_navigation()
	_build_scene_hint()


func _build_header() -> void:
	var header := _new_panel(0.018, 0.022, 0.982, 0.168)
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header.add_child(row)

	var companion := TextureRect.new()
	companion.name = "SpaceCompanion"
	companion.texture = preload("res://assets/branding/space_companion.svg")
	companion.custom_minimum_size = Vector2(66, 66)
	companion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	companion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(companion)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 1)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand.add_child(_new_label("مستكشفو الكون", 24, TEXT_MAIN, true))
	brand.add_child(_new_label("رحلتك الصغيرة إلى عوالم كبيرة", 12, TEXT_MUTED))
	row.add_child(brand)

	var brand_gap := Control.new()
	brand_gap.custom_minimum_size = Vector2(8, 0)
	row.add_child(brand_gap)

	var progress_panel := PanelContainer.new()
	progress_panel.custom_minimum_size = Vector2(188, 58)
	progress_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_LIGHT, Color(0.20, 0.43, 0.62, 0.7), 8))
	row.add_child(progress_panel)

	var progress_content := VBoxContainer.new()
	progress_content.add_theme_constant_override("separation", 4)
	progress_panel.add_child(progress_content)

	var progress_heading := _new_label("رحلة الاكتشاف", 11, TEXT_MUTED, true)
	progress_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_content.add_child(progress_heading)

	_progress_label = _new_label("٠ / ٨ كواكب", 13, GOLD, true)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_content.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 8.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 7)
	_progress_bar.add_theme_stylebox_override("background", _flat_style(Color(0.10, 0.17, 0.27, 1.0), Color(0.10, 0.17, 0.27, 1.0), 4))
	_progress_bar.add_theme_stylebox_override("fill", _flat_style(GOLD, GOLD, 4))
	progress_content.add_child(_progress_bar)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var mission_button := _new_button("مهمة المستكشف", true, Vector2(142, 48))
	mission_button.tooltip_text = "ابدأ تحدياً تعليمياً قصيراً"
	mission_button.pressed.connect(_open_mission)
	row.add_child(mission_button)

	_motion_button = _new_button("إيقاف الحركة", false, Vector2(124, 48))
	_motion_button.tooltip_text = "إيقاف أو تشغيل حركة الكواكب"
	_motion_button.pressed.connect(_toggle_motion)
	row.add_child(_motion_button)

	var reset_button := _new_button("إظهار الكل", false, Vector2(112, 48))
	reset_button.tooltip_text = "العودة إلى مشهد المجموعة الشمسية"
	reset_button.pressed.connect(func(): reset_requested.emit())
	row.add_child(reset_button)

	var zoom_out := _new_button("−", false, Vector2(48, 48))
	zoom_out.tooltip_text = "إبعاد المشهد"
	zoom_out.pressed.connect(func(): zoom_requested.emit(-0.12))
	row.add_child(zoom_out)

	var zoom_in := _new_button("＋", false, Vector2(48, 48))
	zoom_in.tooltip_text = "تقريب المشهد"
	zoom_in.pressed.connect(func(): zoom_requested.emit(0.12))
	row.add_child(zoom_in)


func _build_information_station() -> void:
	var panel := _new_panel(0.735, 0.198, 0.982, 0.965)
	var content := VBoxContainer.new()
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading_row := HBoxContainer.new()
	heading_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	heading_row.add_theme_constant_override("separation", 8)
	content.add_child(heading_row)

	var kicker := _new_label("محطة الاكتشاف", 13, CYAN, true)
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(kicker)

	_classification_label = _new_label("كوكب", 11, GOLD, true)
	_classification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_classification_label.custom_minimum_size = Vector2(66, 28)
	heading_row.add_child(_classification_label)

	_accent_strip = ColorRect.new()
	_accent_strip.custom_minimum_size = Vector2(0, 4)
	_accent_strip.color = CYAN
	content.add_child(_accent_strip)

	_name_label = _new_label("الأرض", 28, TEXT_MAIN, true)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_name_label)

	_english_label = _new_label("EARTH", 10, TEXT_QUIET, true)
	_english_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_english_label)

	var separator := HSeparator.new()
	separator.add_theme_color_override("separator_color", Color(0.20, 0.39, 0.57, 0.76))
	content.add_child(separator)

	_headline_label = _new_label("", 17, GOLD, true)
	_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_headline_label)

	_description_label = _new_label("", 14, TEXT_MAIN)
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.custom_minimum_size = Vector2(0, 84)
	content.add_child(_description_label)

	var fact_header := HBoxContainer.new()
	fact_header.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_child(fact_header)

	var fact_title := _new_label("هل تعلم؟", 15, CYAN, true)
	fact_header.add_child(fact_title)

	var fact_spacer := Control.new()
	fact_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fact_header.add_child(fact_spacer)

	var fact_hint := _new_label("حقيقة سريعة", 10, TEXT_QUIET)
	fact_header.add_child(fact_hint)

	_facts_box = VBoxContainer.new()
	_facts_box.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_facts_box.add_theme_constant_override("separation", 7)
	content.add_child(_facts_box)

	_details_button = _new_button("اكتشف المزيد", true, Vector2(0, 46))
	_details_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_button.pressed.connect(_toggle_details)
	content.add_child(_details_button)

	var footer := _new_label("محتوى تعليمي مبسّط مرتبط بمصادر علمية", 10, TEXT_QUIET)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(footer)


func _build_world_navigation() -> void:
	var panel := _new_panel(0.018, 0.785, 0.715, 0.965)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	panel.add_child(layout)

	var heading_row := HBoxContainer.new()
	heading_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	heading_row.add_theme_constant_override("separation", 8)
	layout.add_child(heading_row)

	var title := _new_label("اختر عالماً لاستكشافه", 13, TEXT_MAIN, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(title)

	var subtitle := _new_label("الشمس والكواكب الثمانية", 10, TEXT_QUIET)
	heading_row.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", 7)
	scroll.add_child(row)

	var all_bodies: Array = []
	if not _sun_data.is_empty():
		all_bodies.append(_sun_data)
	all_bodies.append_array(_catalog)

	for body_data in all_bodies:
		var body_id := str(body_data.get("id", ""))
		var button := _new_button(str(body_data.get("name", "")), false, Vector2(88, 48))
		button.tooltip_text = str(body_data.get("english", ""))
		var captured_id := body_id
		button.pressed.connect(func(): planet_selected.emit(captured_id))
		row.add_child(button)
		_planet_buttons[body_id] = button


func _build_scene_hint() -> void:
	var hint_panel := _new_panel(0.018, 0.188, 0.34, 0.258)
	var hint_row := HBoxContainer.new()
	hint_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	hint_row.add_theme_constant_override("separation", 8)
	hint_panel.add_child(hint_row)

	var hint_marker := _new_label("✦", 17, GOLD, true)
	hint_row.add_child(hint_marker)

	var hint_text := _new_label("اسحب لتدوير المشهد، والمس عالماً لاكتشافه", 11, TEXT_MUTED)
	hint_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_row.add_child(hint_text)


func _build_welcome_overlay() -> void:
	_welcome_overlay = Control.new()
	_welcome_overlay.name = "WelcomeExperience"
	_welcome_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_welcome_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_welcome_overlay.z_index = 50
	add_child(_welcome_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.006, 0.014, 0.039, 0.82)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_welcome_overlay.add_child(dimmer)

	var welcome_panel := PanelContainer.new()
	welcome_panel.anchor_left = 0.16
	welcome_panel.anchor_top = 0.13
	welcome_panel.anchor_right = 0.84
	welcome_panel.anchor_bottom = 0.87
	welcome_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.065, 0.135, 0.99), Color(0.28, 0.59, 0.78, 0.9), 22))
	_welcome_overlay.add_child(welcome_panel)

	var content := VBoxContainer.new()
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_theme_constant_override("separation", 14)
	welcome_panel.add_child(content)

	var brand_row := HBoxContainer.new()
	brand_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	brand_row.add_theme_constant_override("separation", 16)
	content.add_child(brand_row)

	var companion := TextureRect.new()
	companion.texture = preload("res://assets/branding/space_companion.svg")
	companion.custom_minimum_size = Vector2(100, 100)
	companion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	companion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_row.add_child(companion)

	var brand_text := VBoxContainer.new()
	brand_text.add_theme_constant_override("separation", 4)
	brand_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand_text.add_child(_new_label("مرحباً بك في رحلتك الفضائية", 28, TEXT_MAIN, true))
	brand_text.add_child(_new_label("رحلة تفاعلية بين الشمس والكواكب، خطوةً خطوة", 15, TEXT_MUTED))
	brand_row.add_child(brand_text)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator_color", Color(0.20, 0.43, 0.64, 0.78))
	content.add_child(divider)

	var invite := _new_label("ماذا ينتظرك في الرحلة؟", 16, GOLD, true)
	invite.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(invite)

	var cards_row := HBoxContainer.new()
	cards_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	cards_row.add_theme_constant_override("separation", 10)
	content.add_child(cards_row)
	cards_row.add_child(_welcome_card("عوالم مدهشة", "اقترب من الشمس والكواكب، وشاهد تفاصيلها.", "01"))
	cards_row.add_child(_welcome_card("اكتشاف باللمس", "دوّر المشهد واختر العالم الذي تريد زيارته.", "02"))
	cards_row.add_child(_welcome_card("تعلّم بلا استعجال", "حقائق قصيرة ومهمة تعليمية دون مؤقت.", "03"))

	var offline_note := _new_label("تعمل الرحلة الأساسية دون اتصال بالإنترنت", 11, CYAN, true)
	offline_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(offline_note)

	var actions := HBoxContainer.new()
	actions.layout_direction = Control.LAYOUT_DIRECTION_RTL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)

	var start_button := _new_button("ابدأ الرحلة", true, Vector2(210, 54))
	start_button.pressed.connect(_start_exploration)
	actions.add_child(start_button)

	var mission_button := _new_button("ابدأ مهمة المستكشف", false, Vector2(210, 54))
	mission_button.pressed.connect(_open_mission)
	actions.add_child(mission_button)


func _welcome_card(title_text: String, body_text: String, number_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 112)
	card.add_theme_stylebox_override("panel", _panel_style(PANEL_LIGHT, Color(0.16, 0.34, 0.52, 0.75), 6))

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	card.add_child(content)

	var number := _new_label(number_text, 10, CYAN, true)
	content.add_child(number)

	var title := _new_label(title_text, 15, TEXT_MAIN, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(title)

	var body := _new_label(body_text, 12, TEXT_MUTED)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	return card


func _start_exploration() -> void:
	if _welcome_overlay != null:
		_welcome_overlay.visible = false


func _open_mission() -> void:
	if _welcome_overlay != null:
		_welcome_overlay.visible = false
	if _mission_overlay != null:
		_mission_overlay.start_mission()


func _toggle_motion() -> void:
	_motion_enabled = not _motion_enabled
	if _motion_button != null:
		_motion_button.text = "إيقاف الحركة" if _motion_enabled else "تشغيل الحركة"
		motion_requested.emit(_motion_enabled)


func show_planet(planet_id: String, discovered: Array = []) -> void:
	var selected: Dictionary = _body_data(planet_id)
	if selected.is_empty():
		return

	_selected_id = planet_id
	_discovered = discovered.duplicate()
	_details_open = false
	_name_label.text = str(selected.get("name", ""))
	_english_label.text = str(selected.get("english", ""))
	_classification_label.text = "نجم" if planet_id == "sun" else "كوكب"
	_headline_label.text = str(selected.get("headline", ""))
	_description_label.text = str(selected.get("description", ""))

	var accent: Color = selected.get("accent", CYAN)
	_accent_strip.color = accent
	_refresh_facts(selected)
	_details_button.text = "اكتشف المزيد"
	_update_navigation_styles()
	_update_progress()


func _body_data(planet_id: String) -> Dictionary:
	if planet_id == "sun":
		return _sun_data.duplicate(true)
	for body_data in _catalog:
		if str(body_data.get("id", "")) == planet_id:
			return body_data.duplicate(true)
	return {}


func _toggle_details() -> void:
	_details_open = not _details_open
	var selected := _body_data(_selected_id)
	if selected.is_empty():
		return
	_refresh_facts(selected)
	_details_button.text = "إخفاء التفاصيل" if _details_open else "اكتشف المزيد"


func _refresh_facts(selected: Dictionary) -> void:
	for child in _facts_box.get_children():
		_facts_box.remove_child(child)
		child.queue_free()

	var facts: Array = selected.get("facts", [])
	var count := facts.size() if _details_open else mini(1, facts.size())
	for index in range(count):
		var fact_row := HBoxContainer.new()
		fact_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
		fact_row.add_theme_constant_override("separation", 7)
		_facts_box.add_child(fact_row)

		var marker := _new_label("✦", 12, GOLD, true)
		fact_row.add_child(marker)

		var fact := _new_label(str(facts[index]), 13, TEXT_MAIN)
		fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fact.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fact_row.add_child(fact)


func _update_navigation_styles() -> void:
	for body_id in _planet_buttons:
		var button: Button = _planet_buttons[body_id]
		var is_selected := str(body_id) == _selected_id
		var is_discovered := _discovered.has(str(body_id))
		var body := _body_data(str(body_id))
		var body_name := str(body.get("name", ""))
		button.text = ("✓ " if is_discovered and str(body_id) != "sun" else "") + body_name
		var background := Color(0.10, 0.28, 0.40, 1.0) if is_selected else PANEL_LIGHT
		var border := GOLD if is_selected else (CYAN_SOFT if is_discovered else Color(0.17, 0.32, 0.48, 0.92))
		button.add_theme_stylebox_override("normal", _button_style(background, border, is_selected))
		button.add_theme_stylebox_override("hover", _button_style(background.lightened(0.12), border.lightened(0.1), is_selected))
		button.add_theme_stylebox_override("pressed", _button_style(background.darkened(0.1), border, is_selected))


func _update_progress() -> void:
	var count := mini(_discovered.size(), 8)
	_progress_label.text = "%s / ٨ كواكب مكتشفة" % _arabic_number(count)
	_progress_bar.value = count


func _arabic_number(value: int) -> String:
	var digits := ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
	return digits[clampi(value, 0, 9)]


func _new_panel(left: float, top: float, right: float, bottom: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = left
	panel.anchor_top = top
	panel.anchor_right = right
	panel.anchor_bottom = bottom
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	return panel


func _panel_style(
	background: Color = PANEL,
	border: Color = Color(0.18, 0.39, 0.61, 0.78),
	shadow_size: int = 14
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(22)
	style.corner_detail = 8
	style.shadow_color = Color(0.0, 0.008, 0.025, 0.42)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style


func _flat_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(0)
	style.set_corner_radius_all(radius)
	return style


func _button_style(background: Color, border: Color, emphasized: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(15)
	style.corner_detail = 6
	style.shadow_color = Color(0.0, 0.01, 0.03, 0.24)
	style.shadow_size = 4 if emphasized else 2
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _new_button(label_text: String, emphasized: bool, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15 if minimum_size.x > 70 else 20)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", TEXT_QUIET)
	var background := Color(0.10, 0.31, 0.44, 1.0) if emphasized else PANEL_LIGHT
	var border := GOLD if emphasized else Color(0.18, 0.37, 0.55, 0.94)
	button.add_theme_stylebox_override("normal", _button_style(background, border, emphasized))
	button.add_theme_stylebox_override("hover", _button_style(background.lightened(0.13), border.lightened(0.1), emphasized))
	button.add_theme_stylebox_override("pressed", _button_style(background.darkened(0.12), border, emphasized))
	button.add_theme_stylebox_override("focus", _button_style(background, CYAN, true))
	button.add_theme_stylebox_override("disabled", _button_style(PANEL, Color(0.12, 0.22, 0.34, 0.7)))
	return button


func _new_label(label_text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.015, 0.03, 0.06, 0.72))
		label.add_theme_constant_override("outline_size", 1)
	label.text_direction = Control.TEXT_DIRECTION_AUTO
	return label
