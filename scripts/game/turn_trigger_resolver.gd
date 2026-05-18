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
	await resolve_hand_turn_timing_effects(game_manager, trigger, turn_player_id, context)


func get_trigger_sources(game_manager: GameManager, trigger: String) -> Array[CardState]:
	var sources: Array[CardState] = []
	if game_manager == null:
		return sources

	for state in game_manager.board_states:
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
