extends CardEffect
class_name LiberateCardEffect

# Resolves one unique card across every runtime zone. Zone precedence is
# explicit so a malformed duplicate state can never create multiple liberated
# copies from one spell cast.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	var player := get_owner_player(owner_id, game_manager)
	var imprisoned_card_id := EffectData.get_card_id(effect_data)
	var liberated_card_id := EffectData.get_target_card_id(effect_data)
	var liberated_data := get_card_data(liberated_card_id, game_manager)
	if (
		player == null
		or imprisoned_card_id == ""
		or liberated_data == null
		or not liberated_data.is_minion()
	):
		return

	var board_state := find_face_up_owned_card(
		owner_id,
		imprisoned_card_id,
		game_manager
	)
	if board_state != null:
		await liberate_board_state(board_state, liberated_data, player, game_manager)
		return

	var hand_index := find_hand_card_index(player, imprisoned_card_id)
	if hand_index >= 0:
		replace_hand_card(player, hand_index, liberated_data)
		refresh_views(player, game_manager)
		return

	var graveyard_index := find_graveyard_card_index(player, imprisoned_card_id)
	if graveyard_index >= 0:
		player.remove_from_graveyard_at(graveyard_index)
		player.add_to_hand(liberated_data)
		refresh_views(player, game_manager)
		return

	var hidden_state := find_hidden_board_card(imprisoned_card_id, game_manager)
	if hidden_state != null:
		var hidden_slot := hidden_state.slot_index
		hidden_state.clear_card()
		player.add_to_hand(liberated_data)
		if game_manager.has_method("refill_board_slot_from_pool"):
			game_manager.refill_board_slot_from_pool(hidden_slot)
		refresh_views(player, game_manager)
		return

	var card_pool: CardPool = game_manager.card_pool if game_manager is GameManager else null
	if card_pool != null and card_pool.take_first_by_card_id(imprisoned_card_id) != null:
		player.add_to_hand(liberated_data)
		refresh_views(player, game_manager)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	var player := get_owner_player(owner_id, game_manager)
	var imprisoned_card_id := EffectData.get_card_id(effect_data)
	if player == null or imprisoned_card_id == "":
		return false
	if find_face_up_owned_card(owner_id, imprisoned_card_id, game_manager) != null:
		return true
	if find_hand_card_index(player, imprisoned_card_id) >= 0:
		return true
	if find_graveyard_card_index(player, imprisoned_card_id) >= 0:
		return true
	if find_hidden_board_card(imprisoned_card_id, game_manager) != null:
		return true
	return (
		game_manager is GameManager
		and game_manager.card_pool != null
		and game_manager.card_pool.has_card_id(imprisoned_card_id)
	)


func liberate_board_state(
	board_state: CardState,
	liberated_data: CardData,
	player: PlayerState,
	game_manager: Node
) -> void:
	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(
			board_state,
			"symbiote_knull_liberation"
		)
	board_state.transform_to_card_data(liberated_data)
	refresh_views(player, game_manager)


func get_owner_player(owner_id: String, game_manager: Node) -> PlayerState:
	if owner_id == "" or game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null
	return game_manager.get_player_by_id(owner_id) as PlayerState


func get_card_data(card_id: String, game_manager: Node) -> CardData:
	if card_id == "" or game_manager == null or not game_manager.has_method("get_card_data_by_id"):
		return null
	return game_manager.get_card_data_by_id(card_id) as CardData


func find_face_up_owned_card(
	owner_id: String,
	card_id: String,
	game_manager: Node
) -> CardState:
	if game_manager == null or not game_manager.has_method("get_all_board_states"):
		return null
	for board_state in game_manager.get_all_board_states():
		var candidate := board_state as CardState
		if (
			BoardQuery.is_face_up_minion(candidate)
			and candidate.owner_id == owner_id
			and candidate.represents_card_id(card_id)
		):
			return candidate
	return null


func find_hidden_board_card(card_id: String, game_manager: Node) -> CardState:
	if game_manager == null or not game_manager.has_method("get_all_board_states"):
		return null
	for board_state in game_manager.get_all_board_states():
		var candidate := board_state as CardState
		if candidate != null and not candidate.is_empty() and not candidate.is_face_up:
			if candidate.card_id == card_id:
				return candidate
	return null


func find_hand_card_index(player: PlayerState, card_id: String) -> int:
	for index in range(player.hand.size()):
		var card_data := player.get_hand_card_data_at(index)
		if card_data != null and card_data.id == card_id:
			return index
	return -1


func replace_hand_card(player: PlayerState, hand_index: int, card_data: CardData) -> void:
	var hand_state := player.get_hand_card_state_at(hand_index)
	if hand_state != null:
		hand_state.data = card_data
	else:
		player.hand[hand_index] = card_data
	player.state_changed.emit(player)


func find_graveyard_card_index(player: PlayerState, card_id: String) -> int:
	for index in range(player.graveyard.size()):
		var snapshot: Dictionary = player.graveyard[index]
		var origin: Dictionary = snapshot.get("origin", {})
		if str(origin.get("card_id", "")) == card_id:
			return index
	return -1


func refresh_views(player: PlayerState, game_manager: Node) -> void:
	if game_manager.has_method("refresh_hand_passives_for_player"):
		game_manager.refresh_hand_passives_for_player(player, false)
	if game_manager.has_method("update_card_pool_view"):
		game_manager.update_card_pool_view()
	if game_manager.has_method("update_hand_drawer_view"):
		game_manager.update_hand_drawer_view()
	if game_manager.has_method("refresh_action_available_hints"):
		game_manager.refresh_action_available_hints()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()
