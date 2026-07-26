extends RefCounted
class_name DalaranFireAnimationPlayer

const DalaranSpellVisualScript := preload(
	"res://scripts/ui/animation/dalaran_spell_visual.gd"
)

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func play(
	owner: Node,
	effect_root: Control,
	source_position: Vector2,
	target_card: Card,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or target_card == null
		or not is_instance_valid(target_card)
	):
		return

	var is_pyro := animation_key == "pyroblast"
	var target_rect := target_card.get_global_rect()
	var target_position := target_rect.get_center()
	var cast_vector := target_position - source_position
	if cast_vector.length_squared() <= 0.001:
		return

	var direction := cast_vector.normalized()
	var source_rect := Rect2(
		source_position - target_rect.size * 0.36,
		target_rect.size * 0.72
	)
	var charge := _create_visual(
		source_rect,
		"pyroblast_charge" if is_pyro else "fireball_charge",
		1.70 if is_pyro else 1.36
	)
	effect_root.add_child(charge)

	var charge_duration := maxf(
		spell_animation_duration * (1.70 if is_pyro else 0.92),
		0.54 if is_pyro else 0.30
	)
	await _play_charge(owner, charge, charge_duration, is_pyro)

	var projectile_length := target_rect.size.x * (1.08 if is_pyro else 0.72)
	var projectile_height := target_rect.size.x * (0.54 if is_pyro else 0.36)
	var projectile := DalaranSpellVisualScript.new()
	projectile.name = "DalaranPyroblastProjectile" if is_pyro else "DalaranFireballProjectile"
	projectile.configure("pyroblast_projectile" if is_pyro else "fireball_projectile")
	projectile.size = Vector2(projectile_length, projectile_height)
	projectile.pivot_offset = projectile.size * 0.5
	projectile.global_position = source_position - projectile.pivot_offset
	projectile.rotation = direction.angle()
	projectile.modulate.a = 0.0
	projectile.z_index = 2530
	projectile.material = _create_additive_material()
	effect_root.add_child(projectile)

	var trail_sparks := _create_trail_sparks(
		effect_root,
		source_position,
		target_position,
		10 if is_pyro else 6,
		is_pyro
	)
	var flight_duration := clampf(
		cast_vector.length() / (780.0 if is_pyro else 980.0),
		0.34 if is_pyro else 0.24,
		0.64 if is_pyro else 0.46
	)
	await _play_flight(
		owner,
		projectile,
		trail_sparks,
		target_position,
		flight_duration
	)

	projectile.modulate.a = 0.0
	var impact := _create_visual(
		target_rect,
		"pyroblast_impact" if is_pyro else "fireball_impact",
		2.35 if is_pyro else 1.58
	)
	effect_root.add_child(impact)
	await _play_impact(owner, target_card, impact, is_pyro)

	charge.queue_free()
	projectile.queue_free()
	impact.queue_free()
	for spark in trail_sparks:
		spark.queue_free()


func _play_charge(
	owner: Node,
	charge: Control,
	duration: float,
	is_pyro: bool
) -> void:
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(charge, "progress", 1.0, duration)
	tween.tween_property(charge, "modulate:a", 1.0, duration * 0.46)
	tween.tween_property(
		charge,
		"scale",
		Vector2.ONE,
		duration * (0.82 if is_pyro else 0.64)
	)
	await tween.finished


func _play_flight(
	owner: Node,
	projectile: Control,
	trail_sparks: Array[Panel],
	target_position: Vector2,
	duration: float
) -> void:
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		projectile,
		"global_position",
		target_position - projectile.pivot_offset,
		duration
	)
	tween.tween_property(projectile, "progress", 1.0, duration)
	tween.tween_property(projectile, "modulate:a", 1.0, duration * 0.16)
	for spark_index in range(trail_sparks.size()):
		var spark := trail_sparks[spark_index]
		var spark_target: Vector2 = spark.get_meta("target_position", spark.global_position)
		var delay := duration * float(spark_index) * 0.035
		tween.tween_property(spark, "global_position", spark_target, duration * 0.82).set_delay(delay)
		tween.tween_property(spark, "modulate:a", 0.82, duration * 0.24).set_delay(delay)
		tween.tween_property(spark, "modulate:a", 0.0, duration * 0.32).set_delay(delay + duration * 0.46)
	await tween.finished


func _play_impact(
	owner: Node,
	target_card: Card,
	impact: Control,
	is_pyro: bool
) -> void:
	var target_position := target_card.position
	var target_scale := target_card.scale
	var target_modulate := target_card.self_modulate
	var duration := maxf(
		spell_animation_duration * (1.54 if is_pyro else 0.92),
		0.50 if is_pyro else 0.32
	)

	target_card.is_animating = true
	var burst := owner.create_tween()
	burst.set_parallel(true)
	burst.set_trans(Tween.TRANS_BACK)
	burst.set_ease(Tween.EASE_OUT)
	burst.tween_property(impact, "progress", 0.72, duration * 0.54)
	burst.tween_property(impact, "modulate:a", 1.0, duration * 0.26)
	burst.tween_property(impact, "scale", Vector2.ONE, duration * 0.54)
	burst.tween_property(
		target_card,
		"position",
		target_position + Vector2(-8.0 if is_pyro else -5.0, 2.0),
		duration * 0.30
	)
	burst.tween_property(target_card, "scale", target_scale * (0.94 if is_pyro else 0.97), duration * 0.30)
	burst.tween_property(
		target_card,
		"self_modulate",
		Color(1.0, 0.62 if is_pyro else 0.76, 0.38, target_modulate.a),
		duration * 0.34
	)
	await burst.finished

	var settle := owner.create_tween()
	settle.set_parallel(true)
	settle.set_trans(Tween.TRANS_SINE)
	settle.set_ease(Tween.EASE_OUT)
	settle.tween_property(impact, "progress", 1.0, duration * 0.46)
	settle.tween_property(impact, "modulate:a", 0.0, duration * 0.46)
	settle.tween_property(impact, "scale", Vector2(1.18, 1.18), duration * 0.46)
	settle.tween_property(target_card, "position", target_position, duration * 0.42)
	settle.tween_property(target_card, "scale", target_scale, duration * 0.42)
	settle.tween_property(target_card, "self_modulate", target_modulate, duration * 0.42)
	await settle.finished

	target_card.position = target_position
	target_card.scale = target_scale
	target_card.self_modulate = target_modulate
	target_card.is_animating = false


func _create_visual(target_rect: Rect2, key: String, size_scale: float) -> Control:
	var visual := DalaranSpellVisualScript.new()
	visual.name = "Dalaran_%s" % key
	visual.configure(key)
	visual.size = target_rect.size * size_scale
	visual.pivot_offset = visual.size * 0.5
	visual.global_position = target_rect.get_center() - visual.pivot_offset
	visual.scale = Vector2(0.48, 0.48)
	visual.modulate.a = 0.0
	visual.z_index = 2520
	visual.material = _create_additive_material()
	return visual


func _create_trail_sparks(
	effect_root: Control,
	source_position: Vector2,
	target_position: Vector2,
	count: int,
	is_pyro: bool
) -> Array[Panel]:
	var sparks: Array[Panel] = []
	var direction := (target_position - source_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	for spark_index in range(count):
		var spark := Panel.new()
		spark.name = "DalaranFireTrailSpark_%d" % spark_index
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var diameter := (8.0 if is_pyro else 6.0) + float(spark_index % 3) * 2.0
		spark.size = Vector2.ONE * diameter
		spark.pivot_offset = spark.size * 0.5
		spark.global_position = (
			source_position
			- spark.pivot_offset
			+ perpendicular * (float(spark_index % 3) - 1.0) * diameter
		)
		spark.modulate.a = 0.0
		spark.z_index = 2524
		spark.set_meta(
			"target_position",
			target_position
			- spark.pivot_offset
			- direction * float(count - spark_index) * diameter * 0.72
			+ perpendicular * (float(spark_index % 3) - 1.0) * diameter
		)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.52, 0.08, 0.92)
		style.border_color = Color(1.0, 0.88, 0.32, 0.94)
		style.set_border_width_all(1)
		style.set_corner_radius_all(999)
		style.shadow_color = Color(1.0, 0.22, 0.02, 0.68)
		style.shadow_size = 8 if is_pyro else 5
		spark.add_theme_stylebox_override("panel", style)
		effect_root.add_child(spark)
		sparks.append(spark)
	return sparks


func _create_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material
