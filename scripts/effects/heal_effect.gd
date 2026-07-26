extends CardEffect
class_name HealEffect

# 治疗效果。target 由 CardEffect 统一解释。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var healed_targets: Array[CardState] = []
	var target_states := get_target_states(source_state, effect_data, game_manager)
	var trigger_animation_key := str(effect_data.get(EffectData.KEY_ANIMATION, ""))
	var should_try_multi_target_animation := (
		should_play_trigger_animation(effect_data, game_manager)
		and trigger_animation_key != ""
		and game_manager.has_method("play_multi_target_effect_animation")
	)
	var did_play_multi_target_animation := false
	if should_try_multi_target_animation:
		did_play_multi_target_animation = bool(
			await game_manager.play_multi_target_effect_animation(
				target_states,
				trigger_animation_key
			)
		)

	for target_state in target_states:
		var amount := get_heal_amount_for_target(source_state, target_state, effect_data, game_manager)
		if should_play_trigger_animation(effect_data, game_manager) and not did_play_multi_target_animation:
			await game_manager.play_effect_heal_animation(target_state)
		var healed_amount := target_state.heal(amount)
		if healed_amount <= 0:
			continue

		healed_targets.append(target_state)
		queue_effective_heal_trigger(target_state, healed_amount, source_state, game_manager)

	if not healed_targets.is_empty() and game_manager != null and game_manager.has_method("resolve_queued_triggers"):
		await game_manager.resolve_queued_triggers()


func get_heal_amount_for_target(
	source_state: CardState,
	target_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> int:
	if str(effect_data.get(EffectData.KEY_AMOUNT_SOURCE, "")) == EffectData.AMOUNT_SOURCE_MISSING_HEALTH:
		return target_state.damage_taken if target_state != null else 0

	return get_spell_scaled_amount(source_state, effect_data, game_manager)


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
