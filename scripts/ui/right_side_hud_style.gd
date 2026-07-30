extends RefCounted
class_name RightSideHudStyle

const HudSymbolIconScript := preload("res://scripts/ui/hud_symbol_icon.gd")
const GameUiSkinScript := preload("res://scripts/ui/game_ui_skin.gd")

const PANEL_WIDTH := 304.0
const PANEL_MARGIN := 16.0
const PANEL_GAP := 8.0
const CONTENT_MARGIN := 8
const CONTENT_GAP := 8

const BASE_BACKGROUND := Color(0.043, 0.047, 0.050, 0.96)
const INNER_BACKGROUND := Color(0.075, 0.078, 0.080, 0.92)
const PRIMARY_TEXT := Color(0.96, 0.94, 0.88, 1.0)
const SECONDARY_TEXT := Color(0.70, 0.72, 0.72, 0.92)
const MUTED_TEXT := Color(0.49, 0.51, 0.52, 0.90)

const ACCENT_TURN := Color(0.95, 0.70, 0.30, 1.0)
const ACCENT_SKILL := Color(0.93, 0.43, 0.48, 1.0)
const ACCENT_TIME := Color(0.38, 0.78, 0.86, 1.0)
const ACCENT_EQUIPMENT := Color(0.78, 0.63, 0.38, 1.0)


static func create_icon(
	symbol_id: String,
	color: Color,
	icon_size := Vector2(20.0, 20.0),
	hint := ""
) -> Control:
	return HudSymbolIconScript.new().setup(symbol_id, color, icon_size, hint)


static func create_panel_style(accent: Color) -> StyleBox:
	return GameUiSkinScript.create_panel_style(
		GameUiSkinScript.PanelKind.HUD,
		accent,
		0.0
	)


static func create_inner_style(accent: Color, accent_alpha := 0.24) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INNER_BACKGROUND
	style.border_color = Color(accent.r, accent.g, accent.b, accent_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_top = 5
	style.content_margin_right = 6
	style.content_margin_bottom = 5
	return style


static func create_header(title_text: String, symbol_id: String, accent: Color) -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 7)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(create_icon(symbol_id, accent, Vector2(18.0, 18.0), title_text))

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", PRIMARY_TEXT)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title)

	var accent_line := ColorRect.new()
	accent_line.name = "AccentLine"
	accent_line.custom_minimum_size = Vector2(38.0, 2.0)
	accent_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	accent_line.color = Color(accent.r, accent.g, accent.b, 0.72)
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(accent_line)
	return header


static func create_metric_chip(
	symbol_id: String,
	accent: Color,
	hint: String
) -> Dictionary:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.custom_minimum_size = Vector2(0.0, 32.0)
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.tooltip_text = hint
	chip.add_theme_stylebox_override("panel", create_inner_style(accent, 0.20))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	row.add_child(create_icon(symbol_id, accent, Vector2(17.0, 17.0), hint))

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", PRIMARY_TEXT)
	value_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)

	return {
		"root": chip,
		"value_label": value_label,
	}


static func create_pip_meter(current_value: int, max_value: int, accent: Color, hint: String) -> Control:
	var meter := HBoxContainer.new()
	meter.name = "PipMeter"
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.alignment = BoxContainer.ALIGNMENT_END
	meter.add_theme_constant_override("separation", 3)
	meter.mouse_filter = Control.MOUSE_FILTER_PASS
	meter.tooltip_text = hint

	var safe_max := clampi(max_value, 1, 12)
	var safe_current := clampi(current_value, 0, safe_max)
	for index in range(safe_max):
		var pip := PanelContainer.new()
		pip.custom_minimum_size = Vector2(11.0, 17.0)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = (
			Color(accent.r, accent.g, accent.b, 0.94)
			if index < safe_current
			else Color(0.16, 0.17, 0.18, 0.88)
		)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.52)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		pip.add_theme_stylebox_override("panel", style)
		meter.add_child(pip)
	return meter


static func create_progress_meter(current_value: int, max_value: int, accent: Color, hint: String) -> Control:
	var progress := ProgressBar.new()
	progress.name = "ResourceProgress"
	progress.custom_minimum_size = Vector2(112.0, 17.0)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.min_value = 0.0
	progress.max_value = maxf(1.0, float(max_value))
	progress.value = clampf(float(current_value), 0.0, progress.max_value)
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_PASS
	progress.tooltip_text = hint

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.14, 0.15, 0.16, 0.92)
	background.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	progress.add_theme_stylebox_override("background", background)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(accent.r, accent.g, accent.b, 0.88)
	fill.set_corner_radius_all(3)
	progress.add_theme_stylebox_override("fill", fill)
	return progress


static func create_button_style(
	accent: Color,
	is_hover := false,
	is_pressed := false
) -> StyleBox:
	var state := GameUiSkinScript.ButtonState.NORMAL
	if is_pressed:
		state = GameUiSkinScript.ButtonState.PRESSED
	elif is_hover:
		state = GameUiSkinScript.ButtonState.HOVER
	return GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.SECONDARY,
		state,
		accent
	)


static func create_disabled_button_style() -> StyleBox:
	return GameUiSkinScript.create_button_style(
		GameUiSkinScript.ButtonKind.SECONDARY,
		GameUiSkinScript.ButtonState.DISABLED
	)
