extends SceneTree


func _init() -> void:
	test_attack_override_lifecycle()
	test_precision_shot_definition()
	print("STATUS_ATTACK_OVERRIDE_TESTS_OK")
	quit()


func test_attack_override_lifecycle() -> void:
	var data := CardData.new()
	data.id = "attack_override_test_unit"
	data.display_name = "Attack Override Test Unit"
	data.type = CardData.TYPE_MINION
	data.attack = 2
	data.health = 5

	var state := CardState.new()
	state.set_card_data(data)
	state.owner_id = "player_1"

	var first_bonus := create_attack_status("first_bonus", {EffectData.KEY_ATTACK_BONUS: 3})
	state.add_status(first_bonus)
	assert(state.current_attack == 5)

	var attack_override := create_attack_status(
		"fixed_attack",
		{EffectData.KEY_ATTACK_OVERRIDE: 4}
	)
	state.add_status(attack_override)
	assert(state.current_attack == 4)
	var newer_override := create_attack_status(
		"newer_fixed_attack",
		{EffectData.KEY_ATTACK_OVERRIDE: 6}
	)
	state.add_status(newer_override)
	assert(state.current_attack == 6)
	assert(state.remove_status("newer_fixed_attack"))
	assert(state.current_attack == 4)

	var second_bonus := create_attack_status("second_bonus", {EffectData.KEY_ATTACK_BONUS: 2})
	state.add_status(second_bonus)
	state.set_passive_attack_bonus(1)
	assert(state.current_attack == 4)

	var snapshot := state.create_card_snapshot()
	var restored := CardState.new()
	restored.apply_card_snapshot(snapshot)
	assert(restored.current_attack == 4)
	assert(restored.remove_status("fixed_attack"))
	assert(restored.current_attack == 8)

	assert(state.remove_status("fixed_attack"))
	assert(state.current_attack == 8)


func test_precision_shot_definition() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	var precision_shot := database.get_card("precision_shot")
	assert(precision_shot != null and precision_shot.is_spell())
	assert(precision_shot.effects.size() == 1)

	var effect_data: Dictionary = precision_shot.effects[0]
	assert(EffectData.get_status_id(effect_data) == CardStatus.STATUS_PRECISION_SHOT)
	assert(EffectData.get_status_stack_policy(effect_data) == CardStatus.STACK_POLICY_REPLACE)
	assert(EffectData.get_status_duration_turns(effect_data) == 1)
	assert(EffectData.get_status_duration_scope(effect_data) == CardStatus.DURATION_SCOPE_SOURCE_OWNER)
	assert(EffectData.get_status_expires_on_trigger(effect_data) == EventContext.TRIGGER_AFTER_TURN_END)
	var payload := EffectData.get_status_payload(effect_data)
	assert(int(payload.get(EffectData.KEY_ATTACK_OVERRIDE, -1)) == 4)
	assert(not payload.has(EffectData.KEY_STATUS_TRIGGER_EFFECTS))

	var tyrande := CardState.new()
	tyrande.set_card_data(database.get_card("tyrande"))
	tyrande.owner_id = "player_1"
	var status := CardStatus.from_effect_data(effect_data, tyrande, tyrande)
	tyrande.add_status(status)
	assert(tyrande.current_attack == 4)
	var expired := tyrande.expire_statuses_for_turn_timing(
		EventContext.TRIGGER_AFTER_TURN_END,
		"player_1"
	)
	assert(expired.size() == 1)
	assert(tyrande.current_attack == tyrande.data.attack)


func create_attack_status(status_id: String, payload: Dictionary) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = status_id
	status.display_name = status_id
	status.tags = [CardStatus.TAG_ATTACK_MODIFIER]
	status.payload = payload.duplicate(true)
	return status
