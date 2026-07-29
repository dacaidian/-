extends RefCounted
class_name NightElfAnimationProvider

const NightElfVfxFactoryScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_factory.gd"
)

const TARGETED_KEYS: Array[String] = [
	"moonblade",
	"tranquil_spring",
	"precision_shot",
	"full_moon_cover",
	"meteor_aura",
	"meteor_strike",
	"claw_strike",
	"elune_grace"
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = [
	"moonblade",
	"tranquil_spring",
	"precision_shot",
	"full_moon_cover",
	"meteor_aura",
	"meteor_strike",
	"claw_strike"
]
const BOARD_KEYS: Array[String] = [
	"night_elf_time_transition",
	"night_elf_time_transition_sunrise",
	"night_elf_time_transition_noon",
	"night_elf_time_transition_dusk",
	"night_elf_time_transition_moonrise",
	"night_elf_time_transition_full_moon",
	"night_elf_time_transition_moonset"
]
const MULTI_RECT_KEYS: Array[String] = ["meteor_strike"]

const VFX_Z_INDEX := 2470
const PROJECTILE_Z_INDEX := 2490
const TIME_VFX_Z_INDEX := 2450

var spell_animation_duration := 0.32
var vfx := NightElfVfxFactoryScript.new()


func setup(duration: float) -> void:
	spell_animation_duration = maxf(duration, 0.04)


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)
	router.register_multi_rect(MULTI_RECT_KEYS, play_multi_rect)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	var target_rect := target_card.get_global_rect()
	match animation_key:
		"moonblade":
			if caster_card != null:
				await _play_moonblade_path(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_rect
				)
			else:
				await _play_moonblade_impact(owner, effect_root, target_rect)
		"tranquil_spring":
			if caster_card != null:
				await _play_tranquil_spring(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_rect
				)
			else:
				await _play_tranquil_spring_target(owner, effect_root, target_rect)
		"claw_strike":
			var source_rect := target_rect
			if caster_card != null:
				source_rect = caster_card.get_global_rect()
			await _play_claw_strike(owner, effect_root, source_rect, target_rect)
		_:
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

	match animation_key:
		"moonblade":
			await _play_moonblade_impact(owner, effect_root, target_rect)
		"tranquil_spring":
			await _play_tranquil_spring_target(owner, effect_root, target_rect)
		"precision_shot":
			await _play_precision_shot(owner, effect_root, target_rect)
		"full_moon_cover":
			await _play_full_moon_cover(owner, effect_root, target_rect)
		"meteor_aura":
			await _play_meteor_aura(owner, effect_root, target_rect)
		"meteor_strike":
			await _play_meteors(owner, effect_root, [target_rect])
		"claw_strike":
			var source_rect := Rect2(
				target_rect.position - Vector2(target_rect.size.x, target_rect.size.y * 0.35),
				target_rect.size
			)
			await _play_claw_strike(owner, effect_root, source_rect, target_rect)
		"elune_grace":
			await _play_elune_grace(owner, effect_root, target_rect)


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
	):
		return

	var target_rect := target_card.get_global_rect()
	match animation_key:
		"moonblade":
			await _play_moonblade_path(owner, effect_root, source_rect, target_rect)
		"tranquil_spring":
			await _play_tranquil_spring(owner, effect_root, source_rect, target_rect)
		"claw_strike":
			await _play_claw_strike(owner, effect_root, source_rect, target_rect)
		_:
			await play_at_rect(owner, effect_root, target_rect, animation_key)


func play_board(
	owner: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or not BOARD_KEYS.has(animation_key)
	):
		return

	await _play_time_transition(
		owner,
		effect_root,
		_get_time_state_from_animation_key(animation_key)
	)


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
		or animation_key != "meteor_strike"
	):
		return

	var valid_rects: Array[Rect2] = []
	for target_rect in target_rects:
		if target_rect.size != Vector2.ZERO:
			valid_rects.append(target_rect)
	if not valid_rects.is_empty():
		await _play_meteors(owner, effect_root, valid_rects)


func play_moonblade(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	first_card: Card,
	second_card: Card
) -> void:
	if (
		owner == null
		or effect_root == null
		or caster_card == null
		or first_card == null
		or second_card == null
	):
		return

	var root := vfx.create_root(
		effect_root,
		"NightElfMoonbladeSequence",
		VFX_Z_INDEX
	)
	var caster_rect := caster_card.get_global_rect()
	var first_rect := first_card.get_global_rect()
	var second_rect := second_card.get_global_rect()
	await _play_moonblade_charge(owner, root, caster_rect)

	var blade_bundle := _create_moonblade_bundle(
		root,
		caster_rect,
		first_rect
	)
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
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.34, 0.10))


func _play_moonblade_path(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfMoonblade",
		VFX_Z_INDEX
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
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.30, 0.09))


func _play_moonblade_impact(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfMoonbladeImpact",
		VFX_Z_INDEX
	)
	await _play_moonblade_cut(
		owner,
		root,
		target_rect,
		Vector2(0.78, 0.62).normalized(),
		1.0
	)
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.24, 0.08))


func _play_moonblade_charge(
	owner: Node,
	root: Control,
	source_rect: Rect2
) -> void:
	var center: Vector2 = source_rect.get_center()
	var base_size := _card_scale(source_rect)
	var glow := vfx.create_glow(
		center,
		Vector2.ONE * base_size * 0.90,
		Color(0.36, 0.64, 0.92, 0.22),
		PROJECTILE_Z_INDEX - 2
	)
	var crescent := vfx.create_crescent(
		center,
		base_size * 0.44,
		-0.56,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_SILVER,
		PROJECTILE_Z_INDEX,
		0.19
	)
	glow.scale = Vector2.ONE * 0.25
	glow.modulate.a = 0.0
	crescent.scale = Vector2.ONE * 0.18
	crescent.modulate.a = 0.0
	root.add_child(glow)
	root.add_child(crescent)

	var motes := vfx.create_particles(
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
		PROJECTILE_Z_INDEX - 1,
		0.42
	)
	root.add_child(motes)

	var duration := maxf(spell_animation_duration * 0.55, 0.16)
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
		minf(_card_scale(source_rect), _card_scale(target_rect)) * 0.42,
		34.0
	)
	var start_point := source_rect.get_center()
	var outer_trail := vfx.create_trail(
		"MoonbladeOuterTrail",
		maxf(blade_size * 0.16, 5.0),
		Color(0.82, 0.94, 1.0, 0.82),
		Color(0.28, 0.52, 0.82, 0.42),
		PROJECTILE_Z_INDEX - 3
	)
	var core_trail := vfx.create_trail(
		"MoonbladeCoreTrail",
		maxf(blade_size * 0.055, 1.8),
		Color(0.98, 1.0, 1.0, 0.98),
		Color(0.62, 0.82, 0.96, 0.66),
		PROJECTILE_Z_INDEX - 2
	)
	var glow := vfx.create_glow(
		start_point,
		Vector2.ONE * blade_size * 1.65,
		Color(0.32, 0.60, 0.94, 0.28),
		PROJECTILE_Z_INDEX - 1
	)
	var blade := vfx.create_crescent(
		start_point,
		blade_size,
		0.0,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_BLUE,
		PROJECTILE_Z_INDEX,
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
	var duration := maxf(spell_animation_duration * 1.05, 0.30)
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
		duration
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

	var point := _quadratic_bezier(start_point, control_point, end_point, value)
	var tangent_t := minf(value + 0.025, 1.0)
	var tangent_point := _quadratic_bezier(
		start_point,
		control_point,
		end_point,
		tangent_t
	)
	var tangent := (tangent_point - point).normalized()
	if tangent == Vector2.ZERO:
		tangent = (end_point - start_point).normalized()
	var local_point: Vector2 = _to_root_local(root, point)
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
			_to_root_local(
				root,
				_quadratic_bezier(
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
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var base_size := _card_scale(target_rect)
	var cut_rotation := hit_direction.angle() + PI * 0.48
	var outer_cut := vfx.create_crescent(
		center,
		base_size * 0.76 * strength,
		cut_rotation,
		Color(0.96, 0.995, 1.0, 0.98),
		Color(0.42, 0.72, 0.96, 0.88),
		PROJECTILE_Z_INDEX + 2,
		0.10
	)
	var inner_cut := vfx.create_crescent(
		center,
		base_size * 0.54 * strength,
		cut_rotation + 0.12,
		Color(0.98, 1.0, 1.0, 0.92),
		Color(0.68, 0.84, 0.98, 0.62),
		PROJECTILE_Z_INDEX + 3,
		0.23
	)
	outer_cut.scale = Vector2.ONE * 0.34
	inner_cut.scale = Vector2.ONE * 0.24
	root.add_child(outer_cut)
	root.add_child(inner_cut)
	var shards := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 4
	)
	root.add_child(shards)

	var duration := maxf(spell_animation_duration * 0.38, 0.13)
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
	var duration := maxf(spell_animation_duration * 0.20, 0.065)
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


func _play_claw_strike(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfPhysicalClawStrike",
		VFX_Z_INDEX
	)
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var direction := (target_rect.get_center() - source_rect.get_center()).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(0.78, 0.62).normalized()
	var slash_direction := direction.rotated(-0.42)
	var side := slash_direction.orthogonal()
	var length := maxf(_card_scale(target_rect) * 0.92, 62.0)
	var marks: Array[Node2D] = []

	for mark_index in range(3):
		var offset := side * (float(mark_index) - 1.0) * length * 0.15
		var path := PackedVector2Array([
			-slash_direction * length * 0.46 + offset,
			-slash_direction * length * 0.10 + side * length * 0.035 + offset,
			slash_direction * length * 0.18 - side * length * 0.025 + offset,
			slash_direction * length * 0.48 + offset
		])
		var mark := vfx.create_claw_mark(
			path,
			maxf(length * 0.052, 3.4),
			PROJECTILE_Z_INDEX + mark_index
		)
		mark.position = center
		mark.scale = Vector2(0.06, 1.0)
		mark.modulate.a = 0.0
		root.add_child(mark)
		marks.append(mark)

	var wind := vfx.create_trail(
		"ClawWindPressure",
		maxf(length * 0.025, 1.6),
		Color(0.68, 0.84, 0.90, 0.58),
		Color(0.24, 0.38, 0.42, 0.0),
		PROJECTILE_Z_INDEX - 2
	)
	wind.points = PackedVector2Array([
		center - direction * length * 0.58 - side * length * 0.22,
		center + direction * length * 0.54
	])
	wind.modulate.a = 0.0
	root.add_child(wind)

	var leaves := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 4,
		0.78
	)
	root.add_child(leaves)

	var rise_duration := maxf(spell_animation_duration * 0.34, 0.11)
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
	hold.tween_interval(maxf(spell_animation_duration * 0.22, 0.07))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.34, 0.12))


func _play_tranquil_spring(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfTranquilSpring",
		VFX_Z_INDEX
	)
	var source_center: Vector2 = _to_root_local(root, source_rect.get_center())
	var target_center: Vector2 = _to_root_local(root, target_rect.get_center())
	var source_scale := _card_scale(source_rect)

	var source_glow := vfx.create_glow(
		source_center,
		Vector2(source_scale * 1.30, source_scale * 0.72),
		Color(0.26, 0.68, 0.82, 0.24),
		PROJECTILE_Z_INDEX - 4
	)
	var source_ring := vfx.create_ring(
		source_center,
		Vector2(source_scale * 0.45, source_scale * 0.18),
		Color(0.72, 0.94, 1.0, 0.76),
		maxf(source_scale * 0.018, 1.4),
		PROJECTILE_Z_INDEX - 2
	)
	source_glow.scale = Vector2.ONE * 0.42
	source_glow.modulate.a = 0.0
	source_ring.scale = Vector2.ONE * 0.46
	source_ring.modulate.a = 0.0
	root.add_child(source_glow)
	root.add_child(source_ring)
	var source_water := vfx.create_particles(
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
		PROJECTILE_Z_INDEX - 1,
		0.32
	)
	root.add_child(source_water)

	var gather_duration := maxf(spell_animation_duration * 0.58, 0.17)
	var gather := owner.create_tween()
	gather.set_parallel(true)
	gather.set_trans(Tween.TRANS_SINE)
	gather.set_ease(Tween.EASE_OUT)
	gather.tween_property(source_glow, "scale", Vector2.ONE, gather_duration)
	gather.tween_property(source_glow, "modulate:a", 0.82, gather_duration)
	gather.tween_property(source_ring, "scale", Vector2.ONE, gather_duration)
	gather.tween_property(source_ring, "modulate:a", 1.0, gather_duration)
	await gather.finished

	var water_bundle := _create_water_transfer_bundle(root, source_center, target_center)
	var control_point: Vector2 = (
		source_center.lerp(target_center, 0.5)
		+ (target_center - source_center).normalized().orthogonal()
		* minf(source_center.distance_to(target_center) * 0.19, 72.0)
		- Vector2(0.0, minf(source_center.distance_to(target_center) * 0.16, 66.0))
	)
	var transfer_duration := maxf(spell_animation_duration * 1.05, 0.32)
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
		transfer_duration
	)
	await transfer.finished

	_add_tranquil_spring_target_layers(root, target_rect)
	var settle := owner.create_tween()
	settle.tween_interval(maxf(spell_animation_duration * 0.72, 0.23))
	await settle.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.45, 0.14))


func _play_tranquil_spring_target(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfTranquilSpringTarget",
		VFX_Z_INDEX
	)
	_add_tranquil_spring_target_layers(root, target_rect)
	var hold := owner.create_tween()
	hold.tween_interval(maxf(spell_animation_duration * 1.08, 0.34))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.42, 0.13))


func _create_water_transfer_bundle(
	root: Control,
	source_center: Vector2,
	target_center: Vector2
) -> Dictionary:
	var distance := source_center.distance_to(target_center)
	var outer_ribbon := vfx.create_trail(
		"TranquilWaterRibbon",
		clampf(distance * 0.018, 5.0, 12.0),
		Color(0.66, 0.94, 1.0, 0.82),
		Color(0.18, 0.56, 0.76, 0.26),
		PROJECTILE_Z_INDEX - 2
	)
	var inner_ribbon := vfx.create_trail(
		"TranquilWaterCore",
		clampf(distance * 0.006, 1.8, 4.2),
		Color(0.94, 0.995, 1.0, 0.96),
		Color(0.50, 0.84, 0.96, 0.48),
		PROJECTILE_Z_INDEX - 1
	)
	var droplet_size := clampf(distance * 0.085, 30.0, 58.0)
	var droplet := vfx.create_glow(
		source_center,
		Vector2(droplet_size, droplet_size * 1.22),
		Color(0.48, 0.86, 1.0, 0.74),
		PROJECTILE_Z_INDEX
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

	var point := _quadratic_bezier(start_point, control_point, end_point, value)
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
			_quadratic_bezier(
				start_point,
				control_point,
				end_point,
				lerpf(start_t, value, ratio)
			)
		)
	outer_ribbon.points = points
	inner_ribbon.points = points


func _add_tranquil_spring_target_layers(root: Control, target_rect: Rect2) -> void:
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var base_size := _card_scale(target_rect)
	var beam := vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.28),
		Vector2(base_size * 1.24, base_size * 1.92),
		Color(0.82, 0.97, 1.0, 0.40),
		Color(0.24, 0.58, 0.78, 0.0),
		PROJECTILE_Z_INDEX - 4,
		0.94,
		0.30
	)
	var glow := vfx.create_glow(
		center,
		Vector2(base_size * 1.28, base_size * 0.84),
		Color(0.34, 0.78, 0.92, 0.28),
		PROJECTILE_Z_INDEX - 3
	)
	var ripple_outer := vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.30),
		Vector2(base_size * 0.50, base_size * 0.17),
		Color(0.72, 0.94, 1.0, 0.72),
		maxf(base_size * 0.018, 1.4),
		PROJECTILE_Z_INDEX - 1
	)
	var ripple_inner := vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.30),
		Vector2(base_size * 0.32, base_size * 0.11),
		Color(0.92, 0.99, 1.0, 0.80),
		maxf(base_size * 0.012, 1.0),
		PROJECTILE_Z_INDEX
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

	var water := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 2,
		0.44
	)
	var cleansed_fragments := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 1,
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


func _play_precision_shot(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfPrecisionShot",
		VFX_Z_INDEX
	)
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var base_size := _card_scale(target_rect)
	var beam := vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.16),
		Vector2(base_size * 0.78, base_size * 1.54),
		Color(0.88, 0.98, 1.0, 0.30),
		Color(0.24, 0.48, 0.74, 0.0),
		PROJECTILE_Z_INDEX - 4,
		0.86,
		0.36
	)
	var bow_center: Vector2 = center - Vector2(base_size * 0.10, 0.0)
	var bow := vfx.create_ring(
		bow_center,
		Vector2(base_size * 0.30, base_size * 0.42),
		Color(0.88, 0.97, 1.0, 0.92),
		maxf(base_size * 0.018, 1.5),
		PROJECTILE_Z_INDEX,
		42,
		-PI * 0.48,
		PI * 0.96
	)
	var string := Line2D.new()
	string.name = "PrecisionBowString"
	string.width = maxf(base_size * 0.009, 1.0)
	string.default_color = Color(0.68, 0.88, 0.98, 0.74)
	string.antialiased = true
	string.z_index = PROJECTILE_Z_INDEX
	string.points = PackedVector2Array([
		bow_center + Vector2.from_angle(-PI * 0.48) * Vector2(base_size * 0.30, base_size * 0.42),
		bow_center - Vector2(base_size * 0.18, 0.0),
		bow_center + Vector2.from_angle(PI * 0.48) * Vector2(base_size * 0.30, base_size * 0.42)
	])
	var aim_end: Vector2 = center + Vector2(base_size * 1.12, 0.0)
	var aim_line := vfx.create_trail(
		"PrecisionAimLine",
		maxf(base_size * 0.012, 1.1),
		Color(0.98, 1.0, 1.0, 0.92),
		Color(0.42, 0.72, 0.94, 0.0),
		PROJECTILE_Z_INDEX - 1
	)
	aim_line.points = PackedVector2Array([
		bow_center - Vector2(base_size * 0.18, 0.0),
		aim_end
	])
	var arrow := vfx.create_arrow(
		center + Vector2(base_size * 0.10, 0.0),
		Vector2.RIGHT,
		base_size * 0.88,
		Color(0.96, 0.995, 1.0, 0.96),
		PROJECTILE_Z_INDEX + 1
	)
	var elune_mark := vfx.create_crescent(
		center - Vector2(0.0, base_size * 0.55),
		base_size * 0.24,
		-0.62,
		Color(0.94, 0.99, 1.0, 0.92),
		Color(0.50, 0.74, 0.92, 0.68),
		PROJECTILE_Z_INDEX + 2,
		0.18
	)
	for item in [beam, bow, string, aim_line, arrow, elune_mark]:
		item.modulate.a = 0.0
		root.add_child(item)
	var motes := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 3,
		0.36
	)
	root.add_child(motes)

	var rise_duration := maxf(spell_animation_duration * 0.64, 0.19)
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
	rise.tween_property(arrow, "position:x", arrow.position.x + base_size * 0.10, rise_duration)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(maxf(spell_animation_duration * 0.64, 0.18))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.42, 0.13))


func _play_full_moon_cover(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfFullMoonCover",
		TIME_VFX_Z_INDEX
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
	var phase_size := clampf(minf(viewport_size.x, viewport_size.y) * 0.085, 46.0, 82.0)
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
		var phase_moon := vfx.create_moon_disc(
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

	var full_moon := vfx.create_moon_disc(
		horizon_center + Vector2(phase_size * 2.25, 0.0),
		phase_size * 1.58,
		1.0,
		NightElfVfxFactoryScript.MOON_CORE,
		NightElfVfxFactoryScript.MOON_SILVER,
		20
	)
	full_moon.modulate.a = 0.0
	full_moon.scale = Vector2.ONE * 0.34
	root.add_child(full_moon)
	var moon_glow := vfx.create_glow(
		horizon_center + Vector2(phase_size * 2.25, 0.0),
		Vector2.ONE * phase_size * 2.70,
		Color(0.34, 0.54, 0.84, 0.22),
		18
	)
	moon_glow.modulate.a = 0.0
	root.add_child(moon_glow)
	var target_center: Vector2 = _to_root_local(root, target_rect.get_center())
	var broad_beam := vfx.create_moonbeam(
		target_center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(_card_scale(target_rect) * 2.25, viewport_size.y * 0.62),
		Color(0.84, 0.96, 1.0, 0.20),
		Color(0.24, 0.40, 0.68, 0.0),
		15,
		0.78,
		0.20
	)
	broad_beam.modulate.a = 0.0
	root.add_child(broad_beam)
	var stars := vfx.create_particles(
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

	var total_duration := maxf(spell_animation_duration * 2.45, 0.74)
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
	hold.tween_interval(maxf(spell_animation_duration * 0.46, 0.14))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.58, 0.18))


func _play_meteor_aura(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfMeteorAuraInvocation",
		VFX_Z_INDEX
	)
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var base_size := _card_scale(target_rect)
	var beam := vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(base_size * 1.18, base_size * 1.92),
		Color(0.88, 0.98, 1.0, 0.28),
		Color(0.26, 0.46, 0.74, 0.0),
		PROJECTILE_Z_INDEX - 4,
		0.84,
		0.26
	)
	var crescent := vfx.create_crescent(
		center - Vector2(base_size * 0.22, base_size * 0.02),
		base_size * 0.84,
		-0.56,
		Color(0.92, 0.98, 1.0, 0.86),
		Color(0.38, 0.62, 0.90, 0.62),
		PROJECTILE_Z_INDEX - 1,
		0.13
	)
	var orbit := vfx.create_ring(
		center,
		Vector2(base_size * 0.56, base_size * 0.42),
		Color(0.62, 0.82, 0.98, 0.58),
		maxf(base_size * 0.012, 1.1),
		PROJECTILE_Z_INDEX,
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
		var star := vfx.create_star(
			center + Vector2(cos(angle) * base_size * 0.52, sin(angle) * base_size * 0.36),
			base_size * (0.038 + float(star_index) * 0.006),
			Color(0.92, 0.98, 1.0, 0.86),
			PROJECTILE_Z_INDEX + 2
		)
		star.modulate.a = 0.0
		root.add_child(star)
		var star_tween := owner.create_tween()
		star_tween.tween_property(
			star,
			"modulate:a",
			1.0,
			maxf(spell_animation_duration * 0.45, 0.14)
		).set_delay(float(star_index) * 0.05)

	var duration := maxf(spell_animation_duration * 0.92, 0.28)
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
	hold.tween_interval(maxf(spell_animation_duration * 0.52, 0.16))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.46, 0.14))


func _play_meteors(
	owner: Node,
	effect_root: Control,
	target_rects: Array[Rect2]
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfMeteorFall",
		VFX_Z_INDEX
	)
	var bundles: Array[Dictionary] = []
	for target_index in range(target_rects.size()):
		bundles.append(
			_create_meteor_bundle(root, target_rects[target_index], target_index)
		)

	var fall_duration := maxf(spell_animation_duration * 1.22, 0.38)
	var stagger := minf(maxf(spell_animation_duration * 0.15, 0.035), 0.07)
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
	settle.tween_interval(maxf(spell_animation_duration * 0.34, 0.11))
	await settle.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.30, 0.10))


func _create_meteor_bundle(
	root: Control,
	target_rect: Rect2,
	target_index: int
) -> Dictionary:
	var target: Vector2 = _to_root_local(root, target_rect.get_center())
	var vertical_distance := maxf(root.size.y * 0.62, target_rect.size.y * 3.2)
	var side_sign := -1.0 if target_index % 2 == 0 else 1.0
	var start: Vector2 = target + Vector2(
		side_sign * target_rect.size.x * (0.90 + float(target_index % 3) * 0.16),
		-vertical_distance
	)
	var control: Vector2 = start.lerp(target, 0.56) + Vector2(
		-side_sign * target_rect.size.x * 0.34,
		-target_rect.size.y * 0.10
	)
	var base_size := _card_scale(target_rect)
	var outer_trail := vfx.create_trail(
		"MoonMeteorOuterTrail",
		maxf(base_size * 0.085, 5.5),
		Color(0.62, 0.82, 1.0, 0.84),
		Color(0.28, 0.24, 0.60, 0.0),
		PROJECTILE_Z_INDEX - 4
	)
	var core_trail := vfx.create_trail(
		"MoonMeteorCoreTrail",
		maxf(base_size * 0.028, 2.0),
		Color(0.98, 1.0, 1.0, 0.98),
		Color(0.54, 0.68, 0.94, 0.32),
		PROJECTILE_Z_INDEX - 3
	)
	root.add_child(outer_trail)
	root.add_child(core_trail)

	var body := Node2D.new()
	body.name = "FallingMoonMeteor"
	body.position = start
	body.z_index = PROJECTILE_Z_INDEX
	root.add_child(body)
	var halo := vfx.create_glow(
		Vector2.ZERO,
		Vector2.ONE * base_size * 0.72,
		Color(0.40, 0.64, 1.0, 0.42),
		0
	)
	var core_glow := vfx.create_glow(
		Vector2.ZERO,
		Vector2.ONE * base_size * 0.38,
		Color(0.92, 0.99, 1.0, 0.96),
		1
	)
	var star_core := vfx.create_star(
		Vector2.ZERO,
		base_size * 0.12,
		Color(0.98, 1.0, 1.0, 0.98),
		2
	)
	body.add_child(halo)
	body.add_child(core_glow)
	body.add_child(star_core)

	var marker := vfx.create_ring(
		target,
		Vector2(base_size * 0.34, base_size * 0.18),
		Color(0.66, 0.82, 1.0, 0.54),
		maxf(base_size * 0.012, 1.0),
		PROJECTILE_Z_INDEX - 5
	)
	root.add_child(marker)
	var impact_glow := vfx.create_glow(
		target,
		Vector2.ONE * base_size * 1.18,
		Color(0.58, 0.78, 1.0, 0.54),
		PROJECTILE_Z_INDEX - 2
	)
	impact_glow.scale = Vector2.ONE * 0.18
	impact_glow.modulate.a = 0.0
	root.add_child(impact_glow)
	var impact_ring := vfx.create_ring(
		target,
		Vector2(base_size * 0.46, base_size * 0.24),
		Color(0.90, 0.98, 1.0, 0.88),
		maxf(base_size * 0.022, 1.8),
		PROJECTILE_Z_INDEX + 2
	)
	impact_ring.scale = Vector2.ONE * 0.14
	impact_ring.modulate.a = 0.0
	root.add_child(impact_ring)
	var impact_shards := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 4,
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
	var point := _quadratic_bezier(start, control, target, eased_fall)
	var tangent_point := _quadratic_bezier(
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
			_quadratic_bezier(
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
		marker.scale = Vector2.ONE * (0.82 + sin(fall_progress * PI) * 0.18)

	var impact_progress := clampf((value - 0.70) / 0.30, 0.0, 1.0)
	if impact_progress > 0.0:
		if not bool(bundle.get("impact_started", false)):
			bundle["impact_started"] = true
			if is_instance_valid(impact_shards):
				impact_shards.restart()
				impact_shards.emitting = true
		body.modulate.a = clampf(1.0 - impact_progress * 4.2, 0.0, 1.0)
		outer_trail.modulate.a = clampf(1.0 - impact_progress * 2.8, 0.0, 1.0)
		core_trail.modulate.a = outer_trail.modulate.a
		if is_instance_valid(impact_glow):
			impact_glow.modulate.a = sin(impact_progress * PI) * 0.92
			impact_glow.scale = Vector2.ONE * lerpf(0.18, 1.24, impact_progress)
		if is_instance_valid(impact_ring):
			impact_ring.modulate.a = sin(impact_progress * PI) * 0.94
			impact_ring.scale = Vector2.ONE * lerpf(0.14, 1.36, impact_progress)


func _play_elune_grace(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfEluneGrace",
		VFX_Z_INDEX
	)
	var center: Vector2 = _to_root_local(root, target_rect.get_center())
	var base_size := _card_scale(target_rect)
	var beam := vfx.create_moonbeam(
		center + Vector2(0.0, target_rect.size.y * 0.20),
		Vector2(base_size * 0.86, base_size * 1.62),
		Color(0.88, 0.98, 1.0, 0.24),
		Color(0.28, 0.48, 0.72, 0.0),
		PROJECTILE_Z_INDEX - 3,
		0.72,
		0.34
	)
	var crescent := vfx.create_crescent(
		center - Vector2(0.0, base_size * 0.36),
		base_size * 0.42,
		-0.64,
		Color(0.94, 0.99, 1.0, 0.90),
		Color(0.50, 0.74, 0.92, 0.62),
		PROJECTILE_Z_INDEX,
		0.17
	)
	var blessing_arc := vfx.create_ring(
		center + Vector2(0.0, target_rect.size.y * 0.24),
		Vector2(base_size * 0.42, base_size * 0.15),
		Color(0.72, 0.90, 1.0, 0.62),
		maxf(base_size * 0.012, 1.0),
		PROJECTILE_Z_INDEX - 1,
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
	var stars := vfx.create_particles(
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
		PROJECTILE_Z_INDEX + 2,
		0.38
	)
	root.add_child(stars)

	var duration := maxf(spell_animation_duration * 0.82, 0.24)
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
	hold.tween_interval(maxf(spell_animation_duration * 0.42, 0.13))
	await hold.finished
	await _finish_root(owner, root, maxf(spell_animation_duration * 0.38, 0.12))


func _play_time_transition(
	owner: Node,
	effect_root: Control,
	state_id: String
) -> void:
	var root := vfx.create_root(
		effect_root,
		"NightElfTimeTransition_%s" % state_id,
		TIME_VFX_Z_INDEX
	)
	var viewport_size := root.size
	if viewport_size == Vector2.ZERO:
		root.queue_free()
		return
	var presentation := vfx.phase_presentation(state_id)
	var veil_color: Color = presentation.get("veil", Color.TRANSPARENT)
	var veil := ColorRect.new()
	veil.name = "NightElfTimeEnvironment"
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.size = viewport_size
	veil.color = Color(veil_color.r, veil_color.g, veil_color.b, 0.0)
	veil.z_index = 0
	root.add_child(veil)

	var symbol_center := Vector2(viewport_size.x * 0.50, viewport_size.y * 0.18)
	var symbol_size := clampf(
		minf(viewport_size.x, viewport_size.y) * 0.22,
		108.0,
		192.0
	)
	var symbol_nodes := _create_time_symbol(
		root,
		state_id,
		symbol_center,
		symbol_size,
		presentation
	)
	for symbol_node in symbol_nodes:
		symbol_node.modulate.a = 0.0
		symbol_node.scale = Vector2.ONE * 0.54
		symbol_node.position.y -= symbol_size * 0.12

	var is_night := state_id in ["moonrise", "full_moon", "moonset"]
	var particle_kind := "star" if is_night else "leaf"
	var particle_color := (
		Color(0.76, 0.90, 1.0, 0.54)
		if is_night
		else Color(0.28, 0.44, 0.38, 0.46)
	)
	if state_id == "dusk":
		particle_color = Color(0.58, 0.50, 0.62, 0.48)
	var total_duration := maxf(spell_animation_duration * 3.80, 1.35)
	var ambient_particles := vfx.create_particles(
		"NightElfTimeAmbient",
		Vector2(viewport_size.x * 0.50, viewport_size.y * 0.32),
		particle_kind,
		particle_color,
		18 if is_night else 11,
		total_duration * 0.88,
		Vector2.DOWN if is_night else Vector2.RIGHT,
		34.0,
		Vector2(12.0, 38.0),
		Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
		Vector2(0.0, 8.0),
		Vector2(0.10, 0.26),
		30,
		0.20
	)
	root.add_child(ambient_particles)

	var rise_duration := total_duration * 0.30
	var hold_duration := total_duration * 0.42
	var fade_duration := total_duration * 0.28
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_QUART)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(veil, "color:a", veil_color.a, rise_duration)
	for symbol_node in symbol_nodes:
		rise.tween_property(symbol_node, "modulate:a", 1.0, rise_duration * 0.86)
		rise.tween_property(symbol_node, "scale", Vector2.ONE, rise_duration)
		rise.tween_property(
			symbol_node,
			"position:y",
			symbol_node.position.y + symbol_size * 0.12,
			rise_duration
		)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(hold_duration)
	await hold.finished
	await _finish_root(owner, root, fade_duration)


func _create_time_symbol(
	root: Control,
	state_id: String,
	center: Vector2,
	diameter: float,
	presentation: Dictionary
) -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	var core: Color = presentation.get(
		"core",
		NightElfVfxFactoryScript.MOON_CORE
	)
	var edge: Color = presentation.get(
		"edge",
		NightElfVfxFactoryScript.MOON_SILVER
	)
	var phase := float(presentation.get("phase", 1.0))
	var glow := vfx.create_glow(
		center,
		Vector2.ONE * diameter * 1.72,
		Color(edge.r, edge.g, edge.b, edge.a * 0.30),
		8
	)
	root.add_child(glow)
	nodes.append(glow)

	var disc := vfx.create_moon_disc(
		center,
		diameter,
		phase,
		core,
		edge,
		10
	)
	root.add_child(disc)
	nodes.append(disc)

	match state_id:
		"sunrise":
			var dawn_arc := vfx.create_ring(
				center + Vector2(0.0, diameter * 0.20),
				Vector2(diameter * 0.62, diameter * 0.30),
				Color(0.78, 0.56, 0.40, 0.54),
				maxf(diameter * 0.018, 1.4),
				12,
				52,
				-PI * 0.92,
				PI * 0.84
			)
			root.add_child(dawn_arc)
			nodes.append(dawn_arc)
		"dusk":
			var first_moon := vfx.create_crescent(
				center + Vector2(diameter * 0.22, -diameter * 0.10),
				diameter * 0.54,
				-0.55,
				Color(0.78, 0.84, 0.94, 0.78),
				Color(0.46, 0.38, 0.66, 0.54),
				13,
				0.18
			)
			root.add_child(first_moon)
			nodes.append(first_moon)
		"moonrise":
			disc.modulate.a = 0.0
			nodes.erase(disc)
			var rising_crescent := vfx.create_crescent(
				center,
				diameter,
				-0.56,
				core,
				edge,
				11,
				0.17
			)
			root.add_child(rising_crescent)
			nodes.append(rising_crescent)
		"moonset":
			disc.modulate.a = 0.0
			nodes.erase(disc)
			var setting_crescent := vfx.create_crescent(
				center,
				diameter,
				PI + 0.56,
				core,
				edge,
				11,
				0.17
			)
			root.add_child(setting_crescent)
			nodes.append(setting_crescent)
	return nodes


func _get_time_state_from_animation_key(animation_key: String) -> String:
	const PREFIX := "night_elf_time_transition_"
	if animation_key.begins_with(PREFIX):
		var state_id := animation_key.trim_prefix(PREFIX)
		if state_id != "":
			return state_id
	return "full_moon"


func _finish_root(owner: Node, root: Control, duration: float) -> void:
	if owner == null or not is_instance_valid(root):
		return
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(root, "modulate:a", 0.0, maxf(duration, 0.04))
	await tween.finished
	if is_instance_valid(root):
		root.queue_free()


func _card_scale(target_rect: Rect2) -> float:
	return maxf(minf(target_rect.size.x, target_rect.size.y), 52.0)


func _to_root_local(root: Control, global_point: Vector2) -> Vector2:
	return global_point - root.global_position


func _quadratic_bezier(
	start_point: Vector2,
	control_point: Vector2,
	end_point: Vector2,
	t: float
) -> Vector2:
	var clamped_t := clampf(t, 0.0, 1.0)
	var inverse := 1.0 - clamped_t
	return (
		start_point * inverse * inverse
		+ control_point * 2.0 * inverse * clamped_t
		+ end_point * clamped_t * clamped_t
	)
