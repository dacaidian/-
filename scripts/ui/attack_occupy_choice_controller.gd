extends RefCounted
class_name AttackOccupyChoiceController

# AttackOccupyChoiceController 只负责攻击击杀后的占领选择 UI。
# 是否允许占领、占领后如何移动和补牌，仍由 GameManager 的规则流程决定。

signal choice_made(should_occupy: bool)

var layer: CanvasLayer
var panel: PanelContainer
var panel_size := Vector2(320, 132)


func setup(root: Node, new_panel_size: Vector2) -> void:
	panel_size = new_panel_size
	if panel != null:
		return

	if root == null:
		return

	layer = CanvasLayer.new()
	layer.name = "AttackOccupyChoiceLayer"
	layer.layer = 180
	root.add_child(layer)

	panel = PanelContainer.new()
	panel.name = "AttackOccupyChoicePanel"
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", create_panel_style())
	layer.add_child(panel)

	var margin_container := MarginContainer.new()
	margin_container.name = "MarginContainer"
	margin_container.add_theme_constant_override("margin_left", 14)
	margin_container.add_theme_constant_override("margin_top", 14)
	margin_container.add_theme_constant_override("margin_right", 14)
	margin_container.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin_container)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 12)
	margin_container.add_child(box)

	var message_label := Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message_label)

	var button_box := HBoxContainer.new()
	button_box.name = "ButtonBox"
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 12)
	box.add_child(button_box)

	var occupy_button := Button.new()
	occupy_button.text = "占领"
	ApplicationUiStyle.style_inline_button(
		occupy_button,
		ApplicationUiStyle.GOLD,
		true
	)
	occupy_button.pressed.connect(func(): choice_made.emit(true))
	button_box.add_child(occupy_button)

	var stay_button := Button.new()
	stay_button.text = "不占领"
	ApplicationUiStyle.style_inline_button(stay_button, ApplicationUiStyle.BLUE)
	stay_button.pressed.connect(func(): choice_made.emit(false))
	button_box.add_child(stay_button)


func prompt(root: Node, attacker_state: CardState, defeated_state: CardState, new_panel_size: Vector2) -> bool:
	setup(root, new_panel_size)
	if panel == null:
		return false

	var message_label := panel.get_node_or_null("MarginContainer/VBoxContainer/MessageLabel") as Label
	if message_label != null:
		message_label.text = "%s 击败了 %s\n是否占领目标格？" % [
			attacker_state.display_name,
			defeated_state.display_name
		]

	panel.position = get_centered_panel_position(root, panel_size)
	panel.show()
	var should_occupy: bool = await choice_made
	panel.hide()
	return should_occupy


func get_centered_panel_position(root: Node, size: Vector2) -> Vector2:
	var viewport := root.get_viewport()
	if viewport == null:
		return Vector2.ZERO

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	return (viewport_size - size) * 0.5


func create_panel_style() -> StyleBox:
	return ApplicationUiStyle.create_inset_panel_style(ApplicationUiStyle.GOLD)
