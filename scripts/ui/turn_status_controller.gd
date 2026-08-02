extends RefCounted
class_name TurnStatusController

signal spell_turn_requested

const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

# Current-turn summary only. Geometry belongs to RightSideHudLayoutController.

var panel: PanelContainer
var logo_frame: PanelContainer
var logo_texture: TextureRect
var turn_label: Label
var player_label: Label
var faction_label: Label
var mana_label: Label
var flip_label: Label
var resource_label: Label
var victory_label: Label
var spell_turn_button: Button
var current_logo_path := ""


func setup(root: Node, panel_path: NodePath) -> void:
	if root == null:
		return

	panel = root.get_node_or_null(panel_path) as PanelContainer
	if panel == null:
		return

	clear_panel_content()
	build_content()
	panel.custom_minimum_size = Vector2(RightSideHudStyleScript.PANEL_WIDTH, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.z_index = 3000
	panel.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_panel_style(RightSideHudStyleScript.ACCENT_TURN)
	)
	panel.move_to_front.call_deferred()


func clear_panel_content() -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()


func build_content() -> void:
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

	content.add_child(create_identity_row())
	content.add_child(create_metric_row())

	victory_label = Label.new()
	victory_label.name = "VictoryLabel"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 17)
	victory_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.46, 1.0))
	victory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_label.hide()
	content.add_child(victory_label)

	spell_turn_button = Button.new()
	spell_turn_button.name = "SpellTurnButton"
	spell_turn_button.custom_minimum_size = Vector2(0.0, 31.0)
	spell_turn_button.mouse_filter = Control.MOUSE_FILTER_STOP
	spell_turn_button.add_theme_font_size_override("font_size", 14)
	spell_turn_button.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	spell_turn_button.add_theme_color_override("font_disabled_color", RightSideHudStyleScript.MUTED_TEXT)
	spell_turn_button.add_theme_stylebox_override(
		"normal",
		RightSideHudStyleScript.create_button_style(RightSideHudStyleScript.ACCENT_TIME)
	)
	spell_turn_button.add_theme_stylebox_override(
		"hover",
		RightSideHudStyleScript.create_button_style(RightSideHudStyleScript.ACCENT_TIME, true)
	)
	spell_turn_button.add_theme_stylebox_override(
		"pressed",
		RightSideHudStyleScript.create_button_style(
			RightSideHudStyleScript.ACCENT_TIME,
			false,
			true
		)
	)
	spell_turn_button.add_theme_stylebox_override(
		"disabled",
		RightSideHudStyleScript.create_disabled_button_style()
	)
	spell_turn_button.pressed.connect(func(): spell_turn_requested.emit())
	content.add_child(spell_turn_button)


func create_identity_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "IdentityRow"
	row.add_theme_constant_override("separation", 9)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	logo_frame = PanelContainer.new()
	logo_frame.name = "LogoFrame"
	logo_frame.custom_minimum_size = Vector2(48.0, 48.0)
	logo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_frame.add_theme_stylebox_override(
		"panel",
		RightSideHudStyleScript.create_inner_style(RightSideHudStyleScript.ACCENT_TURN, 0.36)
	)
	row.add_child(logo_frame)

	logo_texture = TextureRect.new()
	logo_texture.name = "LogoTexture"
	logo_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_frame.add_child(logo_texture)

	var identity := VBoxContainer.new()
	identity.name = "Identity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 1)
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(identity)

	var top_line := HBoxContainer.new()
	top_line.add_theme_constant_override("separation", 6)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(top_line)

	player_label = Label.new()
	player_label.name = "PlayerLabel"
	player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	player_label.add_theme_font_size_override("font_size", 20)
	player_label.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_line.add_child(player_label)

	var turn_badge := HBoxContainer.new()
	turn_badge.name = "TurnBadge"
	turn_badge.alignment = BoxContainer.ALIGNMENT_END
	turn_badge.add_theme_constant_override("separation", 3)
	turn_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	turn_badge.tooltip_text = "当前累计回合"
	turn_badge.add_child(
		RightSideHudStyleScript.create_icon(
			"turn",
			RightSideHudStyleScript.ACCENT_TURN,
			Vector2(16.0, 16.0),
			"当前累计回合"
		)
	)

	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.add_theme_font_size_override("font_size", 14)
	turn_label.add_theme_color_override("font_color", RightSideHudStyleScript.ACCENT_TURN)
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_badge.add_child(turn_label)
	top_line.add_child(turn_badge)

	faction_label = Label.new()
	faction_label.name = "FactionLabel"
	faction_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	faction_label.add_theme_font_size_override("font_size", 13)
	faction_label.add_theme_color_override("font_color", RightSideHudStyleScript.SECONDARY_TEXT)
	faction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(faction_label)
	return row


func create_metric_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "MetricRow"
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var mana_chip := RightSideHudStyleScript.create_metric_chip(
		"mana",
		Color(0.38, 0.76, 0.98, 1.0),
		"法力水晶"
	)
	mana_label = mana_chip.get("value_label") as Label
	row.add_child(mana_chip.get("root") as Control)

	var flip_chip := RightSideHudStyleScript.create_metric_chip(
		"flip",
		Color(0.94, 0.73, 0.30, 1.0),
		"本回合翻牌次数"
	)
	flip_label = flip_chip.get("value_label") as Label
	row.add_child(flip_chip.get("root") as Control)

	var score_chip := RightSideHudStyleScript.create_metric_chip(
		"score",
		Color(0.58, 0.86, 0.50, 1.0),
		"资源分 / 获胜目标"
	)
	resource_label = score_chip.get("value_label") as Label
	row.add_child(score_chip.get("root") as Control)
	return row


func update(
	current_player: PlayerState,
	turn_number: int,
	is_spell_turn_active := false,
	spell_turn_cost := 0,
	can_activate_spell_turn := false,
	victory_resource_score := 80,
	is_game_over := false,
	winner_player: PlayerState = null
) -> void:
	if panel == null:
		return

	panel.visible = current_player != null
	if current_player == null:
		return

	turn_label.text = str(turn_number)
	player_label.text = current_player.display_name
	faction_label.text = (
		current_player.faction_name
		if current_player.faction_name != ""
		else current_player.faction_id
	)
	mana_label.text = "%d/%d" % [current_player.mana, current_player.max_mana]
	flip_label.text = "%d/%d" % [
		current_player.remaining_flips,
		current_player.max_flips_per_turn,
	]
	resource_label.text = "%d/%d" % [
		current_player.resource_score,
		victory_resource_score,
	]

	victory_label.visible = is_game_over and winner_player != null
	victory_label.text = "%s 获胜" % winner_player.display_name if winner_player != null else ""

	var is_kagune_release := current_player.faction_id == "tokyo_ghoul"
	if is_game_over:
		spell_turn_button.text = "对战结束"
		spell_turn_button.disabled = true
	elif is_spell_turn_active:
		spell_turn_button.text = "赫子已解放" if is_kagune_release else "施法已开启"
		spell_turn_button.disabled = true
	else:
		spell_turn_button.text = (
			"赫子解放  -%d" % spell_turn_cost
			if is_kagune_release
			else "开启施法  -%d" % spell_turn_cost
		)
		spell_turn_button.disabled = not can_activate_spell_turn

	update_logo(current_player)


func update_logo(current_player: PlayerState) -> void:
	if logo_texture == null or current_player == null:
		return

	var logo_path := get_faction_logo_path(current_player)
	if logo_path == current_logo_path:
		return

	current_logo_path = logo_path
	if logo_path != "" and ResourceLoader.exists(logo_path):
		logo_texture.texture = load(logo_path) as Texture2D
		logo_texture.modulate = Color.WHITE
	else:
		logo_texture.texture = null


func get_faction_logo_path(current_player: PlayerState) -> String:
	var folder_name := current_player.faction_name
	if folder_name == "":
		folder_name = current_player.faction_id
	if folder_name == "":
		return ""
	return "res://assets/img/%s/logo.png" % folder_name
