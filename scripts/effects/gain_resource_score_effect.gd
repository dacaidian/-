extends CardEffect
class_name GainResourceScoreEffect

# 给玩家增加资源分。默认用于 on_destroyed 这类事件，通过 target 选择得分玩家。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("award_resource_score"):
		return

	var player_id := get_target_player_id(source_state, effect_data, game_manager)
	if player_id == "":
		return

	game_manager.award_resource_score(player_id, get_amount(effect_data))
