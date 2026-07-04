extends CardEffect
class_name DestroyUnitsEffect

# Generic direct-destroy effect for units selected by CardEffect target rules.
# It intentionally goes through DeathResolver so deathrattles, reborn, hero
# revive, refill and score attribution remain consistent.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null:
		return

	var death_reason := EffectData.get_death_reason(effect_data)
	var animation_key := str(effect_data.get("animation", ""))
	for target_state in get_target_states(source_state, effect_data, gm):
		if target_state == null or target_state.is_empty() or not target_state.is_unit():
			continue

		if animation_key != "" and gm.has_method("play_status_apply_animation"):
			await gm.play_status_apply_animation(target_state, animation_key)

		await gm.destroy_card_with_refill(target_state, death_reason, source_state, true)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	if gm == null:
		return false

	for target_state in get_target_states(source_state, effect_data, gm):
		if target_state != null and not target_state.is_empty() and target_state.is_unit():
			return true

	return false
