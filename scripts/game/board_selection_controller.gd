extends RefCounted
class_name BoardSelectionController

const BoardLineSelectionControllerScript := preload("res://scripts/game/board_line_selection_controller.gd")
const BoardDirectionSelectionControllerScript := preload("res://scripts/game/board_direction_selection_controller.gd")

# Entry point for multi-step board selections.
# Existing selectors can migrate behind this facade one at a time.


func select(game_manager: GameManager, request: SelectionRequest) -> SelectionResult:
	if game_manager == null or request == null:
		return SelectionResult.cancelled_result("")

	match request.kind:
		SelectionRequest.KIND_LINE_VECTOR:
			var line_controller := BoardLineSelectionControllerScript.new()
			return await line_controller.select_line_result(game_manager, request)
		SelectionRequest.KIND_DIRECTION_RAY:
			var direction_controller := BoardDirectionSelectionControllerScript.new()
			return await direction_controller.select_direction_result(game_manager, request)
		_:
			push_warning("Unsupported board selection kind: %s" % request.kind)
			return SelectionResult.cancelled_result(request.kind)
