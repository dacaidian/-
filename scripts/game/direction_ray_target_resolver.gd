extends RefCounted
class_name DirectionRayTargetResolver

# Resolves direction geometry into gameplay targets. Selection UI and AI both
# consume these results so ray stopping and target legality cannot diverge.


func get_valid_results(game_manager: GameManager, request: SelectionRequest) -> Array[SelectionResult]:
	var results: Array[SelectionResult] = []
	if not is_valid_request(game_manager, request):
		return results

	for direction in request.get_direction_vectors():
		var result := resolve_direction(game_manager, request, direction)
		if result.ray_slots.is_empty():
			continue
		if request.require_hit and result.hit_state == null:
			continue
		results.append(result)

	return results


func resolve_direction(
	game_manager: GameManager,
	request: SelectionRequest,
	direction: Vector2i
) -> SelectionResult:
	if not is_valid_request(game_manager, request):
		return SelectionResult.cancelled_result(SelectionRequest.KIND_DIRECTION_RAY)

	var ray_slots := BoardQuery.get_ray_slots(
		request.origin_slot,
		direction,
		game_manager.board_columns,
		game_manager.board_states.size(),
		request.max_distance
	)
	var hit_state := find_hit_state(game_manager, request, ray_slots)
	var hit_slot := hit_state.slot_index if hit_state != null else -1
	return SelectionResult.direction_ray_result(
		request.origin_slot,
		direction,
		ray_slots,
		hit_slot,
		hit_state
	)


func find_hit_state(
	game_manager: GameManager,
	request: SelectionRequest,
	ray_slots: Array[int]
) -> CardState:
	for slot_index in ray_slots:
		var states := game_manager.get_board_states_at_slot(slot_index)
		for state in states:
			if not BoardQuery.is_face_up_unit(state):
				continue

			var matches := matches_hit_rule(game_manager, request, state)
			if request.stop_rule == SelectionRequest.STOP_FIRST_UNIT:
				return state if matches else null
			if matches:
				return state

	return null


func matches_hit_rule(
	game_manager: GameManager,
	request: SelectionRequest,
	target_state: CardState
) -> bool:
	if request.hit_target_rule == "":
		return BoardQuery.is_face_up_unit(target_state)

	return SpellTargetResolver.can_target(
		request.hit_target_rule,
		target_state,
		[],
		request.source_state,
		request.source_owner_id,
		game_manager,
		false
	)


func is_valid_request(game_manager: GameManager, request: SelectionRequest) -> bool:
	return (
		game_manager != null
		and request != null
		and request.kind == SelectionRequest.KIND_DIRECTION_RAY
		and request.origin_slot >= 0
		and request.origin_slot < game_manager.board_states.size()
	)
