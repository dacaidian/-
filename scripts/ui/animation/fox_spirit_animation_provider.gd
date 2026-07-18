extends RefCounted
class_name FoxSpiritAnimationProvider

const TARGETED_KEYS: Array[String] = ["sacrifice", "reborn", "soul_hook", "charm"]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const AREA_KEYS: Array[String] = ["foxfire"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_area(AREA_KEYS, play_area)


func play_targeted(
	owner: Node,
	effect_root: Control,
	_caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card != null:
		await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	_source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card != null:
		await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	var theme := _get_theme(animation_key)
	var halo := _create_rect_panel(target_rect, "FoxSpiritHalo", _create_style(
		theme.halo_fill, theme.halo_border, 7, 999, theme.glow, 32
	), float(theme.halo_scale))
	var core := _create_rect_panel(target_rect, "FoxSpiritCore", _create_style(
		theme.core_fill, theme.core_border, 4, int(theme.core_radius), theme.glow, 20
	), float(theme.core_scale))
	var symbol := _create_symbol(target_rect, str(theme.symbol), theme.symbol_color)
	var motes := _create_motes(target_rect, int(theme.mote_count), theme.mote_fill, theme.mote_border, animation_key)

	effect_root.add_child(halo)
	effect_root.add_child(core)
	effect_root.add_child(symbol)
	for mote in motes:
		effect_root.add_child(mote)

	var appear_tween := owner.create_tween()
	appear_tween.set_parallel(true)
	appear_tween.set_trans(Tween.TRANS_BACK)
	appear_tween.set_ease(Tween.EASE_OUT)
	appear_tween.tween_property(halo, "modulate:a", 0.90, spell_animation_duration * 0.38)
	appear_tween.tween_property(halo, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.38)
	appear_tween.tween_property(halo, "rotation", float(theme.rotation) * 0.30, spell_animation_duration * 0.38)
	appear_tween.tween_property(core, "modulate:a", 0.90, spell_animation_duration * 0.38)
	appear_tween.tween_property(core, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.38)
	appear_tween.tween_property(symbol, "modulate:a", 0.98, spell_animation_duration * 0.38)
	for mote in motes:
		appear_tween.tween_property(mote, "modulate:a", 0.88, spell_animation_duration * 0.38)
	await appear_tween.finished

	var dissolve_tween := owner.create_tween()
	dissolve_tween.set_parallel(true)
	dissolve_tween.set_trans(Tween.TRANS_CUBIC)
	dissolve_tween.set_ease(Tween.EASE_OUT)
	dissolve_tween.tween_property(halo, "scale", Vector2(1.72, 1.72), spell_animation_duration * 0.72)
	dissolve_tween.tween_property(halo, "rotation", float(theme.rotation), spell_animation_duration * 0.72)
	dissolve_tween.tween_property(halo, "modulate:a", 0.0, spell_animation_duration * 0.72)
	dissolve_tween.tween_property(core, "scale", Vector2(0.30, 0.30) if bool(theme.collapse) else Vector2(1.58, 1.58), spell_animation_duration * 0.72)
	dissolve_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	dissolve_tween.tween_property(symbol, "global_position", symbol.global_position + Vector2(0.0, -target_rect.size.y * 0.20), spell_animation_duration * 0.72)
	dissolve_tween.tween_property(symbol, "scale", Vector2(1.50, 1.50), spell_animation_duration * 0.72)
	dissolve_tween.tween_property(symbol, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for mote in motes:
		var drift: Vector2 = mote.get_meta("fox_spirit_drift", Vector2.ZERO)
		dissolve_tween.tween_property(mote, "global_position", mote.global_position + drift, spell_animation_duration * 0.72)
		dissolve_tween.tween_property(mote, "scale", Vector2(0.22, 0.22), spell_animation_duration * 0.72)
		dissolve_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await dissolve_tween.finished

	halo.queue_free()
	core.queue_free()
	symbol.queue_free()
	for mote in motes:
		mote.queue_free()


func play_area(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	center_card: Card,
	spell_data: Dictionary,
	animation_key: String
) -> void:
	if animation_key != "foxfire" or owner == null or effect_root == null or caster_card == null or center_card == null:
		return
	var area_rows := int(spell_data.get("area_rows", 2))
	var area_cols := int(spell_data.get("area_cols", 2))
	var caster_start_scale := caster_card.scale
	var caster_start_z_index := caster_card.z_index
	caster_card.is_animating = true
	caster_card.z_index = 1180

	var charge_tween := owner.create_tween()
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(caster_card, "scale", caster_start_scale * 1.06, spell_animation_duration * 0.20)
	await charge_tween.finished

	var area_rect := _get_area_rect(center_card, area_rows, area_cols)
	var field := _create_foxfire_field(area_rect)
	effect_root.add_child(field)
	for index in range(10):
		var flame := _create_flame(index)
		field.add_child(flame)
		var x_ratio := float((index * 37 + 13) % 101) / 100.0
		var y_ratio := float((index * 61 + 29) % 101) / 100.0
		flame.position = Vector2(
			lerpf(10.0, maxf(10.0, area_rect.size.x - 10.0), x_ratio),
			lerpf(10.0, maxf(10.0, area_rect.size.y - 10.0), y_ratio)
		) - flame.pivot_offset

	var pulse_tween := owner.create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(field, "modulate:a", 0.94, spell_animation_duration * 0.24)
	pulse_tween.tween_property(field, "scale", Vector2(1.05, 1.05), spell_animation_duration * 0.30)
	await owner.create_tween().tween_interval(spell_animation_duration * 0.42).finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(field, "modulate:a", 0.0, spell_animation_duration * 0.34)
	fade_tween.tween_property(field, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.34)
	fade_tween.tween_property(caster_card, "scale", caster_start_scale, spell_animation_duration * 0.34)
	await fade_tween.finished

	field.queue_free()
	caster_card.scale = caster_start_scale
	caster_card.z_index = caster_start_z_index
	caster_card.is_animating = false


func _get_area_rect(anchor_card: Card, area_rows: int, area_cols: int) -> Rect2:
	var anchor_rect := anchor_card.get_global_rect()
	var area_size := Vector2(anchor_card.size.x * area_cols, anchor_card.size.y * area_rows)
	if area_rows % 2 == 0 or area_cols % 2 == 0:
		return Rect2(anchor_rect.position, area_size)
	return Rect2(anchor_rect.get_center() - area_size * 0.5, area_size)


func _create_foxfire_field(area_rect: Rect2) -> Panel:
	var field := Panel.new()
	field.name = "FoxfireAreaEffect"
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.size = area_rect.size
	field.pivot_offset = field.size * 0.5
	field.global_position = area_rect.get_center() - field.pivot_offset
	field.modulate = Color(1.0, 1.0, 1.0, 0.0)
	field.z_index = 2260
	field.add_theme_stylebox_override("panel", _create_style(
		Color(0.72, 0.10, 0.82, 0.20), Color(1.0, 0.48, 0.96, 0.78), 5, 10,
		Color(0.82, 0.12, 1.0, 0.52), 34
	))
	return field


func _create_flame(index: int) -> Panel:
	var flame := Panel.new()
	flame.name = "FoxfireFlame_%d" % index
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flame_size := Vector2(15.0 + float(index % 3) * 3.0, 15.0 + float(index % 3) * 3.0)
	flame.size = flame_size
	flame.pivot_offset = flame_size * 0.5
	flame.rotation = -0.22 + 0.08 * float(index % 6)
	flame.z_index = 2262
	flame.add_theme_stylebox_override("panel", _create_style(
		Color(0.98, 0.34, 0.96, 0.78), Color(1.0, 0.84, 1.0, 0.94), 2, 999,
		Color(0.76, 0.06, 1.0, 0.64), 14
	))
	return flame


func _create_rect_panel(target_rect: Rect2, node_name: String, style: StyleBoxFlat, size_multiplier: float) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = target_rect.size * size_multiplier
	panel.pivot_offset = panel.size * 0.5
	panel.global_position = target_rect.get_center() - panel.pivot_offset
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.z_index = 2300
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_symbol(target_rect: Rect2, text: String, color: Color) -> Label:
	var label := Label.new()
	label.name = "FoxSpiritSymbol"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size = target_rect.size * 0.48
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2310
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * 0.35), 18))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.0, 0.16, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _create_motes(target_rect: Rect2, count: int, fill: Color, border: Color, animation_key: String) -> Array[Panel]:
	var motes: Array[Panel] = []
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) - PI * 0.5
		var mote := Panel.new()
		mote.name = "FoxSpiritMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var width := 8.0 + float(index % 3) * 3.0
		mote.size = Vector2(width, width * (1.5 if animation_key == "soul_hook" else 1.0))
		mote.pivot_offset = mote.size * 0.5
		mote.global_position = target_rect.get_center() - mote.pivot_offset
		mote.rotation = angle
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2308
		mote.add_theme_stylebox_override("panel", _create_style(fill, border, 2, 999, border * Color(1.0, 1.0, 1.0, 0.44), 10))
		mote.set_meta("fox_spirit_drift", Vector2(cos(angle), sin(angle)) * target_rect.size.x * (0.46 + 0.04 * float(index % 2)))
		motes.append(mote)
	return motes


func _create_style(fill: Color, border: Color, width: int, radius: int, shadow: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style


func _get_theme(animation_key: String) -> Dictionary:
	match animation_key:
		"sacrifice":
			return _theme("祭", Color(0.28, 0.01, 0.08, 0.22), Color(1.0, 0.30, 0.58, 0.92), Color(0.68, 0.03, 0.18, 0.66), Color(1.0, 0.54, 0.72, 0.98), true, 10)
		"reborn":
			return _theme("生", Color(0.34, 0.12, 0.02, 0.20), Color(1.0, 0.72, 0.24, 0.92), Color(0.84, 0.36, 0.04, 0.64), Color(1.0, 0.88, 0.48, 0.98), false, 12)
		"soul_hook":
			return _theme("魄", Color(0.18, 0.01, 0.26, 0.24), Color(0.82, 0.28, 1.0, 0.92), Color(0.46, 0.04, 0.64, 0.68), Color(0.94, 0.62, 1.0, 0.98), true, 9)
		_:
			return _theme("魅", Color(0.30, 0.02, 0.26, 0.22), Color(1.0, 0.34, 0.90, 0.92), Color(0.72, 0.06, 0.58, 0.66), Color(1.0, 0.66, 0.96, 0.98), false, 10)


func _theme(symbol: String, halo_fill: Color, halo_border: Color, core_fill: Color, symbol_color: Color, collapse: bool, mote_count: int) -> Dictionary:
	return {
		"symbol": symbol,
		"symbol_color": symbol_color,
		"halo_fill": halo_fill,
		"halo_border": halo_border,
		"halo_scale": 1.28,
		"core_fill": core_fill,
		"core_border": symbol_color,
		"core_scale": 0.58,
		"core_radius": 999,
		"glow": Color(halo_border.r, halo_border.g, halo_border.b, 0.48),
		"mote_fill": Color(core_fill.r, core_fill.g, core_fill.b, 0.88),
		"mote_border": symbol_color,
		"mote_count": mote_count,
		"rotation": 0.64 if collapse else -0.52,
		"collapse": collapse
	}
