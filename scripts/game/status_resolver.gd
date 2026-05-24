extends RefCounted
class_name StatusResolver

# StatusResolver handles fixed status rules and status lifecycle.
# Pre-trigger effects run before normal turn timing triggers; lifecycle ticking runs after them.

func resolve_pre_trigger_status_effects(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return
	if trigger != EventContext.TRIGGER_AFTER_TURN_END:
		return

	await resolve_poison_damage(game_manager, trigger, turn_player_id)


func resolve_turn_timing(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return

	var death_immunity_expired_states: Array[CardState] = []
	for state in game_manager.board_states:
		if not BoardQuery.is_face_up_unit(state):
			continue

		var expired_statuses := state.expire_statuses_for_turn_timing(trigger, turn_player_id)
		if should_check_death_after_status_expiry(state, expired_statuses):
			death_immunity_expired_states.append(state)

	if not death_immunity_expired_states.is_empty():
		await game_manager.resolve_dead_states(
			death_immunity_expired_states,
			EffectData.DEATH_REASON_STATUS_EXPIRED,
			null
		)


func resolve_poison_damage(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	var damaged_states: Array[CardState] = []
	for state in game_manager.board_states:
		if not BoardQuery.is_face_up_unit(state):
			continue

		var poison := state.get_status(CardStatus.STATUS_POISON)
		if poison == null or not poison.should_tick(trigger, turn_player_id):
			continue

		var poison_damage := poison.get_poison_damage()
		if poison_damage <= 0:
			continue

		state.take_damage(poison_damage)
		damaged_states.append(state)

	if not damaged_states.is_empty():
		game_manager.resolve_dead_states(damaged_states, EffectData.DEATH_REASON_POISON, null)


func should_check_death_after_status_expiry(state: CardState, expired_statuses: Array[CardStatus]) -> bool:
	if state == null or state.is_empty() or state.current_health > 0:
		return false
	if state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION):
		return false

	for status in expired_statuses:
		if status != null and status.tags.has(CardStatus.TAG_DEATH_PREVENTION):
			return true

	return false
