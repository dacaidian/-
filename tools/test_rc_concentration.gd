extends SceneTree

const TurnEventLedgerScript := preload("res://scripts/game/turn_event_ledger.gd")
const RcConcentrationResolverScript := preload("res://scripts/game/rc_concentration_resolver.gd")


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var keep_alive := Node.new()
	root.add_child(keep_alive)

	var player := PlayerState.new()
	player.setup("player_1", "测试玩家")
	player.set_faction("tokyo_ghoul", "东京喰种")
	player.setup_faction_runtime_state(load_rc_runtime_config())
	assert(player.faction_runtime_state_id == "rc_high")

	var resolver := RcConcentrationResolverScript.new()
	var ledger := TurnEventLedgerScript.new()
	ledger.begin_turn(player.id)
	player.set_faction_runtime_state_by_id("rc_low")
	var first_record := ledger.record_death(create_minion("enemy_1", "player_2"), player.id, "attack")
	assert(resolver.resolve_after_death_event(player, ledger, first_record))
	assert(player.faction_runtime_state_id == "rc_medium")
	var second_record := ledger.record_death(create_minion("enemy_2", "player_2"), player.id, "attack")
	assert(resolver.resolve_after_death_event(player, ledger, second_record))
	assert(player.faction_runtime_state_id == "rc_high")

	var friendly_record := ledger.record_death(create_minion("friendly", player.id), player.id, "attack")
	assert(not ledger.is_enemy_minion_kill(friendly_record, player.id))
	assert(ledger.get_qualified_minion_kill_count(player.id) == 3)
	assert(resolver.get_decreased_state_id("rc_high") == "rc_medium")
	assert(resolver.get_decreased_state_id("rc_medium") == "rc_low")
	assert(resolver.get_decreased_state_id("rc_low") == "rc_low")

	var game_manager := GameManager.new()
	ledger.begin_turn(player.id)
	player.set_faction_runtime_state_by_id("rc_high")
	assert(await resolver.resolve_after_turn_end(game_manager, player, ledger))
	assert(player.faction_runtime_state_id == "rc_medium")
	ledger.begin_turn(player.id)
	assert(await resolver.resolve_after_turn_end(game_manager, player, ledger))
	assert(player.faction_runtime_state_id == "rc_low")

	game_manager.board_states.resize(3)
	game_manager.aerial_board_states.resize(3)
	game_manager.board_states[0] = create_faction_minion("friendly_ghoul", player.id, "tokyo_ghoul", 0)
	game_manager.board_states[1] = create_faction_minion("friendly_other", player.id, "neutral", 1)
	game_manager.board_states[2] = create_faction_minion("enemy_ghoul", "player_2", "tokyo_ghoul", 2)
	var feeding_candidates := resolver.get_feeding_candidates(game_manager, player)
	assert(feeding_candidates.size() == 1)
	assert(feeding_candidates[0].card_id == "friendly_ghoul")
	if game_manager.audio_manager != null:
		game_manager.audio_manager.free()
	game_manager.free()

	print("RC_CONCENTRATION_TEST_OK")
	quit()


func create_minion(card_id: String, owner_id: String) -> CardState:
	var data := CardData.new()
	data.id = card_id
	data.type = CardData.TYPE_MINION
	data.attack = 1
	data.health = 1
	var state := CardState.new()
	state.set_card_data(data)
	state.set_owner(owner_id)
	return state


func create_faction_minion(
	card_id: String,
	owner_id: String,
	faction_id: String,
	slot_index: int
) -> CardState:
	var state := create_minion(card_id, owner_id)
	state.data.faction_id = faction_id
	state.slot_index = slot_index
	state.is_face_up = true
	return state


func load_rc_runtime_config() -> Dictionary:
	var parsed_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	assert(parsed_data is Array)
	for faction_entry in parsed_data:
		if faction_entry is Dictionary and str(faction_entry.get("id", "")) == "tokyo_ghoul":
			return (faction_entry as Dictionary).get("runtime_state", {}).duplicate(true)
	return {}
