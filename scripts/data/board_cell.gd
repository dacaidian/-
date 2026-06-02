extends Resource
class_name BoardCell

# BoardCell represents the board-cell properties currently occupying a board
# coordinate. The UI slot coordinate stays fixed, but effects such as Arcane
# Space may swap the cell properties between coordinates.
# Current gameplay uses the ground_state layer. The aerial_states layer is
# reserved for future flying units that can share a coordinate with ground units.

const LAYER_GROUND := "ground"
const LAYER_AERIAL := "aerial"

var slot_index := -1
var row := -1
var column := -1
var is_land := true
var ground_state: CardState
var aerial_states: Array[CardState] = []


func setup(index: int, board_columns: int, land_value: bool) -> void:
	slot_index = index
	row = floori(float(index) / float(board_columns)) if board_columns > 0 else -1
	column = index % board_columns if board_columns > 0 else -1
	is_land = land_value


func can_hold_ground() -> bool:
	return is_land


func can_refill_ground() -> bool:
	return is_land and ground_state != null and ground_state.is_empty()


func can_place_ground_card() -> bool:
	if not is_land or ground_state == null:
		return false
	if ground_state.is_empty():
		return true
	return not ground_state.is_face_up


func get_primary_aerial_state() -> CardState:
	if aerial_states.is_empty():
		return null

	return aerial_states[0]


func can_place_aerial_card() -> bool:
	var aerial_state := get_primary_aerial_state()
	return aerial_state != null and aerial_state.is_empty()


func swap_cell_properties_with(other_cell: BoardCell) -> void:
	if other_cell == null:
		return

	var self_is_land := is_land
	is_land = other_cell.is_land
	other_cell.is_land = self_is_land


func has_aerial_units() -> bool:
	return not aerial_states.is_empty()
