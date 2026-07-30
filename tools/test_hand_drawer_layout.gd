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
	assert(used_height <= sections.size.y + 1.0)

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

	print("HAND_DRAWER_LAYOUT_TESTS_OK")
	scene.queue_free()
	await process_frame
	controller = null
	player = null
	await process_frame
	quit()


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
