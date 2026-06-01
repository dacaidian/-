extends CardAction
class_name EffectAction

# Generic board action driven by JSON. It lets buildings and special units reuse
# the normal target-selection + EffectRegistry pipeline without custom action
# classes for every card.

var action_data: Dictionary = {}
var target_rule := SpellTargetResolver.TARGET_RULE_NONE
var target_card_ids: Array[String] = []
var effects: Array[Dictionary] = []
var animation := ""
var required_runtime_state_ids: Array[String] = []


func setup(new_action_data: Dictionary) -> EffectAction:
	action_data = new_action_data.duplicate(true)
	id = EffectData.get_action_id(action_data)
	display_name = str(action_data.get("name", id))
	target_rule = str(action_data.get(EffectData.KEY_TARGET_RULE, SpellTargetResolver.TARGET_RULE_NONE))
	target_card_ids = EffectData.get_card_ids(action_data)
	animation = str(action_data.get("animation", id))
	main_action_cost = int(action_data.get("main_action_cost", 1))
	action_group = str(action_data.get("action_group", CardState.ACTION_GROUP_SPECIAL))
	can_reuse_action_group = bool(action_data.get("can_reuse_action_group", false))
	once_per_turn = bool(action_data.get("once_per_turn", false))
	required_runtime_state_ids = get_required_runtime_state_ids(action_data)
	effects.clear()

	var raw_effects: Variant = action_data.get("effects", [])
	if raw_effects is Array:
		for effect_data in raw_effects:
			if effect_data is Dictionary:
				effects.append(effect_data)

	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_unit(user, game_manager):
		return false
	if id == "" or effects.is_empty():
		return false
	if not is_runtime_state_allowed(user, game_manager):
		return false

	return can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager) or not requires_target():
		return targets

	for target in SpellTargetResolver.get_valid_targets(target_rule, game_manager, target_card_ids, user):
		if can_effects_execute_with_target(user, target, game_manager):
			targets.append(target)

	return targets


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if not requires_target():
		return true
	if not SpellTargetResolver.can_target(target_rule, target, target_card_ids, user):
		return false

	return can_effects_execute_with_target(user, target, game_manager)


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or game_manager == null:
		return
	if not can_start(user, game_manager):
		return
	if requires_target() and not can_target(user, target, game_manager):
		return
	if not pay_action_cost(user):
		return

	if animation != "":
		var animation_data := action_data.duplicate(true)
		animation_data["animation"] = animation
		var animation_target := target if requires_target() else user
		await game_manager.play_spell_cast_animation(user, animation_target, animation_data)

	for effect_data in effects:
		var runtime_effect_data := effect_data.duplicate(true)
		if requires_target():
			EffectData.mark_selected_target(runtime_effect_data, target)
		EffectData.mark_effect_owner(runtime_effect_data, user.owner_id)
		EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
		await game_manager.effect_registry.execute_effect(user, runtime_effect_data, game_manager)


func requires_target() -> bool:
	return SpellTargetResolver.requires_target(target_rule)


func get_area_info() -> Dictionary:
	if SpellTargetResolver.is_area_rule(target_rule):
		return SpellTargetResolver.get_area_dimensions(target_rule)
	return {}


func can_effects_execute_with_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if game_manager == null or game_manager.effect_registry == null:
		return false

	for effect_data in effects:
		var runtime_effect_data := effect_data.duplicate(true)
		if target != null:
			EffectData.mark_selected_target(runtime_effect_data, target)
		EffectData.mark_effect_owner(runtime_effect_data, user.owner_id if user != null else "")
		if not game_manager.effect_registry.can_execute_effect(user, runtime_effect_data, game_manager):
			return false

	return true


func is_controlled_face_up_unit(user: CardState, game_manager: GameManager) -> bool:
	if user == null or game_manager == null:
		return false
	if user.is_empty() or not user.is_face_up or not user.is_unit():
		return false

	var current_player := game_manager.get_current_player() as PlayerState
	return current_player != null and user.is_owned_by(current_player.id)


func is_runtime_state_allowed(user: CardState, game_manager: GameManager) -> bool:
	if required_runtime_state_ids.is_empty():
		return true

	var owner := game_manager.get_player_by_id(user.owner_id) as PlayerState
	return owner != null and required_runtime_state_ids.has(owner.faction_runtime_state_id)


func get_required_runtime_state_ids(data: Dictionary) -> Array[String]:
	var state_ids := EffectData.get_runtime_state_ids(data)
	var required_state_id := str(data.get(EffectData.KEY_REQUIRED_RUNTIME_STATE_ID, ""))
	if required_state_id != "" and not state_ids.has(required_state_id):
		state_ids.append(required_state_id)

	return state_ids
