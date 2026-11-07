extends Control
## Standalone prototype showcase app. This is a review launcher, not the future production menu.

const DEMOS := [
	{
		"id": "echo_mars",
		"title": "صدى المريخ — التجربة الرئيسية",
		"subtitle": "مغامرة مترابطة من الإشارة إلى إعادة الاتصال",
		"details": "قيادة الروفر • تصوير من زاويتين • تبديل الشخصيات • تحليل النبضات • إصلاح محطة الترحيل",
		"scene": "res://scenes/prototypes/echo_of_mars_vertical_slice.tscn",
		"status": "تجربة رئيسية"
	},
	{
		"id": "sana",
		"title": "سفينة سَنا",
		"subtitle": "خمسة مرافق وأنشطة داخل السفينة",
		"details": "جسر القيادة • ورشة سليم • مختبر مرقاب • مرصد ريم • ركن لولو\nرسالة الاتصال • بناء القمر المصغّر • البحث عن النجوم",
		"scene": "res://scenes/prototypes/sana_hub_prototype.tscn",
		"status": "قابل للتجربة"
	},
	{
		"id": "mars",
		"title": "بعثة الروفر إلى المريخ",
		"subtitle": "قيادة ومسح ثلاثة مواقع علمية",
		"details": "التحكم بالروفر • مواقع الملاحظة • تسجيل العينات • حفظ التقدم",
		"scene": "res://scenes/prototypes/mars_rover_survey.tscn",
		"status": "قابل للتجربة"
	},
	{
		"id": "lunar_builder",
		"title": "ورشة سليم: القاعدة القمرية",
		"subtitle": "أربع مراحل بناء مرئية",
		"details": "منصة الهبوط • وحدة السكن • الطاقة الشمسية • وحدة الاتصال",
		"scene": "res://scenes/prototypes/lunar_outpost_builder.tscn",
		"status": "قابل للتجربة"
	},
	{
		"id": "rover_routes",
		"title": "تخطيط مسارات الروفر",
		"subtitle": "ثلاث مراحل برمجة وتخطيط",
		"details": "أوامر الاتجاهات • جمع العينات • تجاوز الصخور • العودة إلى سَنا",
		"scene": "res://scenes/prototypes/lunar_rover_route_planner.tscn",
		"status": "قابل للتجربة"
	},
	{
		"id": "solar_system",
		"title": "المجموعة الشمسية",
		"subtitle": "المشهد السابق — للمعاينة والمقارنة فقط",
		"details": "عرض الشمس والكواكب وواجهة الاستكشاف السابقة. هذا ليس التصميم الجديد للعبة.",
		"scene": "res://scenes/main.tscn",
		"status": "قديم / للمقارنة"
	}
]

const BG := Color(0.012, 0.025, 0.065, 1.0)
const PANEL := Color(0.035, 0.075, 0.14, 0.98)
const BORDER := Color(0.20, 0.48, 0.68, 0.9)
const TEXT := Color(0.94, 0.97, 1.0)
const MUTED := Color(0.67, 0.78, 0.90)
const CYAN := Color(0.35, 0.82, 0.98)
const GOLD := Color(1.0, 0.78, 0.42)

var _status_label: Label


func _ready() -> void:
	theme = preload("res://themes/arabic_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_interface()


func get_demo_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for demo in DEMOS:
		ids.append(str(demo["id"]))
	return ids


func get_demo_scene_path(demo_id: String) -> String:
	for demo in DEMOS:
		if str(demo["id"]) == demo_id:
			return str(demo["scene"])
	return ""


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var stars := Control.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73021
	for index in range(72):
		var star := ColorRect.new()
		var side := rng.randf_range(1.0, 3.0)
		star.position = Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0))
		star.size = Vector2(side, side)
		star.color = Color(0.55, 0.78, 1.0, rng.randf_range(0.16, 0.58))
		stars.add_child(star)


func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.09, 0.17, 0.97), BORDER, 20))
	layout.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 5)
	header.add_child(header_content)

	var eyebrow := _label("COSMIC EXPLORERS  •  PROTOTYPE SHOWCASE", 11, CYAN, true)
	header_content.add_child(eyebrow)
	var title := _label("مختبر التجارب الفضائية", 31, TEXT, true)
	header_content.add_child(title)
	var subtitle := _label("هنا تجد النماذج الموجودة فعلياً في المشروع. افتح كل تجربة واختبرها، ثم عد إلى هذه القائمة من سفينة سَنا.", 15, MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_content.add_child(subtitle)

	var section_row := HBoxContainer.new()
	layout.add_child(section_row)
	var section_title := _label("التجارب المتاحة", 20, GOLD, true)
	section_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_row.add_child(section_title)
	_status_label = _label("٥ مشاهد • تشغيل محلي دون اتصال", 12, MUTED)
	section_row.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for demo in DEMOS:
		grid.add_child(_make_demo_card(demo))

	var footer := _label("نسخة فحص واستعراض مستقلة • لا تغيّر النسخة الرئيسية المنشورة", 11, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)


func _make_demo_card(demo: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 174)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 16))

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)

	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var title := _label(str(demo["title"]), 18, TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var status := _label(str(demo["status"]), 10, GOLD if str(demo["id"]) == "solar_system" else CYAN, true)
	title_row.add_child(status)

	var subtitle := _label(str(demo["subtitle"]), 13, CYAN, true)
	content.add_child(subtitle)
	var details := _label(str(demo["details"]), 12, MUTED)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(details)

	var open_button := Button.new()
	open_button.text = "افتح التجربة  ←"
	open_button.custom_minimum_size = Vector2(0, 40)
	open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_button.add_theme_font_size_override("font_size", 14)
	open_button.add_theme_color_override("font_color", TEXT)
	open_button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.22, 0.34), CYAN))
	open_button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.31, 0.44), CYAN))
	open_button.add_theme_stylebox_override("pressed", _button_style(Color(0.04, 0.15, 0.26), GOLD))
	var scene_path := str(demo["scene"])
	open_button.pressed.connect(func() -> void: _open_scene(scene_path))
	content.add_child(open_button)
	return card


func _open_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_status_label.text = "المشهد غير موجود: " + scene_path
		return
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		_status_label.text = "تعذّر فتح التجربة. رمز الخطأ: " + str(result)


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.07, 0.8))
		label.add_theme_constant_override("outline_size", 1)
	return label
