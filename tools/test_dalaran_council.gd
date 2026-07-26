extends SceneTree


func _init() -> void:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))

	var jaina := database.get_card("jaina")
	assert(jaina != null)
	assert(jaina.faction_id == "dalaran_council")
	assert(jaina.is_hero())
	assert(jaina.level == 1 and jaina.count == 1)
	assert(jaina.attack == 1 and jaina.health == 14)
	assert(jaina.has_keyword(CardData.KEYWORD_RANGED))

	var hero_ids: Array[String] = []
	for hero in database.get_faction_heroes("dalaran_council"):
		hero_ids.append(hero.id)
	assert(hero_ids == ["antonidas", "jaina"])

	assert(
		database.get_attached_card_ids("dalaran_council", "jaina")
		== ["cone_of_cold", "summon_giant_water_elemental"]
	)
	var jaina_pool := database.build_weighted_pool_for_selection("dalaran_council", "jaina")
	assert(pool_contains_card(jaina_pool, "jaina"))
	assert(not pool_contains_card(jaina_pool, "antonidas"))
	assert(not pool_contains_card(jaina_pool, "summon_water_elemental"))
	assert(pool_card_count(jaina_pool, "cone_of_cold") == 3)
	assert(pool_card_count(jaina_pool, "summon_giant_water_elemental") == 2)
	var antonidas_pool := database.build_weighted_pool_for_selection("dalaran_council", "antonidas")
	assert(not pool_contains_card(antonidas_pool, "cone_of_cold"))
	assert(not pool_contains_card(antonidas_pool, "summon_giant_water_elemental"))

	var cone_of_cold := database.get_card("cone_of_cold")
	assert(cone_of_cold != null and cone_of_cold.is_spell())
	assert(cone_of_cold.level == 1 and cone_of_cold.count == 3)
	assert(cone_of_cold.target_rule == SpellTargetResolver.TARGET_RULE_DIRECTION_RAY)
	assert(str(cone_of_cold.selection.get("kind", "")) == SelectionRequest.KIND_DIRECTION_RAY)
	assert(str(cone_of_cold.selection.get("hit_target_rule", "")) == SpellTargetResolver.TARGET_RULE_ENEMY_MINIONS)
	assert(cone_of_cold.effects.size() == 2)
	assert(str(cone_of_cold.effects[0].get("status_id", "")) == CardStatus.STATUS_FREEZE)
	assert(str(cone_of_cold.effects[1].get("id", "")) == "damage")
	assert(int(cone_of_cold.effects[1].get("amount", 0)) == 2)

	var giant_water_spell := database.get_card("summon_giant_water_elemental")
	assert(giant_water_spell != null and giant_water_spell.is_spell())
	assert(giant_water_spell.level == 2 and giant_water_spell.count == 2)
	assert(giant_water_spell.owner_hero_card_id == "jaina")
	assert(giant_water_spell.effects.size() == 1)
	assert(str(giant_water_spell.effects[0].get("id", "")) == EffectData.EFFECT_ADD_CARD_TO_HAND)
	assert(str(giant_water_spell.effects[0].get("card_id", "")) == "giant_water_elemental")

	var giant_water_elemental := database.get_card("giant_water_elemental")
	assert(giant_water_elemental != null and giant_water_elemental.is_minion())
	assert(giant_water_elemental.count == 0 and giant_water_elemental.level == 2)
	assert(giant_water_elemental.attack == 8 and giant_water_elemental.health == 8)
	assert(giant_water_elemental.reborn_health_values == [4])
	test_reborn_queue_model(giant_water_elemental)

	for upgrade_id in [
		"basic_spell_power",
		"intermediate_spell_power",
		"ultimate_spell_power"
	]:
		var upgrade := database.get_card(upgrade_id)
		assert(upgrade != null and upgrade.is_upgrade())
		assert(pool_contains_card(jaina_pool, upgrade_id))
		assert(not upgrade.effects.is_empty())
		var target_ids: Array = upgrade.effects[0].get(EffectData.KEY_CARD_IDS, [])
		assert(target_ids.has("jaina"))

	print("DALARAN_COUNCIL_TESTS_OK")
	quit()


func test_reborn_queue_model(giant_water_elemental: CardData) -> void:
	var state := CardState.new()
	state.set_card_data(giant_water_elemental)
	state.owner_id = "player_1"
	state.is_face_up = true
	assert(state.reborn_health_values == [4])
	assert(state.origin.get("reborn_health_values", []) == [4])
	assert(state.consume_next_reborn_health_value() == 4)
	state.damage_taken = state.max_health
	state.revive_from_reborn(4)
	assert(state.current_health == 4)
	assert(state.max_health == 8)
	assert(not state.has_reborn())

	var multi_reborn_data := CardData.new()
	multi_reborn_data.id = "multi_reborn_test"
	multi_reborn_data.display_name = "Multi Reborn Test"
	multi_reborn_data.type = CardData.TYPE_MINION
	multi_reborn_data.attack = 2
	multi_reborn_data.health = 10
	multi_reborn_data.reborn_health_values = [0, 4, 2]
	var multi_state := CardState.new()
	multi_state.set_card_data(multi_reborn_data)
	assert(multi_state.reborn_health_values == [0, 4, 2])
	assert(multi_state.consume_next_reborn_health_value() == 0)
	multi_state.revive_from_reborn(0)
	assert(multi_state.current_health == 10)
	assert(multi_state.reborn_health_values == [4, 2])
	assert(multi_state.consume_next_reborn_health_value() == 4)
	multi_state.revive_from_reborn(4)
	assert(multi_state.current_health == 4)
	assert(multi_state.reborn_health_values == [2])

	var legacy_data := CardData.new()
	legacy_data.id = "legacy_reborn_test"
	legacy_data.display_name = "Legacy Reborn Test"
	legacy_data.type = CardData.TYPE_MINION
	legacy_data.attack = 1
	legacy_data.health = 6
	legacy_data.keywords = ["reborn_3"]
	var legacy_state := CardState.new()
	legacy_state.set_card_data(legacy_data)
	assert(legacy_state.reborn_health_values == [3])


func pool_contains_card(pool: Array[CardData], card_id: String) -> bool:
	for card_data in pool:
		if card_data != null and card_data.id == card_id:
			return true
	return false


func pool_card_count(pool: Array[CardData], card_id: String) -> int:
	var count := 0
	for card_data in pool:
		if card_data != null and card_data.id == card_id:
			count += 1
	return count
