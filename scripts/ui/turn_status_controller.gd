extends RefCounted
class_name TurnStatusController

signal spell_turn_requested

# TurnStatusController 只负责右上角当前回合铭牌的表现。

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

	logo_frame = panel.get_node_or_null("MarginContainer/HBoxContainer/LogoFrame") as PanelContainer
	logo_texture = panel.get_node_or_null("MarginContainer/HBoxContainer/LogoFrame/LogoTexture") as TextureRect
	var margin_container := panel.get_node_or_null("MarginContainer") as Control
	var hbox_container := panel.get_node_or_null("MarginContainer/HBoxContainer") as Control
	var vbox_container := panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer") as Control
	turn_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/TurnLabel") as Label
	player_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/PlayerLabel") as Label
	faction_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/FactionLabel") as Label
	mana_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/ManaLabel") as Label
	flip_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/FlipLabel") as Label
	resource_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/ResourceLabel") as Label
	victory_label = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/VictoryLabel") as Label
	spell_turn_button = panel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/SpellTurnButton") as Button
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.z_index = 3000
	panel.move_to_front.call_deferred()
	panel.add_theme_stylebox_override("panel", create_panel_style())

	for container in [margin_container, hbox_container, vbox_container]:
		if container == null:
			continue
		container.mouse_filter = Control.MOUSE_FILTER_PASS

	if logo_frame != null:
		logo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_frame.add_theme_stylebox_override("panel", create_logo_frame_style())

	if logo_texture != null:
		logo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for label in [turn_label, player_label, faction_label, mana_label, flip_label, resource_label, victory_label]:
		if label == null:
			continue
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	if turn_label != null:
		turn_label.add_theme_color_override("font_color", Color(0.98, 0.76, 0.36, 1.0))
		turn_label.add_theme_font_size_override("font_size", 15)

	if player_label != null:
		player_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84, 1.0))
		player_label.add_theme_font_size_override("font_size", 25)

	if faction_label != null:
		faction_label.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 0.96))
		faction_label.add_theme_font_size_override("font_size", 17)

	if mana_label != null:
		mana_label.add_theme_color_override("font_color", Color(0.44, 0.82, 1.0, 1.0))
		mana_label.add_theme_font_size_override("font_size", 16)

	if flip_label != null:
		flip_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42, 1.0))
		flip_label.add_theme_font_size_override("font_size", 16)

	if resource_label != null:
		resource_label.add_theme_color_override("font_color", Color(0.94, 0.72, 0.30, 1.0))
		resource_label.add_theme_font_size_override("font_size", 16)

	if victory_label != null:
		victory_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.52, 1.0))
		victory_label.add_theme_font_size_override("font_size", 18)

	if spell_turn_button != null:
		spell_turn_button.mouse_filter = Control.MOUSE_FILTER_STOP
		spell_turn_button.pressed.connect(func(): spell_turn_requested.emit())
		spell_turn_button.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 1.0))
		spell_turn_button.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.62, 1.0))
		spell_turn_button.add_theme_font_size_override("font_size", 15)
		spell_turn_button.add_theme_stylebox_override("normal", create_spell_button_style(false))
		spell_turn_button.add_theme_stylebox_override("hover", create_spell_button_style(true))
		spell_turn_button.add_theme_stylebox_override("pressed", create_spell_button_style(true))
		spell_turn_button.add_theme_stylebox_override("disabled", create_spell_button_disabled_style())


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

	if turn_label != null:
		turn_label.text = "第 %d 回合" % turn_number

	if player_label != null:
		player_label.text = current_player.display_name

	if faction_label != null:
		var faction_text := current_player.faction_name
		if faction_text == "":
			faction_text = current_player.faction_id
		faction_label.text = faction_text

	if mana_label != null:
		mana_label.text = "法力 %d/%d" % [current_player.mana, current_player.max_mana]

	if flip_label != null:
		flip_label.text = "翻牌 %d/%d" % [
			current_player.remaining_flips,
			current_player.max_flips_per_turn
		]

	if resource_label != null:
		resource_label.text = "资源分 %d/%d" % [
			current_player.resource_score,
			victory_resource_score
		]

	if victory_label != null:
		victory_label.visible = is_game_over and winner_player != null
		victory_label.text = "%s 获胜" % winner_player.display_name if winner_player != null else ""

	if spell_turn_button != null:
		if is_game_over:
			spell_turn_button.text = "对战结束"
			spell_turn_button.disabled = true
		elif is_spell_turn_active:
			spell_turn_button.text = "施法已开启"
			spell_turn_button.disabled = true
		else:
			spell_turn_button.text = "开启施法  -%d" % spell_turn_cost
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


func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.043, 0.032, 0.92)
	style.border_color = Color(0.93, 0.68, 0.30, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 2
	style.content_margin_top = 2
	style.content_margin_right = 2
	style.content_margin_bottom = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 6)
	return style


func create_logo_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.055, 0.88)
	style.border_color = Color(1.0, 0.78, 0.38, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(1.0, 0.7, 0.25, 0.18)
	style.shadow_size = 10
	return style


func create_spell_button_style(is_hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.18, 0.24, 0.92) if not is_hover else Color(0.13, 0.28, 0.36, 0.96)
	style.border_color = Color(0.45, 0.86, 1.0, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.28, 0.78, 1.0, 0.18)
	style.shadow_size = 8 if is_hover else 4
	return style


func create_spell_button_disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.085, 0.09, 0.82)
	style.border_color = Color(0.32, 0.34, 0.36, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
