extends RefCounted

# Large celestial spell choreography: full moon invocation and meteor effects.
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


func play_full_moon_cover(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfFullMoonCover",
		NightElfVfxRuntimeScript.TIME_VFX_Z_INDEX
	)
	var viewport_size := root.size
	var veil := ColorRect.new()
	veil.name = "FullMoonEnvironmentVeil"
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.size = viewport_size
	veil.color = Color(0.025, 0.045, 0.12, 0.0)
	veil.z_index = 0
	root.add_child(veil)

	var horizon_center := Vector2(viewport_size.x * 0.50, viewport_size.y * 0.17)
	var phase_size := clampf(
		minf(viewport_size.x, viewport_size.y) * 0.085,
		46.0,
		82.0
	)
	var phases: Array[Control] = []
	var phase_values: Array[float] = [-0.22, 0.12, 0.46, 0.72]
	for phase_index in range(phase_values.size()):
		var ratio := float(phase_index) / float(phase_values.size() - 1)
		var phase_center := (
			horizon_center
			+ Vector2(
				lerpf(-phase_size * 2.35, phase_size * 1.35, ratio),
				-sin(ratio * PI) * phase_size * 0.46
			)
		)
		var phase_moon := _vfx.create_moon_disc(
			phase_center,
			phase_size,
			phase_values[phase_index],
			Color(0.76, 0.86, 0.94, 0.76),
			Color(0.34, 0.48, 0.70, 0.54),
			10 + phase_index
		)
		phase_moon.modulate.a = 0.0
		phase_moon.scale = Vector2.ONE * 0.62
		root.add_child(phase_moon)
		phases.append(phase_moon)

	var full_moon_center := horizon_center + Vector2(phase_size * 2.25, 0.0)
	var full_moon := _vfx.create_moon_disc(
		full_moon_center,
		phase_size * 1.58,
		1.0,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_SILVER,
		20
	)
	full_moon.modulate.a = 0.0
	full_moon.scale = Vector2.ONE * 0.34
	root.add_child(full_moon)
	var moon_glow := _vfx.create_glow(
		full_moon_center,
		Vector2.ONE * phase_size * 2.70,
		Color(0.34, 0.54, 0.84, 0.22),
		18
	)
	moon_glow.modulate.a = 0.0
	root.add_child(moon_glow)
	var target_center: Vector2 = _runtime.to_root_local(
		root,
		target_rect.get_center()
	)
	var broad_beam := _vfx.create_moonbeam(
		target_center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(_runtime.card_scale(target_rect) * 2.25, viewport_size.y * 0.62),
		Color(0.84, 0.96, 1.0, 0.20),
		Color(0.24, 0.40, 0.68, 0.0),
		15,
		0.78,
		0.20
	)
	broad_beam.modulate.a = 0.0
	root.add_child(broad_beam)
	var stars := _vfx.create_particles(
		"FullMoonDescendingStarlight",
		Vector2(viewport_size.x * 0.5, viewport_size.y * 0.32),
		"star",
		Color(0.78, 0.90, 1.0, 0.62),
		28,
		0.92,
		Vector2.DOWN,
		24.0,
		Vector2(18.0, 52.0),
		Vector2(viewport_size.x * 0.28, viewport_size.y * 0.18),
		Vector2(0.0, 8.0),
		Vector2(0.10, 0.24),
		24,
		0.18
	)
	root.add_child(stars)

	var total_duration := _runtime.scaled_duration(2.45, 0.74)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(veil, "color:a", 0.18, total_duration * 0.34)
	for phase_index in range(phases.size()):
		var delay := float(phase_index) * total_duration * 0.085
		tween.tween_property(
			phases[phase_index],
			"modulate:a",
			0.78,
			total_duration * 0.22
		).set_delay(delay)
		tween.tween_property(
			phases[phase_index],
			"scale",
			Vector2.ONE,
			total_duration * 0.26
		).set_delay(delay)
		tween.tween_property(
			phases[phase_index],
			"modulate:a",
			0.0,
			total_duration * 0.16
		).set_delay(delay + total_duration * 0.27)
	tween.tween_property(
		full_moon,
		"modulate:a",
		1.0,
		total_duration * 0.28
	).set_delay(total_duration * 0.30)
	tween.tween_property(
		full_moon,
		"scale",
		Vector2.ONE,
		total_duration * 0.34
	).set_delay(total_duration * 0.30)
	tween.tween_property(
		moon_glow,
		"modulate:a",
		0.86,
		total_duration * 0.30
	).set_delay(total_duration * 0.34)
	tween.tween_property(
		broad_beam,
		"modulate:a",
		0.92,
		total_duration * 0.30
	).set_delay(total_duration * 0.42)
	await tween.finished
	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(0.46, 0.14))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.58, 0.18)
	)


func play_meteor_aura(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfMeteorAuraInvocation",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var center: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var base_size := _runtime.card_scale(target_rect)
	var beam := _vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(base_size * 1.18, base_size * 1.92),
		Color(0.88, 0.98, 1.0, 0.28),
		Color(0.26, 0.46, 0.74, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 4,
		0.84,
		0.26
	)
	var crescent := _vfx.create_crescent(
		center - Vector2(base_size * 0.22, base_size * 0.02),
		base_size * 0.84,
		-0.56,
		Color(0.92, 0.98, 1.0, 0.86),
		Color(0.38, 0.62, 0.90, 0.62),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 1,
		0.13
	)
	var orbit := _vfx.create_ring(
		center,
		Vector2(base_size * 0.56, base_size * 0.42),
		Color(0.62, 0.82, 0.98, 0.58),
		maxf(base_size * 0.012, 1.1),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX,
		56,
		-PI * 0.90,
		PI * 1.52
	)
	beam.modulate.a = 0.0
	crescent.scale = Vector2.ONE * 0.42
	crescent.modulate.a = 0.0
	orbit.scale = Vector2.ONE * 0.34
	orbit.modulate.a = 0.0
	root.add_child(beam)
	root.add_child(crescent)
	root.add_child(orbit)
	for star_index in range(3):
		var angle := -PI * 0.70 + float(star_index) * PI * 0.64
		var star := _vfx.create_star(
			center + Vector2(
				cos(angle) * base_size * 0.52,
				sin(angle) * base_size * 0.36
			),
			base_size * (0.038 + float(star_index) * 0.006),
			Color(0.92, 0.98, 1.0, 0.86),
			NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2
		)
		star.modulate.a = 0.0
		root.add_child(star)
		var star_tween := owner.create_tween()
		star_tween.tween_property(
			star,
			"modulate:a",
			1.0,
			_runtime.scaled_duration(0.45, 0.14)
		).set_delay(float(star_index) * 0.05)

	var duration := _runtime.scaled_duration(0.92, 0.28)
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_BACK)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(beam, "modulate:a", 0.94, duration * 0.62)
	rise.tween_property(crescent, "scale", Vector2.ONE, duration)
	rise.tween_property(crescent, "modulate:a", 1.0, duration * 0.66)
	rise.tween_property(orbit, "scale", Vector2.ONE, duration)
	rise.tween_property(orbit, "modulate:a", 0.82, duration * 0.72)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(_runtime.scaled_duration(0.52, 0.16))
	await hold.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.46, 0.14)
	)


func play_meteors(
	owner: Node,
	effect_root: Control,
	target_rects: Array[Rect2]
) -> void:
	var root := _vfx.create_root(
		effect_root,
		"NightElfMeteorFall",
		NightElfVfxRuntimeScript.VFX_Z_INDEX
	)
	var bundles: Array[Dictionary] = []
	for target_index in range(target_rects.size()):
		bundles.append(
			_create_meteor_bundle(root, target_rects[target_index], target_index)
		)

	var fall_duration := _runtime.scaled_duration(1.22, 0.38)
	var stagger := minf(_runtime.scaled_duration(0.15, 0.035), 0.07)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	for target_index in range(bundles.size()):
		tween.tween_method(
			Callable(self, "_set_meteor_progress").bind(bundles[target_index]),
			0.0,
			1.0,
			fall_duration
		).set_delay(float(target_index % 6) * stagger)
	await tween.finished
	var settle := owner.create_tween()
	settle.tween_interval(_runtime.scaled_duration(0.34, 0.11))
	await settle.finished
	await _runtime.finish_root(
		owner,
		root,
		_runtime.scaled_duration(0.30, 0.10)
	)


func _create_meteor_bundle(
	root: Control,
	target_rect: Rect2,
	target_index: int
) -> Dictionary:
	var target: Vector2 = _runtime.to_root_local(root, target_rect.get_center())
	var vertical_distance := maxf(root.size.y * 0.62, target_rect.size.y * 3.2)
	var side_sign := -1.0 if target_index % 2 == 0 else 1.0
	var start: Vector2 = target + Vector2(
		side_sign * target_rect.size.x
		* (0.90 + float(target_index % 3) * 0.16),
		-vertical_distance
	)
	var control: Vector2 = start.lerp(target, 0.56) + Vector2(
		-side_sign * target_rect.size.x * 0.34,
		-target_rect.size.y * 0.10
	)
	var base_size := _runtime.card_scale(target_rect)
	var outer_trail := _vfx.create_trail(
		"MoonMeteorOuterTrail",
		maxf(base_size * 0.085, 5.5),
		Color(0.62, 0.82, 1.0, 0.84),
		Color(0.28, 0.24, 0.60, 0.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 4
	)
	var core_trail := _vfx.create_trail(
		"MoonMeteorCoreTrail",
		maxf(base_size * 0.028, 2.0),
		Color(0.98, 1.0, 1.0, 0.98),
		Color(0.54, 0.68, 0.94, 0.32),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 3
	)
	root.add_child(outer_trail)
	root.add_child(core_trail)

	var body := Node2D.new()
	body.name = "FallingMoonMeteor"
	body.position = start
	body.z_index = NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX
	root.add_child(body)
	var halo := _vfx.create_glow(
		Vector2.ZERO,
		Vector2.ONE * base_size * 0.72,
		Color(0.40, 0.64, 1.0, 0.42),
		0
	)
	var core_glow := _vfx.create_glow(
		Vector2.ZERO,
		Vector2.ONE * base_size * 0.38,
		Color(0.92, 0.99, 1.0, 0.96),
		1
	)
	var star_core := _vfx.create_star(
		Vector2.ZERO,
		base_size * 0.12,
		Color(0.98, 1.0, 1.0, 0.98),
		2
	)
	body.add_child(halo)
	body.add_child(core_glow)
	body.add_child(star_core)

	var marker := _vfx.create_ring(
		target,
		Vector2(base_size * 0.34, base_size * 0.18),
		Color(0.66, 0.82, 1.0, 0.54),
		maxf(base_size * 0.012, 1.0),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 5
	)
	root.add_child(marker)
	var impact_glow := _vfx.create_glow(
		target,
		Vector2.ONE * base_size * 1.18,
		Color(0.58, 0.78, 1.0, 0.54),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX - 2
	)
	impact_glow.scale = Vector2.ONE * 0.18
	impact_glow.modulate.a = 0.0
	root.add_child(impact_glow)
	var impact_ring := _vfx.create_ring(
		target,
		Vector2(base_size * 0.46, base_size * 0.24),
		Color(0.90, 0.98, 1.0, 0.88),
		maxf(base_size * 0.022, 1.8),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 2
	)
	impact_ring.scale = Vector2.ONE * 0.14
	impact_ring.modulate.a = 0.0
	root.add_child(impact_ring)
	var impact_shards := _vfx.create_particles(
		"MoonMeteorImpactShards",
		target,
		"star",
		Color(0.76, 0.90, 1.0, 0.88),
		13,
		0.44,
		Vector2.UP,
		142.0,
		Vector2(54.0, 142.0),
		Vector2(base_size * 0.12, base_size * 0.08),
		Vector2(0.0, 34.0),
		Vector2(0.14, 0.34),
		NightElfVfxRuntimeScript.PROJECTILE_Z_INDEX + 4,
		0.96
	)
	impact_shards.emitting = false
	root.add_child(impact_shards)

	return {
		"start": start,
		"control": control,
		"target": target,
		"body": body,
		"outer_trail": outer_trail,
		"core_trail": core_trail,
		"marker": marker,
		"impact_glow": impact_glow,
		"impact_ring": impact_ring,
		"impact_shards": impact_shards,
		"impact_started": false
	}


func _set_meteor_progress(value: float, bundle: Dictionary) -> void:
	var body := bundle.get("body") as Node2D
	var outer_trail := bundle.get("outer_trail") as Line2D
	var core_trail := bundle.get("core_trail") as Line2D
	var marker := bundle.get("marker") as Line2D
	var impact_glow := bundle.get("impact_glow") as Control
	var impact_ring := bundle.get("impact_ring") as Line2D
	var impact_shards := bundle.get("impact_shards") as CPUParticles2D
	if (
		not is_instance_valid(body)
		or not is_instance_valid(outer_trail)
		or not is_instance_valid(core_trail)
	):
		return

	var start: Vector2 = bundle.get("start", Vector2.ZERO)
	var control: Vector2 = bundle.get("control", Vector2.ZERO)
	var target: Vector2 = bundle.get("target", Vector2.ZERO)
	var fall_progress := clampf(value / 0.78, 0.0, 1.0)
	var eased_fall := fall_progress * fall_progress * (3.0 - 2.0 * fall_progress)
	var point := _runtime.quadratic_bezier(
		start,
		control,
		target,
		eased_fall
	)
	var tangent_point := _runtime.quadratic_bezier(
		start,
		control,
		target,
		minf(eased_fall + 0.025, 1.0)
	)
	body.position = point
	body.rotation = (tangent_point - point).angle()
	body.scale = Vector2.ONE * (0.76 + eased_fall * 0.34)

	var points := PackedVector2Array()
	var trail_start := maxf(eased_fall - 0.34, 0.0)
	for point_index in range(18):
		var ratio := float(point_index) / 17.0
		points.append(
			_runtime.quadratic_bezier(
				start,
				control,
				target,
				lerpf(trail_start, eased_fall, ratio)
			)
		)
	outer_trail.points = points
	core_trail.points = points
	if is_instance_valid(marker):
		marker.modulate.a = 0.22 + (1.0 - fall_progress) * 0.32
		marker.scale = Vector2.ONE * (
			0.82 + sin(fall_progress * PI) * 0.18
		)

	var impact_progress := clampf((value - 0.70) / 0.30, 0.0, 1.0)
	if impact_progress <= 0.0:
		return
	if not bool(bundle.get("impact_started", false)):
		bundle["impact_started"] = true
		if is_instance_valid(impact_shards):
			impact_shards.restart()
			impact_shards.emitting = true
	body.modulate.a = clampf(1.0 - impact_progress * 4.2, 0.0, 1.0)
	outer_trail.modulate.a = clampf(
		1.0 - impact_progress * 2.8,
		0.0,
		1.0
	)
	core_trail.modulate.a = outer_trail.modulate.a
	if is_instance_valid(impact_glow):
		impact_glow.modulate.a = sin(impact_progress * PI) * 0.92
		impact_glow.scale = Vector2.ONE * lerpf(0.18, 1.24, impact_progress)
	if is_instance_valid(impact_ring):
		impact_ring.modulate.a = sin(impact_progress * PI) * 0.94
		impact_ring.scale = Vector2.ONE * lerpf(0.14, 1.36, impact_progress)
