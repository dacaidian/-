extends RefCounted
class_name AIActionExecutor

const AICommonScript = preload("res://scripts/ai/ai_common.gd")
const AICandidateBuilderScript = preload("res://scripts/ai/ai_candidate_builder.gd")


func execute_candidate(gm: GameManager, candidate: Dictionary, failed_flip_slots: Array[int]) -> bool:
	if gm == null or gm.is_game_over or candidate.is_empty():
		return false

	match str(candidate.get("kind", "")):
		AICandidateBuilderScript.KIND_HAND:
			return await _execute_hand_candidate(gm, candidate)
		AICandidateBuilderScript.KIND_BOARD_ACTION:
			return await _execute_board_action_candidate(gm, candidate)
		AICandidateBuilderScript.KIND_FLIP:
			return await _execute_flip_candidate(gm, candidate, failed_flip_slots)
		AICandidateBuilderScript.KIND_ACTIVATE_SPELL_TURN:
			return _execute_activate_spell_turn_candidate(gm)
		_:
			return false


func _execute_hand_candidate(gm: GameManager, candidate: Dictionary) -> bool:
	var player := gm.get_current_player()
	var card_data := candidate.get("card_data") as CardData
	var hand_index := int(candidate.get("hand_index", -1))
	var target := candidate.get("target") as CardState
	if player == null or card_data == null:
		return false

	var hpr := gm.get_hand_play_resolver()
	if not hpr.can_play_hand_card_at(player, hand_index, gm):
		return false

	gm.is_executing_action = true
	if card_data.is_spell():
		await hpr.execute_hand_card(gm, player, card_data, hand_index, target)
	elif card_data.is_minion():
		await hpr.execute_hand_minion_placement(gm, player, card_data, hand_index, target)
	elif card_data.is_equipment():
		hpr.execute_hand_equipment(gm, player, card_data, hand_index)
	gm.is_executing_action = false

	_refresh_after_step(gm)
	await AICommonScript.await_step_delay(gm)
	return true


func _execute_board_action_candidate(gm: GameManager, candidate: Dictionary) -> bool:
	var user := candidate.get("source") as CardState
	var action := candidate.get("action") as CardAction
	var target := candidate.get("target") as CardState
	if user == null or action == null:
		return false
	if not action.can_start(user, gm):
		return false
	if action.requires_target() and not action.get_valid_targets(user, gm).has(target):
		return false

	gm.is_executing_action = true
	await action.execute(user, target, gm)
	gm.is_executing_action = false

	_refresh_after_step(gm)
	await AICommonScript.await_step_delay(gm)
	return true


func _execute_flip_candidate(gm: GameManager, candidate: Dictionary, failed_flip_slots: Array[int]) -> bool:
	var player := gm.get_current_player()
	var slot := int(candidate.get("slot", -1))
	if player == null or slot < 0 or not player.can_flip_card():
		return false

	var state := gm.get_board_state(slot)
	if state == null or (not state.is_empty() and state.is_face_up):
		return false

	gm.is_resolving_card_action = true
	player.spend_flip()

	if state.is_empty():
		gm.draw_card_to_slot(slot)
		if state.is_empty():
			gm.is_resolving_card_action = false
			return false

	var card: Card = gm.get_card_by_slot(slot)
	if card != null:
		await card.play_flip_animation(Callable(state, "set_face_up").bind(true))
	else:
		state.set_face_up(true)

	if not gm.reveal_resolver.can_player_claim_card(gm, player, state):
		if card != null:
			await card.play_flip_animation(Callable(state, "set_face_up").bind(false))
		else:
			state.set_face_up(false)
		failed_flip_slots.append(slot)
		gm.is_resolving_card_action = false
		_refresh_after_step(gm)
		await AICommonScript.await_step_delay(gm)
		return true

	if gm.reveal_resolver.should_assign_owner_on_reveal(gm, state):
		state.set_owner(player.id)

	await gm.reveal_resolver.resolve_revealed_card(gm, state, player)
	gm.is_resolving_card_action = false
	gm.update_card_pool_view()
	_refresh_after_step(gm)
	await AICommonScript.await_step_delay(gm)
	return true


func _execute_activate_spell_turn_candidate(gm: GameManager) -> bool:
	if gm == null or gm.is_spell_turn_active:
		return false

	var player := gm.get_current_player()
	if player == null or player.mana < gm.spell_turn_mana_cost:
		return false

	gm.activate_spell_turn()
	_refresh_after_step(gm)
	return true


func _refresh_after_step(gm: GameManager) -> void:
	gm.update_hand_drawer_view()
	gm.update_equipment_display_view()
	gm.refresh_action_available_hints()
	gm.update_turn_status_view()
	gm.refresh_debug_panel()
