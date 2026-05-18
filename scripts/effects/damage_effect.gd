extends CardEffect
class_name DamageEffect

# 伤害效果。target 由 CardEffect 统一解释，当前支持 self 和施法时注入的 selected。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	# 从 JSON 效果定义里读取伤害数值。
	var amount := get_amount(effect_data)
	var damaged_targets: Array[CardState] = []

	# 对所有目标状态造成伤害。
	for target_state in get_target_states(source_state, effect_data, game_manager):
		target_state.take_damage(amount)
		damaged_targets.append(target_state)

	if game_manager != null and game_manager.has_method("resolve_dead_states"):
		var death_reason := EffectData.get_death_reason(effect_data)
		game_manager.resolve_dead_states(damaged_targets, death_reason, source_state)
