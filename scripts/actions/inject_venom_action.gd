extends CardAction
class_name InjectVenomAction

const ACTION_ID := "inject_venom"
const FOUNTAIN_CARD_ID := "venomous_fountain"

var poison_attack_resolver := PoisonAttackResolver.new()


func _init() -> void:
	id = ACTION_ID
	display_name = "注入毒液"
	action_group = CardState.ACTION_GROUP_SPECIAL
	can_reuse_action_group = false


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false
	if poison_attack_resolver.get_poison_attack_package(user, game_manager).is_empty():
		return false

	return can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.board_states:
		if can_target(user, state, game_manager):
			targets.append(state)

	return targets


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false
	if not BoardQuery.is_face_up_unit(target):
		return false
	if target.card_id != FOUNTAIN_CARD_ID:
		return false
	if target.owner_id == "" or target.owner_id != user.owner_id:
		return false

	var attack_profile := AttackAction.new().get_attack_profile(user, target, game_manager)
	return bool(attack_profile[AttackAction.PROFILE_CAN_ATTACK])


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return
	if not can_start(user, game_manager) or not can_target(user, target, game_manager):
		return

	var package := poison_attack_resolver.get_poison_attack_package(user, game_manager)
	var total_damage := int(package.get(PoisonAttackResolver.POISON_TOTAL_DAMAGE, 0))
	if total_damage <= 0:
		return
	if not pay_action_cost(user):
		return

	target.add_status(create_stored_venom_status(user, target, total_damage))
	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(target, "gu_infusion")


func create_stored_venom_status(source_state: CardState, target_state: CardState, total_damage: int) -> CardStatus:
	var effect_data := {
		EffectData.KEY_STATUS_ID: CardStatus.STATUS_STORED_VENOM,
		EffectData.KEY_STATUS_NAME: "储毒",
		EffectData.KEY_STATUS_DESCRIPTION: "剧毒之泉储存的毒性伤害。",
		EffectData.KEY_STATUS_TAGS: [CardStatus.TAG_STORED_RESOURCE],
		EffectData.KEY_STATUS_PERMANENT: true,
		EffectData.KEY_STATUS_STACK_POLICY: CardStatus.STACK_POLICY_STACK,
		EffectData.KEY_STATUS_PAYLOAD: {
			EffectData.KEY_STORED_VENOM_DAMAGE: total_damage
		}
	}
	return CardStatus.from_effect_data(effect_data, target_state, source_state)
