extends CardEffect
class_name MoonbladeEffect

const BoardUnitBounceSelectionControllerScript := preload("res://scripts/game/board_unit_bounce_selection_controller.gd")


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if source_state == null or gm == null:
		return

	var first_target := EffectData.get_selected_target_state(effect_data)
	if not is_valid_moonblade_target(first_target):
		return

	var second_target := await choose_second_target(source_state, first_target, effect_data, gm)
	if second_target == null:
		return

	var damage := maxi(source_state.current_attack, 0)
	if damage <= 0:
		return

	if gm.has_method("play_moonblade_animation"):
		await gm.play_moonblade_animation(source_state, first_target, second_target)

	var damaged_states: Array[CardState] = []
	if is_valid_moonblade_target(first_target):
		first_target.take_damage(damage)
		damaged_states.append(first_target)
	if is_valid_moonblade_target(second_target):
		second_target.take_damage(damage)
		damaged_states.append(second_target)

	if not damaged_states.is_empty():
		await gm.resolve_dead_states(damaged_states, EffectData.DEATH_REASON_SPELL, source_state)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	if source_state == null or gm == null:
		return false

	var first_target := EffectData.get_selected_target_state(effect_data)
	if first_target != null:
		return (
			is_valid_moonblade_target(first_target)
			and not get_adjacent_bounce_targets(first_target, gm).is_empty()
		)

	for state in gm.board_states:
		if not is_valid_moonblade_target(state):
			continue
		if not get_adjacent_bounce_targets(state, gm).is_empty():
			return true

	return false


func choose_second_target(
	source_state: CardState,
	first_target: CardState,
	effect_data: Dictionary,
	gm: GameManager
) -> CardState:
	var candidates := get_adjacent_bounce_targets(first_target, gm)
	if candidates.is_empty():
		return null

	var owner := gm.get_player_by_id(source_state.owner_id) as PlayerState
	if owner != null and owner.is_ai:
		return choose_ai_second_target(candidates, source_state.owner_id)

	var controller := BoardUnitBounceSelectionControllerScript.new() as BoardUnitBounceSelectionController
	return await controller.select_second_unit(
		gm,
		first_target,
		candidates,
		str(effect_data.get(EffectData.KEY_SECOND_SELECTION_TITLE, "选择月刃弹射目标")),
		"请选择第一个目标相邻的随从。"
	)


func get_adjacent_bounce_targets(first_target: CardState, gm: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if first_target == null or gm == null:
		return targets

	for slot_index in BoardQuery.get_adjacent_slots(first_target.slot_index, gm.board_columns, gm.board_states.size()):
		var state := gm.get_board_state(slot_index) as CardState
		if state == first_target:
			continue
		if is_valid_moonblade_target(state):
			targets.append(state)

	return targets


func is_valid_moonblade_target(state: CardState) -> bool:
	return (
		state != null
		and not state.is_pending_death
		and BoardQuery.is_face_up_minion(state)
		and SpellTargetResolver.can_spell_affect(state)
	)


func choose_ai_second_target(candidates: Array[CardState], owner_id: String) -> CardState:
	var best_target: CardState = null
	var best_score := -999999.0
	for target in candidates:
		if target == null:
			continue

		var score := float(target.current_attack + target.current_health)
		if target.owner_id != "" and target.owner_id != owner_id:
			score += 100.0
		else:
			score -= 50.0

		if score > best_score:
			best_score = score
			best_target = target

	return best_target
