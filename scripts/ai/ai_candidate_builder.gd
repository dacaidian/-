extends RefCounted
class_name AICandidateBuilder

const AICommonScript = preload("res://scripts/ai/ai_common.gd")
const AIBoardEvaluatorScript = preload("res://scripts/ai/ai_board_evaluator.gd")
const AIHandEvaluatorScript = preload("res://scripts/ai/ai_hand_evaluator.gd")

const KIND_HAND := "hand"
const KIND_BOARD_ACTION := "board_action"
const KIND_FLIP := "flip"
const KIND_ACTIVATE_SPELL_TURN := "activate_spell_turn"

var _board_evaluator: RefCounted
var _hand_evaluator: RefCounted


func _init() -> void:
	_board_evaluator = AIBoardEvaluatorScript.new()
	_hand_evaluator = AIHandEvaluatorScript.new()


func find_best_candidate(gm: GameManager, difficulty: String, failed_flip_slots: Array[int]) -> Dictionary:
	var best := _empty_candidate()
	if gm == null or gm.is_game_over:
		return best

	var player := gm.get_current_player()
	if player == null:
		return best

	_consider_hand_candidates(best, gm, player, difficulty)
	_consider_activate_spell_turn_candidate(best, gm, player, difficulty)
	_consider_board_action_candidates(best, gm, player, difficulty)
	_consider_flip_candidate(best, gm, player, difficulty, failed_flip_slots)

	return best


func _empty_candidate() -> Dictionary:
	return {
		"kind": "",
		"score": -9999.0,
		"reason": "",
	}


func _consider_candidate(best: Dictionary, candidate: Dictionary, difficulty: String) -> void:
	var raw_score := float(candidate.get("score", -9999.0))
	candidate["score"] = AICommonScript.apply_difficulty_noise(raw_score, difficulty)
	if float(candidate["score"]) > float(best["score"]):
		best.clear()
		for key in candidate:
			best[key] = candidate[key]


func _consider_hand_candidates(best: Dictionary, gm: GameManager, player: PlayerState, difficulty: String) -> void:
	var hpr := gm.get_hand_play_resolver()
	for hand_index in range(player.hand.size()):
		if not player.is_hand_card_available_at(hand_index):
			continue
		if not hpr.can_play_hand_card_at(player, hand_index, gm):
			continue

		var card_data := player.get_hand_card_data_at(hand_index)
		if card_data == null:
			continue

		var evaluation: Dictionary = _hand_evaluator.evaluate_hand_card(card_data, hand_index, player, gm, hpr)
		var score := float(evaluation.get("score", 0.0))
		var target := evaluation.get("target") as CardState
		if card_data.is_spell() and hpr.requires_target(card_data) and target == null:
			continue
		if card_data.is_minion() and target == null:
			continue

		_consider_candidate(best, {
			"kind": KIND_HAND,
			"score": score,
			"card_data": card_data,
			"hand_index": hand_index,
			"target": target,
			"reason": "hand:%s" % card_data.id,
		}, difficulty)


func _consider_board_action_candidates(best: Dictionary, gm: GameManager, player: PlayerState, difficulty: String) -> void:
	for user in AICommonScript.get_owned_minions(gm, player.id):
		if user == null or user.is_empty():
			continue

		var actions: Array = gm.action_registry.get_available_actions(user, gm)
		for action in actions:
			var card_action := action as CardAction
			if card_action == null:
				continue

			if not card_action.requires_target():
				var no_target_score: float = _board_evaluator.score_action(card_action, user, null, gm)
				_consider_candidate(best, {
					"kind": KIND_BOARD_ACTION,
					"score": no_target_score,
					"source": user,
					"action": card_action,
					"target": null,
					"reason": card_action.id,
				}, difficulty)
				continue

			for target in card_action.get_valid_targets(user, gm):
				if target == null:
					continue
				var score: float = _board_evaluator.score_action(card_action, user, target, gm)
				_consider_candidate(best, {
					"kind": KIND_BOARD_ACTION,
					"score": score,
					"source": user,
					"action": card_action,
					"target": target,
					"reason": "%s->%d" % [card_action.id, target.slot_index],
				}, difficulty)


func _consider_activate_spell_turn_candidate(best: Dictionary, gm: GameManager, player: PlayerState, difficulty: String) -> void:
	if gm.is_spell_turn_active:
		return
	if player.mana < gm.spell_turn_mana_cost:
		return

	var best_spell_score := _estimate_best_spell_action_score(gm, player)
	var score: float = best_spell_score - float(gm.spell_turn_mana_cost) * 0.65
	if best_spell_score <= AICommonScript.MIN_SCORE_THRESHOLD:
		return

	_consider_candidate(best, {
		"kind": KIND_ACTIVATE_SPELL_TURN,
		"score": score,
		"reason": "activate_spell_turn",
	}, difficulty)


func _estimate_best_spell_action_score(gm: GameManager, player: PlayerState) -> float:
	var best_score := 0.0
	for user in AICommonScript.get_owned_minions(gm, player.id):
		if user == null:
			continue
		for spell_data in gm.action_registry.get_spell_action_data_for_user(user, gm):
			var action := SpellAction.new().setup(spell_data)
			if not action.can_start(user, gm):
				continue

			if not action.requires_target():
				best_score = maxf(best_score, _board_evaluator.score_action(action, user, null, gm))
				continue

			for target in action.get_valid_targets(user, gm):
				if target == null:
					continue
				best_score = maxf(best_score, _board_evaluator.score_action(action, user, target, gm))

	return best_score


func _consider_flip_candidate(
	best: Dictionary,
	gm: GameManager,
	player: PlayerState,
	difficulty: String,
	failed_flip_slots: Array[int]
) -> void:
	if not player.can_flip_card():
		return
	if player.remaining_flips <= AICommonScript.flip_reserve_count(difficulty):
		return

	var best_flip := find_best_flip_slot(gm, player, failed_flip_slots)
	var slot := int(best_flip.get("slot", -1))
	if slot < 0:
		return

	_consider_candidate(best, {
		"kind": KIND_FLIP,
		"score": 1.0 + float(best_flip.get("score", 0.0)) * 0.4,
		"slot": slot,
		"reason": "flip:%d" % slot,
	}, difficulty)


func find_best_flip_slot(gm: GameManager, player: PlayerState, failed_flip_slots: Array[int]) -> Dictionary:
	var best_slot := -1
	var best_score := -999.0
	if gm == null or player == null:
		return {"slot": best_slot, "score": best_score}

	var player_index := gm.players.find(player)
	for slot in AICommonScript.get_empty_or_hidden_slots(gm):
		if failed_flip_slots.has(slot):
			continue

		var state := gm.get_board_state(slot)
		if state == null:
			continue

		var is_own: bool = _is_slot_in_own_half(slot, gm.board_columns, player_index)
		var score: float = AICommonScript.calc_slot_position_weight(slot, gm.board_columns, is_own)
		var enemy_count := 0
		for adj in BoardQuery.get_adjacent_slots(slot, gm.board_columns, gm.board_states.size()):
			var adj_state := gm.get_board_state(adj)
			if adj_state != null and adj_state.owner_id != "" and adj_state.owner_id != player.id and adj_state.current_attack > 0:
				enemy_count += 1
		score -= float(enemy_count) * 1.5

		if state.data != null:
			if state.data.faction_id == player.faction_id or gm.neutral_faction_ids.has(state.data.faction_id):
				score += AICommonScript.calc_threat_score(state) * 0.5
			else:
				score -= 1.0
		else:
			score -= 0.5

		if score > best_score:
			best_slot = slot
			best_score = score

	return {"slot": best_slot, "score": best_score}


func _is_slot_in_own_half(slot_index: int, board_columns: int, player_index: int) -> bool:
	var total_rows := 5
	var row: int = slot_index / board_columns
	if player_index == 0:
		return row <= 1
	return row >= total_rows - 2
