extends RefCounted
class_name DalaranAnimationProvider

const TARGETED_KEYS: Array[String] = ["cone_of_cold"]

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
	if animation_key == "cone_of_cold":
		await play_cone_of_cold(owner, effect_root, caster_card, target_card)


func play_cone_of_cold(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card
) -> void:
	if owner == null or effect_root == null or caster_card == null or target_card == null:
		return

	var source_center := caster_card.get_global_rect().get_center()
	var target_rect := target_card.get_global_rect()
	var target_center := target_rect.get_center()
	var cast_vector := target_center - source_center
	if cast_vector.length_squared() <= 0.001:
		return

	var direction := cast_vector.normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var cone_width := maxf(target_rect.size.x, target_rect.size.y) * 0.72
	var cone := create_cone(source_center, target_center, perpendicular, cone_width)
	var outline := create_cone_outline(source_center, target_center, perpendicular, cone_width)
	var impact := create_impact_ring(target_rect)
	var shards := create_ice_shards(source_center, target_center, perpendicular, cone_width)

	effect_root.add_child(cone)
	effect_root.add_child(outline)
	for shard in shards:
		effect_root.add_child(shard)
	effect_root.add_child(impact)

	caster_card.is_animating = true
	target_card.is_animating = true
	var caster_scale := caster_card.scale
	var target_modulate := target_card.self_modulate

	var release_duration := maxf(spell_animation_duration * 0.72, 0.22)
	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_QUART)
	release.set_ease(Tween.EASE_OUT)
	release.tween_property(caster_card, "scale", caster_scale * 1.06, release_duration * 0.38)
	release.tween_property(cone, "modulate:a", 0.82, release_duration * 0.52)
	release.tween_property(outline, "modulate:a", 0.94, release_duration * 0.48)
	release.tween_property(impact, "scale", Vector2.ONE, release_duration * 0.66)
	release.tween_property(impact, "modulate:a", 0.92, release_duration * 0.56)
	release.tween_property(
		target_card,
		"self_modulate",
		Color(0.68, 0.92, 1.18, target_modulate.a),
		release_duration * 0.56
	)
	for shard in shards:
		var drift: Vector2 = shard.get_meta("ice_drift", Vector2.ZERO)
		release.tween_property(shard, "position", shard.position + drift, release_duration)
		release.tween_property(shard, "scale", Vector2.ONE, release_duration * 0.72)
		release.tween_property(shard, "modulate:a", 0.96, release_duration * 0.42)
	await release.finished

	var fade_duration := maxf(spell_animation_duration * 0.56, 0.18)
	var fade := owner.create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(caster_card, "scale", caster_scale, fade_duration)
	fade.tween_property(target_card, "self_modulate", target_modulate, fade_duration)
	fade.tween_property(cone, "modulate:a", 0.0, fade_duration)
	fade.tween_property(outline, "modulate:a", 0.0, fade_duration)
	fade.tween_property(impact, "scale", Vector2(1.42, 1.42), fade_duration)
	fade.tween_property(impact, "modulate:a", 0.0, fade_duration)
	for shard in shards:
		fade.tween_property(shard, "scale", Vector2(0.24, 0.24), fade_duration)
		fade.tween_property(shard, "modulate:a", 0.0, fade_duration)
	await fade.finished

	cone.queue_free()
	outline.queue_free()
	impact.queue_free()
	for shard in shards:
		shard.queue_free()
	caster_card.scale = caster_scale
	target_card.self_modulate = target_modulate
	caster_card.is_animating = false
	target_card.is_animating = false


func create_cone(
	source_center: Vector2,
	target_center: Vector2,
	perpendicular: Vector2,
	width: float
) -> Polygon2D:
	var cone := Polygon2D.new()
	cone.name = "ConeOfColdBody"
	cone.polygon = PackedVector2Array([
		source_center,
		target_center + perpendicular * width,
		target_center - perpendicular * width
	])
	cone.color = Color(0.24, 0.74, 1.0, 0.74)
	cone.modulate.a = 0.0
	cone.z_index = 2240
	return cone


func create_cone_outline(
	source_center: Vector2,
	target_center: Vector2,
	perpendicular: Vector2,
	width: float
) -> Line2D:
	var outline := Line2D.new()
	outline.name = "ConeOfColdOutline"
	outline.points = PackedVector2Array([
		source_center,
		target_center + perpendicular * width,
		target_center - perpendicular * width,
		source_center
	])
	outline.width = 4.0
	outline.default_color = Color(0.76, 0.96, 1.0, 0.96)
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.modulate.a = 0.0
	outline.z_index = 2242
	return outline


func create_ice_shards(
	source_center: Vector2,
	target_center: Vector2,
	perpendicular: Vector2,
	width: float
) -> Array[Polygon2D]:
	var shards: Array[Polygon2D] = []
	for index in range(9):
		var progress := 0.18 + float(index) * 0.085
		var side := -1.0 if index % 2 == 0 else 1.0
		var lateral := width * (0.10 + float(index % 3) * 0.13) * side
		var shard := Polygon2D.new()
		shard.name = "ConeOfColdShard_%d" % index
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -9.0),
			Vector2(4.0, 0.0),
			Vector2(0.0, 12.0),
			Vector2(-4.0, 0.0)
		])
		shard.position = source_center.lerp(target_center, progress) + perpendicular * lateral
		shard.rotation = 0.28 * side + float(index) * 0.16
		shard.scale = Vector2(0.18, 0.18)
		shard.color = Color(0.72, 0.96, 1.0, 0.98)
		shard.modulate.a = 0.0
		shard.z_index = 2246
		shard.set_meta("ice_drift", (target_center - source_center).normalized() * (18.0 + float(index) * 3.0))
		shards.append(shard)
	return shards


func create_impact_ring(target_rect: Rect2) -> Panel:
	var impact := Panel.new()
	impact.name = "ConeOfColdImpact"
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact.size = target_rect.size * 1.18
	impact.pivot_offset = impact.size * 0.5
	impact.global_position = target_rect.get_center() - impact.pivot_offset
	impact.scale = Vector2(0.32, 0.32)
	impact.modulate.a = 0.0
	impact.z_index = 2248

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.58, 0.92, 0.14)
	style.border_color = Color(0.72, 0.96, 1.0, 0.96)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.26, 0.76, 1.0, 0.62)
	style.shadow_size = 20
	impact.add_theme_stylebox_override("panel", style)
	return impact
