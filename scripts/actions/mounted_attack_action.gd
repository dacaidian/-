extends CardAction
class_name MountedAttackAction

const ACTION_ID := "mounted_attack"

var action_data: Dictionary = {}
var rider_card_id := ""
var attack_amount := 0
var attack_speed := 1
var attack_range := EffectData.RANGE_MELEE


func setup(config: Dictionary) -> MountedAttackAction:
	action_data = config.duplicate(true)
	var configured_id := EffectData.get_action_id(action_data)
	id = configured_id if configured_id != "" else ACTION_ID
	display_name = str(action_data.get("name", "骑乘攻击"))
	rider_card_id = EffectData.get_rider_card_id(action_data)
	attack_amount = maxi(EffectData.get_amount(action_data), 0)
	attack_speed = maxi(EffectData.get_attack_speed(action_data), 0)
	attack_range = EffectData.get_range(action_data)
	action_group = CardState.ACTION_GROUP_SPECIAL
	main_action_cost = 0
	can_reuse_action_group = false
	once_per_turn = false
	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false
	if attack_amount <= 0 or rider_card_id == "":
		return false
	if user.get_mounted_attack_uses(id) <= 0:
		return false

	return can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.get_all_board_states():
		if can_target(user, state, game_manager):
			targets.append(state)

	return targets


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false

	var attack_action := AttackAction.new()
	if not attack_action.is_attackable_unit_target(user, target):
		return false

	if attack_action.is_melee_attack_target(user, target, game_manager.board_columns):
		return true

	if attack_range == EffectData.RANGE_RANGED:
		return is_mounted_ranged_attack_target(user, target, game_manager, attack_action)

	return false


func is_mounted_ranged_attack_target(
	user: CardState,
	target: CardState,
	game_manager: GameManager,
	attack_action: AttackAction
) -> bool:
	for anchor_state in game_manager.get_all_board_states():
		if not attack_action.is_ranged_anchor(user, anchor_state):
			continue

		if target == anchor_state:
			return true

		if attack_action.is_neighbor(anchor_state.slot_index, target.slot_index, game_manager.board_columns):
			return true

	return false


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return
	if not can_start(user, game_manager) or not can_target(user, target, game_manager):
		return
	if not pay_action_cost(user):
		return
	if not user.spend_mounted_attack_use(id):
		return

	var is_melee := attack_range != EffectData.RANGE_RANGED and AttackAction.new().is_melee_attack_target(user, target, game_manager.board_columns)
	await game_manager.play_card_attack_animation(user, target, is_melee)
	var damage := AttackAction.new().apply_armor_to_attack_damage(target, calculate_damage(user, target, game_manager))
	target.take_damage(damage)
	game_manager.resolve_dead_states([target], EffectData.DEATH_REASON_EFFECT, user)


func calculate_damage(user: CardState, target: CardState, game_manager: GameManager) -> int:
	var damage := attack_amount + get_rider_attack_bonus(user, game_manager)
	if target != null and target.is_building():
		damage += get_rider_siege_bonus(game_manager)

	return maxi(damage, 0)


func get_rider_attack_bonus(user: CardState, game_manager: GameManager) -> int:
	if user == null or game_manager == null:
		return 0

	var owner := game_manager.get_player_by_id(user.owner_id) as PlayerState
	if owner == null:
		return 0

	var passive_resolver := HandPassiveResolver.new()
	var attack_bonus_by_card_id := passive_resolver.get_unit_attack_bonuses(owner)
	return int(attack_bonus_by_card_id.get(rider_card_id, 0))


func get_rider_siege_bonus(game_manager: GameManager) -> int:
	if game_manager == null or not game_manager.has_method("get_card_data_by_id"):
		return 0

	var rider_data := game_manager.get_card_data_by_id(rider_card_id) as CardData
	if rider_data == null:
		return 0

	return rider_data.get_siege_bonus()
