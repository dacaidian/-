extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_database := CardDatabase.new()
	if not card_database.load_from_json("res://data/cards.json"):
		return _fail("Could not load card data")

	for raw_card_data in card_database.cards_by_id.values():
		var card_data := raw_card_data as CardData
		if card_data == null:
			continue
		if card_data.is_minion() and card_data.unit_traits.is_empty():
			return _fail("Minion has no unit traits: %s" % card_data.id)
		if not card_data.is_minion() and not card_data.unit_traits.is_empty():
			return _fail("Non-minion has unit traits: %s" % card_data.id)

	if not _expect_traits(card_database, "uther", ["humanoid", "human"]):
		return
	if not _expect_traits(card_database, "tyrande", ["humanoid", "elf"], ["human"]):
		return
	if not _expect_traits(card_database, "sentinel_ballista", ["mechanical"], ["humanoid"]):
		return
	if not _expect_traits(
		card_database,
		"hippogryph_rider",
		["humanoid", "elf", "beast", "avian"]
	):
		return
	if not _expect_traits(card_database, "arcane_golem", ["construct", "mechanical"]):
		return
	if not _expect_traits(card_database, "water_elemental", ["elemental"]):
		return
	if not _expect_traits(card_database, "poison_scorpion", ["beast", "insect", "gu"]):
		return
	if not _expect_traits(card_database, "tianhu", ["yaoguai", "fox", "beast"]):
		return
	if not _expect_traits(
		card_database,
		"sun_wukong",
		["humanoid", "beastfolk", "yaoguai", "monkey"]
	):
		return
	if not _expect_traits(card_database, "infernal", ["demon", "construct", "elemental"]):
		return
	if not _expect_traits(card_database, "kaneki_ken", ["humanoid", "ghoul"]):
		return
	if not _expect_traits(
		card_database,
		"kaneki_dragon_form",
		["ghoul", "aberration"],
		["humanoid"]
	):
		return
	if not _expect_traits(
		card_database,
		"venom",
		["humanoid", "alien", "symbiote"],
		["human"]
	):
		return
	if not _expect_traits(
		card_database,
		"knull_liberated",
		["humanoid", "alien", "cosmic"],
		["symbiote"]
	):
		return
	if not _expect_traits(
		card_database,
		"symbiote_shield_agent",
		["humanoid", "human"],
		["symbiote"]
	):
		return
	if not _expect_traits(
		card_database,
		"xenophage",
		["alien", "beast", "aberration"],
		["symbiote"]
	):
		return

	print("UNIT_TRAITS_TESTS_OK")
	quit()


func _expect_traits(
	card_database: CardDatabase,
	card_id: String,
	required_traits: Array[String],
	excluded_traits: Array[String] = []
) -> bool:
	var card_data := card_database.get_card(card_id)
	if card_data == null:
		return _fail("Missing classification example: %s" % card_id)
	for unit_trait in required_traits:
		if not card_data.has_unit_trait(unit_trait):
			return _fail("%s is missing unit trait '%s'" % [card_id, unit_trait])
	for unit_trait in excluded_traits:
		if card_data.has_unit_trait(unit_trait):
			return _fail("%s unexpectedly has unit trait '%s'" % [card_id, unit_trait])
	return true


func _fail(message: String) -> bool:
	push_error("UNIT_TRAITS_TEST_FAILED: %s" % message)
	quit(1)
	return false
