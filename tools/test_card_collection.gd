extends SceneTree

const CardCollectionCatalogScript := preload(
	"res://scripts/application/card_collection_catalog.gd"
)
const CardCatalogEntryScript := preload(
	"res://scripts/application/card_catalog_entry.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_database := CardDatabase.new()
	assert(card_database.load_from_json("res://data/cards.json"))

	var catalog := CardCollectionCatalogScript.new()
	catalog.rebuild(card_database)
	test_catalog_completeness(card_database, catalog)
	test_source_categories(catalog)
	test_search_and_filters(catalog)
	await test_screen_interactions(catalog.get_total_count())

	print("CARD_COLLECTION_TESTS_OK")
	quit()


func test_catalog_completeness(
	card_database: CardDatabase,
	catalog: CardCollectionCatalogScript
) -> void:
	var expected_total := 0
	var expected_tokens := 0
	for faction_id in card_database.get_all_faction_ids():
		expected_total += card_database.get_faction_cards(faction_id).size()
		var faction_tokens := card_database.get_faction_token_cards(faction_id)
		expected_total += faction_tokens.size()
		expected_tokens += faction_tokens.size()

	assert(expected_total > 170)
	assert(catalog.get_total_count() == expected_total)
	assert(catalog.query({
		"category": CardCatalogEntryScript.CATEGORY_TOKEN,
	}).size() == expected_tokens)


func test_source_categories(catalog: CardCollectionCatalogScript) -> void:
	var water_elemental = _find_entry(catalog.entries, "water_elemental")
	var summon_spell = _find_entry(catalog.entries, "summon_water_elemental")
	var starting_upgrade = _find_entry(catalog.entries, "fox_sacrifice_upgrade")
	var time_state = _find_entry(catalog.entries, "sentinel_time_full_moon")

	assert(water_elemental != null)
	assert(water_elemental.is_token())
	assert(water_elemental.faction_id == "dalaran_council")
	assert(water_elemental.category == CardCatalogEntryScript.CATEGORY_TOKEN)
	assert(summon_spell.category == CardCatalogEntryScript.CATEGORY_POOL)
	assert(starting_upgrade.category == CardCatalogEntryScript.CATEGORY_STARTING_HAND)
	assert(time_state.category == CardCatalogEntryScript.CATEGORY_SYSTEM)


func test_search_and_filters(catalog: CardCollectionCatalogScript) -> void:
	var flying_results = catalog.query({"search": "飞行"})
	assert(not flying_results.is_empty())
	for entry in flying_results:
		assert(entry.search_text.contains("飞行"))

	var jaina_cards = catalog.query({
		"faction_id": "dalaran_council",
		"search": "吉安娜",
	})
	assert(jaina_cards.size() >= 4)
	assert(_find_entry(jaina_cards, "cone_of_cold") != null)

	var heroes = catalog.query({"type": CardData.ROLE_HERO})
	var regular_minions = catalog.query({"type": CardData.TYPE_MINION})
	assert(not heroes.is_empty())
	assert(not regular_minions.is_empty())
	for hero_entry in heroes:
		assert(hero_entry.card_data.is_hero())
	for minion_entry in regular_minions:
		assert(minion_entry.card_data.is_minion())
		assert(not minion_entry.card_data.is_hero())

	var dalaran_level_one_tokens = catalog.query({
		"faction_id": "dalaran_council",
		"category": CardCatalogEntryScript.CATEGORY_TOKEN,
		"level": 1,
	})
	assert(_find_entry(dalaran_level_one_tokens, "water_elemental") != null)
	for entry in dalaran_level_one_tokens:
		assert(entry.is_token())
		assert(entry.faction_id == "dalaran_council")
		assert(entry.card_data.level == 1)


func test_screen_interactions(expected_total: int) -> void:
	root.size = Vector2i(1920, 1080)
	var screen_scene := load("res://scenes/ui/card_collection_screen.tscn") as PackedScene
	assert(screen_scene != null)
	var screen = screen_scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	assert(screen.get_result_count() == expected_total)
	assert(screen.get_current_page_entries().size() <= screen.PAGE_SIZE)
	assert(screen.get_node("%DetailsTexture").texture != null)

	var category_option := screen.get_node("%CategoryOption") as OptionButton
	category_option.select(3)
	category_option.item_selected.emit(3)
	await process_frame
	for entry in screen.get_current_page_entries():
		assert(entry.category == CardCatalogEntryScript.CATEGORY_TOKEN)

	var reset_button := screen.get_node("%ResetButton") as Button
	reset_button.pressed.emit()
	await process_frame
	assert(screen.get_result_count() == expected_total)

	var search_input := screen.get_node("%SearchInput") as LineEdit
	search_input.text = "水元素"
	await create_timer(0.18).timeout
	assert(screen.get_result_count() >= 2)

	var body := screen.get_node("RootMargin/RootLayout/Body") as Control
	var details_panel := screen.get_node("%DetailsPanel") as Control
	var faction_panel := screen.get_node("%FactionPanel") as PanelContainer
	var filter_panel := screen.get_node("%FilterPanel") as PanelContainer
	var results_panel := screen.get_node("%ResultsPanel") as PanelContainer
	var options_row := screen.get_node(
		"RootMargin/RootLayout/Body/CenterColumn/FilterPanel/FilterMargin/"
		+ "FilterLayout/OptionsRow"
	) as HFlowContainer
	assert(options_row != null)
	assert(body.size.x > 0.0 and body.size.y > 0.0)
	assert(details_panel.get_global_rect().end.x <= screen.size.x + 0.5)
	assert(details_panel.get_global_rect().end.y <= screen.size.y + 0.5)
	assert_panel_frame_is_valid(faction_panel)
	assert_panel_frame_is_valid(filter_panel)
	assert_panel_frame_is_valid(results_panel)
	assert_panel_frame_is_valid(details_panel as PanelContainer)
	var horizontal_scrolls: Array[ScrollContainer] = [
		screen.get_node(
			"RootMargin/RootLayout/Body/FactionPanel/FactionMargin/"
			+ "FactionLayout/FactionScroll"
		) as ScrollContainer,
		screen.get_node("%CardGridScroll") as ScrollContainer,
		details_panel.get_node("DetailsScroll") as ScrollContainer,
	]
	for scroll in horizontal_scrolls:
		assert(scroll != null)
		assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
		assert(not scroll.get_h_scroll_bar().visible)

	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	assert(body.get_global_rect().end.x <= screen.size.x + 0.5)
	assert(details_panel.get_global_rect().end.x <= screen.size.x + 0.5)
	for option_control in options_row.get_children():
		var option_rect := (option_control as Control).get_global_rect()
		assert(option_rect.end.x <= options_row.get_global_rect().end.x + 0.5)
	for scroll in horizontal_scrolls:
		assert(not scroll.get_h_scroll_bar().visible)

	var back_requested := [false]
	screen.back_requested.connect(func(): back_requested[0] = true)
	var back_button := screen.get_node("%BackButton") as Button
	back_button.pressed.emit()
	assert(back_requested[0])

	screen.queue_free()
	await process_frame
	await process_frame


func assert_panel_frame_is_valid(panel: PanelContainer) -> void:
	assert(panel != null)
	var style := panel.get_theme_stylebox("panel") as StyleBoxTexture
	assert(style != null)
	assert(panel.size.x > (
		style.get_texture_margin(SIDE_LEFT)
		+ style.get_texture_margin(SIDE_RIGHT)
		+ 8.0
	))
	assert(panel.size.y > (
		style.get_texture_margin(SIDE_TOP)
		+ style.get_texture_margin(SIDE_BOTTOM)
		+ 8.0
	))


func _find_entry(entries: Array, card_id: String):
	for entry in entries:
		if entry != null and entry.card_data != null and entry.card_data.id == card_id:
			return entry
	return null
