extends RefCounted
class_name HandInteractionController

# HandInteractionController 编排手牌 UI 与手牌使用规则。
# 它不直接执行卡牌效果；真正的手牌规则仍交给 HandPlayResolver。

var hand_play_resolver := HandPlayResolver.new()
var selected_hand_card_control: Control
var selected_hand_card_rect := Rect2()
var selected_hand_card_viewport_size := Vector2.ZERO
var has_selected_hand_card_rect := false


func setup(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.hand_drawer_controller.setup(game_manager, game_manager.hand_drawer_panel_path)
	if not game_manager.hand_drawer_controller.hand_card_clicked.is_connected(_on_hand_card_clicked.bind(game_manager)):
		game_manager.hand_drawer_controller.hand_card_clicked.connect(_on_hand_card_clicked.bind(game_manager))


func update_hand_drawer_view(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	var current_player := game_manager.get_current_player()
	var selected_hand_index := game_manager.interaction_manager.selected_hand_index
	var playable_hand_indices: Array[int] = []
	if current_player != null:
		for hand_index in range(current_player.hand.size()):
			if hand_play_resolver.can_play_hand_card_at(current_player, hand_index, game_manager):
				playable_hand_indices.append(hand_index)

	game_manager.hand_drawer_controller.update(current_player, selected_hand_index, playable_hand_indices)


func update_hand_drawer_selection_state(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	var current_player := game_manager.get_current_player()
	var selected_hand_index := game_manager.interaction_manager.selected_hand_index
	var playable_hand_indices: Array[int] = []
	if current_player != null:
		for hand_index in range(current_player.hand.size()):
			if hand_play_resolver.can_play_hand_card_at(current_player, hand_index, game_manager):
				playable_hand_indices.append(hand_index)

	game_manager.hand_drawer_controller.update_selection_state(selected_hand_index, playable_hand_indices)


func show_action_menu_if_selected(game_manager: GameManager) -> bool:
	if game_manager == null:
		return false

	if game_manager.interaction_manager.selected_hand_card_data == null:
		return false

	var current_player := game_manager.get_current_player()
	var hand_actions := hand_play_resolver.get_available_actions(
		current_player,
		game_manager.interaction_manager.selected_hand_card_data,
		game_manager.interaction_manager.selected_hand_index,
		game_manager
	)
	if hand_actions.is_empty():
		game_manager.hide_action_menu()
		return true

	var hand_card_control := game_manager.hand_drawer_controller.get_hand_card_control(game_manager.interaction_manager.selected_hand_index)
	if hand_card_control == null:
		hand_card_control = selected_hand_card_control
	if hand_card_control != null:
		game_manager.action_menu_controller.show_for_control(hand_card_control, hand_actions)
		return true

	if has_selected_hand_card_rect:
		game_manager.action_menu_controller.show_for_rect(
			selected_hand_card_rect,
			selected_hand_card_viewport_size,
			hand_actions
		)
		return true

	game_manager.hide_action_menu()
	return true


func handle_action_menu_request(game_manager: GameManager, action_id: String) -> bool:
	if game_manager == null:
		return false

	if game_manager.interaction_manager.selected_hand_card_data == null:
		return false

	start_hand_card_action_selection(game_manager, action_id)
	return true


func execute_selected_hand_card(game_manager: GameManager, target_state: CardState) -> void:
	if game_manager == null or game_manager.interaction_manager.selected_hand_card_data == null:
		return

	game_manager.is_executing_action = true
	await hand_play_resolver.execute_selected_hand_card(game_manager, target_state)
	game_manager.is_executing_action = false


func clear_anchor() -> void:
	selected_hand_card_control = null
	has_selected_hand_card_rect = false
	selected_hand_card_rect = Rect2()
	selected_hand_card_viewport_size = Vector2.ZERO


func get_selected_hand_card_rect() -> Rect2:
	if has_selected_hand_card_rect:
		return selected_hand_card_rect

	if selected_hand_card_control != null:
		return selected_hand_card_control.get_global_rect()

	return Rect2()


func _on_hand_card_clicked(card_entry: Variant, source_control: Control, hand_index: int, game_manager: GameManager) -> void:
	if game_manager == null or game_manager.is_game_busy():
		return

	if game_manager.get_current_player() != null and game_manager.get_current_player().is_ai:
		return

	var current_player := game_manager.get_current_player()
	if current_player == null:
		return

	var card_data := game_manager.hand_drawer_controller.get_card_data_from_entry(card_entry)
	if card_data == null:
		return

	game_manager.hide_action_menu()
	capture_anchor(source_control)
	game_manager.interaction_manager.toggle_hand_card_selection(card_data, current_player.id, hand_index, game_manager.get_all_board_states())
	if game_manager.interaction_manager.selected_hand_card_data == null:
		clear_anchor()
	game_manager.update_action_menu_after_layout()


func capture_anchor(source_control: Control) -> void:
	selected_hand_card_control = source_control
	if source_control == null:
		has_selected_hand_card_rect = false
		return

	selected_hand_card_rect = source_control.get_global_rect()
	selected_hand_card_viewport_size = source_control.get_viewport_rect().size
	has_selected_hand_card_rect = true


func start_hand_card_action_selection(game_manager: GameManager, action_id: String) -> void:
	game_manager.hide_action_menu()
	var current_player := game_manager.get_current_player()
	var card_data := game_manager.interaction_manager.selected_hand_card_data
	var did_start := false
	match action_id:
		HandPlayResolver.HAND_CAST_ACTION_ID:
			did_start = await hand_play_resolver.start_cast_target_selection(
				game_manager,
				current_player,
				card_data,
				game_manager.interaction_manager.selected_hand_index
			)
		HandPlayResolver.HAND_PLACE_ACTION_ID:
			did_start = await hand_play_resolver.start_place_target_selection(
				game_manager,
				current_player,
				card_data,
				game_manager.interaction_manager.selected_hand_index
			)
		HandPlayResolver.HAND_EQUIP_ACTION_ID:
			await hand_play_resolver.execute_hand_equipment(
				game_manager,
				current_player,
				card_data,
				game_manager.interaction_manager.selected_hand_index
			)
			did_start = true
		_:
			game_manager.update_action_menu()
			game_manager.refresh_debug_panel()
			return

	if not did_start:
		game_manager.update_action_menu()
		game_manager.refresh_debug_panel()
