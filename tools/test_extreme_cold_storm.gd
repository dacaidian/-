extends SceneTree


func _init() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var game_manager := create_game_manager()
	test_cross_layer_area_targets(game_manager)
	await test_death_slot_replacement_fallback(game_manager)
	await test_damage_replacement_beats_refill(game_manager)
	test_ground_only_death_claim(game_manager)
	print("EXTREME_COLD_STORM_TESTS_OK")
	clear_board(game_manager)
	game_manager.board_states.clear()
	game_manager.aerial_board_states.clear()
	game_manager.board_cells.clear()
	game_manager.players.clear()
	if game_manager.audio_manager != null and is_instance_valid(game_manager.audio_manager):
		game_manager.audio_manager.free()
	game_manager.free()
	quit()


func create_game_manager() -> GameManager:
	var game_manager := GameManager.new()
	game_manager.board_columns = 7
	game_manager.board_rows = 7
	assert(game_manager.card_database.load_from_json("res://data/cards.json"))

	var player := PlayerState.new()
	player.id = "player_1"
	player.faction_id = "dalaran_council"
	game_manager.players.append(player)
	var opponent := PlayerState.new()
	opponent.id = "player_2"
	opponent.faction_id = "silver_hand"
	game_manager.players.append(opponent)

	for slot_index in range(49):
		var ground_state := CardState.new()
		ground_state.slot_index = slot_index
		game_manager.board_states.append(ground_state)

		var aerial_state := CardState.new()
		aerial_state.slot_index = slot_index
		game_manager.aerial_board_states.append(aerial_state)

		var cell := BoardCell.new()
		cell.setup(slot_index, 7, true)
		cell.ground_state = ground_state
		cell.aerial_states.append(aerial_state)
		game_manager.board_cells.append(cell)

	return game_manager


func test_cross_layer_area_targets(game_manager: GameManager) -> void:
	clear_board(game_manager)
	var jaina := place_minion(game_manager.board_states[24], "jaina", "player_1")
	var ground_enemy := place_test_minion(game_manager.board_states[17], "ground_enemy", "player_2")
	var aerial_enemy := place_test_minion(game_manager.aerial_board_states[24], "aerial_enemy", "player_2")
	var neutral := place_test_minion(game_manager.board_states[25], "neutral", "")
	var friendly := place_test_minion(game_manager.aerial_board_states[31], "friendly", "player_1")

	var damage_effect := DamageEffect.new()
	var targets := damage_effect.get_target_states(
		jaina,
		{
			EffectData.KEY_TARGET: EffectData.TARGET_SOURCE_AREA_ENEMY_MINIONS,
			EffectData.KEY_AREA_ROWS: 3,
			EffectData.KEY_AREA_COLS: 3,
			EffectData.KEY_DEATH_REASON: EffectData.DEATH_REASON_SPELL
		},
		game_manager
	)
	assert(targets.has(ground_enemy))
	assert(targets.has(aerial_enemy))
	assert(not targets.has(neutral))
	assert(not targets.has(friendly))


func test_death_slot_replacement_fallback(game_manager: GameManager) -> void:
	clear_board(game_manager)
	var slot_index := 24
	var ground_state := game_manager.board_states[slot_index]
	var death_event := {
		"state": ground_state,
		"slot_index": slot_index,
		"owner_id": "player_2",
		"slot_claims": [
			{
				EffectData.KEY_CARD_ID: "giant_water_elemental",
				EffectData.KEY_OWNER_ID: "player_1",
				EffectData.KEY_DESTINATION_LAYER: EffectData.BOARD_LAYER_AERIAL,
				EffectData.KEY_PRIORITY: 200,
				"_claim_order": 0
			},
			{
				EffectData.KEY_CARD_ID: "giant_water_elemental",
				EffectData.KEY_OWNER_ID: "player_1",
				EffectData.KEY_DESTINATION_LAYER: EffectData.BOARD_LAYER_GROUND,
				EffectData.KEY_PRIORITY: 100,
				"_claim_order": 1
			}
		]
	}

	assert(await game_manager.death_resolver.death_slot_claim_resolver.resolve_claims(game_manager, death_event))
	assert(ground_state.card_id == "giant_water_elemental")
	assert(ground_state.owner_id == "player_1")
	assert(ground_state.is_face_up)
	assert(game_manager.aerial_board_states[slot_index].is_empty())


func test_ground_only_death_claim(game_manager: GameManager) -> void:
	clear_board(game_manager)
	var slot_index := 24
	var aerial_state := place_test_minion(
		game_manager.aerial_board_states[slot_index],
		"aerial_victim",
		"player_2"
	)
	var death_event := {
		"state": aerial_state,
		"slot_index": slot_index,
		"owner_id": "player_2",
		"source_owner_id": "player_1",
		"slot_claims": []
	}
	assert(
		not game_manager.death_resolver.death_slot_claim_resolver.append_claim(
			game_manager,
			death_event,
			{
				EffectData.KEY_CARD_ID: "giant_water_elemental",
				EffectData.KEY_OWNER_ID: "player_1",
				EffectData.KEY_VICTIM_LAYER: EffectData.BOARD_LAYER_GROUND
			},
			100
		)
	)


func test_damage_replacement_beats_refill(game_manager: GameManager) -> void:
	clear_board(game_manager)
	var jaina := place_minion(game_manager.board_states[24], "jaina", "player_1")
	var enemy := place_test_minion(game_manager.board_states[17], "storm_victim", "player_2")
	enemy.take_damage(4)
	assert(enemy.current_health == 1)

	game_manager.card_pool = CardPool.new("", game_manager.card_database)
	game_manager.card_pool.add_card(game_manager.card_database.get_card("mage_apprentice"), false)
	var pool_size_before := game_manager.card_pool.get_pool().size()
	await DamageEffect.new().execute(
		jaina,
		{
			EffectData.KEY_AMOUNT: 4,
			EffectData.KEY_TARGET: EffectData.TARGET_SOURCE_AREA_ENEMY_MINIONS,
			EffectData.KEY_AREA_ROWS: 3,
			EffectData.KEY_AREA_COLS: 3,
			EffectData.KEY_DEATH_REASON: EffectData.DEATH_REASON_SPELL,
			EffectData.KEY_DEATH_SLOT_REPLACEMENT: {
				EffectData.KEY_CARD_ID: "giant_water_elemental",
				EffectData.KEY_SLOT_OWNER: EffectData.DEATH_SLOT_OWNER_SOURCE,
				EffectData.KEY_VICTIM_LAYER: EffectData.BOARD_LAYER_GROUND,
				EffectData.KEY_DESTINATION_LAYER: EffectData.BOARD_LAYER_GROUND,
				EffectData.KEY_PRIORITY: 100
			}
		},
		game_manager
	)

	assert(enemy.card_id == "giant_water_elemental")
	assert(enemy.owner_id == "player_1")
	assert(game_manager.card_pool.get_pool().size() == pool_size_before)


func place_minion(state: CardState, card_id: String, owner_id: String) -> CardState:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	var card_data := database.get_card(card_id)
	state.set_card_data(card_data)
	state.set_owner(owner_id)
	state.set_face_up(true)
	return state


func place_test_minion(state: CardState, card_id: String, owner_id: String) -> CardState:
	var card_data := CardData.new()
	card_data.id = card_id
	card_data.display_name = card_id
	card_data.type = CardData.TYPE_MINION
	card_data.attack = 1
	card_data.health = 5
	state.set_card_data(card_data)
	state.set_owner(owner_id)
	state.set_face_up(true)
	return state


func clear_board(game_manager: GameManager) -> void:
	for state in game_manager.get_all_board_states():
		state.clear_card()
