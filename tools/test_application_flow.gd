extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	test_match_setup_snapshot()
	test_match_result_contract()
	test_surrendering_player_resolution()
	test_scene_contracts_load()
	await test_shell_navigation()
	print("APPLICATION_FLOW_TESTS_OK")
	call_deferred("_finish")


func _finish() -> void:
	quit()


func test_match_setup_snapshot() -> void:
	var setup := MatchSetup.new()
	setup.player_names = ["A", "B"]
	setup.player_faction_ids = ["silver_hand", "dalaran_council"]
	setup.selected_hero_card_ids = ["uther", "antonidas"]
	setup.player_ai_flags = [false, true]
	setup.player_ai_difficulties = ["normal", "hard"]

	var copy := setup.duplicate_configuration()
	setup.player_names[0] = "Changed"
	setup.player_faction_ids[0] = "miaojiang"

	assert(copy.player_names == ["A", "B"])
	assert(copy.player_faction_ids == ["silver_hand", "dalaran_council"])
	assert(copy.selected_hero_card_ids == ["uther", "antonidas"])
	assert(copy.player_ai_flags == [false, true])
	assert(copy.player_ai_difficulties == ["normal", "hard"])


func test_match_result_contract() -> void:
	var winner := _create_player("player_1", "A", "silver_hand", false)
	var loser := _create_player("player_2", "B", "dalaran_council", true)
	winner.resource_score = 42

	var result := MatchResult.create(
		MatchResult.EndReason.SURRENDER,
		winner,
		[winner, loser],
		7,
		80,
		loser
	)

	assert(result.is_surrender())
	assert(result.winner_player_id == winner.id)
	assert(result.surrendered_player_id == loser.id)
	assert(result.get_end_reason_text() == "投降")
	assert(result.get_player_summary(winner.id).get("resource_score") == 42)
	assert(result.to_dictionary().get("turn_number") == 7)


func test_surrendering_player_resolution() -> void:
	var human := _create_player("player_1", "A", "silver_hand", false)
	var ai := _create_player("player_2", "B", "dalaran_council", true)
	var manager := GameManager.new()
	manager.players = [human, ai]
	manager.current_player_index = 1

	assert(manager.get_surrendering_player() == human)
	assert(manager.get_opponent_player(human) == ai)
	assert(manager.can_surrender())

	human.is_ai = true
	assert(manager.get_surrendering_player() == null)
	assert(not manager.can_surrender())
	manager.audio_manager.free()
	manager.free()


func test_scene_contracts_load() -> void:
	assert(ResourceLoader.exists("res://scenes/start_menu/start_menu.tscn"))
	assert(ResourceLoader.exists("res://main.tscn"))
	var match_exit_script := load("res://scripts/ui/match_exit_controller.gd") as Script
	var result_screen_script := load("res://scripts/ui/match_result_screen_controller.gd") as Script
	assert(match_exit_script != null and match_exit_script.new() != null)
	assert(result_screen_script != null and result_screen_script.new() != null)


func test_shell_navigation() -> void:
	var shell_scene := load("res://scenes/app/game_shell.tscn") as PackedScene
	var shell = shell_scene.instantiate()
	root.add_child(shell)
	await process_frame
	assert(shell.current_screen_id == "main_menu")

	shell.show_match_history()
	await process_frame
	assert(shell.current_screen_id == "match_history")

	shell.show_card_collection()
	await process_frame
	assert(shell.current_screen_id == "card_collection")
	assert(shell.current_screen.get_node_or_null("%SearchInput") != null)
	var collection_back_button := shell.current_screen.get_node("%BackButton") as Button
	assert(collection_back_button != null)
	collection_back_button.pressed.emit()
	await process_frame
	assert(shell.current_screen_id == "main_menu")

	var start_button := shell.current_screen.get_node("%StartGameButton") as Button
	assert(start_button != null)
	start_button.pressed.emit()
	await process_frame
	assert(shell.current_screen_id == "faction_selection")
	assert(shell.current_screen.has_signal("match_start_requested"))
	assert(shell.current_screen.has_signal("back_requested"))
	var back_button := shell.current_screen.get_node("%BackButton") as Button
	assert(back_button != null)
	await _click_control(back_button)
	assert(shell.current_screen_id == "main_menu")

	start_button = shell.current_screen.get_node("%StartGameButton") as Button
	start_button.pressed.emit()
	await process_frame
	var battle_start_button := shell.current_screen.get_node(
		"RootMargin/VBoxContainer/Footer/StartButton"
	) as Button
	assert(battle_start_button != null and not battle_start_button.disabled)
	battle_start_button.pressed.emit()
	await process_frame
	assert(shell.current_screen_id == "match")

	var game_manager := shell.current_screen.get_node("GameManager") as GameManager
	assert(game_manager != null)
	assert(game_manager.players.size() == 2)
	assert(game_manager.board_states.size() == 49)
	var card_board := shell.current_screen.get_node("BoardCenter/CardBoard") as Control
	var board_view_toggle := shell.current_screen.get_node("BoardViewToggle") as CheckButton
	var end_turn_button := shell.current_screen.get_node("EndTurnButton") as Button
	assert(card_board != null and board_view_toggle != null)
	assert(end_turn_button != null)
	assert(end_turn_button.custom_minimum_size == Vector2(240.0, 54.0))
	assert(end_turn_button.has_theme_stylebox_override("normal"))
	assert(end_turn_button.has_theme_stylebox_override("hover"))
	assert(end_turn_button.has_theme_stylebox_override("pressed"))
	assert(end_turn_button.has_theme_stylebox_override("disabled"))
	assert(not bool(card_board.get("is_full_board_view")))
	assert((card_board.call("get_visible_slot_indices") as Array).size() == 25)
	var board_rect := card_board.get_global_rect()
	var toggle_rect := board_view_toggle.get_global_rect()
	assert(absf(toggle_rect.get_center().x - board_rect.get_center().x) <= 1.0)
	assert(toggle_rect.end.y <= board_rect.position.y + 1.0)
	board_view_toggle.button_pressed = true
	await process_frame
	assert(bool(card_board.get("is_full_board_view")))
	assert((card_board.call("get_visible_slot_indices") as Array).size() == 49)
	board_view_toggle.button_pressed = false
	await process_frame
	assert(not bool(card_board.get("is_full_board_view")))
	assert(game_manager.get_node_or_null("MatchExitLayer/SurrenderButton") != null)
	var result := MatchResult.create(
		MatchResult.EndReason.RESOURCE_VICTORY,
		game_manager.players[0],
		game_manager.players,
		game_manager.turn_number,
		game_manager.victory_resource_score
	)
	game_manager.match_finished.emit(result)
	await process_frame
	assert(shell.current_screen_id == "main_menu")

	await create_timer(0.25).timeout
	shell.queue_free()
	await process_frame
	await process_frame


func _click_control(control: Control) -> void:
	var click_position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = click_position
	motion.global_position = click_position
	control.get_viewport().push_input(motion, true)
	await process_frame

	var press := InputEventMouseButton.new()
	press.position = click_position
	press.global_position = click_position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	control.get_viewport().push_input(press, true)
	await process_frame

	var release := InputEventMouseButton.new()
	release.position = click_position
	release.global_position = click_position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	control.get_viewport().push_input(release, true)
	await process_frame


func _create_player(
	player_id: String,
	display_name: String,
	faction_id: String,
	is_ai: bool
) -> PlayerState:
	var player := PlayerState.new()
	player.setup(player_id, display_name)
	player.set_faction(faction_id, faction_id)
	player.is_ai = is_ai
	return player
