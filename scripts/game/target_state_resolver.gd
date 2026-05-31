extends RefCounted
class_name TargetStateResolver

# TargetStateResolver maps the visually clicked card to the rule target.
# This keeps GameManager out of layer-specific targeting decisions: a flying
# card may cover a slot, while the current action may actually target the
# ground layer in that same slot.

func resolve_clicked_target_state(clicked_state: CardState, game_manager: GameManager) -> CardState:
	if clicked_state == null or game_manager == null:
		return null

	var interaction := game_manager.interaction_manager
	if interaction == null:
		return clicked_state

	if interaction.selected_action != null:
		return _resolve_action_target(clicked_state, game_manager, interaction)

	if interaction.selected_hand_card_data != null:
		return _resolve_hand_target(clicked_state, game_manager, interaction)

	return clicked_state


func _resolve_action_target(
	clicked_state: CardState,
	game_manager: GameManager,
	interaction: InteractionManager
) -> CardState:
	var user_state := interaction.selected_action_user_state
	if interaction.selected_action.can_target(user_state, clicked_state, game_manager):
		return clicked_state

	for candidate in game_manager.get_board_states_at_slot(clicked_state.slot_index, true):
		if interaction.selected_action.can_target(user_state, candidate, game_manager):
			return candidate

	return null


func _resolve_hand_target(
	clicked_state: CardState,
	game_manager: GameManager,
	interaction: InteractionManager
) -> CardState:
	var card_data := interaction.selected_hand_card_data
	var hand_action_id := interaction.selected_hand_action_id
	var hand_resolver := game_manager.get_hand_play_resolver()
	var hand_owner := game_manager.get_player_by_id(interaction.selected_hand_owner_id)

	match hand_action_id:
		HandPlayResolver.HAND_CAST_ACTION_ID:
			return _resolve_hand_cast_target(clicked_state, game_manager, hand_resolver, card_data, hand_owner)
		HandPlayResolver.HAND_PLACE_ACTION_ID:
			return _resolve_hand_place_target(clicked_state, game_manager, hand_resolver, card_data)
		_:
			return clicked_state


func _resolve_hand_cast_target(
	clicked_state: CardState,
	game_manager: GameManager,
	hand_resolver: HandPlayResolver,
	card_data: CardData,
	hand_owner: PlayerState
) -> CardState:
	if hand_resolver.can_target(card_data, clicked_state, game_manager, hand_owner):
		return clicked_state

	for candidate in game_manager.get_board_states_at_slot(clicked_state.slot_index, true):
		if hand_resolver.can_target(card_data, candidate, game_manager, hand_owner):
			return candidate

	return null


func _resolve_hand_place_target(
	clicked_state: CardState,
	game_manager: GameManager,
	hand_resolver: HandPlayResolver,
	card_data: CardData
) -> CardState:
	if hand_resolver.can_place_minion_on_target(clicked_state, game_manager, card_data):
		return clicked_state

	for candidate in game_manager.get_board_states_at_slot(clicked_state.slot_index, true):
		if hand_resolver.can_place_minion_on_target(candidate, game_manager, card_data):
			return candidate

	return null
