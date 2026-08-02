extends RefCounted
class_name FactionSkillPanelController

signal skill_requested(skill_id: String)

const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")
const TailResourceMeterScript := preload("res://scripts/ui/tail_resource_meter.gd")

var panel: PanelContainer
var resource_list: VBoxContainer
var skill_list: VBoxContainer
var last_resource_values_by_player: Dictionary = {}
var last_view_signature := ""


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
	content.alignment = BoxContainer.ALIGNMENT_CENTER
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
	var view_signature := _build_view_signature(current_player, usable_skill_ids)
	if view_signature == last_view_signature:
		return
	last_view_signature = view_signature
	var previous_values: Dictionary = {}
	if current_player != null:
		previous_values = last_resource_values_by_player.get(current_player.id, {}).duplicate()

	clear_children(resource_list)
	clear_children(skill_list)

	var has_resources := current_player != null and not current_player.faction_resource_configs.is_empty()
	var has_skills := current_player != null and not current_player.get_unlocked_faction_skill_configs().is_empty()
	panel.visible = has_resources or has_skills
	if not panel.visible:
		return

	if has_resources:
		var current_values: Dictionary = {}
		for resource_id in current_player.faction_resource_configs.keys():
			var normalized_resource_id := str(resource_id)
			var current_value := current_player.get_faction_resource_value(normalized_resource_id)
			var previous_value := int(previous_values.get(normalized_resource_id, current_value))
			resource_list.add_child(
				create_resource_row(current_player, normalized_resource_id, previous_value)
			)
			current_values[normalized_resource_id] = current_value
		last_resource_values_by_player[current_player.id] = current_values

	if has_skills:
		for skill_config in current_player.get_unlocked_faction_skill_configs():
			skill_list.add_child(create_skill_row(current_player, skill_config, usable_skill_ids))


func _build_view_signature(player: PlayerState, usable_skill_ids: Array[String]) -> String:
	if player == null:
		return "none"
	var resources: Array[String] = []
	var resource_ids: Array = player.faction_resource_configs.keys()
	resource_ids.sort()
	for resource_id_value in resource_ids:
		var resource_id := str(resource_id_value)
		var config := player.get_faction_resource_config(resource_id)
		resources.append("%s:%d:%d" % [
			resource_id,
			player.get_faction_resource_value(resource_id),
			int(config.get("max", 0)),
		])

	var usable_ids := usable_skill_ids.duplicate()
	usable_ids.sort()
	var skills: Array[String] = []
	for skill_config in player.get_unlocked_faction_skill_configs():
		var skill_id := str(skill_config.get("id", ""))
		skills.append("%s:%s:%s" % [
			skill_id,
			str(player.can_use_faction_skill(skill_id)),
			str(usable_ids.has(skill_id)),
		])
	skills.sort()
	return "%s|%s|%s|%s" % [
		player.id,
		player.faction_id,
		",".join(resources),
		",".join(skills),
	]


func create_resource_row(player: PlayerState, resource_id: String, previous_value := -1) -> Control:
	var config := player.get_faction_resource_config(resource_id)
	var current_value := player.get_faction_resource_value(resource_id)
	var max_value := int(config.get("max", 0))
	var display_name := str(config.get("name", resource_id))
	var hint := "%s：%d/%d" % [display_name, current_value, max_value]
	if resource_id == "tail":
		return create_tail_resource_row(
			current_value,
			max_value,
			current_value if previous_value < 0 else previous_value,
			hint
		)

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


func create_tail_resource_row(
	current_value: int,
	max_value: int,
	previous_value: int,
	hint: String
) -> Control:
	var item := PanelContainer.new()
	item.name = "TailResourceRow"
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.tooltip_text = hint
	item.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(Color(0.88, 0.20, 0.44, 1.0), 0.28)
	)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(header)
	header.add_child(
		RightSideHudStyleScript.create_icon(
			"tail",
			Color(0.96, 0.30, 0.54, 1.0),
			Vector2(19.0, 19.0),
			hint
		)
	)

	var name_label := Label.new()
	name_label.text = "妖尾"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(name_label)

	var stage_label := Label.new()
	stage_label.name = "TailStageLabel"
	stage_label.text = get_tail_stage_label(current_value)
	stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage_label.add_theme_font_size_override("font_size", 12)
	stage_label.add_theme_color_override("font_color", get_tail_stage_color(current_value))
	stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(stage_label)

	var next_label := Label.new()
	next_label.name = "TailNextStageLabel"
	next_label.text = get_tail_next_stage_label(current_value)
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_label.add_theme_font_size_override("font_size", 11)
	next_label.add_theme_color_override("font_color", RightSideHudStyleScript.MUTED_TEXT)
	next_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(next_label)

	var meter := TailResourceMeterScript.new() as TailResourceMeter
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.configure(current_value, max_value, previous_value, hint)
	content.add_child(meter)
	return item


func get_tail_stage_label(value: int) -> String:
	if value >= 9:
		return "九尾 · 复生"
	if value >= 6:
		return "六尾 · 免疫"
	if value >= 3:
		return "三尾 · 远程"
	return "初尾"


func get_tail_next_stage_label(value: int) -> String:
	if value >= 9:
		return "终局妖相已成"
	if value >= 6:
		return "距九尾 %d" % (9 - value)
	if value >= 3:
		return "距六尾 %d" % (6 - value)
	return "距三尾 %d" % (3 - value)


func get_tail_stage_color(value: int) -> Color:
	if value >= 9:
		return Color(0.94, 0.80, 0.48, 1.0)
	if value >= 6:
		return Color(0.92, 0.86, 1.0, 1.0)
	if value >= 3:
		return Color(0.96, 0.34, 0.62, 1.0)
	return Color(0.76, 0.22, 0.36, 1.0)


func create_skill_row(
	player: PlayerState,
	skill_config: Dictionary,
	usable_skill_ids: Array[String]
) -> Control:
	var skill_id := str(skill_config.get("id", ""))
	var skill_name := str(skill_config.get("name", skill_id))
	var is_nine_tail_sacrifice := (
		skill_id == "sacrifice"
		and player.get_faction_resource_value("tail") >= 9
	)
	var skill_hint := str(skill_config.get("description", skill_name))
	if is_nine_tail_sacrifice:
		skill_hint = "献祭一个友方非英雄随从，使其死亡，并为九尾生效范围内的随从增加复生。"
	var row := HBoxContainer.new()
	row.name = "%sSkillRow" % skill_id
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(
		RightSideHudStyleScript.create_icon(
			"status" if is_nine_tail_sacrifice else "skill",
			Color(0.94, 0.80, 0.48, 1.0) if is_nine_tail_sacrifice else RightSideHudStyleScript.ACCENT_SKILL,
			Vector2(19.0, 19.0),
			skill_hint
		)
	)

	var button := Button.new()
	button.name = "%sSkillButton" % skill_id
	button.text = "%s · 复生" % skill_name if is_nine_tail_sacrifice else skill_name
	button.tooltip_text = skill_hint
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
