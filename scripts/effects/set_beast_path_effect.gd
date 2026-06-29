extends CardEffect
class_name SetBeastPathEffect

const BoardLineSelectionControllerScript := preload("res://scripts/game/board_line_selection_controller.gd")

# Sets a persistent beast path on board cells. The path is stored on BoardCell,
# so Arcane Space moves the tunnel with the cell properties instead of anchoring
# it to a fixed coordinate.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("add_beast_path_to_slots"):
		return

	var line_length := maxi(int(effect_data.get("line_length", 5)), 2)
	var owner_id := get_effect_owner_id(source_state, effect_data)
	var player: PlayerState = null
	if game_manager.has_method("get_player_by_id"):
		player = game_manager.get_player_by_id(owner_id) as PlayerState
	var selected_slots: Array[int] = []

	if player != null and player.is_ai:
		selected_slots = choose_ai_line(game_manager, line_length)
	else:
		var controller := BoardLineSelectionControllerScript.new()
		selected_slots = await controller.select_line(
			game_manager,
			line_length,
			str(effect_data.get(EffectData.KEY_SELECTION_TITLE, "选择一条直线兽径"))
		)

	if selected_slots.is_empty():
		return

	var path_id := "%s_%d_%d" % [str(effect_data.get("path_id_prefix", "beast_path")), Time.get_ticks_msec(), randi()]
	game_manager.add_beast_path_to_slots(selected_slots, path_id)

	var animation_key := str(effect_data.get("animation", "beast_path"))
	if animation_key != "" and game_manager.has_method("play_path_effect_animation"):
		await game_manager.play_path_effect_animation(selected_slots, animation_key)

	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()


func can_execute(_source_state: CardState, _effect_data: Dictionary, game_manager: Node) -> bool:
	return game_manager != null and game_manager.has_method("add_beast_path_to_slots")


func choose_ai_line(game_manager: Node, line_length: int) -> Array[int]:
	if game_manager == null or game_manager.board_columns <= 0:
		return []

	var directions := [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, -1)
	]
	for start_slot in range(game_manager.board_states.size()):
		var start_row := floori(float(start_slot) / float(game_manager.board_columns))
		var start_col := start_slot % game_manager.board_columns
		for direction in directions:
			var slots: Array[int] = []
			for index in range(line_length):
				var row := start_row + direction.x * index
				var col := start_col + direction.y * index
				if row < 0 or col < 0 or row >= game_manager.board_rows or col >= game_manager.board_columns:
					slots.clear()
					break
				slots.append(row * game_manager.board_columns + col)
			if slots.size() == line_length:
				return slots

	return []
