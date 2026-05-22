extends RefCounted

const STEP_DELAY := 0.45
const MIN_SCORE_THRESHOLD := 0.1


static func calc_slot_position_weight(slot_index: int, board_columns: int, is_own_half: bool) -> float:
	if board_columns <= 0:
		return 0.0

	var center := int(board_columns * board_columns / 2)
	var center_row: int = center / board_columns
	var center_col: int = center % board_columns
	var slot_row: int = slot_index / board_columns
	var slot_col: int = slot_index % board_columns
	var row_dist: int = abs(slot_row - center_row)
	var col_dist: int = abs(slot_col - center_col)
	var max_dist := float(center_row + center_col)
	var dist: float = float(row_dist + col_dist)
	var base := 1.0 - (dist / max_dist) * 0.7
	base = clampf(base, 0.3, 1.0)

	if is_own_half:
		base *= 1.5
	else:
		base *= 0.8

	return clampf(base, 0.15, 1.5)


static func predict_combat(attacker: CardState, defender: CardState) -> Dictionary:
	if attacker == null or defender == null:
		return _empty_combat_result()

	var atk_damage := attacker.current_attack
	var result := _empty_combat_result()

	if defender.has_status("divine_shield"):
		result["breaks_divine_shield"] = true
		result["dealt_to_defender"] = 0
	else:
		var remaining := atk_damage
		if defender.shield > 0:
			var absorbed := mini(defender.shield, remaining)
			result["damage_to_shield"] = absorbed
			remaining -= absorbed
		if remaining > 0:
			result["damage_to_health"] = mini(remaining, defender.current_health)
		result["dealt_to_defender"] = result["damage_to_shield"] + result["damage_to_health"]

	result["will_kill_defender"] = result["damage_to_health"] >= defender.current_health

	var is_melee := not attacker.has_keyword(CardData.KEYWORD_RANGED)
	var retaliation := 0
	if is_melee and defender.current_attack > 0 and not result["will_kill_defender"]:
		retaliation = defender.current_attack
		if attacker.has_status("divine_shield"):
			retaliation = 0
		elif attacker.shield > 0:
			retaliation = maxi(retaliation - attacker.shield, 0)

	result["retaliation_to_attacker"] = retaliation
	result["will_kill_attacker"] = retaliation >= attacker.current_health
	result["attacker_survives"] = not result["will_kill_attacker"]
	return result


static func _empty_combat_result() -> Dictionary:
	return {
		"dealt_to_defender": 0,
		"breaks_divine_shield": false,
		"damage_to_shield": 0,
		"damage_to_health": 0,
		"will_kill_defender": false,
		"retaliation_to_attacker": 0,
		"will_kill_attacker": false,
		"attacker_survives": true
	}


static func calc_threat_score(state: CardState) -> float:
	if state == null or state.is_empty():
		return 0.0

	var threat := state.current_attack * 2.0 + state.max_health * 0.5
	if state.has_keyword(CardData.KEYWORD_RANGED):
		threat *= 1.3
	if state.is_hero():
		threat *= 1.5
	return threat


static func get_owned_minions(gm: GameManager, owner_id: String) -> Array:
	var result: Array = []
	if gm == null:
		return result
	for state in gm.board_states:
		if state == null or state.is_empty():
			continue
		if not state.is_face_up or not state.is_minion():
			continue
		if state.owner_id == owner_id:
			result.append(state)
	return result


static func get_enemy_minions(gm: GameManager, owner_id: String) -> Array:
	var result: Array = []
	if gm == null:
		return result
	for state in gm.board_states:
		if state == null or state.is_empty():
			continue
		if not state.is_face_up or not state.is_minion():
			continue
		if state.owner_id != "" and state.owner_id != owner_id:
			result.append(state)
	return result


static func get_empty_or_hidden_slots(gm: GameManager) -> Array:
	var slots: Array = []
	if gm == null:
		return slots
	for state in gm.board_states:
		if state == null:
			continue
		if gm.has_method("can_place_ground_card_on_slot") and not gm.can_place_ground_card_on_slot(state.slot_index):
			continue
		if state.is_empty() or not state.is_face_up:
			slots.append(state.slot_index)
	return slots


static func apply_difficulty_noise(score: float, difficulty: String) -> float:
	var noise_range := 0.0
	match difficulty:
		"easy": noise_range = 0.20
		"normal": noise_range = 0.05
		_: noise_range = 0.0

	if noise_range <= 0.0:
		return score

	var noise: float = (randf() * 2.0 - 1.0) * noise_range * abs(score)
	return score + noise


static func reserve_threshold(difficulty: String) -> float:
	match difficulty:
		"easy": return 0.0
		"normal": return 0.3
		"hard": return 0.6
		_: return 0.3


static func flip_reserve_count(difficulty: String) -> int:
	match difficulty:
		"hard": return 1
		_: return 0


static func await_step_delay(gm: GameManager) -> void:
	if gm == null:
		return
	var tree := gm.get_tree()
	if tree == null:
		return
	await tree.create_timer(STEP_DELAY).timeout
