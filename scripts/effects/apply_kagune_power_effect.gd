extends CardEffect
class_name ApplyKagunePowerEffect

const KagunePowerResolverScript := preload("res://scripts/game/kagune_power_resolver.gd")

var kagune_power_resolver := KagunePowerResolverScript.new()


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var owner := get_effect_owner(source_state, effect_data, game_manager)
	if owner == null or not kagune_power_resolver.handles(owner):
		return

	var kagune_types := EffectData.get_keywords(effect_data)
	if kagune_types.is_empty():
		return

	var is_high_concentration := owner.faction_runtime_state_id == KagunePowerResolver.HIGH_RC_STATE_ID
	var runtime_effect_data := effect_data.duplicate(true)
	runtime_effect_data[EffectData.KEY_STATUS_PAYLOAD] = kagune_power_resolver.create_kagune_payload(
		kagune_types,
		is_high_concentration
	)
	var tags := EffectData.get_status_tags(runtime_effect_data)
	if not tags.has(KagunePowerResolver.STATUS_TAG):
		tags.append(KagunePowerResolver.STATUS_TAG)
	runtime_effect_data[EffectData.KEY_STATUS_TAGS] = tags

	for target_state in get_target_states(source_state, runtime_effect_data, game_manager):
		if target_state == null or not target_state.is_minion():
			continue

		var status := CardStatus.from_effect_data(runtime_effect_data, target_state, source_state)
		status.source_card_id = str(runtime_effect_data.get(EffectData.KEY_SOURCE_CARD_ID, status.status_id))
		target_state.add_status(status)

		var apply_animation := str(runtime_effect_data.get("apply_animation", ""))
		if apply_animation != "" and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, apply_animation)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var owner := get_effect_owner(source_state, effect_data, game_manager)
	if owner == null or not kagune_power_resolver.handles(owner):
		return false
	if EffectData.get_keywords(effect_data).is_empty():
		return false
	return not get_target_states(source_state, effect_data, game_manager).is_empty()


func get_effect_owner(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var owner_id := get_effect_owner_id(source_state, effect_data)
	return game_manager.get_player_by_id(owner_id) as PlayerState if owner_id != "" else null
