extends RefCounted
class_name MonkeyAnimationProvider

const TARGETED_KEYS: Array[String] = [
	"fiery_eyes_golden_gaze",
	"somersault_cloud",
	"body_beyond_body",
	"bronze_head_iron_arms",
	"immortal_peach",
	"drive_spirit",
	"immobilize",
	"gather_scatter_qi",
	"heavenly_form",
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)


func play_targeted(
	owner: Node,
	effect_root: Control,
	_caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	_source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var palette := get_palette(animation_key)
	var aura := create_panel(
		target_rect,
		"MonkeySpellAura",
		create_style(palette.aura_fill, palette.aura_border, 7, palette.corner_radius, palette.glow, 34),
		1.22,
		2300
	)
	var core := create_panel(
		target_rect,
		"MonkeySpellCore",
		create_style(palette.core_fill, palette.core_border, 4, palette.corner_radius, palette.glow, 24),
		get_core_size(animation_key),
		2310
	)
	var symbol := create_symbol(target_rect, animation_key, palette)
	var accents := create_accents(target_rect, animation_key, palette)
	effect_root.add_child(aura)
	effect_root.add_child(core)
	effect_root.add_child(symbol)
	for accent in accents:
		effect_root.add_child(accent)

	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_SINE)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(aura, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.38)
	rise.tween_property(aura, "modulate:a", 0.86, spell_animation_duration * 0.38)
	rise.tween_property(aura, "rotation", get_rotation(animation_key) * 0.35, spell_animation_duration * 0.38)
	rise.tween_property(core, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.38)
	rise.tween_property(core, "modulate:a", 0.94, spell_animation_duration * 0.38)
	rise.tween_property(symbol, "scale", Vector2(1.14, 1.14), spell_animation_duration * 0.38)
	rise.tween_property(symbol, "modulate:a", 0.98, spell_animation_duration * 0.38)
	for accent in accents:
		rise.tween_property(accent, "modulate:a", 0.88, spell_animation_duration * 0.38)
		rise.tween_property(accent, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.38)
	await rise.finished

	var fade := owner.create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN)
	fade.tween_property(aura, "scale", Vector2(1.78, 1.78), spell_animation_duration * 0.72)
	fade.tween_property(aura, "rotation", get_rotation(animation_key), spell_animation_duration * 0.72)
	fade.tween_property(aura, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade.tween_property(core, "scale", get_core_fade_scale(animation_key), spell_animation_duration * 0.72)
	fade.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade.tween_property(symbol, "position", symbol.position + get_symbol_drift(target_rect, animation_key), spell_animation_duration * 0.72)
	fade.tween_property(symbol, "scale", get_symbol_fade_scale(animation_key), spell_animation_duration * 0.72)
	fade.tween_property(symbol, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for index in range(accents.size()):
		var accent := accents[index]
		fade.tween_property(accent, "position", accent.position + get_accent_drift(target_rect, animation_key, index), spell_animation_duration * 0.72)
		fade.tween_property(accent, "scale", get_accent_fade_scale(animation_key, index), spell_animation_duration * 0.72)
		fade.tween_property(accent, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await fade.finished

	aura.queue_free()
	core.queue_free()
	symbol.queue_free()
	for accent in accents:
		accent.queue_free()


func create_symbol(target_rect: Rect2, animation_key: String, palette: Dictionary) -> Label:
	var label := Label.new()
	label.name = "MonkeySpellSymbol"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = get_symbol(animation_key)
	var size_multiplier := 0.92 if animation_key == "heavenly_form" else (0.66 if animation_key == "immobilize" else 0.58)
	label.size = target_rect.size * size_multiplier
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2350
	var font_scale := 0.56 if animation_key == "heavenly_form" else (0.42 if animation_key == "immobilize" else 0.36)
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * font_scale), 20))
	label.add_theme_color_override("font_color", palette.symbol)
	label.add_theme_color_override("font_shadow_color", palette.shadow)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func create_accents(target_rect: Rect2, animation_key: String, palette: Dictionary) -> Array[Control]:
	var accents: Array[Control] = []
	var count := get_accent_count(animation_key)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) - PI * 0.5
		var radial_offset := Vector2(cos(angle), sin(angle)) * target_rect.size.x * get_accent_radius(animation_key)
		var size_multiplier := get_accent_size(animation_key, index)
		var accent := create_panel(
			target_rect,
			"MonkeyAccent_%d" % index,
			create_style(palette.accent_fill, palette.accent_border, 2, 999, palette.glow, 14),
			1.0,
			2340
		)
		accent.size = Vector2(target_rect.size.x * size_multiplier.x, target_rect.size.y * size_multiplier.y)
		accent.pivot_offset = accent.size * 0.5
		accent.global_position = target_rect.get_center() + radial_offset - accent.pivot_offset
		accent.rotation = angle + PI * 0.5
		accents.append(accent)
	return accents


func create_panel(
	target_rect: Rect2,
	panel_name: String,
	style: StyleBoxFlat,
	size_multiplier: float,
	z_index: int
) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = target_rect.size * size_multiplier
	panel.pivot_offset = panel.size * 0.5
	panel.global_position = target_rect.get_center() - panel.pivot_offset
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.z_index = z_index
	panel.add_theme_stylebox_override("panel", style)
	return panel


func create_style(
	bg_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_color: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	return style


func get_palette(animation_key: String) -> Dictionary:
	match animation_key:
		"somersault_cloud", "gather_scatter_qi":
			return create_palette(Color(0.62, 0.86, 1.0, 0.18), Color(1.0, 0.96, 0.70, 0.76), Color(0.90, 0.98, 1.0, 0.70), Color(0.92, 0.98, 1.0, 0.96), Color(0.05, 0.18, 0.28, 0.86))
		"immortal_peach":
			return create_palette(Color(1.0, 0.36, 0.54, 0.16), Color(1.0, 0.84, 0.54, 0.84), Color(1.0, 0.50, 0.66, 0.70), Color(1.0, 0.84, 0.58, 0.98), Color(0.28, 0.04, 0.12, 0.84))
		"drive_spirit":
			return create_palette(Color(0.34, 0.74, 0.68, 0.14), Color(1.0, 0.92, 0.42, 0.82), Color(0.98, 0.86, 0.34, 0.42), Color(1.0, 0.94, 0.52, 0.98), Color(0.14, 0.06, 0.02, 0.88))
		"bronze_head_iron_arms":
			return create_palette(Color(0.50, 0.28, 0.12, 0.20), Color(1.0, 0.72, 0.30, 0.86), Color(0.78, 0.48, 0.20, 0.48), Color(1.0, 0.76, 0.34, 0.98), Color(0.24, 0.08, 0.02, 0.88))
		"immobilize":
			return create_palette(Color(0.76, 0.34, 0.02, 0.20), Color(1.0, 0.84, 0.22, 0.92), Color(1.0, 0.64, 0.06, 0.46), Color(1.0, 0.88, 0.30, 0.98), Color(0.24, 0.08, 0.02, 0.88))
		_:
			return create_palette(Color(1.0, 0.58, 0.08, 0.16), Color(1.0, 0.90, 0.34, 0.92), Color(1.0, 0.68, 0.14, 0.42), Color(1.0, 0.88, 0.30, 0.98), Color(0.24, 0.08, 0.02, 0.88))


func create_palette(aura_fill: Color, aura_border: Color, core_fill: Color, symbol: Color, shadow: Color) -> Dictionary:
	return {
		"aura_fill": aura_fill,
		"aura_border": aura_border,
		"core_fill": core_fill,
		"core_border": aura_border.lightened(0.18),
		"accent_fill": core_fill,
		"accent_border": aura_border,
		"symbol": symbol,
		"shadow": shadow,
		"glow": aura_border.darkened(0.12),
		"corner_radius": 12 if aura_fill.r > 0.9 else 999,
	}


func get_symbol(animation_key: String) -> String:
	match animation_key:
		"fiery_eyes_golden_gaze": return "眼"
		"somersault_cloud": return "云"
		"body_beyond_body": return "毫"
		"bronze_head_iron_arms": return "铁"
		"immortal_peach": return "桃"
		"drive_spirit": return "敕"
		"immobilize": return "定"
		"gather_scatter_qi": return "气"
		"heavenly_form": return "法"
		_: return "猿"


func get_core_size(animation_key: String) -> float:
	if animation_key == "heavenly_form": return 0.82
	if animation_key in ["bronze_head_iron_arms", "immobilize"]: return 0.66
	if animation_key == "somersault_cloud": return 0.74
	return 0.54


func get_rotation(animation_key: String) -> float:
	match animation_key:
		"somersault_cloud": return 0.58
		"body_beyond_body": return -0.82
		"gather_scatter_qi": return 0.72
		"heavenly_form": return 0.12
		_: return 0.36


func get_accent_count(animation_key: String) -> int:
	match animation_key:
		"body_beyond_body": return 7
		"bronze_head_iron_arms": return 8
		"gather_scatter_qi": return 6
		"heavenly_form": return 4
		_: return 5


func get_accent_radius(animation_key: String) -> float:
	return 0.34 if animation_key in ["heavenly_form", "bronze_head_iron_arms"] else 0.28


func get_accent_size(animation_key: String, index: int) -> Vector2:
	if animation_key == "body_beyond_body": return Vector2(0.035, 0.18)
	if animation_key == "heavenly_form": return Vector2(0.055, 0.72)
	if animation_key == "immobilize": return Vector2(0.58, 0.035)
	return Vector2(0.12 + float(index % 3) * 0.025, 0.045)


func get_core_fade_scale(animation_key: String) -> Vector2:
	if animation_key == "gather_scatter_qi": return Vector2(0.34, 0.34)
	if animation_key == "heavenly_form": return Vector2(1.46, 1.46)
	return Vector2(1.36, 1.36)


func get_symbol_fade_scale(animation_key: String) -> Vector2:
	if animation_key in ["gather_scatter_qi", "body_beyond_body"]: return Vector2(0.45, 0.45)
	if animation_key == "heavenly_form": return Vector2(1.34, 1.34)
	return Vector2(0.74, 0.74)


func get_symbol_drift(target_rect: Rect2, animation_key: String) -> Vector2:
	if animation_key == "somersault_cloud": return Vector2(target_rect.size.x * 0.24, -target_rect.size.y * 0.16)
	if animation_key == "gather_scatter_qi": return Vector2(0.0, -target_rect.size.y * 0.24)
	if animation_key == "heavenly_form": return Vector2(0.0, -target_rect.size.y * 0.08)
	return Vector2.ZERO


func get_accent_drift(target_rect: Rect2, animation_key: String, index: int) -> Vector2:
	var count := get_accent_count(animation_key)
	var angle := TAU * float(index) / float(maxi(count, 1)) - PI * 0.5
	if animation_key == "gather_scatter_qi": return Vector2(0.0, -target_rect.size.y * 0.28)
	if animation_key == "somersault_cloud": return Vector2(target_rect.size.x * 0.22, -target_rect.size.y * 0.14)
	return Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.16


func get_accent_fade_scale(animation_key: String, index: int) -> Vector2:
	if animation_key in ["gather_scatter_qi", "body_beyond_body"]: return Vector2(0.28, 0.28)
	if animation_key == "heavenly_form": return Vector2(1.24 + float(index) * 0.08, 1.24 + float(index) * 0.08)
	if animation_key == "immobilize": return Vector2(1.36, 1.08)
	return Vector2(1.42, 1.42)
