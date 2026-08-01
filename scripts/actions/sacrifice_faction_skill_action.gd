extends CardAction
class_name SacrificeFactionSkillAction

const ACTION_ID := "faction_skill:sacrifice"
const RESOURCE_TAIL := "tail"

var skill_data: Dictionary = {}


func setup(value: Dictionary) -> SacrificeFactionSkillAction:
	skill_data = value.duplicate(true)
	id = ACTION_ID
	display_name = str(skill_data.get("name", "献祭"))
	action_group = ""
	main_action_cost = 0
	return self


func can_start(_user: CardState, game_manager: GameManager) -> bool:
	var player := get_current_player(game_manager)
	if player == null:
		return false

	return player.can_use_faction_skill(get_skill_id())


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.get_all_board_states():
		if can_target(user, state, game_manager):
			targets.append(state)

	return targets


func can_target(_user: CardState, target: CardState, game_manager: GameManager) -> bool:
	var player := get_current_player(game_manager)
	if player == null or target == null:
		return false

	return (
		BoardQuery.is_face_up_minion(target)
		and target.is_owned_by(player.id)
		and not target.is_hero()
	)


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	var player := get_current_player(game_manager)
	if player == null or target == null:
		return
	if not can_start(user, game_manager) or not can_target(user, target, game_manager):
		return
	if not player.register_faction_skill_use(get_skill_id()):
		return

	var matching_modifiers := get_matching_skill_modifiers(player)
	var suppress_resource_gain := should_suppress_resource_gain(matching_modifiers)
	await execute_before_target_effects(player, target, game_manager, matching_modifiers)

	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(
			target,
			"nine_tail_sacrifice" if suppress_resource_gain else "sacrifice"
		)

	await game_manager.destroy_card_with_refill(target, "faction_skill_sacrifice", user, true)
	if not suppress_resource_gain:
		player.gain_faction_resource(str(skill_data.get("resource_id", RESOURCE_TAIL)), int(skill_data.get("amount", 1)))
	if game_manager.has_method("refresh_hand_passives_for_player"):
		game_manager.refresh_hand_passives_for_player(player, player == game_manager.get_current_player())


func get_skill_id() -> String:
	return str(skill_data.get("id", "sacrifice"))


func get_current_player(game_manager: GameManager) -> PlayerState:
	if game_manager == null:
		return null
	return game_manager.get_current_player()


func get_matching_skill_modifiers(player: PlayerState) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	if player == null:
		return modifiers

	var skill_id := get_skill_id()
	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not effect_data is Dictionary:
				continue

			var modifier_data: Dictionary = effect_data
			if not is_matching_skill_modifier(modifier_data, player, skill_id):
				continue

			modifiers.append(modifier_data)

	return modifiers


func is_matching_skill_modifier(effect_data: Dictionary, player: PlayerState, skill_id: String) -> bool:
	if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_FACTION_SKILL:
		return false

	if EffectData.get_trigger(effect_data) != EffectData.TRIGGER_WHILE_IN_HAND:
		return false

	if not EffectData.get_skill_ids(effect_data).has(skill_id):
		return false

	return is_effect_condition_met(effect_data, player)


func is_effect_condition_met(effect_data: Dictionary, player: PlayerState) -> bool:
	var required_resource_id := EffectData.get_required_resource_id(effect_data)
	if required_resource_id != "":
		var required_min := EffectData.get_required_resource_min(effect_data)
		if player.get_faction_resource_value(required_resource_id) < required_min:
			return false

	return true


func execute_before_target_effects(
	player: PlayerState,
	target: CardState,
	game_manager: GameManager,
	modifiers: Array[Dictionary]
) -> void:
	if player == null or target == null or game_manager == null:
		return

	for modifier in modifiers:
		for effect_data in EffectData.get_before_target_effects(modifier):
			var runtime_effect_data := effect_data.duplicate(true)
			apply_modifier_scope_to_runtime_effect(modifier, runtime_effect_data)
			EffectData.mark_effect_owner(runtime_effect_data, player.id)
			EffectData.mark_selected_target(runtime_effect_data, target)
			await game_manager.effect_registry.execute_effect(null, runtime_effect_data, game_manager)


func apply_modifier_scope_to_runtime_effect(modifier: Dictionary, runtime_effect_data: Dictionary) -> void:
	if EffectData.get_target(runtime_effect_data, "") != EffectData.TARGET_OWNER_CARD_BY_ID:
		return

	if EffectData.get_target_card_id(runtime_effect_data) != "":
		return

	if not EffectData.get_card_ids(runtime_effect_data).is_empty():
		return

	var scoped_card_ids := EffectData.get_card_ids(modifier)
	if scoped_card_ids.is_empty():
		return

	runtime_effect_data[EffectData.KEY_CARD_IDS] = scoped_card_ids


func should_suppress_resource_gain(modifiers: Array[Dictionary]) -> bool:
	for modifier in modifiers:
		if EffectData.should_suppress_resource_gain(modifier):
			return true

	return false
