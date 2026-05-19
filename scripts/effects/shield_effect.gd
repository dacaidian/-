extends CardEffect
class_name ShieldEffect

# 护盾效果。target 由 CardEffect 统一解释，当前支持 self 和施法时注入的 selected。


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_spell_scaled_amount(source_state, effect_data, game_manager)

	for target_state in get_target_states(source_state, effect_data, game_manager):
		target_state.gain_shield(amount)
