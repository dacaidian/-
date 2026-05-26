extends CardEffect
class_name DamageEffect

# 伤害效果。target 由 CardEffect 统一解释，当前支持 self 和施法时注入的 selected。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	# 从 JSON 效果定义里读取伤害数值。
	var amount := get_spell_scaled_amount(source_state, effect_data, game_manager)
	var damaged_targets: Array[CardState] = []
	var animation_key := str(effect_data.get("animation", ""))

	# 对所有目标状态造成伤害。
	for target_state in get_target_states(source_state, effect_data, game_manager):
		if animation_key != "" and game_manager != null and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, animation_key)
		target_state.take_damage(amount)
		damaged_targets.append(target_state)

	if game_manager != null and game_manager.has_method("resolve_dead_states"):
		var death_reason := EffectData.get_death_reason(effect_data)
		game_manager.resolve_dead_states(damaged_targets, death_reason, source_state)
