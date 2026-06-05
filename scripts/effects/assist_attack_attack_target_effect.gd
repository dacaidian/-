extends CardEffect
class_name AssistAttackAttackTargetEffect

# Passive assist attack against the attack target stored in event context.
# It checks the helper's normal attack range, but does not spend its action or
# attack count and does not trigger occupy.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if source_state == null or game_manager == null:
		return
	if source_state.current_attack <= 0 and not source_state.has_keyword(CardData.KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK):
		return

	var target_state := effect_data.get(EventContext.ATTACK_TARGET_STATE) as CardState
	if not BoardQuery.is_face_up_unit(target_state):
		return

	var attack_action := AttackAction.new()
	var profile := attack_action.get_attack_profile(source_state, target_state, game_manager)
	if not bool(profile.get(AttackAction.PROFILE_CAN_ATTACK, false)):
		return

	await game_manager.play_card_attack_animation(source_state, target_state, bool(profile.get(AttackAction.PROFILE_IS_MELEE, false)))
	if not BoardQuery.is_face_up_unit(target_state):
		return

	var attack_damage := attack_action.calculate_attack_damage(source_state, target_state)
	var was_reflected := await attack_action.resolve_bronze_head_iron_arms(source_state, target_state, attack_damage, game_manager)
	if was_reflected:
		return

	target_state.take_damage(attack_action.apply_armor_to_attack_damage(target_state, attack_damage))
	if target_state.current_health <= 0 and game_manager.has_method("resolve_attack_kill"):
		await game_manager.resolve_attack_kill(source_state, target_state, false)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if source_state == null or game_manager == null:
		return false

	var target_state := effect_data.get(EventContext.ATTACK_TARGET_STATE) as CardState
	if not BoardQuery.is_face_up_unit(target_state):
		return false

	var attack_action := AttackAction.new()
	var profile := attack_action.get_attack_profile(source_state, target_state, game_manager)
	return bool(profile.get(AttackAction.PROFILE_CAN_ATTACK, false))
