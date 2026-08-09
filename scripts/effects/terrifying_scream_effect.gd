extends CardEffect
class_name TerrifyingScreamEffect

# Venom emits one board-local spell pulse. Damage resolves first; surviving
# adjacent enemy minions then receive Fear with a stable source-slot fallback.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var fear_source := resolve_fear_source(source_state, effect_data, game_manager)
	if fear_source == null:
		return

	var targets := get_valid_targets(fear_source, effect_data, game_manager)
	if targets.is_empty():
		return

	var damage := get_spell_scaled_amount(fear_source, effect_data, game_manager)
	var fear_animation := str(effect_data.get("apply_animation", "symbiote_fear_apply"))
	if (
		fear_animation != ""
		and game_manager.has_method("play_multi_target_effect_animation")
	):
		await game_manager.play_multi_target_effect_animation(targets, fear_animation)

	for target_state in targets:
		target_state.take_damage(damage)
	if game_manager.has_method("resolve_dead_states"):
		await game_manager.resolve_dead_states(
			targets,
			EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_HAND_SPELL),
			fear_source,
			get_effect_owner_id(fear_source, effect_data)
		)

	for target_state in targets:
		if not BoardQuery.is_face_up_minion(target_state) or target_state.is_pending_death:
			continue
		var status_data := effect_data.duplicate(true)
		var payload := EffectData.get_status_payload(status_data)
		payload[EffectData.KEY_FEAR_SOURCE_SLOT] = fear_source.slot_index
		status_data[EffectData.KEY_STATUS_PAYLOAD] = payload
		target_state.add_status(CardStatus.from_effect_data(status_data, target_state, fear_source))

	if game_manager.has_method("refresh_action_available_hints"):
		game_manager.refresh_action_available_hints()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var fear_source := resolve_fear_source(source_state, effect_data, game_manager)
	return fear_source != null and not get_valid_targets(
		fear_source,
		effect_data,
		game_manager
	).is_empty()


func resolve_fear_source(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> CardState:
	if BoardQuery.is_face_up_minion(source_state):
		return source_state
	if game_manager == null or not game_manager.has_method("get_all_board_states"):
		return null

	var owner_id := get_effect_owner_id(source_state, effect_data)
	var source_card_id := EffectData.get_target_card_id(effect_data)
	if owner_id == "" or source_card_id == "":
		return null
	for board_state in game_manager.get_all_board_states():
		var candidate := board_state as CardState
		if (
			BoardQuery.is_face_up_minion(candidate)
			and candidate.owner_id == owner_id
			and candidate.represents_card_id(source_card_id)
		):
			return candidate
	return null


func get_valid_targets(
	fear_source: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> Array[CardState]:
	var targets := get_adjacent_enemy_minions(fear_source, game_manager, true)
	return filter_spell_immune_targets(targets, effect_data)
