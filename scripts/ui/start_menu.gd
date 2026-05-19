extends Control
class_name StartMenu

const PLAYER_COUNT := 2

@export var cards_json_path := "res://data/cards.json"
@export var battle_scene_path := "res://main.tscn"
@export var player_names: Array[String] = ["Player 1", "Player 2"]

var card_database := CardDatabase.new()
var match_setup := MatchSetup.new()
var faction_ids: Array[String] = []
var faction_selects: Array[OptionButton] = []
var hero_selects: Array[OptionButton] = []
var logo_textures: Array[TextureRect] = []
var hero_textures: Array[TextureRect] = []
var faction_labels: Array[Label] = []
var hero_labels: Array[Label] = []
var attached_labels: Array[Label] = []
var control_type_selects: Array[OptionButton] = []
var ai_difficulty_selects: Array[OptionButton] = []
var start_button: Button
var warning_label: Label
var is_refreshing := false


func _ready() -> void:
	if not card_database.load_from_json(cards_json_path):
		push_error("入口页无法加载卡牌数据")
		return

	faction_ids = card_database.get_playable_faction_ids()
	match_setup.initialize_defaults(card_database, faction_ids, player_names, PLAYER_COUNT)
	build_view()
	refresh_all_controls()


func build_view() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = load("res://assets/img/ChatGPT Image 2026年5月11日 14_57_04.png") as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.03, 0.025, 0.02, 0.62)
	add_child(shade)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 78)
	root_margin.add_theme_constant_override("margin_top", 56)
	root_margin.add_theme_constant_override("margin_right", 78)
	root_margin.add_theme_constant_override("margin_bottom", 56)
	add_child(root_margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 28)
	root_margin.add_child(root_box)

	root_box.add_child(create_header())
	root_box.add_child(create_selection_area())
	root_box.add_child(create_footer())


func create_header() -> Control:
	var header := VBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "选择你的阵营"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.52, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "双方选择不同种族与英雄后，即可进入战局"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.93, 0.87, 0.74, 0.95))
	header.add_child(subtitle)

	return header


func create_selection_area() -> Control:
	var area := HBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.add_theme_constant_override("separation", 38)

	for index in range(PLAYER_COUNT):
		area.add_child(create_player_panel(index))

	return area


func create_player_panel(player_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", create_panel_style(player_index))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var player_label := Label.new()
	player_label.text = player_names[player_index] if player_index < player_names.size() else "Player %d" % (player_index + 1)
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.add_theme_font_size_override("font_size", 32)
	player_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76, 1.0))
	box.add_child(player_label)

	var logo_frame := PanelContainer.new()
	logo_frame.custom_minimum_size = Vector2(160, 160)
	logo_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_frame.add_theme_stylebox_override("panel", create_logo_style())
	box.add_child(logo_frame)

	var logo_texture := TextureRect.new()
	logo_texture.custom_minimum_size = Vector2(142, 142)
	logo_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_frame.add_child(logo_texture)
	logo_textures.append(logo_texture)

	var faction_label := Label.new()
	faction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	faction_label.add_theme_font_size_override("font_size", 25)
	faction_label.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0, 1.0))
	box.add_child(faction_label)
	faction_labels.append(faction_label)

	var faction_select := OptionButton.new()
	faction_select.custom_minimum_size = Vector2(0, 58)
	faction_select.add_theme_font_size_override("font_size", 22)
	faction_select.add_theme_stylebox_override("normal", create_select_style(false))
	faction_select.add_theme_stylebox_override("hover", create_select_style(true))
	faction_select.item_selected.connect(_on_faction_selected.bind(player_index))
	box.add_child(faction_select)
	faction_selects.append(faction_select)

	var hero_title := Label.new()
	hero_title.text = "英雄"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 22)
	hero_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.47, 1.0))
	box.add_child(hero_title)

	var hero_preview := TextureRect.new()
	hero_preview.custom_minimum_size = Vector2(220, 308)
	hero_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hero_preview)
	hero_textures.append(hero_preview)

	var hero_select := OptionButton.new()
	hero_select.custom_minimum_size = Vector2(0, 52)
	hero_select.add_theme_font_size_override("font_size", 20)
	hero_select.add_theme_stylebox_override("normal", create_select_style(false))
	hero_select.add_theme_stylebox_override("hover", create_select_style(true))
	hero_select.item_selected.connect(_on_hero_selected.bind(player_index))
	box.add_child(hero_select)
	hero_selects.append(hero_select)

	var hero_label := Label.new()
	hero_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_label.add_theme_font_size_override("font_size", 18)
	hero_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.76, 0.95))
	box.add_child(hero_label)
	hero_labels.append(hero_label)

	var attached_label := Label.new()
	attached_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attached_label.add_theme_font_size_override("font_size", 16)
	attached_label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.95, 0.9))
	box.add_child(attached_label)
	attached_labels.append(attached_label)

	var control_separator := HSeparator.new()
	control_separator.custom_minimum_size = Vector2(0, 2)
	control_separator.add_theme_color_override("color", Color(0.75, 0.60, 0.36, 0.55))
	box.add_child(control_separator)

	var control_title := Label.new()
	control_title.text = "操控方式"
	control_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_title.add_theme_font_size_override("font_size", 18)
	control_title.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0, 0.85))
	box.add_child(control_title)

	var control_type_select := OptionButton.new()
	control_type_select.custom_minimum_size = Vector2(0, 50)
	control_type_select.add_theme_font_size_override("font_size", 20)
	control_type_select.add_theme_stylebox_override("normal", create_select_style(false))
	control_type_select.add_theme_stylebox_override("hover", create_select_style(true))
	control_type_select.add_item("玩家操作")
	control_type_select.set_item_metadata(0, false)
	control_type_select.add_item("AI 控制")
	control_type_select.set_item_metadata(1, true)
	control_type_select.item_selected.connect(_on_control_type_selected.bind(player_index))
	box.add_child(control_type_select)
	control_type_selects.append(control_type_select)

	var ai_difficulty_select := OptionButton.new()
	ai_difficulty_select.custom_minimum_size = Vector2(0, 46)
	ai_difficulty_select.add_theme_font_size_override("font_size", 18)
	ai_difficulty_select.add_theme_stylebox_override("normal", create_select_style(false))
	ai_difficulty_select.add_theme_stylebox_override("hover", create_select_style(true))
	ai_difficulty_select.add_item("AI 难度：简单")
	ai_difficulty_select.set_item_metadata(0, "easy")
	ai_difficulty_select.add_item("AI 难度：普通")
	ai_difficulty_select.set_item_metadata(1, "normal")
	ai_difficulty_select.add_item("AI 难度：困难")
	ai_difficulty_select.set_item_metadata(2, "hard")
	ai_difficulty_select.select(1)
	ai_difficulty_select.visible = false
	ai_difficulty_select.item_selected.connect(_on_ai_difficulty_selected.bind(player_index))
	box.add_child(ai_difficulty_select)
	ai_difficulty_selects.append(ai_difficulty_select)

	return panel


func create_footer() -> Control:
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	warning_label = Label.new()
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 18)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.44, 1.0))
	footer.add_child(warning_label)

	start_button = Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(320, 68)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.add_theme_color_override("font_color", Color(0.16, 0.10, 0.04, 1.0))
	start_button.add_theme_color_override("font_disabled_color", Color(0.62, 0.55, 0.48, 1.0))
	start_button.add_theme_stylebox_override("normal", create_start_button_style(false))
	start_button.add_theme_stylebox_override("hover", create_start_button_style(true))
	start_button.add_theme_stylebox_override("pressed", create_start_button_style(true))
	start_button.add_theme_stylebox_override("disabled", create_start_button_disabled_style())
	start_button.pressed.connect(_on_start_pressed)
	footer.add_child(start_button)

	return footer


func refresh_all_controls() -> void:
	is_refreshing = true
	for index in range(PLAYER_COUNT):
		refresh_faction_select(index)
		refresh_hero_select(index)
		refresh_preview(index)
		refresh_control_type_select(index)

	is_refreshing = false
	refresh_start_button()


func refresh_faction_select(player_index: int) -> void:
	var select := faction_selects[player_index]
	select.clear()

	var opponent_index := 1 - player_index
	var opponent_faction_id := match_setup.get_faction_id(opponent_index)
	var selected_index := 0

	for index in range(faction_ids.size()):
		var faction_id := faction_ids[index]
		select.add_item(card_database.get_faction_display_name(faction_id))
		select.set_item_metadata(index, faction_id)
		if faction_id == opponent_faction_id:
			select.set_item_disabled(index, true)
		if faction_id == match_setup.get_faction_id(player_index):
			selected_index = index

	select.select(selected_index)


func refresh_hero_select(player_index: int) -> void:
	var select := hero_selects[player_index]
	select.clear()

	var heroes := card_database.get_faction_heroes(match_setup.get_faction_id(player_index))
	var selected_hero_id := match_setup.get_hero_id(player_index)
	if selected_hero_id == "" and not heroes.is_empty():
		selected_hero_id = heroes[0].id
		match_setup.set_hero(player_index, selected_hero_id)

	var selected_index := 0
	for index in range(heroes.size()):
		var hero := heroes[index]
		select.add_item(hero.display_name)
		select.set_item_metadata(index, hero.id)
		if hero.id == selected_hero_id:
			selected_index = index

	select.disabled = heroes.is_empty()
	if not heroes.is_empty():
		select.select(selected_index)


func refresh_preview(player_index: int) -> void:
	var faction_id := match_setup.get_faction_id(player_index)
	var hero_id := match_setup.get_hero_id(player_index)
	var faction_name := card_database.get_faction_display_name(faction_id)
	var hero := card_database.get_card(hero_id)

	faction_labels[player_index].text = faction_name
	logo_textures[player_index].texture = load_faction_logo(faction_id)

	if hero != null:
		hero_textures[player_index].texture = hero.front_texture
		hero_labels[player_index].text = hero.description if hero.description != "" else hero.display_name
	else:
		hero_textures[player_index].texture = null
		hero_labels[player_index].text = "该种族暂未配置英雄"

	var attached_count := card_database.get_attached_card_ids(faction_id, hero_id).size()
	attached_labels[player_index].text = "英雄附属牌：%d" % attached_count


func refresh_control_type_select(player_index: int) -> void:
	var control_select := control_type_selects[player_index]
	var is_ai := match_setup.get_ai_flag(player_index)
	control_select.select(0 if not is_ai else 1)

	var difficulty_select := ai_difficulty_selects[player_index]
	difficulty_select.visible = is_ai

	if is_ai:
		var difficulty := match_setup.get_ai_difficulty(player_index)
		match difficulty:
			"easy":   difficulty_select.select(0)
			"normal": difficulty_select.select(1)
			"hard":   difficulty_select.select(2)
			_:        difficulty_select.select(1)


func refresh_start_button() -> void:
	var can_start := can_start_game()
	start_button.disabled = not can_start
	warning_label.text = "" if can_start else get_start_warning()


func can_start_game() -> bool:
	return match_setup.can_start()


func get_start_warning() -> String:
	return match_setup.get_start_warning(faction_ids)


func _on_faction_selected(item_index: int, player_index: int) -> void:
	if is_refreshing:
		return

	var select := faction_selects[player_index]
	var faction_id := str(select.get_item_metadata(item_index))
	if faction_id == "":
		return

	match_setup.set_faction(player_index, faction_id, faction_ids, card_database)
	refresh_all_controls()


func _on_hero_selected(item_index: int, player_index: int) -> void:
	if is_refreshing:
		return

	var select := hero_selects[player_index]
	match_setup.set_hero(player_index, str(select.get_item_metadata(item_index)))
	refresh_preview(player_index)
	refresh_start_button()


func _on_control_type_selected(item_index: int, player_index: int) -> void:
	if is_refreshing:
		return

	var select := control_type_selects[player_index]
	var is_ai := bool(select.get_item_metadata(item_index))
	match_setup.set_ai_control(player_index, is_ai)
	var difficulty_select := ai_difficulty_selects[player_index]
	difficulty_select.visible = is_ai
	refresh_start_button()


func _on_ai_difficulty_selected(item_index: int, player_index: int) -> void:
	if is_refreshing:
		return

	var select := ai_difficulty_selects[player_index]
	var difficulty := str(select.get_item_metadata(item_index))
	match_setup.set_ai_difficulty(player_index, difficulty)


func _on_start_pressed() -> void:
	if not can_start_game():
		return

	var battle_scene := load(battle_scene_path) as PackedScene
	if battle_scene == null:
		push_error("找不到战斗场景: %s" % battle_scene_path)
		return

	var battle_root := battle_scene.instantiate()
	var game_manager := battle_root.get_node_or_null("GameManager") as GameManager
	if game_manager == null:
		push_error("战斗场景缺少 GameManager")
		battle_root.queue_free()
		return

	game_manager.player_faction_ids = match_setup.player_faction_ids.duplicate()
	game_manager.selected_hero_card_ids = match_setup.selected_hero_card_ids.duplicate()
	game_manager.player_names = match_setup.player_names.duplicate()
	game_manager.player_ai_flags = match_setup.player_ai_flags.duplicate()
	game_manager.player_ai_difficulties = match_setup.player_ai_difficulties.duplicate()

	get_tree().root.add_child(battle_root)
	get_tree().current_scene = battle_root
	queue_free()


func load_faction_logo(faction_id: String) -> Texture2D:
	var folder_name := card_database.get_faction_display_name(faction_id)
	var logo_path := "res://assets/img/%s/logo.png" % folder_name
	if ResourceLoader.exists(logo_path):
		return load(logo_path) as Texture2D

	return null


func create_panel_style(player_index: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var tint := Color(0.15, 0.20, 0.24, 0.86) if player_index == 0 else Color(0.24, 0.16, 0.20, 0.86)
	style.bg_color = tint
	style.border_color = Color(0.96, 0.78, 0.42, 0.72)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func create_logo_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.035, 0.72)
	style.border_color = Color(1.0, 0.84, 0.42, 0.55)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func create_select_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.075, 0.055, 0.92) if not is_hovered else Color(0.15, 0.12, 0.08, 0.98)
	style.border_color = Color(0.85, 0.65, 0.32, 0.82)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func create_start_button_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.72, 0.30, 1.0) if not is_hovered else Color(1.0, 0.82, 0.42, 1.0)
	style.border_color = Color(1.0, 0.92, 0.66, 1.0)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 10
	return style


func create_start_button_disabled_style() -> StyleBoxFlat:
	var style := create_start_button_style(false)
	style.bg_color = Color(0.24, 0.22, 0.20, 0.92)
	style.border_color = Color(0.42, 0.37, 0.31, 0.75)
	style.shadow_size = 0
	return style
