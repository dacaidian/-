extends RefCounted
class_name RcConcentrationResolver

const FACTION_ID := "tokyo_ghoul"
const TRANSITION_POLICY := "rc_concentration"
const STATE_LOW := "rc_low"
const STATE_MEDIUM := "rc_medium"
const STATE_HIGH := "rc_high"
const FORCED_FEEDING_REASON := "rc_forced_feeding"


func handles(player: PlayerState) -> bool:
	return (
		player != null
		and player.faction_id == FACTION_ID
		and str(player.faction_runtime_state_config.get("transition_policy", "")) == TRANSITION_POLICY
	)


func resolve_after_death_event(
	player: PlayerState,
	ledger: TurnEventLedger,
	death_record: Dictionary
) -> bool:
	if player == null or ledger == null or not handles(player):
		return false
	if not ledger.is_enemy_minion_kill(death_record, player.id):
		return false

	var next_state_id := get_increased_state_id(player.faction_runtime_state_id)
	if next_state_id == player.faction_runtime_state_id:
		return false
	return player.set_faction_runtime_state_by_id(next_state_id)


func resolve_after_turn_end(
	game_manager: GameManager,
	player: PlayerState,
	ledger: TurnEventLedger
) -> bool:
	if game_manager == null or player == null or ledger == null or not handles(player):
		return false
	if ledger.get_qualified_minion_kill_count(player.id) > 0:
		return false

	var current_state_id := player.faction_runtime_state_id
	var next_state_id := get_decreased_state_id(player.faction_runtime_state_id)
	var did_change := false
	if next_state_id != player.faction_runtime_state_id:
		did_change = player.set_faction_runtime_state_by_id(next_state_id)

	if current_state_id == STATE_LOW:
		await resolve_forced_feeding(game_manager, player)

	return did_change


func get_increased_state_id(current_state_id: String) -> String:
	match current_state_id:
		STATE_LOW:
			return STATE_MEDIUM
		STATE_MEDIUM:
			return STATE_HIGH
		STATE_HIGH:
			return STATE_HIGH
		_:
			return current_state_id


func get_decreased_state_id(current_state_id: String) -> String:
	match current_state_id:
		STATE_HIGH:
			return STATE_MEDIUM
		STATE_MEDIUM:
			return STATE_LOW
		STATE_LOW:
			return STATE_LOW
		_:
			return current_state_id


func resolve_forced_feeding(game_manager: GameManager, player: PlayerState) -> void:
	var candidates := get_feeding_candidates(game_manager, player)
	if candidates.is_empty():
		return

	var target: CardState = candidates.pick_random()
	if target == null or target.is_empty():
		return

	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(target, "rc_forced_feeding")
	await game_manager.destroy_card_with_refill(target, FORCED_FEEDING_REASON, null, true)


func get_feeding_candidates(game_manager: GameManager, player: PlayerState) -> Array[CardState]:
	var candidates: Array[CardState] = []
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != player.id or state.is_hero() or state.data == null:
			continue
		if state.data.faction_id != FACTION_ID:
			continue
		candidates.append(state)
	return candidates
