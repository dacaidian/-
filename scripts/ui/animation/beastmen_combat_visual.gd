extends Control

const Palette := preload("res://scripts/ui/animation/beastmen_vfx_palette.gd")

var animation_key := ""
var source_center := Vector2.ZERO
var target_center := Vector2.ZERO
var card_size := Vector2(120.0, 168.0)
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(
	key: String,
	local_source_center: Vector2,
	local_target_center: Vector2,
	target_card_size: Vector2
) -> void:
	animation_key = key
	source_center = local_source_center
	target_center = local_target_center
	card_size = target_card_size
	queue_redraw()


func _draw() -> void:
	match animation_key:
		"beastmen_evolution":
			_draw_evolution()
		"beastmen_slaughter":
			_draw_slaughter_growth()
		"wanmo_charge":
			_draw_wanmo_charge()
		"savage_roar_buff":
			_draw_roar_buff()


func _draw_evolution() -> void:
	var scale_value := _card_scale()
	var gather := Palette.phase(progress, 0.0, 0.34)
	var rupture := Palette.phase(progress, 0.22, 0.68)
	var reveal := Palette.phase(progress, 0.46, 0.86)
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)

	_draw_absorbing_streaks(target_center, scale_value, gather, 7)
	_draw_rough_card_frame(
		target_center,
		card_size * (1.02 + reveal * 0.06),
		Palette.with_alpha(Palette.DRIED_BLOOD, 0.20 * settle + 0.12),
		Palette.with_alpha(Palette.BONE, 0.52 * reveal * settle),
		2.2 + reveal * 1.8
	)

	var horn_alpha := Palette.ease_out(reveal) * settle
	_draw_horn_crown(target_center + Vector2(0.0, -card_size.y * 0.18), scale_value * 0.46, horn_alpha)
	_draw_growth_spine(target_center, scale_value, reveal, settle)
	_draw_ground_impact(target_center + Vector2(0.0, card_size.y * 0.46), scale_value, rupture, settle)


func _draw_slaughter_growth() -> void:
	var scale_value := _card_scale()
	var close_phase := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.42))
	var absorb_phase := Palette.ease_out(Palette.phase(progress, 0.16, 0.68))
	var scar_phase := Palette.phase(progress, 0.34, 0.78)
	var settle := 1.0 - Palette.phase(progress, 0.78, 1.0)

	_draw_closing_jaws(target_center, scale_value, close_phase, settle)
	_draw_absorbing_streaks(target_center, scale_value * 1.12, absorb_phase, 9)
	_draw_slash_group(target_center, scale_value, scar_phase, settle)

	var core_radius := scale_value * (0.055 + 0.040 * sin(absorb_phase * PI))
	draw_circle(
		target_center,
		core_radius * 2.2,
		Palette.with_alpha(Palette.CHAOS_PURPLE, 0.18 * absorb_phase * settle)
	)
	draw_circle(
		target_center,
		core_radius,
		Palette.with_alpha(Palette.CHAOS_GREEN, 0.78 * absorb_phase * settle)
	)
	for pip_index in range(3):
		var pip_angle := -PI * 0.78 + float(pip_index) * PI * 0.78
		var pip_center := target_center + Vector2(cos(pip_angle), sin(pip_angle)) * scale_value * 0.24
		draw_circle(pip_center, scale_value * 0.018, Palette.with_alpha(Palette.EMBER, 0.88 * scar_phase * settle))


func _draw_wanmo_charge() -> void:
	var scale_value := _card_scale()
	var fall_phase := Palette.ease_out(Palette.phase(progress, 0.0, 0.48))
	var crack_phase := Palette.ease_out(Palette.phase(progress, 0.28, 0.74))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var impact_center := target_center + Vector2(0.0, card_size.y * 0.04)

	var ember_start := target_center + Vector2(-scale_value * 0.42, -scale_value * 0.72)
	var ember_center := ember_start.lerp(impact_center, fall_phase)
	var trail := PackedVector2Array()
	for point_index in range(9):
		var ratio := float(point_index) / 8.0
		var sample_phase := maxf(fall_phase - (1.0 - ratio) * 0.22, 0.0)
		trail.append(ember_start.lerp(impact_center, sample_phase))
	_draw_layered_line(
		trail,
		Palette.with_alpha(Palette.DRIED_BLOOD, 0.86 * settle),
		Palette.with_alpha(Palette.EMBER, 0.92 * settle),
		scale_value * 0.055,
		scale_value * 0.018
	)
	draw_circle(ember_center, scale_value * 0.045, Palette.with_alpha(Palette.EMBER, 0.96 * settle))

	_draw_stone_cracks(impact_center, scale_value, crack_phase, settle)
	_draw_bone_notches(target_center, scale_value, crack_phase, settle)


func _draw_roar_buff() -> void:
	var scale_value := _card_scale()
	var carve_phase := Palette.ease_out(Palette.phase(progress, 0.0, 0.62))
	var settle := 1.0 - Palette.phase(progress, 0.74, 1.0)
	var attack_anchor := target_center + Vector2(-card_size.x * 0.30, card_size.y * 0.33)

	for slash_index in range(3):
		var offset := Vector2(float(slash_index - 1) * scale_value * 0.075, float(slash_index) * scale_value * 0.025)
		var start_point := attack_anchor + offset + Vector2(-scale_value * 0.16, scale_value * 0.13)
		var end_point := attack_anchor + offset + Vector2(scale_value * 0.17, -scale_value * 0.18) * carve_phase
		var slash_points := _jagged_segment(start_point, end_point, 7, scale_value * 0.018)
		_draw_layered_line(
			slash_points,
			Palette.with_alpha(Palette.SOIL_BLACK, 0.76 * settle),
			Palette.with_alpha(Palette.BLOOD_EDGE, 0.90 * settle),
			scale_value * 0.044,
			scale_value * 0.018
		)

	var pulse_radius := scale_value * (0.18 + carve_phase * 0.22)
	draw_arc(
		attack_anchor,
		pulse_radius,
		PI * 0.82,
		PI * 1.76,
		26,
		Palette.with_alpha(Palette.DARK_ORANGE, 0.62 * (1.0 - carve_phase) * settle),
		2.2,
		true
	)


func _draw_absorbing_streaks(center: Vector2, scale_value: float, phase_value: float, count: int) -> void:
	if phase_value <= 0.0:
		return
	for streak_index in range(count):
		var angle := TAU * float(streak_index) / float(count) + float(streak_index % 3) * 0.11
		var tangent := Vector2(cos(angle), sin(angle))
		var start_radius := scale_value * (0.78 + float(streak_index % 4) * 0.08)
		var end_radius := scale_value * (0.12 + (1.0 - phase_value) * 0.44)
		var start_point := center + tangent * start_radius
		var end_point := center + tangent.rotated(0.34) * end_radius
		var control_a := start_point + tangent.orthogonal() * scale_value * (0.18 + float(streak_index % 2) * 0.05)
		var control_b := end_point + tangent.orthogonal() * scale_value * 0.10
		var visible_points := _cubic_curve(start_point, control_a, control_b, end_point, phase_value, 16)
		_draw_layered_line(
			visible_points,
			Palette.with_alpha(Palette.SOIL_BLACK, 0.56 * phase_value),
			Palette.with_alpha(Palette.DRIED_BLOOD if streak_index % 2 == 0 else Palette.DUST, 0.76 * phase_value),
			scale_value * 0.028,
			scale_value * 0.010
		)


func _draw_horn_crown(center: Vector2, radius: float, alpha: float) -> void:
	if alpha <= 0.001:
		return
	for side_sign in [-1.0, 1.0]:
		var base := center + Vector2(side_sign * radius * 0.18, radius * 0.20)
		var control_a := center + Vector2(side_sign * radius * 0.80, radius * 0.04)
		var control_b := center + Vector2(side_sign * radius * 0.92, -radius * 0.72)
		var tip := center + Vector2(side_sign * radius * 0.42, -radius)
		var horn := _cubic_curve(base, control_a, control_b, tip, 1.0, 20)
		_draw_tapered_curve(horn, radius * 0.14, Palette.with_alpha(Palette.BONE, 0.82 * alpha), Palette.with_alpha(Palette.SOIL_BLACK, 0.72 * alpha))

	var brow := PackedVector2Array([
		center + Vector2(-radius * 0.34, radius * 0.12),
		center + Vector2(0.0, -radius * 0.02),
		center + Vector2(radius * 0.34, radius * 0.12),
	])
	_draw_layered_line(brow, Palette.with_alpha(Palette.DEEP_EARTH, 0.72 * alpha), Palette.with_alpha(Palette.BONE_HIGHLIGHT, 0.78 * alpha), radius * 0.12, radius * 0.045)


func _draw_growth_spine(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	for spine_index in range(5):
		var ratio := float(spine_index) / 4.0
		var spine_center := center + Vector2(0.0, lerpf(scale_value * 0.28, -scale_value * 0.36, ratio))
		var half_width := scale_value * (0.24 - absf(ratio - 0.50) * 0.12) * phase_value
		var points := PackedVector2Array([
			spine_center + Vector2(-half_width, scale_value * 0.055),
			spine_center + Vector2(0.0, -scale_value * 0.075),
			spine_center + Vector2(half_width, scale_value * 0.055),
		])
		draw_polyline(points, Palette.with_alpha(Palette.COPPER, 0.54 * alpha), 2.0, true)


func _draw_ground_impact(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	if phase_value <= 0.0:
		return
	for ring_index in range(3):
		var radius := scale_value * (0.18 + float(ring_index) * 0.12 + phase_value * 0.24)
		draw_arc(
			center,
			radius,
			PI * 0.08,
			PI * 0.92,
			28,
			Palette.with_alpha(Palette.DUST, (0.58 - float(ring_index) * 0.12) * alpha * (1.0 - phase_value * 0.42)),
			3.0 - float(ring_index) * 0.55,
			true
		)
	for crack_index in range(7):
		var angle := PI * (0.10 + float(crack_index) / 8.2)
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(center, center + direction * scale_value * (0.24 + phase_value * 0.32), 6, scale_value * 0.020)
		draw_polyline(crack, Palette.with_alpha(Palette.SOIL_BLACK, 0.78 * alpha), 2.0, true)


func _draw_closing_jaws(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	for side_sign in [-1.0, 1.0]:
		var jaw_start := center + Vector2(side_sign * scale_value * (0.76 - phase_value * 0.26), -scale_value * 0.32)
		var jaw_end := center + Vector2(side_sign * scale_value * 0.16, scale_value * 0.32)
		var control_a := jaw_start + Vector2(-side_sign * scale_value * 0.10, scale_value * 0.30)
		var control_b := jaw_end + Vector2(side_sign * scale_value * 0.24, -scale_value * 0.04)
		var jaw := _cubic_curve(jaw_start, control_a, control_b, jaw_end, phase_value, 18)
		_draw_tapered_curve(jaw, scale_value * 0.075, Palette.with_alpha(Palette.BONE, 0.78 * alpha), Palette.with_alpha(Palette.SOIL_BLACK, 0.80 * alpha))


func _draw_slash_group(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	for slash_index in range(3):
		var shift := Vector2(float(slash_index - 1) * scale_value * 0.10, float(slash_index - 1) * scale_value * 0.03)
		var start_point := center + shift + Vector2(-scale_value * 0.34, scale_value * 0.30)
		var end_point := center + shift + Vector2(scale_value * 0.30, -scale_value * 0.34) * phase_value
		var slash := _jagged_segment(start_point, end_point, 9, scale_value * 0.026)
		_draw_layered_line(slash, Palette.with_alpha(Palette.SOIL_BLACK, 0.90 * alpha), Palette.with_alpha(Palette.BLOOD_EDGE, 0.86 * alpha), scale_value * 0.052, scale_value * 0.018)


func _draw_stone_cracks(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	for crack_index in range(8):
		var angle := TAU * float(crack_index) / 8.0 + 0.18
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(center, center + direction * scale_value * (0.22 + phase_value * 0.36), 7, scale_value * 0.022)
		draw_polyline(crack, Palette.with_alpha(Palette.SOIL_BLACK, 0.92 * alpha), 5.0, true)
		draw_polyline(crack, Palette.with_alpha(Palette.DARK_ORANGE, 0.86 * phase_value * alpha), 1.9, true)


func _draw_bone_notches(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	for notch_index in range(6):
		var angle := TAU * float(notch_index) / 6.0 - PI * 0.5
		var direction := Vector2(cos(angle), sin(angle))
		var side := direction.orthogonal()
		var notch_center := center + direction * scale_value * (0.42 + phase_value * 0.12)
		var notch := PackedVector2Array([
			notch_center - side * scale_value * 0.035,
			notch_center + direction * scale_value * 0.12,
			notch_center + side * scale_value * 0.035,
		])
		draw_colored_polygon(notch, Palette.with_alpha(Palette.BONE, 0.76 * alpha))


func _draw_rough_card_frame(center: Vector2, frame_size: Vector2, fill: Color, edge: Color, edge_width: float) -> void:
	var half := frame_size * 0.5
	var points := PackedVector2Array([
		center + Vector2(-half.x, -half.y * 0.88),
		center + Vector2(-half.x * 0.92, -half.y),
		center + Vector2(half.x * 0.86, -half.y),
		center + Vector2(half.x, -half.y * 0.82),
		center + Vector2(half.x, half.y * 0.86),
		center + Vector2(half.x * 0.82, half.y),
		center + Vector2(-half.x * 0.88, half.y),
		center + Vector2(-half.x, half.y * 0.80),
	])
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, edge, edge_width, true)


func _draw_tapered_curve(points: PackedVector2Array, width: float, fill: Color, edge: Color) -> void:
	if points.size() < 2:
		return
	for point_index in range(points.size() - 1):
		var ratio := (float(point_index) + 0.5) / float(points.size() - 1)
		var segment_width := maxf(width * (1.0 - ratio * 0.78), 1.0)
		draw_line(points[point_index], points[point_index + 1], edge, segment_width + 4.0, true)
		draw_line(points[point_index], points[point_index + 1], fill, segment_width, true)


func _draw_layered_line(points: PackedVector2Array, outer: Color, inner: Color, outer_width: float, inner_width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, outer, maxf(outer_width, 1.0), true)
	draw_polyline(points, inner, maxf(inner_width, 1.0), true)


func _jagged_segment(start_point: Vector2, end_point: Vector2, segments: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var direction := end_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.001 else Vector2.UP
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		var jag := sin(float(point_index) * 2.37) * amplitude * sin(ratio * PI)
		points.append(start_point.lerp(end_point, ratio) + normal * jag)
	return points


func _cubic_curve(
	start_point: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end_point: Vector2,
	visible_progress: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_progress := clampf(visible_progress, 0.0, 1.0)
	var visible_segments := maxi(int(ceil(float(segments) * safe_progress)), 1)
	for point_index in range(visible_segments + 1):
		var ratio := float(point_index) / float(visible_segments) * safe_progress
		var inverse := 1.0 - ratio
		points.append(
			start_point * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * ratio
			+ control_b * 3.0 * inverse * ratio * ratio
			+ end_point * ratio * ratio * ratio
		)
	return points


func _card_scale() -> float:
	return maxf(minf(card_size.x, card_size.y), 56.0)
