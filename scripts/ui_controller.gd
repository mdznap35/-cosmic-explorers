extends Control

signal planet_selected(planet_id: String)
signal zoom_requested(amount: float)
signal reset_requested

const NAVY := Color(0.025, 0.055, 0.12, 0.95)
const NAVY_LIGHT := Color(0.045, 0.095, 0.19, 0.97)
const CYAN := Color(0.37, 0.82, 0.96)
const GOLD := Color(1.0, 0.72, 0.34)
const TEXT_MAIN := Color(0.94, 0.97, 1.0)
const TEXT_MUTED := Color(0.66, 0.75, 0.88)

var _catalog: Array = []
var _discovered: Array = []
var _selected_id := "earth"
var _details_open := false
var _planet_buttons: Dictionary = {}
var _name_label: Label
var _english_label: Label
var _headline_label: Label
var _description_label: Label
var _facts_box: VBoxContainer
var _progress_label: Label
var _details_button: Button


func configure(planets: Array, discovered: Array) -> void:
	_catalog = planets.duplicate(true)
	_discovered = discovered.duplicate()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	show_planet(_selected_id, _discovered)


func _build_ui() -> void:
	var header := _new_panel(0.018, 0.025, 0.982, 0.165)
	var header_row := HBoxContainer.new()
	header_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 0)
	header_row.add_child(brand)
	brand.add_child(_new_label("مستكشفو الكون", 25, TEXT_MAIN, true))
	brand.add_child(_new_label("رحلة صغيرة... واكتشافات لا تنتهي", 12, TEXT_MUTED))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)

	_progress_label = _new_label("", 15, GOLD, true)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.custom_minimum_size = Vector2(170, 42)
	header_row.add_child(_progress_label)

	var zoom_in := _new_button("＋", true, Vector2(54, 48))
	zoom_in.tooltip_text = "تكبير المشهد"
	zoom_in.pressed.connect(func(): zoom_requested.emit(0.12))
	header_row.add_child(zoom_in)

	var zoom_out := _new_button("−", false, Vector2(54, 48))
	zoom_out.tooltip_text = "إبعاد المشهد"
	zoom_out.pressed.connect(func(): zoom_requested.emit(-0.12))
	header_row.add_child(zoom_out)

	var reset := _new_button("إظهار الكل", false, Vector2(116, 48))
	reset.pressed.connect(func(): reset_requested.emit())
	header_row.add_child(reset)

	_build_info_panel()
	_build_planet_navigation()


func _build_info_panel() -> void:
	var panel := _new_panel(0.715, 0.205, 0.982, 0.965)
	var content := VBoxContainer.new()
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var kicker := _new_label("محطة الاكتشاف", 13, CYAN, true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(kicker)

	_name_label = _new_label("الأرض", 27, TEXT_MAIN, true)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_name_label)

	_english_label = _new_label("EARTH", 10, TEXT_MUTED)
	_english_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_english_label)

	var separator := HSeparator.new()
	separator.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.62, 0.75))
	content.add_child(separator)

	_headline_label = _new_label("", 17, GOLD, true)
	_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_headline_label)

	_description_label = _new_label("", 15, TEXT_MAIN)
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_description_label)

	var fact_title := _new_label("هل تعلم؟", 16, CYAN, true)
	fact_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(fact_title)

	_facts_box = VBoxContainer.new()
	_facts_box.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_facts_box.add_theme_constant_override("separation", 7)
	content.add_child(_facts_box)

	_details_button = _new_button("اكتشف المزيد", true, Vector2(0, 48))
	_details_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_button.pressed.connect(_toggle_details)
	content.add_child(_details_button)

	var hint := _new_label("المس كوكباً في المشهد أو اختره من القائمة", 11, TEXT_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)


func _build_planet_navigation() -> void:
	var panel := _new_panel(0.018, 0.795, 0.697, 0.965)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	panel.add_child(layout)

	var title := _new_label("اختر عالماً لاستكشافه", 13, TEXT_MUTED, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", 7)
	scroll.add_child(row)

	for planet in _catalog:
		var planet_id := str(planet["id"])
		var button := _new_button(str(planet["name"]), false, Vector2(86, 52))
		button.tooltip_text = str(planet["english"])
		var captured_id := planet_id
		button.pressed.connect(func(): planet_selected.emit(captured_id))
		row.add_child(button)
		_planet_buttons[planet_id] = button


func show_planet(planet_id: String, discovered: Array = []) -> void:
	var selected: Dictionary = {}
	for planet in _catalog:
		if str(planet.get("id", "")) == planet_id:
			selected = planet
			break
	if selected.is_empty():
		return

	_selected_id = planet_id
	_discovered = discovered.duplicate()
	_details_open = false
	_name_label.text = str(selected.get("name", ""))
	_english_label.text = str(selected.get("english", ""))
	_headline_label.text = str(selected.get("headline", ""))
	_description_label.text = str(selected.get("description", ""))

	_refresh_facts(selected)
	_details_button.text = "اكتشف المزيد"
	_update_navigation_styles()
	_update_progress()


func _toggle_details() -> void:
	_details_open = not _details_open
	var selected: Dictionary = {}
	for planet in _catalog:
		if str(planet.get("id", "")) == _selected_id:
			selected = planet
			break
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
		var fact := _new_label("✦  " + str(facts[index]), 14, TEXT_MAIN)
		fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_facts_box.add_child(fact)


func _update_navigation_styles() -> void:
	for planet_id in _planet_buttons:
		var button: Button = _planet_buttons[planet_id]
		var is_selected := planet_id == _selected_id
		var bg := Color(0.10, 0.32, 0.47, 0.98) if is_selected else NAVY_LIGHT
		var border := GOLD if is_selected else Color(0.19, 0.38, 0.56, 0.95)
		button.add_theme_stylebox_override("normal", _button_style(bg, border))
		button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.13), border.lightened(0.1)))
		button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.1), border))


func _update_progress() -> void:
	_progress_label.text = "اكتشفت %d من ٨ كواكب" % _discovered.size()


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


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = Color(0.18, 0.39, 0.61, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(23)
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _new_button(label_text: String, emphasized: bool, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var bg := Color(0.10, 0.32, 0.47, 0.98) if emphasized else NAVY_LIGHT
	var border := GOLD if emphasized else Color(0.19, 0.38, 0.56, 0.95)
	button.add_theme_stylebox_override("normal", _button_style(bg, border))
	button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.13), border.lightened(0.1)))
	button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.1), border))
	return button


func _new_label(label_text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.7))
		label.add_theme_constant_override("outline_size", 1)
	label.text_direction = TextServer.DIRECTION_AUTO
	return label
