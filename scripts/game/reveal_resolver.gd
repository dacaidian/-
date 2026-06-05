extends RefCounted
class_name RevealResolver

# RevealResolver 负责“翻牌成功之后，这张牌去哪里”的区域路由。
# 它只处理规则分流；具体表现通过 GameManager 的语义化动画入口委托给 UI 控制器。


func can_player_claim_card(game_manager: GameManager, player: PlayerState, state: CardState) -> bool:
	if game_manager == null or player == null or state == null or state.data == null:
		return false

	if game_manager.neutral_faction_ids.has(state.data.faction_id):
		return true

	return state.data.faction_id == player.faction_id


func should_assign_owner_on_reveal(game_manager: GameManager, state: CardState) -> bool:
	if game_manager == null or state == null or state.data == null:
		return false

	if game_manager.neutral_faction_ids.has(state.data.faction_id):
		return state.data.should_enter_hand_when_revealed()

	return true


func resolve_revealed_card(game_manager: GameManager, state: CardState, player: PlayerState) -> void:
	if game_manager == null or state == null or player == null or state.data == null:
		return

	if state.data.should_enter_hand_when_revealed():
		await move_revealed_card_to_hand(game_manager, state, player)
		return

	if state.is_flying() and game_manager.has_method("promote_ground_flying_to_aerial"):
		state = await game_manager.promote_ground_flying_to_aerial(state)
		if state == null or state.is_empty():
			return

	resolve_revealed_board_card(game_manager, state)


func resolve_revealed_board_card(game_manager: GameManager, state: CardState) -> void:
	if state.owner_id != "":
		var owner := game_manager.get_player_by_id(state.owner_id)
		if owner != null:
			game_manager.refresh_hand_passives_for_player(owner, false)

	game_manager.refresh_action_available_hints()

	if state.is_face_up:
		if state.is_minion():
			await game_manager.resolve_slot_unit_entered(state)
			if state.is_empty():
				return

		game_manager.trigger_resolver.queue_trigger(state, EventContext.TRIGGER_ON_ENTER_BOARD)
		game_manager.trigger_resolver.queue_trigger(state, EventContext.TRIGGER_ON_REVEAL)
		await game_manager.trigger_resolver.resolve_queued(game_manager)
		game_manager.check_and_destroy_if_dead(state, "effect")


func move_revealed_card_to_hand(game_manager: GameManager, state: CardState, player: PlayerState) -> void:
	if game_manager == null or state == null or player == null or state.data == null:
		return

	# 区域路由只处理已经成功归属的牌。这里再防护一次，避免未来误调用。
	if not can_player_claim_card(game_manager, player, state):
		return

	var slot_index := state.slot_index
	var source_card := game_manager.get_card_by_slot(slot_index)
	if source_card != null:
		source_card.set_content_temporarily_hidden(true)
		await game_manager.play_card_to_hand_animation(source_card, state.data)

	player.add_to_hand(state.data)
	game_manager.refresh_hand_passives_for_player(player, player == game_manager.get_current_player())
	state.clear_card()
	if source_card != null:
		source_card.set_content_temporarily_hidden(false)

	game_manager.refill_board_slot_from_pool(slot_index)
	game_manager.refresh_action_available_hints()
	game_manager.update_hand_drawer_view()
	game_manager.refresh_debug_panel()
