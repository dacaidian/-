extends Control

# Full-board Tokyo Ghoul visual. The provider owns timing and lifecycle; this
# canvas only renders a deterministic frame from its normalized progress.

const BLOOD_CORE := Color(0.94, 0.12, 0.24, 0.96)
const BLOOD_DEEP := Color(0.38, 0.015, 0.07, 0.94)
const WINE_RED := Color(0.58, 0.035, 0.14, 0.92)
const BLACK_RED := Color(0.075, 0.006, 0.025, 0.96)
const VIOLET_SHADOW := Color(0.20, 0.035, 0.22, 0.82)
const COLD_EDGE := Color(0.96, 0.86, 0.90, 0.94)
const NEON_BLUE := Color(0.18, 0.46, 0.72, 0.52)
const NEON_VIOLET := Color(0.44, 0.20, 0.66, 0.50)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func configure() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var center := size * Vector2(0.50, 0.52)
	var radius := minf(size.x, size.y) * 0.32
	var gather := _stage(0.0, 0.24)
	var pulse := _stage(0.10, 0.43)
	var emerge := _stage(0.27, 0.70)
	var strike := _stage(0.50, 0.84)
	var fade := 1.0 - _stage(0.84, 1.0)
	var presence := _stage(0.0, 0.12) * fade

	_draw_urban_night(presence, gather)
	_draw_rc_field(center, radius, gather, pulse, presence)
	_draw_human_core(center, radius, pulse, emerge, presence)
	_draw_ukaku(center, radius, emerge, strike, presence)
	_draw_koukaku(center, radius, emerge, strike, presence)
	_draw_rinkaku(center, radius, emerge, strike, presence)
	_draw_bikaku(center, radius, emerge, strike, presence)
	_draw_residue(center, radius, strike, presence)


func _draw_urban_night(alpha: float, gather: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.018, 0.030, 0.60 * alpha), true)

	var edge_width := minf(size.x, size.y) * 0.12
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge_width, size.y)), Color(0.05, 0.006, 0.025, 0.34 * alpha), true)
	draw_rect(Rect2(Vector2(size.x - edge_width, 0.0), Vector2(edge_width, size.y)), Color(0.05, 0.006, 0.025, 0.34 * alpha), true)

	for reflection_index in range(5):
		var reflection_width := size.x * (0.045 + float(reflection_index % 3) * 0.016)
		var reflection_x := size.x * (0.08 + float(reflection_index) * 0.205)
		var reflection_color := NEON_BLUE if reflection_index % 2 == 0 else NEON_VIOLET
		draw_rect(
			Rect2(
				Vector2(reflection_x, size.y * 0.91),
				Vector2(reflection_width, size.y * 0.008)
			),
			Color(reflection_color.r, reflection_color.g, reflection_color.b, reflection_color.a * alpha * gather),
			true
		)

	for rain_index in range(34):
		var column := fmod(float(rain_index) * 0.61803398875, 1.0)
		var travel := fmod(progress * (1.25 + float(rain_index % 5) * 0.08) + float(rain_index) * 0.173, 1.0)
		var start := Vector2(
			column * size.x + sin(float(rain_index) * 1.37) * 9.0,
			travel * size.y
		)
		var length := 12.0 + float(rain_index % 6) * 5.0
		var rain_color := Color(0.48, 0.62, 0.76, (0.06 + float(rain_index % 3) * 0.018) * alpha)
		draw_line(start, start + Vector2(-3.0, length), rain_color, 1.0, true)


func _draw_rc_field(
	center: Vector2,
	radius: float,
	gather: float,
	pulse: float,
	alpha: float
) -> void:
	var heartbeat := 0.5 + 0.5 * sin(progress * TAU * 3.2)
	for ring_index in range(4):
		var ring_phase := fmod(pulse + float(ring_index) * 0.21, 1.0)
		var ring_radius := radius * (0.12 + ring_phase * 1.10)
		var ring_alpha := (1.0 - ring_phase) * (0.18 + float(ring_index) * 0.025) * alpha
		draw_arc(
			center,
			ring_radius,
			-progress * 0.8 + float(ring_index),
			-progress * 0.8 + float(ring_index) + PI * 1.72,
			64,
			Color(BLOOD_CORE.r, BLOOD_CORE.g, BLOOD_CORE.b, ring_alpha),
			1.5 + float(ring_index % 2),
			true
		)

	for vein_index in range(16):
		var angle := TAU * float(vein_index) / 16.0 + sin(float(vein_index) * 1.7) * 0.14
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var start := center + radial * radius * 0.10
		var middle := center + radial * radius * (0.34 + gather * 0.24) + tangent * radius * sin(float(vein_index) * 2.1) * 0.10
		var end := center + radial * radius * (0.46 + gather * 0.48) + tangent * radius * cos(float(vein_index) * 1.3) * 0.08
		var points := _quadratic_points(start, middle, end, 10)
		draw_polyline(
			points,
			Color(WINE_RED.r, WINE_RED.g, WINE_RED.b, alpha * (0.18 + heartbeat * 0.16)),
			1.0 + float(vein_index % 3) * 0.5,
			true
		)

	_draw_glow_circle(center, radius * (0.07 + heartbeat * 0.018) * pulse, Color(BLOOD_CORE.r, BLOOD_CORE.g, BLOOD_CORE.b, 0.76 * alpha))


func _draw_human_core(
	center: Vector2,
	radius: float,
	pulse: float,
	emerge: float,
	alpha: float
) -> void:
	var body_alpha := alpha * (0.48 + pulse * 0.30)
	var head_center := center + Vector2(0.0, -radius * 0.37)
	draw_circle(head_center, radius * 0.105, Color(0.025, 0.018, 0.026, 0.92 * body_alpha))
	draw_arc(head_center, radius * 0.105, 0.0, TAU, 32, Color(COLD_EDGE.r, COLD_EDGE.g, COLD_EDGE.b, 0.18 * body_alpha), 1.2, true)

	var torso := PackedVector2Array([
		center + Vector2(-radius * 0.16, -radius * 0.22),
		center + Vector2(radius * 0.16, -radius * 0.22),
		center + Vector2(radius * 0.22, radius * 0.30),
		center + Vector2(radius * 0.10, radius * 0.54),
		center + Vector2(-radius * 0.10, radius * 0.54),
		center + Vector2(-radius * 0.22, radius * 0.30)
	])
	draw_colored_polygon(torso, Color(0.018, 0.012, 0.024, 0.86 * body_alpha))
	draw_polyline(_closed(torso), Color(WINE_RED.r, WINE_RED.g, WINE_RED.b, 0.42 * emerge * alpha), 1.8, true)

	for node_index in range(6):
		var node_y := lerpf(center.y - radius * 0.18, center.y + radius * 0.38, float(node_index) / 5.0)
		var node_pulse := 0.55 + 0.45 * sin(progress * TAU * 3.4 - float(node_index) * 0.72)
		draw_circle(Vector2(center.x, node_y), radius * (0.013 + node_pulse * 0.007), Color(BLOOD_CORE.r, BLOOD_CORE.g, BLOOD_CORE.b, alpha * node_pulse * 0.76))

	var eye_center := head_center + Vector2(0.0, radius * 0.012)
	var eye_width := radius * 0.15 * pulse
	draw_line(eye_center - Vector2(eye_width, 0.0), eye_center + Vector2(eye_width, 0.0), Color(0.94, 0.86, 0.90, alpha * pulse * 0.76), 2.1, true)
	draw_circle(eye_center, radius * 0.021 * pulse, Color(BLOOD_CORE.r, BLOOD_CORE.g, BLOOD_CORE.b, alpha * pulse))
	draw_line(eye_center + Vector2(0.0, -radius * 0.025), eye_center + Vector2(0.0, radius * 0.025), Color(0.02, 0.0, 0.008, alpha * pulse), 1.6, true)


func _draw_ukaku(
	center: Vector2,
	radius: float,
	emerge: float,
	strike: float,
	alpha: float
) -> void:
	var origin := center + Vector2(-radius * 0.14, -radius * 0.16)
	for shard_index in range(8):
		var angle := lerpf(-PI * 0.94, -PI * 0.42, float(shard_index) / 7.0)
		var length := radius * (0.34 + float(shard_index % 3) * 0.09) * emerge
		var drift := Vector2.from_angle(angle) * radius * strike * (0.10 + float(shard_index % 2) * 0.06)
		var shard_center := origin + Vector2.from_angle(angle) * length * 0.58 + drift
		_draw_feather_shard(
			shard_center,
			angle,
			length,
			radius * (0.035 + float(shard_index % 2) * 0.012),
			Color(0.72, 0.07, 0.20, alpha * (0.58 + strike * 0.24))
		)


func _draw_koukaku(
	center: Vector2,
	radius: float,
	emerge: float,
	strike: float,
	alpha: float
) -> void:
	if emerge <= 0.01:
		return
	var anchor := center + Vector2(-radius * 0.16, radius * 0.10)
	for plate_index in range(3):
		var plate_scale := emerge * (1.0 + strike * 0.04)
		var offset := Vector2(-radius * (0.18 + float(plate_index) * 0.13), radius * (0.05 + float(plate_index) * 0.12))
		var plate_center := anchor + offset * emerge
		var plate_width := radius * (0.30 - float(plate_index) * 0.035) * plate_scale
		var plate_height := radius * (0.25 + float(plate_index) * 0.025) * plate_scale
		var plate := PackedVector2Array([
			plate_center + Vector2(-plate_width * 0.58, -plate_height * 0.12),
			plate_center + Vector2(-plate_width * 0.20, -plate_height * 0.58),
			plate_center + Vector2(plate_width * 0.52, -plate_height * 0.30),
			plate_center + Vector2(plate_width * 0.62, plate_height * 0.20),
			plate_center + Vector2(0.0, plate_height * 0.58),
			plate_center + Vector2(-plate_width * 0.52, plate_height * 0.34)
		])
		draw_colored_polygon(plate, Color(0.30, 0.018, 0.07, alpha * 0.72))
		draw_polyline(_closed(plate), Color(COLD_EDGE.r, 0.34, 0.42, alpha * (0.48 + strike * 0.22)), 2.2 + float(plate_index) * 0.45, true)
		draw_line(plate_center - Vector2(plate_width * 0.32, 0.0), plate_center + Vector2(plate_width * 0.36, plate_height * 0.08), Color(WINE_RED.r, WINE_RED.g, WINE_RED.b, alpha * 0.62), 1.5, true)


func _draw_rinkaku(
	center: Vector2,
	radius: float,
	emerge: float,
	strike: float,
	alpha: float
) -> void:
	var origin := center + Vector2(radius * 0.10, radius * 0.10)
	for tendril_index in range(4):
		var target_angle := lerpf(-0.72, 0.72, float(tendril_index) / 3.0)
		var target := center + Vector2.from_angle(target_angle) * radius * (0.92 + float(tendril_index % 2) * 0.14)
		target.x += radius * 0.42
		var control := origin + Vector2(radius * (0.46 + strike * 0.20), radius * sin(float(tendril_index) * 1.9) * 0.34)
		var end := origin.lerp(target, emerge)
		var curve := _quadratic_points(origin, origin.lerp(control, emerge), end, 18)
		_draw_tapered_curve(curve, radius * 0.052, Color(BLOOD_DEEP.r, BLOOD_DEEP.g, BLOOD_DEEP.b, alpha * 0.90), Color(0.96, 0.25, 0.34, alpha * 0.82))
		for joint_index in range(3):
			var joint_t := (float(joint_index) + 1.0) / 4.0
			var joint := _quadratic_point(origin, origin.lerp(control, emerge), end, joint_t)
			draw_circle(joint, radius * (0.018 + float(joint_index) * 0.003), Color(WINE_RED.r, WINE_RED.g, WINE_RED.b, alpha * 0.74))


func _draw_bikaku(
	center: Vector2,
	radius: float,
	emerge: float,
	strike: float,
	alpha: float
) -> void:
	var origin := center + Vector2(0.0, radius * 0.30)
	var control := center + Vector2(radius * (0.18 + strike * 0.22), radius * 0.94)
	var target := center + Vector2(radius * 0.92, radius * 0.70 - strike * radius * 0.24)
	var end := origin.lerp(target, emerge)
	var curve := _quadratic_points(origin, origin.lerp(control, emerge), end, 22)
	_draw_tapered_curve(curve, radius * 0.080, Color(0.25, 0.012, 0.055, alpha * 0.96), Color(0.88, 0.16, 0.27, alpha * 0.86))
	if curve.size() >= 2:
		var direction := (curve[curve.size() - 1] - curve[curve.size() - 2]).normalized()
		var tangent := direction.orthogonal()
		var tip := curve[curve.size() - 1]
		var barb := PackedVector2Array([
			tip + direction * radius * 0.15,
			tip - direction * radius * 0.055 + tangent * radius * 0.050,
			tip - direction * radius * 0.026,
			tip - direction * radius * 0.055 - tangent * radius * 0.050
		])
		draw_colored_polygon(barb, Color(WINE_RED.r, WINE_RED.g, WINE_RED.b, alpha * emerge))
		draw_polyline(_closed(barb), Color(COLD_EDGE.r, 0.36, 0.44, alpha * emerge * 0.68), 1.4, true)


func _draw_residue(center: Vector2, radius: float, strike: float, alpha: float) -> void:
	for particle_index in range(22):
		var phase := fmod(progress * (0.64 + float(particle_index % 4) * 0.08) + float(particle_index) * 0.119, 1.0)
		var angle := float(particle_index) * 2.399963
		var orbit := radius * (0.20 + phase * (0.66 + strike * 0.34))
		var point := center + Vector2.from_angle(angle) * orbit + Vector2(0.0, -phase * radius * 0.20)
		var color := BLOOD_CORE if particle_index % 3 != 0 else NEON_VIOLET
		draw_circle(point, 1.2 + float(particle_index % 3), Color(color.r, color.g, color.b, sin(phase * PI) * alpha * 0.44))


func _draw_feather_shard(
	center: Vector2,
	angle: float,
	length: float,
	half_width: float,
	color: Color
) -> void:
	if length <= 0.1:
		return
	var direction := Vector2.from_angle(angle)
	var tangent := direction.orthogonal()
	var root := center - direction * length * 0.45
	var tip := center + direction * length * 0.55
	var shard := PackedVector2Array([
		root - tangent * half_width * 0.45,
		center - tangent * half_width,
		tip,
		center + tangent * half_width,
		root + tangent * half_width * 0.45
	])
	draw_colored_polygon(shard, color)
	draw_polyline(_closed(shard), Color(COLD_EDGE.r, COLD_EDGE.g, COLD_EDGE.b, color.a * 0.62), 1.2, true)
	draw_line(root, tip, Color(1.0, 0.44, 0.52, color.a * 0.74), 1.0, true)


func _draw_tapered_curve(
	points: PackedVector2Array,
	base_width: float,
	fill_color: Color,
	edge_color: Color
) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		var t := float(index) / float(points.size() - 1)
		var width := maxf(base_width * (1.0 - t * 0.74), 1.4)
		draw_line(points[index], points[index + 1], fill_color, width, true)
		draw_line(points[index], points[index + 1], edge_color, maxf(width * 0.18, 1.0), true)


func _draw_glow_circle(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.1:
		return
	draw_circle(center, radius * 2.20, Color(color.r, color.g, color.b, color.a * 0.08))
	draw_circle(center, radius * 1.52, Color(color.r, color.g, color.b, color.a * 0.18))
	draw_circle(center, radius, color)


func _quadratic_points(
	start: Vector2,
	control: Vector2,
	end: Vector2,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		points.append(_quadratic_point(start, control, end, float(index) / float(segments)))
	return points


func _quadratic_point(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + end * t * t


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed_points := points.duplicate()
	if not closed_points.is_empty():
		closed_points.append(closed_points[0])
	return closed_points


func _stage(start: float, finish: float) -> float:
	if finish <= start:
		return 1.0 if progress >= finish else 0.0
	var value := clampf((progress - start) / (finish - start), 0.0, 1.0)
	return value * value * (3.0 - 2.0 * value)
