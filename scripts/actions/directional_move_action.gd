extends CardAction
class_name DirectionalMoveAction

# Configured side action that moves a unit one slot in a fixed direction.
# It reuses MoveAction legality and movement execution, but does not spend movement
# unless a future config explicitly makes it a normal move-like action.

const ACTION_ID := "directional_move"
const DIRECTION_LEFT := "left"
const DIRECTION_RIGHT := "right"
const DIRECTION_UP := "up"
const DIRECTION_DOWN := "down"

var action_data: Dictionary = {}
var direction := DIRECTION_LEFT
var spend_movement := false


func setup(new_action_data: Dictionary) -> DirectionalMoveAction:
	action_data = new_action_data.duplicate(true)
	id = EffectData.get_action_id(action_data)
	display_name = str(action_data.get("name", id))
	direction = EffectData.get_direction(action_data)
	if direction == "":
		direction = DIRECTION_LEFT
	main_action_cost = int(action_data.get("main_action_cost", 0))
	action_group = str(action_data.get("action_group", CardState.ACTION_GROUP_SPECIAL))
	can_reuse_action_group = bool(action_data.get("can_reuse_action_group", true))
	once_per_turn = bool(action_data.get("once_per_turn", false))
	spend_movement = bool(action_data.get("spend_movement", false))
	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false
	if id == "" or not can_pay_action_cost(user):
		return false
	if spend_movement and not user.can_move():
		return false

	return get_destination_state(user, game_manager) != null


func requires_target() -> bool:
	return false


func execute(user: CardState, _target: CardState, game_manager: GameManager) -> void:
	if user == null or game_manager == null:
		return
	if not can_start(user, game_manager):
		return
	if not pay_action_cost(user):
		return
	if spend_movement and not user.spend_movement():
		return

	var destination := get_destination_state(user, game_manager)
	if destination == null:
		return

	if user.is_flying():
		await game_manager.move_flying_card_to_slot(user, destination.slot_index)
		return

	await game_manager.swap_board_slot_contents(user, destination)


func get_destination_state(user: CardState, game_manager: GameManager) -> CardState:
	if user == null or game_manager == null or game_manager.board_columns <= 0:
		return null

	var target_slot := get_target_slot(user.slot_index, game_manager.board_columns, game_manager.board_states.size())
	if target_slot < 0 or target_slot >= game_manager.board_states.size():
		return null

	var destination := game_manager.board_states[target_slot] as CardState
	if destination == null:
		return null

	var move_action := MoveAction.new()
	if not move_action.can_target(user, destination, game_manager):
		return null

	return destination


func get_target_slot(slot_index: int, board_columns: int, board_size: int) -> int:
	if slot_index < 0 or board_columns <= 0 or board_size <= 0:
		return -1

	var row := floori(float(slot_index) / float(board_columns))
	var col := slot_index % board_columns
	var target_row := row
	var target_col := col

	match direction:
		DIRECTION_LEFT, "west":
			target_col -= 1
		DIRECTION_RIGHT, "east":
			target_col += 1
		DIRECTION_UP, "north":
			target_row -= 1
		DIRECTION_DOWN, "south":
			target_row += 1
		_:
			return -1

	if target_row < 0 or target_col < 0 or target_col >= board_columns:
		return -1

	var board_rows := int(ceil(float(board_size) / float(board_columns)))
	if target_row >= board_rows:
		return -1

	var target_slot := target_row * board_columns + target_col
	return target_slot if target_slot < board_size else -1
