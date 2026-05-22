extends RefCounted
class_name GrantedUnitTriggerResolver

# Grants trigger effects from hand upgrades to matching board units.
# Example: an upgrade can give selected units an after_attack poison package.


func execute_granted_triggers(
	source_state: CardState,
	trigger: String,
	game_manager: Node,
	context: Dictionary = {}
) -> void:
	if source_state == null or trigger == "" or game_manager == null:
		return
	if source_state.owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return

	var owner := game_manager.get_player_by_id(source_state.owner_id) as PlayerState
	if owner == null:
		return

	for grant_data in get_grants_for_source(owner, source_state, trigger):
		for effect_data in EffectData.get_granted_effects(grant_data):
			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
			EffectData.mark_effect_owner(runtime_effect_data, owner.id)
			EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
			await game_manager.effect_registry.execute_effect(source_state, runtime_effect_data, game_manager)


func get_grants_for_source(player: PlayerState, source_state: CardState, trigger: String) -> Array[Dictionary]:
	var grants: Array[Dictionary] = []
	if player == null or source_state == null:
		return grants

	for hand_entry in player.hand:
		var card_data := HandCardState.get_card_data(hand_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not effect_data is Dictionary:
				continue
			if not is_active_grant(effect_data):
				continue
			if EffectData.get_granted_trigger(effect_data) != trigger:
				continue
			if not matches_source_card(effect_data, source_state):
				continue

			grants.append(effect_data)

	return grants


func is_active_grant(effect_data: Dictionary) -> bool:
	if EffectData.get_id(effect_data) != EffectData.EFFECT_GRANT_UNIT_TRIGGER_EFFECTS:
		return false

	var trigger := EffectData.get_trigger(effect_data)
	if trigger == "":
		return EffectData.is_active_in_hand(effect_data)

	return trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE


func matches_source_card(effect_data: Dictionary, source_state: CardState) -> bool:
	var card_ids := EffectData.get_card_ids(effect_data)
	return card_ids.is_empty() or card_ids.has(source_state.card_id)
