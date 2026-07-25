extends SceneTree

const DirectionRayTargetResolverScript := preload("res://scripts/game/direction_ray_target_resolver.gd")


func _init() -> void:
	test_direction_ray_rules()
	call_deferred("finish_test")


func finish_test() -> void:
	await process_frame
	print("DIRECTION_RAY_SELECTION_TESTS_OK")
	quit()


func test_direction_ray_rules() -> void:
	var game_manager := create_game_manager()
	var jaina := place_unit(game_manager, 24, "jaina", "player_1", true)

	place_unit(game_manager, 17, "friendly_blocker", "player_1")
	var immune_enemy := place_unit(game_manager, 10, "immune_enemy", "player_2")
	immune_enemy.data.keywords.append(CardData.KEYWORD_MAGIC_IMMUNE)
	var expected_enemy := place_unit(game_manager, 3, "expected_enemy", "player_2")
	expected_enemy.data.keywords.append(CardData.KEYWORD_STEALTH)

	var request := SelectionRequest.direction_ray(
		jaina.slot_index,
		"Select direction",
		SelectionRequest.DIRECTIONS_8_WAY,
		-1,
		SpellTargetResolver.TARGET_RULE_ENEMY_MINIONS,
		"player_1",
		jaina,
		SelectionRequest.STOP_FIRST_MATCHING,
		true
	)
	var resolver := DirectionRayTargetResolverScript.new()
	var result := resolver.resolve_direction(game_manager, request, Vector2i(-1, 0))
	assert(result.hit_state == immune_enemy)
	assert(result.hit_slot == 10)
	assert(result.ray_slots == [17, 10, 3])
	assert(not SpellTargetResolver.can_spell_affect(immune_enemy))

	var valid_results := resolver.get_valid_results(game_manager, request)
	assert(valid_results.size() == 1)
	assert(valid_results[0].direction == Vector2i(-1, 0))

	immune_enemy.clear_card()
	assert(not SpellTargetResolver.can_target(
		SpellTargetResolver.TARGET_RULE_ENEMY_MINIONS,
		expected_enemy,
		[],
		jaina,
		"player_1",
		game_manager
	))
	var stealth_result := resolver.resolve_direction(game_manager, request, Vector2i(-1, 0))
	assert(stealth_result.hit_state == expected_enemy)

	request.stop_rule = SelectionRequest.STOP_FIRST_UNIT
	var blocked_result := resolver.resolve_direction(game_manager, request, Vector2i(-1, 0))
	assert(blocked_result.hit_state == null)

	blocked_result = null
	stealth_result = null
	result = null
	valid_results.clear()
	request = null
	resolver = null
	immune_enemy = null
	expected_enemy = null
	jaina = null
	for state in game_manager.get_all_board_states():
		if state != null:
			state.clear_card()
	game_manager.board_states.clear()
	game_manager.aerial_board_states.clear()
	if game_manager.audio_manager != null and is_instance_valid(game_manager.audio_manager):
		game_manager.audio_manager.free()
	game_manager.free()


func create_game_manager() -> GameManager:
	var game_manager := GameManager.new()
	game_manager.board_columns = 7
	game_manager.board_rows = 7
	for slot_index in range(49):
		var ground_state := CardState.new()
		ground_state.slot_index = slot_index
		game_manager.board_states.append(ground_state)

		var aerial_state := CardState.new()
		aerial_state.slot_index = slot_index
		game_manager.aerial_board_states.append(aerial_state)
	return game_manager


func place_unit(
	game_manager: GameManager,
	slot_index: int,
	card_id: String,
	owner_id: String,
	is_hero := false
) -> CardState:
	var card_data := CardData.new()
	card_data.id = card_id
	card_data.display_name = card_id
	card_data.type = CardData.TYPE_MINION
	card_data.role = CardData.ROLE_HERO if is_hero else ""
	card_data.attack = 1
	card_data.health = 5

	var state := game_manager.board_states[slot_index]
	state.set_card_data(card_data)
	state.set_owner(owner_id)
	state.set_face_up(true)
	return state
