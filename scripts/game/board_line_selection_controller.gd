extends RefCounted
class_name BoardLineSelectionController

signal line_selected(slot_indices: Array[int])

# Two-click board vector selector. The first click chooses the start slot;
# the second click must be exactly line_length - 1 steps away horizontally,
# vertically, or diagonally. The returned line includes both endpoints.

var _game_manager: GameManager
var _line_length := 5
var _first_slot := -1
var _buttons: Array[Button] = []
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label


func select_line(game_manager: GameManager, line_length := 5, title := "选择一条直线兽径") -> Array[int]:
	_game_manager = game_manager
	_line_length = maxi(line_length, 2)
	_first_slot = -1
	if _game_manager == null:
		return []

	setup_ui(title)
	clear_marks()
	mark_start_candidates()

	var result: Array[int] = await line_selected
	cleanup()
	return result


func setup_ui(title: String) -> void:
	var root := _game_manager.get_overlay_animation_root()
	if root == null:
		root = _game_manager.get_parent() as Control

	_layer = CanvasLayer.new()
	_layer.name = "BoardLineSelectionLayer"
	_layer.layer = 170
	root.add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "BoardLineSelectionPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(20, 20)
	_panel.custom_minimum_size = Vector2(360, 56)
	_panel.add_theme_stylebox_override("panel", create_panel_style())
	_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	_title_label = Label.new()
	_title_label.text = "%s：选择起点" % title
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.50, 1.0))
	margin.add_child(_title_label)

	for slot_index in range(_game_manager.board_states.size()):
		var card := _game_manager.get_card_by_slot(slot_index)
		if card == null:
			continue
		var rect := card.get_global_rect()
		var button := Button.new()
		button.name = "LineSlotButton_%d" % slot_index
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.position = rect.position
		button.size = rect.size
		button.modulate = Color(1.0, 1.0, 1.0, 0.01)
		button.pressed.connect(func(): handle_slot_pressed(slot_index))
		_layer.add_child(button)
		_buttons.append(button)


func handle_slot_pressed(slot_index: int) -> void:
	if _first_slot < 0:
		if get_valid_end_slots(slot_index).is_empty():
			return
		_first_slot = slot_index
		clear_marks()
		mark_first_slot()
		mark_end_candidates()
		if _title_label != null:
			_title_label.text = "兽径：选择终点（必须为横、竖或斜向 %d 格）" % _line_length
		return

	if slot_index == _first_slot:
		_first_slot = -1
		clear_marks()
		mark_start_candidates()
		if _title_label != null:
			_title_label.text = "兽径：重新选择起点"
		return

	var path := get_line_slots(_first_slot, slot_index)
	if path.is_empty():
		return

	clear_marks()
	line_selected.emit(path)


func mark_start_candidates() -> void:
	for slot_index in range(_game_manager.board_states.size()):
		if get_valid_end_slots(slot_index).is_empty():
			continue
		var state := _game_manager.get_board_state(slot_index)
		if state != null:
			state.set_valid_target(true)


func mark_first_slot() -> void:
	var state := _game_manager.get_board_state(_first_slot)
	if state != null:
		state.set_selected(true)
		state.set_area_preview(true)


func mark_end_candidates() -> void:
	for slot_index in get_valid_end_slots(_first_slot):
		var state := _game_manager.get_board_state(slot_index)
		if state != null:
			state.set_valid_target(true)


func clear_marks() -> void:
	if _game_manager == null:
		return

	for state in _game_manager.board_states:
		if state == null:
			continue
		state.set_selected(false)
		state.set_valid_target(false)
		state.set_area_preview(false)


func get_valid_end_slots(start_slot: int) -> Array[int]:
	var slots: Array[int] = []
	for direction in get_line_directions():
		var end_slot := get_slot_at_offset(start_slot, direction * (_line_length - 1))
		if end_slot >= 0:
			slots.append(end_slot)
	return slots


func get_line_slots(start_slot: int, end_slot: int) -> Array[int]:
	if start_slot < 0 or end_slot < 0 or _game_manager == null:
		return []

	var start_row := floori(float(start_slot) / float(_game_manager.board_columns))
	var start_col := start_slot % _game_manager.board_columns
	var end_row := floori(float(end_slot) / float(_game_manager.board_columns))
	var end_col := end_slot % _game_manager.board_columns
	var row_delta := end_row - start_row
	var col_delta := end_col - start_col
	var steps := _line_length - 1

	var is_horizontal := row_delta == 0 and abs(col_delta) == steps
	var is_vertical := col_delta == 0 and abs(row_delta) == steps
	var is_diagonal := abs(row_delta) == steps and abs(col_delta) == steps
	if not (is_horizontal or is_vertical or is_diagonal):
		return []

	var row_step := signi(row_delta)
	var col_step := signi(col_delta)
	var slots: Array[int] = []
	for index in range(_line_length):
		var slot := get_slot_at_row_col(start_row + row_step * index, start_col + col_step * index)
		if slot < 0:
			return []
		slots.append(slot)

	return slots


func get_line_directions() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1)
	]


func get_slot_at_offset(start_slot: int, offset: Vector2i) -> int:
	if _game_manager == null:
		return -1
	var row := floori(float(start_slot) / float(_game_manager.board_columns)) + offset.x
	var col := start_slot % _game_manager.board_columns + offset.y
	return get_slot_at_row_col(row, col)


func get_slot_at_row_col(row: int, col: int) -> int:
	if _game_manager == null:
		return -1
	if row < 0 or col < 0 or row >= _game_manager.board_rows or col >= _game_manager.board_columns:
		return -1

	var slot := row * _game_manager.board_columns + col
	return slot if slot >= 0 and slot < _game_manager.board_states.size() else -1


func signi(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


func cleanup() -> void:
	clear_marks()
	for button in _buttons:
		if button != null:
			button.queue_free()
	_buttons.clear()
	if _layer != null:
		_layer.queue_free()
	_layer = null
	_panel = null
	_title_label = null


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.02, 0.88)
	style.border_color = Color(0.72, 0.46, 0.16, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 12
	return style
