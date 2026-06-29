extends RefCounted
class_name BoardDirectionSelectionController

signal direction_selected(result: SelectionResult)

# Direction/ray selector. The player chooses one of the valid directions from an
# origin slot; the result contains the ray slots and the first face-up unit hit.

var _game_manager: GameManager
var _request: SelectionRequest
var _buttons: Array[Button] = []
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label


func select_direction_result(game_manager: GameManager, request: SelectionRequest) -> SelectionResult:
	_game_manager = game_manager
	_request = request
	if _game_manager == null or _request == null or _request.origin_slot < 0:
		return SelectionResult.cancelled_result(SelectionRequest.KIND_DIRECTION_RAY)

	setup_ui()
	clear_marks()
	mark_origin()
	mark_direction_candidates()

	var result: SelectionResult = await direction_selected
	cleanup()
	return result


func setup_ui() -> void:
	var root := _game_manager.get_overlay_animation_root()
	if root == null:
		root = _game_manager.get_parent() as Control

	_layer = CanvasLayer.new()
	_layer.name = "BoardDirectionSelectionLayer"
	_layer.layer = 170
	root.add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "BoardDirectionSelectionPanel"
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
	_title_label.text = _request.title if _request.title != "" else "选择方向"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.76, 0.92, 1.0, 1.0))
	margin.add_child(_title_label)

	for direction in _request.get_direction_vectors():
		var target_slot := BoardQuery.get_slot_at_offset(
			_request.origin_slot,
			direction,
			_game_manager.board_columns,
			_game_manager.board_states.size()
		)
		if target_slot < 0:
			continue

		var card := _game_manager.get_card_by_slot(target_slot)
		if card == null:
			continue

		var rect := card.get_global_rect()
		var button := Button.new()
		button.name = "DirectionButton_%d_%d" % [direction.x, direction.y]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.position = rect.position
		button.size = rect.size
		button.modulate = Color(1.0, 1.0, 1.0, 0.01)
		button.mouse_entered.connect(func(): mark_ray_preview(direction))
		button.mouse_exited.connect(clear_ray_preview)
		button.pressed.connect(func(): handle_direction_pressed(direction))
		_layer.add_child(button)
		_buttons.append(button)


func handle_direction_pressed(direction: Vector2i) -> void:
	var ray_slots := BoardQuery.get_ray_slots(
		_request.origin_slot,
		direction,
		_game_manager.board_columns,
		_game_manager.board_states.size(),
		_request.max_distance
	)
	var hit_state := find_first_unit_on_ray(ray_slots)
	var hit_slot := hit_state.slot_index if hit_state != null else -1
	var result := SelectionResult.direction_ray_result(_request.origin_slot, direction, ray_slots, hit_slot, hit_state)
	direction_selected.emit(result)


func mark_origin() -> void:
	var state := _game_manager.get_board_state(_request.origin_slot)
	if state != null:
		state.set_selected(true)
		state.set_area_preview(true)


func mark_direction_candidates() -> void:
	for direction in _request.get_direction_vectors():
		var slot := BoardQuery.get_slot_at_offset(
			_request.origin_slot,
			direction,
			_game_manager.board_columns,
			_game_manager.board_states.size()
		)
		if slot < 0:
			continue
		var state := _game_manager.get_board_state(slot)
		if state != null:
			state.set_valid_target(true)


func mark_ray_preview(direction: Vector2i) -> void:
	clear_ray_preview()
	var ray_slots := BoardQuery.get_ray_slots(
		_request.origin_slot,
		direction,
		_game_manager.board_columns,
		_game_manager.board_states.size(),
		_request.max_distance
	)
	for slot in ray_slots:
		var state := _game_manager.get_board_state(slot)
		if state != null:
			state.set_area_preview(true)


func clear_ray_preview() -> void:
	if _game_manager == null:
		return
	for state in _game_manager.board_states:
		if state != null and state.slot_index != _request.origin_slot:
			state.set_area_preview(false)


func clear_marks() -> void:
	if _game_manager == null:
		return
	for state in _game_manager.board_states:
		if state == null:
			continue
		state.set_selected(false)
		state.set_valid_target(false)
		state.set_area_preview(false)


func find_first_unit_on_ray(ray_slots: Array[int]) -> CardState:
	var candidates: Array[CardState] = _game_manager.board_states
	if _game_manager.has_method("get_all_board_states"):
		candidates = _game_manager.get_all_board_states()

	for slot in ray_slots:
		for state in candidates:
			if state != null and state.slot_index == slot and BoardQuery.is_face_up_unit(state):
				return state

	return null


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


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.08, 0.88)
	style.border_color = Color(0.32, 0.70, 1.0, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 12
	return style
