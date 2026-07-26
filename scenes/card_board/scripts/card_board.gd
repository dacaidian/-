@tool
extends PanelContainer

const CardScene := preload("res://scenes/card.tscn")
const GuTrapSlotOverlayScript := preload("res://scripts/ui/gu_trap_slot_overlay.gd")

@export var max_board_size := Vector2(980, 1340)
@export var viewport_margin := Vector2(40, 40)
@export var slot_aspect_ratio := 180.0 / 252.0
@export var board_columns := 7
@export var board_rows := 7

@onready var grid_container: GridContainer = $MarginContainer/GridContainer

var land_slot_states: Array[bool] = []


func _ready() -> void:
	ensure_board_slots()
	resize_to_viewport()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		resize_to_viewport()


func ensure_board_slots() -> void:
	if grid_container == null:
		return

	grid_container.columns = board_columns
	var desired_count := maxi(board_columns * board_rows, 0)

	while grid_container.get_child_count() < desired_count:
		var slot := PanelContainer.new()
		slot.name = "CardSlot%02d" % (grid_container.get_child_count() + 1)
		slot.add_theme_stylebox_override("panel", create_slot_style())
		grid_container.add_child(slot)

		var card := CardScene.instantiate()
		card.name = "Card"
		slot.add_child(card)

		var aerial_card := CardScene.instantiate()
		aerial_card.name = "AerialCard"
		aerial_card.allows_empty_clicks = false
		aerial_card.z_index = 20
		slot.add_child(aerial_card)

	while grid_container.get_child_count() > desired_count:
		var child := grid_container.get_child(grid_container.get_child_count() - 1)
		grid_container.remove_child(child)
		child.queue_free()

	for slot in grid_container.get_children():
		ensure_slot_layer_cards(slot)

	apply_slot_styles()


func ensure_slot_layer_cards(slot: Node) -> void:
	if slot == null:
		return

	if slot.get_node_or_null("Card") == null:
		var card := CardScene.instantiate()
		card.name = "Card"
		slot.add_child(card)

	if slot.get_node_or_null("AerialCard") == null:
		var aerial_card := CardScene.instantiate()
		aerial_card.name = "AerialCard"
		aerial_card.allows_empty_clicks = false
		aerial_card.z_index = 20
		slot.add_child(aerial_card)


func set_slot_effect_visual(slot_index: int, visual_key: String) -> void:
	if grid_container == null or slot_index < 0 or slot_index >= grid_container.get_child_count():
		return

	var slot := grid_container.get_child(slot_index)
	if slot == null:
		return
	var overlay := slot.get_node_or_null("GuTrapSlotOverlay") as GuTrapSlotOverlay
	if visual_key == "":
		if overlay != null:
			overlay.queue_free()
		return

	if overlay == null:
		overlay = GuTrapSlotOverlayScript.new() as GuTrapSlotOverlay
		overlay.name = "GuTrapSlotOverlay"
		overlay.z_index = 15
		slot.add_child(overlay)
		if slot is Control:
			overlay.apply_card_size((slot as Control).size)
	overlay.configure(visual_key)


func create_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	style.border_color = Color(1.0, 1.0, 1.0, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


func create_edge_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.16, 0.18, 0.16)
	style.border_color = Color(0.62, 0.86, 1.0, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


func apply_slot_styles() -> void:
	if grid_container == null or board_columns <= 0:
		return

	for index in range(grid_container.get_child_count()):
		var slot := grid_container.get_child(index)
		if not slot is PanelContainer:
			continue

		var is_land := is_land_style_slot(index)
		var style := create_slot_style() if is_land else create_edge_slot_style()
		slot.add_theme_stylebox_override("panel", style)


func set_land_slot_states(new_land_slot_states: Array) -> void:
	land_slot_states.clear()
	for value in new_land_slot_states:
		land_slot_states.append(bool(value))

	apply_slot_styles()


func is_land_style_slot(index: int) -> bool:
	if index >= 0 and index < land_slot_states.size():
		return land_slot_states[index]

	var row := floori(float(index) / float(board_columns))
	var column := index % board_columns
	return not (row == 0 or row == board_rows - 1 or column == 0 or column == board_columns - 1)


func resize_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_size := Vector2(
		maxf(viewport_size.x - viewport_margin.x * 2.0, 1.0),
		maxf(viewport_size.y - viewport_margin.y * 2.0, 1.0)
	)

	var scale_factor: float = minf(
		available_size.x / max_board_size.x,
		available_size.y / max_board_size.y
	)
	scale_factor = minf(scale_factor, 1.0)
	var board_size: Vector2 = max_board_size * scale_factor

	custom_minimum_size = board_size
	size = board_size
	update_slot_sizes(board_size)


func update_slot_sizes(board_size: Vector2) -> void:
	if grid_container == null:
		return

	var margin: float = 16.0 * 2.0
	var horizontal_gap: float = 12.0
	var vertical_gap: float = 12.0
	var inner_size: Vector2 = board_size - Vector2(margin, margin)
	var column_count := maxf(float(board_columns), 1.0)
	var row_count := maxf(float(board_rows), 1.0)
	var horizontal_gaps := maxf(column_count - 1.0, 0.0)
	var vertical_gaps := maxf(row_count - 1.0, 0.0)
	var slot_width: float = (inner_size.x - horizontal_gap * horizontal_gaps) / column_count
	var slot_height: float = (inner_size.y - vertical_gap * vertical_gaps) / row_count

	if slot_width / slot_height > slot_aspect_ratio:
		slot_width = slot_height * slot_aspect_ratio
	else:
		slot_height = slot_width / slot_aspect_ratio

	for child in grid_container.get_children():
		if child is Control:
			var slot_size := Vector2(slot_width, slot_height)
			child.custom_minimum_size = slot_size
			resize_cards_in_slot(child, slot_size)


func resize_cards_in_slot(slot: Control, slot_size: Vector2) -> void:
	for child in slot.get_children():
		if child is Control:
			if not Engine.is_editor_hint() and child.has_method("apply_card_size"):
				child.apply_card_size(slot_size)
			else:
				child.custom_minimum_size = slot_size
				child.size = slot_size
				child.set("card_size", slot_size)
