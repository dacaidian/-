extends CardEffect
class_name IncreaseMaxHealthEffect

# 提高目标生命上限。保持 damage_taken 不变时，当前生命也会随上限同步提高同等数值。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_amount(effect_data)
	if amount <= 0:
		return

	for target_state in get_target_states(source_state, effect_data, game_manager):
		target_state.increase_max_health(amount, false)
