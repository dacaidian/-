extends RefCounted
class_name FactionSkillResolver

const SacrificeFactionSkillActionScript := preload("res://scripts/actions/sacrifice_faction_skill_action.gd")

# FactionSkillResolver 负责把玩家已解锁的种族技能配置转成 CardAction。
# UI 面板只发出 skill_id；GameManager 只委托这里判断可用性和启动目标选择。


func get_usable_skill_ids(game_manager: GameManager, player: PlayerState) -> Array[String]:
	var usable_skill_ids: Array[String] = []
	if game_manager == null or player == null:
		return usable_skill_ids

	for skill_config in player.get_unlocked_faction_skill_configs():
		var skill_id := str(skill_config.get("id", ""))
		if skill_id == "" or not player.can_use_faction_skill(skill_id):
			continue

		var action := create_action(skill_config)
		if action == null:
			continue

		var source_state := get_source_state(game_manager, player)
		if source_state == null:
			continue

		if not action.get_valid_targets(source_state, game_manager).is_empty():
			usable_skill_ids.append(skill_id)

	return usable_skill_ids


func start_skill_selection(game_manager: GameManager, player: PlayerState, skill_id: String) -> bool:
	if game_manager == null or player == null or skill_id == "":
		return false
	if not player.can_use_faction_skill(skill_id):
		return false

	var skill_config: Dictionary = player.faction_skill_configs.get(skill_id, {})
	if skill_config.is_empty():
		return false

	var action := create_action(skill_config)
	if action == null:
		return false

	var source_state := get_source_state(game_manager, player)
	if source_state == null:
		return false

	if action.get_valid_targets(source_state, game_manager).is_empty():
		return false

	var source_hand_index := get_source_hand_index(player, skill_id)
	var source_hand_card_data := HandCardState.get_card_data(player.hand[source_hand_index]) if source_hand_index >= 0 else null
	if source_hand_card_data == null:
		return false

	game_manager.cancel_interaction()
	game_manager.action_registry.register_action(action)
	game_manager.hide_action_menu()
	game_manager.hand_interaction_controller.capture_anchor(
		game_manager.hand_drawer_controller.get_hand_card_control(source_hand_index)
	)
	game_manager.interaction_manager.start_hand_anchored_action_selection(
		action,
		source_state,
		source_hand_card_data,
		player.id,
		source_hand_index,
		game_manager.get_all_board_states(),
		game_manager
	)
	return true


func get_source_hand_index(player: PlayerState, skill_id: String) -> int:
	if player == null or skill_id == "":
		return -1

	for hand_index in range(player.hand.size()):
		var card_data := HandCardState.get_card_data(player.hand[hand_index])
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if EffectData.get_id(effect_data) != EffectData.EFFECT_GRANT_FACTION_SKILLS:
				continue
			if EffectData.get_skill_ids(effect_data).has(skill_id):
				return hand_index

	return -1


func create_action(skill_config: Dictionary) -> CardAction:
	match str(skill_config.get("action_id", skill_config.get("id", ""))):
		"sacrifice":
			return SacrificeFactionSkillActionScript.new().setup(skill_config)
		_:
			return null


func get_source_state(game_manager: GameManager, player: PlayerState) -> CardState:
	if game_manager == null or player == null:
		return null

	for state in game_manager.get_all_board_states():
		if BoardQuery.is_face_up_unit(state) and state.is_owned_by(player.id) and state.is_hero():
			return state

	for state in game_manager.get_all_board_states():
		if BoardQuery.is_face_up_unit(state) and state.is_owned_by(player.id):
			return state

	return null
