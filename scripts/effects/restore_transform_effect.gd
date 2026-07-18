extends CardEffect
class_name RestoreTransformEffect

# Ends an active cover transform through CardState's canonical snapshot restore path.
# Evolution transforms remain controlled by duration/death rules and cannot use this effect.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	for target_state in get_target_states(source_state, effect_data, game_manager):
		if not can_restore_target(target_state):
			continue

		var transform_status := target_state.get_transform_status()
		if not target_state.restore_from_transform_status(transform_status):
			continue

		if game_manager != null and game_manager.has_method("refresh_action_available_hints"):
			game_manager.refresh_action_available_hints()
		if game_manager != null and game_manager.has_method("refresh_debug_panel"):
			game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	for target_state in get_target_states(source_state, effect_data, game_manager):
		if can_restore_target(target_state):
			return true

	return false


func can_restore_target(target_state: CardState) -> bool:
	if target_state == null or not target_state.is_cover_transformed():
		return false

	var transform_status := target_state.get_transform_status()
	if transform_status == null:
		return false

	var original_snapshot: Dictionary = transform_status.payload.get("original_snapshot", {})
	return not original_snapshot.is_empty()
