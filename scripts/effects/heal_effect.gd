extends CardEffect
class_name HealEffect

# 治疗效果。target 由 CardEffect 统一解释。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_amount(effect_data)
	var healed_targets: Array[CardState] = []

	for target_state in get_target_states(source_state, effect_data, game_manager):
		if should_play_trigger_animation(effect_data, game_manager):
			await game_manager.play_effect_heal_animation(target_state)
		var healed_amount := target_state.heal(amount)
		if healed_amount <= 0:
			continue

		healed_targets.append(target_state)
		queue_effective_heal_trigger(target_state, healed_amount, source_state, game_manager)

	if not healed_targets.is_empty() and game_manager != null and game_manager.has_method("resolve_queued_triggers"):
		await game_manager.resolve_queued_triggers()


func queue_effective_heal_trigger(
	target_state: CardState,
	healed_amount: int,
	source_state: CardState,
	game_manager: Node
) -> void:
	if target_state == null or game_manager == null:
		return
	if not game_manager.has_method("queue_card_trigger"):
		return

	var context := {
		EventContext.EFFECTIVE_HEAL_AMOUNT: healed_amount
	}
	if source_state != null:
		context[EventContext.SOURCE_STATE] = source_state

	game_manager.queue_card_trigger(target_state, EventContext.TRIGGER_ON_EFFECTIVE_HEAL, context)


func should_play_trigger_animation(effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null:
		return false

	return EffectData.has_trigger(effect_data)
