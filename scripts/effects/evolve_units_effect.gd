extends CardEffect
class_name EvolveUnitsEffect

# Replaces matching board units with a new CardData instance. Evolution creates a
# fresh unit: combat stats, health, shield, action resources, statuses and origin
# are all reset by CardState.set_card_data().


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null:
		return

	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id == "":
		target_card_id = EffectData.get_card_id(effect_data)
	if target_card_id == "":
		return

	var target_data := gm.get_card_data_by_id(target_card_id) as CardData
	if target_data == null or not target_data.is_minion():
		return

	var states := get_evolution_targets(source_state, effect_data, gm)
	var animation_key := str(effect_data.get("animation", ""))
	if not states.is_empty() and animation_key != "":
		await gm.play_multi_target_effect_animation(states, animation_key)
	for state in states:
		evolve_state(state, target_data)
		await gm.resolve_board_entry_triggers(
			state,
			EventContext.BOARD_ENTRY_PERMANENT_TRANSFORM
		)
		if not state.is_empty():
			await gm.check_and_destroy_if_dead(
				state,
				EffectData.DEATH_REASON_EFFECT
			)

	if not states.is_empty():
		gm.refresh_action_available_hints()
		gm.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	if gm == null:
		return false

	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id == "":
		target_card_id = EffectData.get_card_id(effect_data)
	if target_card_id == "":
		return false

	var target_data := gm.get_card_data_by_id(target_card_id) as CardData
	if target_data == null or not target_data.is_minion():
		return false

	return not get_evolution_targets(source_state, effect_data, gm).is_empty()


func get_evolution_targets(source_state: CardState, effect_data: Dictionary, gm: GameManager) -> Array[CardState]:
	var selected_state := EffectData.get_selected_target_state(effect_data)
	if selected_state != null:
		var selected_targets: Array[CardState] = []
		if can_evolve_state(selected_state, effect_data, ""):
			selected_targets.append(selected_state)
		return selected_targets

	var owner_id := get_effect_owner_id(source_state, effect_data)
	var targets: Array[CardState] = []
	for state in gm.get_all_board_states():
		if can_evolve_state(state, effect_data, owner_id):
			targets.append(state)

	return targets


func can_evolve_state(state: CardState, effect_data: Dictionary, owner_id: String) -> bool:
	if not BoardQuery.is_face_up_minion(state):
		return false
	if state.is_pending_death:
		return false
	if owner_id != "" and state.owner_id != owner_id:
		return false

	var source_card_ids := EffectData.get_card_ids(effect_data)
	if not source_card_ids.is_empty() and not source_card_ids.has(state.card_id):
		return false

	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id == "":
		target_card_id = EffectData.get_card_id(effect_data)
	return target_card_id != "" and state.card_id != target_card_id


func evolve_state(state: CardState, target_data: CardData) -> void:
	var owner_id := state.owner_id
	state.set_card_data(target_data)
	state.owner_id = owner_id
	state.is_face_up = true
	state.state_changed.emit(state)
