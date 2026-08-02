extends RefCounted
class_name BoardMovementResolver

# BoardMovementResolver owns board content movement flows that change layer
# state and may need movement animation. Actions and death resolution call the
# GameManager facade, while this resolver keeps the actual movement sequence in
# one place.

func move_card_content_to_empty_slot(
	game_manager: GameManager,
	from_state: CardState,
	to_state: CardState,
	animation_key := ""
) -> void:
	if game_manager == null or from_state == null or to_state == null:
		return

	if from_state.is_empty() or not to_state.is_empty():
		return

	var involved_slots: Array[int] = [from_state.slot_index, to_state.slot_index]
	await game_manager.ensure_board_slots_visible(involved_slots)
	var from_card: Card = game_manager.get_card_by_slot(from_state.slot_index)
	var to_card: Card = game_manager.get_card_by_slot(to_state.slot_index)
	var moving_snapshot := from_state.create_card_snapshot()
	if from_card == null or to_card == null:
		await _apply_snapshot_without_animation(game_manager, from_state, to_state, moving_snapshot)
		return

	game_manager.is_resolving_card_action = true
	await game_manager.card_animation_controller.play_card_to_empty_slot(
		game_manager,
		from_card,
		to_card,
		game_manager.game_animation_resolver.get_overlay_animation_root(game_manager),
		animation_key
	)
	to_state.apply_card_snapshot(moving_snapshot)
	from_state.clear_card()
	await game_manager.resolve_slot_unit_entered(to_state)
	game_manager.is_resolving_card_action = false
	_refresh_after_move(game_manager)


func move_flying_card_to_slot(
	game_manager: GameManager,
	from_state: CardState,
	to_slot_index: int,
	animation_key := ""
) -> void:
	if game_manager == null or from_state == null or from_state.is_empty() or not from_state.is_flying():
		return

	var from_slot_index := from_state.slot_index
	var source_was_ground_state := from_state == game_manager.get_board_state(from_slot_index)
	var to_state := game_manager.get_aerial_state(to_slot_index)
	if to_state == null or not to_state.is_empty():
		return

	var involved_slots: Array[int] = [from_slot_index, to_slot_index]
	await game_manager.ensure_board_slots_visible(involved_slots)
	var from_card := game_manager.get_card_for_state(from_state)
	var to_card := game_manager.get_card_for_state(to_state)
	var moving_snapshot := from_state.create_card_snapshot()
	if from_card == null or to_card == null:
		to_state.apply_card_snapshot(moving_snapshot)
		from_state.clear_card()
		if source_was_ground_state:
			game_manager.refill_board_slot_from_pool(from_slot_index)
		await game_manager.resolve_slot_unit_entered(to_state)
		_refresh_after_move(game_manager)
		return

	game_manager.is_resolving_card_action = true
	await game_manager.card_animation_controller.play_card_to_empty_slot(
		game_manager,
		from_card,
		to_card,
		game_manager.game_animation_resolver.get_overlay_animation_root(game_manager),
		animation_key
	)
	to_state.apply_card_snapshot(moving_snapshot)
	from_state.clear_card()
	if source_was_ground_state:
		game_manager.refill_board_slot_from_pool(from_slot_index)
	await game_manager.resolve_slot_unit_entered(to_state)
	game_manager.is_resolving_card_action = false
	_refresh_after_move(game_manager)


func promote_ground_flying_to_aerial(game_manager: GameManager, source_state: CardState) -> CardState:
	if game_manager == null or source_state == null or source_state.is_empty() or not source_state.is_flying():
		return source_state

	var aerial_state := game_manager.get_aerial_state(source_state.slot_index)
	if aerial_state == null or not aerial_state.is_empty():
		return source_state

	var moving_snapshot := source_state.create_card_snapshot()
	aerial_state.apply_card_snapshot(moving_snapshot)
	source_state.clear_card()
	game_manager.refill_board_slot_from_pool(source_state.slot_index)
	await game_manager.resolve_slot_unit_entered(aerial_state)
	_refresh_after_move(game_manager)
	return aerial_state


func _apply_snapshot_without_animation(
	game_manager: GameManager,
	from_state: CardState,
	to_state: CardState,
	moving_snapshot: Dictionary
) -> void:
	to_state.apply_card_snapshot(moving_snapshot)
	from_state.clear_card()
	await game_manager.resolve_slot_unit_entered(to_state)
	_refresh_after_move(game_manager)


func _refresh_after_move(game_manager: GameManager) -> void:
	game_manager.refresh_action_available_hints()
	game_manager.refresh_debug_panel()
