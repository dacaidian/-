extends RefCounted

# Restorative and unit-buff choreography with no board-wide environment ownership.
const NightElfVfxFactoryScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_factory.gd"
)
const NightElfVfxRuntimeScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_runtime.gd"
)

var _vfx: NightElfVfxFactoryScript
var _runtime: NightElfVfxRuntimeScript


func setup(
	vfx_factory: NightElfVfxFactoryScript,
	runtime: NightElfVfxRuntimeScript
) -> void:
	_vfx = vfx_factory
	_runtime = runtime


func play_tranquil_spring(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfTranquilSpring",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var source_center: Vector2 = _runtime.to_root_local(
		root,
		source_rect.get_center()
	)
	var target_center: Vector2 = _runtime.to_root_local(
		root,
		target_rect.get_center()
	)
	var source_scale := _runtime.card_scale(source_rect)

	var source_glow := _vfx.create_glow(
		source_center,
		Vector2(source_scale * 1.30, source_scale * 0.72),
		Color(0.26, 0.68, 0.82, 0.24),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 4
	)
	var source_ring := _vfx.create_ring(
		source_center,
		Vector2(source_scale * 0.45, source_scale * 0.18),
		Color(0.72, 0.94, 1.0, 0.76),
		maxf(source_scale * 0.018, 1.4),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	source_glow.scale = Vector2.ONE * 0.42
	source_glow.modulate.a = 0.0
	source_ring.scale = Vector2.ONE * 0.46
	source_ring.modulate.a = 0.0
	root.add_child(source_glow)
	root.add_child(source_ring)
	var source_water := _vfx.create_particles(
		"MoonwellWaterRise",
		source_center,
		"water",
		Color(0.58, 0.90, 1.0, 0.78),
		14,
		0.62,
		Vector2.UP,
		24.0,
		Vector2(18.0, 52.0),
		Vector2(source_scale * 0.28, source_scale * 0.08),
		Vector2(0.0, -18.0),
		Vector2(0.18, 0.40),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1,
		0.32
	)
	root.add_child(source_water)

	var gather_duration := _runtime.scaled_duration(0.58, 0.17)
	var gather := owner.create_tween()
	gather.set_parallel(true)
	gather.set_trans(Tween.TRANS_SINE)
	gather.set_ease(Tween.EASE_OUT)
	gather.tween_property(source_glow, "scale", Vector2.ONE, gather_duration)
	gather.tween_property(source_glow, "modulate:a", 0.82, gather_duration)
	gather.tween_property(source_ring, "scale", Vector2.ONE, gather_duration)
	gather.tween_property(source_ring, "modulate:a", 1.0, gather_duration)
	await gather.finished

	var water_bundle := _create_water_transfer_bundle(
		root,
		source_center,
		target_center
	)
	var control_point: Vector2 = (
		source_center.lerp(target_center, 0.5)
		+ (target_center - source_center).normalized().orthogonal()
		* minf(source_center.distance_to(target_center) * 0.19, 72.0)
		- Vector2(
			0.0,
			minf(source_center.distance_to(target_center) * 0.16, 66.0)
		)
	)
	var transfer := owner.create_tween()
	transfer.set_trans(Tween.TRANS_SINE)
	transfer.set_ease(Tween.EASE_IN_OUT)
	transfer.tween_method(
		Callable(self, "_set_water_transfer_progress").bind(
			water_bundle,
			source_center,
			control_point,
			target_center
		),
		0.0,
		1.0,
		_runtime.scaled_duration(1.05, 0.32)
	)
	await transfer.finished

	_add_tranquil_spring_target_layers(root, target_rect)
	var settle := owner.create_tween()
	settle.tween_interval(_runtime.scaled_duration(0.72, 0.23))
	await settle.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.45, 0.14)
	)


func play_tranquil_spring_target(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfTranquilSpringTarget",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	_add_tranquil_spring_target_layers(root, target_rect)
	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(1.08, 0.34))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.42, 0.13)
	)


func play_precision_shot(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfPrecisionShot",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var base_size := _runtime.card_scale(target_rect)
	var beam := _vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.16),
		Vector2(base_size * 0.78, base_size * 1.54),
		Color(0.88, 0.98, 1.0, 0.30),
		Color(0.24, 0.48, 0.74, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 4,
		0.86,
		0.36
	)
	var bow_center: Vector2 = center - Vector2(base_size * 0.10, 0.0)
	var bow := _vfx.create_ring(
		bow_center,
		Vector2(base_size * 0.30, base_size * 0.42),
		Color(0.88, 0.97, 1.0, 0.92),
		maxf(base_size * 0.018, 1.5),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX,
		42,
		-PI * 0.48,
		PI * 0.96
	)
	var string := Line2D.new()
	string.name = "PrecisionBowString"
	string.width = maxf(base_size * 0.009, 1.0)
	string.default_color = Color(0.68, 0.88, 0.98, 0.74)
	string.antialiased = true
	string.z_index = NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX
	string.points = PackedVector2Array([
		bow_center + Vector2.from_angle(-PI * 0.48)
		* Vector2(base_size * 0.30, base_size * 0.42),
		bow_center - Vector2(base_size * 0.18, 0.0),
		bow_center + Vector2.from_angle(PI * 0.48)
		* Vector2(base_size * 0.30, base_size * 0.42)
	])
	var aim_end: Vector2 = center + Vector2(base_size * 1.12, 0.0)
	var aim_line := _vfx.create_trail(
		"PrecisionAimLine",
		maxf(base_size * 0.012, 1.1),
		Color(0.98, 1.0, 1.0, 0.92),
		Color(0.42, 0.72, 0.94, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1
	)
	aim_line.points = PackedVector2Array([
		bow_center - Vector2(base_size * 0.18, 0.0),
		aim_end
	])
	var arrow := _vfx.create_arrow(
		center + Vector2(base_size * 0.10, 0.0),
		Vector2.RIGHT,
		base_size * 0.88,
		Color(0.96, 0.995, 1.0, 0.96),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 1
	)
	var elune_mark := _vfx.create_crescent(
		center - Vector2(0.0, base_size * 0.55),
		base_size * 0.24,
		-0.62,
		Color(0.94, 0.99, 1.0, 0.92),
		Color(0.50, 0.74, 0.92, 0.68),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2,
		0.18
	)
	for item in [beam, bow, string, aim_line, arrow, elune_mark]:
		item.modulate.a = 0.0
		root.add_child(item)
	var motes := _vfx.create_particles(
		"PrecisionFocusedStarlight",
		center,
		"star",
		Color(0.82, 0.94, 1.0, 0.78),
		10,
		0.54,
		Vector2.RIGHT,
		18.0,
		Vector2(12.0, 38.0),
		target_rect.size * 0.20,
		Vector2.ZERO,
		Vector2(0.12, 0.26),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 3,
		0.36
	)
	root.add_child(motes)

	var rise_duration := _runtime.scaled_duration(0.64, 0.19)
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_SINE)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(beam, "modulate:a", 0.92, rise_duration)
	rise.tween_property(bow, "modulate:a", 1.0, rise_duration)
	rise.tween_property(string, "modulate:a", 1.0, rise_duration)
	rise.tween_property(aim_line, "modulate:a", 0.92, rise_duration)
	rise.tween_property(arrow, "modulate:a", 1.0, rise_duration)
	rise.tween_property(elune_mark, "modulate:a", 1.0, rise_duration)
	rise.tween_property(
		arrow,
		"position:x",
		arrow.position.x + base_size * 0.10,
		rise_duration
	)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(0.64, 0.18))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.42, 0.13)
	)


func play_elune_grace(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfEluneGrace",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var base_size := _runtime.card_scale(target_rect)
	var beam := _vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.20),
		Vector2(base_size * 0.86, base_size * 1.62),
		Color(0.88, 0.98, 1.0, 0.24),
		Color(0.28, 0.48, 0.72, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 3,
		0.72,
		0.34
	)
	var crescent := _vfx.create_crescent(
		center - Vector2(0.0, base_size * 0.36),
		base_size * 0.42,
		-0.64,
		Color(0.94, 0.99, 1.0, 0.90),
		Color(0.50, 0.74, 0.92, 0.62),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX,
		0.17
	)
	var blessing_arc := _vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(base_size * 0.42, base_size * 0.15),
		Color(0.72, 0.90, 1.0, 0.62),
		maxf(base_size * 0.012, 1.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1,
		52,
		-PI * 0.86,
		PI * 1.48
	)
	beam.modulate.a = 0.0
	crescent.scale = Vector2.ONE * 0.32
	crescent.modulate.a = 0.0
	blessing_arc.scale = Vector2.ONE * 0.42
	blessing_arc.modulate.a = 0.0
	root.add_child(beam)
	root.add_child(crescent)
	root.add_child(blessing_arc)
	var stars := _vfx.create_particles(
		"EluneGraceStarlight",
		center,
		"star",
		Color(0.82, 0.94, 1.0, 0.72),
		12,
		0.62,
		Vector2.UP,
		44.0,
		Vector2(16.0, 48.0),
		target_rect.size * 0.18,
		Vector2(0.0, -12.0),
		Vector2(0.10, 0.24),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2,
		0.38
	)
	root.add_child(stars)

	var duration := _runtime.scaled_duration(0.82, 0.24)
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_BACK)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(beam, "modulate:a", 0.86, duration * 0.68)
	rise.tween_property(crescent, "scale", Vector2.ONE, duration)
	rise.tween_property(crescent, "modulate:a", 1.0, duration * 0.68)
	rise.tween_property(blessing_arc, "scale", Vector2.ONE, duration)
	rise.tween_property(blessing_arc, "modulate:a", 0.86, duration * 0.72)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(0.42, 0.13))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.38, 0.12)
	)


func _create_water_transfer_bundle(
	root: Control,
	source_center: Vector2,
	target_center: Vector2
) -> Dictionary:
	var distance := source_center.distance_to(target_center)
	var outer_ribbon := _vfx.create_trail(
		"TranquilWaterRibbon",
		clampf(distance * 0.018, 5.0, 12.0),
		Color(0.66, 0.94, 1.0, 0.82),
		Color(0.18, 0.56, 0.76, 0.26),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	var inner_ribbon := _vfx.create_trail(
		"TranquilWaterCore",
		clampf(distance * 0.006, 1.8, 4.2),
		Color(0.94, 0.995, 1.0, 0.96),
		Color(0.50, 0.84, 0.96, 0.48),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1
	)
	var droplet_size := clampf(distance * 0.085, 30.0, 58.0)
	var droplet := _vfx.create_glow(
		source_center,
		Vector2(droplet_size, droplet_size * 1.22),
		Color(0.48, 0.86, 1.0, 0.74),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX
	)
	root.add_child(outer_ribbon)
	root.add_child(inner_ribbon)
	root.add_child(droplet)
	return {
		"outer_ribbon": outer_ribbon,
		"inner_ribbon": inner_ribbon,
		"droplet": droplet
	}


func _set_water_transfer_progress(
	value: float,
	water_bundle: Dictionary,
	start_point: Vector2,
	control_point: Vector2,
	end_point: Vector2
) -> void:
	var outer_ribbon := water_bundle.get("outer_ribbon") as Line2D
	var inner_ribbon := water_bundle.get("inner_ribbon") as Line2D
	var droplet := water_bundle.get("droplet") as Control
	if (
		not is_instance_valid(outer_ribbon)
		or not is_instance_valid(inner_ribbon)
		or not is_instance_valid(droplet)
	):
		return

	var point := _runtime.quadratic_bezier(
		start_point,
		control_point,
		end_point,
		value
	)
	droplet.position = point - droplet.pivot_offset
	droplet.scale = Vector2(
		0.86 + sin(value * PI) * 0.24,
		1.08 - sin(value * PI) * 0.10
	)
	var points := PackedVector2Array()
	var start_t := maxf(value - 0.52, 0.0)
	for point_index in range(20):
		var ratio := float(point_index) / 19.0
		points.append(
			_runtime.quadratic_bezier(
				start_point,
				control_point,
				end_point,
				lerpf(start_t, value, ratio)
			)
		)
	outer_ribbon.points = points
	inner_ribbon.points = points


func _add_tranquil_spring_target_layers(
	root: Control,
	target_rect: Rect2
) -> void:
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var base_size := _runtime.card_scale(target_rect)
	var beam := _vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.28),
		Vector2(base_size * 1.24, base_size * 1.92),
		Color(0.82, 0.97, 1.0, 0.40),
		Color(0.24, 0.58, 0.78, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 4,
		0.94,
		0.30
	)
	var glow := _vfx.create_glow(
		center,
		Vector2(base_size * 1.28, base_size * 0.84),
		Color(0.34, 0.78, 0.92, 0.28),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 3
	)
	var ripple_outer := _vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.30),
		Vector2(base_size * 0.50, base_size * 0.17),
		Color(0.72, 0.94, 1.0, 0.72),
		maxf(base_size * 0.018, 1.4),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1
	)
	var ripple_inner := _vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.30),
		Vector2(base_size * 0.32, base_size * 0.11),
		Color(0.92, 0.99, 1.0, 0.80),
		maxf(base_size * 0.012, 1.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX
	)
	beam.scale = Vector2(0.66, 0.12)
	beam.modulate.a = 0.0
	glow.scale = Vector2.ONE * 0.42
	glow.modulate.a = 0.0
	ripple_outer.scale = Vector2.ONE * 0.28
	ripple_inner.scale = Vector2.ONE * 0.20
	root.add_child(beam)
	root.add_child(glow)
	root.add_child(ripple_outer)
	root.add_child(ripple_inner)

	var water := _vfx.create_particles(
		"TranquilHealingWater",
		center + Vector2(0.0, target_rect.size.y * 0.18),
		"water",
		Color(0.66, 0.94, 1.0, 0.86),
		18,
		0.66,
		Vector2.UP,
		32.0,
		Vector2(24.0, 74.0),
		Vector2(base_size * 0.26, base_size * 0.10),
		Vector2(0.0, -22.0),
		Vector2(0.16, 0.38),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2,
		0.44
	)
	var cleansed_fragments := _vfx.create_particles(
		"TranquilCleansedFragments",
		center,
		"leaf",
		Color(0.08, 0.13, 0.20, 0.62),
		9,
		0.48,
		Vector2.UP,
		128.0,
		Vector2(42.0, 88.0),
		target_rect.size * 0.18,
		Vector2(0.0, 18.0),
		Vector2(0.16, 0.30),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 1,
		0.86
	)
	root.add_child(water)
	root.add_child(cleansed_fragments)

	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(beam, "scale", Vector2.ONE, 0.24)
	tween.tween_property(beam, "modulate:a", 1.0, 0.16)
	tween.tween_property(glow, "scale", Vector2.ONE, 0.28)
	tween.tween_property(glow, "modulate:a", 0.88, 0.18)
	tween.tween_property(ripple_outer, "scale", Vector2.ONE, 0.30)
	tween.tween_property(ripple_inner, "scale", Vector2.ONE, 0.24)
