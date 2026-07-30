extends RefCounted
class_name CardMultiSelectController

# 通用卡牌多选面板。不绑定任何特定区域或卡牌语义。
# 调用方传入 title、待选卡牌列表和最大可选数量，
# 面板负责展示和交互，通过 signal 返回选中索引。

const THUMB_WIDTH := 72
const THUMB_HEIGHT := 100
const PANEL_WIDTH := 640

signal selection_completed(selected_indices: Array[int])

var _layer: CanvasLayer
var _panel: PanelContainer
var _title_label: Label
var _count_label: Label
var _checkboxes: Array[CheckBox] = []
var _confirm_button: Button
var _selected_set: Array[int] = []
var _max_select: int = 0
var _cards: Array[Dictionary] = []


func setup(root: Node) -> void:
	if _panel != null:
		return
	if root == null:
		return

	_layer = CanvasLayer.new()
	_layer.name = "CardMultiSelectLayer"
	_layer.layer = 181
	root.add_child(_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.0, 0.0, 0.0, 0.5)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(backdrop)

	_panel = PanelContainer.new()
	_panel.name = "CardMultiSelectPanel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 520)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_title_label)

	_count_label = Label.new()
	_count_label.name = "CountLabel"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	box.add_child(_count_label)

	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	box.add_child(scroll)

	var check_container := VBoxContainer.new()
	check_container.name = "CheckContainer"
	check_container.add_theme_constant_override("separation", 8)
	scroll.add_child(check_container)

	var button_box := HBoxContainer.new()
	button_box.name = "ButtonBox"
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 16)
	box.add_child(button_box)

	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmButton"
	_confirm_button.text = "确认"
	_confirm_button.disabled = true
	ApplicationUiStyle.style_inline_button(
		_confirm_button,
		ApplicationUiStyle.GOLD,
		true
	)
	_confirm_button.custom_minimum_size.x = 120.0
	_confirm_button.pressed.connect(_on_confirm)
	button_box.add_child(_confirm_button)


func show_panel(root: Node, title: String, cards: Array[Dictionary], max_select: int) -> Array[int]:
	setup(root)
	if _panel == null:
		var empty_result: Array[int] = []
		return empty_result

	_cards = cards
	_max_select = max_select
	_selected_set.clear()

	_title_label.text = title
	_refresh_count_label()

	_clear_checkboxes()
	for i in range(cards.size()):
		_add_check_row(i, cards[i])

	_panel.position = _get_centered_position(root, _panel.custom_minimum_size)
	_panel.show()
	_layer.show()

	var result: Array[int] = await _await_selection()

	_panel.hide()
	_layer.hide()
	return result


func _add_check_row(index: int, card_data: Dictionary) -> void:
	var scroll := _panel.get_node_or_null("MarginContainer/VBoxContainer/CardScroll") as ScrollContainer
	if scroll == null:
		return

	var check_container := scroll.get_node_or_null("CheckContainer") as VBoxContainer
	if check_container == null:
		return

	var row := HBoxContainer.new()
	row.name = "Row_%d" % index
	row.add_theme_constant_override("separation", 10)

	var check := CheckBox.new()
	check.name = "Check"
	check.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	check.add_theme_font_size_override("font_size", 14)
	check.add_theme_stylebox_override("normal", _create_checkbox_normal_style())
	check.add_theme_stylebox_override("hover", _create_checkbox_hover_style())
	check.toggled.connect(func(checked: bool): _on_check_toggled(index, checked))
	row.add_child(check)
	_checkboxes.append(check)

	var texture_path := str(card_data.get("front_texture_path", ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var thumb := TextureRect.new()
		thumb.name = "Thumbnail"
		thumb.custom_minimum_size = Vector2(THUMB_WIDTH, THUMB_HEIGHT)
		thumb.texture = ResourceLoader.load(texture_path) as Texture2D
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(thumb)

	var display_name := str(card_data.get("name", "???"))
	var attack := int(card_data.get("attack", 0))
	var health := int(card_data.get("health", 0))

	var info_box := VBoxContainer.new()
	info_box.name = "InfoBox"
	info_box.add_theme_constant_override("separation", 4)
	info_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var name_label := Label.new()
	name_label.text = display_name
	name_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	name_label.add_theme_font_size_override("font_size", 15)
	info_box.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = "攻击 %d    生命 %d" % [attack, health]
	stats_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	stats_label.add_theme_font_size_override("font_size", 13)
	info_box.add_child(stats_label)

	row.add_child(info_box)
	check_container.add_child(row)


func _clear_checkboxes() -> void:
	_checkboxes.clear()
	var scroll := _panel.get_node_or_null("MarginContainer/VBoxContainer/CardScroll") as ScrollContainer
	if scroll == null:
		return

	var check_container := scroll.get_node_or_null("CheckContainer") as VBoxContainer
	if check_container == null:
		return

	for child in check_container.get_children():
		child.queue_free()


func _on_check_toggled(index: int, checked: bool) -> void:
	if checked:
		if _selected_set.has(index):
			return
		_selected_set.append(index)
	else:
		_selected_set.erase(index)

	_refresh_count_label()
	_update_check_states()


func _update_check_states() -> void:
	var at_limit := _selected_set.size() >= _max_select
	for i in range(_checkboxes.size()):
		if not _selected_set.has(i):
			_checkboxes[i].disabled = at_limit

	_confirm_button.disabled = _selected_set.is_empty()


func _refresh_count_label() -> void:
	_count_label.text = "已选 %d / 最多 %d" % [_selected_set.size(), _max_select]


func _on_confirm() -> void:
	selection_completed.emit(_selected_set.duplicate())


func _await_selection() -> Array[int]:
	var result: Array[int] = await selection_completed
	return result


func _get_centered_position(root: Node, size: Vector2) -> Vector2:
	var viewport := root.get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	return (viewport_size - size) * 0.5


func _create_checkbox_normal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.16, 0.12, 0.95)
	style.border_color = Color(0.55, 0.50, 0.40)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _create_checkbox_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.22, 0.16, 0.95)
	style.border_color = Color(0.85, 0.72, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _create_panel_style() -> StyleBox:
	return ApplicationUiStyle.create_drawer_panel_style(ApplicationUiStyle.GOLD)
