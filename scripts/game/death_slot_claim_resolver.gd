extends RefCounted
class_name DeathSlotClaimResolver

# Arbitrates replacement requests for a slot whose unit is being destroyed.
# Reborn is handled before this resolver; normal board refill is the fallback.

const PRIORITY_KILL_EFFECT := 100
const PRIORITY_DEATHRATTLE := 200

var active_events_by_state_id: Dictionary = {}
var claim_sequence := 0


func register_events(death_events: Array[Dictionary]) -> void:
	for death_event in death_events:
		var state := death_event.get("state") as CardState
		if state != null:
			active_events_by_state_id[state.get_instance_id()] = death_event


func unregister_events(death_events: Array[Dictionary]) -> void:
	for death_event in death_events:
		var state := death_event.get("state") as CardState
		if state != null:
			active_events_by_state_id.erase(state.get_instance_id())


func claim_for_active_death(
	game_manager: GameManager,
	dead_state: CardState,
	claim: Dictionary
) -> bool:
	if dead_state == null or claim.is_empty():
		return false

	var death_event := active_events_by_state_id.get(dead_state.get_instance_id()) as Dictionary
	if death_event == null:
		return false

	return append_claim(game_manager, death_event, claim, PRIORITY_DEATHRATTLE)


func append_claim(
	game_manager: GameManager,
	death_event: Dictionary,
	raw_claim: Dictionary,
	default_priority: int
) -> bool:
	if game_manager == null or death_event.is_empty() or raw_claim.is_empty():
		return false

	var card_id := str(raw_claim.get(EffectData.KEY_CARD_ID, ""))
	if card_id == "" or game_manager.get_card_data_by_id(card_id) == null:
		return false

	var victim_layer := get_death_event_layer(game_manager, death_event)
	var required_victim_layer := str(
		raw_claim.get(EffectData.KEY_VICTIM_LAYER, EffectData.BOARD_LAYER_GROUND)
	)
	if required_victim_layer != "" and required_victim_layer != victim_layer:
		return false

	var claim := raw_claim.duplicate(true)
	var slot_owner := str(
		claim.get(EffectData.KEY_SLOT_OWNER, EffectData.DEATH_SLOT_OWNER_DEFEATED)
	)
	if str(claim.get(EffectData.KEY_OWNER_ID, "")) == "":
		if slot_owner == EffectData.DEATH_SLOT_OWNER_DEFEATED:
			claim[EffectData.KEY_OWNER_ID] = str(death_event.get("owner_id", ""))
		else:
			claim[EffectData.KEY_OWNER_ID] = str(death_event.get("source_owner_id", ""))

	claim[EffectData.KEY_PRIORITY] = int(claim.get(EffectData.KEY_PRIORITY, default_priority))
	claim[EffectData.KEY_DESTINATION_LAYER] = str(
		claim.get(EffectData.KEY_DESTINATION_LAYER, victim_layer)
	)
	claim["_claim_order"] = claim_sequence
	claim_sequence += 1

	var claims := death_event.get("slot_claims", []) as Array
	claims.append(claim)
	death_event["slot_claims"] = claims
	return true


func get_death_event_layer(game_manager: GameManager, death_event: Dictionary) -> String:
	var state := death_event.get("state") as CardState
	var slot_index := int(death_event.get("slot_index", -1))
	if state != null and game_manager.get_aerial_state(slot_index) == state:
		return EffectData.BOARD_LAYER_AERIAL
	return EffectData.BOARD_LAYER_GROUND


func resolve_claims(game_manager: GameManager, death_event: Dictionary) -> bool:
	var claims := death_event.get("slot_claims", []) as Array
	if claims.is_empty():
		return false

	sort_claims(claims)
	for claim_value in claims:
		var claim := claim_value as Dictionary
		if claim != null and await place_claim(game_manager, death_event, claim):
			return true
	return false


func sort_claims(claims: Array) -> void:
	claims.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_priority := int(first.get(EffectData.KEY_PRIORITY, 0))
		var second_priority := int(second.get(EffectData.KEY_PRIORITY, 0))
		if first_priority != second_priority:
			return first_priority > second_priority
		return int(first.get("_claim_order", 0)) < int(second.get("_claim_order", 0))
	)


func place_claim(
	game_manager: GameManager,
	death_event: Dictionary,
	claim: Dictionary
) -> bool:
	var slot_index := int(death_event.get("slot_index", -1))
	var card_data := game_manager.get_card_data_by_id(str(claim.get(EffectData.KEY_CARD_ID, "")))
	if slot_index < 0 or card_data == null or not card_data.is_minion():
		return false

	var destination_layer := str(
		claim.get(EffectData.KEY_DESTINATION_LAYER, EffectData.BOARD_LAYER_GROUND)
	)
	var target_state: CardState = null
	if destination_layer == EffectData.BOARD_LAYER_AERIAL:
		if not card_data.has_keyword(CardData.KEYWORD_FLYING):
			return false
		if not game_manager.can_place_aerial_card_on_slot(slot_index):
			return false
		target_state = game_manager.get_aerial_state(slot_index)
	else:
		if card_data.has_keyword(CardData.KEYWORD_FLYING):
			return false
		if not game_manager.can_place_ground_card_on_slot(slot_index):
			return false
		target_state = game_manager.get_board_state(slot_index)

	if target_state == null or not target_state.is_empty():
		return false

	target_state.set_card_data(card_data)
	target_state.set_owner(str(claim.get(EffectData.KEY_OWNER_ID, "")))
	target_state.set_face_up(true)

	var animation_key := str(claim.get(EffectData.KEY_ANIMATION, ""))
	if animation_key != "":
		await game_manager.play_status_apply_animation(target_state, animation_key)

	await game_manager.resolve_slot_unit_entered(target_state)
	if not target_state.is_empty():
		game_manager.queue_card_trigger(target_state, EventContext.TRIGGER_ON_ENTER_BOARD)
		await game_manager.resolve_queued_triggers()
		await game_manager.check_and_destroy_if_dead(target_state, EffectData.DEATH_REASON_EFFECT)

	var owner := game_manager.get_player_by_id(target_state.owner_id)
	if owner != null:
		game_manager.refresh_hand_passives_for_player(owner, owner == game_manager.get_current_player())
	return true
