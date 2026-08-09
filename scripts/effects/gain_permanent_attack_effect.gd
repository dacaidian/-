extends CardEffect
class_name GainPermanentAttackEffect

# Permanently grows a unit's base attack. The absolute value is stored in the
# card state's permanent overrides so heroes keep it through death and revival.
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_amount(effect_data)
	if amount <= 0:
		return

	var animation_key := str(effect_data.get(EffectData.KEY_ANIMATION, ""))
	for target_state in get_target_states(source_state, effect_data, game_manager):
		if (
			animation_key != ""
			and game_manager != null
			and game_manager.has_method("play_status_apply_animation")
		):
			await game_manager.play_status_apply_animation(target_state, animation_key)
		target_state.add_permanent_attack(amount)
