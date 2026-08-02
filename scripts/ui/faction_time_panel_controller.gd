extends RefCounted
class_name FactionTimePanelController

const CardTexturePreviewControllerScript := preload("res://scripts/ui/card_texture_preview_controller.gd")
const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

const CARD_PREVIEW_SIZE := Vector2(48.0, 66.0)

var panel: PanelContainer
var state_box: VBoxContainer
var card_preview_controller := CardTexturePreviewControllerScript.new()


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "FactionTimePanel"
	panel.custom_minimum_size = Vector2(RightSideHudStyleScript.PANEL_WIDTH, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.z_index = 2080
	panel.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_panel_style(RightSideHudStyleScript.ACCENT_TIME)
	)
	root.add_child.call_deferred(panel)
	card_preview_controller.setup(root)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_bottom", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", RightSideHudStyleScript.CONTENT_GAP)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(content)
	content.add_child(
		RightSideHudStyleScript.create_header(
			"种族状态",
			"time",
			RightSideHudStyleScript.ACCENT_TIME
		)
	)

	state_box = VBoxContainer.new()
	state_box.name = "StateBox"
	state_box.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(state_box)
	panel.hide()


func update(current_player: PlayerState, card_database: CardDatabase, _root: Control = null) -> void:
	if panel == null or state_box == null:
		return

	clear_state()
	var has_current_state := current_player != null and current_player.has_faction_runtime_state()
	panel.visible = has_current_state
	if not has_current_state:
		return

	state_box.add_child(create_player_state_row(current_player, card_database))


func clear_state() -> void:
	card_preview_controller.hide_preview()
	for child in state_box.get_children():
		state_box.remove_child(child)
		child.queue_free()


func create_player_state_row(player: PlayerState, card_database: CardDatabase) -> Control:
	var item := PanelContainer.new()
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(
			RightSideHudStyleScript.ACCENT_TIME,
			0.24
		)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_child(row)

	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.custom_minimum_size = CARD_PREVIEW_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
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
		card_preview_controller.bind_card(frame, card_data)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var title_text := player.get_faction_runtime_state_title()
	if title_text == "":
		title_text = "状态"

	var title_label := Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", RightSideHudStyleScript.SECONDARY_TEXT)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(title_label)

	var state_label := Label.new()
	state_label.text = player.faction_runtime_state_name
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.add_theme_font_size_override("font_size", 18)
	state_label.add_theme_color_override("font_color", RightSideHudStyleScript.ACCENT_TIME)
	state_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	state_label.add_theme_constant_override("shadow_offset_x", 1)
	state_label.add_theme_constant_override("shadow_offset_y", 1)
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(state_label)

	var hint_label := Label.new()
	hint_label.text = str(player.faction_runtime_state_config.get("panel_hint", "回合结束后推进"))
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hint_label.tooltip_text = hint_label.text
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", RightSideHudStyleScript.MUTED_TEXT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_PASS
	info.add_child(hint_label)
	return item


func create_card_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.055, 0.06, 0.96)
	style.border_color = Color(
		RightSideHudStyleScript.ACCENT_TIME.r,
		RightSideHudStyleScript.ACCENT_TIME.g,
		RightSideHudStyleScript.ACCENT_TIME.b,
		0.58
	)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style
