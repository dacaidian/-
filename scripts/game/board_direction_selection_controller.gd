extends RefCounted
class_name BoardDirectionSelectionController

signal direction_selected(result: SelectionResult)

const DirectionRayTargetResolverScript := preload("res://scripts/game/direction_ray_target_resolver.gd")

# Direction/ray selection is presentation only. DirectionRayTargetResolver owns
# hit legality and stopping behavior so player input and AI evaluate the same ray.

var _game_manager: GameManager
var _request: SelectionRequest
var _target_resolver := DirectionRayTargetResolverScript.new()
var _results_by_direction: Dictionary = {}
var _buttons: Array[Button] = []
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label


func select_direction_result(game_manager: GameManager, request: SelectionRequest) -> SelectionResult:
	_game_manager = game_manager
	_request = request
	if _game_manager == null or _request == null or _request.origin_slot < 0:
		return SelectionResult.cancelled_result(SelectionRequest.KIND_DIRECTION_RAY)

	for result in _target_resolver.get_valid_results(_game_manager, _request):
		if not is_result_visible(result):
			continue
		_results_by_direction[result.direction] = result
	if _results_by_direction.is_empty():
		cleanup()
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

	var input_blocker := ColorRect.new()
	input_blocker.name = "DirectionSelectionInputBlocker"
	input_blocker.color = Color(0.0, 0.02, 0.05, 0.18)
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	input_blocker.position = Vector2.ZERO
	input_blocker.size = root.get_viewport_rect().size
	_layer.add_child(input_blocker)

	_panel = PanelContainer.new()
	_panel.name = "BoardDirectionSelectionPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.position = Vector2(20, 20)
	_panel.custom_minimum_size = Vector2(420, 56)
	_panel.add_theme_stylebox_override("panel", create_panel_style())
	_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_title_label = Label.new()
	_title_label.text = _request.title if _request.title != "" else "选择方向"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.76, 0.92, 1.0, 1.0))
	row.add_child(_title_label)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.focus_mode = Control.FOCUS_NONE
	ApplicationUiStyle.style_inline_button(cancel_button, ApplicationUiStyle.DANGER)
	cancel_button.pressed.connect(handle_cancel_pressed)
	row.add_child(cancel_button)

	for direction in _results_by_direction:
		var target_slot := BoardQuery.get_slot_at_offset(
			_request.origin_slot,
			direction,
			_game_manager.board_columns,
			_game_manager.board_states.size()
		)
		if target_slot < 0 or not _game_manager.is_board_slot_visible(target_slot):
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
	var result := _results_by_direction.get(direction) as SelectionResult
	if result != null:
		direction_selected.emit(result)


func handle_cancel_pressed() -> void:
	direction_selected.emit(SelectionResult.cancelled_result(SelectionRequest.KIND_DIRECTION_RAY))


func mark_origin() -> void:
	if _request.source_state != null:
		_request.source_state.set_selected(true)
		_request.source_state.set_area_preview(true)
		return

	var state := _game_manager.get_board_state(_request.origin_slot)
	if state != null:
		state.set_selected(true)
		state.set_area_preview(true)


func mark_direction_candidates() -> void:
	for direction in _results_by_direction:
		var slot := BoardQuery.get_slot_at_offset(
			_request.origin_slot,
			direction,
			_game_manager.board_columns,
			_game_manager.board_states.size()
		)
		if slot >= 0 and _game_manager.is_board_slot_visible(slot):
			var state := _game_manager.get_board_state(slot)
			if state != null:
				state.set_valid_target(true)

		var result := _results_by_direction.get(direction) as SelectionResult
		if (
			result != null
			and result.hit_state != null
			and _game_manager.is_board_slot_visible(result.hit_state.slot_index)
		):
			result.hit_state.set_valid_target(true)


func mark_ray_preview(direction: Vector2i) -> void:
	clear_ray_preview()
	var result := _results_by_direction.get(direction) as SelectionResult
	if result == null:
		return

	for slot in result.ray_slots:
		if not _game_manager.is_board_slot_visible(slot):
			continue
		var state := _game_manager.get_board_state(slot)
		if state != null:
			state.set_area_preview(true)
	if (
		result.hit_state != null
		and _game_manager.is_board_slot_visible(result.hit_state.slot_index)
	):
		result.hit_state.set_selected(true)


func is_result_visible(result: SelectionResult) -> bool:
	if result == null:
		return false

	var selector_slot := BoardQuery.get_slot_at_offset(
		_request.origin_slot,
		result.direction,
		_game_manager.board_columns,
		_game_manager.board_states.size()
	)
	if selector_slot < 0 or not _game_manager.is_board_slot_visible(selector_slot):
		return false

	return (
		result.hit_state == null
		or _game_manager.is_board_slot_visible(result.hit_state.slot_index)
	)


func clear_ray_preview() -> void:
	if _game_manager == null:
		return
	for state in _game_manager.get_all_board_states():
		if state == null:
			continue
		if state != _request.source_state:
			state.set_selected(false)
		if state.slot_index != _request.origin_slot:
			state.set_area_preview(false)


func clear_marks() -> void:
	if _game_manager == null:
		return
	for state in _game_manager.get_all_board_states():
		if state == null:
			continue
		state.set_selected(false)
		state.set_valid_target(false)
		state.set_area_preview(false)


func cleanup() -> void:
	clear_marks()
	for button in _buttons:
		if button != null:
			button.queue_free()
	_buttons.clear()
	_results_by_direction.clear()
	if _layer != null:
		_layer.queue_free()
	_layer = null
	_panel = null
	_title_label = null
	_game_manager = null
	_request = null


func create_panel_style() -> StyleBox:
	return ApplicationUiStyle.create_section_panel_style(
		Color(0.32, 0.70, 1.0, 1.0)
	)
