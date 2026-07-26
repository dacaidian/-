extends RefCounted
class_name StatusModifierResolver

# StatusModifierResolver rewrites status application data before CardStatus is created.
# It lets hand upgrades change how their owner applies statuses without hard-coding
# specific cards or status sources inside ApplyStatusEffect.


func resolve_status_effect_data(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> Dictionary:
	var runtime_effect_data := effect_data.duplicate(true)
	var owner := get_effect_owner(source_state, effect_data, game_manager)
	if owner == null:
		return runtime_effect_data

	for modifier_data in get_status_modifiers(owner):
		if not applies_to_status(modifier_data, runtime_effect_data):
			continue

		runtime_effect_data = apply_modifier(runtime_effect_data, modifier_data)

	return runtime_effect_data


func get_effect_owner(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var owner_id := ""
	if source_state != null and source_state.owner_id != "":
		owner_id = source_state.owner_id
	else:
		owner_id = EffectData.get_effect_owner_id(effect_data)

	if owner_id == "":
		return null

	return game_manager.get_player_by_id(owner_id) as PlayerState


func get_status_modifiers(player: PlayerState) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	if player == null:
		return modifiers

	for hand_entry in player.hand:
		var card_data := HandCardState.get_card_data(hand_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not effect_data is Dictionary:
				continue
			if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_APPLIED_STATUS:
				continue
			if not is_active_modifier(effect_data):
				continue

			modifiers.append(effect_data)

	return modifiers


func is_active_modifier(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	if trigger == "":
		return EffectData.is_active_in_hand(effect_data)

	return trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE


func applies_to_status(modifier_data: Dictionary, effect_data: Dictionary) -> bool:
	var status_id := EffectData.get_status_id(effect_data)
	if status_id == "":
		return false

	var status_ids := EffectData.get_status_ids(modifier_data)
	return status_ids.is_empty() or status_ids.has(status_id)


func apply_modifier(effect_data: Dictionary, modifier_data: Dictionary) -> Dictionary:
	var modified_effect_data := effect_data.duplicate(true)

	if modifier_data.has(EffectData.KEY_SET_DURATION_TURNS):
		var next_duration := maxi(int(modifier_data.get(EffectData.KEY_SET_DURATION_TURNS, 1)), 1)
		if bool(modifier_data.get(EffectData.KEY_PRESERVE_TOTAL_DAMAGE, false)):
			preserve_total_damage(modified_effect_data, next_duration)
		modified_effect_data[EffectData.KEY_STATUS_DURATION_TURNS] = next_duration
		modified_effect_data[EffectData.KEY_STATUS_PERMANENT] = false

	return modified_effect_data


func preserve_total_damage(effect_data: Dictionary, next_duration: int) -> void:
	if EffectData.get_status_id(effect_data) != CardStatus.STATUS_POISON:
		return
	if next_duration <= 0:
		return

	var payload := EffectData.get_status_payload(effect_data)
	var poison_damage := int(payload.get(EffectData.KEY_POISON_DAMAGE, 0))
	var current_duration := EffectData.get_status_duration_turns(effect_data)
	if poison_damage <= 0 or current_duration <= 0:
		return

	var total_damage := poison_damage * current_duration
	payload[EffectData.KEY_POISON_DAMAGE] = int(ceil(float(total_damage) / float(next_duration)))
	payload[EffectData.KEY_STATUS_COMPRESSED] = true
	effect_data[EffectData.KEY_STATUS_PAYLOAD] = payload
