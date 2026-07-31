extends CardAction
class_name MoveAction

# 移动行动：随从和相邻空格/背面牌交换位置。
# teleport 关键字允许跳过相邻限制，选择全场合法空位。

func _init() -> void:
	id = "move"
	display_name = "移动"
	action_group = CardState.ACTION_GROUP_MOVE


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false

	return (user.can_move() and can_pay_action_cost(user)) or has_beast_path_move_target(user, game_manager)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.board_states:
		if can_target(user, state, game_manager):
			targets.append(state)

	return targets


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return

	if not can_target(user, target, game_manager):
		return

	var movement_animation_key := get_movement_animation_key(user)
	if user.is_flying():
		if not can_start(user, game_manager):
			return
		if not pay_action_cost(user):
			return
		if not user.spend_movement():
			return
		await game_manager.move_flying_card_to_slot(user, target.slot_index, movement_animation_key)
		return

	if is_beast_path_move_target(user, target, game_manager):
		await game_manager.swap_board_slot_contents(user, target)
		return

	if not can_start(user, game_manager):
		return

	if not pay_action_cost(user):
		return

	if not user.spend_movement():
		return

	await game_manager.swap_board_slot_contents(user, target, movement_animation_key)


func get_movement_animation_key(user: CardState) -> String:
	if user == null or user.data == null:
		return ""
	if user.data.faction_id == "monkey_spirit" and user.has_keyword(CardData.KEYWORD_TELEPORT):
		return "monkey_somersault_move"
	return ""


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null or game_manager.board_columns <= 0:
		return false

	if user == target:
		return false

	if user.is_flying():
		if not game_manager.has_method("can_place_aerial_card_on_slot"):
			return false
		if not game_manager.can_place_aerial_card_on_slot(target.slot_index):
			return false
	elif game_manager.has_method("can_place_ground_card_on_slot"):
		if not game_manager.can_place_ground_card_on_slot(target.slot_index):
			return false

	if not user.has_keyword(CardData.KEYWORD_TELEPORT) and not is_neighbor(user.slot_index, target.slot_index, game_manager.board_columns):
		if not is_beast_path_move_target(user, target, game_manager):
			return false

	if user.is_flying():
		return true

	return target.is_empty() or not target.is_face_up


func is_beast_path_move_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false
	if user == target or user.is_flying():
		return false
	if user.has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION):
		return false
	if not is_beastmen_ground_minion(user):
		return false
	if not game_manager.has_method("are_slots_connected_by_beast_path"):
		return false
	if not game_manager.are_slots_connected_by_beast_path(user.slot_index, target.slot_index):
		return false
	if game_manager.has_method("can_place_ground_card_on_slot") and not game_manager.can_place_ground_card_on_slot(target.slot_index):
		return false
	return target.is_empty() or not target.is_face_up


func has_beast_path_move_target(user: CardState, game_manager: GameManager) -> bool:
	if user == null or game_manager == null:
		return false

	for state in game_manager.board_states:
		if is_beast_path_move_target(user, state, game_manager):
			return true

	return false


func is_beastmen_ground_minion(user: CardState) -> bool:
	return (
		user != null
		and user.data != null
		and user.data.faction_id == "beastmen"
		and user.is_minion()
		and not user.is_flying()
	)
