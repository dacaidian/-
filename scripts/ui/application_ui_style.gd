extends RefCounted
class_name ApplicationUiStyle

const GameUiSkinScript := preload("res://scripts/ui/game_ui_skin.gd")

const PRIMARY_TEXT := Color(0.96, 0.91, 0.82, 1.0)
const SECONDARY_TEXT := Color(0.72, 0.69, 0.64, 1.0)
const GOLD := Color(0.86, 0.62, 0.28, 1.0)
const BLUE := Color(0.30, 0.58, 0.82, 1.0)
const DANGER := Color(0.76, 0.25, 0.20, 1.0)


static func create_panel_style(accent := GOLD) -> StyleBox:
	return GameUiSkinScript.create_panel_style(GameUiSkinScript.PanelKind.MAIN, accent)


static func create_inset_panel_style(accent := BLUE, extra_content_padding := 0.0) -> StyleBox:
	return GameUiSkinScript.create_panel_style(
		GameUiSkinScript.PanelKind.INSET,
		accent,
		extra_content_padding
	)


static func create_field_style(focused := false) -> StyleBox:
	return GameUiSkinScript.create_field_style(focused)


static func create_focus_style(accent := BLUE, radius := 5) -> StyleBox:
	return GameUiSkinScript.create_focus_style(accent, radius)


static func style_menu_button(button: Button, accent := GOLD, emphasized := false) -> void:
	if button == null:
		return

	button.custom_minimum_size = Vector2(360.0, 58.0)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", PRIMARY_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.44, 0.42, 0.39, 1.0))
	var button_kind := _resolve_button_kind(accent, emphasized)
	button.add_theme_stylebox_override(
		"normal",
		GameUiSkinScript.create_button_style(
			button_kind,
			GameUiSkinScript.ButtonState.NORMAL,
			accent
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		GameUiSkinScript.create_button_style(
			button_kind,
			GameUiSkinScript.ButtonState.HOVER,
			accent
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		GameUiSkinScript.create_button_style(
			button_kind,
			GameUiSkinScript.ButtonState.PRESSED,
			accent
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		GameUiSkinScript.create_button_style(
			button_kind,
			GameUiSkinScript.ButtonState.DISABLED,
			accent
		)
	)
	button.add_theme_stylebox_override("focus", GameUiSkinScript.create_focus_style(accent))


static func style_compact_button(button: Button, accent := GOLD) -> void:
	if button == null:
		return
	style_menu_button(button, accent, false)
	button.custom_minimum_size = Vector2(174.0, 42.0)
	button.add_theme_font_size_override("font_size", 16)


static func style_choice_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(0.0, 40.0)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.78, 0.77, 0.73, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.76, 1.0))
	button.add_theme_stylebox_override(
		"normal",
		GameUiSkinScript.create_button_style(
			GameUiSkinScript.ButtonKind.SECONDARY,
			GameUiSkinScript.ButtonState.NORMAL,
			BLUE
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		GameUiSkinScript.create_button_style(
			GameUiSkinScript.ButtonKind.SECONDARY,
			GameUiSkinScript.ButtonState.HOVER,
			BLUE
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		GameUiSkinScript.create_button_style(
			GameUiSkinScript.ButtonKind.PRIMARY,
			GameUiSkinScript.ButtonState.PRESSED,
			GOLD
		)
	)
	button.add_theme_stylebox_override("focus", GameUiSkinScript.create_focus_style(BLUE))


static func _resolve_button_kind(accent: Color, emphasized: bool) -> int:
	if accent.is_equal_approx(DANGER):
		return GameUiSkinScript.ButtonKind.DANGER
	if emphasized or accent.is_equal_approx(GOLD):
		return GameUiSkinScript.ButtonKind.PRIMARY
	return GameUiSkinScript.ButtonKind.SECONDARY
