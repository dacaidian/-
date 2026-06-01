extends CardEffect
class_name SacrificeFriendlyMinionsEffect

# Sacrifices all current friendly non-hero minions one by one. Each sacrifice
# re-reads faction skill modifiers, so resource thresholds such as Nine Tails can
# become active midway through a mass sacrifice.

const RESOURCE_TAIL := "tail"
const SKILL_SACRIFICE := "sacrifice"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null:
		return

	var player := get_effect_owner_player(source_state, effect_data, gm)
	if player == null:
		return

	var targets := get_sacrifice_targets(player, gm)
	for target in targets:
		if not can_sacrifice_target(player, target):
			continue

		var modifiers := get_matching_skill_modifiers(player, SKILL_SACRIFICE)
		await execute_before_target_effects(player, target, gm, modifiers)

		if gm.has_method("play_status_apply_animation"):
			await gm.play_status_apply_animation(target, "sacrifice")

		gm.destroy_card_with_refill(target, "mass_sacrifice", source_state, true)
		if not should_suppress_resource_gain(modifiers):
			player.gain_faction_resource(
				str(effect_data.get(EffectData.KEY_RESOURCE_ID, RESOURCE_TAIL)),
				int(effect_data.get(EffectData.KEY_AMOUNT, 1))
			)

		if gm.has_method("refresh_hand_passives_for_player"):
			gm.refresh_hand_passives_for_player(player, player == gm.get_current_player())


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	if gm == null:
		return false

	var player := get_effect_owner_player(source_state, effect_data, gm)
	return player != null


func get_effect_owner_player(source_state: CardState, effect_data: Dictionary, gm: GameManager) -> PlayerState:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" and source_state != null:
		owner_id = source_state.owner_id
	if owner_id == "":
		var current_player := gm.get_current_player() as PlayerState
		return current_player

	return gm.get_player_by_id(owner_id) as PlayerState


func get_sacrifice_targets(player: PlayerState, gm: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	for state in gm.get_all_board_states():
		if can_sacrifice_target(player, state):
			targets.append(state)

	targets.sort_custom(func(first: CardState, second: CardState) -> bool:
		return first.slot_index < second.slot_index
	)
	return targets


func can_sacrifice_target(player: PlayerState, target: CardState) -> bool:
	return (
		player != null
		and BoardQuery.is_face_up_minion(target)
		and target.is_owned_by(player.id)
		and not target.is_hero()
		and not target.is_pending_death
	)


func get_matching_skill_modifiers(player: PlayerState, skill_id: String) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	if player == null:
		return modifiers

	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not effect_data is Dictionary:
				continue

			var modifier_data: Dictionary = effect_data
			if is_matching_skill_modifier(modifier_data, player, skill_id):
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
	gm: GameManager,
	modifiers: Array[Dictionary]
) -> void:
	for modifier in modifiers:
		for effect_data in EffectData.get_before_target_effects(modifier):
			var runtime_effect_data := effect_data.duplicate(true)
			apply_modifier_scope_to_runtime_effect(modifier, runtime_effect_data)
			EffectData.mark_effect_owner(runtime_effect_data, player.id)
			EffectData.mark_selected_target(runtime_effect_data, target)
			await gm.effect_registry.execute_effect(null, runtime_effect_data, gm)


func apply_modifier_scope_to_runtime_effect(modifier: Dictionary, runtime_effect_data: Dictionary) -> void:
	if EffectData.get_target(runtime_effect_data, "") != EffectData.TARGET_OWNER_CARD_BY_ID:
		return
	if EffectData.get_target_card_id(runtime_effect_data) != "":
		return
	if not EffectData.get_card_ids(runtime_effect_data).is_empty():
		return

	var scoped_card_ids := EffectData.get_card_ids(modifier)
	if not scoped_card_ids.is_empty():
		runtime_effect_data[EffectData.KEY_CARD_IDS] = scoped_card_ids


func should_suppress_resource_gain(modifiers: Array[Dictionary]) -> bool:
	for modifier in modifiers:
		if EffectData.should_suppress_resource_gain(modifier):
			return true

	return false
