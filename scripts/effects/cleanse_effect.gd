extends CardEffect
class_name CleanseEffect

# Removes cleanseable runtime statuses from target units. Today all CardStatus
# instances are cleanseable; future exceptions should be expressed as status
# metadata here, not in individual cards.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var cleansed_targets: Array[CardState] = []
	var cleanse_mode := EffectData.get_cleanse_mode(effect_data)
	for target_state in get_target_states(source_state, effect_data, game_manager):
		var removed_statuses := target_state.cleanse_statuses(cleanse_mode)
		if removed_statuses.is_empty():
			continue

		cleansed_targets.append(target_state)
		remove_link_counterparts(target_state, removed_statuses, game_manager)

	if not cleansed_targets.is_empty() and game_manager != null and game_manager.has_method("resolve_dead_states"):
		await game_manager.resolve_dead_states(
			cleansed_targets,
			EffectData.DEATH_REASON_EFFECT,
			source_state,
			EffectData.get_effect_owner_id(effect_data)
		)


func remove_link_counterparts(target_state: CardState, removed_statuses: Array[CardStatus], game_manager: Node) -> void:
	if target_state == null or game_manager == null:
		return
	if not game_manager.has_method("get_all_board_states"):
		return

	var link_ids: Array[String] = []
	for status in removed_statuses:
		if status == null or not status.tags.has(CardStatus.TAG_DEATH_LINK):
			continue
		var link_id := str(status.payload.get(EffectData.KEY_LINK_ID, ""))
		if link_id != "" and not link_ids.has(link_id):
			link_ids.append(link_id)

	if link_ids.is_empty():
		return

	for state in game_manager.get_all_board_states():
		if state == null or state == target_state:
			continue
		remove_matching_link_statuses(state, link_ids)


func remove_matching_link_statuses(state: CardState, link_ids: Array[String]) -> void:
	for status in state.statuses.duplicate():
		if status == null or not status.tags.has(CardStatus.TAG_DEATH_LINK):
			continue
		var link_id := str(status.payload.get(EffectData.KEY_LINK_ID, ""))
		if link_ids.has(link_id):
			state.remove_status_instance(status)
