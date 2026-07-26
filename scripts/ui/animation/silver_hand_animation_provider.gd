extends RefCounted
class_name SilverHandAnimationProvider

const HolySpellVisualScript := preload("res://scripts/ui/animation/holy_spell_visual.gd")

const TARGETED_KEYS: Array[String] = [
	"divine_shield",
	"baptism",
	"holy_heal",
	"power_word_shield",
	"inner_fire"
]
const RECT_KEYS: Array[String] = [
	"divine_shield",
	"baptism",
	"holy_heal",
	"power_word_shield",
	"inner_fire",
	"resurrection"
]
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
	if target_card == null or not is_instance_valid(target_card):
		return

	_play_target_pulse(owner, target_card, animation_key)
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
	await _play_source_transfer(
		owner,
		effect_root,
		source_rect.get_center(),
		target_rect.get_center(),
		animation_key
	)
	_play_target_pulse(owner, target_card, animation_key)
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
	var visual := HolySpellVisualScript.new()
	visual.name = "SilverHand_%s" % animation_key
	visual.configure(animation_key)
	visual.size = target_rect.size * float(presentation.size_scale)
	visual.pivot_offset = visual.size * 0.5
	visual.global_position = (
		target_rect.get_center()
		+ target_rect.size * presentation.center_offset
		- visual.pivot_offset
	)
	visual.scale = Vector2.ONE * float(presentation.start_scale)
	visual.modulate = Color(1.0, 1.0, 1.0, 0.0)
	visual.z_index = 2480

	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	visual.material = additive_material
	effect_root.add_child(visual)

	var total_duration := maxf(
		spell_animation_duration * float(presentation.duration_scale),
		float(presentation.minimum_duration)
	)
	var rise_duration := total_duration * 0.28
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
		Vector2.ONE * float(presentation.end_scale),
		fade_duration
	)
	await presentation_tween.finished

	if is_instance_valid(visual):
		visual.queue_free()


func _play_source_transfer(
	owner: Node,
	effect_root: Control,
	source_position: Vector2,
	target_position: Vector2,
	animation_key: String
) -> void:
	var color := _get_transfer_color(animation_key)
	var direction := (target_position - source_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var nodes: Array[Panel] = []
	for node_index in range(3):
		var mote := Panel.new()
		mote.name = "SilverHandTransfer_%d" % node_index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var diameter := 14.0 - float(node_index) * 3.0
		mote.size = Vector2.ONE * diameter
		mote.pivot_offset = mote.size * 0.5
		mote.global_position = (
			source_position
			- mote.pivot_offset
			+ perpendicular * (float(node_index) - 1.0) * 9.0
		)
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2482
		mote.add_theme_stylebox_override(
			"panel",
			_create_mote_style(color, maxi(10 - node_index * 2, 4))
		)
		effect_root.add_child(mote)
		nodes.append(mote)

	var duration := maxf(spell_animation_duration * 0.72, 0.20)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_IN)
	for node_index in range(nodes.size()):
		var mote := nodes[node_index]
		var target_offset := perpendicular * (float(node_index) - 1.0) * 2.0
		tween.tween_property(
			mote,
			"global_position",
			target_position - mote.pivot_offset + target_offset,
			duration
		).set_delay(float(node_index) * 0.025)
		tween.tween_property(
			mote,
			"modulate:a",
			1.0,
			duration * 0.34
		).set_delay(float(node_index) * 0.025)
		tween.tween_property(
			mote,
			"scale",
			Vector2(0.42, 0.42),
			duration
		).set_delay(float(node_index) * 0.025)
	await tween.finished

	for mote in nodes:
		if is_instance_valid(mote):
			mote.queue_free()


func _play_target_pulse(owner: Node, target_card: Card, animation_key: String) -> void:
	if owner == null or target_card == null:
		return
	var base_scale := target_card.scale
	var base_modulate := target_card.self_modulate
	var tint := _get_target_tint(animation_key)
	var pulse_duration := maxf(spell_animation_duration * 0.72, 0.24)
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "scale", base_scale * 1.045, pulse_duration * 0.42)
	tween.parallel().tween_property(target_card, "self_modulate", tint, pulse_duration * 0.42)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target_card, "scale", base_scale, pulse_duration * 0.58)
	tween.parallel().tween_property(target_card, "self_modulate", base_modulate, pulse_duration * 0.58)


func _get_target_tint(animation_key: String) -> Color:
	match animation_key:
		"holy_heal":
			return Color(0.82, 1.0, 0.78, 1.0)
		"inner_fire":
			return Color(1.0, 0.78, 0.52, 1.0)
		_:
			return Color(1.0, 0.94, 0.70, 1.0)


func _get_transfer_color(animation_key: String) -> Color:
	match animation_key:
		"holy_heal":
			return Color(0.48, 1.0, 0.54, 0.96)
		"inner_fire":
			return Color(1.0, 0.52, 0.12, 0.98)
		_:
			return Color(1.0, 0.88, 0.28, 0.98)


func _create_mote_style(color: Color, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1.0, 1.0, 0.84, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(color.r, color.g, color.b, 0.62)
	style.shadow_size = shadow_size
	return style


func _get_presentation(animation_key: String) -> Dictionary:
	match animation_key:
		"baptism":
			return _presentation(2.35, Vector2.ZERO, 0.76, 1.14, 2.75, 0.78)
		"resurrection":
			return _presentation(3.10, Vector2(0.0, -0.72), 0.70, 1.08, 3.50, 1.04)
		"inner_fire":
			return _presentation(1.80, Vector2(0.0, -0.06), 0.72, 1.12, 2.55, 0.72)
		"power_word_shield":
			return _presentation(1.82, Vector2.ZERO, 0.70, 1.10, 2.45, 0.70)
		"holy_heal":
			return _presentation(1.72, Vector2.ZERO, 0.74, 1.08, 2.30, 0.66)
		_:
			return _presentation(1.84, Vector2.ZERO, 0.68, 1.10, 2.45, 0.70)


func _presentation(
	size_scale: float,
	center_offset: Vector2,
	start_scale: float,
	end_scale: float,
	duration_scale: float,
	minimum_duration: float
) -> Dictionary:
	return {
		"size_scale": size_scale,
		"center_offset": center_offset,
		"start_scale": start_scale,
		"end_scale": end_scale,
		"duration_scale": duration_scale,
		"minimum_duration": minimum_duration
	}
