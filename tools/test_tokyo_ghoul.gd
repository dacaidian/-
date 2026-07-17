extends SceneTree

const TurnEventLedgerScript := preload("res://scripts/game/turn_event_ledger.gd")
const RcConcentrationResolverScript := preload("res://scripts/game/rc_concentration_resolver.gd")
const KagunePowerResolverScript := preload("res://scripts/game/kagune_power_resolver.gd")
const TransformUnitEffectScript := preload("res://scripts/effects/transform_unit_effect.gd")
const DeathResolverScript := preload("res://scripts/game/death_resolver.gd")
const HandPlayResolverScript := preload("res://scripts/game/hand_play_resolver.gd")


func _init() -> void:
	test_rc_transitions()
	test_turn_event_ledger()
	test_card_definitions()
	test_status_numeric_modifiers()
	test_base_armor()
	test_kagune_payloads()
	test_cover_transforms()
	test_sss_ghoul_definitions()
	test_once_per_lifetime_action_resource()
	test_friendly_faction_target_filter()
	test_bikaku_volley_hero_gate()
	test_saint_sword_splash_crosses_board_layers()
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

	var bikaku_volley := database.get_card("bikaku_volley")
	assert(bikaku_volley != null)
	assert(bikaku_volley.level == 1 and bikaku_volley.count == 3)
	assert(bikaku_volley.owner_hero_card_id == "kaneki_ken")
	assert(bikaku_volley.effects.size() == 2)
	assert(EffectData.get_id(bikaku_volley.effects[0]) == EffectData.EFFECT_APPLY_STATUS)
	assert(EffectData.get_status_stack_policy(bikaku_volley.effects[0]) == CardStatus.STACK_POLICY_STACK)
	assert(
		int(EffectData.get_status_payload(bikaku_volley.effects[0]).get(EffectData.KEY_ATTACK_BONUS, 0))
		== 1
	)
	assert(EffectData.get_id(bikaku_volley.effects[1]) == EffectData.EFFECT_APPLY_KAGUNE_POWER)
	assert(EffectData.get_status_stack_policy(bikaku_volley.effects[1]) == CardStatus.STACK_POLICY_REPLACE)
	assert(EffectData.get_keywords(bikaku_volley.effects[1]) == [CardData.KEYWORD_KAGUNE_BIKAKU])

	var centipede_spell := database.get_card("centipede_form")
	assert(centipede_spell != null)
	assert(centipede_spell.level == 2 and centipede_spell.count == 1)
	assert(centipede_spell.owner_hero_card_id == "kaneki_ken")

	var centipede_form := database.get_card("kaneki_centipede_form")
	assert(centipede_form != null and centipede_form.is_hero())
	assert(centipede_form.attack == 3 and centipede_form.health == 6)
	assert(centipede_form.attack_speed == 2 and centipede_form.movement == 3)
	assert(centipede_form.has_keyword(CardData.KEYWORD_MOBILE_ASSAULT))

	var dragon_spell := database.get_card("dragon_form")
	assert(dragon_spell != null)
	assert(dragon_spell.level == 2 and dragon_spell.count == 1)
	assert(dragon_spell.owner_hero_card_id == "kaneki_ken")

	var dragon_form := database.get_card("kaneki_dragon_form")
	assert(dragon_form != null and dragon_form.is_hero())
	assert(dragon_form.attack == 5 and dragon_form.health == 8)
	assert(dragon_form.has_keyword(CardData.KEYWORD_GIANT))

	var saint_sword_spell := database.get_card("saint_sword_form")
	assert(saint_sword_spell != null)
	assert(saint_sword_spell.level == 3 and saint_sword_spell.count == 1)
	assert(saint_sword_spell.owner_hero_card_id == "kaneki_ken")

	var saint_sword_form := database.get_card("kaneki_saint_sword_form")
	assert(saint_sword_form != null and saint_sword_form.is_hero())
	assert(saint_sword_form.attack == 8 and saint_sword_form.health == 8)
	assert(saint_sword_form.has_keyword(CardData.KEYWORD_RANGED))
	assert(saint_sword_form.get_splash_damage() == 4)


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


func test_cover_transforms() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	var kaneki := database.get_card("kaneki_ken")
	var centipede := database.get_card("kaneki_centipede_form")
	var dragon := database.get_card("kaneki_dragon_form")
	var saint_sword := database.get_card("kaneki_saint_sword_form")
	assert(kaneki != null and centipede != null and dragon != null and saint_sword != null)

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

	effect_data[EffectData.KEY_STATUS_NAME] = "龙形态"
	transform_effect.apply_transform(state, dragon, effect_data)
	assert(state.card_id == "kaneki_dragon_form")
	assert(state.is_hero() and state.has_keyword(CardData.KEYWORD_GIANT))
	assert(not state.represents_card_id("kaneki_ken"))
	assert(not transform_effect.can_transform_target(state))

	state.damage_taken = state.max_health
	assert(death_resolver.try_restore_cover_transform_death(null, state))
	assert(state.card_id == "kaneki_ken")
	assert(state.represents_card_id("kaneki_ken"))
	assert(state.get_status("transform_snapshot_test") != null)
	assert(state.get_transform_status() == null)

	effect_data[EffectData.KEY_STATUS_NAME] = "圣剑形态"
	transform_effect.apply_transform(state, saint_sword, effect_data)
	assert(state.card_id == "kaneki_saint_sword_form")
	assert(state.is_hero() and state.has_keyword(CardData.KEYWORD_RANGED))
	assert(state.get_splash_damage() == 4)
	assert(not state.represents_card_id("kaneki_ken"))
	assert(not transform_effect.can_transform_target(state))

	state.damage_taken = state.max_health
	assert(death_resolver.try_restore_cover_transform_death(null, state))
	assert(state.card_id == "kaneki_ken")
	assert(state.represents_card_id("kaneki_ken"))
	assert(state.get_status("transform_snapshot_test") != null)
	assert(state.get_transform_status() == null)


func test_saint_sword_splash_crosses_board_layers() -> void:
	var game_manager := GameManager.new()
	game_manager.board_columns = 7
	game_manager.board_rows = 7
	game_manager.board_states.resize(49)
	game_manager.aerial_board_states.resize(49)

	var attacker := create_test_board_unit("attacker", "player_1", 23, 10, 0, ["splash_4"])
	var main_target := create_test_board_unit("main_target", "player_2", 24)
	var friendly_ground := create_test_board_unit("friendly_ground", "player_1", 16)
	var enemy_ground := create_test_board_unit("enemy_ground", "player_2", 17)
	var enemy_aerial := create_test_board_unit("enemy_aerial", "player_2", 17, 10, 1)
	var neutral_ground := create_test_board_unit("neutral_ground", "", 18)
	var neutral_aerial := create_test_board_unit("neutral_aerial", "", 25)
	var same_slot_aerial := create_test_board_unit("same_slot_aerial", "player_2", 24)
	var distant_enemy := create_test_board_unit("distant_enemy", "player_2", 0)

	game_manager.board_states[23] = attacker
	game_manager.board_states[24] = main_target
	game_manager.board_states[16] = friendly_ground
	game_manager.board_states[17] = enemy_ground
	game_manager.aerial_board_states[17] = enemy_aerial
	game_manager.board_states[18] = neutral_ground
	game_manager.aerial_board_states[25] = neutral_aerial
	game_manager.aerial_board_states[24] = same_slot_aerial
	game_manager.board_states[0] = distant_enemy

	var damaged_targets := AttackAction.new().apply_fixed_splash_damage(attacker, main_target, game_manager)
	assert(damaged_targets.size() == 4)
	assert(enemy_ground.current_health == 6)
	assert(enemy_aerial.current_health == 7)
	assert(neutral_ground.current_health == 6)
	assert(neutral_aerial.current_health == 6)
	assert(friendly_ground.current_health == 10)
	assert(main_target.current_health == 10)
	assert(same_slot_aerial.current_health == 10)
	assert(distant_enemy.current_health == 10)


func test_sss_ghoul_definitions() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))

	var kuzen := database.get_card("kuzen_yoshimura")
	assert(kuzen != null and kuzen.attack == 4 and kuzen.health == 12)
	assert(kuzen.actions.size() == 2)
	var free_meal: Dictionary = kuzen.actions[0]
	assert(EffectData.get_action_id(free_meal) == "free_meal")
	assert(int(free_meal.get("main_action_cost", 0)) == 1)
	var free_meal_effects: Array = free_meal.get("effects", [])
	assert(free_meal_effects.size() == 2)
	assert(str(free_meal_effects[0].get(EffectData.KEY_TARGET, "")) == EffectData.TARGET_FRIENDLY_MINIONS_BY_FACTION)
	assert(str(free_meal_effects[0].get(EffectData.KEY_TARGET_FACTION_ID, "")) == "tokyo_ghoul")
	assert(EffectData.get_id(free_meal_effects[1]) == EffectData.EFFECT_SET_FACTION_RUNTIME_STATE)
	assert(str(free_meal_effects[1].get(EffectData.KEY_RUNTIME_STATE_ID, "")) == "rc_high")
	var kuzen_transform: Dictionary = kuzen.actions[1]
	assert(bool(kuzen_transform.get(EffectData.KEY_ONCE_PER_LIFETIME, false)))
	assert(str((kuzen_transform.get("effects", []) as Array)[0].get(EffectData.KEY_CARD_ID, "")) == "non_killing_owl")

	var non_killing_owl := database.get_card("non_killing_owl")
	assert(non_killing_owl != null and non_killing_owl.attack == 4 and non_killing_owl.health == 10)
	assert(non_killing_owl.has_keyword(CardData.KEYWORD_GIANT))
	assert(non_killing_owl.get_siege_bonus() == 4)

	var eto := database.get_card("eto_yoshimura")
	assert(eto != null and eto.attack == 5 and eto.health == 10)
	assert(eto.has_keyword(CardData.KEYWORD_TELEPORT))
	assert(eto.has_keyword(CardData.KEYWORD_MOBILE_ASSAULT))
	assert(eto.actions.size() == 1)
	var eto_transform: Dictionary = eto.actions[0]
	assert(bool(eto_transform.get(EffectData.KEY_ONCE_PER_LIFETIME, false)))
	assert(str((eto_transform.get("effects", []) as Array)[0].get(EffectData.KEY_CARD_ID, "")) == "one_eyed_owl")

	var one_eyed_owl := database.get_card("one_eyed_owl")
	assert(one_eyed_owl != null and one_eyed_owl.attack == 8 and one_eyed_owl.health == 8)
	assert(one_eyed_owl.has_keyword(CardData.KEYWORD_GIANT))


func test_once_per_lifetime_action_resource() -> void:
	var state := create_minion("once_per_lifetime_user", "player_1")
	var action := EffectAction.new().setup({
		EffectData.KEY_ACTION_ID: "test_once_per_lifetime",
		"main_action_cost": 0,
		EffectData.KEY_ONCE_PER_LIFETIME: true,
		"effects": [{EffectData.KEY_ID: "heal", EffectData.KEY_TARGET: EffectData.TARGET_SELF, EffectData.KEY_AMOUNT: 1}]
	})
	assert(action.can_pay_action_cost(state))
	assert(action.pay_action_cost(state))
	assert(state.has_consumed_action_id(action.id))
	state.restore_main_actions()
	assert(not action.can_pay_action_cost(state))

	var action_snapshot := state.create_action_economy_snapshot()
	var transformed_data := CardData.new()
	transformed_data.id = "temporary_form"
	transformed_data.type = CardData.TYPE_MINION
	transformed_data.attack = 2
	transformed_data.health = 2
	state.set_card_data(transformed_data)
	state.apply_action_economy_after_form_change(action_snapshot)
	assert(state.has_consumed_action_id(action.id))
	assert(not action.can_pay_action_cost(state))


func test_friendly_faction_target_filter() -> void:
	var game_manager := GameManager.new()
	game_manager.board_states.resize(49)
	game_manager.aerial_board_states.resize(49)

	var kuzen := create_test_faction_unit("kuzen_yoshimura", "player_1", "tokyo_ghoul", 0)
	var ghoul_ally := create_test_faction_unit("ghoul_ally", "player_1", "tokyo_ghoul", 1)
	var other_ally := create_test_faction_unit("other_ally", "player_1", "neutral", 2)
	var enemy_ghoul := create_test_faction_unit("enemy_ghoul", "player_2", "tokyo_ghoul", 3)
	game_manager.board_states[0] = kuzen
	game_manager.board_states[1] = ghoul_ally
	game_manager.board_states[2] = other_ally
	game_manager.board_states[3] = enemy_ghoul

	var effect_data := {
		EffectData.KEY_TARGET: EffectData.TARGET_FRIENDLY_MINIONS_BY_FACTION,
		EffectData.KEY_TARGET_FACTION_ID: "tokyo_ghoul"
	}
	var targets := HealEffect.new().get_target_states(kuzen, effect_data, game_manager)
	assert(targets.size() == 2)
	assert(targets.has(kuzen))
	assert(targets.has(ghoul_ally))
	assert(not targets.has(other_ally))
	assert(not targets.has(enemy_ghoul))

	if game_manager.audio_manager != null:
		game_manager.audio_manager.free()
	game_manager.free()


func create_test_faction_unit(
	card_id: String,
	owner_id: String,
	faction_id: String,
	slot_index: int
) -> CardState:
	var data := CardData.new()
	data.id = card_id
	data.type = CardData.TYPE_MINION
	data.attack = 1
	data.health = 5
	data.faction_id = faction_id
	return create_test_board_unit_from_data(data, owner_id, slot_index)


func test_bikaku_volley_hero_gate() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	var game_manager := GameManager.new()
	game_manager.card_database = database
	game_manager.board_states.resize(49)
	game_manager.aerial_board_states.resize(49)
	var player := PlayerState.new()
	player.setup("player_1", "测试玩家")
	player.set_faction("tokyo_ghoul", "东京喰种")
	game_manager.players = [player]
	var spell := database.get_card("bikaku_volley")
	player.add_to_hand(spell)
	var resolver := HandPlayResolverScript.new()

	var kaneki := create_test_board_unit_from_data(database.get_card("kaneki_ken"), player.id, 24)
	game_manager.board_states[24] = kaneki
	assert(resolver.can_play_hand_card(player, spell, game_manager))

	for form_id in ["kaneki_centipede_form", "kaneki_dragon_form", "kaneki_saint_sword_form"]:
		game_manager.board_states[24] = create_test_board_unit_from_data(database.get_card(form_id), player.id, 24)
		assert(not resolver.can_play_hand_card(player, spell, game_manager))

	if game_manager.audio_manager != null:
		game_manager.audio_manager.free()
	game_manager.free()


func create_test_board_unit_from_data(data: CardData, owner_id: String, slot_index: int) -> CardState:
	var state := CardState.new()
	state.slot_index = slot_index
	state.set_card_data(data)
	state.set_owner(owner_id)
	state.is_face_up = true
	return state


func create_test_board_unit(
	card_id: String,
	owner_id: String,
	slot_index: int,
	health := 10,
	armor := 0,
	keywords: Array[String] = []
) -> CardState:
	var data := CardData.new()
	data.id = card_id
	data.type = CardData.TYPE_MINION
	data.attack = 8
	data.health = health
	data.armor = armor
	data.keywords = keywords.duplicate()
	var state := CardState.new()
	state.slot_index = slot_index
	state.set_card_data(data)
	state.set_owner(owner_id)
	state.is_face_up = true
	return state
