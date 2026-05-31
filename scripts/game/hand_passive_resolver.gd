extends RefCounted
class_name HandPassiveResolver

# HandPassiveResolver 统一解析“在手牌中持续生效”的被动效果。
# 当前支持金手指一类的翻牌上限加成；未来手牌冷却、费用、资源等持续修正也优先放这里。

func refresh_player_passives(player: PlayerState, should_adjust_remaining_flips := false, game_manager: GameManager = null) -> void:
	if player == null:
		return

	var previous_capacity := player.max_flips_per_turn
	var flip_bonus := get_flip_capacity_bonus(player)
	player.set_flip_capacity_bonus(flip_bonus)
	refresh_faction_runtime_cycle_passives(player, game_manager)
	refresh_unit_movement_passives(player, game_manager)
	refresh_unit_keyword_passives(player, game_manager)
	refresh_unit_attack_passives(player, game_manager)
	refresh_unit_attack_speed_passives(player, game_manager)
	refresh_mounted_attack_speed_passives(player, game_manager)
	refresh_faction_skill_passives(player)

	if should_adjust_remaining_flips:
		var delta := player.max_flips_per_turn - previous_capacity
		if delta > 0:
			player.gain_flips(delta)


func get_flip_capacity_bonus(player: PlayerState) -> int:
	var bonus := 0
	if player == null:
		return bonus

	for effect_data in get_hand_passive_effects(player):
		match EffectData.get_id(effect_data):
			EffectData.EFFECT_MODIFY_FLIP_CAPACITY, EffectData.EFFECT_PASSIVE_FLIP_BONUS:
				bonus += EffectData.get_amount(effect_data)

	return bonus


func refresh_faction_skill_passives(player: PlayerState) -> void:
	if player == null:
		return

	var skill_ids: Array[String] = []
	for effect_data in get_hand_passive_effects(player):
		if EffectData.get_id(effect_data) != EffectData.EFFECT_GRANT_FACTION_SKILLS:
			continue

		for skill_id in EffectData.get_skill_ids(effect_data):
			if not skill_ids.has(skill_id):
				skill_ids.append(skill_id)

	player.set_unlocked_faction_skills(skill_ids)


func refresh_faction_runtime_cycle_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null:
		return

	var override_state_ids: Array[String] = []
	var fallback_state_id := ""
	for effect_data in get_hand_passive_effects(player):
		if EffectData.get_id(effect_data) != EffectData.EFFECT_RESTRICT_FACTION_RUNTIME_CYCLE:
			continue

		override_state_ids = EffectData.get_runtime_state_ids(effect_data)
		fallback_state_id = str(effect_data.get(EffectData.KEY_FALLBACK_RUNTIME_STATE_ID, ""))
		break

	var changed := player.set_faction_runtime_state_cycle_override(override_state_ids, fallback_state_id)
	if changed and game_manager != null:
		game_manager.update_faction_time_panel_view()


func is_hand_passive_effect(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	return trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE


func refresh_unit_movement_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var movement_by_card_id := get_unit_movement_overrides(player)
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id:
			continue

		var base_movement := get_origin_movement(state)
		var target_movement: int = base_movement
		if movement_by_card_id.has(state.card_id):
			target_movement = int(movement_by_card_id[state.card_id])

		state.set_max_movement(target_movement, true)


func refresh_unit_keyword_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var keywords_by_card_id := get_unit_keyword_grants(player)
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id:
			continue

		var keywords: Array[String] = []
		var raw_keywords: Variant = keywords_by_card_id.get(state.card_id, [])
		if raw_keywords is Array:
			for keyword in raw_keywords:
				var normalized_keyword := str(keyword)
				if normalized_keyword != "" and not keywords.has(normalized_keyword):
					keywords.append(normalized_keyword)

		state.set_passive_keywords(keywords)


func refresh_unit_attack_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var attack_bonus_by_card_id := get_unit_attack_bonuses(player)
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id:
			continue

		var attack_bonus := 0
		if attack_bonus_by_card_id.has(state.card_id):
			attack_bonus = int(attack_bonus_by_card_id[state.card_id])

		state.set_passive_attack_bonus(attack_bonus)


func refresh_unit_attack_speed_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var attack_speed_bonus_by_card_id := get_unit_attack_speed_bonuses(player)
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id:
			continue

		var base_attack_speed := get_origin_attack_speed(state)
		var attack_speed_bonus := 0
		if attack_speed_bonus_by_card_id.has(state.card_id):
			attack_speed_bonus = int(attack_speed_bonus_by_card_id[state.card_id])

		state.set_max_attack_speed(base_attack_speed + attack_speed_bonus, true)


func refresh_mounted_attack_speed_passives(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var attack_speed_bonus_by_card_id := get_unit_attack_speed_bonuses(player)
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id or state.data == null:
			continue

		for mounted_attack in state.data.mounted_attacks:
			var action_id := EffectData.get_action_id(mounted_attack)
			var rider_card_id := EffectData.get_rider_card_id(mounted_attack)
			if action_id == "":
				continue

			var base_attack_speed := maxi(EffectData.get_attack_speed(mounted_attack), 0)
			var attack_speed_bonus := 0
			if attack_speed_bonus_by_card_id.has(rider_card_id):
				attack_speed_bonus = int(attack_speed_bonus_by_card_id[rider_card_id])

			state.set_mounted_attack_max_uses(action_id, base_attack_speed + attack_speed_bonus, true)


func get_unit_movement_overrides(player: PlayerState) -> Dictionary:
	var movement_by_card_id := {}
	if player == null:
		return movement_by_card_id

	for effect_data in get_hand_passive_effects(player):
		if not is_effect_condition_met(effect_data, player):
			continue
		if EffectData.get_id(effect_data) != EffectData.EFFECT_SET_UNIT_MOVEMENT:
			continue

		var amount := EffectData.get_amount(effect_data)
		for card_id in EffectData.get_card_ids(effect_data):
			if not movement_by_card_id.has(card_id):
				movement_by_card_id[card_id] = amount
			else:
				movement_by_card_id[card_id] = maxi(int(movement_by_card_id[card_id]), amount)

	return movement_by_card_id


func get_unit_keyword_grants(player: PlayerState) -> Dictionary:
	var keywords_by_card_id := {}
	if player == null:
		return keywords_by_card_id

	for effect_data in get_hand_passive_effects(player):
		if not is_effect_condition_met(effect_data, player):
			continue
		if EffectData.get_id(effect_data) != EffectData.EFFECT_GRANT_UNIT_KEYWORDS:
			continue

		var keywords := EffectData.get_keywords(effect_data)
		if keywords.is_empty():
			continue

		for card_id in EffectData.get_card_ids(effect_data):
			if not keywords_by_card_id.has(card_id):
				keywords_by_card_id[card_id] = []

			var merged_keywords: Array[String] = []
			var raw_existing_keywords: Variant = keywords_by_card_id[card_id]
			if raw_existing_keywords is Array:
				for existing_keyword in raw_existing_keywords:
					var normalized_existing_keyword := str(existing_keyword)
					if normalized_existing_keyword != "" and not merged_keywords.has(normalized_existing_keyword):
						merged_keywords.append(normalized_existing_keyword)
			for keyword in keywords:
				if not merged_keywords.has(keyword):
					merged_keywords.append(keyword)
			keywords_by_card_id[card_id] = merged_keywords

	return keywords_by_card_id


func get_unit_attack_bonuses(player: PlayerState) -> Dictionary:
	var attack_bonus_by_card_id := {}
	if player == null:
		return attack_bonus_by_card_id

	for effect_data in get_hand_passive_effects(player):
		if not is_effect_condition_met(effect_data, player):
			continue
		if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_UNIT_ATTACK:
			continue

		var amount := EffectData.get_amount(effect_data)
		for card_id in EffectData.get_card_ids(effect_data):
			attack_bonus_by_card_id[card_id] = int(attack_bonus_by_card_id.get(card_id, 0)) + amount

	return attack_bonus_by_card_id


func get_unit_attack_speed_bonuses(player: PlayerState) -> Dictionary:
	var attack_speed_bonus_by_card_id := {}
	if player == null:
		return attack_speed_bonus_by_card_id

	for effect_data in get_hand_passive_effects(player):
		if not is_effect_condition_met(effect_data, player):
			continue
		if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_UNIT_ATTACK_SPEED:
			continue

		var amount := EffectData.get_amount(effect_data)
		for card_id in EffectData.get_card_ids(effect_data):
			attack_speed_bonus_by_card_id[card_id] = int(attack_speed_bonus_by_card_id.get(card_id, 0)) + amount

	return attack_speed_bonus_by_card_id


func is_effect_condition_met(effect_data: Dictionary, player: PlayerState) -> bool:
	var required_runtime_state_id := str(effect_data.get(EffectData.KEY_REQUIRED_RUNTIME_STATE_ID, ""))
	if required_runtime_state_id != "" and player.faction_runtime_state_id != required_runtime_state_id:
		return false

	var required_resource_id := EffectData.get_required_resource_id(effect_data)
	if required_resource_id != "":
		var required_min := EffectData.get_required_resource_min(effect_data)
		if player.get_faction_resource_value(required_resource_id) < required_min:
			return false

	return true


func get_hand_passive_effects(player: PlayerState) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if player == null:
		return effects

	for card_entry in player.hand:
		var card_data := get_card_data_from_hand_entry(card_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if is_hand_passive_effect(effect_data):
				effects.append(effect_data)

	return effects


func get_origin_movement(state: CardState) -> int:
	if state == null:
		return 0

	return int(state.origin.get("movement", state.max_movement))


func get_origin_attack_speed(state: CardState) -> int:
	if state == null:
		return 0

	return int(state.origin.get("attack_speed", state.max_attack_speed))


func get_card_data_from_hand_entry(card_entry: Variant) -> CardData:
	return HandCardState.get_card_data(card_entry)
