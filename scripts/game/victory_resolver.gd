extends RefCounted
class_name VictoryResolver

# VictoryResolver 只负责检查胜利条件，不关心资源分来自哪张牌或哪种行为。

func get_winner(players: Array[PlayerState], target_resource_score: int) -> PlayerState:
	if target_resource_score <= 0:
		return null

	for player in players:
		if player != null and player.resource_score >= target_resource_score:
			return player

	return null
