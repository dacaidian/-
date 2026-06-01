extends CardAction
class_name VenomBurstAction

const ACTION_ID := "venom_burst"
const FOUNTAIN_CARD_ID := "venomous_fountain"

var allocation_resolver := RandomAllocationResolver.new()


func _init() -> void:
	id = ACTION_ID
	display_name = "毒爆"
	action_group = CardState.ACTION_GROUP_SPECIAL
	can_reuse_action_group = false


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_building(user, game_manager):
		return false
	if user.card_id != FOUNTAIN_CARD_ID:
		return false
	if get_stored_venom_damage(user) <= 0:
		return false
	if not has_valid_burst_target(user, game_manager):
		return false

	return can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if user == null or game_manager == null or not can_start(user, game_manager):
		return targets

	for slot_index in BoardQuery.get_adjacent_slots(user.slot_index, game_manager.board_columns, game_manager.board_states.size()):
		var state := game_manager.get_board_state(slot_index)
		if is_valid_burst_target(user, state):
			targets.append(state)

	return targets


func execute(user: CardState, _target: CardState, game_manager: GameManager) -> void:
	if user == null or game_manager == null:
		return
	if not can_start(user, game_manager):
		return

	var targets := get_valid_targets(user, game_manager)
	if targets.is_empty():
		return

	if not pay_action_cost(user):
		return

	var stored_damage := get_stored_venom_damage(user)
	clear_stored_venom(user)

	var allocation := allocation_resolver.allocate_integer(stored_damage, targets)
	var damaged_states: Array[CardState] = []
	for allocated_target in allocation.keys():
		var target_state := allocated_target as CardState
		if target_state == null:
			continue

		var amount := int(allocation[allocated_target])
		if amount <= 0:
			continue

		if game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, "gu_trap_trigger")
		target_state.take_damage(amount)
		damaged_states.append(target_state)

	if not damaged_states.is_empty():
		await game_manager.resolve_dead_states(damaged_states, EffectData.DEATH_REASON_POISON, user)


func requires_target() -> bool:
	return false


func is_controlled_face_up_building(user: CardState, game_manager: GameManager) -> bool:
	if user == null or game_manager == null:
		return false
	if user.is_empty() or not user.is_face_up or not user.is_building():
		return false

	var current_player := game_manager.get_current_player()
	if current_player == null:
		return false

	return user.is_owned_by(current_player.id)


func is_valid_burst_target(source_state: CardState, target_state: CardState) -> bool:
	return (
		target_state != null
		and BoardQuery.is_face_up_minion(target_state)
		and not target_state.has_keyword(CardData.KEYWORD_MECHANICAL)
		and target_state.owner_id != ""
		and target_state.owner_id != source_state.owner_id
	)


func has_valid_burst_target(source_state: CardState, game_manager: GameManager) -> bool:
	if source_state == null or game_manager == null:
		return false

	for slot_index in BoardQuery.get_adjacent_slots(source_state.slot_index, game_manager.board_columns, game_manager.board_states.size()):
		if is_valid_burst_target(source_state, game_manager.get_board_state(slot_index)):
			return true

	return false


func get_stored_venom_damage(state: CardState) -> int:
	if state == null:
		return 0

	var status := state.get_status(CardStatus.STATUS_STORED_VENOM)
	if status == null:
		return 0

	return status.get_stored_venom_damage()


func clear_stored_venom(state: CardState) -> void:
	if state == null:
		return

	state.remove_status(CardStatus.STATUS_STORED_VENOM)
