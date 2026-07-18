extends SceneTree

const CardReserveResolverScript := preload("res://scripts/game/card_reserve_resolver.gd")

const RESERVE_ID := "s_rank_ghouls"
const POOL_CARD_IDS: Array[String] = [
	"yamori",
	"bin_brothers",
	"touka_kirishima",
	"shu_tsukiyama",
]
const SSS_RESERVE_ID := "sss_rank_ghouls"
const SSS_POOL_CARD_IDS: Array[String] = [
	"kuzen_yoshimura",
	"eto_yoshimura",
	"nimura_furuta",
	"shikorae",
]


func _init() -> void:
	test_card_definitions()
	test_finite_reserve_and_cooldown()
	test_capacity_increase_during_cooldown()
	test_independent_reserve_runtimes()
	print("CARD_RESERVE_TESTS_OK")
	quit()


func test_card_definitions() -> void:
	var database := load_database()
	var library := database.get_card("s_rank_ghoul_intelligence")
	assert(library != null)
	assert(library.is_upgrade())
	assert(library.upgrade_type == CardData.UPGRADE_TYPE_MINION_LIBRARY)
	assert(library.level == 2 and library.count == 1)

	var yamori := database.get_card("yamori")
	assert(yamori.attack == 8 and yamori.health == 8)
	assert(yamori.has_keyword(CardData.KEYWORD_KAGUNE_RINKAKU))

	var bin_brothers := database.get_card("bin_brothers")
	assert(bin_brothers.attack == 3 and bin_brothers.health == 10)
	assert(bin_brothers.attack_speed == 2)
	assert(bin_brothers.has_keyword(CardData.KEYWORD_KAGUNE_BIKAKU))

	var touka := database.get_card("touka_kirishima")
	assert(touka.attack == 6 and touka.health == 6)
	assert(touka.has_keyword(CardData.KEYWORD_KAGUNE_UKAKU))
	assert(touka.has_keyword(CardData.KEYWORD_RANGED))

	var tsukiyama := database.get_card("shu_tsukiyama")
	assert(tsukiyama.attack == 3 and tsukiyama.health == 8 and tsukiyama.armor == 2)
	assert(tsukiyama.has_keyword(CardData.KEYWORD_KAGUNE_KOUKAKU))

	var sss_library := database.get_card("sss_rank_ghoul_intelligence")
	assert(sss_library != null)
	assert(sss_library.is_upgrade())
	assert(sss_library.upgrade_type == CardData.UPGRADE_TYPE_MINION_LIBRARY)
	assert(sss_library.level == 3 and sss_library.count == 1)
	var sss_pool_ids: Array[String] = [
		"kuzen_yoshimura",
		"eto_yoshimura",
		"nimura_furuta",
		"shikorae",
	]
	for card_id in sss_pool_ids:
		var reserve_minion := database.get_card(card_id)
		assert(reserve_minion != null and reserve_minion.is_minion())
		assert(reserve_minion.level == 3 and reserve_minion.count == 0)
	assert(database.get_card("kuzen_yoshimura").attack == 4)
	assert(database.get_card("kuzen_yoshimura").health == 12)
	assert(database.get_card("eto_yoshimura").attack == 5)
	assert(database.get_card("eto_yoshimura").health == 10)
	assert(database.get_card("nimura_furuta").attack == 8)
	assert(database.get_card("nimura_furuta").health == 8)
	assert(database.get_card("shikorae").attack == 6)
	assert(database.get_card("shikorae").health == 14)
	assert(database.get_card("one_eyed_owl").attack == 12)
	assert(database.get_card("one_eyed_owl").health == 12)


func test_finite_reserve_and_cooldown() -> void:
	var context := create_context()
	var game_manager := context.game_manager as GameManager
	var player := context.player as PlayerState
	var resolver := context.resolver as CardReserveResolver
	var library := game_manager.get_card_data_by_id("s_rank_ghoul_intelligence")
	player.add_to_hand(library)

	resolver.refresh_player(player, game_manager)
	assert(count_pool_minions_in_hand(player) == 1)
	var drawn_ids: Array[String] = get_pool_minion_ids_in_hand(player)
	assert(get_runtime(player, resolver).get("remaining_pool", []).size() == 3)

	var first_minion := get_first_pool_minion_in_hand(player)
	assert(first_minion != null)
	player.remove_from_hand(first_minion)
	var board_state := CardState.new()
	board_state.set_card_data(first_minion)
	board_state.set_owner(player.id)
	board_state.set_face_up(true)
	game_manager.board_states = [board_state]
	resolver.refresh_player(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == -1)

	game_manager.board_states.clear()
	resolver.refresh_player(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 2)
	resolver.refresh_player(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 2)

	resolver.advance_owner_turn(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 1)
	assert(count_pool_minions_in_hand(player) == 0)

	player.remove_from_hand(library)
	resolver.advance_owner_turn(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 1)
	player.add_to_hand(library)
	resolver.refresh_player(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 1)

	resolver.advance_owner_turn(player, game_manager)
	assert(count_pool_minions_in_hand(player) == 1)
	drawn_ids.append_array(get_pool_minion_ids_in_hand(player))
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == -1)

	while get_runtime(player, resolver).get("remaining_pool", []).size() > 0:
		remove_pool_minions_from_hand(player)
		resolver.refresh_player(player, game_manager)
		resolver.advance_owner_turn(player, game_manager)
		resolver.advance_owner_turn(player, game_manager)
		assert(count_pool_minions_in_hand(player) == 1)
		drawn_ids.append_array(get_pool_minion_ids_in_hand(player))

	assert(drawn_ids.size() == 4)
	var unique_ids: Array[String] = []
	for card_id in drawn_ids:
		if not unique_ids.has(card_id):
			unique_ids.append(card_id)
	assert(unique_ids.size() == 4)

	remove_pool_minions_from_hand(player)
	resolver.refresh_player(player, game_manager)
	var runtime := get_runtime(player, resolver)
	assert(runtime.get("remaining_pool", []).is_empty())
	assert(int(runtime.get("cooldown_remaining", -1)) == -1)
	var views := resolver.get_hand_view_data(player, game_manager)
	var library_index := player.find_hand_card_index(library)
	assert(bool(views.get(library_index, {}).get("is_exhausted", false)))
	free_game_manager(game_manager)


func test_capacity_increase_during_cooldown() -> void:
	var context := create_context()
	var game_manager := context.game_manager as GameManager
	var player := context.player as PlayerState
	var resolver := context.resolver as CardReserveResolver
	var library := game_manager.get_card_data_by_id("s_rank_ghoul_intelligence")
	player.add_to_hand(library)
	resolver.refresh_player(player, game_manager)

	remove_pool_minions_from_hand(player)
	resolver.refresh_player(player, game_manager)
	resolver.advance_owner_turn(player, game_manager)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 1)

	var capacity_upgrade := CardData.new()
	capacity_upgrade.id = "reserve_capacity_test"
	capacity_upgrade.type = CardData.TYPE_UPGRADE
	capacity_upgrade.effects = [{
		EffectData.KEY_ID: EffectData.EFFECT_MODIFY_CARD_RESERVE_CAPACITY,
		EffectData.KEY_TRIGGER: EffectData.TRIGGER_WHILE_IN_HAND,
		EffectData.KEY_ACTIVE_ZONE: EffectData.ACTIVE_ZONE_HAND,
		EffectData.KEY_RESERVE_ID: RESERVE_ID,
		EffectData.KEY_AMOUNT: 1,
	}]
	player.add_to_hand(capacity_upgrade)
	resolver.refresh_player(player, game_manager)
	assert(count_pool_minions_in_hand(player) == 1)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == 1)

	resolver.advance_owner_turn(player, game_manager)
	assert(count_pool_minions_in_hand(player) == 2)
	assert(int(get_runtime(player, resolver).get("cooldown_remaining", -1)) == -1)
	free_game_manager(game_manager)


func test_independent_reserve_runtimes() -> void:
	var context := create_context()
	var game_manager := context.game_manager as GameManager
	var player := context.player as PlayerState
	var resolver := context.resolver as CardReserveResolver
	player.add_to_hand(game_manager.get_card_data_by_id("s_rank_ghoul_intelligence"))
	player.add_to_hand(game_manager.get_card_data_by_id("sss_rank_ghoul_intelligence"))

	resolver.refresh_player(player, game_manager)
	assert(count_card_ids_in_hand(player, POOL_CARD_IDS) == 1)
	assert(count_card_ids_in_hand(player, SSS_POOL_CARD_IDS) == 1)
	assert(get_reserve_runtime(player, resolver, RESERVE_ID).get("remaining_pool", []).size() == 3)
	assert(get_reserve_runtime(player, resolver, SSS_RESERVE_ID).get("remaining_pool", []).size() == 3)
	free_game_manager(game_manager)


func create_context() -> Dictionary:
	var game_manager := GameManager.new()
	game_manager.card_database = load_database()
	game_manager.board_states.clear()
	game_manager.aerial_board_states.clear()

	var player := PlayerState.new()
	player.setup("player_1", "测试玩家")
	player.set_faction("tokyo_ghoul", "东京喰种")
	game_manager.players = [player]

	var resolver := CardReserveResolverScript.new()
	resolver.random.seed = 20260716
	return {
		"game_manager": game_manager,
		"player": player,
		"resolver": resolver,
	}


func load_database() -> CardDatabase:
	var database := CardDatabase.new()
	assert(database.load_from_json("res://data/cards.json"))
	return database


func get_runtime(player: PlayerState, resolver: CardReserveResolver) -> Dictionary:
	return get_reserve_runtime(player, resolver, RESERVE_ID)


func get_reserve_runtime(player: PlayerState, resolver: CardReserveResolver, reserve_id: String) -> Dictionary:
	return player.get_effect_runtime_value(resolver.get_runtime_key(reserve_id), {})


func count_pool_minions_in_hand(player: PlayerState) -> int:
	return get_pool_minion_ids_in_hand(player).size()


func count_card_ids_in_hand(player: PlayerState, card_ids: Array[String]) -> int:
	var count := 0
	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data != null and card_ids.has(card_data.id):
			count += 1
	return count


func get_pool_minion_ids_in_hand(player: PlayerState) -> Array[String]:
	var ids: Array[String] = []
	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data != null and POOL_CARD_IDS.has(card_data.id):
			ids.append(card_data.id)
	return ids


func remove_pool_minions_from_hand(player: PlayerState) -> void:
	for hand_index in range(player.hand.size() - 1, -1, -1):
		var card_data := player.get_hand_card_data_at(hand_index)
		if card_data != null and POOL_CARD_IDS.has(card_data.id):
			player.remove_from_hand_at(hand_index, card_data)


func free_game_manager(game_manager: GameManager) -> void:
	if game_manager == null:
		return
	if game_manager.audio_manager != null:
		game_manager.audio_manager.free()
	game_manager.free()


func get_first_pool_minion_in_hand(player: PlayerState) -> CardData:
	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data != null and POOL_CARD_IDS.has(card_data.id):
			return card_data
	return null
