extends RefCounted
class_name BoardUnitBounceSelectionController

signal state_selected(state: CardState)

var _game_manager: GameManager
var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _hint_label: Label
var _active := false
var _first_state: CardState
var _valid_second_states: Array[CardState] = []


func select_second_unit(
	game_manager: GameManager,
	first_state: CardState,
	valid_second_states: Array[CardState],
	title: String,
	hint: String
) -> CardState:
	if game_manager == null or first_state == null or valid_second_states.is_empty():
		return null

	_game_manager = game_manager
	_first_state = first_state
	_valid_second_states = valid_second_states.duplicate()
	_active = true

	setup_ui(game_manager.get_parent(), title, hint)
	connect_board_cards()
	set_target_flags()

	while _active:
		var selected_state: CardState = await state_selected
		if selected_state == null:
			break
		if not _valid_second_states.has(selected_state):
			continue

		cleanup()
		return selected_state

	cleanup()
	return null


func setup_ui(parent: Node, title: String, hint: String) -> void:
	if parent == null:
		return

	_layer = CanvasLayer.new()
	_layer.name = "BoardUnitBounceSelectionLayer"
	_layer.layer = 172
	parent.add_child(_layer)

	_panel = PanelContainer.new()
	_panel.name = "BoardUnitBounceSelectionPanel"
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
	_title_label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0))
	box.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.text = hint
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0))
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
	for card in _game_manager.aerial_board_cards:
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
	for card in _game_manager.aerial_board_cards:
		if card == null:
			continue
		if card.clicked.is_connected(_on_card_clicked):
			card.clicked.disconnect(_on_card_clicked)


func _on_card_clicked(card: Card) -> void:
	if not _active or card == null or card.state == null:
		return

	state_selected.emit(card.state)


func set_target_flags() -> void:
	if _game_manager == null:
		return

	for state in _game_manager.get_all_board_states():
		if state == null:
			continue
		state.set_selected(state == _first_state)
		state.set_valid_target(_valid_second_states.has(state))


func clear_target_flags() -> void:
	if _game_manager == null:
		return

	for state in _game_manager.get_all_board_states():
		if state == null:
			continue
		state.set_selected(false)
		state.set_valid_target(false)


func cleanup() -> void:
	_active = false
	clear_target_flags()
	disconnect_board_cards()
	if _layer != null:
		_layer.queue_free()
	_layer = null
	_panel = null
	_title_label = null
	_hint_label = null
	_game_manager = null
	_first_state = null
	_valid_second_states.clear()


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.040, 0.070, 0.95)
	style.border_color = Color(0.62, 0.82, 1.0, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 12
	return style
