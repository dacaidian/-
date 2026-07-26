extends RefCounted
class_name MiaoAnimationProvider

const MiaoSpellVisualScript := preload("res://scripts/ui/animation/miao_spell_visual.gd")

const TARGETED_KEYS: Array[String] = [
	"medical_practice",
	"gu_herb_poison",
	"gu_infusion",
	"gu_lure",
	"gu_life_link_larva",
	"gu_life_link",
	"gu_life_link_death",
	"thin_burial",
	"thin_burial_release",
	"thin_burial_break",
	"gu_summon",
	"gu_scorpion_breeding",
	"gu_trap_trigger",
	"gu_snake_venom_apply",
	"gu_devour",
	"gu_venom_inject",
	"gu_venom_burst",
	"gu_scorpion_venom_apply",
	"gu_king_venom_apply",
	"gu_poison_tick_scorpion",
	"gu_poison_tick_snake",
	"gu_poison_tick_king",
	"gu_poison_burst"
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const MULTI_RECT_KEYS: Array[String] = [
	"gu_venom_burst",
	"gu_poison_tick_scorpion",
	"gu_poison_tick_snake",
	"gu_poison_tick_king",
	"gu_poison_burst",
	"thin_burial_release",
	"thin_burial_break"
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
	router.register_multi_rect(MULTI_RECT_KEYS, play_multi_rect)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null or not is_instance_valid(target_card):
		return

	if animation_key == "gu_devour" and caster_card != null and is_instance_valid(caster_card):
		await _play_organic_transfer(
			owner,
			effect_root,
			target_card.get_global_rect().get_center(),
			caster_card.get_global_rect().get_center(),
			animation_key
		)
		await play_at_rect(owner, effect_root, caster_card.get_global_rect(), animation_key)
		return

	if caster_card != null and is_instance_valid(caster_card) and _uses_source_transfer(animation_key):
		await _play_organic_transfer(
			owner,
			effect_root,
			caster_card.get_global_rect().get_center(),
			target_card.get_global_rect().get_center(),
			animation_key
		)

	await play_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or source_rect.size == Vector2.ZERO
		or target_card == null
		or not is_instance_valid(target_card)
	):
		return

	var target_rect := target_card.get_global_rect()
	if animation_key == "gu_devour":
		await _play_organic_transfer(
			owner,
			effect_root,
			target_rect.get_center(),
			source_rect.get_center(),
			animation_key
		)
		await play_at_rect(owner, effect_root, source_rect, animation_key)
		return

	if _uses_source_transfer(animation_key):
		await _play_organic_transfer(
			owner,
			effect_root,
			source_rect.get_center(),
			target_rect.get_center(),
			animation_key
		)
	await play_at_rect(owner, effect_root, target_rect, animation_key)


func play_at_rect(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or target_rect.size == Vector2.ZERO
		or not RECT_KEYS.has(animation_key)
	):
		return

	var presentation := _get_presentation(animation_key)
	var visual := _create_visual(target_rect, animation_key, presentation)
	effect_root.add_child(visual)
	await _animate_visual(owner, visual, presentation)
	if is_instance_valid(visual):
		visual.queue_free()


func play_multi_rect(
	owner: Node,
	effect_root: Control,
	target_rects: Array[Rect2],
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or target_rects.is_empty()
		or not MULTI_RECT_KEYS.has(animation_key)
	):
		return

	var presentation := _get_presentation(animation_key)
	var visuals: Array[Control] = []
	for target_rect in target_rects:
		if target_rect.size == Vector2.ZERO:
			continue
		var visual := _create_visual(target_rect, animation_key, presentation)
		effect_root.add_child(visual)
		visuals.append(visual)
	if visuals.is_empty():
		return

	var total_duration := _get_total_duration(presentation)
	var rise_duration := total_duration * 0.24
	var hold_duration := total_duration * 0.38
	var fade_duration := total_duration - rise_duration - hold_duration

	var progress_tween := owner.create_tween()
	progress_tween.set_parallel(true)
	progress_tween.set_trans(Tween.TRANS_SINE)
	progress_tween.set_ease(Tween.EASE_IN_OUT)
	for visual in visuals:
		progress_tween.tween_property(visual, "progress", 1.0, total_duration)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_QUART)
	rise_tween.set_ease(Tween.EASE_OUT)
	for visual in visuals:
		rise_tween.tween_property(visual, "modulate:a", 1.0, rise_duration)
		rise_tween.tween_property(visual, "scale", Vector2.ONE, rise_duration)
	await rise_tween.finished
	await owner.create_tween().tween_interval(hold_duration).finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN)
	for visual in visuals:
		fade_tween.tween_property(visual, "modulate:a", 0.0, fade_duration)
		fade_tween.tween_property(
			visual,
			"scale",
			Vector2.ONE * float(presentation.get("end_scale", 1.16)),
			fade_duration
		)
	await fade_tween.finished

	for visual in visuals:
		if is_instance_valid(visual):
			visual.queue_free()


func play_life_link(
	owner: Node,
	effect_root: Control,
	first_card: Card,
	second_card: Card,
	spell_data: Dictionary
) -> void:
	if (
		owner == null
		or effect_root == null
		or first_card == null
		or second_card == null
		or not is_instance_valid(first_card)
		or not is_instance_valid(second_card)
	):
		return

	var animation_key := str(spell_data.get("animation", "gu_life_link"))
	var first_rect := first_card.get_global_rect()
	var second_rect := second_card.get_global_rect()
	var presentation := _get_presentation(animation_key)
	var first_visual := _create_visual(first_rect, animation_key, presentation)
	var second_visual := _create_visual(second_rect, animation_key, presentation)
	effect_root.add_child(first_visual)
	effect_root.add_child(second_visual)

	var is_larva := animation_key == "gu_life_link_larva"
	var is_death := animation_key == "gu_life_link_death"
	var primary_line: Line2D = null
	var secondary_line: Line2D = null
	var travelling_node: Panel = null
	if not is_larva:
		primary_line = _create_link_line(
			first_rect.get_center(),
			second_rect.get_center(),
			MiaoSpellVisualScript.CINNABAR if is_death else MiaoSpellVisualScript.DARK_RED,
			6.4 if is_death else 4.8,
			"GuLifeLinkPrimary"
		)
		secondary_line = _create_link_line(
			first_rect.get_center(),
			second_rect.get_center(),
			MiaoSpellVisualScript.DEEP_TEAL,
			2.4,
			"GuLifeLinkVein"
		)
		effect_root.add_child(primary_line)
		effect_root.add_child(secondary_line)
		travelling_node = _create_transfer_mote(
			first_rect.get_center(),
			MiaoSpellVisualScript.CINNABAR,
			12.0 if is_death else 8.0
		)
		effect_root.add_child(travelling_node)

	var total_duration := _get_total_duration(presentation)
	var progress_tween := owner.create_tween()
	progress_tween.set_parallel(true)
	progress_tween.tween_property(first_visual, "progress", 1.0, total_duration)
	progress_tween.tween_property(second_visual, "progress", 1.0, total_duration)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_QUART)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(first_visual, "modulate:a", 1.0, total_duration * 0.28)
	bind_tween.tween_property(first_visual, "scale", Vector2.ONE, total_duration * 0.28)
	bind_tween.tween_property(second_visual, "modulate:a", 1.0, total_duration * 0.28)
	bind_tween.tween_property(second_visual, "scale", Vector2.ONE, total_duration * 0.28)
	if primary_line != null:
		bind_tween.tween_property(primary_line, "modulate:a", 0.92, total_duration * 0.28)
		bind_tween.tween_property(secondary_line, "modulate:a", 0.72, total_duration * 0.28)
	if travelling_node != null:
		bind_tween.tween_property(
			travelling_node,
			"global_position",
			second_rect.get_center() - travelling_node.size * 0.5,
			total_duration * (0.56 if is_death else 0.72)
		)
	await bind_tween.finished
	await owner.create_tween().tween_interval(total_duration * 0.30).finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.tween_property(first_visual, "modulate:a", 0.0, total_duration * 0.42)
	fade_tween.tween_property(second_visual, "modulate:a", 0.0, total_duration * 0.42)
	if primary_line != null:
		fade_tween.tween_property(primary_line, "width", 1.0 if is_death else 2.0, total_duration * 0.42)
		fade_tween.tween_property(primary_line, "modulate:a", 0.0, total_duration * 0.42)
		fade_tween.tween_property(secondary_line, "modulate:a", 0.0, total_duration * 0.42)
	if travelling_node != null:
		fade_tween.tween_property(travelling_node, "modulate:a", 0.0, total_duration * 0.42)
	await fade_tween.finished

	for node in [first_visual, second_visual, primary_line, secondary_line, travelling_node]:
		if node != null and is_instance_valid(node):
			node.queue_free()


func _animate_visual(owner: Node, visual: Control, presentation: Dictionary) -> void:
	var total_duration := _get_total_duration(presentation)
	var rise_duration := total_duration * 0.26
	var hold_duration := total_duration * 0.36
	var fade_duration := total_duration - rise_duration - hold_duration

	var progress_tween := owner.create_tween()
	progress_tween.set_trans(Tween.TRANS_SINE)
	progress_tween.set_ease(Tween.EASE_IN_OUT)
	progress_tween.tween_property(visual, "progress", 1.0, total_duration)

	var presentation_tween := owner.create_tween()
	presentation_tween.set_trans(Tween.TRANS_QUART)
	presentation_tween.set_ease(Tween.EASE_OUT)
	presentation_tween.tween_property(visual, "modulate:a", 1.0, rise_duration)
	presentation_tween.parallel().tween_property(visual, "scale", Vector2.ONE, rise_duration)
	presentation_tween.tween_interval(hold_duration)
	presentation_tween.set_trans(Tween.TRANS_SINE)
	presentation_tween.set_ease(Tween.EASE_IN)
	presentation_tween.tween_property(visual, "modulate:a", 0.0, fade_duration)
	presentation_tween.parallel().tween_property(
		visual,
		"scale",
		Vector2.ONE * float(presentation.get("end_scale", 1.14)),
		fade_duration
	)
	await presentation_tween.finished


func _create_visual(
	target_rect: Rect2,
	animation_key: String,
	presentation: Dictionary
) -> Control:
	var visual := MiaoSpellVisualScript.new()
	visual.name = "Miao_%s" % animation_key
	visual.configure(animation_key, float(presentation.get("strength", 1.0)))
	visual.size = target_rect.size * float(presentation.get("size_scale", 1.54))
	visual.pivot_offset = visual.size * 0.5
	visual.global_position = (
		target_rect.get_center()
		+ target_rect.size * presentation.get("center_offset", Vector2.ZERO)
		- visual.pivot_offset
	)
	visual.scale = Vector2.ONE * float(presentation.get("start_scale", 0.72))
	visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	visual.z_index = 2470
	var material := CanvasItemMaterial.new()
	material.blend_mode = (
		CanvasItemMaterial.BLEND_MODE_MIX
		if animation_key in ["thin_burial", "thin_burial_release", "thin_burial_break", "gu_devour"]
		else CanvasItemMaterial.BLEND_MODE_ADD
	)
	visual.material = material
	return visual


func _play_organic_transfer(
	owner: Node,
	effect_root: Control,
	source_position: Vector2,
	target_position: Vector2,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or source_position == target_position:
		return

	var color := _get_transfer_color(animation_key)
	var direction := (target_position - source_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var conduit := Line2D.new()
	conduit.name = "MiaoOrganicConduit"
	conduit.width = 4.0 if animation_key == "gu_devour" else 2.8
	conduit.default_color = Color(color.r, color.g, color.b, 0.66)
	conduit.antialiased = true
	conduit.modulate.a = 0.0
	conduit.z_index = 2472
	var points := PackedVector2Array()
	for point_index in range(13):
		var t := float(point_index) / 12.0
		var base := source_position.lerp(target_position, t)
		var bend := sin(t * TAU * 1.5 + float(animation_key.hash() % 7)) * 7.0
		points.append(base + perpendicular * bend * sin(t * PI))
	conduit.points = points
	effect_root.add_child(conduit)

	var motes: Array[Panel] = []
	for mote_index in range(5):
		var mote := _create_transfer_mote(
			source_position,
			color,
			7.0 + float(mote_index % 3) * 2.0
		)
		mote.global_position += perpendicular * (float(mote_index) - 2.0) * 4.0
		effect_root.add_child(mote)
		motes.append(mote)

	var duration := maxf(spell_animation_duration * 0.74, 0.20)
	var travel_tween := owner.create_tween()
	travel_tween.set_parallel(true)
	travel_tween.set_trans(Tween.TRANS_CUBIC)
	travel_tween.set_ease(Tween.EASE_IN_OUT)
	travel_tween.tween_property(conduit, "modulate:a", 1.0, duration * 0.26)
	for mote_index in range(motes.size()):
		var mote := motes[mote_index]
		travel_tween.tween_property(
			mote,
			"global_position",
			target_position
				- mote.size * 0.5
				+ perpendicular * (float(mote_index) - 2.0) * 2.0,
			duration * (0.78 + float(mote_index) * 0.025)
		)
		travel_tween.tween_property(mote, "rotation", 1.4 + float(mote_index) * 0.26, duration)
	await travel_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(conduit, "modulate:a", 0.0, duration * 0.28)
	for mote in motes:
		fade_tween.tween_property(mote, "modulate:a", 0.0, duration * 0.28)
		fade_tween.tween_property(mote, "scale", Vector2(0.28, 0.28), duration * 0.28)
	await fade_tween.finished

	conduit.queue_free()
	for mote in motes:
		mote.queue_free()


func _create_link_line(
	first_position: Vector2,
	second_position: Vector2,
	color: Color,
	width: float,
	node_name: String
) -> Line2D:
	var direction := (second_position - first_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var line := Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.modulate.a = 0.0
	line.z_index = 2471
	var points := PackedVector2Array()
	for point_index in range(17):
		var t := float(point_index) / 16.0
		points.append(
			first_position.lerp(second_position, t)
			+ perpendicular * sin(t * TAU * 2.0) * 4.5 * sin(t * PI)
		)
	line.points = points
	return line


func _create_transfer_mote(position: Vector2, color: Color, diameter: float) -> Panel:
	var mote := Panel.new()
	mote.name = "MiaoTransferMote"
	mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mote.size = Vector2.ONE * diameter
	mote.pivot_offset = mote.size * 0.5
	mote.global_position = position - mote.pivot_offset
	mote.z_index = 2473
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.90, 0.98, 0.58, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(color.r, color.g, color.b, 0.38)
	style.shadow_size = 8
	mote.add_theme_stylebox_override("panel", style)
	return mote


func _uses_source_transfer(animation_key: String) -> bool:
	return animation_key in [
		"medical_practice",
		"gu_herb_poison",
		"gu_infusion",
		"gu_snake_venom_apply",
		"gu_venom_inject",
		"gu_devour"
	]


func _get_transfer_color(animation_key: String) -> Color:
	match animation_key:
		"medical_practice":
			return MiaoSpellVisualScript.AMBER
		"gu_life_link_larva", "gu_life_link", "gu_life_link_death":
			return MiaoSpellVisualScript.CINNABAR
		"gu_devour":
			return MiaoSpellVisualScript.OXIDIZED_COPPER
		"gu_snake_venom_apply", "gu_venom_inject":
			return MiaoSpellVisualScript.DEEP_TEAL
		_:
			return MiaoSpellVisualScript.VENOM_LIME


func _get_total_duration(presentation: Dictionary) -> float:
	return maxf(
		spell_animation_duration * float(presentation.get("duration_scale", 1.45)),
		float(presentation.get("minimum_duration", 0.42))
	)


func _get_presentation(animation_key: String) -> Dictionary:
	var presentation := {
		"size_scale": 1.62,
		"center_offset": Vector2.ZERO,
		"start_scale": 0.72,
		"end_scale": 1.16,
		"duration_scale": 1.55,
		"minimum_duration": 0.46,
		"strength": 1.0
	}
	match animation_key:
		"medical_practice":
			presentation["size_scale"] = 1.48
			presentation["duration_scale"] = 1.72
		"gu_scorpion_breeding":
			presentation["size_scale"] = 1.74
			presentation["duration_scale"] = 1.90
		"gu_lure":
			presentation["size_scale"] = 1.76
		"gu_trap_trigger":
			presentation["size_scale"] = 2.04
			presentation["duration_scale"] = 1.86
		"gu_life_link_larva", "gu_life_link", "gu_life_link_death":
			presentation["size_scale"] = 1.52
			presentation["duration_scale"] = 1.82
		"thin_burial", "thin_burial_release", "thin_burial_break":
			presentation["size_scale"] = 1.70
			presentation["duration_scale"] = 1.92
		"gu_summon":
			presentation["size_scale"] = 1.94
			presentation["duration_scale"] = 2.12
		"gu_devour":
			presentation["size_scale"] = 1.92
			presentation["duration_scale"] = 2.05
		"gu_venom_burst", "gu_poison_burst":
			presentation["size_scale"] = 1.96
			presentation["duration_scale"] = 1.84
		"gu_poison_tick_scorpion", "gu_poison_tick_snake", "gu_poison_tick_king":
			presentation["size_scale"] = 1.58
			presentation["duration_scale"] = 1.36
			presentation["minimum_duration"] = 0.38
	return presentation
