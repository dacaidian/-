extends RefCounted
class_name BoardLayerResolver

# BoardLayerResolver owns board layer queries and slot capability checks.
# GameManager keeps the public facade for compatibility, while this resolver
# centralizes the 7x7 ground/aerial layer semantics.

func is_land_slot(game_manager: GameManager, slot_index: int) -> bool:
	if game_manager == null:
		return false
	if slot_index < 0 or game_manager.board_columns <= 0 or game_manager.board_rows <= 0:
		return false

	var row := floori(float(slot_index) / float(game_manager.board_columns))
	var column := slot_index % game_manager.board_columns
	return (
		row > 0
		and row < game_manager.board_rows - 1
		and column > 0
		and column < game_manager.board_columns - 1
	)


func get_board_cell(game_manager: GameManager, slot_index: int) -> BoardCell:
	if game_manager == null:
		return null
	if slot_index < 0 or slot_index >= game_manager.board_cells.size():
		return null

	return game_manager.board_cells[slot_index]

func get_aerial_state(game_manager: GameManager, slot_index: int) -> CardState:
	if game_manager == null:
		return null
	if slot_index < 0 or slot_index >= game_manager.aerial_board_states.size():
		return null

	return game_manager.aerial_board_states[slot_index]


func get_all_board_states(game_manager: GameManager) -> Array[CardState]:
	var states: Array[CardState] = []
	if game_manager == null:
		return states

	states.append_array(game_manager.board_states)
	states.append_array(game_manager.aerial_board_states)
	return states


func get_board_states_at_slot(
	game_manager: GameManager,
	slot_index: int,
	include_empty := false
) -> Array[CardState]:
	var states: Array[CardState] = []
	if game_manager == null:
		return states

	var ground_state: CardState = null
	if slot_index >= 0 and slot_index < game_manager.board_states.size():
		ground_state = game_manager.board_states[slot_index]
	if ground_state != null and (include_empty or not ground_state.is_empty()):
		states.append(ground_state)

	var aerial_state := get_aerial_state(game_manager, slot_index)
	if aerial_state != null and (include_empty or not aerial_state.is_empty()):
		states.append(aerial_state)

	return states


func can_refill_ground_slot(game_manager: GameManager, slot_index: int) -> bool:
	var cell := get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_refill_ground()


func can_place_ground_card_on_slot(game_manager: GameManager, slot_index: int) -> bool:
	var cell := get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_place_ground_card()


func can_place_aerial_card_on_slot(game_manager: GameManager, slot_index: int) -> bool:
	var cell := get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_place_aerial_card()


func sync_board_cell_state_flags(game_manager: GameManager, slot_index: int) -> void:
	if game_manager == null:
		return

	var cell := get_board_cell(game_manager, slot_index)
	var state := game_manager.get_board_state(slot_index)
	if cell == null or state == null:
		return

	cell.ground_state = state
	var can_interact := cell.can_hold_ground()
	if state.is_interactable != can_interact:
		state.is_interactable = can_interact
		state.state_changed.emit(state)

	var aerial_state := get_aerial_state(game_manager, slot_index)
	if aerial_state != null and aerial_state.is_interactable != true:
		aerial_state.is_interactable = true
		aerial_state.state_changed.emit(aerial_state)

	game_manager.sync_slot_card_layout(slot_index)


func get_land_slot_states(game_manager: GameManager) -> Array[bool]:
	var land_states: Array[bool] = []
	if game_manager == null:
		return land_states

	for cell in game_manager.board_cells:
		land_states.append(cell != null and cell.is_land)

	return land_states
