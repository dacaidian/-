extends RefCounted
class_name SelectionResult

# Normalized result for board selection workflows.
# A selector returns data only; actions/effects decide what gameplay mutation follows.

var kind := ""
var cancelled := false

var selected_slots: Array[int] = []
var start_slot := -1
var end_slot := -1
var path_slots: Array[int] = []

var origin_slot := -1
var direction := Vector2i.ZERO
var ray_slots: Array[int] = []
var hit_slot := -1
var hit_state: CardState


static func cancelled_result(selection_kind: String) -> SelectionResult:
	var result := SelectionResult.new()
	result.kind = selection_kind
	result.cancelled = true
	return result


static func line_vector_result(start: int, end: int, slots: Array[int]) -> SelectionResult:
	var result := SelectionResult.new()
	result.kind = SelectionRequest.KIND_LINE_VECTOR
	result.start_slot = start
	result.end_slot = end
	result.path_slots = slots.duplicate()
	result.selected_slots = slots.duplicate()
	return result


static func direction_ray_result(origin: int, ray_direction: Vector2i, slots: Array[int], first_hit_slot := -1, first_hit_state: CardState = null) -> SelectionResult:
	var result := SelectionResult.new()
	result.kind = SelectionRequest.KIND_DIRECTION_RAY
	result.origin_slot = origin
	result.direction = ray_direction
	result.ray_slots = slots.duplicate()
	result.selected_slots = slots.duplicate()
	result.hit_slot = first_hit_slot
	result.hit_state = first_hit_state
	return result
