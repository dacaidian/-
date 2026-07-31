extends SceneTree


func _init() -> void:
	run.call_deferred()


func run() -> void:
	var scene := create_hand_drawer_scene()
	root.add_child(scene)
	await process_frame
	await process_frame

	var controller := HandDrawerController.new()
	controller.setup(scene, NodePath("HandDrawerPanel"))

	var player := PlayerState.new()
	player.setup("layout_test", "布局测试")
	player.set_faction("layout_test", "布局测试种族")
	append_cards(player, CardData.TYPE_SPELL, 3)
	append_cards(player, CardData.TYPE_UPGRADE, 30)
	controller.update(player)
	await wait_for_layout()

	var sections := scene.get_node("HandDrawerPanel/DrawerBody/MarginContainer/VBoxContainer/Sections") as VBoxContainer
	var spell_section := sections.get_node("SpellSection") as PanelContainer
	var minion_section := sections.get_node("MinionSection") as PanelContainer
	var upgrade_section := sections.get_node("UpgradeSection") as PanelContainer
	var equipment_section := sections.get_node("EquipmentSection") as PanelContainer
	assert(upgrade_section.size.y > spell_section.size.y)
	assert(minion_section.size.y < spell_section.size.y)
	assert(equipment_section.size.y < spell_section.size.y)
	assert(not minion_section.get_node("VBoxContainer/CardList").visible)
	assert(not equipment_section.get_node("VBoxContainer/CardList").visible)
	assert("3" in str(spell_section.get_node("VBoxContainer/SectionTitle").text))
	assert("30" in str(upgrade_section.get_node("VBoxContainer/SectionTitle").text))

	var used_height := float(sections.get_theme_constant("separation")) * 3.0
	for section in [spell_section, minion_section, upgrade_section, equipment_section]:
		used_height += section.size.y
	assert(
		used_height <= sections.size.y + 1.0,
		"Hand sections overflowed: used=%s available=%s" % [used_height, sections.size.y]
	)

	var old_scroll := controller.get_section_scroll_container("upgrade")
	assert(old_scroll != null)
	assert(controller.get_cards_per_row() >= 3)
	assert(old_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(not old_scroll.get_h_scroll_bar().visible)
	assert(old_scroll.scroll_horizontal == 0)
	old_scroll.scroll_vertical = 100
	await process_frame
	var expected_offset := old_scroll.scroll_vertical
	if expected_offset <= 0:
		push_error("Upgrade section did not create a vertical scroll range")
		scene.queue_free()
		await process_frame
		quit(1)
		return
	controller.update(player)
	await wait_for_layout()
	var new_scroll := controller.get_section_scroll_container("upgrade")
	assert(new_scroll != null)
	assert(abs(new_scroll.scroll_vertical - expected_offset) <= 1)

	scene.queue_free()
	await process_frame
	controller = null
	player = null
	await process_frame

	await test_constrained_viewport_layout()
	await test_runtime_resize_layout()
	print("HAND_DRAWER_LAYOUT_TESTS_OK")
	quit()


func test_constrained_viewport_layout() -> void:
	var viewport := SubViewport.new()
	viewport.name = "ConstrainedHandDrawerViewport"
	viewport.size = Vector2i(640, 640)
	root.add_child(viewport)

	var scene := create_hand_drawer_scene()
	viewport.add_child(scene)
	await process_frame
	await process_frame

	var controller := HandDrawerController.new()
	controller.setup(scene, NodePath("HandDrawerPanel"))
	var player := PlayerState.new()
	player.setup("constrained_layout_test", "窄屏布局测试")
	player.set_faction("layout_test", "布局测试种族")
	for card_type in [
		CardData.TYPE_SPELL,
		CardData.TYPE_MINION,
		CardData.TYPE_UPGRADE,
		CardData.TYPE_EQUIPMENT
	]:
		append_cards(player, card_type, 8)
	controller.update(player)
	await wait_for_layout()

	var panel := scene.get_node("HandDrawerPanel") as Panel
	var sections := panel.get_node("DrawerBody/MarginContainer/VBoxContainer/Sections") as VBoxContainer
	assert(panel.position.x >= -0.01)
	assert(panel.position.y >= -0.01)
	assert(panel.position.x + panel.size.x <= float(viewport.size.x) + 0.01)
	assert(panel.position.y + panel.size.y <= float(viewport.size.y) + 0.01)

	var used_height := float(sections.get_theme_constant("separation")) * 3.0
	for card_type in controller.SECTION_TYPES:
		var section := controller.section_panels.get(card_type) as PanelContainer
		assert(section != null and section.visible)
		assert(section.size.y > 0.0)
		used_height += section.size.y
		var scroll := controller.get_section_scroll_container(card_type)
		assert(scroll != null)
		assert(scroll.size.y > 0.0)
	assert(used_height <= sections.size.y + 1.0)
	assert(sections.size.y <= controller.get_sections_height_budget() + 1.0)

	var equipment_section := controller.section_panels.get(CardData.TYPE_EQUIPMENT) as PanelContainer
	assert(
		equipment_section.get_global_rect().end.y <= panel.get_global_rect().end.y + 0.01,
		"Equipment section ended below the drawer viewport"
	)

	viewport.queue_free()
	await process_frame
	controller = null
	player = null
	await process_frame


func test_runtime_resize_layout() -> void:
	var viewport := SubViewport.new()
	viewport.name = "ResizableHandDrawerViewport"
	viewport.size = Vector2i(1024, 720)
	root.add_child(viewport)

	var scene := create_hand_drawer_scene()
	viewport.add_child(scene)
	await process_frame
	await process_frame

	var controller := HandDrawerController.new()
	controller.setup(scene, NodePath("HandDrawerPanel"))
	var player := PlayerState.new()
	player.setup("resize_layout_test", "缩放布局测试")
	player.set_faction("layout_test", "布局测试种族")
	for card_type in controller.SECTION_TYPES:
		append_cards(player, card_type, 12)
	controller.update(player)
	await wait_for_layout()

	var initial_flow_width := controller.get_card_flow_width()
	assert(controller.get_cards_per_row() >= 3)
	assert_all_card_flows_match_width(controller, initial_flow_width)
	var upgrade_scroll := controller.get_section_scroll_container(CardData.TYPE_UPGRADE)
	assert(upgrade_scroll != null)
	upgrade_scroll.scroll_vertical = 120
	await process_frame
	var expected_scroll_offset := upgrade_scroll.scroll_vertical
	assert(expected_scroll_offset > 0)

	controller.set_open(false)
	await wait_for_drawer_tween()
	viewport.size = Vector2i(560, 520)
	await wait_for_layout()

	var panel := scene.get_node("HandDrawerPanel") as Panel
	var toggle := panel.get_node("ToggleButton") as Button
	var toggle_rect := toggle.get_global_rect()
	assert(toggle_rect.position.x >= -0.01)
	assert(toggle_rect.end.x <= float(viewport.size.x) + 0.01)
	assert(panel.get_global_rect().end.x <= float(viewport.size.x) + 0.01)

	var resized_flow_width := controller.get_card_flow_width()
	assert(resized_flow_width < initial_flow_width)
	assert(controller.get_cards_per_row() == 2)
	assert_all_card_flows_match_width(controller, resized_flow_width)
	assert(abs(upgrade_scroll.scroll_vertical - expected_scroll_offset) <= 1)

	controller.set_open(true)
	await wait_for_drawer_tween()
	assert(panel.get_global_rect().position.x >= -0.01)
	assert(panel.get_global_rect().end.x <= float(viewport.size.x) + 0.01)
	assert(panel.get_global_rect().end.y <= float(viewport.size.y) + 0.01)

	viewport.queue_free()
	await process_frame
	controller = null
	player = null
	await process_frame


func assert_all_card_flows_match_width(controller: HandDrawerController, expected_width: float) -> void:
	for card_type in controller.SECTION_TYPES:
		var scroll := controller.get_section_scroll_container(card_type)
		assert(scroll != null)
		var flow := scroll.get_node("GlowPadding/CardFlow") as HFlowContainer
		assert(flow != null)
		assert(
			is_equal_approx(flow.custom_minimum_size.x, expected_width),
			"Card flow kept stale width: type=%s actual=%s expected=%s" % [
				card_type,
				flow.custom_minimum_size.x,
				expected_width
			]
		)
		assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
		assert(not scroll.get_h_scroll_bar().visible)


func append_cards(player: PlayerState, card_type: String, amount: int) -> void:
	for index in range(amount):
		var card_data := CardData.new()
		card_data.id = "%s_%d" % [card_type, index]
		card_data.display_name = card_data.id
		card_data.type = card_type
		player.hand.append(card_data)


func create_hand_drawer_scene() -> Control:
	var scene := Control.new()
	scene.name = "HandDrawerTestRoot"
	scene.size = Vector2(1280.0, 900.0)
	var packed_scene := load("res://scenes/ui/hand_drawer_panel.tscn") as PackedScene
	assert(packed_scene != null)
	var panel := packed_scene.instantiate() as Panel
	assert(panel != null)
	scene.add_child(panel)
	return scene


func wait_for_layout() -> void:
	await process_frame
	await process_frame
	await process_frame


func wait_for_drawer_tween() -> void:
	await create_timer(0.24).timeout
	await process_frame
