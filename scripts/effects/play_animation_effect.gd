extends CardEffect
class_name PlayAnimationEffect

# A presentation-only step for effect chains that need an explicit visual order.
# Rules select the targets; this effect only forwards the configured semantic key.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null:
		return
	var animation_key := str(effect_data.get(EffectData.KEY_ANIMATION, ""))
	if animation_key == "":
		return

	match EffectData.get_presentation_scope(effect_data):
		EffectData.PRESENTATION_SCOPE_BOARD:
			if game_manager.has_method("play_board_effect_animation"):
				await game_manager.play_board_effect_animation(animation_key)
		EffectData.PRESENTATION_SCOPE_MULTI:
			var targets := get_presentation_targets(source_state, effect_data, game_manager)
			if not targets.is_empty() and game_manager.has_method("play_multi_target_effect_animation"):
				await game_manager.play_multi_target_effect_animation(targets, animation_key)
		EffectData.PRESENTATION_SCOPE_SOURCE_TO_TARGET:
			if source_state == null or not game_manager.has_method("play_spell_cast_animation"):
				return
			for target_state in get_presentation_targets(source_state, effect_data, game_manager):
				await game_manager.play_spell_cast_animation(
					source_state,
					target_state,
					{EffectData.KEY_ANIMATION: animation_key}
				)
		_:
			if not game_manager.has_method("play_status_apply_animation"):
				return
			for target_state in get_presentation_targets(source_state, effect_data, game_manager):
				await game_manager.play_status_apply_animation(target_state, animation_key)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null or str(effect_data.get(EffectData.KEY_ANIMATION, "")) == "":
		return false
	if EffectData.get_presentation_scope(effect_data) == EffectData.PRESENTATION_SCOPE_BOARD:
		return true
	return not get_presentation_targets(source_state, effect_data, game_manager).is_empty()


func get_presentation_targets(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> Array[CardState]:
	var targets := get_target_states(source_state, effect_data, game_manager)
	var required_traits := EffectData.get_target_unit_traits(effect_data)
	if required_traits.is_empty():
		return targets

	var filtered_targets: Array[CardState] = []
	for target_state in targets:
		if target_state == null or target_state.data == null:
			continue
		var has_all_traits := true
		for unit_trait in required_traits:
			if not target_state.data.has_unit_trait(unit_trait):
				has_all_traits = false
				break
		if has_all_traits:
			filtered_targets.append(target_state)
	return filtered_targets
