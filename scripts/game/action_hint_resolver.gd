extends RefCounted
class_name ActionHintResolver

# ActionHintResolver 负责计算空闲状态下哪些卡牌应显示“可行动”提示。
# 它只写入 CardState.is_action_available_hint，不改变行动资源或交互状态。


func refresh(
	board_states: Array[CardState],
	current_player: PlayerState,
	interaction_manager: InteractionManager,
	action_registry: ActionRegistry,
	game_manager: GameManager
) -> void:
	var current_player_id := ""
	if current_player != null:
		current_player_id = current_player.id

	var can_show_highlights := (
		interaction_manager != null
		and interaction_manager.mode == InteractionManager.Mode.IDLE
	)

	for state in board_states:
		if state == null:
			continue

		var should_highlight := false
		if can_show_highlights and current_player_id != "" and state.data != null:
			var available_actions: Array[CardAction] = action_registry.get_available_actions(state, game_manager)
			should_highlight = (
				state.is_face_up
				and state.is_minion()
				and state.is_owned_by(current_player_id)
				and not available_actions.is_empty()
			)

		state.set_action_available_hint(should_highlight)
