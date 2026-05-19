extends RefCounted
class_name CardEffect

# CardEffect 是所有卡牌效果的基类。
# 具体效果只修改游戏状态，不直接操作 Card 节点或其他 UI。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	pass


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	return true


func get_amount(effect_data: Dictionary) -> int:
	return EffectData.get_amount(effect_data)


func get_target(effect_data: Dictionary) -> String:
	# target 来自 JSON 或运行时动作注入。常用值包括 self、selected。
	return EffectData.get_target(effect_data)


func get_target_player_id(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> String:
	# 玩家目标解析供资源、法力、抽牌等玩家级效果复用。
	var target := get_target(effect_data)

	match target:
		EffectData.TARGET_OWNER:
			return source_state.owner_id if source_state != null else ""
		EffectData.TARGET_DESTROYER:
			return str(effect_data.get(EventContext.DESTROYER_PLAYER_ID, ""))
		EffectData.TARGET_TURN_PLAYER:
			return str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
		EffectData.TARGET_CURRENT_PLAYER:
			if game_manager != null and game_manager.has_method("get_current_player"):
				var current_player := game_manager.get_current_player() as PlayerState
				return current_player.id if current_player != null else ""
			return ""
		_:
			push_warning("暂不支持的玩家效果目标: %s" % target)
			return ""


func get_target_player(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var player_id := get_target_player_id(source_state, effect_data, game_manager)
	if player_id == "":
		return null

	return game_manager.get_player_by_id(player_id) as PlayerState


func get_target_states(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var target := get_target(effect_data)

	match target:
		EffectData.TARGET_SELF:
			if source_state != null:
				return [source_state]
			return []
		EffectData.TARGET_SELECTED:
			var selected_state := EffectData.get_selected_target_state(effect_data)
			if selected_state != null:
				return [selected_state]
			return []
		EffectData.TARGET_ADJACENT_TURN_PLAYER_MINIONS:
			return get_adjacent_turn_player_minions(source_state, effect_data, game_manager)
		EffectData.TARGET_TURN_PLAYER_MINIONS_BY_CARD_IDS:
			return get_turn_player_minions_by_card_ids(effect_data, game_manager)
		EffectData.TARGET_SELECTED_ADJACENT_ENEMY_MINIONS:
			return get_selected_adjacent_enemy_minions(source_state, effect_data, game_manager)
		EffectData.TARGET_OWNER_CARD_BY_ID:
			return get_owner_cards_by_id(source_state, effect_data, game_manager)
		_:
			push_warning("暂不支持的效果目标: %s" % target)
			return []


func get_adjacent_turn_player_minions(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var targets: Array[CardState] = []
	if source_state == null or game_manager == null:
		return targets

	var turn_player_id := str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if turn_player_id == "":
		return targets

	var board_columns: int = int(game_manager.board_columns)
	var board_size: int = game_manager.board_states.size()
	var adjacent_slots := BoardQuery.get_adjacent_slots(source_state.slot_index, board_columns, board_size)

	for slot_index in adjacent_slots:
		var target_state := game_manager.get_board_state(slot_index) as CardState
		if not BoardQuery.is_face_up_minion(target_state):
			continue
		if target_state.owner_id != turn_player_id:
			continue

		targets.append(target_state)

	return targets


func get_turn_player_minions_by_card_ids(effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	var turn_player_id := str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if turn_player_id == "":
		return targets

	var allowed_card_ids := get_card_id_filter(effect_data)
	if allowed_card_ids.is_empty():
		return targets

	for value in game_manager.board_states:
		var target_state := value as CardState
		if not BoardQuery.is_face_up_minion(target_state):
			continue
		if target_state.owner_id != turn_player_id:
			continue
		if not allowed_card_ids.has(target_state.card_id):
			continue

		targets.append(target_state)

	return targets


func get_card_id_filter(effect_data: Dictionary) -> Array[String]:
	return EffectData.get_card_ids(effect_data)


func get_selected_adjacent_enemy_minions(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	var selected_state := EffectData.get_selected_target_state(effect_data)
	if selected_state == null:
		return targets

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		return targets

	var board_columns: int = int(game_manager.board_columns)
	var board_size: int = game_manager.board_states.size()
	var adjacent_slots := BoardQuery.get_adjacent_slots(selected_state.slot_index, board_columns, board_size)

	for slot_index in adjacent_slots:
		var target_state := game_manager.get_board_state(slot_index) as CardState
		if not BoardQuery.is_face_up_minion(target_state):
			continue
		if target_state.owner_id == "" or target_state.owner_id == owner_id:
			continue

		targets.append(target_state)

	return targets


func get_owner_cards_by_id(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	var owner_id := get_effect_owner_id(source_state, effect_data)
	var target_card_id := EffectData.get_target_card_id(effect_data)
	if owner_id == "" or target_card_id == "":
		return targets

	for value in game_manager.board_states:
		var target_state := value as CardState
		if not BoardQuery.is_face_up_unit(target_state):
			continue
		if target_state.owner_id == owner_id and target_state.card_id == target_card_id:
			targets.append(target_state)

	return targets


func get_effect_owner_id(source_state: CardState, effect_data: Dictionary) -> String:
	if source_state != null and source_state.owner_id != "":
		return source_state.owner_id

	return EffectData.get_effect_owner_id(effect_data)
