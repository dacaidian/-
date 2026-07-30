extends SceneTree

const GameUiSkinScript := preload("res://scripts/ui/game_ui_skin.gd")
const HandDrawerControllerScript := preload("res://scripts/ui/hand_drawer_controller.gd")
const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_skin_factory()
	await _test_main_menu_skin()
	await _test_collection_skin()
	await _test_hand_drawer_skin()
	_test_hud_skin()
	print("UI_SKIN_TESTS_OK")
	quit()


func _test_skin_factory() -> void:
	var main_panel := GameUiSkinScript.create_panel_style(
		GameUiSkinScript.PanelKind.MAIN,
		ApplicationUiStyle.GOLD
	)
	var inset_panel := GameUiSkinScript.create_panel_style(
		GameUiSkinScript.PanelKind.INSET,
		ApplicationUiStyle.BLUE
	)
	var hud_panel := GameUiSkinScript.create_panel_style(
		GameUiSkinScript.PanelKind.HUD,
		ApplicationUiStyle.BLUE
	)
	assert(main_panel is StyleBoxTexture)
	assert(inset_panel is StyleBoxTexture)
	assert(hud_panel is StyleBoxTexture)
	assert(main_panel.texture != null)
	assert(inset_panel.texture != null)
	assert(hud_panel.texture != null)
	assert(main_panel.get_texture_margin(SIDE_LEFT) > 0.0)
	assert(inset_panel.get_texture_margin(SIDE_TOP) > 0.0)
	assert(hud_panel.get_texture_margin(SIDE_RIGHT) > 0.0)
	assert(main_panel.content_margin_left >= 42.0)
	assert(main_panel.content_margin_top >= 42.0)
	assert(inset_panel.content_margin_left >= 28.0)
	assert(inset_panel.content_margin_top >= 16.0)
	assert(hud_panel.content_margin_left >= 36.0)
	assert(hud_panel.content_margin_top >= 18.0)
	assert(inset_panel.texture.get_height() <= 192)
	assert(hud_panel.texture.get_height() <= 192)

	var normal := GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.PRIMARY,
		GameUiSkinScript.ButtonState.NORMAL
	)
	var hover := GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.PRIMARY,
		GameUiSkinScript.ButtonState.HOVER
	)
	var pressed := GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.PRIMARY,
		GameUiSkinScript.ButtonState.PRESSED
	)
	var disabled := GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.PRIMARY,
		GameUiSkinScript.ButtonState.DISABLED
	)
	var tab := GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.TAB,
		GameUiSkinScript.ButtonState.NORMAL
	)
	assert(normal.texture != hover.texture)
	assert(hover.texture != pressed.texture)
	assert(pressed.texture != disabled.texture)
	assert(tab.texture != normal.texture)
	assert(normal.texture.get_height() <= 96)
	assert(tab.texture.get_height() > tab.texture.get_width())
	assert(pressed.content_margin_top > normal.content_margin_top)
	assert(pressed.content_margin_bottom < normal.content_margin_bottom)

	var field_normal := GameUiSkinScript.create_field_style(false)
	var field_focus := GameUiSkinScript.create_field_style(true)
	assert(field_normal.texture != field_focus.texture)


func _test_main_menu_skin() -> void:
	var packed_scene := load("res://scenes/main_menu/main_menu.tscn") as PackedScene
	assert(packed_scene != null)
	var screen := packed_scene.instantiate() as Control
	root.add_child(screen)
	await process_frame

	var panel := screen.get_node("%MenuPanel") as PanelContainer
	var panel_margin := panel.get_node("Margin") as MarginContainer
	var start_button := screen.get_node("%StartGameButton") as Button
	assert(panel.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(panel_margin.position.x >= 42.0)
	assert(panel_margin.position.y >= 42.0)
	assert(start_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(start_button.get_theme_stylebox("hover") is StyleBoxTexture)
	assert(start_button.get_theme_stylebox("pressed") is StyleBoxTexture)

	screen.queue_free()
	await process_frame


func _test_collection_skin() -> void:
	var packed_scene := load("res://scenes/ui/card_collection_screen.tscn") as PackedScene
	assert(packed_scene != null)
	var screen := packed_scene.instantiate() as Control
	root.add_child(screen)
	await process_frame
	await process_frame

	var faction_panel := screen.get_node("%FactionPanel") as PanelContainer
	var filter_panel := screen.get_node("%FilterPanel") as PanelContainer
	var faction_margin := faction_panel.get_node("FactionMargin") as MarginContainer
	var filter_margin := filter_panel.get_node("FilterMargin") as MarginContainer
	var search_input := screen.get_node("%SearchInput") as LineEdit
	assert(faction_panel.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(filter_panel.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(faction_margin.position.x >= 28.0)
	assert(filter_margin.position.x >= 28.0)
	assert(search_input.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(search_input.get_theme_stylebox("focus") is StyleBoxTexture)

	screen.queue_free()
	await process_frame


func _test_hand_drawer_skin() -> void:
	var host := Control.new()
	host.name = "HandDrawerSkinHost"
	root.add_child(host)
	var packed_scene := load("res://scenes/ui/hand_drawer_panel.tscn") as PackedScene
	assert(packed_scene != null)
	var panel := packed_scene.instantiate() as Panel
	host.add_child(panel)

	var controller := HandDrawerControllerScript.new()
	controller.setup(host, NodePath("HandDrawerPanel"))
	await process_frame
	await process_frame

	var spell_section := panel.get_node(
		"DrawerBody/MarginContainer/VBoxContainer/Sections/SpellSection"
	) as PanelContainer
	var drawer_body := panel.get_node("DrawerBody") as Control
	var toggle_button := panel.get_node("ToggleButton") as Button
	var main_safe_insets := GameUiSkinScript.get_panel_safe_insets(
		GameUiSkinScript.PanelKind.MAIN
	)
	assert(panel.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(drawer_body.position.x >= main_safe_insets.x)
	assert(drawer_body.position.y >= main_safe_insets.y)
	assert(
		panel.size.x - (drawer_body.position.x + drawer_body.size.x)
		>= main_safe_insets.z
	)
	assert(
		panel.size.y - (drawer_body.position.y + drawer_body.size.y)
		>= main_safe_insets.w
	)
	assert(spell_section.get_theme_stylebox("panel") is StyleBoxTexture)
	assert(toggle_button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(toggle_button.get_theme_stylebox("pressed") is StyleBoxTexture)

	host.queue_free()
	await process_frame


func _test_hud_skin() -> void:
	var panel_style := RightSideHudStyleScript.create_panel_style(
		RightSideHudStyleScript.ACCENT_TURN
	)
	var normal_button := RightSideHudStyleScript.create_button_style(
		RightSideHudStyleScript.ACCENT_TIME
	)
	var pressed_button := RightSideHudStyleScript.create_button_style(
		RightSideHudStyleScript.ACCENT_TIME,
		false,
		true
	)
	assert(panel_style is StyleBoxTexture)
	assert(normal_button is StyleBoxTexture)
	assert(pressed_button is StyleBoxTexture)
	assert(normal_button.texture != pressed_button.texture)
