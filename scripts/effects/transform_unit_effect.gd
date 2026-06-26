extends CardEffect
class_name TransformUnitEffect

# 通用变身效果。变身会把原形完整快照存入 transform 状态。
# 变身形态本身是全新状态，不继承原状态；恢复原形时恢复原形快照中的状态。
# 进化变身：死亡时正常死亡；持续结束后恢复原形。
# 覆盖变身：死亡时先解除变身并恢复原形。

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var target_data := get_transform_target_data(effect_data, game_manager)
	if target_data == null:
		return

	for target_state in get_target_states(source_state, effect_data, game_manager):
		if target_state == null or not target_state.is_unit():
			continue

		apply_transform(target_state, target_data, effect_data)
		if game_manager != null and game_manager.has_method("refresh_action_available_hints"):
			game_manager.refresh_action_available_hints()
		if game_manager != null and game_manager.has_method("refresh_debug_panel"):
			game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var target_data := get_transform_target_data(effect_data, game_manager)
	if target_data == null:
		return false

	return not get_target_states(source_state, effect_data, game_manager).is_empty()


func get_transform_target_data(effect_data: Dictionary, game_manager: Node) -> CardData:
	if game_manager == null or not game_manager.has_method("get_card_data_by_id"):
		return null

	var transform_card_id := EffectData.get_card_id(effect_data)
	if transform_card_id == "":
		return null

	var target_data := game_manager.get_card_data_by_id(transform_card_id) as CardData
	if target_data == null or not target_data.is_minion():
		return null

	return target_data


func apply_transform(target_state: CardState, target_data: CardData, effect_data: Dictionary) -> void:
	var original_snapshot := target_state.create_card_snapshot()
	var owner_id := target_state.owner_id

	target_state.transform_to_card_data(target_data)
	target_state.owner_id = owner_id
	target_state.is_face_up = true

	var status_effect_data := effect_data.duplicate(true)
	status_effect_data[EffectData.KEY_STATUS_ID] = CardStatus.STATUS_TRANSFORM
	status_effect_data[EffectData.KEY_STATUS_NAME] = str(effect_data.get(EffectData.KEY_STATUS_NAME, "变身"))
	status_effect_data[EffectData.KEY_STATUS_DESCRIPTION] = str(effect_data.get(EffectData.KEY_STATUS_DESCRIPTION, "持续期间变为另一种形态。"))
	status_effect_data[EffectData.KEY_STATUS_TAGS] = [CardStatus.TAG_TRANSFORM, CardStatus.TAG_UNCLEANSEABLE]
	status_effect_data[EffectData.KEY_STATUS_STACK_POLICY] = CardStatus.STACK_POLICY_REPLACE
	status_effect_data[EffectData.KEY_STATUS_PAYLOAD] = {
		"original_snapshot": original_snapshot,
		EffectData.KEY_TRANSFORM_MODE: EffectData.get_transform_mode(effect_data)
	}

	var status := CardStatus.from_effect_data(status_effect_data, target_state, null)
	status.source_owner_id = owner_id
	status.duration_owner_id = status.resolve_duration_owner_id(target_state)
	target_state.add_status(status)
	target_state.state_changed.emit(target_state)
