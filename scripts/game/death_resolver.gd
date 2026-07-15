extends RefCounted
class_name DeathResolver

# DeathResolver 统一处理卡牌死亡、入坟、攻击击杀后的占领结算。
# 死亡触发不直接散落在各个效果里，而是先形成死亡批次，再交给 TriggerResolver 结算。

var is_resolving_death_batches := false
var queued_death_scan_requests: Array[Dictionary] = []
const HERO_REVIVE_COOLDOWN_TURNS := 3
const BeastmenEvolutionResolverScript := preload("res://scripts/game/beastmen_evolution_resolver.gd")

var beastmen_evolution_resolver := BeastmenEvolutionResolverScript.new()


func check_and_destroy_if_dead(game_manager: GameManager, state: CardState, reason: String = "damage", source_state: CardState = null) -> bool:
	if state == null or state.is_empty():
		return false

	if not can_state_die(state):
		return false

	if state.current_health > 0:
		return false

	return await resolve_dead_states(game_manager, [state], reason, source_state)


func resolve_dead_units(game_manager: GameManager, reason: String = "damage", source_state: CardState = null) -> bool:
	if game_manager == null:
		return false

	return await resolve_dead_states(game_manager, game_manager.get_all_board_states(), reason, source_state)


func resolve_dead_states(
	game_manager: GameManager,
	states_to_check: Array,
	reason: String = "damage",
	source_state: CardState = null,
	should_refill_slots := true,
	force_destroy := false,
	source_owner_id := ""
) -> bool:
	if game_manager == null:
		return false

	var request := {
		"states_to_check": states_to_check,
		"reason": reason,
		"source_state": source_state,
		# Death scans can be queued while the current death batch is still resolving.
		# Keep attribution data now, because the live source_state may be cleared before
		# the queued request becomes a death event.
		"source_snapshot": create_source_snapshot(source_state),
		"source_owner_id": source_owner_id,
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
			active_request.get("source_snapshot", {}) as Dictionary,
			bool(active_request.get("should_refill_slots", true)),
			bool(active_request.get("force_destroy", false)),
			str(active_request.get("source_owner_id", ""))
		)

		if not death_events.is_empty():
			destroyed_any = true
			await resolve_death_batch(game_manager, death_events)

		if queued_death_scan_requests.is_empty():
			break

		active_request = queued_death_scan_requests.pop_front()

	is_resolving_death_batches = false
	return destroyed_any


func destroy_card(game_manager: GameManager, state: CardState, reason: String = "destroy", source_state: CardState = null) -> void:
	if state == null or state.is_empty():
		return

	await destroy_card_with_refill(game_manager, state, reason, source_state, true)


func destroy_card_with_refill(
	game_manager: GameManager,
	state: CardState,
	reason: String = "destroy",
	source_state: CardState = null,
	should_refill_slot := true,
	source_owner_id := ""
) -> void:
	if game_manager == null or state == null or state.is_empty():
		return

	await resolve_dead_states(game_manager, [state], reason, source_state, should_refill_slot, true, source_owner_id)


func collect_death_events(
	game_manager: GameManager,
	states_to_check: Array,
	reason: String,
	source_state: CardState,
	source_snapshot: Dictionary = {},
	should_refill_slots := true,
	force_destroy := false,
	source_owner_id := ""
) -> Array[Dictionary]:
	var death_events: Array[Dictionary] = []

	for value in states_to_check:
		var state := value as CardState
		if state == null or not can_state_die(state):
			continue

		if not force_destroy and state.current_health > 0:
			continue
		if try_restore_cover_transform_death(game_manager, state):
			continue

		state.is_pending_death = true
		death_events.append(create_death_event(
			game_manager,
			state,
			reason,
			source_state,
			source_snapshot,
			should_refill_slots,
			source_owner_id
		))

	sort_death_events(game_manager, death_events)
	return death_events


func try_restore_cover_transform_death(game_manager: GameManager, state: CardState) -> bool:
	if state == null or state.is_empty() or not state.is_cover_transformed():
		return false

	var transform_status := state.get_transform_status()
	if transform_status == null:
		return false

	var did_restore := state.restore_from_transform_status(transform_status)
	if not did_restore:
		return false

	if game_manager != null:
		game_manager.refresh_action_available_hints()
		game_manager.refresh_debug_panel()
	return true


func can_state_die(state: CardState) -> bool:
	return (
		state != null
		and not state.is_empty()
		and state.is_unit()
		and not state.is_pending_death
		and not state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION)
	)


func create_death_event(
	game_manager: GameManager,
	state: CardState,
	reason: String,
	source_state: CardState = null,
	source_snapshot: Dictionary = {},
	should_refill_slot := true,
	source_owner_id := ""
) -> Dictionary:
	var death_metadata := create_death_metadata(
		game_manager,
		state,
		reason,
		source_state,
		source_snapshot,
		source_owner_id
	)
	var destroy_context := create_destroy_context(state, source_state, death_metadata, source_snapshot)
	return {
		"state": state,
		"slot_index": state.slot_index,
		"owner_id": state.owner_id,
		"reason": reason,
		"source_state": source_state,
		"source_snapshot": source_snapshot.duplicate(true),
		"should_refill_slot": should_refill_slot,
		"has_reborn": state.has_reborn(),
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

		game_manager.record_turn_death_event(death_event)

		if is_interaction_related_to_state(game_manager, state):
			should_cancel_interaction = true

		if not should_reborn_death_event(death_event, state):
			move_death_event_to_owner_zone(game_manager, death_event, state)

		await resolve_destroyed_trigger(game_manager, state, death_event.get("destroy_context", {}))

	if not game_manager.trigger_resolver.is_resolving:
		await game_manager.trigger_resolver.resolve_queued(game_manager)
	await beastmen_evolution_resolver.resolve_after_death_batch(game_manager, death_events)

	for death_event in death_events:
		var state := death_event.get("state") as CardState
		if state == null or state.is_empty():
			continue

		var did_reborn := await resolve_reborn_death_event(game_manager, death_event, state)
		if did_reborn:
			continue

		var removed_slot_index := int(death_event.get("slot_index", state.slot_index))
		state.clear_card()
		if bool(death_event.get("should_refill_slot", true)):
			game_manager.refill_board_slot_from_pool(removed_slot_index)

	if should_cancel_interaction and not game_manager.is_resolving_card_action and not game_manager.is_executing_action:
		game_manager.hide_action_menu()
		game_manager.interaction_manager.cancel(game_manager.get_all_board_states())

	game_manager.refresh_action_available_hints()
	game_manager.refresh_debug_panel()


func resolve_destroyed_trigger(game_manager: GameManager, state: CardState, context: Dictionary) -> void:
	if game_manager == null or state == null:
		return

	if game_manager.trigger_resolver.is_resolving:
		await game_manager.effect_registry.execute_trigger(state, EventContext.TRIGGER_ON_DESTROYED, game_manager, context)
	else:
		game_manager.trigger_resolver.queue_trigger(state, EventContext.TRIGGER_ON_DESTROYED, context)


func should_reborn_death_event(death_event: Dictionary, state: CardState) -> bool:
	return bool(death_event.get("has_reborn", false)) and state != null and state.has_reborn()


func resolve_reborn_death_event(game_manager: GameManager, death_event: Dictionary, state: CardState) -> bool:
	if game_manager == null or state == null or state.is_empty():
		return false

	if not should_reborn_death_event(death_event, state):
		return false

	var health_value := state.consume_next_reborn_health_value()
	if health_value < 0:
		return false

	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(state, "reborn")

	state.revive_from_reborn(health_value)
	refresh_reborn_owner_passives(game_manager, state.owner_id)
	return true


func refresh_reborn_owner_passives(game_manager: GameManager, owner_id: String) -> void:
	if game_manager == null or owner_id == "":
		return

	var owner := game_manager.get_player_by_id(owner_id)
	if owner == null:
		return

	game_manager.refresh_hand_passives_for_player(owner, owner == game_manager.get_current_player())


func move_death_event_to_owner_zone(game_manager: GameManager, death_event: Dictionary, state: CardState) -> void:
	if game_manager == null or state == null:
		return

	var owner := game_manager.get_player_by_id(str(death_event.get("owner_id", "")))
	if owner == null:
		return

	if state.is_hero():
		var hero_card_id := state.get_effective_hero_card_id()
		var hero_card_data := state.get_effective_hero_card_data()
		if hero_card_data == null:
			hero_card_data = state.data
		var revive_cooldown := maxi(HERO_REVIVE_COOLDOWN_TURNS + owner.get_hero_revive_cooldown_modifier(hero_card_id), 0)
		owner.add_to_hand_with_cooldown(
			hero_card_data,
			revive_cooldown,
			HandCardState.SOURCE_HERO_REVIVE,
			["hero_revive"],
			state.permanent_stat_overrides
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
	if not can_state_die(defeated_state):
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
		await destroy_card_with_refill(game_manager, defeated_state, "attack", attacker_state, true)


func can_offer_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> bool:
	if attacker_state == null or defeated_state == null:
		return false

	if attacker_state.is_empty() or defeated_state.is_empty():
		return false

	if attacker_state == defeated_state:
		return false
	if attacker_state.owner_id == defeated_state.owner_id and attacker_state.owner_id != "":
		return false

	if defeated_state.current_health > 0:
		return false

	if defeated_state.has_reborn():
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
	var attacker_row := floori(float(attacker_state.slot_index) / float(board_columns))
	var defeated_row := floori(float(defeated_state.slot_index) / float(board_columns))

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
	await destroy_card_with_refill(game_manager, defeated_state, "attack_occupied", attacker_state, false)

	var attacker_after_death := game_manager.get_board_state(attacker_slot_index)
	var defeated_after_death := game_manager.get_board_state(defeated_slot_index)
	if attacker_after_death == null or defeated_after_death == null:
		return

	await game_manager.move_card_content_to_empty_slot(attacker_after_death, defeated_after_death)
	game_manager.refill_board_slot_from_pool(attacker_slot_index)


func create_destroy_context(
	state: CardState,
	source_state: CardState = null,
	death_metadata: Dictionary = {},
	source_snapshot: Dictionary = {}
) -> Dictionary:
	var context := {
		EventContext.DEAD_STATE: state,
		EventContext.DEATH: death_metadata.duplicate(true),
		EventContext.DESTROYER_PLAYER_ID: ""
	}

	if source_state != null and not source_state.is_empty():
		context[EventContext.DESTROYER_PLAYER_ID] = source_state.owner_id
		context[EventContext.SOURCE_STATE] = source_state
	elif not source_snapshot.is_empty():
		context[EventContext.DESTROYER_PLAYER_ID] = str(source_snapshot.get("owner_id", ""))
	else:
		context[EventContext.DESTROYER_PLAYER_ID] = str(death_metadata.get("source_owner_id", ""))

	return context


func create_death_metadata(
	game_manager: GameManager,
	state: CardState,
	reason: String = "destroy",
	source_state: CardState = null,
	source_snapshot: Dictionary = {},
	source_owner_id := ""
) -> Dictionary:
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
	elif not source_snapshot.is_empty():
		metadata["source_slot_index"] = int(source_snapshot.get("slot_index", -1))
		metadata["source_owner_id"] = str(source_snapshot.get("owner_id", ""))
		metadata["source_card_id"] = str(source_snapshot.get("card_id", ""))
		metadata["source_display_name"] = str(source_snapshot.get("display_name", ""))
	else:
		var resolved_source_owner_id := resolve_status_source_owner_id(state, reason, source_owner_id)
		if resolved_source_owner_id != "":
			metadata["source_owner_id"] = resolved_source_owner_id

	return metadata


func resolve_status_source_owner_id(state: CardState, reason: String, explicit_owner_id: String) -> String:
	if explicit_owner_id != "":
		return explicit_owner_id
	if state == null:
		return ""

	var status_id := ""
	match reason:
		EffectData.DEATH_REASON_POISON:
			status_id = CardStatus.STATUS_POISON
		EffectData.DEATH_REASON_FIRE:
			status_id = CardStatus.STATUS_FIRE
		_:
			return ""

	var status := state.get_status(status_id)
	return status.source_owner_id if status != null else ""


func create_source_snapshot(source_state: CardState) -> Dictionary:
	if source_state == null or source_state.is_empty():
		return {}

	return {
		"slot_index": source_state.slot_index,
		"owner_id": source_state.owner_id,
		"card_id": source_state.card_id,
		"display_name": source_state.display_name
	}
