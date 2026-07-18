extends RefCounted
class_name BeastmenAnimationProvider

const TARGETED_KEYS: Array[String] = [
	"beastmen_evolution", "beastmen_slaughter", "wanmo_charge",
	"savage_roar", "wild_call", "beast_path", "wanmo_ritual"
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const BOARD_KEYS: Array[String] = ["chaos_corruption_burst"]
const PATH_KEYS: Array[String] = ["beast_path"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)
	router.register_path(PATH_KEYS, play_path)


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

	var theme := _get_local_theme(animation_key)
	var aura := _create_rect_panel(
		target_rect,
		"BeastmenAura",
		_create_style(theme.aura_fill, theme.aura_border, 7, 999, theme.glow, 34),
		float(theme.aura_scale)
	)
	var core := _create_rect_panel(
		target_rect,
		"BeastmenCore",
		_create_style(theme.core_fill, theme.core_border, 4, int(theme.core_radius), theme.glow, 22),
		float(theme.core_scale)
	)
	var sigil := _create_sigil(target_rect, str(theme.symbol), theme.symbol_color, float(theme.symbol_scale))
	var shards := _create_radial_shards(target_rect, int(theme.shard_count), theme.shard_fill, theme.shard_border)

	effect_root.add_child(aura)
	effect_root.add_child(core)
	effect_root.add_child(sigil)
	for shard in shards:
		effect_root.add_child(shard)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(aura, "modulate:a", 0.92, spell_animation_duration * 0.34)
	rise_tween.tween_property(aura, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.34)
	rise_tween.tween_property(aura, "rotation", float(theme.rotation) * 0.35, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "modulate:a", 0.92, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "modulate:a", 0.98, spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "scale", Vector2(1.14, 1.14), spell_animation_duration * 0.34)
	for shard in shards:
		rise_tween.tween_property(shard, "modulate:a", 0.88, spell_animation_duration * 0.34)
	await rise_tween.finished

	var release_tween := owner.create_tween()
	release_tween.set_parallel(true)
	release_tween.set_trans(Tween.TRANS_CUBIC)
	release_tween.set_ease(Tween.EASE_OUT)
	release_tween.tween_property(aura, "scale", Vector2(1.78, 1.78), spell_animation_duration * 0.76)
	release_tween.tween_property(aura, "rotation", float(theme.rotation), spell_animation_duration * 0.76)
	release_tween.tween_property(aura, "modulate:a", 0.0, spell_animation_duration * 0.76)
	release_tween.tween_property(core, "scale", Vector2(0.34, 0.34) if bool(theme.collapse) else Vector2(1.72, 1.72), spell_animation_duration * 0.76)
	release_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.76)
	release_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.20), spell_animation_duration * 0.76)
	release_tween.tween_property(sigil, "scale", Vector2(1.58, 1.58), spell_animation_duration * 0.76)
	release_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.76)
	for shard in shards:
		var drift: Vector2 = shard.get_meta("beastmen_drift", Vector2.ZERO)
		release_tween.tween_property(shard, "global_position", shard.global_position + drift, spell_animation_duration * 0.76)
		release_tween.tween_property(shard, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.76)
		release_tween.tween_property(shard, "modulate:a", 0.0, spell_animation_duration * 0.76)
	await release_tween.finished

	aura.queue_free()
	core.queue_free()
	sigil.queue_free()
	for shard in shards:
		shard.queue_free()


func play_board(owner: Node, effect_root: Control, animation_key: String) -> void:
	if animation_key != "chaos_corruption_burst":
		return
	await _play_chaos_corruption_board_burst(owner, effect_root)


func play_path(owner: Node, effect_root: Control, target_rects: Array[Rect2], animation_key: String) -> void:
	if animation_key != "beast_path" or owner == null or effect_root == null or target_rects.is_empty():
		return

	var segments: Array[Panel] = []
	var sigils: Array[Label] = []
	for index in range(target_rects.size()):
		var rect := target_rects[index]
		if rect.size == Vector2.ZERO:
			continue
		var segment := _create_rect_panel(
			rect,
			"BeastPathSegment_%d" % index,
			_create_beast_path_segment_style(index),
			1.12
		)
		var sigil := _create_sigil(rect, "径", Color(0.94, 0.74, 0.34, 0.98), 0.34)
		segment.z_index = 2260
		sigil.z_index = 2268
		effect_root.add_child(segment)
		effect_root.add_child(sigil)
		segments.append(segment)
		sigils.append(sigil)

	var dig_tween := owner.create_tween()
	dig_tween.set_parallel(true)
	dig_tween.set_trans(Tween.TRANS_BACK)
	dig_tween.set_ease(Tween.EASE_OUT)
	for index in range(segments.size()):
		var delay := spell_animation_duration * 0.08 * float(index)
		dig_tween.tween_property(segments[index], "modulate:a", 0.94, spell_animation_duration * 0.28).set_delay(delay)
		dig_tween.tween_property(segments[index], "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.28).set_delay(delay)
		dig_tween.tween_property(sigils[index], "modulate:a", 0.92, spell_animation_duration * 0.28).set_delay(delay)
	await dig_tween.finished

	var settle_tween := owner.create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_SINE)
	settle_tween.set_ease(Tween.EASE_IN_OUT)
	for index in range(segments.size()):
		settle_tween.tween_property(segments[index], "scale", Vector2(1.30, 1.30), spell_animation_duration * 0.62)
		settle_tween.tween_property(segments[index], "modulate:a", 0.0, spell_animation_duration * 0.62)
		settle_tween.tween_property(sigils[index], "global_position", sigils[index].global_position + Vector2(0.0, -target_rects[index].size.y * 0.12), spell_animation_duration * 0.62)
		settle_tween.tween_property(sigils[index], "modulate:a", 0.0, spell_animation_duration * 0.62)
	await settle_tween.finished

	for segment in segments:
		segment.queue_free()
	for sigil in sigils:
		sigil.queue_free()


func _play_chaos_corruption_board_burst(owner: Node, effect_root: Control) -> void:
	if owner == null or effect_root == null:
		return
	var viewport_size := effect_root.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var veil := ColorRect.new()
	veil.name = "ChaosCorruptionVeil"
	veil.color = Color(0.14, 0.025, 0.0, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 2280

	var pulse := Panel.new()
	pulse.name = "ChaosCorruptionBoardPulse"
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.size = viewport_size * 0.72
	pulse.pivot_offset = pulse.size * 0.5
	pulse.position = (viewport_size - pulse.size) * 0.5
	pulse.modulate = Color(1.0, 1.0, 1.0, 0.0)
	pulse.z_index = 2290
	pulse.add_theme_stylebox_override("panel", _create_style(
		Color(0.28, 0.04, 0.0, 0.20), Color(0.92, 0.22, 0.04, 0.78), 10, 999,
		Color(0.72, 0.08, 0.0, 0.54), 54
	))

	var sigil := _create_centered_label(viewport_size * 0.5, Vector2(220.0, 220.0), "蚀", 132, Color(0.90, 0.12, 0.03, 0.97))
	sigil.name = "ChaosCorruptionBoardSigil"
	sigil.z_index = 2298
	var motes := _create_board_motes(viewport_size)

	effect_root.add_child(veil)
	effect_root.add_child(pulse)
	effect_root.add_child(sigil)
	for mote in motes:
		effect_root.add_child(mote)

	var surge_tween := owner.create_tween()
	surge_tween.set_parallel(true)
	surge_tween.set_trans(Tween.TRANS_CUBIC)
	surge_tween.set_ease(Tween.EASE_OUT)
	surge_tween.tween_property(veil, "color:a", 0.30, spell_animation_duration * 0.42)
	surge_tween.tween_property(pulse, "modulate:a", 0.86, spell_animation_duration * 0.42)
	surge_tween.tween_property(pulse, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.42)
	surge_tween.tween_property(sigil, "modulate:a", 0.94, spell_animation_duration * 0.42)
	surge_tween.tween_property(sigil, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.42)
	for mote in motes:
		surge_tween.tween_property(mote, "modulate:a", 0.82, spell_animation_duration * 0.42)
	await surge_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(veil, "color:a", 0.0, spell_animation_duration * 0.92)
	fade_tween.tween_property(pulse, "scale", Vector2(1.58, 1.58), spell_animation_duration * 0.92)
	fade_tween.tween_property(pulse, "modulate:a", 0.0, spell_animation_duration * 0.92)
	fade_tween.tween_property(sigil, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.92)
	fade_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.92)
	for mote in motes:
		var drift: Vector2 = mote.get_meta("beastmen_drift", Vector2.ZERO)
		fade_tween.tween_property(mote, "position", mote.position + drift, spell_animation_duration * 0.92)
		fade_tween.tween_property(mote, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.92)
		fade_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.92)
	await fade_tween.finished

	veil.queue_free()
	pulse.queue_free()
	sigil.queue_free()
	for mote in motes:
		mote.queue_free()


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


func _create_sigil(target_rect: Rect2, text: String, font_color: Color, size_multiplier: float) -> Label:
	return _create_centered_label(
		target_rect.get_center(),
		target_rect.size * size_multiplier,
		text,
		maxi(int(target_rect.size.x * size_multiplier * 0.76), 18),
		font_color
	)


func _create_centered_label(center: Vector2, label_size: Vector2, text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size = label_size
	label.pivot_offset = label.size * 0.5
	label.position = center - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2310
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.01, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _create_radial_shards(target_rect: Rect2, count: int, fill_color: Color, border_color: Color) -> Array[Panel]:
	var shards: Array[Panel] = []
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) - PI * 0.5
		var shard := Panel.new()
		shard.name = "BeastmenShard_%d" % index
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.size = Vector2(target_rect.size.x * 0.045, target_rect.size.y * (0.16 + 0.025 * float(index % 3)))
		shard.pivot_offset = shard.size * 0.5
		shard.global_position = target_rect.get_center() - shard.pivot_offset
		shard.rotation = angle + PI * 0.5
		shard.modulate = Color(1.0, 1.0, 1.0, 0.0)
		shard.z_index = 2306
		shard.add_theme_stylebox_override("panel", _create_style(fill_color, border_color, 2, 5, border_color * Color(1.0, 1.0, 1.0, 0.5), 10))
		shard.set_meta("beastmen_drift", Vector2(cos(angle), sin(angle)) * target_rect.size.x * (0.48 + 0.04 * float(index % 2)))
		shards.append(shard)
	return shards


func _create_board_motes(viewport_size: Vector2) -> Array[Panel]:
	var motes: Array[Panel] = []
	for index in range(18):
		var mote := Panel.new()
		mote.name = "ChaosCorruptionMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = Vector2(8.0 + float(index % 4) * 4.0, 8.0 + float(index % 4) * 4.0)
		mote.pivot_offset = mote.size * 0.5
		var x_ratio := float((index * 37) % 101) / 100.0
		var y_ratio := float((index * 61 + 17) % 101) / 100.0
		mote.position = Vector2(viewport_size.x * x_ratio, viewport_size.y * y_ratio) - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2294
		mote.add_theme_stylebox_override("panel", _create_style(
			Color(0.72, 0.06 + 0.02 * float(index % 3), 0.0, 0.88),
			Color(1.0, 0.32, 0.05, 0.80), 2, 999, Color(0.62, 0.03, 0.0, 0.54), 12
		))
		var direction := (mote.position + mote.pivot_offset - viewport_size * 0.5).normalized()
		mote.set_meta("beastmen_drift", direction * (70.0 + float(index % 5) * 24.0))
		motes.append(mote)
	return motes


func _create_beast_path_segment_style(index: int) -> StyleBoxFlat:
	var phase := float(index % 2)
	return _create_style(
		Color(0.18 + phase * 0.04, 0.09, 0.025, 0.76),
		Color(0.78, 0.48 + phase * 0.08, 0.16, 0.92),
		5, 10, Color(0.52, 0.22, 0.04, 0.52), 22
	)


func _create_style(
	fill_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_color: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	return style


func _get_local_theme(animation_key: String) -> Dictionary:
	match animation_key:
		"beastmen_slaughter":
			return _theme("噬", Color(0.22, 0.01, 0.0, 0.24), Color(0.96, 0.16, 0.03, 0.90), Color(0.64, 0.01, 0.0, 0.72), Color(1.0, 0.42, 0.10, 0.96), true, 10, 0.70)
		"wanmo_charge":
			return _theme("魄", Color(0.18, 0.01, 0.0, 0.22), Color(0.88, 0.12, 0.02, 0.88), Color(0.52, 0.02, 0.0, 0.66), Color(1.0, 0.36, 0.08, 0.96), true, 8, 0.66)
		"savage_roar":
			return _theme("吼", Color(0.24, 0.05, 0.0, 0.20), Color(1.0, 0.50, 0.08, 0.92), Color(0.88, 0.18, 0.01, 0.72), Color(1.0, 0.72, 0.18, 0.98), false, 10, 0.52)
		"wild_call":
			return _theme("兽", Color(0.08, 0.15, 0.02, 0.22), Color(0.78, 0.78, 0.18, 0.88), Color(0.30, 0.48, 0.08, 0.68), Color(0.94, 0.96, 0.42, 0.98), false, 8, 0.58)
		"beast_path":
			return _theme("径", Color(0.16, 0.08, 0.02, 0.24), Color(0.82, 0.54, 0.20, 0.90), Color(0.42, 0.18, 0.04, 0.72), Color(0.96, 0.76, 0.38, 0.98), false, 7, 0.62)
		"wanmo_ritual":
			return _theme("仪", Color(0.18, 0.0, 0.0, 0.26), Color(1.0, 0.12, 0.04, 0.94), Color(0.58, 0.0, 0.0, 0.76), Color(1.0, 0.24, 0.08, 0.98), true, 12, 0.72)
		_:
			return _theme("化", Color(0.13, 0.08, 0.02, 0.22), Color(0.94, 0.58, 0.16, 0.88), Color(0.48, 0.26, 0.06, 0.68), Color(1.0, 0.76, 0.28, 0.98), false, 8, 0.60)


func _theme(
	symbol: String,
	aura_fill: Color,
	aura_border: Color,
	core_fill: Color,
	symbol_color: Color,
	collapse: bool,
	shard_count: int,
	core_scale: float
) -> Dictionary:
	return {
		"symbol": symbol,
		"symbol_color": symbol_color,
		"symbol_scale": 0.46,
		"aura_fill": aura_fill,
		"aura_border": aura_border,
		"aura_scale": 1.34,
		"core_fill": core_fill,
		"core_border": symbol_color,
		"core_radius": 999,
		"core_scale": core_scale,
		"glow": Color(aura_border.r, aura_border.g, aura_border.b, 0.48),
		"shard_fill": Color(core_fill.r, core_fill.g, core_fill.b, 0.88),
		"shard_border": symbol_color,
		"shard_count": shard_count,
		"rotation": 0.64 if collapse else -0.48,
		"collapse": collapse
	}
