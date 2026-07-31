extends RefCounted
class_name GameUiSkin

enum PanelKind {
	MAIN = 0,
	DRAWER = 1,
	INSET = 2,
	SECTION = 3,
	HUD = 4,
	SIDEBAR = 5,
}

enum ButtonKind {
	PRIMARY,
	SECONDARY,
	DANGER,
	TAB,
}

enum ButtonState {
	NORMAL,
	HOVER,
	PRESSED,
	DISABLED,
}

const PANEL_MAIN_TEXTURE := preload("res://assets/img/ui_skin/panel_main.png")
const PANEL_DRAWER_TEXTURE := preload("res://assets/img/ui_skin/panel_drawer.png")
const PANEL_SIDEBAR_TEXTURE := preload("res://assets/img/ui_skin/panel_sidebar.png")
const PANEL_HUD_TEXTURE := preload("res://assets/img/ui_skin/panel_hud.png")
const PANEL_INSET_TEXTURE := preload("res://assets/img/ui_skin/panel_inset.png")
const PANEL_SECTION_TEXTURE := preload("res://assets/img/ui_skin/panel_section.png")

const PRIMARY_BUTTON_TEXTURES := {
	ButtonState.NORMAL: preload("res://assets/img/ui_skin/button_primary_normal.png"),
	ButtonState.HOVER: preload("res://assets/img/ui_skin/button_primary_hover.png"),
	ButtonState.PRESSED: preload("res://assets/img/ui_skin/button_primary_pressed.png"),
	ButtonState.DISABLED: preload("res://assets/img/ui_skin/button_primary_disabled.png"),
}
const SECONDARY_BUTTON_TEXTURES := {
	ButtonState.NORMAL: preload("res://assets/img/ui_skin/button_secondary_normal.png"),
	ButtonState.HOVER: preload("res://assets/img/ui_skin/button_secondary_hover.png"),
	ButtonState.PRESSED: preload("res://assets/img/ui_skin/button_secondary_pressed.png"),
	ButtonState.DISABLED: preload("res://assets/img/ui_skin/button_secondary_disabled.png"),
}
const TAB_BUTTON_TEXTURES := {
	ButtonState.NORMAL: preload("res://assets/img/ui_skin/button_tab_normal.png"),
	ButtonState.HOVER: preload("res://assets/img/ui_skin/button_tab_hover.png"),
	ButtonState.PRESSED: preload("res://assets/img/ui_skin/button_tab_pressed.png"),
	ButtonState.DISABLED: preload("res://assets/img/ui_skin/button_tab_disabled.png"),
}

const FIELD_NORMAL_TEXTURE := preload("res://assets/img/ui_skin/field_normal.png")
const FIELD_FOCUS_TEXTURE := preload("res://assets/img/ui_skin/field_focus.png")

const PANEL_TEXTURE_MARGINS := {
	PanelKind.MAIN: Vector4(86.0, 78.0, 86.0, 78.0),
	PanelKind.DRAWER: Vector4(34.0, 32.0, 34.0, 32.0),
	PanelKind.SIDEBAR: Vector4(22.0, 26.0, 22.0, 26.0),
	PanelKind.INSET: Vector4(20.0, 12.0, 20.0, 12.0),
	PanelKind.SECTION: Vector4(10.0, 7.0, 10.0, 7.0),
	PanelKind.HUD: Vector4(30.0, 20.0, 30.0, 20.0),
}

# Texture slice margins protect the artwork. These separate safe insets keep
# child controls clear of the visible wood, metal corners, and inner bevel.
const PANEL_SAFE_INSETS := {
	PanelKind.MAIN: Vector4(44.0, 44.0, 44.0, 44.0),
	PanelKind.DRAWER: Vector4(32.0, 30.0, 32.0, 30.0),
	PanelKind.SIDEBAR: Vector4(22.0, 26.0, 22.0, 26.0),
	PanelKind.INSET: Vector4(20.0, 12.0, 20.0, 12.0),
	PanelKind.SECTION: Vector4(10.0, 8.0, 10.0, 8.0),
	PanelKind.HUD: Vector4(22.0, 14.0, 22.0, 14.0),
}


static func create_panel_style(
	kind := PanelKind.MAIN,
	accent := Color.WHITE,
	extra_content_padding := 0.0
) -> StyleBoxTexture:
	var texture: Texture2D = PANEL_MAIN_TEXTURE
	var texture_margins: Vector4 = PANEL_TEXTURE_MARGINS[PanelKind.MAIN]
	match kind:
		PanelKind.DRAWER:
			texture = PANEL_DRAWER_TEXTURE
			texture_margins = PANEL_TEXTURE_MARGINS[PanelKind.DRAWER]
		PanelKind.SIDEBAR:
			texture = PANEL_SIDEBAR_TEXTURE
			texture_margins = PANEL_TEXTURE_MARGINS[PanelKind.SIDEBAR]
		PanelKind.INSET:
			texture = PANEL_INSET_TEXTURE
			texture_margins = PANEL_TEXTURE_MARGINS[PanelKind.INSET]
		PanelKind.SECTION:
			texture = PANEL_SECTION_TEXTURE
			texture_margins = PANEL_TEXTURE_MARGINS[PanelKind.SECTION]
		PanelKind.HUD:
			texture = PANEL_HUD_TEXTURE
			texture_margins = PANEL_TEXTURE_MARGINS[PanelKind.HUD]

	var safe_insets := get_panel_safe_insets(kind)
	var extra_padding := Vector4(
		extra_content_padding,
		extra_content_padding,
		extra_content_padding,
		extra_content_padding
	)
	var style := _create_texture_style(
		texture,
		texture_margins,
		safe_insets + extra_padding
	)
	style.modulate_color = _create_subtle_accent_modulate(accent)
	return style


static func get_panel_safe_insets(kind := PanelKind.MAIN) -> Vector4:
	return PANEL_SAFE_INSETS.get(kind, PANEL_SAFE_INSETS[PanelKind.MAIN])


static func create_button_style(
	kind := ButtonKind.SECONDARY,
	state := ButtonState.NORMAL,
	accent := Color.WHITE
) -> StyleBoxTexture:
	var textures: Dictionary = SECONDARY_BUTTON_TEXTURES
	if kind == ButtonKind.PRIMARY:
		textures = PRIMARY_BUTTON_TEXTURES
	elif kind == ButtonKind.TAB:
		textures = TAB_BUTTON_TEXTURES
	var texture := textures.get(state, textures[ButtonState.NORMAL]) as Texture2D
	var top_margin := 9.0
	var bottom_margin := 9.0
	if state == ButtonState.PRESSED:
		top_margin = 11.0
		bottom_margin = 7.0

	var texture_margins := Vector4(42.0, 14.0, 42.0, 14.0)
	var content_margins := Vector4(20.0, top_margin, 20.0, bottom_margin)
	if kind == ButtonKind.TAB:
		texture_margins = Vector4(14.0, 18.0, 14.0, 18.0)
		content_margins = Vector4(6.0, top_margin, 6.0, bottom_margin)
	var style := _create_texture_style(texture, texture_margins, content_margins)
	if kind == ButtonKind.DANGER:
		style.modulate_color = Color(1.0, 0.66, 0.62, 1.0)
	elif kind == ButtonKind.SECONDARY:
		style.modulate_color = _create_subtle_accent_modulate(accent, 0.10)
	return style


static func create_field_style(focused := false) -> StyleBoxTexture:
	var texture: Texture2D = FIELD_FOCUS_TEXTURE if focused else FIELD_NORMAL_TEXTURE
	return _create_texture_style(
		texture,
		Vector4(54.0, 10.0, 54.0, 10.0),
		Vector4(13.0, 7.0, 13.0, 7.0)
	)


static func create_focus_style(accent: Color, radius := 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(accent.r, accent.g, accent.b, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.expand_margin_left = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_bottom = 2.0
	return style


static func _create_texture_style(
	texture: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	return style


static func _create_subtle_accent_modulate(accent: Color, strength := 0.06) -> Color:
	return Color(
		lerpf(1.0, accent.r, strength),
		lerpf(1.0, accent.g, strength),
		lerpf(1.0, accent.b, strength),
		1.0
	)
