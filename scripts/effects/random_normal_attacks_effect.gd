extends CardEffect
class_name RandomNormalAttacksEffect

const KEY_MAX_TARGETS := "max_targets"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var manager := game_manager as GameManager
	if source_state == null or manager == null:
		return

	var attack_action := AttackAction.new()
	var candidates := get_legal_targets(source_state, manager, attack_action)
	candidates.shuffle()
	var max_targets := maxi(int(effect_data.get(KEY_MAX_TARGETS, 3)), 0)
	var resolved_count := 0
	for target_state in candidates:
		if resolved_count >= max_targets:
			break
		if not BoardQuery.is_face_up_unit(source_state) or source_state.is_pending_death:
			break
		var profile := attack_action.get_attack_profile(source_state, target_state, manager)
		if not bool(profile.get(AttackAction.PROFILE_CAN_ATTACK, false)):
			continue
		await attack_action.perform_attack(source_state, target_state, manager, false)
		resolved_count += 1


func can_execute(source_state: CardState, _effect_data: Dictionary, game_manager: Node) -> bool:
	var manager := game_manager as GameManager
	if source_state == null or manager == null:
		return false
	if not BoardQuery.is_face_up_minion(source_state) or source_state.is_pending_death:
		return false
	if source_state.current_attack <= 0 and not source_state.has_keyword(CardData.KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK):
		return false
	return not get_legal_targets(source_state, manager, AttackAction.new()).is_empty()


func get_legal_targets(
	source_state: CardState,
	game_manager: GameManager,
	attack_action: AttackAction
) -> Array[CardState]:
	var targets: Array[CardState] = []
	if source_state == null or game_manager == null or attack_action == null:
		return targets
	for target_state in game_manager.get_all_board_states():
		var profile := attack_action.get_attack_profile(source_state, target_state, game_manager)
		if bool(profile.get(AttackAction.PROFILE_CAN_ATTACK, false)):
			targets.append(target_state)
	return targets
