extends RefCounted
class_name GenericSpellAnimationProvider

# 通用施法回合表现。只消费全战场 animation key，不读取或修改规则状态。
const BOARD_KEYS: Array[String] = ["spell_turn_activation"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router != null:
		router.register_board(BOARD_KEYS, play_board)


func play_board(owner: Node, effect_root: Control, animation_key: String) -> void:
	if owner == null or effect_root == null:
		return
	if animation_key == "spell_turn_activation":
		await play_spell_turn_activation(owner, effect_root)


func play_spell_turn_activation(owner: Node, effect_root: Control) -> void:
	var viewport_size := effect_root.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var veil := create_veil()
	var outer_ring := create_ring(viewport_size, 0.58, "SpellTurnOuterRing", create_outer_ring_style(), 2292)
	var inner_ring := create_ring(viewport_size, 0.31, "SpellTurnInnerRing", create_inner_ring_style(), 2294)
	var sigil := create_sigil(viewport_size)
	var rays := create_rays(viewport_size)
	var motes := create_motes(viewport_size)

	effect_root.add_child(veil)
	for ray in rays:
		effect_root.add_child(ray)
	effect_root.add_child(outer_ring)
	effect_root.add_child(inner_ring)
	for mote in motes:
		effect_root.add_child(mote)
	effect_root.add_child(sigil)

	var invoke := owner.create_tween()
	invoke.set_parallel(true)
	invoke.set_trans(Tween.TRANS_QUART)
	invoke.set_ease(Tween.EASE_OUT)
	invoke.tween_property(veil, "color:a", 0.34, spell_animation_duration * 0.52)
	invoke.tween_property(outer_ring, "scale", Vector2.ONE, spell_animation_duration * 0.72)
	invoke.tween_property(outer_ring, "modulate:a", 0.92, spell_animation_duration * 0.46)
	invoke.tween_property(inner_ring, "scale", Vector2.ONE, spell_animation_duration * 0.62)
	invoke.tween_property(inner_ring, "modulate:a", 0.98, spell_animation_duration * 0.40)
	invoke.tween_property(sigil, "scale", Vector2.ONE, spell_animation_duration * 0.68)
	invoke.tween_property(sigil, "modulate:a", 0.96, spell_animation_duration * 0.42)
	for ray in rays:
		invoke.tween_property(ray, "scale:x", 1.0, spell_animation_duration * 0.76)
		invoke.tween_property(ray, "modulate:a", 0.82, spell_animation_duration * 0.42)
	for mote in motes:
		invoke.tween_property(mote, "modulate:a", 0.90, spell_animation_duration * 0.54)
	await invoke.finished

	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_SINE)
	release.set_ease(Tween.EASE_IN_OUT)
	release.tween_property(veil, "color:a", 0.0, spell_animation_duration * 0.92)
	release.tween_property(outer_ring, "scale", Vector2(1.48, 1.48), spell_animation_duration * 0.92)
	release.tween_property(outer_ring, "rotation", 0.36, spell_animation_duration * 0.92)
	release.tween_property(outer_ring, "modulate:a", 0.0, spell_animation_duration * 0.92)
	release.tween_property(inner_ring, "scale", Vector2(1.30, 1.30), spell_animation_duration * 0.82)
	release.tween_property(inner_ring, "rotation", -0.48, spell_animation_duration * 0.82)
	release.tween_property(inner_ring, "modulate:a", 0.0, spell_animation_duration * 0.82)
	release.tween_property(sigil, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.72)
	release.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for ray in rays:
		release.tween_property(ray, "scale:x", 1.22, spell_animation_duration * 0.76)
		release.tween_property(ray, "modulate:a", 0.0, spell_animation_duration * 0.76)
	for mote in motes:
		var drift: Vector2 = mote.get_meta("spell_turn_drift", Vector2.ZERO)
		release.tween_property(mote, "position", mote.position + drift, spell_animation_duration * 0.86)
		release.tween_property(mote, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.86)
		release.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.86)
	await release.finished

	veil.queue_free()
	outer_ring.queue_free()
	inner_ring.queue_free()
	sigil.queue_free()
	for ray in rays:
		ray.queue_free()
	for mote in motes:
		mote.queue_free()


func create_veil() -> ColorRect:
	var veil := ColorRect.new()
	veil.name = "SpellTurnVeil"
	veil.color = Color(0.015, 0.055, 0.16, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 2280
	return veil


func create_ring(
	viewport_size: Vector2,
	size_ratio: float,
	ring_name: String,
	style: StyleBoxFlat,
	z_index: int
) -> Panel:
	var diameter := minf(viewport_size.x, viewport_size.y) * size_ratio
	var ring := Panel.new()
	ring.name = ring_name
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2(diameter, diameter)
	ring.pivot_offset = ring.size * 0.5
	ring.position = viewport_size * 0.5 - ring.pivot_offset
	ring.scale = Vector2(0.16, 0.16)
	ring.modulate = Color(1.0, 1.0, 1.0, 0.0)
	ring.z_index = z_index
	ring.add_theme_stylebox_override("panel", style)
	return ring


func create_sigil(viewport_size: Vector2) -> Label:
	var sigil := Label.new()
	sigil.name = "SpellTurnSigil"
	sigil.text = "法"
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil.size = Vector2(180.0, 180.0)
	sigil.pivot_offset = sigil.size * 0.5
	sigil.position = viewport_size * 0.5 - sigil.pivot_offset
	sigil.scale = Vector2(0.20, 0.20)
	sigil.modulate = Color(1.0, 1.0, 1.0, 0.0)
	sigil.z_index = 2310
	sigil.add_theme_font_size_override("font_size", 104)
	sigil.add_theme_color_override("font_color", Color(0.94, 0.86, 0.48, 0.98))
	sigil.add_theme_color_override("font_shadow_color", Color(0.08, 0.18, 0.54, 0.98))
	sigil.add_theme_constant_override("shadow_offset_x", 4)
	sigil.add_theme_constant_override("shadow_offset_y", 4)
	return sigil


func create_rays(viewport_size: Vector2) -> Array[Panel]:
	var rays: Array[Panel] = []
	var center := viewport_size * 0.5
	var ray_length := minf(viewport_size.x, viewport_size.y) * 0.42
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var ray := Panel.new()
		ray.name = "SpellTurnRay_%d" % index
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ray.size = Vector2(ray_length, 4.0 if index % 2 == 0 else 2.0)
		ray.pivot_offset = Vector2(0.0, ray.size.y * 0.5)
		ray.position = center - ray.pivot_offset
		ray.rotation = angle
		ray.scale = Vector2(0.02, 1.0)
		ray.modulate = Color(1.0, 1.0, 1.0, 0.0)
		ray.z_index = 2288
		ray.add_theme_stylebox_override("panel", create_ray_style(index))
		rays.append(ray)
	return rays


func create_motes(viewport_size: Vector2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center := viewport_size * 0.5
	var radius := minf(viewport_size.x, viewport_size.y) * 0.25
	for index in range(12):
		var angle := TAU * float(index) / 12.0 + 0.18
		var mote := Panel.new()
		var mote_size := 7.0 + float(index % 3) * 3.0
		mote.name = "SpellTurnMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = Vector2(mote_size, mote_size)
		mote.pivot_offset = mote.size * 0.5
		mote.position = center + Vector2.RIGHT.rotated(angle) * radius - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2302
		mote.set_meta("spell_turn_drift", Vector2.RIGHT.rotated(angle) * radius * 0.62 + Vector2(0.0, -24.0))
		mote.add_theme_stylebox_override("panel", create_mote_style(index))
		motes.append(mote)
	return motes


func create_outer_ring_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.04, 0.12, 0.34, 0.18),
		Color(0.32, 0.66, 1.0, 0.92),
		7,
		999,
		Color(0.18, 0.46, 1.0, 0.70),
		34
	)


func create_inner_ring_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.12, 0.16, 0.34, 0.28),
		Color(1.0, 0.82, 0.34, 0.96),
		4,
		999,
		Color(0.56, 0.42, 1.0, 0.62),
		24
	)


func create_ray_style(index: int) -> StyleBoxFlat:
	var is_gold := index % 2 == 1
	return create_glow_style(
		Color(0.94, 0.72, 0.22, 0.86) if is_gold else Color(0.20, 0.58, 1.0, 0.88),
		Color(1.0, 0.92, 0.58, 0.94) if is_gold else Color(0.62, 0.86, 1.0, 0.96),
		1,
		999,
		Color(0.40, 0.54, 1.0, 0.64),
		12
	)


func create_mote_style(index: int) -> StyleBoxFlat:
	var is_gold := index % 3 == 0
	return create_glow_style(
		Color(1.0, 0.76, 0.24, 0.94) if is_gold else Color(0.30, 0.70, 1.0, 0.94),
		Color(1.0, 0.94, 0.68, 0.98) if is_gold else Color(0.74, 0.92, 1.0, 0.98),
		1,
		999,
		Color(0.34, 0.56, 1.0, 0.68),
		10
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
