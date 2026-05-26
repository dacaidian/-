extends RefCounted
class_name BoardLayerResolver

# BoardLayerResolver owns read-only board layer queries and placement checks.
# GameManager keeps the public facade for compatibility, while this resolver
# centralizes the 7x7 ground/aerial layer semantics.

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
	var cell := _get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_refill_ground()


func can_place_ground_card_on_slot(game_manager: GameManager, slot_index: int) -> bool:
	var cell := _get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_place_ground_card()


func can_place_aerial_card_on_slot(game_manager: GameManager, slot_index: int) -> bool:
	var cell := _get_board_cell(game_manager, slot_index)
	return cell != null and cell.can_place_aerial_card()


func _get_board_cell(game_manager: GameManager, slot_index: int) -> BoardCell:
	if game_manager == null:
		return null
	if slot_index < 0 or slot_index >= game_manager.board_cells.size():
		return null

	return game_manager.board_cells[slot_index]
