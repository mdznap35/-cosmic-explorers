extends Control
## A calm, child-friendly command-planning puzzle for the lunar rover.
## Commands are planned first, then simulated together; there is no timer or penalty.

const SAVE_PATH := "user://lunar_rover_routes.json"
const SAVE_VERSION := 1
const GRID_SIZE := 5
const MAX_COMMANDS := 16
const COMMANDS := ["up", "right", "down", "left"]
const COMMAND_GLYPHS := {"up": "↑", "right": "→", "down": "↓", "left": "←"}
const LEVELS := [
	{
		"id": "route_01",
		"title": "العينة الأولى",
		"start": Vector2i(0, 4),
		"goal": Vector2i(4, 0),
		"samples": [Vector2i(2, 4)],
		"blocked": [Vector2i(3, 2)],
		"hint": "خطّط طريقاً يمرّ بالعينة ثم يصل إلى محطة سَنا."
	},
	{
		"id": "route_02",
		"title": "حول الصخور",
		"start": Vector2i(0, 4),
		"goal": Vector2i(4, 0),
		"samples": [Vector2i(4, 2)],
		"blocked": [Vector2i(1, 4), Vector2i(2, 3), Vector2i(3, 3)],
		"hint": "الممر السفلي مغلق. ابحث عن طريق آمن حول الصخور."
	},
	{
		"id": "route_03",
		"title": "عينتان للمرصد",
		"start": Vector2i(0, 4),
		"goal": Vector2i(4, 0),
		"samples": [Vector2i(2, 1), Vector2i(4, 3)],
		"blocked": [Vector2i(1, 3), Vector2i(1, 1), Vector2i(3, 1), Vector2i(3, 3)],
		"hint": "اجمع العينتين أولاً، ثم أعد الروفر إلى محطة الاتصال."
	}
]

var _state: Dictionary = {}
var _level_index := 0
var _commands: Array[String] = []
var _display_position := Vector2i.ZERO
var _display_samples: Array[Vector2i] = []
var _board_labels: Array[Label] = []
var _level_label: Label
var _hint_label: Label
var _commands_label: Label
var _feedback_label: Label
var _next_button: Button


func _ready() -> void:
	_state = _load_state()
	_level_index = _first_incomplete_level()
	_build_interface()
	_reset_preview()
	_update_interface()


func get_level_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for level in LEVELS:
		ids.append(str(level["id"]))
	return ids


func get_current_level_id() -> String:
	if _level_index >= LEVELS.size():
		return ""
	return str(LEVELS[_level_index]["id"])


func get_completed_level_ids() -> PackedStringArray:
	return PackedStringArray(_state.get("completed_level_ids", []))


func get_command_count() -> int:
	return _commands.size()


func get_current_position() -> Vector2i:
	return _display_position


func is_all_levels_completed() -> bool:
	return get_completed_level_ids().size() == LEVELS.size()


func add_command(command_id: String) -> bool:
	if not COMMANDS.has(command_id) or _level_index >= LEVELS.size() or _commands.size() >= MAX_COMMANDS:
		return false
	_commands.append(command_id)
	_reset_preview()
	_update_interface()
	return true


func remove_last_command() -> bool:
	if _commands.is_empty():
		return false
	_commands.pop_back()
	_reset_preview()
	_update_interface()
	return true


func clear_commands() -> void:
	_commands.clear()
	_reset_preview()
	_update_interface()


func execute_program() -> bool:
	if _level_index >= LEVELS.size() or _commands.is_empty():
		_set_feedback("أضف أوامر الحركة أولاً، ثم شغّل البرنامج.")
		return false

	var level: Dictionary = LEVELS[_level_index]
	var position: Vector2i = level["start"]
	var found_samples: Array[Vector2i] = []
	for command_id in _commands:
		position += _command_delta(command_id)
		if not _inside_grid(position) or (level["blocked"] as Array).has(position):
			_display_position = position - _command_delta(command_id)
			_display_samples = found_samples.duplicate()
			_set_feedback("هذا الطريق غير متاح. عدّل الأوامر وجرب طريقاً آخر؛ لا يوجد أي عقاب.")
			_update_board()
			return false
		if (level["samples"] as Array).has(position) and not found_samples.has(position):
			found_samples.append(position)

	_display_position = position
	_display_samples = found_samples.duplicate()
	if position != level["goal"]:
		_set_feedback("وصل الروفر إلى نقطة آمنة، لكنه لم يصل إلى محطة سَنا بعد. أضف أو عدّل الأوامر.")
		_update_board()
		return false
	if found_samples.size() != (level["samples"] as Array).size():
		_set_feedback("وصل الروفر إلى المحطة، لكن بقيت عينة لم تُجمع. خطّط مساراً يمر بها.")
		_update_board()
		return false

	var completed: Array = _state.get("completed_level_ids", [])
	var level_id := str(level["id"])
	if not completed.has(level_id):
		completed.append(level_id)
	_state["completed_level_ids"] = completed
	if not _save_state():
		completed.erase(level_id)
		_state["completed_level_ids"] = completed
		_set_feedback("تعذّر حفظ المرحلة. بقيت المحاولة متاحة ويمكنك تشغيلها مجدداً.")
		return false

	if is_all_levels_completed():
		_level_index = LEVELS.size()
	_set_feedback("نجحت المهمة! جمع الروفر العينات وعاد إلى محطة سَنا. أحسنت التخطيط!")
	_update_interface()
	return true


func next_level() -> bool:
	if _level_index >= LEVELS.size() or not get_completed_level_ids().has(get_current_level_id()):
		return false
	_level_index = _first_incomplete_level()
	_commands.clear()
	_reset_preview()
	_update_interface()
	return _level_index < LEVELS.size()


func _first_incomplete_level() -> int:
	var completed: Array = _state.get("completed_level_ids", [])
	for index in range(LEVELS.size()):
		if not completed.has(str(LEVELS[index]["id"])):
			return index
	return LEVELS.size()


func _command_delta(command_id: String) -> Vector2i:
	match command_id:
		"up":
			return Vector2i(0, -1)
		"right":
			return Vector2i(1, 0)
		"down":
			return Vector2i(0, 1)
		"left":
			return Vector2i(-1, 0)
	return Vector2i.ZERO


func _inside_grid(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < GRID_SIZE and position.y >= 0 and position.y < GRID_SIZE


func _reset_preview() -> void:
	if _level_index >= LEVELS.size():
		return
	_display_position = LEVELS[_level_index]["start"]
	_display_samples.clear()


func _load_state() -> Dictionary:
	var defaults := {"version": SAVE_VERSION, "completed_level_ids": []}
	if not FileAccess.file_exists(SAVE_PATH):
		return defaults
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return defaults
	var result: Array = []
	for level in LEVELS:
		var level_id := str(level["id"])
		if (parsed.get("completed_level_ids", []) as Array).has(level_id):
			result.append(level_id)
	return {"version": SAVE_VERSION, "completed_level_ids": result}


func _save_state() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_state))
	file.close()
	return true


func _build_interface() -> void:
	theme = preload("res://themes/arabic_theme.tres")
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _new_label("مهمة الروفر: خطّط الطريق", 25, Color(0.95, 0.97, 1.0), true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _new_button("العودة إلى القاعدة", Callable(self, "_return_to_builder"), Vector2(180.0, 48.0))
	header.add_child(back)

	_level_label = _new_label("", 18, Color(1.0, 0.81, 0.42), true)
	layout.add_child(_level_label)
	_hint_label = _new_label("", 16, Color(0.76, 0.86, 0.96))
	layout.add_child(_hint_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(center)
	var board_panel := PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(board_panel)
	var board := GridContainer.new()
	board.name = "RouteBoard"
	board.columns = GRID_SIZE
	board.add_theme_constant_override("h_separation", 5)
	board.add_theme_constant_override("v_separation", 5)
	board_panel.add_child(board)
	for index in range(GRID_SIZE * GRID_SIZE):
		var cell_panel := PanelContainer.new()
		cell_panel.custom_minimum_size = Vector2(66.0, 58.0)
		cell_panel.add_theme_stylebox_override("panel", _tile_style(Color(0.075, 0.12, 0.20)))
		board.add_child(cell_panel)
		var cell_label := _new_label("·", 23, Color(0.72, 0.82, 0.92), true)
		cell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell_panel.add_child(cell_label)
		_board_labels.append(cell_label)

	_commands_label = _new_label("الأوامر: —", 18, Color(0.58, 0.85, 0.98), true)
	layout.add_child(_commands_label)

	var command_row := HBoxContainer.new()
	command_row.alignment = BoxContainer.ALIGNMENT_CENTER
	command_row.add_theme_constant_override("separation", 8)
	layout.add_child(command_row)
	for command_id in COMMANDS:
		var command_button := _new_button(
			str(COMMAND_GLYPHS[command_id]),
			func() -> void: add_command(command_id),
			Vector2(66.0, 52.0)
		)
		command_row.add_child(command_button)
	var undo_button := _new_button("تراجع", Callable(self, "remove_last_command"), Vector2(90.0, 52.0))
	command_row.add_child(undo_button)
	var clear_button := _new_button("مسح", Callable(self, "clear_commands"), Vector2(82.0, 52.0))
	command_row.add_child(clear_button)
	var run_button := _new_button("شغّل الروفر", Callable(self, "execute_program"), Vector2(150.0, 52.0))
	command_row.add_child(run_button)

	_feedback_label = _new_label("", 16, Color(0.95, 0.84, 0.58))
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_feedback_label)
	_next_button = _new_button("المرحلة التالية", Callable(self, "next_level"), Vector2(190.0, 48.0))
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(_next_button)


func _update_interface() -> void:
	if _level_index >= LEVELS.size():
		_level_label.text = "اكتملت المهمات الثلاث!"
		_hint_label.text = "أصبحت خبير تخطيط مسارات الروفر. يمكنك العودة إلى القاعدة."
		_commands_label.text = "كل المسارات محفوظة."
		_next_button.disabled = true
		_update_board()
		return
	var level: Dictionary = LEVELS[_level_index]
	_level_label.text = "%s  •  المرحلة %d من %d" % [str(level["title"]), _level_index + 1, LEVELS.size()]
	_hint_label.text = str(level["hint"])
	var glyphs := PackedStringArray()
	for command_id in _commands:
		glyphs.append(str(COMMAND_GLYPHS[command_id]))
	_commands_label.text = "الأوامر: " + ("  ".join(glyphs) if not glyphs.is_empty() else "—")
	_next_button.disabled = not get_completed_level_ids().has(str(level["id"]))
	_update_board()


func _update_board() -> void:
	if _level_index >= LEVELS.size():
		return
	var level: Dictionary = LEVELS[_level_index]
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var position := Vector2i(x, y)
			var index := y * GRID_SIZE + x
			var label: Label = _board_labels[index]
			var text_value := "·"
			var color := Color(0.72, 0.82, 0.92)
			var background := Color(0.075, 0.12, 0.20)
			if (level["blocked"] as Array).has(position):
				text_value = "■"
				color = Color(0.48, 0.54, 0.63)
				background = Color(0.10, 0.13, 0.19)
			elif position == level["goal"]:
				text_value = "س"
				color = Color(0.48, 0.88, 0.68)
				background = Color(0.08, 0.22, 0.18)
			elif (level["samples"] as Array).has(position) and not _display_samples.has(position):
				text_value = "✦"
				color = Color(1.0, 0.82, 0.40)
				background = Color(0.23, 0.17, 0.08)
			if position == _display_position:
				text_value = "ر"
				color = Color(0.46, 0.86, 1.0)
				background = Color(0.08, 0.22, 0.32)
			label.text = text_value
			var panel := label.get_parent() as PanelContainer
			panel.add_theme_stylebox_override("panel", _tile_style(background))
			label.add_theme_color_override("font_color", color)


func _return_to_builder() -> void:
	get_tree().change_scene_to_file("res://scenes/prototypes/showcase_app.tscn")


func _set_feedback(message: String) -> void:
	if is_instance_valid(_feedback_label):
		_feedback_label.text = message


func _new_label(value: String, size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.9))
		label.add_theme_constant_override("outline_size", 1)
	return label


func _new_button(caption: String, callback: Callable, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.07, 0.15, 0.26), Color(0.22, 0.55, 0.78)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.22, 0.35), Color(0.38, 0.72, 0.92)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.13, 0.29, 0.43), Color(0.52, 0.82, 0.96)))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.14, 0.94)
	style.border_color = Color(0.22, 0.52, 0.72, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12)
	return style


func _tile_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.20, 0.34, 0.48, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(3)
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	return style
