extends CardEffect
class_name GrantRebornEffect

# Adds one or more reborn charges to target minions.
# A health value of 0 means "revive at full health"; positive values revive
# with that many current health, capped by the unit's max health.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var health_values := EffectData.get_health_values(effect_data)
	if health_values.is_empty():
		health_values.append(maxi(EffectData.get_amount(effect_data), 0))

	for target_state in get_target_states(source_state, effect_data, game_manager):
		if target_state == null or not target_state.is_minion():
			continue

		for health_value in health_values:
			target_state.add_reborn_health_value(health_value)

		if game_manager != null and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, "reborn")


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	for target_state in get_target_states(source_state, effect_data, game_manager):
		if target_state != null and target_state.is_minion():
			return true

	return false
