extends RefCounted
class_name TokyoGhoulAnimationProvider

# 东京喰种表现只消费 animation key 与卡牌矩形，不读取或修改规则状态。

const TARGETED_KEYS: Array[String] = ["feather_needle", "rc_forced_feeding"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router != null:
		router.register_targeted(TARGETED_KEYS, play_targeted)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	match animation_key:
		"feather_needle":
			if caster_card != null:
				await play_feather_needle(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_card.get_global_rect()
				)
		"rc_forced_feeding":
			await play_forced_feeding(owner, effect_root, target_card.get_global_rect())


func play_feather_needle(owner: Node, effect_root: Control, source_rect: Rect2, target_rect: Rect2) -> void:
	var source_point := source_rect.get_center()
	var target_point := target_rect.get_center()
	var direction := target_point - source_point
	if direction.length() <= 0.01:
		return

	var needles: Array[Panel] = []
	var normal := direction.normalized().orthogonal()
	for index in range(3):
		var offset := normal * float(index - 1) * 8.0
		var needle := create_needle(source_point + offset, target_point + offset)
		effect_root.add_child(needle)
		needles.append(needle)

	var impact := create_impact(target_rect)
	effect_root.add_child(impact)

	var flight := owner.create_tween()
	flight.set_parallel(true)
	flight.set_trans(Tween.TRANS_QUART)
	flight.set_ease(Tween.EASE_IN)
	for needle in needles:
		flight.tween_property(needle, "scale:x", 1.0, spell_animation_duration * 0.70)
		flight.tween_property(needle, "modulate:a", 0.96, spell_animation_duration * 0.24)
	await flight.finished

	var burst := owner.create_tween()
	burst.set_parallel(true)
	burst.set_trans(Tween.TRANS_CUBIC)
	burst.set_ease(Tween.EASE_OUT)
	burst.tween_property(impact, "scale", Vector2(1.62, 1.62), spell_animation_duration * 0.62)
	burst.tween_property(impact, "modulate:a", 0.0, spell_animation_duration * 0.62)
	for needle in needles:
		burst.tween_property(needle, "modulate:a", 0.0, spell_animation_duration * 0.36)
	await burst.finished

	for needle in needles:
		needle.queue_free()
	impact.queue_free()


func play_forced_feeding(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var outer := create_centered_panel(target_rect, "RcFeedingOuter", 1.34, create_feeding_outer_style())
	var core := create_centered_panel(target_rect, "RcFeedingCore", 0.74, create_feeding_core_style())
	var mark := create_feeding_mark(target_rect)
	effect_root.add_child(outer)
	effect_root.add_child(core)
	effect_root.add_child(mark)

	var appear := owner.create_tween()
	appear.set_parallel(true)
	appear.set_trans(Tween.TRANS_BACK)
	appear.set_ease(Tween.EASE_OUT)
	appear.tween_property(outer, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(outer, "modulate:a", 0.92, spell_animation_duration * 0.34)
	appear.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(core, "modulate:a", 0.82, spell_animation_duration * 0.34)
	appear.tween_property(mark, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(mark, "modulate:a", 0.96, spell_animation_duration * 0.34)
	await appear.finished

	var consume := owner.create_tween()
	consume.set_parallel(true)
	consume.set_trans(Tween.TRANS_QUINT)
	consume.set_ease(Tween.EASE_IN)
	consume.tween_property(outer, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.72)
	consume.tween_property(outer, "rotation", 0.55, spell_animation_duration * 0.72)
	consume.tween_property(outer, "modulate:a", 0.0, spell_animation_duration * 0.72)
	consume.tween_property(core, "scale", Vector2(0.08, 0.08), spell_animation_duration * 0.72)
	consume.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.60)
	consume.tween_property(mark, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.72)
	consume.tween_property(mark, "modulate:a", 0.0, spell_animation_duration * 0.58)
	await consume.finished

	outer.queue_free()
	core.queue_free()
	mark.queue_free()


func create_needle(source_point: Vector2, target_point: Vector2) -> Panel:
	var vector := target_point - source_point
	var needle := Panel.new()
	needle.name = "UkakuNeedle"
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	needle.size = Vector2(vector.length(), 6.0)
	needle.pivot_offset = Vector2(0.0, needle.size.y * 0.5)
	needle.global_position = source_point - needle.pivot_offset
	needle.rotation = vector.angle()
	needle.scale = Vector2(0.0, 1.0)
	needle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	needle.z_index = 2320
	needle.add_theme_stylebox_override("panel", create_needle_style())
	return needle


func create_impact(target_rect: Rect2) -> Panel:
	var impact := create_centered_panel(target_rect, "UkakuImpact", 0.36, create_impact_style())
	impact.scale = Vector2(0.42, 0.42)
	impact.modulate = Color(1.0, 1.0, 1.0, 0.92)
	return impact


func create_centered_panel(
	target_rect: Rect2,
	effect_name: String,
	size_multiplier: float,
	style: StyleBoxFlat
) -> Panel:
	var effect := Panel.new()
	effect.name = effect_name
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = target_rect.size * size_multiplier
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = target_rect.get_center() - effect.pivot_offset
	effect.scale = Vector2(0.32, 0.32)
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2318
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_feeding_mark(target_rect: Rect2) -> Label:
	var mark := Label.new()
	mark.name = "RcFeedingMark"
	mark.text = "喰"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = target_rect.size * Vector2(0.72, 0.72)
	mark.pivot_offset = mark.size * 0.5
	mark.global_position = target_rect.get_center() - mark.pivot_offset
	mark.scale = Vector2(0.32, 0.32)
	mark.modulate = Color(1.0, 1.0, 1.0, 0.0)
	mark.z_index = 2322
	mark.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * 0.34), 20))
	mark.add_theme_color_override("font_color", Color(1.0, 0.84, 0.84, 0.96))
	mark.add_theme_color_override("font_shadow_color", Color(0.20, 0.0, 0.04, 0.98))
	mark.add_theme_constant_override("shadow_offset_x", 2)
	mark.add_theme_constant_override("shadow_offset_y", 2)
	return mark


func create_needle_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.94, 0.10, 0.24, 0.92),
		Color(1.0, 0.58, 0.68, 0.98),
		2,
		4,
		Color(0.86, 0.02, 0.18, 0.62),
		14
	)


func create_impact_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.50, 0.0, 0.10, 0.56),
		Color(1.0, 0.32, 0.48, 0.94),
		4,
		999,
		Color(0.94, 0.04, 0.22, 0.72),
		24
	)


func create_feeding_outer_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.08, 0.0, 0.02, 0.58),
		Color(0.72, 0.03, 0.14, 0.90),
		7,
		999,
		Color(0.48, 0.0, 0.08, 0.64),
		34
	)


func create_feeding_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.30, 0.0, 0.06, 0.78),
		Color(1.0, 0.28, 0.36, 0.88),
		3,
		999,
		Color(0.86, 0.02, 0.16, 0.52),
		20
	)


func create_glow_style(
	background: Color,
	border: Color,
	border_width: int,
	corner_radius: int,
	shadow: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
