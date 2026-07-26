extends SceneTree


func _init() -> void:
	var game_manager := GameManager.new()
	game_manager.board_columns = 7
	game_manager.board_rows = 7
	create_state_fixture(game_manager)

	var jaina_state := game_manager.board_states[24]
	var jaina_data := CardData.new()
	jaina_data.id = "jaina"
	jaina_data.display_name = "Jaina"
	jaina_data.type = CardData.TYPE_MINION
	jaina_data.attack = 1
	jaina_data.health = 14
	jaina_state.set_card_data(jaina_data)
	jaina_state.set_owner("player_1")
	jaina_state.set_face_up(true)

	var storm_status := CardStatus.new()
	storm_status.status_id = CardStatus.STATUS_EXTREME_COLD_STORM
	storm_status.payload = {
		EffectData.KEY_PERSISTENT_VISUALS: [
			{
				EffectData.KEY_VISUAL_KEY: ExtremeColdStormAreaVisual.VISUAL_KEY,
				EffectData.KEY_AREA_ROWS: 3,
				EffectData.KEY_AREA_COLS: 3
			}
		]
	}
	jaina_state.add_status(storm_status)

	var controller := BoardPersistentVisualController.new()
	game_manager.board_persistent_visual_controller = controller
	controller.game_manager = game_manager
	assert(
		controller.has_registered_visual(
			ExtremeColdStormAreaVisual.VISUAL_KEY
		)
	)
	controller.refresh_sources()
	assert(controller.get_active_visual_count() == 1)

	var visual := controller.active_visuals.values()[0] as PersistentBoardAreaVisual
	assert(visual != null)
	assert(visual.source_state == jaina_state)
	assert(visual.source_status == storm_status)
	assert(visual.area_rows == 3 and visual.area_cols == 3)

	jaina_state.remove_status(CardStatus.STATUS_EXTREME_COLD_STORM)
	controller.refresh_sources()
	assert(controller.get_active_visual_count() == 0)

	if game_manager.audio_manager != null and is_instance_valid(game_manager.audio_manager):
		game_manager.audio_manager.free()
	controller.free()
	game_manager.free()
	print("BOARD_PERSISTENT_VISUAL_TESTS_OK")
	quit()


func create_state_fixture(game_manager: GameManager) -> void:
	for slot_index in range(49):
		var state := CardState.new()
		state.slot_index = slot_index
		state.is_interactable = true
		game_manager.board_states.append(state)
