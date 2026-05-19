extends RefCounted

const AICommonScript = preload("res://scripts/ai/ai_common.gd")
const AIBoardEvaluatorScript = preload("res://scripts/ai/ai_board_evaluator.gd")
const AIHandEvaluatorScript = preload("res://scripts/ai/ai_hand_evaluator.gd")

var _board_evaluator: RefCounted
var _hand_evaluator: RefCounted


func _init() -> void:
	_board_evaluator = AIBoardEvaluatorScript.new()
	_hand_evaluator = AIHandEvaluatorScript.new()


func run_turn(gm: GameManager) -> void:
	if gm == null or gm.is_game_over:
		return

	var player := gm.get_current_player()
	if player == null or not player.is_ai:
		return

	await _play_hand_cards(gm)
	if gm.is_game_over:
		return

	await _execute_board_actions(gm)
	if gm.is_game_over:
		return

	await _flip_cards(gm)
	if gm.is_game_over:
		return

	gm.end_turn()


func _play_hand_cards(gm: GameManager) -> void:
	var player := gm.get_current_player()
	if player == null:
		return
	await _hand_evaluator.evaluate_and_play_all(gm, player.ai_difficulty)


func _execute_board_actions(gm: GameManager) -> void:
	var player := gm.get_current_player()
	if player == null:
		return
	await _board_evaluator.evaluate_and_execute_all(gm, player.ai_difficulty)


func _flip_cards(gm: GameManager) -> void:
	var player := gm.get_current_player()
	if player == null or not player.can_flip_card():
		return

	var difficulty := player.ai_difficulty
	var reserve_capacity: int = AICommonScript.flip_reserve_count(difficulty)
	var reveal_resolver = gm.reveal_resolver
	var failed_slots: Array = []

	while player.remaining_flips > reserve_capacity:
		if gm.is_game_over:
			return

		var hidden_slots: Array = AICommonScript.get_empty_or_hidden_slots(gm)
		# Exclude slots that already failed this turn (enemy faction flips back)
		for failed in failed_slots:
			hidden_slots.erase(failed)
		if hidden_slots.is_empty():
			break

		var best: Dictionary = _best_flip_slot(hidden_slots, gm, player)
		if best["slot"] < 0:
			break

		var slot := best["slot"] as int
		var state := gm.get_board_state(slot)
		if state == null:
			break

		gm.is_resolving_card_action = true
		player.spend_flip()

		# Fill empty slot from pool before flipping
		if state.is_empty():
			gm.draw_card_to_slot(slot)
			if state.is_empty():
				gm.is_resolving_card_action = false
				continue

		var card: Card = gm.get_card_by_slot(slot)

		# Flip face-up
		if card != null:
			await card.play_flip_animation(Callable(state, "set_face_up").bind(true))
		else:
			state.set_face_up(true)

		# Check faction claim — same gate as human _on_card_clicked
		if not reveal_resolver.can_player_claim_card(gm, player, state):
			if card != null:
				await card.play_flip_animation(Callable(state, "set_face_up").bind(false))
			else:
				state.set_face_up(false)
			failed_slots.append(slot)
			gm.is_resolving_card_action = false
			gm.refresh_debug_panel()
			continue

		if reveal_resolver.should_assign_owner_on_reveal(gm, state):
			state.set_owner(player.id)

		await reveal_resolver.resolve_revealed_card(gm, state, player)

		gm.is_resolving_card_action = false
		gm.update_card_pool_view()
		gm.refresh_action_available_hints()
		gm.refresh_debug_panel()

		await AICommonScript.await_step_delay(gm)

		# After flip, evaluate actions for newly acquired minion
		var flipped_state := gm.get_board_state(slot)
		if flipped_state != null and flipped_state.is_face_up and flipped_state.is_minion() and flipped_state.owner_id == player.id:
			await _board_evaluator.evaluate_and_execute_all(gm, difficulty)


func _best_flip_slot(hidden_slots: Array, gm: GameManager, player: PlayerState) -> Dictionary:
	var best_slot := -1
	var best_score := -999.0
	var player_index := gm.players.find(player)

	for slot in hidden_slots:
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
			if state.data.faction_id == player.faction_id:
				score += AICommonScript.calc_threat_score(state) * 0.5
			else:
				score -= 1.0
		else:
			# Empty slot — slight penalty since card is unknown
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
