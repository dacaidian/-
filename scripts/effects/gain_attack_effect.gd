extends CardEffect
class_name GainAttackEffect

# 增加目标当前攻击力。可以读取固定 amount，也可以从触发上下文读取动态数值。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := EffectData.get_contextual_amount(
		effect_data,
		EventContext.EFFECTIVE_HEAL_AMOUNT,
		0
	)
	if amount <= 0:
		return

	for target_state in get_target_states(source_state, effect_data, game_manager):
		target_state.set_current_attack(target_state.current_attack + amount)
