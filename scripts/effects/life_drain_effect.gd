extends CardEffect
class_name LifeDrainEffect

# 通用生命吸取效果：对目标造成伤害，并按实际失去的生命给指定单位增加当前生命。
# 增加的生命允许临时超过生命上限，但不会改变 max_health。


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_spell_scaled_amount(source_state, effect_data, game_manager)
	if amount <= 0:
		return

	var recipients := get_drain_recipients(source_state, effect_data, game_manager)
	if recipients.is_empty():
		return

	var damaged_targets: Array[CardState] = []
	for target_state in get_target_states(source_state, effect_data, game_manager):
		var drained_amount := drain_from_target(target_state, amount)
		if drained_amount <= 0:
			continue

		damaged_targets.append(target_state)
		for recipient in recipients:
			recipient.gain_temporary_health(drained_amount)
			if game_manager != null and game_manager.has_method("play_effect_heal_animation"):
				await game_manager.play_effect_heal_animation(recipient)

	if not damaged_targets.is_empty() and game_manager != null and game_manager.has_method("resolve_dead_states"):
		var death_reason := EffectData.get_death_reason(effect_data)
		await game_manager.resolve_dead_states(
			damaged_targets,
			death_reason,
			source_state,
			EffectData.get_effect_owner_id(effect_data)
		)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if get_amount(effect_data) <= 0:
		return false
	if get_drain_recipients(source_state, effect_data, game_manager).is_empty():
		return false
	if EffectData.get_target(effect_data) == EffectData.TARGET_SELECTED and EffectData.get_selected_target_state(effect_data) == null:
		return true
	return not get_target_states(source_state, effect_data, game_manager).is_empty()


func drain_from_target(target_state: CardState, amount: int) -> int:
	if target_state == null or amount <= 0:
		return 0

	var previous_health := target_state.current_health
	target_state.take_damage(amount)
	return maxi(previous_health - target_state.current_health, 0)


func get_drain_recipients(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id != "":
		return get_owner_cards_by_id(source_state, effect_data, game_manager)

	var recipients: Array[CardState] = []
	if source_state != null:
		recipients.append(source_state)

	return recipients
