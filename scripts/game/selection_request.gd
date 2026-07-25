extends RefCounted
class_name SelectionRequest

# Describes a board selection workflow without knowing how the UI will collect it.
# Effects and actions should create a request, then consume SelectionResult.

const KIND_LINE_VECTOR := "line_vector"
const KIND_DIRECTION_RAY := "direction_ray"

const DIRECTIONS_4_WAY := "4_way"
const DIRECTIONS_8_WAY := "8_way"

const STOP_FIRST_UNIT := "first_unit"
const STOP_FIRST_MATCHING := "first_matching"

var kind := ""
var title := ""
var directions := DIRECTIONS_8_WAY

var line_length := 0

var origin_slot := -1
var max_distance := -1
var stop_rule := STOP_FIRST_UNIT
var hit_target_rule := ""
var source_owner_id := ""
var source_state: CardState
var require_hit := false


static func line_vector(title_text: String, length: int, direction_mode := DIRECTIONS_8_WAY) -> SelectionRequest:
	var request := SelectionRequest.new()
	request.kind = KIND_LINE_VECTOR
	request.title = title_text
	request.line_length = maxi(length, 2)
	request.directions = direction_mode
	return request


static func direction_ray(
	origin: int,
	title_text: String,
	direction_mode := DIRECTIONS_8_WAY,
	distance := -1,
	hit_rule := "",
	owner_id := "",
	source: CardState = null,
	ray_stop_rule := STOP_FIRST_UNIT,
	must_hit := false
) -> SelectionRequest:
	var request := SelectionRequest.new()
	request.kind = KIND_DIRECTION_RAY
	request.title = title_text
	request.origin_slot = origin
	request.directions = direction_mode
	request.max_distance = distance
	request.hit_target_rule = hit_rule
	request.source_owner_id = owner_id
	request.source_state = source
	request.stop_rule = ray_stop_rule
	request.require_hit = must_hit
	return request


func get_direction_vectors() -> Array[Vector2i]:
	return BoardQuery.get_direction_vectors(directions)
