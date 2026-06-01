extends RefCounted
class_name HandDrawerController

signal hand_card_clicked(card_entry: Variant, source_control: Control, hand_index: int)

# HandDrawerController 只负责左侧手牌抽屉的表现。
# 手牌内容来自当前 PlayerState，真正的使用、放置、冷却等规则后续交给规则层。

const DRAWER_OPEN_X := 18.0
const DRAWER_TWEEN_DURATION := 0.18
const CARD_TYPE_SPELL := "spell"
const CARD_TYPE_MINION := "minion"
const CARD_TYPE_UPGRADE := "upgrade"
const CARD_TYPE_EQUIPMENT := "equipment"
const DEFAULT_DRAWER_WIDTH := 720.0
const DRAWER_VERTICAL_MARGIN := 18.0
const MIN_DRAWER_HEIGHT := 520.0
const DRAWER_BODY_PADDING := 10.0
const TOGGLE_WIDTH := 48.0
const TOGGLE_HEIGHT := 132.0
const HAND_CARD_SIZE := Vector2(180, 252)
const HAND_CARD_GLOW_PADDING := 8
const HAND_CARD_FLIGHT_DURATION := 0.34
const PREVIEW_SIZE := Vector2(360, 504)
const PREVIEW_GAP := 16.0

var panel: Panel
var drawer_body: Control
var toggle_button: Button
var title_label: Label
var owner_label: Label
var section_lists: Dictionary = {}
var is_open := true
var drawer_tween: Tween
var preview_rect: TextureRect
var selected_hand_index := -1
var playable_hand_indices: Array[int] = []
var card_controls: Dictionary = {}
var section_scroll_offsets: Dictionary = {}


func setup(root: Node, panel_path: NodePath) -> void:
	if root == null:
		return

	panel = root.get_node_or_null(panel_path) as Panel
	if panel == null:
		return

	drawer_body = panel.get_node_or_null("DrawerBody") as Control
	toggle_button = panel.get_node_or_null("ToggleButton") as Button
	title_label = panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Header/TitleLabel") as Label
	owner_label = panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Header/OwnerLabel") as Label
	section_lists = {
		CARD_TYPE_SPELL: panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Sections/SpellSection/VBoxContainer/CardList"),
		CARD_TYPE_MINION: panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Sections/MinionSection/VBoxContainer/CardList"),
		CARD_TYPE_UPGRADE: panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Sections/UpgradeSection/VBoxContainer/CardList"),
		CARD_TYPE_EQUIPMENT: panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Sections/EquipmentSection/VBoxContainer/CardList")
	}

	panel.z_index = 2600
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	configure_responsive_layout()
	apply_drawer_position(DRAWER_OPEN_X)
	panel.add_theme_stylebox_override("panel", create_panel_style())
	panel.move_to_front.call_deferred()

	if drawer_body != null:
		drawer_body.mouse_filter = Control.MOUSE_FILTER_PASS

	if toggle_button != null:
		toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
		toggle_button.disabled = false
		toggle_button.text = get_toggle_text()
		toggle_button.move_to_front.call_deferred()
		if not toggle_button.pressed.is_connected(Callable(self, "toggle")):
			toggle_button.pressed.connect(Callable(self, "toggle"))
		toggle_button.add_theme_stylebox_override("normal", create_toggle_style(false))
		toggle_button.add_theme_stylebox_override("hover", create_toggle_style(true))
		toggle_button.add_theme_stylebox_override("pressed", create_toggle_style(true))
		toggle_button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.66, 1.0))
		toggle_button.add_theme_font_size_override("font_size", 15)

	if title_label != null:
		title_label.text = "手牌"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1.0))
		title_label.add_theme_font_size_override("font_size", 24)

	if owner_label != null:
		owner_label.add_theme_color_override("font_color", Color(0.74, 0.86, 1.0, 0.94))
		owner_label.add_theme_font_size_override("font_size", 15)

	style_existing_labels(panel)
	style_sections()
	style_card_lists()
	connect_viewport_resize()
	update(null)


func update(
	current_player: PlayerState,
	new_selected_hand_index := -1,
	new_playable_hand_indices: Array[int] = []
) -> void:
	if panel == null:
		return

	capture_section_scroll_offsets()
	selected_hand_index = new_selected_hand_index
	playable_hand_indices = new_playable_hand_indices
	card_controls.clear()
	panel.visible = true
	if owner_label != null:
		if current_player == null:
			owner_label.text = "无当前玩家"
		else:
			owner_label.text = "%s  ·  %s" % [
				current_player.display_name,
				current_player.faction_name if current_player.faction_name != "" else current_player.faction_id
			]

	var cards_by_type := create_empty_card_groups()
	if current_player != null:
		for hand_index in range(current_player.hand.size()):
			var card_entry = current_player.hand[hand_index]
			var card_type := get_hand_card_type(card_entry)
			if not cards_by_type.has(card_type):
				card_type = CARD_TYPE_SPELL
			cards_by_type[card_type].append(create_hand_view_entry(card_entry, hand_index))

	for card_type in cards_by_type.keys():
		render_section(card_type, cards_by_type[card_type])


func update_selection_state(new_selected_hand_index := -1, new_playable_hand_indices: Array[int] = []) -> void:
	selected_hand_index = new_selected_hand_index
	playable_hand_indices = new_playable_hand_indices

	for hand_index in card_controls.keys():
		var card := card_controls.get(hand_index) as PanelContainer
		if card == null or not is_instance_valid(card):
			continue

		card.add_theme_stylebox_override("panel", create_hand_card_style({
			"_hand_index": int(hand_index)
		}))


func toggle() -> void:
	set_open(not is_open)


func set_open(value: bool) -> void:
	if panel == null:
		return

	is_open = value
	if toggle_button != null:
		toggle_button.text = get_toggle_text()

	var target_left := DRAWER_OPEN_X if is_open else get_closed_x()
	if drawer_tween != null and drawer_tween.is_valid():
		drawer_tween.kill()

	drawer_tween = panel.create_tween()
	drawer_tween.set_trans(Tween.TRANS_CUBIC)
	drawer_tween.set_ease(Tween.EASE_OUT)
	drawer_tween.tween_method(apply_drawer_position, panel.offset_left, target_left, DRAWER_TWEEN_DURATION)


func apply_drawer_position(left: float) -> void:
	if panel == null:
		return

	var drawer_height := get_drawer_height()
	panel.offset_left = left
	panel.offset_right = left + get_drawer_width()
	panel.offset_top = DRAWER_VERTICAL_MARGIN
	panel.offset_bottom = DRAWER_VERTICAL_MARGIN + drawer_height
	panel.custom_minimum_size = Vector2(get_drawer_width(), drawer_height)

	if drawer_body != null:
		drawer_body.offset_left = DRAWER_BODY_PADDING
		drawer_body.offset_top = DRAWER_BODY_PADDING
		drawer_body.offset_right = get_drawer_width() - TOGGLE_WIDTH + 4.0
		drawer_body.offset_bottom = drawer_height - DRAWER_BODY_PADDING

	if toggle_button != null:
		toggle_button.custom_minimum_size = Vector2(TOGGLE_WIDTH, TOGGLE_HEIGHT)
		toggle_button.offset_left = get_drawer_width() - TOGGLE_WIDTH
		toggle_button.offset_right = get_drawer_width()
		toggle_button.offset_top = (drawer_height - TOGGLE_HEIGHT) * 0.5
		toggle_button.offset_bottom = toggle_button.offset_top + TOGGLE_HEIGHT


func configure_responsive_layout() -> void:
	if panel == null:
		return

	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_vertical = Control.GROW_DIRECTION_END


func get_drawer_width() -> float:
	if panel == null:
		return DEFAULT_DRAWER_WIDTH

	return maxf(panel.custom_minimum_size.x, DEFAULT_DRAWER_WIDTH)


func get_drawer_height() -> float:
	if panel == null:
		return MIN_DRAWER_HEIGHT

	var viewport_size := get_viewport_size()
	if viewport_size == Vector2.ZERO:
		return maxf(panel.custom_minimum_size.y, MIN_DRAWER_HEIGHT)

	return maxf(viewport_size.y - DRAWER_VERTICAL_MARGIN * 2.0, MIN_DRAWER_HEIGHT)


func get_closed_x() -> float:
	if toggle_button == null:
		return -(get_drawer_width() - 48.0)

	return -toggle_button.offset_left


func get_toggle_text() -> String:
	return "收起" if is_open else "手牌"


func create_empty_card_groups() -> Dictionary:
	return {
		CARD_TYPE_SPELL: [],
		CARD_TYPE_MINION: [],
		CARD_TYPE_UPGRADE: [],
		CARD_TYPE_EQUIPMENT: []
	}


func create_hand_view_entry(card_entry: Variant, hand_index: int) -> Dictionary:
	return {
		"_hand_entry": card_entry,
		"_hand_index": hand_index
	}


func render_section(card_type: String, cards: Array) -> void:
	var card_list := section_lists.get(card_type) as VBoxContainer
	if card_list == null:
		return

	for child in card_list.get_children():
		child.queue_free()

	if cards.is_empty():
		card_list.add_child(create_empty_label())
		return

	var scroll := ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	card_list.add_child(scroll)

	var glow_margin := MarginContainer.new()
	glow_margin.name = "GlowPadding"
	glow_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glow_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	glow_margin.add_theme_constant_override("margin_left", HAND_CARD_GLOW_PADDING)
	glow_margin.add_theme_constant_override("margin_top", HAND_CARD_GLOW_PADDING)
	glow_margin.add_theme_constant_override("margin_right", HAND_CARD_GLOW_PADDING)
	glow_margin.add_theme_constant_override("margin_bottom", HAND_CARD_GLOW_PADDING)
	scroll.add_child(glow_margin)

	var flow := HFlowContainer.new()
	flow.name = "CardFlow"
	flow.custom_minimum_size.x = get_card_flow_width()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	glow_margin.add_child(flow)

	for card_entry in cards:
		flow.add_child(create_hand_card_view(card_entry))

	restore_section_scroll_offset.call_deferred(card_type)


func capture_section_scroll_offsets() -> void:
	for card_type in section_lists.keys():
		var scroll := get_section_scroll_container(card_type)
		if scroll == null:
			continue

		section_scroll_offsets[card_type] = Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)


func get_section_scroll_container(card_type: String) -> ScrollContainer:
	var card_list := section_lists.get(card_type) as Control
	if card_list == null:
		return null

	return card_list.get_node_or_null("CardScroll") as ScrollContainer


func restore_section_scroll_offset(card_type: String) -> void:
	var scroll := get_section_scroll_container(card_type)
	if scroll == null or not is_instance_valid(scroll):
		return

	var offset := section_scroll_offsets.get(card_type, Vector2i.ZERO) as Vector2i
	scroll.scroll_horizontal = offset.x
	scroll.scroll_vertical = offset.y


func create_empty_label() -> Label:
	var label := Label.new()
	label.text = "暂无"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.74, 0.56))
	label.add_theme_font_size_override("font_size", 13)
	return label


func get_card_flow_width() -> float:
	var content_padding := float(HAND_CARD_GLOW_PADDING * 2)
	return maxf(get_drawer_width() - TOGGLE_WIDTH - 56.0 - content_padding, HAND_CARD_SIZE.x)


func create_hand_card_view(card_entry: Variant) -> PanelContainer:
	var card := PanelContainer.new()
	var hand_index := get_hand_index_from_entry(card_entry)
	card_controls[hand_index] = card
	card.custom_minimum_size = HAND_CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.tooltip_text = get_hand_card_display_name(card_entry)
	card.add_theme_stylebox_override("panel", create_hand_card_style(card_entry))
	card.mouse_entered.connect(func(): show_hand_card_preview(card_entry, card))
	card.mouse_exited.connect(hide_hand_card_preview)
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				hide_hand_card_preview()
				hand_card_clicked.emit(get_raw_hand_entry(card_entry), card, hand_index)
				card.accept_event()
	)

	var texture := TextureRect.new()
	texture.custom_minimum_size = HAND_CARD_SIZE
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.texture = get_hand_card_texture(card_entry)
	card.add_child(texture)
	add_cooldown_badge(texture, card_entry)

	return card


func get_hand_card_type(card_entry: Variant) -> String:
	var card_data := get_card_data_from_entry(card_entry)
	if card_data != null:
		if card_data.is_minion():
			return CARD_TYPE_MINION
		if card_data.is_upgrade():
			return CARD_TYPE_UPGRADE
		if card_data.is_spell():
			return CARD_TYPE_SPELL
		if card_data.is_equipment():
			return CARD_TYPE_EQUIPMENT
		return card_data.type

	if card_entry is Dictionary:
		return str(card_entry.get("type", card_entry.get("card_type", CARD_TYPE_SPELL)))

	return CARD_TYPE_SPELL


func get_hand_card_display_name(card_entry: Variant) -> String:
	var card_data := get_card_data_from_entry(card_entry)
	if card_data != null:
		return card_data.display_name

	if card_entry is Dictionary:
		return str(card_entry.get("display_name", card_entry.get("name", card_entry.get("card_id", "未知卡牌"))))

	return str(card_entry)


func get_hand_card_texture(card_entry: Variant) -> Texture2D:
	var card_data := get_card_data_from_entry(card_entry)
	if card_data != null:
		return card_data.front_texture

	return null


func get_hand_card_cooldown(card_entry: Variant) -> int:
	return HandCardState.get_cooldown_turns(get_raw_hand_entry(card_entry))


func add_cooldown_badge(card: Control, card_entry: Variant) -> void:
	var cooldown := get_hand_card_cooldown(card_entry)
	if cooldown <= 0:
		return

	var badge := PanelContainer.new()
	badge.name = "CooldownBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(58, 58)
	badge.size = Vector2(58, 58)
	badge.position = Vector2(HAND_CARD_SIZE.x - 66.0, 8.0)
	badge.add_theme_stylebox_override("panel", create_cooldown_badge_style())
	card.add_child(badge)

	var label := Label.new()
	label.name = "CooldownLabel"
	label.text = str(cooldown)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	badge.add_child(label)


func show_hand_card_preview(card_entry: Variant, source_control: Control) -> void:
	var texture := get_hand_card_texture(card_entry)
	if texture == null or source_control == null:
		return

	var scene := get_current_scene()
	if scene == null:
		return

	var display_size := get_preview_display_size(source_control)
	if preview_rect == null:
		preview_rect = TextureRect.new()
		preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_rect.z_index = 3400
		scene.add_child(preview_rect)

	preview_rect.texture = texture
	preview_rect.custom_minimum_size = display_size
	preview_rect.size = display_size
	preview_rect.global_position = get_preview_position(source_control, display_size)
	preview_rect.show()


func hide_hand_card_preview() -> void:
	if preview_rect == null:
		return

	preview_rect.queue_free()
	preview_rect = null


func get_preview_position(source_control: Control, display_size: Vector2) -> Vector2:
	var viewport_size := get_viewport_size()
	var board_rect := get_card_board_rect(source_control)
	var source_rect := source_control.get_global_rect()
	var target_position := Vector2(
		board_rect.position.x + board_rect.size.x + PREVIEW_GAP,
		source_rect.position.y
	)

	target_position.x = clampf(target_position.x, 0.0, maxf(viewport_size.x - display_size.x, 0.0))
	target_position.y = clampf(target_position.y, 0.0, maxf(viewport_size.y - display_size.y, 0.0))
	return target_position


func get_preview_display_size(source_control: Control) -> Vector2:
	var viewport_size := get_viewport_size()
	var board_rect := get_card_board_rect(source_control)
	var available_width := viewport_size.x - (board_rect.position.x + board_rect.size.x + PREVIEW_GAP)
	var available_height := viewport_size.y
	var scale_factor := minf(available_width / PREVIEW_SIZE.x, available_height / PREVIEW_SIZE.y)
	scale_factor = minf(scale_factor, 1.0)
	scale_factor = maxf(scale_factor, 0.25)
	return PREVIEW_SIZE * scale_factor


func get_card_board_rect(fallback_control: Control) -> Rect2:
	var scene := get_current_scene()
	if scene != null:
		var board := scene.get_node_or_null("BoardCenter/CardBoard") as Control
		if board != null:
			return board.get_global_rect()

	if fallback_control != null:
		return fallback_control.get_global_rect()

	return Rect2()


func get_current_scene() -> Node:
	if panel == null:
		return null

	var tree := panel.get_tree()
	if tree == null:
		return null

	return tree.current_scene


func get_viewport_size() -> Vector2:
	if panel == null:
		return Vector2.ZERO

	return panel.get_viewport().get_visible_rect().size


func play_card_to_hand_animation(owner: Node, animation_root: Control, source_card: Card, card_data: CardData) -> void:
	if owner == null or animation_root == null or source_card == null or card_data == null:
		return

	var card_texture := card_data.front_texture
	if card_texture == null:
		return

	var source_rect := source_card.get_global_rect()
	var target_rect := get_hand_animation_target_rect(card_data)
	var flying_card := TextureRect.new()
	flying_card.name = "HandCardFlight"
	flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_card.texture = card_texture
	flying_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_card.stretch_mode = TextureRect.STRETCH_SCALE
	flying_card.size = source_rect.size
	flying_card.pivot_offset = flying_card.size * 0.5
	flying_card.z_index = 3200
	animation_root.add_child(flying_card)
	flying_card.global_position = source_rect.position

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flying_card, "global_position", target_rect.position, HAND_CARD_FLIGHT_DURATION)
	tween.tween_property(flying_card, "size", target_rect.size, HAND_CARD_FLIGHT_DURATION)
	tween.tween_property(flying_card, "rotation", -0.08, HAND_CARD_FLIGHT_DURATION * 0.55)
	await tween.finished

	var settle_tween := owner.create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_BACK)
	settle_tween.set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(flying_card, "rotation", 0.0, 0.10)
	settle_tween.tween_property(flying_card, "scale", Vector2(1.03, 1.03), 0.05)
	settle_tween.chain().tween_property(flying_card, "scale", Vector2.ONE, 0.05)
	await settle_tween.finished

	flying_card.queue_free()


func get_hand_animation_target_rect(card_data: CardData) -> Rect2:
	if toggle_button != null and not is_open:
		var toggle_rect := toggle_button.get_global_rect()
		return Rect2(toggle_rect.get_center() - HAND_CARD_SIZE * 0.5, HAND_CARD_SIZE)

	var card_type := get_hand_card_type(card_data)
	var card_list := section_lists.get(card_type) as Control
	if card_list != null:
		return Rect2(card_list.get_global_rect().position, HAND_CARD_SIZE)

	if panel != null:
		var panel_rect := panel.get_global_rect()
		return Rect2(panel_rect.position + Vector2(24.0, 96.0), HAND_CARD_SIZE)

	return Rect2(Vector2.ZERO, HAND_CARD_SIZE)


func get_card_data_from_entry(card_entry: Variant) -> CardData:
	card_entry = get_raw_hand_entry(card_entry)

	var hand_card_data := HandCardState.get_card_data(card_entry)
	if hand_card_data != null:
		return hand_card_data

	if card_entry is CardState:
		var state := card_entry as CardState
		return state.data

	if card_entry is Dictionary:
		var data = card_entry.get("data")
		if data is CardData:
			return data as CardData

	return null


func get_raw_hand_entry(card_entry: Variant) -> Variant:
	if card_entry is Dictionary and card_entry.has("_hand_entry"):
		return card_entry.get("_hand_entry")

	return card_entry


func get_hand_index_from_entry(card_entry: Variant) -> int:
	if card_entry is Dictionary and card_entry.has("_hand_index"):
		return int(card_entry.get("_hand_index", -1))

	return -1


func get_hand_card_control(hand_index: int) -> Control:
	if hand_index < 0:
		return null

	return card_controls.get(hand_index) as Control


func style_existing_labels(root: Node) -> void:
	if root is Label:
		var label := root as Label
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	for child in root.get_children():
		style_existing_labels(child)


func style_sections() -> void:
	if panel == null:
		return

	for section_name in ["SpellSection", "MinionSection", "UpgradeSection", "EquipmentSection"]:
		var section := panel.get_node_or_null("DrawerBody/MarginContainer/VBoxContainer/Sections/%s" % section_name) as PanelContainer
		if section == null:
			continue
		section.add_theme_stylebox_override("panel", create_section_style())


func style_card_lists() -> void:
	for card_list in section_lists.values():
		var list := card_list as Control
		if list == null:
			continue

		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.size_flags_vertical = Control.SIZE_EXPAND_FILL


func connect_viewport_resize() -> void:
	if panel == null:
		return

	var viewport := panel.get_viewport()
	if viewport == null:
		return

	if not viewport.size_changed.is_connected(refresh_drawer_layout):
		viewport.size_changed.connect(refresh_drawer_layout)


func refresh_drawer_layout() -> void:
	if panel == null:
		return

	apply_drawer_position(panel.offset_left)


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.035, 0.94)
	style.border_color = Color(0.86, 0.62, 0.30, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 20
	style.shadow_offset = Vector2(4, 6)
	return style


func create_section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.085, 0.058, 0.74)
	style.border_color = Color(0.72, 0.50, 0.24, 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func create_cooldown_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.14, 0.24, 0.92)
	style.border_color = Color(0.55, 0.88, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(29)
	style.shadow_color = Color(0.20, 0.72, 1.0, 0.48)
	style.shadow_size = 14
	return style


func create_hand_card_style(card_entry: Variant = null) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_corner_radius_all(3)

	var hand_index := get_hand_index_from_entry(card_entry)
	if hand_index >= 0 and hand_index == selected_hand_index:
		style.border_color = Color(1.0, 0.82, 0.22, 0.92)
		style.set_border_width_all(2)
		style.shadow_color = Color(1.0, 0.72, 0.20, 0.42)
		style.shadow_size = 24
	elif hand_index >= 0 and playable_hand_indices.has(hand_index):
		style.border_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_border_width_all(0)
		style.shadow_color = Color(0.24, 1.0, 0.48, 0.34)
		style.shadow_size = 20
	else:
		style.border_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_border_width_all(0)

	return style


func create_toggle_style(is_hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.045, 0.96) if not is_hover else Color(0.18, 0.12, 0.065, 0.98)
	style.border_color = Color(1.0, 0.74, 0.34, 0.84)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(1.0, 0.72, 0.28, 0.18)
	style.shadow_size = 8 if is_hover else 4
	return style
