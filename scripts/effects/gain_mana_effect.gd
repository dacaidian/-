extends CardEffect
class_name GainManaEffect

# 给玩家增加法力。默认用于 on_destroyed 这类事件，通过 target 选择获得法力的玩家。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null:
		return

	var player := get_target_player(source_state, effect_data, game_manager)
	if player == null:
		return

	player.gain_mana(get_amount(effect_data))
