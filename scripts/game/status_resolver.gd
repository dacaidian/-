extends RefCounted
class_name StatusResolver

# StatusResolver 负责状态生命周期。
# 状态本身存放在 CardState.statuses 中；这里只在回合时点推进临时状态的剩余回合。

func resolve_turn_timing(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return

	for state in game_manager.board_states:
		if not BoardQuery.is_face_up_unit(state):
			continue

		state.expire_statuses_for_turn_timing(trigger, turn_player_id)
