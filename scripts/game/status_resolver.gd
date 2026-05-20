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

	for state in game_manager.board_states:
		if not BoardQuery.is_face_up_unit(state):
			continue

		state.expire_statuses_for_turn_timing(trigger, turn_player_id)


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
