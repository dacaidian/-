extends RefCounted
class_name BoardLineSelectionController

signal line_selected(slot_indices: Array[int])

# Two-click board vector selector. The first click chooses the start slot;
# the second click must be exactly line_length - 1 steps away horizontally,
# vertically, or diagonally. The returned line includes both endpoints.

var _game_manager: GameManager
var _request: SelectionRequest
var _line_length := 5
var _direction_mode := BoardQuery.DIRECTIONS_8_WAY
var _first_slot := -1
var _buttons: Array[Button] = []
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _title := ""


func select_line(game_manager: GameManager, line_length := 5, title := "选择一条直线兽径") -> Array[int]:
	var request := SelectionRequest.line_vector(title, line_length)
	var result := await select_line_result(game_manager, request)
	return result.path_slots


func select_line_result(game_manager: GameManager, request: SelectionRequest) -> SelectionResult:
	_game_manager = game_manager
	_request = request
	_line_length = maxi(request.line_length, 2) if request != null else 5
	_direction_mode = request.directions if request != null else BoardQuery.DIRECTIONS_8_WAY
	_title = request.title if request != null and request.title != "" else "选择一条直线"
	_first_slot = -1
	if _game_manager == null:
		return SelectionResult.cancelled_result(SelectionRequest.KIND_LINE_VECTOR)

	setup_ui(_title)
	clear_marks()
	mark_start_candidates()

	var result: Array[int] = await line_selected
	var selection_result := SelectionResult.line_vector_result(
		result[0] if not result.is_empty() else -1,
		result[result.size() - 1] if not result.is_empty() else -1,
		result
	)
	cleanup()
	return selection_result


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
			_title_label.text = "%s：选择终点（必须为横、竖或斜向 %d 格）" % [_title, _line_length]
		return

	if slot_index == _first_slot:
		_first_slot = -1
		clear_marks()
		mark_start_candidates()
		if _title_label != null:
			_title_label.text = "%s：重新选择起点" % _title
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
	return BoardQuery.get_line_end_slots(
		start_slot,
		_line_length,
		_game_manager.board_columns,
		_game_manager.board_states.size(),
		_direction_mode
	)


func get_line_slots(start_slot: int, end_slot: int) -> Array[int]:
	if _game_manager == null:
		return []

	return BoardQuery.get_line_slots(
		start_slot,
		end_slot,
		_line_length,
		_game_manager.board_columns,
		_game_manager.board_states.size(),
		_direction_mode
	)


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
	_game_manager = null
	_request = null


func create_panel_style() -> StyleBox:
	return ApplicationUiStyle.create_section_panel_style(
		Color(0.72, 0.46, 0.16, 1.0)
	)
