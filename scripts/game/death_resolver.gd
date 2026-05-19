extends RefCounted
class_name DeathResolver

# DeathResolver 统一处理卡牌死亡、入坟、攻击击杀后的占领结算。
# 死亡触发不直接散落在各个效果里，而是先形成死亡批次，再交给 TriggerResolver 结算。

var is_resolving_death_batches := false
var queued_death_scan_requests: Array[Dictionary] = []
const HERO_REVIVE_COOLDOWN_TURNS := 3


func check_and_destroy_if_dead(game_manager: GameManager, state: CardState, reason: String = "damage", source_state: CardState = null) -> bool:
	if state == null or state.is_empty():
		return false

	if not can_state_die(state):
		return false

	if state.current_health > 0:
		return false

	return resolve_dead_states(game_manager, [state], reason, source_state)


func resolve_dead_units(game_manager: GameManager, reason: String = "damage", source_state: CardState = null) -> bool:
	if game_manager == null:
		return false

	return resolve_dead_states(game_manager, game_manager.board_states, reason, source_state)


func resolve_dead_states(
	game_manager: GameManager,
	states_to_check: Array,
	reason: String = "damage",
	source_state: CardState = null,
	should_refill_slots := true,
	force_destroy := false
) -> bool:
	if game_manager == null:
		return false

	var request := {
		"states_to_check": states_to_check,
		"reason": reason,
		"source_state": source_state,
		"should_refill_slots": should_refill_slots,
		"force_destroy": force_destroy
	}

	if is_resolving_death_batches:
		queued_death_scan_requests.append(request)
		return false

	is_resolving_death_batches = true
	var destroyed_any := false
	var active_request := request

	while true:
		var death_events := collect_death_events(
			game_manager,
			active_request.get("states_to_check", []),
			str(active_request.get("reason", "damage")),
			active_request.get("source_state") as CardState,
			bool(active_request.get("should_refill_slots", true)),
			bool(active_request.get("force_destroy", false))
		)

		if not death_events.is_empty():
			destroyed_any = true
			resolve_death_batch(game_manager, death_events)

		if queued_death_scan_requests.is_empty():
			break

		active_request = queued_death_scan_requests.pop_front()

	is_resolving_death_batches = false
	return destroyed_any


func destroy_card(game_manager: GameManager, state: CardState, reason: String = "destroy", source_state: CardState = null) -> void:
	if state == null or state.is_empty():
		return

	destroy_card_with_refill(game_manager, state, reason, source_state, true)


func destroy_card_with_refill(
	game_manager: GameManager,
	state: CardState,
	reason: String = "destroy",
	source_state: CardState = null,
	should_refill_slot := true
) -> void:
	if game_manager == null or state == null or state.is_empty():
		return

	resolve_dead_states(game_manager, [state], reason, source_state, should_refill_slot, true)


func collect_death_events(
	game_manager: GameManager,
	states_to_check: Array,
	reason: String,
	source_state: CardState,
	should_refill_slots := true,
	force_destroy := false
) -> Array[Dictionary]:
	var death_events: Array[Dictionary] = []

	for value in states_to_check:
		var state := value as CardState
		if state == null or not can_state_die(state):
			continue

		if not force_destroy and state.current_health > 0:
			continue

		state.is_pending_death = true
		death_events.append(create_death_event(game_manager, state, reason, source_state, should_refill_slots))

	sort_death_events(game_manager, death_events)
	return death_events


func can_state_die(state: CardState) -> bool:
	return (
		state != null
		and not state.is_empty()
		and state.is_unit()
		and not state.is_pending_death
	)


func create_death_event(
	game_manager: GameManager,
	state: CardState,
	reason: String,
	source_state: CardState = null,
	should_refill_slot := true
) -> Dictionary:
	var death_metadata := create_death_metadata(game_manager, state, reason, source_state)
	var destroy_context := create_destroy_context(state, source_state, death_metadata)
	return {
		"state": state,
		"slot_index": state.slot_index,
		"owner_id": state.owner_id,
		"reason": reason,
		"source_state": source_state,
		"should_refill_slot": should_refill_slot,
		"death_metadata": death_metadata,
		"graveyard_snapshot": state.create_graveyard_snapshot(death_metadata),
		"destroy_context": destroy_context
	}


func sort_death_events(game_manager: GameManager, death_events: Array[Dictionary]) -> void:
	death_events.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_priority := get_death_event_priority(game_manager, first)
		var second_priority := get_death_event_priority(game_manager, second)
		if first_priority != second_priority:
			return first_priority < second_priority

		return int(first.get("slot_index", -1)) < int(second.get("slot_index", -1))
	)


func get_death_event_priority(game_manager: GameManager, death_event: Dictionary) -> int:
	var owner_id := str(death_event.get("owner_id", ""))
	if owner_id == "":
		return 2

	var current_player := game_manager.get_current_player()
	if current_player != null and owner_id == current_player.id:
		return 0

	return 1


func resolve_death_batch(game_manager: GameManager, death_events: Array[Dictionary]) -> void:
	var should_cancel_interaction := false

	for death_event in death_events:
		var state := death_event.get("state") as CardState
		if state == null or state.is_empty():
			continue

		if is_interaction_related_to_state(game_manager, state):
			should_cancel_interaction = true

		move_death_event_to_owner_zone(game_manager, death_event, state)

		game_manager.trigger_resolver.queue_trigger(
			state,
			EventContext.TRIGGER_ON_DESTROYED,
			death_event.get("destroy_context", {})
		)

	await game_manager.trigger_resolver.resolve_queued(game_manager)

	for death_event in death_events:
		var state := death_event.get("state") as CardState
		if state == null or state.is_empty():
			continue

		var removed_slot_index := int(death_event.get("slot_index", state.slot_index))
		state.clear_card()
		if bool(death_event.get("should_refill_slot", true)):
			game_manager.refill_board_slot_from_pool(removed_slot_index)

	if should_cancel_interaction and not game_manager.is_resolving_card_action and not game_manager.is_executing_action:
		game_manager.hide_action_menu()
		game_manager.interaction_manager.cancel(game_manager.board_states)

	game_manager.refresh_action_available_hints()
	game_manager.refresh_debug_panel()


func move_death_event_to_owner_zone(game_manager: GameManager, death_event: Dictionary, state: CardState) -> void:
	if game_manager == null or state == null:
		return

	var owner := game_manager.get_player_by_id(str(death_event.get("owner_id", "")))
	if owner == null:
		return

	if state.is_hero():
		owner.add_to_hand_with_cooldown(
			state.data,
			HERO_REVIVE_COOLDOWN_TURNS,
			HandCardState.SOURCE_HERO_REVIVE,
			["hero_revive"]
		)
		return

	owner.add_to_graveyard(death_event.get("graveyard_snapshot", {}))


func is_interaction_related_to_state(game_manager: GameManager, state: CardState) -> bool:
	return (
		game_manager.interaction_manager.focused_state == state
		or game_manager.interaction_manager.valid_target_slots.has(state.slot_index)
	)


func resolve_attack_kill(game_manager: GameManager, attacker_state: CardState, defeated_state: CardState, can_occupy := true) -> void:
	if game_manager == null or attacker_state == null or defeated_state == null:
		return

	if defeated_state.is_empty() or defeated_state.current_health > 0:
		return

	var should_occupy := false
	if can_occupy and can_offer_attack_occupy(attacker_state, defeated_state):
		var attacker_owner := game_manager.get_player_by_id(attacker_state.owner_id)
		if attacker_owner != null and attacker_owner.is_ai:
			should_occupy = _ai_decide_occupy(game_manager, attacker_state, defeated_state)
		else:
			should_occupy = await game_manager.attack_occupy_choice_controller.prompt(
				game_manager.get_parent(),
				attacker_state,
				defeated_state,
				game_manager.occupy_choice_panel_size
			)

	if should_occupy:
		await resolve_attack_occupy(game_manager, attacker_state, defeated_state)
	else:
		destroy_card_with_refill(game_manager, defeated_state, "attack", attacker_state, true)


func can_offer_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> bool:
	if attacker_state == null or defeated_state == null:
		return false

	if attacker_state.is_empty() or defeated_state.is_empty():
		return false

	if attacker_state == defeated_state:
		return false

	if defeated_state.current_health > 0:
		return false

	return true


func _ai_decide_occupy(game_manager: GameManager, attacker_state: CardState, defeated_state: CardState) -> bool:
	var player_index := -1
	for i in range(game_manager.players.size()):
		var p := game_manager.players[i] as PlayerState
		if p != null and p.id == attacker_state.owner_id:
			player_index = i
			break

	if player_index < 0:
		return true

	var board_columns := game_manager.board_columns
	var attacker_row := attacker_state.slot_index / board_columns
	var defeated_row := defeated_state.slot_index / board_columns

	var is_advancing := false
	if player_index == 0:
		is_advancing = defeated_row > attacker_row
	else:
		is_advancing = defeated_row < attacker_row

	# 检查占领后是否会被相邻敌人反杀
	var incoming_damage := 0
	for adj in BoardQuery.get_adjacent_slots(defeated_state.slot_index, board_columns, game_manager.board_states.size()):
		var adj_state := game_manager.get_board_state(adj)
		if adj_state != null and adj_state.owner_id != "" and adj_state.owner_id != attacker_state.owner_id and adj_state.current_attack > 0:
			incoming_damage += adj_state.current_attack

	if incoming_damage >= attacker_state.current_health:
		return false

	return is_advancing or defeated_row == attacker_row


func resolve_attack_occupy(game_manager: GameManager, attacker_state: CardState, defeated_state: CardState) -> void:
	if game_manager == null or not can_offer_attack_occupy(attacker_state, defeated_state):
		return

	var attacker_slot_index := attacker_state.slot_index
	var defeated_slot_index := defeated_state.slot_index
	destroy_card_with_refill(game_manager, defeated_state, "attack_occupied", attacker_state, false)

	var attacker_after_death := game_manager.get_board_state(attacker_slot_index)
	var defeated_after_death := game_manager.get_board_state(defeated_slot_index)
	if attacker_after_death == null or defeated_after_death == null:
		return

	await game_manager.move_card_content_to_empty_slot(attacker_after_death, defeated_after_death)
	game_manager.refill_board_slot_from_pool(attacker_slot_index)


func create_destroy_context(state: CardState, source_state: CardState = null, death_metadata: Dictionary = {}) -> Dictionary:
	var context := {
		EventContext.DEAD_STATE: state,
		EventContext.DEATH: death_metadata.duplicate(true),
		EventContext.DESTROYER_PLAYER_ID: ""
	}

	if source_state != null and not source_state.is_empty():
		context[EventContext.DESTROYER_PLAYER_ID] = source_state.owner_id
		context[EventContext.SOURCE_STATE] = source_state

	return context


func create_death_metadata(game_manager: GameManager, state: CardState, reason: String = "destroy", source_state: CardState = null) -> Dictionary:
	var metadata := {
		"reason": reason,
		"turn": game_manager.turn_number,
		"slot_index": state.slot_index,
		"owner_id": state.owner_id
	}

	if source_state != null and not source_state.is_empty():
		metadata["source_slot_index"] = source_state.slot_index
		metadata["source_owner_id"] = source_state.owner_id
		metadata["source_card_id"] = source_state.card_id
		metadata["source_display_name"] = source_state.display_name

	return metadata
