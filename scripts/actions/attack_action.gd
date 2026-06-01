extends CardAction
class_name AttackAction

# 普通攻击：默认攻击相邻正面单位，不区分敌我。
# ranged 关键词会扩展目标范围，但只有近战攻击击杀时才触发占领；近战击杀随从或摧毁建筑都可以占领。
const PROFILE_CAN_ATTACK := "can_attack"
const PROFILE_IS_MELEE := "is_melee"
const PROFILE_CAN_OCCUPY := "can_occupy"

func _init() -> void:
	id = "attack"
	display_name = "攻击"
	action_group = CardState.ACTION_GROUP_ATTACK


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false

	if user.current_attack <= 0 and not user.has_keyword(CardData.KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK):
		return false

	return user.can_attack() and can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.get_all_board_states():
		if get_attack_profile(user, state, game_manager)[PROFILE_CAN_ATTACK]:
			targets.append(state)

	return targets


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return

	if not can_start(user, game_manager):
		return

	var attack_profile := get_attack_profile(user, target, game_manager)
	if not attack_profile[PROFILE_CAN_ATTACK]:
		return

	if not pay_action_cost(user):
		return

	if not user.spend_attack():
		return

	var attacker_owner_id := user.owner_id
	var attacker_card_id := user.card_id
	await game_manager.play_card_attack_animation(user, target, attack_profile[PROFILE_IS_MELEE])
	target.take_damage(calculate_attack_damage(user, target))
	var splash_targets := apply_giant_splash_damage(user, target, game_manager)
	if target.current_health <= 0:
		await game_manager.resolve_attack_kill(user, target, attack_profile[PROFILE_CAN_OCCUPY])
	if not splash_targets.is_empty():
		game_manager.resolve_dead_states(splash_targets, "attack", user)

	var trigger_source := user
	if trigger_source.is_empty() or trigger_source.card_id != attacker_card_id:
		trigger_source = game_manager.find_face_up_board_state(attacker_owner_id, attacker_card_id)
	if trigger_source != null:
		await game_manager.resolve_after_attack_triggers(trigger_source, target)


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	return bool(get_attack_profile(user, target, game_manager)[PROFILE_CAN_ATTACK])


func calculate_attack_damage(user: CardState, target: CardState) -> int:
	if user == null:
		return 0

	var damage := user.current_attack
	if target != null and target.is_building():
		damage += user.get_siege_bonus()

	return maxi(damage, 0)


func apply_giant_splash_damage(user: CardState, target: CardState, game_manager: GameManager) -> Array[CardState]:
	var damaged_targets: Array[CardState] = []
	if user == null or target == null or game_manager == null:
		return damaged_targets
	if not user.has_keyword(CardData.KEYWORD_GIANT):
		return damaged_targets

	for slot_index in get_giant_splash_slots(user.slot_index, target.slot_index, game_manager.board_columns, game_manager.board_states.size()):
		for splash_target in game_manager.get_board_states_at_slot(slot_index):
			if splash_target == target:
				continue
			if not can_giant_splash_target(user, splash_target):
				continue

			splash_target.take_damage(calculate_attack_damage(user, splash_target))
			damaged_targets.append(splash_target)

	return damaged_targets


func get_giant_splash_slots(attacker_slot: int, target_slot: int, board_columns: int, board_size: int) -> Array[int]:
	var slots: Array[int] = []
	if attacker_slot == target_slot or board_columns <= 0 or board_size <= 0:
		return slots

	slots.append(target_slot)
	var attacker_row: int = floori(float(attacker_slot) / float(board_columns))
	var attacker_col: int = attacker_slot % board_columns
	var target_row: int = floori(float(target_slot) / float(board_columns))
	var target_col: int = target_slot % board_columns
	var row_delta: int = clampi(target_row - attacker_row, -1, 1)
	var col_delta: int = clampi(target_col - attacker_col, -1, 1)
	if row_delta == 0 and col_delta == 0:
		return slots

	var offsets: Array[Vector2i] = []
	if row_delta != 0 and col_delta != 0:
		offsets.append(Vector2i(row_delta, 0))
		offsets.append(Vector2i(0, col_delta))
	elif row_delta != 0:
		offsets.append(Vector2i(row_delta, -1))
		offsets.append(Vector2i(row_delta, 1))
	elif col_delta != 0:
		offsets.append(Vector2i(-1, col_delta))
		offsets.append(Vector2i(1, col_delta))

	for offset in offsets:
		var slot := get_slot_by_offset(attacker_row, attacker_col, offset, board_columns, board_size)
		if slot >= 0 and not slots.has(slot):
			slots.append(slot)

	return slots


func get_slot_by_offset(row: int, col: int, offset: Vector2i, board_columns: int, board_size: int) -> int:
	var board_rows: int = int(ceil(float(board_size) / float(board_columns)))
	var target_row := row + offset.x
	var target_col := col + offset.y
	if target_row < 0 or target_row >= board_rows:
		return -1
	if target_col < 0 or target_col >= board_columns:
		return -1

	var slot := target_row * board_columns + target_col
	return slot if slot >= 0 and slot < board_size else -1


func can_giant_splash_target(user: CardState, target: CardState) -> bool:
	if user == null or target == null or target == user:
		return false
	if not BoardQuery.is_face_up_unit(target):
		return false
	if target.owner_id == user.owner_id and target.owner_id != "":
		return false

	return true


func get_attack_profile(user: CardState, target: CardState, game_manager: GameManager) -> Dictionary:
	var profile := {
		PROFILE_CAN_ATTACK: false,
		PROFILE_IS_MELEE: false,
		PROFILE_CAN_OCCUPY: false
	}

	if game_manager == null:
		return profile

	if not is_attackable_unit_target(user, target):
		return profile

	if is_melee_attack_target(user, target, game_manager.board_columns):
		profile[PROFILE_CAN_ATTACK] = true
		profile[PROFILE_IS_MELEE] = true
		profile[PROFILE_CAN_OCCUPY] = target.is_unit() and not user.is_flying()
		return profile

	if is_ranged_attack_target(user, target, game_manager):
		profile[PROFILE_CAN_ATTACK] = true

	return profile


func is_attackable_unit_target(user: CardState, target: CardState) -> bool:
	if user == null or target == null:
		return false

	if user == target:
		return false

	if not BoardQuery.is_face_up_unit(target):
		return false

	return true


func is_melee_attack_target(user: CardState, target: CardState, board_columns: int) -> bool:
	if user == null or target == null or board_columns <= 0:
		return false

	if user.slot_index == target.slot_index:
		return user != target

	return is_neighbor(user.slot_index, target.slot_index, board_columns)


func is_ranged_attack_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false

	if not user.has_keyword(CardData.KEYWORD_RANGED):
		return false

	for anchor_state in game_manager.get_all_board_states():
		if not is_ranged_anchor(user, anchor_state):
			continue

		if target == anchor_state:
			return true

		if is_neighbor(anchor_state.slot_index, target.slot_index, game_manager.board_columns):
			return true

	return false


func is_ranged_anchor(user: CardState, anchor_state: CardState) -> bool:
	if user == null or anchor_state == null:
		return false

	if not BoardQuery.is_face_up_minion(anchor_state):
		return false

	return anchor_state.owner_id != "" and anchor_state.owner_id == user.owner_id
