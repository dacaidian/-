extends SceneTree

const TurnEventLedgerScript := preload("res://scripts/game/turn_event_ledger.gd")
const RcConcentrationResolverScript := preload("res://scripts/game/rc_concentration_resolver.gd")
const KagunePowerResolverScript := preload("res://scripts/game/kagune_power_resolver.gd")


func _init() -> void:
	test_rc_transitions()
	test_turn_event_ledger()
	test_status_numeric_modifiers()
	test_kagune_payloads()
	print("TOKYO_GHOUL_TESTS_OK")
	quit()


func test_rc_transitions() -> void:
	var resolver := RcConcentrationResolverScript.new()
	assert(resolver.get_next_state_id("rc_low", true, false, false) == "rc_medium")
	assert(resolver.get_next_state_id("rc_low", false, false, false) == "rc_low")
	assert(resolver.get_next_state_id("rc_medium", false, false, false) == "rc_low")
	assert(resolver.get_next_state_id("rc_medium", true, false, false) == "rc_medium")
	assert(resolver.get_next_state_id("rc_medium", true, true, true) == "rc_high")
	assert(resolver.get_next_state_id("rc_high", true, true, true) == "rc_high")
	assert(resolver.get_next_state_id("rc_high", false, false, true) == "rc_medium")


func test_turn_event_ledger() -> void:
	var ledger := TurnEventLedgerScript.new()
	ledger.begin_turn("player_1")
	ledger.record_death(create_minion("enemy", "player_2"), "player_1", "attack")
	assert(ledger.get_qualified_minion_kill_count("player_1") == 1)
	assert(ledger.has_enemy_minion_kill("player_1"))

	ledger.record_death(create_minion("friendly", "player_1"), "player_1", "attack")
	assert(ledger.get_qualified_minion_kill_count("player_1") == 2)

	ledger.record_death(create_minion("neutral", ""), "player_1", "attack")
	ledger.record_death(create_minion("enemy_hero", "player_2", true), "player_1", "attack")
	ledger.record_death(create_minion("wrong_source", "player_2"), "player_2", "attack")
	assert(ledger.get_qualified_minion_kill_count("player_1") == 2)

	ledger.begin_turn("player_2")
	assert(ledger.get_qualified_minion_kill_count("player_1") == 0)


func create_minion(card_id: String, owner_id: String, is_hero := false) -> CardState:
	var data := CardData.new()
	data.id = card_id
	data.type = CardData.TYPE_MINION
	data.role = CardData.ROLE_HERO if is_hero else ""
	data.attack = 1
	data.health = 1
	var state := CardState.new()
	state.set_card_data(data)
	state.set_owner(owner_id)
	return state


func test_status_numeric_modifiers() -> void:
	var data := CardData.new()
	data.id = "modifier_target"
	data.type = CardData.TYPE_MINION
	data.attack = 2
	data.health = 4
	data.movement = 1
	var state := CardState.new()
	state.set_card_data(data)

	var status := CardStatus.new()
	status.status_id = "numeric_modifier_test"
	status.tags = [CardStatus.TAG_ATTACK_MODIFIER]
	status.payload = {
		EffectData.KEY_ATTACK_BONUS: 2,
		EffectData.KEY_ARMOR_BONUS: 2,
		EffectData.KEY_MOVEMENT_BONUS: 2,
		EffectData.KEY_KEYWORDS: [CardData.KEYWORD_REFLECT]
	}
	state.add_status(status)
	assert(state.current_attack == 4)
	assert(state.armor == 2)
	assert(state.max_movement == 3)
	assert(state.has_keyword(CardData.KEYWORD_REFLECT))
	state.remove_status("numeric_modifier_test")
	assert(state.current_attack == 2)
	assert(state.armor == 0)
	assert(state.max_movement == 1)


func test_kagune_payloads() -> void:
	var resolver := KagunePowerResolverScript.new()
	var normal_tail := resolver.create_kagune_payload([CardData.KEYWORD_KAGUNE_BIKAKU], false)
	assert(EffectData.get_keywords(normal_tail).has(CardData.KEYWORD_MOBILE_ASSAULT))
	assert(not normal_tail.has(EffectData.KEY_MOVEMENT_BONUS))
	var high_tail := resolver.create_kagune_payload([CardData.KEYWORD_KAGUNE_BIKAKU], true)
	assert(int(high_tail.get(EffectData.KEY_MOVEMENT_BONUS, 0)) == 2)

	var high_rinkaku := resolver.create_kagune_payload([CardData.KEYWORD_KAGUNE_RINKAKU], true)
	assert(int(high_rinkaku.get(EffectData.KEY_ATTACK_BONUS, 0)) == 2)
	assert(EffectData.get_keywords(high_rinkaku).has(CardData.KEYWORD_LIFESTEAL))

	var high_koukaku := resolver.create_kagune_payload([CardData.KEYWORD_KAGUNE_KOUKAKU], true)
	assert(int(high_koukaku.get(EffectData.KEY_ARMOR_BONUS, 0)) == 2)
	assert(EffectData.get_keywords(high_koukaku).has(CardData.KEYWORD_REFLECT))

	var high_ukaku := resolver.create_kagune_payload([CardData.KEYWORD_KAGUNE_UKAKU], true)
	var actions := EffectData.get_actions(high_ukaku)
	assert(actions.size() == 1)
	assert(int(actions[0]["effects"][0][EffectData.KEY_AMOUNT]) == 3)
