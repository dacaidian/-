extends RefCounted
class_name FactionTimePanelController

const PANEL_WIDTH := 248.0
const PANEL_MARGIN := 12.0
const PANEL_TOP_LIMIT := 112.0
const CARD_PREVIEW_SIZE := Vector2(54, 78)
const MIN_SCROLL_HEIGHT := 92.0
const MAX_SCROLL_HEIGHT := 230.0

var panel: PanelContainer
var list_scroll: ScrollContainer
var list: VBoxContainer


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "FactionTimePanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 2100
	panel.add_theme_stylebox_override("panel", create_panel_style())
	root.add_child.call_deferred(panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "种族状态"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	list_scroll = ScrollContainer.new()
	list_scroll.name = "StateScroll"
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	list_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(list_scroll)

	list = VBoxContainer.new()
	list.name = "StateList"
	list.add_theme_constant_override("separation", 7)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_scroll.add_child(list)

	position_panel(root)
	panel.hide()


func update(players: Array[PlayerState], card_database: CardDatabase, root: Control = null) -> void:
	if panel == null or list == null:
		return

	for child in list.get_children():
		child.queue_free()

	var has_any_state := false
	for player in players:
		if player == null or not player.has_faction_runtime_state():
			continue

		has_any_state = true
		list.add_child(create_player_state_row(player, card_database))

	panel.visible = has_any_state
	if root != null:
		call_deferred("position_panel", root)


func position_panel(root: Control) -> void:
	if panel == null or root == null:
		return

	var viewport := root.get_viewport()
	if viewport == null:
		return

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var available_height := maxf(MIN_SCROLL_HEIGHT, viewport_size.y - PANEL_TOP_LIMIT - PANEL_MARGIN * 2.0)
	list_scroll.custom_minimum_size = Vector2(PANEL_WIDTH - 20.0, minf(MAX_SCROLL_HEIGHT, available_height))

	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size = Vector2(PANEL_WIDTH, 0)

	var panel_size := panel.get_combined_minimum_size()
	var max_x := maxf(PANEL_MARGIN, viewport_size.x - panel_size.x - PANEL_MARGIN)
	var max_y := maxf(PANEL_MARGIN, viewport_size.y - panel_size.y - PANEL_MARGIN)
	panel.position = Vector2(
		clampf(viewport_size.x - panel_size.x - PANEL_MARGIN, PANEL_MARGIN, max_x),
		clampf(max_y, PANEL_MARGIN, max_y)
	)


func create_player_state_row(player: PlayerState, card_database: CardDatabase) -> Control:
	var row := HBoxContainer.new()
	row.name = "%sRuntimeStateRow" % player.id
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.custom_minimum_size = CARD_PREVIEW_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", create_card_frame_style())
	row.add_child(frame)

	var texture := TextureRect.new()
	texture.name = "StateTexture"
	texture.custom_minimum_size = CARD_PREVIEW_SIZE
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(texture)

	var card_data := card_database.get_card(player.faction_runtime_state_card_id)
	if card_data != null and card_data.front_texture != null:
		texture.texture = card_data.front_texture

	var info := VBoxContainer.new()
	info.name = "InfoBox"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 3)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var player_label := Label.new()
	player_label.text = player.display_name
	player_label.add_theme_font_size_override("font_size", 13)
	player_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80, 1.0))
	player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(player_label)

	var title_text := player.get_faction_runtime_state_title()
	if title_text == "":
		title_text = "状态"

	var state_label := Label.new()
	state_label.text = "%s：%s" % [title_text, player.faction_runtime_state_name]
	state_label.add_theme_font_size_override("font_size", 16)
	state_label.add_theme_color_override("font_color", Color(0.58, 0.90, 1.0, 1.0))
	state_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	state_label.add_theme_constant_override("shadow_offset_x", 1)
	state_label.add_theme_constant_override("shadow_offset_y", 1)
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(state_label)

	var hint_label := Label.new()
	hint_label.text = str(player.faction_runtime_state_config.get("panel_hint", "回合结束后推进"))
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.82, 0.88))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(hint_label)

	return row


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.060, 0.94)
	style.border_color = Color(0.48, 0.82, 0.95, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 6)
	return style


func create_card_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.075, 0.96)
	style.border_color = Color(0.86, 0.78, 0.48, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.28, 0.78, 1.0, 0.22)
	style.shadow_size = 8
	return style
