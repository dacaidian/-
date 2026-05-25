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

	for state in game_manager.board_states:
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
	if target.current_health <= 0:
		await game_manager.resolve_attack_kill(user, target, attack_profile[PROFILE_CAN_OCCUPY])

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
		profile[PROFILE_CAN_OCCUPY] = target.is_unit()
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

	return is_neighbor(user.slot_index, target.slot_index, board_columns)


func is_ranged_attack_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false

	if not user.has_keyword(CardData.KEYWORD_RANGED):
		return false

	for anchor_state in game_manager.board_states:
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
