extends RefCounted
class_name EquipmentDisplayController

# Displays the current player's equipment. Equipment rules stay in PlayerState
# and the equipment resolvers; geometry stays in RightSideHudLayoutController.

const CardTexturePreviewControllerScript := preload("res://scripts/ui/card_texture_preview_controller.gd")
const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

const CARD_SIZE := Vector2(48.0, 66.0)

var panel: PanelContainer
var card_box: VBoxContainer
var card_preview_controller := CardTexturePreviewControllerScript.new()


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "EquipmentDisplayPanel"
	panel.custom_minimum_size = Vector2(RightSideHudStyleScript.PANEL_WIDTH, 0.0)
	panel.z_index = 2070
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_panel_style(RightSideHudStyleScript.ACCENT_EQUIPMENT)
	)
	root.add_child.call_deferred(panel)
	card_preview_controller.setup(root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_bottom", RightSideHudStyleScript.CONTENT_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", RightSideHudStyleScript.CONTENT_GAP)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(content)
	content.add_child(
		RightSideHudStyleScript.create_header(
			"装备",
			"equipment",
			RightSideHudStyleScript.ACCENT_EQUIPMENT
		)
	)

	card_box = VBoxContainer.new()
	card_box.name = "EquipmentList"
	card_box.add_theme_constant_override("separation", 6)
	card_box.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(card_box)


func update(player: PlayerState) -> void:
	if panel == null:
		return

	clear_cards()
	if player == null:
		add_empty_view()
		return

	var equipped_cards := player.get_equipped_cards()
	if equipped_cards.is_empty():
		add_empty_view()
		return

	for card_data in equipped_cards:
		card_box.add_child(create_equipment_view(card_data))


func clear_cards() -> void:
	if card_box == null:
		return

	card_preview_controller.hide_preview()
	for child in card_box.get_children():
		card_box.remove_child(child)
		child.queue_free()


func add_empty_view() -> void:
	var empty := PanelContainer.new()
	empty.custom_minimum_size = Vector2(0.0, 38.0)
	empty.mouse_filter = Control.MOUSE_FILTER_PASS
	empty.tooltip_text = "当前玩家没有装备"
	empty.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(
			RightSideHudStyleScript.ACCENT_EQUIPMENT,
			0.14
		)
	)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty.add_child(row)
	var icon := RightSideHudStyleScript.create_icon(
		"equipment",
		Color(
			RightSideHudStyleScript.ACCENT_EQUIPMENT.r,
			RightSideHudStyleScript.ACCENT_EQUIPMENT.g,
			RightSideHudStyleScript.ACCENT_EQUIPMENT.b,
			0.42
		),
		Vector2(20.0, 20.0),
		"当前玩家没有装备"
	)
	icon.modulate = Color(1.0, 1.0, 1.0, 0.62)
	row.add_child(icon)

	var label := Label.new()
	label.text = "未装备"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", RightSideHudStyleScript.MUTED_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	card_box.add_child(empty)


func create_equipment_view(card_data: CardData) -> Control:
	var item := PanelContainer.new()
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(
			RightSideHudStyleScript.ACCENT_EQUIPMENT,
			0.24
		)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_child(row)

	var type_id := card_data.equipment_type
	var type_name := get_equipment_type_name(type_id)
	row.add_child(
		RightSideHudStyleScript.create_icon(
			get_equipment_symbol(type_id),
			RightSideHudStyleScript.ACCENT_EQUIPMENT,
			Vector2(22.0, 22.0),
			type_name
		)
	)

	var card_frame := PanelContainer.new()
	card_frame.name = "CardFrame"
	card_frame.custom_minimum_size = CARD_SIZE
	card_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	card_frame.tooltip_text = "%s：%s" % [type_name, card_data.display_name]
	card_frame.add_theme_stylebox_override("panel", create_card_style())
	card_preview_controller.bind_card(card_frame, card_data)
	row.add_child(card_frame)

	var texture := TextureRect.new()
	texture.custom_minimum_size = CARD_SIZE
	texture.texture = card_data.front_texture
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_child(texture)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = card_data.display_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var type_label := Label.new()
	type_label.text = type_name
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", RightSideHudStyleScript.SECONDARY_TEXT)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(type_label)
	return item


func get_equipment_symbol(equipment_type: String) -> String:
	return "suit" if equipment_type == "suit" else "weapon"


func get_equipment_type_name(equipment_type: String) -> String:
	match equipment_type:
		"weapon":
			return "武器"
		"suit":
			return "套装"
		_:
			return "装备"


func create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.02, 0.84)
	style.border_color = Color(
		RightSideHudStyleScript.ACCENT_EQUIPMENT.r,
		RightSideHudStyleScript.ACCENT_EQUIPMENT.g,
		RightSideHudStyleScript.ACCENT_EQUIPMENT.b,
		0.56
	)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style
