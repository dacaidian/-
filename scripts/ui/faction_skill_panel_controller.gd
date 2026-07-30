extends RefCounted
class_name FactionSkillPanelController

signal skill_requested(skill_id: String)

const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

var panel: PanelContainer
var resource_list: VBoxContainer
var skill_list: VBoxContainer


func setup(root: Control) -> void:
	if root == null or panel != null:
		return

	panel = PanelContainer.new()
	panel.name = "FactionSkillPanel"
	panel.custom_minimum_size = Vector2(RightSideHudStyleScript.PANEL_WIDTH, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.z_index = 2090
	panel.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_panel_style(RightSideHudStyleScript.ACCENT_SKILL)
	)
	root.add_child.call_deferred(panel)

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
			"种族能力",
			"skill",
			RightSideHudStyleScript.ACCENT_SKILL
		)
	)

	resource_list = VBoxContainer.new()
	resource_list.name = "ResourceList"
	resource_list.add_theme_constant_override("separation", 5)
	resource_list.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(resource_list)

	skill_list = VBoxContainer.new()
	skill_list.name = "SkillList"
	skill_list.add_theme_constant_override("separation", 6)
	skill_list.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(skill_list)
	panel.hide()


func update(current_player: PlayerState, _root: Control = null, usable_skill_ids: Array[String] = []) -> void:
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
			skill_list.add_child(create_skill_row(current_player, skill_config, usable_skill_ids))


func create_resource_row(player: PlayerState, resource_id: String) -> Control:
	var config := player.get_faction_resource_config(resource_id)
	var current_value := player.get_faction_resource_value(resource_id)
	var max_value := int(config.get("max", 0))
	var display_name := str(config.get("name", resource_id))
	var hint := "%s：%d/%d" % [display_name, current_value, max_value]

	var item := PanelContainer.new()
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.tooltip_text = hint
	item.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(
			RightSideHudStyleScript.ACCENT_SKILL,
			0.20
		)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_child(row)
	row.add_child(
		RightSideHudStyleScript.create_icon(
			get_resource_symbol(resource_id),
			RightSideHudStyleScript.ACCENT_SKILL,
			Vector2(20.0, 20.0),
			display_name
		)
	)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.custom_minimum_size.x = 32.0
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	if max_value > 0 and max_value <= 12:
		row.add_child(
			RightSideHudStyleScript.create_pip_meter(
				current_value,
				max_value,
				RightSideHudStyleScript.ACCENT_SKILL,
				hint
			)
		)
	else:
		row.add_child(
			RightSideHudStyleScript.create_progress_meter(
				current_value,
				max_value,
				RightSideHudStyleScript.ACCENT_SKILL,
				hint
			)
		)
	return item


func create_skill_row(
	player: PlayerState,
	skill_config: Dictionary,
	usable_skill_ids: Array[String]
) -> Control:
	var skill_id := str(skill_config.get("id", ""))
	var skill_name := str(skill_config.get("name", skill_id))
	var row := HBoxContainer.new()
	row.name = "%sSkillRow" % skill_id
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(
		RightSideHudStyleScript.create_icon(
			"skill",
			RightSideHudStyleScript.ACCENT_SKILL,
			Vector2(19.0, 19.0),
			str(skill_config.get("description", skill_name))
		)
	)

	var button := Button.new()
	button.name = "%sSkillButton" % skill_id
	button.text = skill_name
	button.tooltip_text = str(skill_config.get("description", skill_name))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 31.0
	button.disabled = not player.can_use_faction_skill(skill_id) or not usable_skill_ids.has(skill_id)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	button.add_theme_color_override("font_disabled_color", RightSideHudStyleScript.MUTED_TEXT)
	button.add_theme_stylebox_override(
		"normal",
		RightSideHudStyleScript.create_button_style(RightSideHudStyleScript.ACCENT_SKILL)
	)
	button.add_theme_stylebox_override(
		"hover",
		RightSideHudStyleScript.create_button_style(RightSideHudStyleScript.ACCENT_SKILL, true)
	)
	button.add_theme_stylebox_override(
		"pressed",
		RightSideHudStyleScript.create_button_style(
			RightSideHudStyleScript.ACCENT_SKILL,
			false,
			true
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		RightSideHudStyleScript.create_disabled_button_style()
	)
	button.pressed.connect(func(): skill_requested.emit(skill_id))
	row.add_child(button)
	return row


func get_resource_symbol(resource_id: String) -> String:
	return "tail" if resource_id == "tail" else "status"


func clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
