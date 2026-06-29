extends RefCounted
class_name BoardQuery

# BoardQuery 提供棋盘几何与常用单位过滤。
# 规则层需要“相邻”“正面单位”“正面随从”时优先走这里，避免各模块重复计算格子。

const DIRECTIONS_4_WAY := "4_way"
const DIRECTIONS_8_WAY := "8_way"


static func get_direction_vectors(direction_mode := DIRECTIONS_8_WAY) -> Array[Vector2i]:
	var directions: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(1, 0)
	]
	if direction_mode == DIRECTIONS_8_WAY:
		directions = [
			Vector2i(-1, -1),
			Vector2i(-1, 0),
			Vector2i(-1, 1),
			Vector2i(0, -1),
			Vector2i(0, 1),
			Vector2i(1, -1),
			Vector2i(1, 0),
			Vector2i(1, 1)
		]

	return directions

static func is_neighbor(from_slot: int, to_slot: int, board_columns: int) -> bool:
	if board_columns <= 0:
		return false

	var from_row: int = floori(float(from_slot) / float(board_columns))
	var from_column: int = from_slot % board_columns
	var to_row: int = floori(float(to_slot) / float(board_columns))
	var to_column: int = to_slot % board_columns
	var row_distance: int = abs(from_row - to_row)
	var column_distance: int = abs(from_column - to_column)

	return row_distance <= 1 and column_distance <= 1 and row_distance + column_distance > 0


static func get_adjacent_slots(slot_index: int, board_columns: int, board_size: int) -> Array[int]:
	var adjacent_slots: Array[int] = []
	if slot_index < 0 or board_columns <= 0 or board_size <= 0:
		return adjacent_slots

	var source_row: int = floori(float(slot_index) / float(board_columns))
	var source_column: int = slot_index % board_columns
	var board_rows: int = int(ceil(float(board_size) / float(board_columns)))

	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			if row_offset == 0 and column_offset == 0:
				continue

			var target_row: int = source_row + row_offset
			var target_column: int = source_column + column_offset
			if target_row < 0 or target_row >= board_rows:
				continue
			if target_column < 0 or target_column >= board_columns:
				continue

			var target_slot: int = target_row * board_columns + target_column
			if target_slot < 0 or target_slot >= board_size:
				continue

			adjacent_slots.append(target_slot)

	return adjacent_slots


static func get_slot_row(slot_index: int, board_columns: int) -> int:
	if slot_index < 0 or board_columns <= 0:
		return -1

	return floori(float(slot_index) / float(board_columns))


static func get_slot_column(slot_index: int, board_columns: int) -> int:
	if slot_index < 0 or board_columns <= 0:
		return -1

	return slot_index % board_columns


static func get_slot_at_row_col(row: int, column: int, board_columns: int, board_size: int) -> int:
	if row < 0 or column < 0 or board_columns <= 0 or board_size <= 0:
		return -1

	var board_rows := int(ceil(float(board_size) / float(board_columns)))
	if row >= board_rows or column >= board_columns:
		return -1

	var slot := row * board_columns + column
	return slot if slot >= 0 and slot < board_size else -1


static func get_slot_at_offset(start_slot: int, offset: Vector2i, board_columns: int, board_size: int) -> int:
	var row := get_slot_row(start_slot, board_columns)
	var column := get_slot_column(start_slot, board_columns)
	if row < 0 or column < 0:
		return -1

	return get_slot_at_row_col(row + offset.x, column + offset.y, board_columns, board_size)


static func get_line_end_slots(
	start_slot: int,
	line_length: int,
	board_columns: int,
	board_size: int,
	direction_mode := DIRECTIONS_8_WAY
) -> Array[int]:
	var slots: Array[int] = []
	if line_length <= 1:
		return slots

	for direction in get_direction_vectors(direction_mode):
		var end_slot := get_slot_at_offset(start_slot, direction * (line_length - 1), board_columns, board_size)
		if end_slot >= 0:
			slots.append(end_slot)

	return slots


static func get_line_slots(
	start_slot: int,
	end_slot: int,
	line_length: int,
	board_columns: int,
	board_size: int,
	direction_mode := DIRECTIONS_8_WAY
) -> Array[int]:
	var slots: Array[int] = []
	if start_slot < 0 or end_slot < 0 or line_length <= 1 or board_columns <= 0 or board_size <= 0:
		return slots

	var start_row := get_slot_row(start_slot, board_columns)
	var start_col := get_slot_column(start_slot, board_columns)
	var end_row := get_slot_row(end_slot, board_columns)
	var end_col := get_slot_column(end_slot, board_columns)
	var row_delta := end_row - start_row
	var col_delta := end_col - start_col
	var steps := line_length - 1
	var row_step := signi(row_delta)
	var col_step := signi(col_delta)
	var direction := Vector2i(row_step, col_step)

	if not get_direction_vectors(direction_mode).has(direction):
		return slots
	if abs(row_delta) != abs(row_step) * steps:
		return slots
	if abs(col_delta) != abs(col_step) * steps:
		return slots
	if row_step == 0 and col_step == 0:
		return slots

	for index in range(line_length):
		var slot := get_slot_at_row_col(start_row + row_step * index, start_col + col_step * index, board_columns, board_size)
		if slot < 0:
			slots.clear()
			return slots
		slots.append(slot)

	return slots


static func get_ray_slots(
	origin_slot: int,
	direction: Vector2i,
	board_columns: int,
	board_size: int,
	max_distance := -1
) -> Array[int]:
	var slots: Array[int] = []
	if origin_slot < 0 or direction == Vector2i.ZERO or board_columns <= 0 or board_size <= 0:
		return slots

	var row := get_slot_row(origin_slot, board_columns)
	var column := get_slot_column(origin_slot, board_columns)
	var distance := 1
	while max_distance < 0 or distance <= max_distance:
		var slot := get_slot_at_row_col(row + direction.x * distance, column + direction.y * distance, board_columns, board_size)
		if slot < 0:
			break
		slots.append(slot)
		distance += 1

	return slots


static func is_face_up_board_card(state: CardState) -> bool:
	return state != null and not state.is_empty() and state.is_face_up


static func is_face_up_unit(state: CardState) -> bool:
	return is_face_up_board_card(state) and state.is_unit()


static func is_face_up_minion(state: CardState) -> bool:
	return is_face_up_board_card(state) and state.is_minion()


static func get_face_up_minions(board_states: Array[CardState]) -> Array[CardState]:
	var targets: Array[CardState] = []
	for state in board_states:
		if is_face_up_minion(state):
			targets.append(state)

	return targets


static func has_face_up_hero(board_states: Array[CardState], owner_id: String, hero_card_id: String) -> bool:
	if owner_id == "" or hero_card_id == "":
		return false

	for state in board_states:
		if not is_face_up_board_card(state):
			continue
		if state.owner_id == owner_id and state.represents_card_id(hero_card_id) and state.is_hero():
			return true

	return false


static func get_area_slots(center_slot: int, area_rows: int, area_cols: int, board_columns: int, board_size: int) -> Array[int]:
	var slots: Array[int] = []
	var total_rows: int = int(ceil(float(board_size) / float(board_columns)))
	var center_row: int = floori(float(center_slot) / float(board_columns))
	var center_col: int = center_slot % board_columns
	var before_rows: int = floori(float(area_rows - 1) / 2.0)
	var before_cols: int = floori(float(area_cols - 1) / 2.0)
	var after_rows: int = area_rows - 1 - before_rows
	var after_cols: int = area_cols - 1 - before_cols

	for row_offset in range(-before_rows, after_rows + 1):
		for col_offset in range(-before_cols, after_cols + 1):
			var row: int = center_row + row_offset
			var col: int = center_col + col_offset
			if row < 0 or row >= total_rows or col < 0 or col >= board_columns:
				continue
			slots.append(row * board_columns + col)

	return slots


static func signi(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


static func is_full_area_inside_board(anchor_slot: int, area_rows: int, area_cols: int, board_columns: int, board_size: int) -> bool:
	if anchor_slot < 0 or area_rows <= 0 or area_cols <= 0 or board_columns <= 0 or board_size <= 0:
		return false

	return get_area_slots(anchor_slot, area_rows, area_cols, board_columns, board_size).size() == area_rows * area_cols
