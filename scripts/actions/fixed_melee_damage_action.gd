extends CardAction
class_name FixedMeleeDamageAction

const ACTION_ID := "fixed_melee_damage"

var damage := 1
var animation_key := ""


func setup(action_data: Dictionary) -> FixedMeleeDamageAction:
	var configured_id := EffectData.get_action_id(action_data)
	id = configured_id if configured_id != "" else ACTION_ID
	display_name = str(action_data.get("name", "爪击"))
	damage = maxi(EffectData.get_amount(action_data), 0)
	animation_key = str(action_data.get("animation", ""))
	action_group = CardState.ACTION_GROUP_SPECIAL
	main_action_cost = 0
	once_per_turn = true
	can_reuse_action_group = false
	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false
	if damage <= 0:
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
	if not AttackAction.new().is_attackable_unit_target(user, target):
		return false

	if user.slot_index == target.slot_index:
		return user != target

	return is_neighbor(user.slot_index, target.slot_index, game_manager.board_columns)


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return
	if not can_start(user, game_manager) or not can_target(user, target, game_manager):
		return
	if not pay_action_cost(user):
		return

	await game_manager.play_card_attack_animation(user, target, true, animation_key)
	target.take_damage(damage)
	await game_manager.resolve_dead_states([target], EffectData.DEATH_REASON_EFFECT, user)
