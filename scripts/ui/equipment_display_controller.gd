extends RefCounted
class_name EquipmentDisplayController

# 右侧装备展示区。只展示当前回合玩家的已装备卡牌，不参与装备规则。

const CardTexturePreviewControllerScript := preload("res://scripts/ui/card_texture_preview_controller.gd")

const PANEL_SIZE := Vector2(220, 320)
const CARD_SIZE := Vector2(96, 134)
const RIGHT_MARGIN := 24.0
const TOP_MARGIN := 236.0

var panel: PanelContainer
var owner_label: Label
var card_box: VBoxContainer
var card_preview_controller := CardTexturePreviewControllerScript.new()


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "EquipmentDisplayPanel"
	panel.custom_minimum_size = PANEL_SIZE
	panel.z_index = 120
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", create_panel_style())
	root.add_child.call_deferred(panel)
	card_preview_controller.setup(root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = "装备"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1.0))
	content.add_child(title)

	owner_label = Label.new()
	owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner_label.add_theme_font_size_override("font_size", 13)
	owner_label.add_theme_color_override("font_color", Color(0.76, 0.86, 1.0, 0.92))
	content.add_child(owner_label)

	card_box = VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	card_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(card_box)

	panel.ready.connect(position_panel, CONNECT_ONE_SHOT)


func update(player: PlayerState) -> void:
	if panel == null:
		return

	position_panel()
	clear_cards()

	if player == null:
		owner_label.text = ""
		add_empty_label()
		return

	owner_label.text = player.display_name
	var equipped_cards := player.get_equipped_cards()
	if equipped_cards.is_empty():
		add_empty_label()
		return

	for card_data in equipped_cards:
		card_box.add_child(create_equipment_view(card_data))


func position_panel() -> void:
	if panel == null:
		return

	var viewport := panel.get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	panel.position = Vector2(
		maxf(viewport_size.x - PANEL_SIZE.x - RIGHT_MARGIN, RIGHT_MARGIN),
		TOP_MARGIN
	)
	panel.size = PANEL_SIZE


func clear_cards() -> void:
	if card_box == null:
		return

	card_preview_controller.hide_preview()
	for child in card_box.get_children():
		child.queue_free()


func add_empty_label() -> void:
	var label := Label.new()
	label.text = "暂无装备"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.74, 0.56))
	card_box.add_child(label)


func create_equipment_view(card_data: CardData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", create_card_style())
	card_preview_controller.bind_card(card, card_data)
	row.add_child(card)

	var texture := TextureRect.new()
	texture.custom_minimum_size = CARD_SIZE
	texture.texture = card_data.front_texture
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)

	var type_label := Label.new()
	type_label.text = card_data.equipment_type if card_data.equipment_type != "" else "equipment"
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58, 0.92))
	info.add_child(type_label)

	var name_label := Label.new()
	name_label.text = card_data.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	info.add_child(name_label)

	return row

func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.035, 0.90)
	style.border_color = Color(0.86, 0.62, 0.30, 0.76)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 14
	return style


func create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(1.0, 0.78, 0.32, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(1.0, 0.72, 0.24, 0.20)
	style.shadow_size = 12
	return style
