extends RefCounted
class_name BoardUnitPairSelectionController

signal slot_selected(slot_index: int)

# BoardUnitPairSelectionController is a small modal selector for effects that
# need exactly two board units after a spell has already been committed.

var _game_manager: GameManager
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _hint_label: Label
var _first_slot := -1
var _active := false
var _valid_slots: Array[int] = []
var _selected_slots: Array[int] = []


func select_unit_pair(
	game_manager: GameManager,
	valid_states: Array[CardState],
	title: String
) -> Array[CardState]:
	var result: Array[CardState] = []
	if game_manager == null or valid_states.size() < 2:
		return result

	_game_manager = game_manager
	_valid_slots = get_valid_slots(valid_states)
	_selected_slots.clear()
	_first_slot = -1
	_active = true

	setup_ui(game_manager.get_parent(), title)
	connect_board_cards()
	set_target_flags()
	update_hint()

	while _active and _selected_slots.size() < 2:
		var slot_index: int = await slot_selected
		if slot_index < 0:
			break

		handle_slot_selected(slot_index)

	for slot_index in _selected_slots:
		var state := _game_manager.get_board_state(slot_index) as CardState
		if state != null:
			result.append(state)

	cleanup()
	return result


func get_valid_slots(valid_states: Array[CardState]) -> Array[int]:
	var slots: Array[int] = []
	for state in valid_states:
		if state != null and not slots.has(state.slot_index):
			slots.append(state.slot_index)
	return slots


func setup_ui(parent: Node, title: String) -> void:
	if parent == null:
		return

	_layer = CanvasLayer.new()
	_layer.name = "BoardUnitPairSelectionLayer"
	_layer.layer = 171
	parent.add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "BoardUnitPairSelectionPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2(420, 88)
	_panel.add_theme_stylebox_override("panel", create_panel_style())
	_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	_title_label = Label.new()
	_title_label.text = title
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72))
	box.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.74, 1.0, 0.62))
	box.add_child(_hint_label)

	position_panel()


func position_panel() -> void:
	if _panel == null or _game_manager == null:
		return

	var viewport_size: Vector2 = _game_manager.get_viewport().get_visible_rect().size
	var panel_size := _panel.custom_minimum_size
	_panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, 24.0)


func connect_board_cards() -> void:
	if _game_manager == null:
		return

	for card in _game_manager.board_cards:
		if card == null:
			continue
		if not card.clicked.is_connected(_on_card_clicked):
			card.clicked.connect(_on_card_clicked)


func disconnect_board_cards() -> void:
	if _game_manager == null:
		return

	for card in _game_manager.board_cards:
		if card == null:
			continue
		if card.clicked.is_connected(_on_card_clicked):
			card.clicked.disconnect(_on_card_clicked)


func _on_card_clicked(card: Card) -> void:
	if not _active or card == null or card.state == null:
		return

	slot_selected.emit(card.state.slot_index)


func handle_slot_selected(slot_index: int) -> void:
	if not is_selectable_slot(slot_index):
		return

	if _first_slot < 0:
		select_first_slot(slot_index)
		return

	if slot_index == _first_slot:
		clear_first_slot()
		update_hint()
		return

	_selected_slots = [_first_slot, slot_index]
	_active = false


func select_first_slot(slot_index: int) -> void:
	clear_first_slot()
	_first_slot = slot_index
	var state := _game_manager.get_board_state(_first_slot) as CardState
	if state != null:
		state.set_selected(true)
	update_hint()


func clear_first_slot() -> void:
	if _first_slot < 0 or _game_manager == null:
		_first_slot = -1
		return

	var state := _game_manager.get_board_state(_first_slot) as CardState
	if state != null:
		state.set_selected(false)
	_first_slot = -1


func is_selectable_slot(slot_index: int) -> bool:
	return _valid_slots.has(slot_index)


func set_target_flags() -> void:
	if _game_manager == null:
		return

	for state in _game_manager.board_states:
		if state != null:
			state.set_valid_target(_valid_slots.has(state.slot_index))


func clear_target_flags() -> void:
	if _game_manager == null:
		return

	for state in _game_manager.board_states:
		if state != null:
			state.set_valid_target(false)


func update_hint() -> void:
	if _hint_label == null:
		return

	if _first_slot >= 0:
		_hint_label.text = "已选择第一个随从。请选择第二个随从建立链接。"
	else:
		_hint_label.text = "请选择两个随从建立同命链接。"


func cleanup() -> void:
	_active = false
	clear_first_slot()
	clear_target_flags()
	disconnect_board_cards()
	if _layer != null:
		_layer.queue_free()
	_layer = null
	_panel = null
	_title_label = null
	_hint_label = null
	_game_manager = null
	_valid_slots.clear()


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.050, 0.032, 0.95)
	style.border_color = Color(0.48, 1.0, 0.38, 0.80)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 12
	return style
