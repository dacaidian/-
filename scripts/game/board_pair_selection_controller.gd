extends RefCounted
class_name BoardPairSelectionController

signal slot_selected(slot_index: int)

# BoardPairSelectionController runs a temporary multi-step board selection flow.
# It is used by effects that need repeated "select A, select B" pairs, such as
# swapping board slots multiple times.

var _game_manager: GameManager
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _hint_label: Label
var _finish_button: Button
var _first_slot := -1
var _completed_pairs := 0
var _max_pairs := 0
var _active := false
var _swap_animation_key := ""


func select_and_swap_pairs(
	game_manager: GameManager,
	max_pairs: int,
	title: String,
	swap_animation_key := ""
) -> int:
	if game_manager == null or max_pairs <= 0:
		return 0

	_game_manager = game_manager
	_max_pairs = max_pairs
	_completed_pairs = 0
	_first_slot = -1
	_active = true
	if swap_animation_key != "":
		_swap_animation_key = swap_animation_key

	setup_ui(game_manager.get_parent(), title)
	connect_board_cards()
	set_all_targets_enabled(true)
	update_hint()

	while _active and _completed_pairs < _max_pairs:
		var slot_index: int = await slot_selected
		if slot_index < 0:
			break

		await handle_slot_selected(slot_index)

	cleanup()
	return _completed_pairs


func setup_ui(parent: Node, title: String) -> void:
	if parent == null:
		return

	_layer = CanvasLayer.new()
	_layer.name = "BoardPairSelectionLayer"
	_layer.layer = 170
	parent.add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "BoardPairSelectionPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2(380, 96)
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
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
	box.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	box.add_child(_hint_label)

	_finish_button = Button.new()
	_finish_button.text = "完成"
	ApplicationUiStyle.style_inline_button(
		_finish_button,
		ApplicationUiStyle.GOLD,
		true
	)
	_finish_button.pressed.connect(func(): slot_selected.emit(-1))
	box.add_child(_finish_button)

	position_panel()


func position_panel() -> void:
	if _panel == null or _game_manager == null:
		return

	var viewport_size: Vector2 = _game_manager.get_viewport().get_visible_rect().size
	var panel_size := _panel.custom_minimum_size
	_panel.position = Vector2(
		(viewport_size.x - panel_size.x) * 0.5,
		24.0
	)


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

	var first_state := _game_manager.get_board_state(_first_slot) as CardState
	var second_state := _game_manager.get_board_state(slot_index) as CardState
	clear_first_slot()
	if first_state == null or second_state == null:
		update_hint()
		return

	await _game_manager.swap_board_cells(first_state, second_state, _swap_animation_key)
	_completed_pairs += 1
	set_all_targets_enabled(true)
	update_hint()


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
	return (
		_game_manager != null
		and slot_index >= 0
		and slot_index < _game_manager.board_states.size()
	)


func set_all_targets_enabled(enabled: bool) -> void:
	if _game_manager == null:
		return

	for state in _game_manager.board_states:
		if state != null:
			state.set_valid_target(enabled)


func update_hint() -> void:
	if _hint_label == null:
		return

	var remaining := maxi(_max_pairs - _completed_pairs, 0)
	if _first_slot >= 0:
		_hint_label.text = "已选择第一个格子。请选择第二个格子交换。剩余 %d 次。" % remaining
	else:
		_hint_label.text = "请选择两个格子交换。已交换 %d/%d 次。" % [_completed_pairs, _max_pairs]


func cleanup() -> void:
	_active = false
	clear_first_slot()
	set_all_targets_enabled(false)
	disconnect_board_cards()
	if _layer != null:
		_layer.queue_free()
	_layer = null
	_panel = null
	_title_label = null
	_hint_label = null
	_finish_button = null
	_game_manager = null
	_swap_animation_key = ""


func create_panel_style() -> StyleBox:
	return ApplicationUiStyle.create_section_panel_style(
		Color(0.55, 0.45, 1.0, 1.0)
	)
