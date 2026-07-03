extends RefCounted
class_name StatusResolver

# StatusResolver handles fixed status rules and status lifecycle.
# Pre-trigger effects run before normal turn timing triggers; lifecycle ticking runs after them.

func resolve_pre_trigger_status_effects(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return

	match trigger:
		EventContext.TRIGGER_BEFORE_TURN_START:
			await mature_life_link_larvae(game_manager, turn_player_id)
		EventContext.TRIGGER_AFTER_TURN_END:
			await resolve_poison_damage(game_manager, trigger, turn_player_id)


func resolve_turn_timing(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	if game_manager == null or trigger == "" or turn_player_id == "":
		return

	var death_immunity_expired_states: Array[CardState] = []
	var transform_restored_states: Array[CardState] = []
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_unit(state):
			continue

		var expired_statuses := state.expire_statuses_for_turn_timing(trigger, turn_player_id)
		if restore_expired_transforms(state, expired_statuses):
			transform_restored_states.append(state)
		if should_check_death_after_status_expiry(state, expired_statuses):
			death_immunity_expired_states.append(state)

	if not transform_restored_states.is_empty():
		game_manager.refresh_action_available_hints()
		game_manager.refresh_debug_panel()

	if not death_immunity_expired_states.is_empty():
		await game_manager.resolve_dead_states(
			death_immunity_expired_states,
			EffectData.DEATH_REASON_STATUS_EXPIRED,
			null
		)


func resolve_poison_damage(game_manager: GameManager, trigger: String, turn_player_id: String) -> void:
	var damaged_states: Array[CardState] = []
	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_unit(state):
			continue
		if state.has_keyword(CardData.KEYWORD_MECHANICAL):
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
		await game_manager.resolve_dead_states(damaged_states, EffectData.DEATH_REASON_POISON, null)


func mature_life_link_larvae(game_manager: GameManager, turn_player_id: String) -> void:
	var processed_link_ids: Array[String] = []
	var has_matured_or_removed := false

	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_unit(state):
			continue

		for status in state.statuses.duplicate():
			if not should_mature_life_link_larva(status, turn_player_id):
				continue

			var link_id := str(status.payload.get(EffectData.KEY_LINK_ID, ""))
			if link_id == "" or processed_link_ids.has(link_id):
				continue

			processed_link_ids.append(link_id)
			var participants := get_life_link_larva_participants(game_manager, link_id, turn_player_id)
			if participants.size() < 2:
				if remove_life_link_larvae(game_manager, link_id, turn_player_id):
					has_matured_or_removed = true
				continue

			var first_state := participants[0]
			var second_state := participants[1]
			var first_larva := get_life_link_larva_status(first_state, link_id, turn_player_id)
			var mature_animation := get_life_link_mature_animation(first_larva)

			remove_life_link_larva_status(first_state, link_id, turn_player_id)
			remove_life_link_larva_status(second_state, link_id, turn_player_id)
			apply_mature_life_link_status(first_state, second_state, link_id, turn_player_id)
			apply_mature_life_link_status(second_state, first_state, link_id, turn_player_id)
			has_matured_or_removed = true

			if game_manager.has_method("play_link_units_animation"):
				await game_manager.play_link_units_animation(first_state, second_state, mature_animation)

	if has_matured_or_removed:
		game_manager.refresh_action_available_hints()
		game_manager.refresh_debug_panel()


func should_mature_life_link_larva(status: CardStatus, turn_player_id: String) -> bool:
	if status == null or status.status_id != CardStatus.STATUS_LIFE_LINK_LARVA:
		return false

	var mature_owner_id := str(status.payload.get("mature_on_owner_id", status.source_owner_id))
	return mature_owner_id != "" and mature_owner_id == turn_player_id


func get_life_link_larva_participants(
	game_manager: GameManager,
	link_id: String,
	turn_player_id: String
) -> Array[CardState]:
	var participants: Array[CardState] = []
	for state in game_manager.get_all_board_states():
		if state == null or state.is_pending_death or not BoardQuery.is_face_up_minion(state):
			continue
		if get_life_link_larva_status(state, link_id, turn_player_id) != null:
			participants.append(state)

	return participants


func get_life_link_larva_status(state: CardState, link_id: String, turn_player_id: String) -> CardStatus:
	if state == null or link_id == "":
		return null

	for status in state.statuses:
		if status == null or status.status_id != CardStatus.STATUS_LIFE_LINK_LARVA:
			continue
		if str(status.payload.get(EffectData.KEY_LINK_ID, "")) != link_id:
			continue
		if should_mature_life_link_larva(status, turn_player_id):
			return status

	return null


func remove_life_link_larvae(game_manager: GameManager, link_id: String, turn_player_id: String) -> bool:
	var removed_any := false
	for state in game_manager.get_all_board_states():
		if remove_life_link_larva_status(state, link_id, turn_player_id):
			removed_any = true

	return removed_any


func remove_life_link_larva_status(state: CardState, link_id: String, turn_player_id: String) -> bool:
	if state == null or link_id == "":
		return false

	var removed_any := false
	for status in state.statuses.duplicate():
		if status == null or status.status_id != CardStatus.STATUS_LIFE_LINK_LARVA:
			continue
		if str(status.payload.get(EffectData.KEY_LINK_ID, "")) != link_id:
			continue
		if not should_mature_life_link_larva(status, turn_player_id):
			continue
		if state.remove_status_instance(status):
			removed_any = true

	return removed_any


func get_life_link_mature_animation(status: CardStatus) -> String:
	if status == null:
		return "gu_life_link"

	return str(status.payload.get("mature_animation", "gu_life_link"))


func apply_mature_life_link_status(
	target_state: CardState,
	linked_state: CardState,
	link_id: String,
	owner_id: String
) -> void:
	var status := CardStatus.new()
	status.status_id = CardStatus.STATUS_LIFE_LINK
	status.display_name = "同命蛊"
	status.description = "与另一个随从相连，其中一个死亡时另一个也会死亡。"
	status.tags = [CardStatus.TAG_DEATH_LINK]
	status.stacks = 1
	status.stack_policy = CardStatus.STACK_POLICY_STACK
	status.is_permanent = true
	status.remaining_turns = -1
	status.source_card_id = "life_link:%s" % link_id
	status.source_owner_id = owner_id
	status.duration_owner_id = target_state.owner_id
	status.valence = EffectData.STATUS_VALENCE_NEGATIVE
	status.payload = {
		EffectData.KEY_LINK_ID: link_id,
		"linked_card_id": linked_state.card_id,
		"linked_display_name": linked_state.display_name,
		EffectData.KEY_STATUS_TRIGGER_EFFECTS: [
			{
				EffectData.KEY_ID: EffectData.EFFECT_DESTROY_LINKED_UNITS,
				EffectData.KEY_TRIGGER: EventContext.TRIGGER_ON_DESTROYED
			}
		]
	}
	target_state.add_status(status)


func should_check_death_after_status_expiry(state: CardState, expired_statuses: Array[CardStatus]) -> bool:
	if state == null or state.is_empty() or state.current_health > 0:
		return false
	if state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION):
		return false

	for status in expired_statuses:
		if status != null and status.tags.has(CardStatus.TAG_DEATH_PREVENTION):
			return true

	return false


func restore_expired_transforms(state: CardState, expired_statuses: Array[CardStatus]) -> bool:
	if state == null or expired_statuses.is_empty():
		return false

	for status in expired_statuses:
		if status != null and status.status_id == CardStatus.STATUS_TRANSFORM:
			return state.restore_from_transform_status(status)

	return false
