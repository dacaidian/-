extends RefCounted
class_name ApplicationUiStyle

const PRIMARY_TEXT := Color(0.96, 0.91, 0.82, 1.0)
const SECONDARY_TEXT := Color(0.72, 0.69, 0.64, 1.0)
const GOLD := Color(0.86, 0.62, 0.28, 1.0)
const BLUE := Color(0.30, 0.58, 0.82, 1.0)
const DANGER := Color(0.76, 0.25, 0.20, 1.0)


static func create_panel_style(accent := GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.047, 0.040, 0.94)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 12
	return style


static func style_menu_button(button: Button, accent := GOLD, emphasized := false) -> void:
	if button == null:
		return

	button.custom_minimum_size = Vector2(360.0, 58.0)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", PRIMARY_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.44, 0.42, 0.39, 1.0))
	button.add_theme_stylebox_override("normal", _create_button_style(accent, emphasized, false))
	button.add_theme_stylebox_override("hover", _create_button_style(accent, true, false))
	button.add_theme_stylebox_override("pressed", _create_button_style(accent, true, true))
	button.add_theme_stylebox_override("disabled", _create_disabled_button_style())


static func style_compact_button(button: Button, accent := GOLD) -> void:
	if button == null:
		return
	style_menu_button(button, accent, false)
	button.custom_minimum_size = Vector2(174.0, 42.0)
	button.add_theme_font_size_override("font_size", 16)


static func _create_button_style(accent: Color, emphasized: bool, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base_alpha := 0.24 if emphasized else 0.12
	style.bg_color = Color(accent.r, accent.g, accent.b, base_alpha)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.95 if emphasized else 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	if pressed:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.34)
		style.content_margin_top = 14.0
		style.content_margin_bottom = 10.0
	return style


static func _create_disabled_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.10, 0.70)
	style.border_color = Color(0.28, 0.27, 0.25, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style
