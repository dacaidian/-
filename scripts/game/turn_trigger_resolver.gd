extends RefCounted
class_name TurnTriggerResolver

# TurnTriggerResolver 收集回合时点触发。
# 它只负责“哪些战场牌在这个时点触发”，具体效果仍交给 TriggerResolver / EffectRegistry。

func queue_turn_timing_triggers(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return

	var trigger_sources := get_trigger_sources(game_manager, trigger)
	var context := {
		EventContext.TURN_PLAYER_ID: turn_player_id
	}

	for source_state in trigger_sources:
		game_manager.trigger_resolver.queue_trigger(source_state, trigger, context)

	await game_manager.trigger_resolver.resolve_queued(game_manager)
	await resolve_status_turn_timing_effects(game_manager, trigger, turn_player_id, context)
	await resolve_hand_turn_timing_effects(game_manager, trigger, turn_player_id, context)


func get_trigger_sources(game_manager: GameManager, trigger: String) -> Array[CardState]:
	var sources: Array[CardState] = []
	if game_manager == null:
		return sources

	for state in game_manager.get_all_board_states():
		if not can_source_trigger(state, trigger):
			continue

		sources.append(state)

	sources.sort_custom(sort_by_slot_index)
	return sources


func can_source_trigger(state: CardState, trigger: String) -> bool:
	if state == null or state.is_empty() or not state.is_face_up or state.data == null:
		return false

	for effect_data in state.data.effects:
		if EffectData.get_trigger(effect_data) == trigger:
			return true

	return false


func resolve_hand_turn_timing_effects(
	game_manager: GameManager,
	trigger: String,
	turn_player_id: String,
	context: Dictionary
) -> void:
	var player := game_manager.get_player_by_id(turn_player_id)
	if player == null:
		return

	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null or not card_data.is_upgrade():
			continue

		for effect_data in card_data.effects:
			if not is_hand_turn_timing_effect(effect_data, trigger):
				continue

			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
			await game_manager.effect_registry.execute_effect(null, runtime_effect_data, game_manager)


func resolve_status_turn_timing_effects(
	game_manager: GameManager,
	trigger: String,
	turn_player_id: String,
	context: Dictionary
) -> void:
	for source_state in get_status_trigger_sources(game_manager, trigger, turn_player_id):
		for status in source_state.statuses:
			if status == null:
				continue

			for effect_data in EffectData.get_status_turn_effects(status):
				if not is_status_turn_timing_effect(effect_data, source_state, trigger, turn_player_id):
					continue

				var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
				scale_status_effect_amount_by_stacks(runtime_effect_data, status.stacks)
				await game_manager.effect_registry.execute_effect(source_state, runtime_effect_data, game_manager)


func get_status_trigger_sources(game_manager: GameManager, trigger: String, turn_player_id: String) -> Array[CardState]:
	var sources: Array[CardState] = []
	if game_manager == null:
		return sources

	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_unit(state):
			continue
		if not has_status_turn_timing_effect(state, trigger, turn_player_id):
			continue

		sources.append(state)

	sources.sort_custom(sort_by_slot_index)
	return sources


func has_status_turn_timing_effect(state: CardState, trigger: String, turn_player_id: String) -> bool:
	for status in state.statuses:
		if status == null:
			continue

		for effect_data in EffectData.get_status_turn_effects(status):
			if is_status_turn_timing_effect(effect_data, state, trigger, turn_player_id):
				return true

	return false


func is_status_turn_timing_effect(
	effect_data: Dictionary,
	source_state: CardState,
	trigger: String,
	turn_player_id: String
) -> bool:
	if EffectData.get_trigger(effect_data) != trigger:
		return false

	return is_trigger_player_matched(effect_data, source_state, turn_player_id)


func is_trigger_player_matched(effect_data: Dictionary, source_state: CardState, turn_player_id: String) -> bool:
	match EffectData.get_trigger_player(effect_data):
		EffectData.TRIGGER_PLAYER_SOURCE_OWNER:
			return source_state != null and source_state.owner_id == turn_player_id
		_:
			return true


func scale_status_effect_amount_by_stacks(effect_data: Dictionary, stacks: int) -> void:
	if not effect_data.has(EffectData.KEY_AMOUNT):
		return

	effect_data[EffectData.KEY_AMOUNT] = int(effect_data.get(EffectData.KEY_AMOUNT, 0)) * maxi(stacks, 1)


func is_hand_turn_timing_effect(effect_data: Dictionary, trigger: String) -> bool:
	return (
		EffectData.get_trigger(effect_data) == trigger
		and EffectData.is_active_in_hand(effect_data)
	)


func sort_by_slot_index(first: CardState, second: CardState) -> bool:
	if first == null:
		return false
	if second == null:
		return true

	return first.slot_index < second.slot_index
