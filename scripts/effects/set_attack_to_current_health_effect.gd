extends CardEffect
class_name SetAttackToCurrentHealthEffect

# 一次性把目标攻击力设置为施法结算瞬间的当前生命值。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	for target_state in get_target_states(source_state, effect_data, game_manager):
		target_state.set_current_attack(target_state.current_health)
