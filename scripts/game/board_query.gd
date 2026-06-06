extends RefCounted
class_name BoardQuery

# BoardQuery 提供棋盘几何与常用单位过滤。
# 规则层需要“相邻”“正面单位”“正面随从”时优先走这里，避免各模块重复计算格子。

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


static func is_full_area_inside_board(anchor_slot: int, area_rows: int, area_cols: int, board_columns: int, board_size: int) -> bool:
	if anchor_slot < 0 or area_rows <= 0 or area_cols <= 0 or board_columns <= 0 or board_size <= 0:
		return false

	return get_area_slots(anchor_slot, area_rows, area_cols, board_columns, board_size).size() == area_rows * area_cols
