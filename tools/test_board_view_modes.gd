extends SceneTree

const CardBoardScene := preload("res://scenes/card_board/card_board.tscn")
const BoardViewToggleControllerScript := preload("res://scripts/ui/board_view_toggle_controller.gd")


class FakeGameManager:
	extends Node
	var busy := false
	var cancel_count := 0

	func is_game_busy() -> bool:
		return busy

	func cancel_interaction() -> void:
		cancel_count += 1

	func prepare_board_view_change() -> void:
		cancel_interaction()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.name = "BoardViewTestHost"
	host.size = Vector2(1440.0, 1000.0)
	root.add_child(host)

	var board := CardBoardScene.instantiate() as Control
	board.name = "CardBoard"
	host.add_child(board)
	await process_frame
	await process_frame

	var grid := board.get_node("MarginContainer/GridContainer") as GridContainer
	if grid == null or grid.get_child_count() != 49:
		return _fail("CardBoard did not preserve all 49 logical slots")
	if bool(board.get("is_full_board_view")):
		return _fail("CardBoard did not start in compact view")
	if grid.columns != 5:
		return _fail("Compact view did not use five visible columns")

	var expected_compact_indices: Array[int] = []
	for row in range(1, 6):
		for column in range(1, 6):
			expected_compact_indices.append(row * 7 + column)
	var compact_indices: Array[int] = board.call("get_visible_slot_indices")
	if compact_indices != expected_compact_indices:
		return _fail("Compact view did not expose the central 5x5 slots")
	if _count_visible_slots(grid) != 25:
		return _fail("Compact view did not hide exactly the outer ring")

	var stable_inner_slot := grid.get_child(8) as Control
	var compact_slot_size := stable_inner_slot.size
	if compact_slot_size.x <= 0.0 or compact_slot_size.y <= 0.0:
		return _fail("Compact slots were not laid out")
	if not (grid.get_child(8) as Control).visible or (grid.get_child(0) as Control).visible:
		return _fail("Compact slot visibility is incorrect")

	var mode_change_counter := {"count": 0}
	board.connect(
		"view_mode_changed",
		func(_is_full: bool): mode_change_counter["count"] = int(mode_change_counter["count"]) + 1
	)
	board.call("set_full_board_view", true)
	await process_frame
	await process_frame
	if grid.columns != 7 or _count_visible_slots(grid) != 49:
		return _fail("Full view did not restore all 49 slots")
	if grid.get_child(8) != stable_inner_slot:
		return _fail("View switching rebuilt or reordered logical slots")
	var full_slot_size := stable_inner_slot.size
	if compact_slot_size.x <= full_slot_size.x or compact_slot_size.y <= full_slot_size.y:
		return _fail("Compact view did not enlarge card presentation")

	board.call("set_full_board_view", false)
	await process_frame
	var central_slots: Array[int] = [8, 9, 15]
	if bool(board.call("ensure_slots_visible", central_slots)):
		return _fail("Central slots unexpectedly forced full view")
	var outer_slots: Array[int] = [0]
	if not bool(board.call("ensure_slots_visible", outer_slots)):
		return _fail("Outer slot did not force full view")
	await process_frame
	if not bool(board.get("is_full_board_view")) or not (grid.get_child(0) as Control).visible:
		return _fail("Outer-slot visibility safeguard did not expand the board")
	if not stable_inner_slot.size.is_equal_approx(full_slot_size):
		return _fail("One layout frame did not settle full-view animation coordinates")
	if int(mode_change_counter["count"]) != 3:
		return _fail("Board view mode signal count was not stable")

	var toggle := CheckButton.new()
	host.add_child(toggle)
	var fake_game_manager := FakeGameManager.new()
	host.add_child(fake_game_manager)
	var toggle_controller = BoardViewToggleControllerScript.new()
	toggle_controller.setup(fake_game_manager, host, board, toggle)
	board.call("set_full_board_view", false)
	await process_frame
	if toggle.button_pressed:
		return _fail("View toggle did not synchronize compact state")
	fake_game_manager.busy = true
	toggle.set_pressed_no_signal(true)
	toggle.toggled.emit(true)
	await process_frame
	if bool(board.get("is_full_board_view")) or toggle.button_pressed:
		return _fail("Busy match allowed a mid-animation board view switch")
	fake_game_manager.busy = false
	toggle.set_pressed_no_signal(true)
	toggle.toggled.emit(true)
	await process_frame
	if not bool(board.get("is_full_board_view")) or not toggle.button_pressed:
		return _fail("View toggle did not switch to full board mode")
	if fake_game_manager.cancel_count != 1:
		return _fail("View toggle did not clear pending interaction exactly once")

	host.queue_free()
	await process_frame
	if root.get_child_count() != 0:
		return _fail("Board view test leaked nodes")
	print("BOARD_VIEW_MODE_TESTS_OK")
	quit()


func _count_visible_slots(grid: GridContainer) -> int:
	var result := 0
	for child in grid.get_children():
		var slot := child as Control
		if slot != null and slot.visible:
			result += 1
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
