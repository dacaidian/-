extends RefCounted
class_name ShadowmoonAnimationProvider

const TARGETED_KEYS: Array[String] = [
	"fel_infusion", "fel_overload", "fel_burst", "fel_madness",
	"demon_summon", "dark_portal", "curse", "kiljaeden_whisper",
	"immolation", "fire", "mana_burn", "fel_bite", "life_drain"
]
const RECT_KEYS: Array[String] = [
	"fel_infusion", "fel_overload", "fel_burst", "fel_madness",
	"demon_summon", "dark_portal", "life_drain", "curse", "kiljaeden_whisper",
	"immolation", "fire"
]
const SOURCE_RECT_KEYS: Array[String] = [
	"fel_infusion", "fel_overload", "fel_burst", "fel_madness",
	"demon_summon", "dark_portal", "curse", "kiljaeden_whisper",
	"immolation", "fire", "life_drain"
]
const FEL_RIFT_KEYS: Array[String] = [
	"fel_infusion", "fel_overload", "fel_burst", "fel_madness",
	"demon_summon", "dark_portal", "life_drain", "curse", "kiljaeden_whisper"
]
const TARGETED_FEL_RIFT_KEYS: Array[String] = [
	"fel_infusion", "fel_overload", "fel_burst", "fel_madness",
	"demon_summon", "dark_portal", "curse", "kiljaeden_whisper"
]

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
	if TARGETED_FEL_RIFT_KEYS.has(animation_key):
		await play_fel_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
	elif animation_key == "immolation" or animation_key == "fire":
		await play_immolation_at_rect(owner, effect_root, target_card.get_global_rect())
	elif animation_key == "mana_burn" or animation_key == "fel_bite" or animation_key == "life_drain":
		if caster_card != null:
			await play_life_drain_between_rects(
				owner,
				effect_root,
				caster_card.get_global_rect(),
				target_card.get_global_rect()
			)


func play_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if FEL_RIFT_KEYS.has(animation_key):
		await play_fel_spell_at_rect(owner, effect_root, target_rect, animation_key)
	elif animation_key == "immolation" or animation_key == "fire":
		await play_immolation_at_rect(owner, effect_root, target_rect)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	if animation_key == "life_drain":
		await play_life_drain_between_rects(owner, effect_root, source_rect, target_card.get_global_rect())
	elif FEL_RIFT_KEYS.has(animation_key):
		await play_fel_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
	elif animation_key == "immolation" or animation_key == "fire":
		await play_immolation_at_rect(owner, effect_root, target_card.get_global_rect())


func play_fel_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var is_madness := animation_key == "fel_madness"
	var is_portal := animation_key == "dark_portal"
	var rift := create_rect_effect(target_rect, "FelRift", create_fel_rift_style(is_madness, is_portal), 1.42 if is_portal else 1.24)
	var core := create_rect_effect(target_rect, "FelCore", create_fel_core_style(is_madness, is_portal), 0.78 if is_portal else 0.54)
	var sigil := create_fel_sigil(target_rect, animation_key)
	var embers := create_fel_embers(target_rect, is_madness, is_portal)

	effect_root.add_child(rift)
	effect_root.add_child(core)
	effect_root.add_child(sigil)
	for ember in embers:
		effect_root.add_child(ember)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(rift, "modulate:a", 0.92, spell_animation_duration * 0.34)
	rise_tween.tween_property(rift, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.34)
	rise_tween.tween_property(rift, "rotation", -0.24, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "modulate:a", 0.88, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "modulate:a", 0.96, spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.34)
	for ember in embers:
		var offset: Vector2 = ember.get_meta("fel_ember_offset", Vector2.ZERO)
		rise_tween.tween_property(ember, "global_position", ember.global_position + offset * 0.22, spell_animation_duration * 0.34)
		rise_tween.tween_property(ember, "modulate:a", 0.86, spell_animation_duration * 0.34)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(rift, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.72)
	burst_tween.tween_property(rift, "rotation", 0.58, spell_animation_duration * 0.72)
	burst_tween.tween_property(rift, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "scale", Vector2(0.38, 0.38) if is_madness else (Vector2(1.82, 1.82) if is_portal else Vector2(1.56, 1.56)), spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.18), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "scale", Vector2(1.46, 1.46), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for ember in embers:
		var offset: Vector2 = ember.get_meta("fel_ember_offset", Vector2.ZERO)
		burst_tween.tween_property(ember, "global_position", ember.global_position + offset, spell_animation_duration * 0.72)
		burst_tween.tween_property(ember, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.72)
		burst_tween.tween_property(ember, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burst_tween.finished

	rift.queue_free()
	core.queue_free()
	sigil.queue_free()
	for ember in embers:
		ember.queue_free()


func play_immolation_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var outer_ring := create_rect_effect(target_rect, "ImmolationOuterRing", create_immolation_ring_style(), 1.24)
	var inner_flame := create_rect_effect(target_rect, "ImmolationInnerFlame", create_immolation_flame_style(), 0.72)
	var embers := create_immolation_embers(target_rect)
	effect_root.add_child(outer_ring)
	effect_root.add_child(inner_flame)
	for ember in embers:
		effect_root.add_child(ember)

	var flare_tween := owner.create_tween()
	flare_tween.set_parallel(true)
	flare_tween.set_trans(Tween.TRANS_BACK)
	flare_tween.set_ease(Tween.EASE_OUT)
	flare_tween.tween_property(outer_ring, "modulate:a", 0.9, spell_animation_duration * 0.28)
	flare_tween.tween_property(outer_ring, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.28)
	flare_tween.tween_property(inner_flame, "modulate:a", 0.95, spell_animation_duration * 0.28)
	flare_tween.tween_property(inner_flame, "scale", Vector2(1.22, 1.22), spell_animation_duration * 0.28)
	for ember in embers:
		flare_tween.tween_property(ember, "modulate:a", 0.86, spell_animation_duration * 0.28)
	await flare_tween.finished

	var burn_tween := owner.create_tween()
	burn_tween.set_parallel(true)
	burn_tween.set_trans(Tween.TRANS_CUBIC)
	burn_tween.set_ease(Tween.EASE_OUT)
	burn_tween.tween_property(outer_ring, "scale", Vector2(1.92, 1.92), spell_animation_duration * 0.72)
	burn_tween.tween_property(outer_ring, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burn_tween.tween_property(inner_flame, "scale", Vector2(1.54, 1.54), spell_animation_duration * 0.72)
	burn_tween.tween_property(inner_flame, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for ember in embers:
		var offset: Vector2 = ember.get_meta("immolation_ember_offset", Vector2.ZERO)
		burn_tween.tween_property(ember, "global_position", ember.global_position + offset, spell_animation_duration * 0.72)
		burn_tween.tween_property(ember, "scale", Vector2(0.22, 0.22), spell_animation_duration * 0.72)
		burn_tween.tween_property(ember, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burn_tween.finished

	outer_ring.queue_free()
	inner_flame.queue_free()
	for ember in embers:
		ember.queue_free()


func play_life_drain_between_rects(owner: Node, effect_root: Control, recipient_rect: Rect2, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or recipient_rect.size == Vector2.ZERO or target_rect.size == Vector2.ZERO:
		return

	var source_point := target_rect.get_center()
	var destination_point := recipient_rect.get_center()
	if source_point.distance_to(destination_point) <= 0.01:
		return

	var pillar := create_rect_effect(target_rect, "ManaBurnPillar", create_mana_burn_pillar_style(), 0.76)
	var core := create_rect_effect(recipient_rect, "ManaBurnCore", create_mana_burn_core_style(), 0.46)
	var beam := create_mana_burn_beam(source_point, destination_point)
	effect_root.add_child(pillar)
	effect_root.add_child(beam)
	effect_root.add_child(core)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(pillar, "scale", Vector2(1.12, 1.26), spell_animation_duration * 0.32)
	rise_tween.tween_property(pillar, "modulate:a", 0.92, spell_animation_duration * 0.32)
	rise_tween.tween_property(beam, "scale:x", 1.0, spell_animation_duration * 0.42)
	rise_tween.tween_property(beam, "modulate:a", 0.88, spell_animation_duration * 0.42)
	rise_tween.tween_property(core, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.42)
	rise_tween.tween_property(core, "modulate:a", 0.82, spell_animation_duration * 0.42)
	await rise_tween.finished

	var drain_tween := owner.create_tween()
	drain_tween.set_parallel(true)
	drain_tween.set_trans(Tween.TRANS_CUBIC)
	drain_tween.set_ease(Tween.EASE_OUT)
	drain_tween.tween_property(pillar, "scale", Vector2(0.58, 1.82), spell_animation_duration * 0.70)
	drain_tween.tween_property(pillar, "modulate:a", 0.0, spell_animation_duration * 0.70)
	drain_tween.tween_property(beam, "scale:y", 1.80, spell_animation_duration * 0.46)
	drain_tween.tween_property(beam, "modulate:a", 0.0, spell_animation_duration * 0.70)
	drain_tween.tween_property(core, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.70)
	drain_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.70)
	await drain_tween.finished

	pillar.queue_free()
	beam.queue_free()
	core.queue_free()


func create_rect_effect(target_rect: Rect2, effect_name: String, style: StyleBoxFlat, size_multiplier: float) -> Panel:
	var effect := Panel.new()
	effect.name = effect_name
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = target_rect.size * size_multiplier
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = target_rect.get_center() - effect.pivot_offset
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2300
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_mana_burn_beam(source_point: Vector2, destination_point: Vector2) -> Panel:
	var beam_vector := destination_point - source_point
	var beam := Panel.new()
	beam.name = "ManaBurnBeam"
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.size = Vector2(beam_vector.length(), 14.0)
	beam.pivot_offset = Vector2(0.0, beam.size.y * 0.5)
	beam.global_position = source_point - beam.pivot_offset
	beam.rotation = beam_vector.angle()
	beam.scale = Vector2(0.0, 1.0)
	beam.modulate = Color(1.0, 1.0, 1.0, 0.0)
	beam.z_index = 2310
	beam.add_theme_stylebox_override("panel", create_mana_burn_beam_style())
	return beam


func create_fel_sigil(target_rect: Rect2, animation_key: String) -> Label:
	var is_madness := animation_key == "fel_madness"
	var is_portal := animation_key == "dark_portal"
	var label := Label.new()
	label.name = "FelSigil"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "门" if is_portal else ("RAGE" if is_madness else "FEL")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = target_rect.size * (Vector2(0.82, 0.82) if is_portal else (Vector2(0.78, 0.36) if is_madness else Vector2(0.66, 0.34)))
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2303
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * (0.38 if is_portal else (0.17 if is_madness else 0.19))), 18))
	label.add_theme_color_override("font_color", Color(0.44, 1.0, 0.08, 0.98) if is_portal else (Color(0.56, 1.0, 0.18, 0.96) if not is_madness else Color(0.86, 0.18, 0.16, 0.96)))
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.0, 0.0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func create_fel_embers(target_rect: Rect2, is_madness: bool, is_portal: bool) -> Array[Panel]:
	var embers: Array[Panel] = []
	var ember_count := 13 if is_portal else (9 if is_madness else 7)
	var ember_color := Color(0.58, 1.0, 0.04, 0.94) if is_portal else (Color(0.70, 0.94, 0.10, 0.72) if is_madness else Color(0.18, 1.0, 0.42, 0.86))
	var smoke_color := Color(0.01, 0.02, 0.01, 0.72) if is_portal else (Color(0.10, 0.01, 0.12, 0.68) if is_madness else Color(0.02, 0.02, 0.02, 0.64))
	var radius := minf(target_rect.size.x, target_rect.size.y) * (0.58 if is_portal else 0.48)
	for index in range(ember_count):
		var angle := TAU * float(index) / float(ember_count) + (0.24 if is_madness else -0.18)
		var ember := Panel.new()
		ember.name = "FelEmber"
		ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ember.size = target_rect.size * Vector2(0.055, 0.055)
		ember.pivot_offset = ember.size * 0.5
		ember.global_position = target_rect.get_center() + Vector2(cos(angle), sin(angle)) * radius * 0.42 - ember.pivot_offset
		ember.modulate = Color(1.0, 1.0, 1.0, 0.0)
		ember.z_index = 2302
		var chosen_color := smoke_color if index % 3 == 0 else (Color(0.78, 0.05, 0.07, 0.74) if is_madness and index % 4 == 1 else ember_color)
		ember.add_theme_stylebox_override("panel", create_fel_ember_style(chosen_color))
		ember.set_meta("fel_ember_offset", Vector2(cos(angle), sin(angle)) * radius * (1.04 if is_portal else (0.92 if is_madness else 0.74)))
		embers.append(ember)
	return embers


func create_immolation_embers(target_rect: Rect2) -> Array[Panel]:
	var embers: Array[Panel] = []
	var radius := minf(target_rect.size.x, target_rect.size.y) * 0.50
	for index in range(10):
		var angle := TAU * float(index) / 10.0 - 0.35
		var ember := Panel.new()
		ember.name = "ImmolationEmber"
		ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ember.size = target_rect.size * Vector2(0.052, 0.070)
		ember.pivot_offset = ember.size * 0.5
		ember.global_position = target_rect.get_center() + Vector2(cos(angle), sin(angle)) * radius * 0.36 - ember.pivot_offset
		ember.rotation = angle
		ember.modulate = Color(1.0, 1.0, 1.0, 0.0)
		ember.z_index = 2304
		var ember_color := Color(1.0, 0.30, 0.04, 0.90) if index % 3 != 0 else Color(1.0, 0.76, 0.16, 0.86)
		ember.add_theme_stylebox_override("panel", create_immolation_ember_style(ember_color))
		ember.set_meta("immolation_ember_offset", Vector2(cos(angle), sin(angle) - 0.45) * radius * 0.78)
		embers.append(ember)
	return embers


func create_fel_rift_style(is_madness: bool, is_portal: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.02, 0.0, 0.58) if is_portal else (Color(0.04, 0.13, 0.04, 0.34) if not is_madness else Color(0.10, 0.02, 0.12, 0.42))
	style.border_color = Color(0.44, 1.0, 0.02, 0.96) if is_portal else (Color(0.36, 1.0, 0.08, 0.88) if not is_madness else Color(0.62, 0.92, 0.12, 0.72))
	style.set_border_width_all(7 if is_portal else 5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.16, 1.0, 0.02, 0.66) if is_portal else (Color(0.10, 1.0, 0.22, 0.44) if not is_madness else Color(0.24, 0.72, 0.04, 0.26))
	style.shadow_size = 46 if is_portal else 34
	return style


func create_fel_core_style(is_madness: bool, is_portal: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.86) if is_portal else (Color(0.02, 0.0, 0.0, 0.74) if not is_madness else Color(0.08, 0.0, 0.08, 0.82))
	style.border_color = Color(0.66, 1.0, 0.06, 0.98) if is_portal else (Color(0.48, 1.0, 0.16, 0.92) if not is_madness else Color(0.92, 0.18, 0.12, 0.86))
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.28, 1.0, 0.02, 0.72) if is_portal else (Color(0.18, 1.0, 0.18, 0.58) if not is_madness else Color(0.42, 0.86, 0.06, 0.32))
	style.shadow_size = 34 if is_portal else 22
	return style


func create_fel_ember_style(color: Color) -> StyleBoxFlat:
	return create_glow_style(color, Color(color.r, color.g, color.b, minf(color.a + 0.14, 1.0)), 1, 999, Color(color.r, color.g, color.b, 0.42), 10)


func create_immolation_ring_style() -> StyleBoxFlat:
	return create_glow_style(Color(0.40, 0.04, 0.0, 0.26), Color(1.0, 0.42, 0.06, 0.92), 6, 999, Color(1.0, 0.20, 0.02, 0.58), 36)


func create_immolation_flame_style() -> StyleBoxFlat:
	return create_glow_style(Color(1.0, 0.20, 0.02, 0.62), Color(1.0, 0.82, 0.22, 0.96), 4, 999, Color(1.0, 0.36, 0.04, 0.66), 28)


func create_immolation_ember_style(color: Color) -> StyleBoxFlat:
	return create_glow_style(color, Color(1.0, 0.88, 0.30, 0.94), 1, 999, Color(1.0, 0.28, 0.02, 0.48), 12)


func create_mana_burn_pillar_style() -> StyleBoxFlat:
	return create_glow_style(Color(0.04, 0.48, 0.10, 0.32), Color(0.54, 1.0, 0.16, 0.92), 4, 10, Color(0.18, 1.0, 0.10, 0.62), 22)


func create_mana_burn_core_style() -> StyleBoxFlat:
	return create_glow_style(Color(0.16, 1.0, 0.24, 0.30), Color(0.78, 1.0, 0.20, 0.96), 3, 999, Color(0.20, 1.0, 0.04, 0.66), 18)


func create_mana_burn_beam_style() -> StyleBoxFlat:
	return create_glow_style(Color(0.28, 1.0, 0.08, 0.72), Color(0.76, 1.0, 0.26, 0.92), 3, 7, Color(0.12, 1.0, 0.02, 0.70), 18)


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
