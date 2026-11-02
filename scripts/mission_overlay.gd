extends Control

const MissionCatalog = preload("res://scripts/mission_catalog.gd")
const SaveService = preload("res://scripts/save_service.gd")

const NAVY := Color(0.025, 0.055, 0.12, 0.98)
const NAVY_LIGHT := Color(0.055, 0.12, 0.22, 1.0)
const CYAN := Color(0.37, 0.82, 0.96)
const GOLD := Color(1.0, 0.72, 0.34)
const TEXT_MAIN := Color(0.94, 0.97, 1.0)
const TEXT_MUTED := Color(0.68, 0.77, 0.89)

var _questions: Array = []
var _question_index := 0
var _score := 0
var _answered := false
var _completed := false
var _progress_label: Label
var _prompt_label: Label
var _options_box: VBoxContainer
var _feedback_label: Label
var _continue_button: Button
var _option_buttons: Array[Button] = []


func _ready() -> void:
	theme = preload("res://themes/arabic_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_questions = MissionCatalog.get_questions()
	_build_overlay()
	visible = false


func start_mission() -> void:
	_question_index = 0
	_score = 0
	_answered = false
	_completed = false
	visible = true
	_render_question()


func _build_overlay() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.006, 0.012, 0.035, 0.88)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.14
	panel.anchor_top = 0.09
	panel.anchor_right = 0.86
	panel.anchor_bottom = 0.91
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var content := VBoxContainer.new()
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	title_row.add_theme_constant_override("separation", 10)
	content.add_child(title_row)

	var title := _new_label("مهمة المستكشفين", 24, TEXT_MAIN, true)
	title_row.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)

	var close_button := _new_button("إغلاق", false, Vector2(104, 44))
	close_button.pressed.connect(func(): visible = false)
	title_row.add_child(close_button)

	_progress_label = _new_label("", 14, GOLD, true)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_progress_label)

	_prompt_label = _new_label("", 21, TEXT_MAIN, true)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_prompt_label)

	_options_box = VBoxContainer.new()
	_options_box.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_options_box.add_theme_constant_override("separation", 9)
	content.add_child(_options_box)

	_feedback_label = _new_label("", 15, CYAN, true)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.custom_minimum_size = Vector2(0, 56)
	content.add_child(_feedback_label)

	_continue_button = _new_button("التالي", true, Vector2(0, 50))
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.visible = false
	content.add_child(_continue_button)


func _render_question() -> void:
	_answered = false
	_completed = false
	var question: Dictionary = _questions[_question_index]
	_progress_label.text = "السؤال %d من %d" % [_question_index + 1, _questions.size()]
	_prompt_label.text = str(question.get("prompt", ""))
	_feedback_label.text = ""
	_continue_button.visible = false
	_continue_button.text = "التالي"
	_options_box.visible = true
	_clear_options()

	var options: Array = question.get("options", [])
	for index in range(options.size()):
		var option_button := _new_button(str(options[index]), false, Vector2(0, 56))
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var chosen_index := index
		option_button.pressed.connect(func(): _answer(chosen_index))
		_options_box.add_child(option_button)
		_option_buttons.append(option_button)


func _answer(choice_index: int) -> void:
	if _answered or _question_index >= _questions.size():
		return
	_answered = true
	var question: Dictionary = _questions[_question_index]
	var options: Array = question.get("options", [])
	var correct_index := int(question.get("correct_index", -1))
	var correct := choice_index == correct_index
	if correct:
		_score += 1

	for index in range(_option_buttons.size()):
		var button: Button = _option_buttons[index]
		button.disabled = true
		var background := Color(0.11, 0.29, 0.35, 1.0) if index == correct_index else NAVY_LIGHT
		var border := GOLD if index == correct_index else Color(0.20, 0.39, 0.57, 0.9)
		button.add_theme_stylebox_override("normal", _button_style(background, border))

	var explanation := str(question.get("explanation", ""))
	if correct:
		_feedback_label.text = "إجابة صحيحة! ✦ " + explanation
	else:
		_feedback_label.text = "معلومة جديدة: " + str(options[correct_index]) + ". " + explanation
	_continue_button.visible = true


func _on_continue_pressed() -> void:
	if _completed:
		start_mission()
		return
	if not _answered:
		return
	if _question_index + 1 < _questions.size():
		_question_index += 1
		_render_question()
	else:
		_show_results()


func _show_results() -> void:
	_completed = true
	_options_box.visible = false
	_question_index = _questions.size()
	var stats: Dictionary = SaveService.record_mission_result(_score, _questions.size())
	var best_score := int(stats.get("best_score", _score))
	_progress_label.text = "اكتملت المهمة"
	_prompt_label.text = "رائع! لقد أنهيت رحلة الأسئلة الفضائية."
	_feedback_label.text = "نتيجتك: %d من %d
أفضل نتيجة محفوظة: %d من %d
كل سؤال تعلّمت منه شيئاً جديداً!" % [
		_score, _questions.size(), best_score, _questions.size()
	]
	_continue_button.text = "أعد المهمة"
	_continue_button.visible = true


func _clear_options() -> void:
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()
	_option_buttons.clear()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = Color(0.22, 0.48, 0.68, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(26)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(17)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _new_button(label_text: String, emphasized: bool, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var background := Color(0.10, 0.32, 0.47, 0.98) if emphasized else NAVY_LIGHT
	var border := GOLD if emphasized else Color(0.19, 0.38, 0.56, 0.95)
	button.add_theme_stylebox_override("normal", _button_style(background, border))
	button.add_theme_stylebox_override("hover", _button_style(background.lightened(0.12), border.lightened(0.1)))
	button.add_theme_stylebox_override("pressed", _button_style(background.darkened(0.1), border))
	return button


func _new_label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.7))
		label.add_theme_constant_override("outline_size", 1)
	label.text_direction = TextServer.DIRECTION_AUTO
	return label
