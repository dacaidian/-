extends RefCounted
class_name FactionSkillPanelController

signal skill_requested(skill_id: String)

const PANEL_WIDTH := 248.0
const PANEL_MARGIN := 12.0
const PANEL_TOP := 292.0

var panel: PanelContainer
var resource_list: VBoxContainer
var skill_list: VBoxContainer


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "FactionSkillPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.z_index = 2090
	panel.add_theme_stylebox_override("panel", create_panel_style())
	root.add_child.call_deferred(panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "种族能力"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.72, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	resource_list = VBoxContainer.new()
	resource_list.name = "ResourceList"
	resource_list.add_theme_constant_override("separation", 5)
	resource_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(resource_list)

	skill_list = VBoxContainer.new()
	skill_list.name = "SkillList"
	skill_list.add_theme_constant_override("separation", 6)
	box.add_child(skill_list)

	position_panel(root)
	panel.hide()


func update(current_player: PlayerState, root: Control = null, usable_skill_ids: Array[String] = []) -> void:
	if panel == null:
		return

	clear_children(resource_list)
	clear_children(skill_list)

	var has_resources := current_player != null and not current_player.faction_resource_configs.is_empty()
	var has_skills := current_player != null and not current_player.get_unlocked_faction_skill_configs().is_empty()
	panel.visible = has_resources or has_skills
	if not panel.visible:
		return

	if has_resources:
		for resource_id in current_player.faction_resource_configs.keys():
			resource_list.add_child(create_resource_row(current_player, str(resource_id)))

	if has_skills:
		for skill_config in current_player.get_unlocked_faction_skill_configs():
			skill_list.add_child(create_skill_button(current_player, skill_config, usable_skill_ids))

	if root != null:
		call_deferred("position_panel", root)


func position_panel(root: Control) -> void:
	if panel == null or root == null:
		return

	var viewport := root.get_viewport()
	if viewport == null:
		return

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var panel_size := panel.get_combined_minimum_size()
	panel.position = Vector2(
		maxf(PANEL_MARGIN, viewport_size.x - panel_size.x - PANEL_MARGIN),
		clampf(PANEL_TOP, PANEL_MARGIN, maxf(PANEL_MARGIN, viewport_size.y - panel_size.y - PANEL_MARGIN))
	)


func create_resource_row(player: PlayerState, resource_id: String) -> Control:
	var config := player.get_faction_resource_config(resource_id)
	var row := HBoxContainer.new()
	row.name = "%sResourceRow" % resource_id
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_label := Label.new()
	name_label.text = str(config.get("name", resource_id))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.76, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "%d/%d" % [
		player.get_faction_resource_value(resource_id),
		int(config.get("max", 0))
	]
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.42, 1.0))
	value_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)

	return row


func create_skill_button(player: PlayerState, skill_config: Dictionary, usable_skill_ids: Array[String]) -> Button:
	var button := Button.new()
	var skill_id := str(skill_config.get("id", ""))
	button.name = "%sSkillButton" % skill_id
	button.text = str(skill_config.get("name", skill_id))
	button.disabled = not player.can_use_faction_skill(skill_id) or not usable_skill_ids.has(skill_id)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.82, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.48, 1.0))
	button.add_theme_stylebox_override("normal", create_skill_button_style(false))
	button.add_theme_stylebox_override("hover", create_skill_button_style(true))
	button.add_theme_stylebox_override("pressed", create_skill_button_style(true))
	button.add_theme_stylebox_override("disabled", create_skill_button_disabled_style())
	button.pressed.connect(func(): skill_requested.emit(skill_id))
	return button


func clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.045, 0.055, 0.94)
	style.border_color = Color(1.0, 0.48, 0.56, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.60)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 5)
	return style


func create_skill_button_style(is_hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.08, 0.10, 0.94) if not is_hover else Color(0.33, 0.11, 0.14, 0.98)
	style.border_color = Color(1.0, 0.60, 0.66, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(1.0, 0.42, 0.48, 0.20)
	style.shadow_size = 8 if is_hover else 4
	return style


func create_skill_button_disabled_style() -> StyleBoxFlat:
	var style := create_skill_button_style(false)
	style.bg_color = Color(0.10, 0.08, 0.085, 0.82)
	style.border_color = Color(0.32, 0.26, 0.27, 0.72)
	style.shadow_size = 0
	return style
