extends RefCounted
class_name MiaoAnimationProvider

const TARGETED_KEYS: Array[String] = [
	"medical_practice", "gu_infusion", "gu_lure", "gu_life_link_larva",
	"gu_life_link", "thin_burial", "gu_summon", "gu_trap_trigger"
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
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	if animation_key == "gu_infusion" and caster_card != null:
		await _play_gu_projectile(owner, effect_root, caster_card.get_global_rect().get_center(), target_card)
	else:
		await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	if animation_key == "gu_infusion":
		await _play_gu_projectile(owner, effect_root, source_rect.get_center(), target_card)
	else:
		await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	var theme := _get_theme(animation_key)
	var outer := _create_rect_panel(target_rect, "MiaoOuter", _create_style(
		theme.outer_fill, theme.outer_border, 6, int(theme.corner_radius), theme.glow, 28
	), float(theme.outer_scale))
	var inner := _create_rect_panel(target_rect, "MiaoInner", _create_style(
		theme.inner_fill, theme.inner_border, 3, int(theme.inner_radius), theme.glow, 18
	), float(theme.inner_scale))
	var symbol := _create_symbol(target_rect, str(theme.symbol), theme.symbol_color)
	var motes := _create_motes(target_rect, int(theme.mote_count), theme.mote_fill, theme.mote_border)

	effect_root.add_child(outer)
	effect_root.add_child(inner)
	effect_root.add_child(symbol)
	for mote in motes:
		effect_root.add_child(mote)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_BACK)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(outer, "modulate:a", 0.90, spell_animation_duration * 0.38)
	bind_tween.tween_property(outer, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.38)
	bind_tween.tween_property(outer, "rotation", float(theme.rotation) * 0.32, spell_animation_duration * 0.38)
	bind_tween.tween_property(inner, "modulate:a", 0.88, spell_animation_duration * 0.38)
	bind_tween.tween_property(inner, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.38)
	bind_tween.tween_property(symbol, "modulate:a", 0.96, spell_animation_duration * 0.38)
	for mote in motes:
		bind_tween.tween_property(mote, "modulate:a", 0.86, spell_animation_duration * 0.38)
	await bind_tween.finished

	var release_tween := owner.create_tween()
	release_tween.set_parallel(true)
	release_tween.set_trans(Tween.TRANS_CUBIC)
	release_tween.set_ease(Tween.EASE_OUT)
	release_tween.tween_property(outer, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.70)
	release_tween.tween_property(outer, "rotation", float(theme.rotation), spell_animation_duration * 0.70)
	release_tween.tween_property(outer, "modulate:a", 0.0, spell_animation_duration * 0.70)
	release_tween.tween_property(inner, "scale", Vector2(0.34, 0.34) if bool(theme.collapse) else Vector2(1.56, 1.56), spell_animation_duration * 0.70)
	release_tween.tween_property(inner, "modulate:a", 0.0, spell_animation_duration * 0.70)
	release_tween.tween_property(symbol, "global_position", symbol.global_position + Vector2(0.0, -target_rect.size.y * 0.16), spell_animation_duration * 0.70)
	release_tween.tween_property(symbol, "scale", Vector2(1.48, 1.48), spell_animation_duration * 0.70)
	release_tween.tween_property(symbol, "modulate:a", 0.0, spell_animation_duration * 0.70)
	for mote in motes:
		var drift: Vector2 = mote.get_meta("miao_drift", Vector2.ZERO)
		release_tween.tween_property(mote, "global_position", mote.global_position + drift, spell_animation_duration * 0.70)
		release_tween.tween_property(mote, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.70)
		release_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.70)
	await release_tween.finished

	outer.queue_free()
	inner.queue_free()
	symbol.queue_free()
	for mote in motes:
		mote.queue_free()


func play_life_link(
	owner: Node,
	effect_root: Control,
	first_card: Card,
	second_card: Card,
	spell_data: Dictionary
) -> void:
	if owner == null or effect_root == null or first_card == null or second_card == null:
		return
	var animation_key := str(spell_data.get("animation", "gu_life_link"))
	var is_larva := animation_key == "gu_life_link_larva"
	var first_rect := first_card.get_global_rect()
	var second_rect := second_card.get_global_rect()
	var link_color := Color(0.92, 0.78, 0.16, 0.0) if is_larva else Color(0.50, 1.0, 0.24, 0.0)
	var tether := Line2D.new()
	tether.name = "GuLifeLinkTether"
	tether.width = 4.5 if is_larva else 7.0
	tether.default_color = link_color
	tether.z_index = 2310
	tether.points = PackedVector2Array([first_rect.get_center(), second_rect.get_center()])
	tether.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tether.end_cap_mode = Line2D.LINE_CAP_ROUND
	var first_ring := _create_link_ring(first_rect, is_larva)
	var second_ring := _create_link_ring(second_rect, is_larva)
	effect_root.add_child(tether)
	effect_root.add_child(first_ring)
	effect_root.add_child(second_ring)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_SINE)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(tether, "default_color:a", 0.88, spell_animation_duration * 0.36)
	bind_tween.tween_property(first_ring, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	bind_tween.tween_property(first_ring, "modulate:a", 0.92, spell_animation_duration * 0.36)
	bind_tween.tween_property(second_ring, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	bind_tween.tween_property(second_ring, "modulate:a", 0.92, spell_animation_duration * 0.36)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(tether, "width", 2.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(tether, "default_color:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(first_ring, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.64)
	fade_tween.tween_property(first_ring, "modulate:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(second_ring, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.64)
	fade_tween.tween_property(second_ring, "modulate:a", 0.0, spell_animation_duration * 0.64)
	await fade_tween.finished

	tether.queue_free()
	first_ring.queue_free()
	second_ring.queue_free()


func _play_gu_projectile(owner: Node, effect_root: Control, source_point: Vector2, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return
	var target_point := target_card.get_global_rect().get_center()
	var direction := (target_point - source_point).normalized()
	if direction == Vector2.ZERO:
		await play_at_rect(owner, effect_root, target_card.get_global_rect(), "gu_infusion")
		return
	var perpendicular := Vector2(-direction.y, direction.x)
	var worms: Array[Panel] = []
	for index in range(5):
		var worm := Panel.new()
		worm.name = "GuProjectile_%d" % index
		worm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		worm.size = Vector2(18.0, 10.0)
		worm.pivot_offset = worm.size * 0.5
		worm.global_position = source_point + perpendicular * ((float(index) - 2.0) * 8.0) - worm.pivot_offset
		worm.rotation = direction.angle() + sin(float(index)) * 0.28
		worm.z_index = 2320
		worm.add_theme_stylebox_override("panel", _create_style(Color(0.09, 0.28, 0.08, 0.94), Color(0.54, 1.0, 0.20, 0.86), 2, 999, Color(0.34, 0.86, 0.14, 0.46), 12))
		effect_root.add_child(worm)
		worms.append(worm)
		var flight := owner.create_tween()
		flight.set_parallel(true)
		flight.set_trans(Tween.TRANS_CUBIC)
		flight.set_ease(Tween.EASE_IN_OUT)
		flight.tween_property(worm, "global_position", target_point + perpendicular * ((float(index) - 2.0) * 1.8) - worm.pivot_offset, spell_animation_duration * 0.62)
		flight.tween_property(worm, "rotation", worm.rotation + 0.75 + float(index) * 0.10, spell_animation_duration * 0.62)
	await owner.create_tween().tween_interval(spell_animation_duration * 0.62).finished
	await play_at_rect(owner, effect_root, target_card.get_global_rect(), "gu_infusion")
	for worm in worms:
		worm.queue_free()


func _create_link_ring(target_rect: Rect2, is_larva: bool) -> Panel:
	var style := _create_style(
		Color(0.44, 0.30, 0.02, 0.24) if is_larva else Color(0.14, 0.42, 0.04, 0.22),
		Color(0.96, 0.80, 0.18, 0.92) if is_larva else Color(0.56, 1.0, 0.28, 0.94),
		6, 999,
		Color(0.86, 0.58, 0.06, 0.46) if is_larva else Color(0.34, 0.84, 0.16, 0.48), 24
	)
	return _create_rect_panel(target_rect, "GuLifeLinkRing", style, 1.16)


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
	label.name = "MiaoSymbol"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size = target_rect.size * 0.46
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2310
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * 0.34), 18))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _create_motes(target_rect: Rect2, count: int, fill_color: Color, border_color: Color) -> Array[Panel]:
	var motes: Array[Panel] = []
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1))
		var mote := Panel.new()
		mote.name = "MiaoMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = Vector2(7.0 + float(index % 3) * 3.0, 7.0 + float(index % 3) * 3.0)
		mote.pivot_offset = mote.size * 0.5
		mote.global_position = target_rect.get_center() - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2308
		mote.add_theme_stylebox_override("panel", _create_style(fill_color, border_color, 2, 999, border_color * Color(1.0, 1.0, 1.0, 0.45), 10))
		mote.set_meta("miao_drift", Vector2(cos(angle), sin(angle)) * target_rect.size.x * (0.46 + 0.04 * float(index % 2)))
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
		"medical_practice":
			return _theme("医", Color(0.04, 0.20, 0.10, 0.18), Color(0.42, 1.0, 0.52, 0.86), Color(0.10, 0.50, 0.22, 0.52), Color(0.72, 1.0, 0.68, 0.98), false, 8)
		"gu_lure":
			return _theme("诱", Color(0.04, 0.22, 0.02, 0.22), Color(0.52, 1.0, 0.20, 0.90), Color(0.14, 0.44, 0.04, 0.64), Color(0.78, 1.0, 0.34, 0.98), false, 9)
		"gu_life_link_larva":
			return _theme("幼", Color(0.24, 0.16, 0.01, 0.22), Color(0.96, 0.78, 0.16, 0.90), Color(0.46, 0.30, 0.02, 0.62), Color(1.0, 0.88, 0.36, 0.98), true, 7)
		"gu_life_link":
			return _theme("蛊", Color(0.06, 0.22, 0.02, 0.22), Color(0.56, 1.0, 0.24, 0.92), Color(0.16, 0.48, 0.04, 0.64), Color(0.76, 1.0, 0.38, 0.98), false, 8)
		"thin_burial":
			return _theme("葬", Color(0.08, 0.08, 0.08, 0.26), Color(0.72, 0.82, 0.66, 0.86), Color(0.20, 0.24, 0.18, 0.62), Color(0.88, 0.96, 0.82, 0.98), true, 6)
		"gu_summon":
			return _theme("生", Color(0.03, 0.18, 0.01, 0.24), Color(0.64, 1.0, 0.18, 0.92), Color(0.12, 0.42, 0.02, 0.68), Color(0.82, 1.0, 0.32, 0.98), false, 12)
		"gu_trap_trigger":
			return _theme("噬", Color(0.20, 0.01, 0.04, 0.26), Color(0.94, 0.18, 0.34, 0.94), Color(0.48, 0.02, 0.08, 0.70), Color(1.0, 0.38, 0.48, 0.98), true, 10)
		_:
			return _theme("励", Color(0.03, 0.18, 0.02, 0.22), Color(0.50, 1.0, 0.20, 0.90), Color(0.12, 0.38, 0.03, 0.66), Color(0.72, 1.0, 0.30, 0.98), false, 8)


func _theme(symbol: String, outer_fill: Color, outer_border: Color, inner_fill: Color, symbol_color: Color, collapse: bool, mote_count: int) -> Dictionary:
	return {
		"symbol": symbol,
		"symbol_color": symbol_color,
		"outer_fill": outer_fill,
		"outer_border": outer_border,
		"outer_scale": 1.24,
		"corner_radius": 999,
		"inner_fill": inner_fill,
		"inner_border": symbol_color,
		"inner_scale": 0.64,
		"inner_radius": 999,
		"glow": Color(outer_border.r, outer_border.g, outer_border.b, 0.46),
		"mote_fill": Color(inner_fill.r, inner_fill.g, inner_fill.b, 0.88),
		"mote_border": symbol_color,
		"mote_count": mote_count,
		"rotation": 0.62 if collapse else -0.48,
		"collapse": collapse
	}
