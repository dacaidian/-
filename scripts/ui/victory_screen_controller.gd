extends RefCounted
class_name VictoryScreenController

signal return_to_menu_requested()

var _layer: CanvasLayer
var _backdrop: ColorRect
var _banner_container: Control
var _banner_label: Label
var _subtitle_label: Label
var _effect_root: Control
var _stats_panel: PanelContainer
var _return_button: Button
var _pending_particles: Array[Node] = []


func show(root: Node, winner: PlayerState, all_players: Array[PlayerState], turn_number: int, victory_target: int) -> void:
	if root == null or winner == null:
		return

	_build_ui(root, winner, all_players, turn_number, victory_target)
	await _play_animation_sequence(root)
	await _return_button.pressed
	_layer.hide()
	_cleanup()
	return_to_menu_requested.emit()


func _build_ui(root: Node, winner: PlayerState, all_players: Array[PlayerState], turn_number: int, victory_target: int) -> void:
	_layer = CanvasLayer.new()
	_layer.name = "VictoryScreenLayer"
	_layer.layer = 4000
	root.add_child(_layer)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_backdrop)

	_effect_root = Control.new()
	_effect_root.name = "EffectRoot"
	_effect_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_effect_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_effect_root)

	var viewport_size := root.get_viewport().get_visible_rect().size

	_banner_container = Control.new()
	_banner_container.name = "BannerContainer"
	_banner_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_banner_container)

	var banner_panel := PanelContainer.new()
	banner_panel.name = "BannerPanel"
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_theme_stylebox_override("panel", _create_banner_style())
	_banner_container.add_child(banner_panel)

	var banner_margin := MarginContainer.new()
	banner_margin.name = "BannerMargin"
	banner_margin.add_theme_constant_override("margin_left", 40)
	banner_margin.add_theme_constant_override("margin_top", 20)
	banner_margin.add_theme_constant_override("margin_right", 40)
	banner_margin.add_theme_constant_override("margin_bottom", 20)
	banner_panel.add_child(banner_margin)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.name = "BannerVBox"
	banner_vbox.add_theme_constant_override("separation", 6)
	banner_margin.add_child(banner_vbox)

	_banner_label = Label.new()
	_banner_label.name = "BannerLabel"
	_banner_label.text = "%s 获胜!" % winner.display_name
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 64)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.52, 1.0))
	banner_vbox.add_child(_banner_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.text = "以 %d 资源分赢得胜利" % winner.resource_score
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 22)
	_subtitle_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.74, 0.95))
	banner_vbox.add_child(_subtitle_label)

	var banner_size := banner_panel.get_combined_minimum_size()
	var banner_pos := _get_centered_position(root, banner_size)
	banner_pos.y = viewport_size.y * 0.22
	banner_panel.position = banner_pos
	banner_panel.modulate = Color(1, 1, 1, 0)
	_banner_container.position = Vector2(0, -300)

	_stats_panel = _build_stats_panel(winner, all_players, turn_number, victory_target)
	_stats_panel.modulate = Color(1, 1, 1, 0)
	_stats_panel.scale = Vector2(0.85, 0.85)
	_stats_panel.position = _get_centered_position(root, _stats_panel.custom_minimum_size)
	_layer.add_child(_stats_panel)

	_return_button = Button.new()
	_return_button.name = "ReturnButton"
	_return_button.text = "正在生成战报..."
	_return_button.disabled = true
	_return_button.custom_minimum_size = Vector2(280, 52)
	_return_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_return_button.add_theme_font_size_override("font_size", 22)
	_return_button.add_theme_color_override("font_color", Color(0.16, 0.10, 0.04, 1.0))
	_return_button.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.42, 1.0))
	_return_button.add_theme_stylebox_override("normal", _create_button_style(false))
	_return_button.add_theme_stylebox_override("hover", _create_button_style(true))
	_return_button.add_theme_stylebox_override("pressed", _create_button_style(true))
	_return_button.add_theme_stylebox_override("disabled", _create_button_disabled_style())
	_layer.add_child(_return_button)

	var stats_bottom: float = _stats_panel.position.y + _stats_panel.custom_minimum_size.y
	_return_button.position = Vector2(
		(viewport_size.x - _return_button.custom_minimum_size.x) * 0.5,
		stats_bottom + 20
	)


func _build_stats_panel(winner: PlayerState, all_players: Array[PlayerState], turn_number: int, victory_target: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "StatsPanel"
	panel.custom_minimum_size = Vector2(580, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _create_stats_panel_style())

	var margin := MarginContainer.new()
	margin.name = "StatsMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "StatsVBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "StatsTitle"
	title.text = "战局统计"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.52, 1.0))
	vbox.add_child(title)

	vbox.add_child(_create_separator())

	vbox.add_child(_create_stat_row("获胜方", winner.faction_name, Color(1.0, 0.87, 0.52, 1.0)))
	vbox.add_child(_create_stat_row("总回合数", "第 %d 回合" % turn_number, Color(0.93, 0.87, 0.74, 0.95)))
	vbox.add_child(_create_stat_row("胜利目标", "%d 资源分" % victory_target, Color(0.93, 0.87, 0.74, 0.95)))

	vbox.add_child(_create_separator())

	var loser := _find_loser(winner, all_players)
	if loser != null:
		vbox.add_child(_create_comparison_section(winner, loser))

	return panel


func _create_comparison_section(winner: PlayerState, loser: PlayerState) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = "ComparisonSection"
	section.add_theme_constant_override("separation", 8)

	var header_label := Label.new()
	header_label.text = "玩家对比"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 20)
	header_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.74, 0.95))
	section.add_child(header_label)

	var columns := HBoxContainer.new()
	columns.name = "ComparisonColumns"
	columns.add_theme_constant_override("separation", 16)
	section.add_child(columns)

	var p1_vbox := VBoxContainer.new()
	p1_vbox.name = "Player1Stats"
	p1_vbox.add_theme_constant_override("separation", 4)
	p1_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(p1_vbox)

	var labels_vbox := VBoxContainer.new()
	labels_vbox.name = "StatLabels"
	labels_vbox.add_theme_constant_override("separation", 4)
	columns.add_child(labels_vbox)

	var p2_vbox := VBoxContainer.new()
	p2_vbox.name = "Player2Stats"
	p2_vbox.add_theme_constant_override("separation", 4)
	p2_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(p2_vbox)

	_add_player_name_row(p1_vbox, winner, true)
	labels_vbox.add_child(_create_label("", 16, Color.WHITE))
	_add_player_name_row(p2_vbox, loser, false)

	_add_compare_row(p1_vbox, labels_vbox, p2_vbox, "资源分", _resource_text(winner, 80), _resource_text(loser, 80), true, false)
	_add_compare_row(p1_vbox, labels_vbox, p2_vbox, "手牌数", str(winner.hand.size()), str(loser.hand.size()), true, false)
	_add_compare_row(p1_vbox, labels_vbox, p2_vbox, "坟场牌", str(winner.graveyard.size()), str(loser.graveyard.size()), true, false)
	_add_compare_row(p1_vbox, labels_vbox, p2_vbox, "装备数", str(winner.equipped_cards_by_type.size()), str(loser.equipped_cards_by_type.size()), true, false)

	return section


func _add_player_name_row(column: VBoxContainer, player: PlayerState, is_winner: bool) -> void:
	var label := _create_label(player.faction_name, 17, _winner_color(is_winner))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)


func _add_compare_row(col1: VBoxContainer, col_labels: VBoxContainer, col2: VBoxContainer, stat_name: String, val1: String, val2: String, is_winner1: bool, is_winner2: bool) -> void:
	col1.add_child(_create_label(val1, 17, _winner_color(is_winner1)))
	col_labels.add_child(_create_label(stat_name, 16, Color(0.82, 0.78, 0.68, 0.9)))
	col2.add_child(_create_label(val2, 17, _winner_color(is_winner2)))


func _resource_text(player: PlayerState, target: int) -> String:
	return "%d/%d" % [player.resource_score, target]


func _winner_color(is_winner: bool) -> Color:
	return Color(1.0, 0.87, 0.52, 1.0) if is_winner else Color(0.75, 0.72, 0.65, 0.9)


func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _create_stat_row(label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "StatRow"
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.74, 0.95))
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", value_color)
	row.add_child(value_label)

	return row


func _create_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.name = "Separator"
	sep.add_theme_constant_override("separation", 6)
	return sep


func _find_loser(winner: PlayerState, all_players: Array[PlayerState]) -> PlayerState:
	for p in all_players:
		if p != null and p.id != winner.id:
			return p
	return null


func _play_animation_sequence(root: Node) -> void:
	var viewport_size := root.get_viewport().get_visible_rect().size
	var banner_origin := _banner_container.position
	var banner_target := Vector2(0, 0)
	_banner_container.position = banner_origin

	var t0 := root.create_tween()
	t0.set_trans(Tween.TRANS_SINE)
	t0.set_ease(Tween.EASE_OUT)
	t0.tween_property(_backdrop, "color:a", 0.62, 0.5)

	var t1 := root.create_tween()
	t1.set_trans(Tween.TRANS_BACK)
	t1.set_ease(Tween.EASE_OUT)
	t1.tween_property(_banner_container, "position", banner_target, 0.6)
	t1.tween_property(_banner_container.get_child(0), "modulate:a", 1.0, 0.6)

	await root.get_tree().create_timer(0.6).timeout
	_spawn_victory_particles(root, _get_banner_center(root))

	await root.get_tree().create_timer(0.4).timeout
	var t2 := root.create_tween()
	t2.set_parallel(true)
	t2.set_trans(Tween.TRANS_BACK)
	t2.set_ease(Tween.EASE_OUT)
	t2.tween_property(_stats_panel, "modulate:a", 1.0, 0.5)
	t2.tween_property(_stats_panel, "scale", Vector2(1.0, 1.0), 0.5)
	await t2.finished

	await root.get_tree().create_timer(0.1).timeout
	_return_button.text = "返回主菜单"
	_return_button.disabled = false


func _get_banner_center(root: Node) -> Vector2:
	var banner_panel := _banner_container.get_child(0) as PanelContainer
	if banner_panel == null:
		return Vector2.ZERO
	var panel_global_pos := banner_panel.global_position
	var panel_size := banner_panel.size
	return panel_global_pos + panel_size * 0.5


func _spawn_victory_particles(owner: Node, origin: Vector2) -> void:
	var count := 35
	var gold_colors := [
		Color(1.0, 0.87, 0.52),
		Color(1.0, 0.78, 0.38),
		Color(0.94, 0.72, 0.30),
		Color(1.0, 0.92, 0.66),
		Color(0.96, 0.82, 0.44),
	]

	for i in range(count):
		var particle := Panel.new()
		particle.name = "VictoryParticle_%d" % i
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.z_index = 4050
		var p_size := randf_range(6, 16)
		particle.size = Vector2(p_size, p_size)
		particle.pivot_offset = particle.size * 0.5
		particle.global_position = origin
		var p_style := StyleBoxFlat.new()
		p_style.bg_color = gold_colors[i % gold_colors.size()]
		p_style.corner_radius_all = 2
		particle.add_theme_stylebox_override("panel", p_style)
		_effect_root.add_child(particle)
		_pending_particles.append(particle)

		var angle := randf_range(0, TAU)
		var distance := randf_range(120, 380)
		var target_pos := origin + Vector2(cos(angle), sin(angle)) * distance
		var duration := randf_range(0.6, 1.0)

		var tween := owner.create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "global_position", target_pos, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.15, 0.15), duration)
		tween.tween_callback(particle.queue_free)


func _cleanup() -> void:
	for particle in _pending_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_pending_particles.clear()

	if _layer != null:
		_layer.queue_free()
		_layer = null


func _get_centered_position(root: Node, size: Vector2) -> Vector2:
	var viewport := root.get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var viewport_size := viewport.get_visible_rect().size
	return (viewport_size - size) * 0.5


func _create_banner_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.02, 0.92)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.93, 0.68, 0.30, 0.9)
	style.corner_radius_all = 12
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	style.shadow_color = Color(0, 0, 0, 0.58)
	return style


func _create_stats_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.94)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.93, 0.68, 0.30, 0.82)
	style.corner_radius_all = 10
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 6)
	style.shadow_color = Color(0, 0, 0, 0.52)
	return style


func _create_button_style(is_hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_hover:
		style.bg_color = Color(1.0, 0.82, 0.42, 1.0)
		style.border_color = Color(1.0, 0.94, 0.68, 1.0)
	else:
		style.bg_color = Color(0.95, 0.72, 0.30, 1.0)
		style.border_color = Color(1.0, 0.92, 0.66, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_all = 8
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.shadow_color = Color(0, 0, 0, 0.45)
	return style


func _create_button_disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.23, 0.20, 0.8)
	style.border_color = Color(0.42, 0.38, 0.32, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_all = 8
	return style
