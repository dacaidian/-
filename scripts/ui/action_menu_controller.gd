extends RefCounted
class_name ActionMenuController

signal action_requested(action_id: String)
signal cancel_requested

# ActionMenuController 只负责动作菜单 UI：创建、显示、定位和按钮事件。
# 它不判断规则，也不执行行动。

const MENU_SIZE: Vector2 = Vector2(136, 44)
const MENU_GAP: float = 10.0
const SAFE_MARGIN: float = 24.0

var canvas_layer: CanvasLayer
var menu: PanelContainer
var button_box: HBoxContainer
var cancel_button: Button
var action_buttons: Array[Button] = []


func setup(parent: Node) -> void:
	if menu != null:
		return

	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ActionMenuLayer"
	canvas_layer.layer = 100
	parent.add_child(canvas_layer)

	menu = PanelContainer.new()
	menu.name = "ActionMenu"
	menu.visible = false
	menu.custom_minimum_size = MENU_SIZE
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.add_theme_stylebox_override("panel", create_menu_style())

	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	menu.add_child(margin_container)

	button_box = HBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	margin_container.add_child(button_box)

	cancel_button = Button.new()
	cancel_button.text = "取消"
	ApplicationUiStyle.style_inline_button(cancel_button, ApplicationUiStyle.DANGER)
	cancel_button.pressed.connect(func(): cancel_requested.emit())
	button_box.add_child(cancel_button)

	canvas_layer.add_child(menu)


func show_for_card(card: Card, actions: Array[CardAction]) -> void:
	show_for_control(card, actions)


func show_for_control(source_control: Control, actions: Array[CardAction]) -> void:
	if menu == null or button_box == null or source_control == null:
		return

	rebuild_action_buttons(actions)
	menu.visible = true
	menu.move_to_front()
	menu.size = menu.get_combined_minimum_size()
	position_for_control(source_control)


func show_for_rect(source_rect: Rect2, viewport_size: Vector2, actions: Array[CardAction]) -> void:
	if menu == null or button_box == null:
		return

	rebuild_action_buttons(actions)
	menu.visible = true
	menu.move_to_front()
	menu.size = menu.get_combined_minimum_size()
	position_for_rect(source_rect, viewport_size)


func hide() -> void:
	if menu != null:
		menu.hide()


func create_menu_style() -> StyleBox:
	return ApplicationUiStyle.create_section_panel_style(ApplicationUiStyle.GOLD)


func rebuild_action_buttons(actions: Array[CardAction]) -> void:
	for button in action_buttons:
		button_box.remove_child(button)
		button.queue_free()

	action_buttons.clear()

	for action in actions:
		var button: Button = Button.new()
		button.text = action.display_name
		ApplicationUiStyle.style_inline_button(button, ApplicationUiStyle.BLUE)
		button.pressed.connect(_on_action_button_pressed.bind(action.id))
		action_buttons.append(button)
		button_box.add_child(button)
		var insert_index: int = maxi(button_box.get_child_count() - 2, 0)
		button_box.move_child(button, insert_index)


func _on_action_button_pressed(action_id: String) -> void:
	action_requested.emit(action_id)


func position_for_card(card: Card) -> void:
	position_for_control(card)


func position_for_control(source_control: Control) -> void:
	var card_rect: Rect2 = source_control.get_global_rect()
	var viewport_size: Vector2 = source_control.get_viewport_rect().size
	position_for_rect(card_rect, viewport_size)


func position_for_rect(card_rect: Rect2, viewport_size: Vector2) -> void:
	var menu_size: Vector2 = menu.size
	var right_position: Vector2 = Vector2(card_rect.position.x + card_rect.size.x + MENU_GAP, card_rect.position.y)
	var left_position: Vector2 = Vector2(card_rect.position.x - menu_size.x - MENU_GAP, card_rect.position.y)
	var top_position: Vector2 = Vector2(card_rect.position.x, card_rect.position.y - menu_size.y - MENU_GAP)
	var target_position: Vector2 = right_position

	if right_position.x + menu_size.x > viewport_size.x - SAFE_MARGIN:
		target_position = left_position

	if target_position.x < SAFE_MARGIN:
		target_position = top_position

	target_position.x = clampf(target_position.x, SAFE_MARGIN, maxf(viewport_size.x - menu_size.x - SAFE_MARGIN, SAFE_MARGIN))
	target_position.y = clampf(target_position.y, SAFE_MARGIN, maxf(viewport_size.y - menu_size.y - SAFE_MARGIN, SAFE_MARGIN))
	menu.position = target_position
