extends CardEffect
class_name DamageEffect

# Generic damage effect. Target resolution and spell immunity stay in CardEffect.
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_spell_scaled_amount(source_state, effect_data, game_manager)
	var damaged_targets: Array[CardState] = []
	var animation_key := str(effect_data.get(EffectData.KEY_ANIMATION, ""))
	var source_animation_key := str(effect_data.get(EffectData.KEY_SOURCE_ANIMATION, ""))

	if (
		source_animation_key != ""
		and source_state != null
		and game_manager != null
		and game_manager.has_method("play_status_apply_animation")
	):
		await game_manager.play_status_apply_animation(source_state, source_animation_key)

	for target_state in get_target_states(source_state, effect_data, game_manager):
		if (
			animation_key != ""
			and game_manager != null
			and game_manager.has_method("play_status_apply_animation")
		):
			await game_manager.play_status_apply_animation(target_state, animation_key)
		target_state.take_damage(amount)
		damaged_targets.append(target_state)

	if game_manager != null and game_manager.has_method("resolve_dead_states"):
		await game_manager.resolve_dead_states(
			damaged_targets,
			EffectData.get_death_reason(effect_data),
			source_state,
			get_effect_owner_id(source_state, effect_data),
			create_death_slot_claim(source_state, effect_data)
		)


func create_death_slot_claim(source_state: CardState, effect_data: Dictionary) -> Dictionary:
	var raw_claim: Variant = effect_data.get(EffectData.KEY_DEATH_SLOT_REPLACEMENT, {})
	if not raw_claim is Dictionary:
		return {}

	var claim := (raw_claim as Dictionary).duplicate(true)
	if str(claim.get(EffectData.KEY_CARD_ID, "")) == "":
		return {}

	if str(claim.get(EffectData.KEY_SLOT_OWNER, "")) == EffectData.DEATH_SLOT_OWNER_SOURCE:
		claim[EffectData.KEY_OWNER_ID] = get_effect_owner_id(source_state, effect_data)

	claim[EffectData.KEY_PRIORITY] = int(claim.get(EffectData.KEY_PRIORITY, 100))
	claim[EffectData.KEY_DESTINATION_LAYER] = str(
		claim.get(EffectData.KEY_DESTINATION_LAYER, EffectData.BOARD_LAYER_GROUND)
	)
	return claim
