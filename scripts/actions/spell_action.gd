extends CardAction
class_name SpellAction

var spell_data: Dictionary = {}
var target_rule := SpellTargetResolver.TARGET_RULE_ALL_MINIONS
var effects: Array[Dictionary] = []


func setup(new_spell_data: Dictionary) -> SpellAction:
	spell_data = new_spell_data.duplicate(true)
	var spell_id := str(spell_data.get("id", ""))
	id = "spell:%s" % spell_id
	display_name = str(spell_data.get("name", spell_id))
	action_group = CardState.ACTION_GROUP_SPELL
	can_reuse_action_group = false
	target_rule = SpellTargetResolver.get_rule_from_spell_data(spell_data)
	effects.clear()

	var raw_effects = spell_data.get("effects", [])
	if raw_effects is Array:
		for effect_data in raw_effects:
			if effect_data is Dictionary:
				effects.append(effect_data)

	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false

	if effects.is_empty():
		return false

	return can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	if not requires_target():
		return targets

	return SpellTargetResolver.get_valid_targets(target_rule, game_manager)


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or game_manager == null:
		return

	if not can_start(user, game_manager):
		return

	if requires_target() and not can_target(user, target, game_manager):
		return

	if not pay_action_cost(user):
		return

	if SpellTargetResolver.is_area_rule(target_rule):
		await game_manager.play_area_spell_animation(user, target, spell_data)
	else:
		var animation_target := target if requires_target() else user
		await game_manager.play_spell_cast_animation(user, animation_target, spell_data)

	for effect_data in effects:
		var runtime_effect_data := effect_data.duplicate(true)
		if requires_target():
			EffectData.mark_selected_target(runtime_effect_data, target)
		EffectData.mark_spell_power_enabled(runtime_effect_data)
		EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_SPELL)
		await game_manager.effect_registry.execute_effect(user, runtime_effect_data, game_manager)

	record_successful_spell_cast(user, game_manager)


func requires_target() -> bool:
	return SpellTargetResolver.requires_target(target_rule)


func get_area_info() -> Dictionary:
	if SpellTargetResolver.is_area_rule(target_rule):
		return SpellTargetResolver.get_area_dimensions(target_rule)
	return {}


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	return SpellTargetResolver.can_target(target_rule, target)


func record_successful_spell_cast(user: CardState, game_manager: GameManager) -> void:
	if user == null or game_manager == null:
		return

	var owner := game_manager.get_player_by_id(user.owner_id) as PlayerState
	if owner == null:
		return

	owner.record_spell_action(user.card_id, spell_data)
