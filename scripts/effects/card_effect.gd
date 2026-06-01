extends RefCounted
class_name CardEffect

# CardEffect 是所有卡牌效果的基类。
# 具体效果只修改游戏状态，不直接操作 Card 节点或其他 UI。
func execute(_source_state: CardState, _effect_data: Dictionary, _game_manager: Node) -> void:
	if false:
		await Engine.get_main_loop().process_frame
	pass


func can_execute(_source_state: CardState, _effect_data: Dictionary, _game_manager: Node) -> bool:
	return true


func get_amount(effect_data: Dictionary) -> int:
	return EffectData.get_amount(effect_data)


func get_spell_scaled_amount(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> int:
	var amount := get_amount(effect_data)
	if amount <= 0 or not EffectData.should_apply_spell_power(effect_data):
		return amount

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or game_manager == null or not game_manager.has_method("get_player_by_id"):
		return amount

	var owner := game_manager.get_player_by_id(owner_id) as PlayerState
	if owner == null:
		return amount

	return amount + owner.get_spell_power_bonus()


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
	var targets: Array[CardState] = []

	match target:
		EffectData.TARGET_SELF:
			if source_state != null:
				targets.append(source_state)
		EffectData.TARGET_SELECTED:
			var selected_state := EffectData.get_selected_target_state(effect_data)
			if selected_state != null:
				targets.append(selected_state)
		EffectData.TARGET_ADJACENT_TURN_PLAYER_MINIONS:
			targets = get_adjacent_turn_player_minions(source_state, effect_data, game_manager)
		EffectData.TARGET_TURN_PLAYER_MINIONS_BY_CARD_IDS:
			targets = get_turn_player_minions_by_card_ids(effect_data, game_manager)
		EffectData.TARGET_SELECTED_ADJACENT_ENEMY_MINIONS:
			targets = get_selected_adjacent_enemy_minions(source_state, effect_data, game_manager)
		EffectData.TARGET_OWNER_CARD_BY_ID:
			targets = get_owner_cards_by_id(source_state, effect_data, game_manager)
		EffectData.TARGET_SELECTED_AREA_ENEMY_MINIONS:
			targets = get_selected_area_targets(source_state, effect_data, game_manager, AreaFilter.ENEMY_MINIONS)
		EffectData.TARGET_SELECTED_AREA_ALL_MINIONS:
			targets = get_selected_area_targets(source_state, effect_data, game_manager, AreaFilter.ALL_MINIONS)
		EffectData.TARGET_ATTACK_TARGET_ENEMY_UNIT:
			targets = get_attack_target_enemy_unit(source_state, effect_data)
		EffectData.TARGET_ATTACK_TARGET_ENEMY_MINION:
			targets = get_attack_target_enemy_minion(source_state, effect_data)
		EffectData.TARGET_ATTACK_TARGET_UNIT:
			targets = get_attack_target_unit(effect_data)
		EffectData.TARGET_ENEMY_AND_NEUTRAL_UNITS:
			targets = get_enemy_and_neutral_units(source_state, effect_data, game_manager)
		_:
			push_warning("暂不支持的效果目标: %s" % target)
			targets = []

	return filter_spell_immune_targets(targets, effect_data)


func get_attack_target_unit(effect_data: Dictionary) -> Array[CardState]:
	var targets: Array[CardState] = []
	var attack_target := effect_data.get(EventContext.ATTACK_TARGET_STATE) as CardState
	if BoardQuery.is_face_up_unit(attack_target):
		targets.append(attack_target)

	return targets


func get_attack_target_enemy_unit(source_state: CardState, effect_data: Dictionary) -> Array[CardState]:
	var targets: Array[CardState] = []
	var attack_target := effect_data.get(EventContext.ATTACK_TARGET_STATE) as CardState
	if source_state == null or attack_target == null:
		return targets
	if not BoardQuery.is_face_up_unit(attack_target):
		return targets
	if source_state.owner_id == "" or attack_target.owner_id == "" or source_state.owner_id == attack_target.owner_id:
		return targets

	targets.append(attack_target)
	return targets


func get_attack_target_enemy_minion(source_state: CardState, effect_data: Dictionary) -> Array[CardState]:
	var targets: Array[CardState] = []
	var attack_target := effect_data.get(EventContext.ATTACK_TARGET_STATE) as CardState
	if source_state == null or attack_target == null:
		return targets
	if not BoardQuery.is_face_up_minion(attack_target):
		return targets
	if source_state.owner_id == "" or attack_target.owner_id == "" or source_state.owner_id == attack_target.owner_id:
		return targets

	targets.append(attack_target)
	return targets


func filter_spell_immune_targets(targets: Array[CardState], effect_data: Dictionary) -> Array[CardState]:
	if not EffectData.is_spell_effect(effect_data):
		return targets

	var filtered_targets: Array[CardState] = []
	for target_state in targets:
		if SpellTargetResolver.can_spell_affect(target_state):
			filtered_targets.append(target_state)

	return filtered_targets


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
		for target_state in game_manager.get_board_states_at_slot(slot_index):
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

	for value in game_manager.get_all_board_states():
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
		for target_state in game_manager.get_board_states_at_slot(slot_index):
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
	var target_card_ids := EffectData.get_card_ids(effect_data)
	if target_card_id != "" and not target_card_ids.has(target_card_id):
		target_card_ids.append(target_card_id)

	if owner_id == "" or target_card_ids.is_empty():
		return targets

	for value in game_manager.get_all_board_states():
		var target_state := value as CardState
		if not BoardQuery.is_face_up_unit(target_state):
			continue
		if target_state.owner_id == owner_id and target_card_ids.has(target_state.card_id):
			targets.append(target_state)

	return targets


func get_enemy_and_neutral_units(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		return targets

	for value in game_manager.get_all_board_states():
		var target_state := value as CardState
		if not BoardQuery.is_face_up_unit(target_state):
			continue
		if target_state.owner_id == owner_id:
			continue

		targets.append(target_state)

	return targets


func get_effect_owner_id(source_state: CardState, effect_data: Dictionary) -> String:
	if source_state != null and source_state.owner_id != "":
		return source_state.owner_id

	return EffectData.get_effect_owner_id(effect_data)


enum AreaFilter { ENEMY_MINIONS, ALL_MINIONS }


func get_selected_area_targets(source_state: CardState, effect_data: Dictionary, game_manager: Node, filter_type: AreaFilter) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	var selected_state := EffectData.get_selected_target_state(effect_data)
	if selected_state == null:
		return targets

	var area_rows: int = int(effect_data.get(EffectData.KEY_AREA_ROWS, 3))
	var area_cols: int = int(effect_data.get(EffectData.KEY_AREA_COLS, 3))
	var board_columns: int = int(game_manager.board_columns)
	var board_size: int = game_manager.board_states.size()
	var area_slots := BoardQuery.get_area_slots(selected_state.slot_index, area_rows, area_cols, board_columns, board_size)

	var owner_id := get_effect_owner_id(source_state, effect_data)

	for slot_index in area_slots:
		for target_state in game_manager.get_board_states_at_slot(slot_index):
			if not BoardQuery.is_face_up_minion(target_state):
				continue
			if not SpellTargetResolver.can_spell_affect(target_state):
				continue

			match filter_type:
				AreaFilter.ENEMY_MINIONS:
					if target_state.owner_id == "" or target_state.owner_id == owner_id:
						continue
				AreaFilter.ALL_MINIONS:
					pass

			targets.append(target_state)

	return targets
