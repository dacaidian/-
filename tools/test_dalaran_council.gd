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

	assert(database.get_attached_card_ids("dalaran_council", "jaina").is_empty())
	var jaina_pool := database.build_weighted_pool_for_selection("dalaran_council", "jaina")
	assert(pool_contains_card(jaina_pool, "jaina"))
	assert(not pool_contains_card(jaina_pool, "antonidas"))
	assert(not pool_contains_card(jaina_pool, "summon_water_elemental"))

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


func pool_contains_card(pool: Array[CardData], card_id: String) -> bool:
	for card_data in pool:
		if card_data != null and card_data.id == card_id:
			return true
	return false
