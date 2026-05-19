extends RefCounted

const AICommonScript = preload("res://scripts/ai/ai_common.gd")


func evaluate_and_execute_all(gm: GameManager, difficulty: String) -> void:
	if gm == null or gm.is_game_over:
		return

	var player := gm.get_current_player()
	if player == null:
		return

	var owned: Array = AICommonScript.get_owned_minions(gm, player.id)
	if owned.is_empty():
		return

	owned.sort_custom(func(a: CardState, b: CardState): return AICommonScript.calc_threat_score(a) > AICommonScript.calc_threat_score(b))

	var acted_slots: Array = []

	for minion in owned:
		if gm.is_game_over:
			return
		if acted_slots.has(minion.slot_index):
			continue

		var best: Dictionary = _find_best_action(minion, gm)
		if best["score"] < AICommonScript.MIN_SCORE_THRESHOLD:
			continue

		var final_score: float = AICommonScript.apply_difficulty_noise(best["score"], difficulty)
		if final_score < AICommonScript.MIN_SCORE_THRESHOLD:
			continue

		var action := best["action"] as CardAction
		var target := best["target"] as CardState
		if action == null:
			continue

		gm.is_executing_action = true
		await action.execute(minion, target, gm)
		gm.is_executing_action = false

		acted_slots.append(minion.slot_index)
		gm.refresh_action_available_hints()
		gm.refresh_debug_panel()
		await AICommonScript.await_step_delay(gm)


func _find_best_action(minion: CardState, gm: GameManager) -> Dictionary:
	var best := {"action": null, "target": null, "score": -999.0}
	if minion == null or gm == null:
		return best

	var actions: Array = gm.action_registry.get_available_actions(minion, gm)
	for action in actions:
		if action == null:
			continue
		var targets: Array = action.get_valid_targets(minion, gm)
		for target in targets:
			if target == null:
				continue
			var score: float = _score_action(action, minion, target, gm)
			if score > best["score"]:
				best["action"] = action
				best["target"] = target
				best["score"] = score

	return best


func _score_action(action: CardAction, user: CardState, target: CardState, gm: GameManager) -> float:
	match action.id:
		"move": return _score_move(user, target, gm)
		"attack": return _score_attack(user, target, gm)
		_: return _score_spell(action, user, target, gm) if action.id.begins_with("spell:") else 0.0


func _score_move(user: CardState, target: CardState, gm: GameManager) -> float:
	if user == null or target == null or gm == null:
		return 0.0

	var player := gm.get_current_player()
	if player == null:
		return 0.0

	var is_own_half: bool = _is_slot_in_own_half(target.slot_index, gm.board_columns, gm.players.find(player))
	var new_weight: float = AICommonScript.calc_slot_position_weight(target.slot_index, gm.board_columns, is_own_half)
	var old_half: bool = _is_slot_in_own_half(user.slot_index, gm.board_columns, gm.players.find(player))
	var old_weight: float = AICommonScript.calc_slot_position_weight(user.slot_index, gm.board_columns, old_half)
	var position_delta: float = (new_weight - old_weight) * 2.0

	var toward_enemy := 0.0
	var enemy_minions: Array = AICommonScript.get_enemy_minions(gm, player.id)
	if not enemy_minions.is_empty():
		var old_dist: float = _nearest_distance(user.slot_index, enemy_minions, gm.board_columns)
		var new_dist: float = _nearest_distance(target.slot_index, enemy_minions, gm.board_columns)
		if new_dist < old_dist:
			toward_enemy = 1.5

	var away_from_threat := 0.0
	for enemy in enemy_minions:
		if enemy.current_attack <= 0:
			continue
		if BoardQuery.is_neighbor(user.slot_index, enemy.slot_index, gm.board_columns):
			if not BoardQuery.is_neighbor(target.slot_index, enemy.slot_index, gm.board_columns):
				away_from_threat = 2.0
				break

	return position_delta + toward_enemy + away_from_threat


func _score_attack(user: CardState, target: CardState, gm: GameManager) -> float:
	if user == null or target == null or gm == null:
		return 0.0

	var player := gm.get_current_player()
	if player == null:
		return 0.0

	# 攻击己方单位几乎永远不是正确选择（游戏允许，但 AI 不应这样做）
	if target.owner_id == player.id:
		return -50.0

	var combat: Dictionary = AICommonScript.predict_combat(user, target)
	var score := 0.0
	var threat: float = AICommonScript.calc_threat_score(target)

	score += combat["dealt_to_defender"] * 3.0
	if combat["breaks_divine_shield"]:
		score += 2.0
	if combat["will_kill_defender"]:
		score += threat * 1.2 + 10.0
		if target.is_hero():
			score += 8.0
	else:
		score += threat * 0.3

	var retaliation := int(combat["retaliation_to_attacker"])
	score -= retaliation * 2.0
	if combat["will_kill_attacker"]:
		score *= 0.15

	return score


func _score_spell(action: CardAction, user: CardState, target: CardState, gm: GameManager) -> float:
	var spell_action := action as SpellAction
	if spell_action == null:
		return 0.0

	var player := gm.get_current_player()
	if player == null:
		return 0.0

	var score := 0.0

	for effect_data in spell_action.effects:
		if not effect_data is Dictionary:
			continue
		var effect_id := str(effect_data.get("id", ""))
		var amount := int(effect_data.get("amount", 1))

		if effect_id == "damage":
			score += _score_damage_effect(user, target, amount, gm, player)
		elif effect_id == "heal":
			score += _score_heal_effect(user, target, amount, gm, player)
		elif effect_id == "shield":
			score += _score_shield_effect(target, amount, player)
		elif effect_id == "gain_attack":
			score += _score_buff_effect(target, amount, player)
		elif effect_id == "increase_max_health":
			score += _score_buff_effect(target, amount, player)
		elif effect_id == "apply_status":
			score += _score_apply_status_effect(target, effect_data, player)
		elif effect_id == "gain_resource_score":
			score += amount * 10.0
		elif effect_id == "gain_flips":
			score += amount * 4.0
		elif effect_id == "gain_mana":
			score += amount * 3.0
		elif effect_id == "add_card_to_hand" or effect_id == "choose_card_to_hand":
			score += 4.0
		elif effect_id == "resurrect":
			score += 5.0
		elif effect_id == "play_spell_action":
			score += 3.0
		elif effect_id == "set_attack_to_current_health":
			var new_attack := target.current_health - target.current_attack
			if new_attack > 0:
				score += new_attack * 2.0

	var target_rule := spell_action.target_rule
	if SpellTargetResolver.is_area_rule(target_rule):
		var area_counts: Dictionary = _count_area_hits(spell_action, target, gm, player)
		var enemy_hits: int = area_counts["enemy"]
		var own_hits: int = area_counts["own"]
		# AOE: 命中敌人是收益，误伤己方是代价
		var net_hits: int = maxi(enemy_hits - own_hits * 2, 0)
		var multiplier: float = minf(float(net_hits) * 0.6, 2.5)
		score *= maxf(multiplier, 1.0)

	var spell_power := player.get_spell_power_bonus()
	if spell_power > 0:
		score *= 1.0 + float(spell_power) * 0.15

	return score


func _score_damage_effect(_user: CardState, target: CardState, amount: int, _gm: GameManager, player: PlayerState) -> float:
	if target == null:
		return 0.0
	# 对己方单位造成伤害是严重错误
	if target.owner_id == player.id:
		return -30.0

	var effective := amount
	if target.has_status("divine_shield"):
		effective = 0
	elif target.shield > 0:
		effective = maxi(amount - target.shield, 0)

	var will_kill := effective >= target.current_health
	if will_kill:
		return AICommonScript.calc_threat_score(target) * 1.2 + 10.0
	return effective * 2.5


func _score_heal_effect(_user: CardState, target: CardState, amount: int, _gm: GameManager, player: PlayerState) -> float:
	if target == null:
		return 0.0
	# 治疗只对己方有效
	if target.owner_id != player.id:
		return -10.0

	var missing := target.max_health - target.current_health
	var effective := mini(amount, missing)
	if effective <= 0:
		return 0.0

	var bonus := 3.0 if target.is_hero() else 0.0
	return effective * 2.0 + bonus


func _score_shield_effect(target: CardState, amount: int, player: PlayerState) -> float:
	if target == null or target.owner_id != player.id:
		return -5.0
	return amount * 1.5


func _score_buff_effect(target: CardState, amount: int, player: PlayerState) -> float:
	if target == null or target.owner_id != player.id:
		return -5.0
	return amount * 2.0 + AICommonScript.calc_threat_score(target) * 0.5


func _score_apply_status_effect(target: CardState, effect_data: Dictionary, player: PlayerState) -> float:
	if target == null:
		return 0.0
	var status_id := str(effect_data.get("status_id", ""))
	var is_own := target.owner_id == player.id
	var is_enemy := target.owner_id != "" and target.owner_id != player.id
	var threat: float = AICommonScript.calc_threat_score(target)

	# 冻结: 对敌人是debuff(好)，对己方是debuff(坏)
	if status_id == "freeze":
		if is_enemy:
			return threat * 0.6 + 2.0
		elif is_own:
			return -threat * 0.6 - 2.0
		return 0.0

	# 圣盾: 对己方是buff(好)，对敌人是buff(坏)
	if status_id == "divine_shield":
		if is_own:
			return threat * 0.4 + 2.0
		elif is_enemy:
			return -threat * 0.4 - 2.0
		return 0.0

	# 其他正面状态默认加给己方
	if is_own:
		return 2.0
	return 0.0


func _count_area_hits(action: SpellAction, center_target: CardState, gm: GameManager, player: PlayerState) -> Dictionary:
	var result := {"enemy": 0, "own": 0}
	if center_target == null or gm == null:
		return result

	var dims: Dictionary = SpellTargetResolver.get_area_dimensions(action.target_rule)
	if dims.is_empty():
		result["enemy"] = 1
		return result

	var rows := int(dims.get("rows", 0))
	var cols := int(dims.get("cols", 0))
	if rows <= 0 or cols <= 0:
		result["enemy"] = 1
		return result

	var area_slots: Array = BoardQuery.get_area_slots(center_target.slot_index, rows, cols, gm.board_columns, gm.board_states.size())
	for slot_idx in area_slots:
		var state := gm.get_board_state(slot_idx)
		if state != null and SpellTargetResolver.can_target(action.target_rule, state):
			if state.owner_id == player.id:
				result["own"] += 1
			elif state.owner_id != "":
				result["enemy"] += 1

	return result


func _nearest_distance(slot_index: int, enemy_minions: Array, board_columns: int) -> float:
	var nearest := 9999.0
	for enemy in enemy_minions:
		if enemy == null:
			continue
		var row1: int = slot_index / board_columns
		var col1: int = slot_index % board_columns
		var row2: int = enemy.slot_index / board_columns
		var col2: int = enemy.slot_index % board_columns
		var dist: float = float(abs(row1 - row2) + abs(col1 - col2))
		if dist < nearest:
			nearest = dist
	return nearest


func _is_slot_in_own_half(slot_index: int, board_columns: int, player_index: int) -> bool:
	var total_rows := 5
	var row: int = slot_index / board_columns
	if player_index == 0:
		return row <= 1
	return row >= total_rows - 2
