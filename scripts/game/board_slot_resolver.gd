extends RefCounted
class_name BoardSlotResolver

# BoardSlotResolver 负责棋盘格被填充、清空和从公共牌池补位的规则。
# 它不处理死亡原因、区域归属或玩家交互，只围绕“某个 slot 是否能放入下一张牌”工作。


func draw_card_to_slot(game_manager: GameManager, slot_index: int) -> bool:
	if game_manager == null:
		return false

	if game_manager.card_pool == null or game_manager.card_pool.is_empty():
		return false

	if game_manager.has_method("can_refill_ground_slot") and not game_manager.can_refill_ground_slot(slot_index):
		return false

	var state := game_manager.get_board_state(slot_index)
	if state == null or not state.is_empty():
		return false

	var card_data := game_manager.card_pool.draw_random()
	state.set_card_data(card_data)
	state.set_face_up(false)
	game_manager.update_card_pool_view()
	game_manager.refresh_debug_panel()
	return true


func refill_board_slot_from_pool(game_manager: GameManager, slot_index: int) -> bool:
	if game_manager == null:
		return false

	if game_manager.card_pool == null or game_manager.card_pool.is_empty():
		return false

	if game_manager.has_method("can_refill_ground_slot") and not game_manager.can_refill_ground_slot(slot_index):
		return false

	var state := game_manager.get_board_state(slot_index)
	if state == null or not state.is_empty():
		return false

	var card_data := game_manager.card_pool.draw_random()
	game_manager.update_card_pool_view()
	game_manager.call_deferred("animate_refill_board_slot", slot_index, card_data)
	game_manager.refresh_debug_panel()
	return true


func clear_board_slot(game_manager: GameManager, slot_index: int) -> void:
	if game_manager == null:
		return

	var state := game_manager.get_board_state(slot_index)
	if state == null:
		return

	state.clear_card()
	game_manager.refresh_debug_panel()


func refill_empty_board_slots(game_manager: GameManager, max_count: int = -1) -> int:
	if game_manager == null:
		return 0

	var filled_count := 0

	for state in game_manager.board_states:
		if max_count >= 0 and filled_count >= max_count:
			break

		if not state.is_empty():
			continue
		if game_manager.has_method("can_refill_ground_slot") and not game_manager.can_refill_ground_slot(state.slot_index):
			continue

		if draw_card_to_slot(game_manager, state.slot_index):
			filled_count += 1
		else:
			break

	game_manager.refresh_debug_panel()
	return filled_count
