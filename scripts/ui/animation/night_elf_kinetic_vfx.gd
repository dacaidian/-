extends RefCounted

# Projectile and physical-hit choreography: moonblade and claw strike.
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


func play_moonblade(
	owner: Node,
	effect_root: Control,
	caster_rect: Rect2,
	first_rect: Rect2,
	second_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfMoonbladeSequence",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	await _play_moonblade_charge(owner, root, caster_rect)

	var blade_bundle := _create_moonblade_bundle(root, caster_rect, first_rect)
	var first_direction := await _fly_moonblade_segment(
		owner,
		root,
		blade_bundle,
		caster_rect.get_center(),
		first_rect.get_center(),
		1.0
	)
	await _play_moonblade_cut(owner, root, first_rect, first_direction, 1.0)
	await _play_moonblade_pivot(owner, blade_bundle)

	_clear_moonblade_trails(blade_bundle)
	var second_direction := await _fly_moonblade_segment(
		owner,
		root,
		blade_bundle,
		first_rect.get_center(),
		second_rect.get_center(),
		-1.0
	)
	await _play_moonblade_cut(owner, root, second_rect, second_direction, 0.82)
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.34, 0.10)
	)


func play_moonblade_path(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfMoonblade",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	await _play_moonblade_charge(owner, root, source_rect)
	var blade_bundle := _create_moonblade_bundle(root, source_rect, target_rect)
	var hit_direction := await _fly_moonblade_segment(
		owner,
		root,
		blade_bundle,
		source_rect.get_center(),
		target_rect.get_center(),
		1.0
	)
	await _play_moonblade_cut(owner, root, target_rect, hit_direction, 1.0)
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.30, 0.09)
	)


func play_moonblade_impact(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfMoonbladeImpact",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	await _play_moonblade_cut(
		owner,
		root,
		target_rect,
		Vector2(0.78, 0.62).normalized(),
		1.0
	)
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.24, 0.08)
	)


func play_claw_strike(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfPhysicalClawStrike",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var direction := (target_rect.get_center() - source_rect.get_center()).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(0.78, 0.62).normalized()
	var slash_direction := direction.rotated(-0.42)
	var side := slash_direction.orthogonal()
	var length := maxf(_runtime.card_scale(target_rect) * 0.92, 62.0)
	var marks: Array[Node2D] = []

	for mark_index in range(3):
		var offset := side * (float(mark_index) - 1.0) * length * 0.15
		var path := PackedVector2Array([
			-slash_direction * length * 0.46 + offset,
			-slash_direction * length * 0.10 + side * length * 0.035 + offset,
			slash_direction * length * 0.18 - side * length * 0.025 + offset,
			slash_direction * length * 0.48 + offset
		])
		var mark := _vfx.create_claw_mark(
			path,
			maxf(length * 0.052, 3.4),
			NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + mark_index
		)
		mark.position = center
		mark.scale = Vector2(0.06, 1.0)
		mark.modulate.a = 0.0
		root.add_child(mark)
		marks.append(mark)

	var wind := _vfx.create_trail(
		"ClawWindPressure",
		maxf(length * 0.025, 1.6),
		Color(0.68, 0.84, 0.90, 0.58),
		Color(0.24, 0.38, 0.42, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	wind.points = PackedVector2Array([
		center - direction * length * 0.58 - side * length * 0.22,
		center + direction * length * 0.54
	])
	wind.modulate.a = 0.0
	root.add_child(wind)

	var leaves := _vfx.create_particles(
		"ClawWindLeaves",
		center,
		"leaf",
		Color(0.24, 0.42, 0.37, 0.66),
		7,
		0.42,
		direction,
		34.0,
		Vector2(58.0, 122.0),
		target_rect.size * 0.16,
		Vector2(0.0, 14.0),
		Vector2(0.20, 0.44),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 4,
		0.78
	)
	root.add_child(leaves)

	var rise_duration := _runtime.scaled_duration(0.34, 0.11)
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_QUART)
	rise.set_ease(Tween.EASE_OUT)
	for mark_index in range(marks.size()):
		rise.tween_property(
			marks[mark_index],
			"scale",
			Vector2.ONE,
			rise_duration
		).set_delay(float(mark_index) * 0.025)
		rise.tween_property(
			marks[mark_index],
			"modulate:a",
			1.0,
			rise_duration * 0.58
		).set_delay(float(mark_index) * 0.025)
	rise.tween_property(wind, "modulate:a", 0.74, rise_duration)
	await rise.finished

	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(0.22, 0.07))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.34, 0.12)
	)


func _play_moonblade_charge(
	owner: Node,
	root: Control,
	source_rect: Rect2
) -> void:
	var center: Vector2 = source_rect.get_center()
	var base_size := _runtime.card_scale(source_rect)
	var glow := _vfx.create_glow(
		center,
		Vector2.ONE * base_size * 0.90,
		Color(0.36, 0.64, 0.92, 0.22),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	var crescent := _vfx.create_crescent(
		center,
		base_size * 0.44,
		-0.56,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_SILVER,
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX,
		0.19
	)
	glow.scale = Vector2.ONE * 0.25
	glow.modulate.a = 0.0
	crescent.scale = Vector2.ONE * 0.18
	crescent.modulate.a = 0.0
	root.add_child(glow)
	root.add_child(crescent)

	var motes := _vfx.create_particles(
		"MoonbladeChargeMotes",
		center,
		"star",
		Color(0.78, 0.92, 1.0, 0.82),
		10,
		0.38,
		Vector2.UP,
		70.0,
		Vector2(10.0, 28.0),
		Vector2.ONE * base_size * 0.16,
		Vector2(0.0, -8.0),
		Vector2(0.16, 0.34),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1,
		0.42
	)
	root.add_child(motes)

	var duration := _runtime.scaled_duration(0.55, 0.16)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "scale", Vector2.ONE, duration)
	tween.tween_property(glow, "modulate:a", 0.78, duration * 0.72)
	tween.tween_property(crescent, "scale", Vector2.ONE, duration)
	tween.tween_property(crescent, "modulate:a", 1.0, duration * 0.62)
	tween.tween_property(crescent, "rotation", 0.26, duration)
	await tween.finished
	glow.queue_free()
	crescent.queue_free()


func _create_moonblade_bundle(
	root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> Dictionary:
	var blade_size := maxf(
		minf(
			_runtime.card_scale(source_rect),
			_runtime.card_scale(target_rect)
		) * 0.42,
		34.0
	)
	var start_point := source_rect.get_center()
	var outer_trail := _vfx.create_trail(
		"MoonbladeOuterTrail",
		maxf(blade_size * 0.16, 5.0),
		Color(0.82, 0.94, 1.0, 0.82),
		Color(0.28, 0.52, 0.82, 0.42),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 3
	)
	var core_trail := _vfx.create_trail(
		"MoonbladeCoreTrail",
		maxf(blade_size * 0.055, 1.8),
		Color(0.98, 1.0, 1.0, 0.98),
		Color(0.62, 0.82, 0.96, 0.66),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	var glow := _vfx.create_glow(
		start_point,
		Vector2.ONE * blade_size * 1.65,
		Color(0.32, 0.60, 0.94, 0.28),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1
	)
	var blade := _vfx.create_crescent(
		start_point,
		blade_size,
		0.0,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_BLUE,
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX,
		0.18
	)
	root.add_child(outer_trail)
	root.add_child(core_trail)
	root.add_child(glow)
	root.add_child(blade)
	return {
		"blade": blade,
		"glow": glow,
		"outer_trail": outer_trail,
		"core_trail": core_trail
	}


func _fly_moonblade_segment(
	owner: Node,
	root: Control,
	blade_bundle: Dictionary,
	start_point: Vector2,
	end_point: Vector2,
	curve_direction: float
) -> Vector2:
	var direction := end_point - start_point
	var normal := (
		direction.normalized().orthogonal()
		if direction.length() > 0.01
		else Vector2.UP
	)
	var control_point: Vector2 = (
		start_point.lerp(end_point, 0.5)
		+ normal * minf(direction.length() * 0.23, 92.0) * curve_direction
	)
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		Callable(self, "_set_moonblade_flight_progress").bind(
			root,
			blade_bundle,
			start_point,
			control_point,
			end_point
		),
		0.0,
		1.0,
		_runtime.scaled_duration(1.05, 0.30)
	)
	await tween.finished
	return (end_point - control_point).normalized()


func _set_moonblade_flight_progress(
	value: float,
	root: Control,
	blade_bundle: Dictionary,
	start_point: Vector2,
	control_point: Vector2,
	end_point: Vector2
) -> void:
	var blade := blade_bundle.get("blade") as Control
	var glow := blade_bundle.get("glow") as Control
	var outer_trail := blade_bundle.get("outer_trail") as Line2D
	var core_trail := blade_bundle.get("core_trail") as Line2D
	if (
		not is_instance_valid(blade)
		or not is_instance_valid(glow)
		or not is_instance_valid(outer_trail)
		or not is_instance_valid(core_trail)
	):
		return

	var point := _runtime.quadratic_bezier(
		start_point,
		control_point,
		end_point,
		value
	)
	var tangent_point := _runtime.quadratic_bezier(
		start_point,
		control_point,
		end_point,
		minf(value + 0.025, 1.0)
	)
	var tangent := (tangent_point - point).normalized()
	if tangent == Vector2.ZERO:
		tangent = (end_point - start_point).normalized()
	var local_point: Vector2 = _runtime.to_root_local(root, point)
	blade.position = local_point - blade.pivot_offset
	glow.position = local_point - glow.pivot_offset
	blade.rotation = tangent.angle() + value * TAU * 2.8
	glow.rotation = blade.rotation * 0.18
	glow.scale = Vector2.ONE * (0.92 + sin(value * PI) * 0.22)

	var trail_points := PackedVector2Array()
	var trail_start := maxf(value - 0.42, 0.0)
	for point_index in range(18):
		var ratio := float(point_index) / 17.0
		var sample_t := lerpf(trail_start, value, ratio)
		trail_points.append(
			_runtime.to_root_local(
				root,
				_runtime.quadratic_bezier(
					start_point,
					control_point,
					end_point,
					sample_t
				)
			)
		)
	outer_trail.points = trail_points
	core_trail.points = trail_points


func _play_moonblade_cut(
	owner: Node,
	root: Control,
	target_rect: Rect2,
	hit_direction: Vector2,
	strength: float
) -> void:
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var base_size := _runtime.card_scale(target_rect)
	var cut_rotation := hit_direction.angle() + PI * 0.48
	var outer_cut := _vfx.create_crescent(
		center,
		base_size * 0.76 * strength,
		cut_rotation,
		Color(0.96, 0.995, 1.0, 0.98),
		Color(0.42, 0.72, 0.96, 0.88),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2,
		0.10
	)
	var inner_cut := _vfx.create_crescent(
		center,
		base_size * 0.54 * strength,
		cut_rotation + 0.12,
		Color(0.98, 1.0, 1.0, 0.92),
		Color(0.68, 0.84, 0.98, 0.62),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 3,
		0.23
	)
	outer_cut.scale = Vector2.ONE * 0.34
	inner_cut.scale = Vector2.ONE * 0.24
	root.add_child(outer_cut)
	root.add_child(inner_cut)
	var shards := _vfx.create_particles(
		"MoonbladeSilverShards",
		center,
		"star",
		Color(0.82, 0.94, 1.0, 0.88),
		9,
		0.30,
		hit_direction,
		74.0,
		Vector2(34.0, 92.0),
		Vector2.ONE * base_size * 0.08,
		Vector2.ZERO,
		Vector2(0.12, 0.26),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 4
	)
	root.add_child(shards)

	var duration := _runtime.scaled_duration(0.38, 0.13)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(outer_cut, "scale", Vector2.ONE * 1.18, duration)
	tween.tween_property(outer_cut, "modulate:a", 0.0, duration)
	tween.tween_property(inner_cut, "scale", Vector2.ONE, duration * 0.72)
	tween.tween_property(inner_cut, "modulate:a", 0.0, duration)
	await tween.finished
	outer_cut.queue_free()
	inner_cut.queue_free()


func _play_moonblade_pivot(owner: Node, blade_bundle: Dictionary) -> void:
	var blade := blade_bundle.get("blade") as Control
	var glow := blade_bundle.get("glow") as Control
	if not is_instance_valid(blade) or not is_instance_valid(glow):
		return
	var duration := _runtime.scaled_duration(0.20, 0.065)
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(blade, "scale", Vector2.ONE * 1.22, duration)
	tween.parallel().tween_property(blade, "rotation", blade.rotation + 0.72, duration)
	tween.parallel().tween_property(glow, "scale", Vector2.ONE * 1.28, duration)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blade, "scale", Vector2.ONE, duration * 0.72)
	tween.parallel().tween_property(glow, "scale", Vector2.ONE, duration * 0.72)
	await tween.finished


func _clear_moonblade_trails(blade_bundle: Dictionary) -> void:
	var outer_trail := blade_bundle.get("outer_trail") as Line2D
	var core_trail := blade_bundle.get("core_trail") as Line2D
	if is_instance_valid(outer_trail):
		outer_trail.clear_points()
	if is_instance_valid(core_trail):
		core_trail.clear_points()
