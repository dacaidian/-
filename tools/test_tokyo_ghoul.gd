extends SceneTree

const TurnEventLedgerScript := preload("res://scripts/game/turn_event_ledger.gd")
const RcConcentrationResolverScript := preload("res://scripts/game/rc_concentration_resolver.gd")
const KagunePowerResolverScript := preload("res://scripts/game/kagune_power_resolver.gd")
const TransformUnitEffectScript := preload("res://scripts/effects/transform_unit_effect.gd")
const DeathResolverScript := preload("res://scripts/game/death_resolver.gd")


func _init() -> void:
	test_rc_transitions()
	test_turn_event_ledger()
	test_card_definitions()
	test_status_numeric_modifiers()
	test_base_armor()
	test_kagune_payloads()
	test_centipede_cover_transform()
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


func test_card_definitions() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))

	var black_goat := database.get_card("black_goat_agent")
	assert(black_goat != null)
	assert(black_goat.level == 1 and black_goat.count == 5)
	assert(black_goat.attack == 2 and black_goat.health == 1 and black_goat.armor == 1)
	assert(black_goat.has_keyword(CardData.KEYWORD_KAGUNE_KOUKAKU))

	var wanderer := database.get_card("anteiku_wanderer")
	assert(wanderer != null)
	assert(wanderer.level == 2 and wanderer.count == 4)
	assert(wanderer.attack == 3 and wanderer.health == 5)
	assert(wanderer.has_keyword(CardData.KEYWORD_KAGUNE_RINKAKU))

	var aogiri_member := database.get_card("aogiri_tree_member")
	assert(aogiri_member != null)
	assert(aogiri_member.level == 2 and aogiri_member.count == 4)
	assert(aogiri_member.has_keyword(CardData.KEYWORD_RANGED))
	assert(aogiri_member.has_keyword(CardData.KEYWORD_FLYING))
	assert(aogiri_member.has_keyword(CardData.KEYWORD_KAGUNE_UKAKU))

	var clown_worker := database.get_card("clown_temp_worker")
	assert(clown_worker != null)
	assert(clown_worker.level == 3 and clown_worker.count == 4)
	assert(clown_worker.attack == 5 and clown_worker.health == 12)
	assert(clown_worker.has_keyword(CardData.KEYWORD_KAGUNE_BIKAKU))

	var centipede_spell := database.get_card("centipede_form")
	assert(centipede_spell != null)
	assert(centipede_spell.level == 2 and centipede_spell.count == 1)
	assert(centipede_spell.owner_hero_card_id == "kaneki_ken")

	var centipede_form := database.get_card("kaneki_centipede_form")
	assert(centipede_form != null and centipede_form.is_hero())
	assert(centipede_form.attack == 3 and centipede_form.health == 6)
	assert(centipede_form.attack_speed == 2 and centipede_form.movement == 3)
	assert(centipede_form.has_keyword(CardData.KEYWORD_MOBILE_ASSAULT))


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


func test_base_armor() -> void:
	var data := CardData.new()
	data.id = "black_goat_agent"
	data.type = CardData.TYPE_MINION
	data.attack = 2
	data.health = 1
	data.armor = 1
	var state := CardState.new()
	state.set_card_data(data)
	assert(state.armor == 1)

	var status := CardStatus.new()
	status.status_id = "base_armor_stack_test"
	status.payload = {EffectData.KEY_ARMOR_BONUS: 2}
	state.add_status(status)
	assert(state.armor == 3)
	state.remove_status(status.status_id)
	assert(state.armor == 1)

	state.add_reborn_health_value()
	state.consume_next_reborn_health_value()
	state.revive_from_reborn(0)
	assert(state.armor == 1)


func test_kagune_payloads() -> void:
	var resolver := KagunePowerResolverScript.new()
	assert(resolver.RELEASE_ANIMATION_KEY == "kagune_release")
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


func test_centipede_cover_transform() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	var kaneki := database.get_card("kaneki_ken")
	var centipede := database.get_card("kaneki_centipede_form")
	assert(kaneki != null and centipede != null)

	var state := CardState.new()
	state.set_card_data(kaneki)
	state.set_owner("player_1")
	var original_status := CardStatus.new()
	original_status.status_id = "transform_snapshot_test"
	state.add_status(original_status)

	var effect_data := {
		EffectData.KEY_TRANSFORM_MODE: "cover",
		EffectData.KEY_PRESERVE_ORIGINAL_IDENTITY: false,
		EffectData.KEY_STATUS_NAME: "蜈蚣形态",
		"permanent": true
	}
	var transform_effect := TransformUnitEffectScript.new()
	transform_effect.apply_transform(state, centipede, effect_data)

	assert(state.card_id == "kaneki_centipede_form")
	assert(state.is_hero())
	assert(not state.represents_card_id("kaneki_ken"))
	assert(state.get_effective_hero_card_id() == "kaneki_centipede_form")
	assert(state.is_cover_transformed())
	assert(not transform_effect.can_transform_target(state))
	assert(state.get_status("transform_snapshot_test") == null)

	state.damage_taken = state.max_health
	var death_resolver := DeathResolverScript.new()
	assert(death_resolver.try_restore_cover_transform_death(null, state))
	assert(state.card_id == "kaneki_ken")
	assert(state.represents_card_id("kaneki_ken"))
	assert(state.get_status("transform_snapshot_test") != null)
	assert(state.get_transform_status() == null)
