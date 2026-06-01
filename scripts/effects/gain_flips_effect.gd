extends CardEffect
class_name GainFlipsEffect

# 增加当前玩家本回合剩余翻牌次数。
# 这是玩家资源效果，不需要卡牌目标；后续减少翻牌或提高基础翻牌上限可扩展为独立效果。


func execute(_source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("get_current_player"):
		return

	var current_player := game_manager.get_current_player() as PlayerState
	if current_player == null:
		return

	current_player.gain_flips(get_amount(effect_data))
