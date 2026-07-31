extends Control

# Draws Tokyo Ghoul attacks as living RC-cell weapons. The provider owns the
# animation lifetime; this canvas only renders a deterministic progress frame.

const BLOOD := Color(0.91, 0.055, 0.15, 0.96)
const WINE := Color(0.47, 0.012, 0.075, 0.96)
const DEEP := Color(0.105, 0.004, 0.025, 0.98)
const VIOLET := Color(0.30, 0.035, 0.31, 0.86)
const COLD := Color(0.98, 0.83, 0.88, 0.94)
const CITY_BLUE := Color(0.20, 0.43, 0.66, 0.38)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var source_point := Vector2.ZERO
var target_point := Vector2.ZERO
var profile := "bikaku"


func configure(source: Vector2, target: Vector2, visual_profile: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_point = source
	target_point = target
	profile = visual_profile
	queue_redraw()


func _draw() -> void:
	if source_point.distance_to(target_point) <= 0.01:
		return

	var gather := _stage(0.0, 0.18)
	var release := _stage(0.14, 0.68)
	var impact := _stage(0.62, 0.82)
	var residue := (1.0 - _stage(0.80, 1.0)) * _stage(0.02, 0.14)
	var alpha := 1.0 - _stage(0.88, 1.0)

	_draw_corridor(gather, release, alpha)
	_draw_source_pulse(gather, alpha)

	match profile:
		"ukaku":
			_draw_ukaku(release, impact, alpha)
		"koukaku":
			_draw_koukaku(release, impact, alpha)
		"rinkaku":
			_draw_rinkaku(release, impact, alpha)
		"chimera":
			_draw_rinkaku(release, impact, alpha)
			_draw_ukaku(clampf(release * 1.08, 0.0, 1.0), impact, alpha * 0.82)
			_draw_bikaku(clampf(release * 0.94, 0.0, 1.0), impact, alpha * 0.86)
			_draw_koukaku(clampf(release * 0.88, 0.0, 1.0), impact, alpha * 0.72)
		"centipede":
			_draw_centipede(release, alpha)
		"dragon":
			_draw_dragon(release, impact, alpha)
		"saint_sword":
			_draw_saint_sword(release, impact, alpha)
		"owl":
			_draw_owl(release, impact, alpha)
		"furuta":
			_draw_furuta_fan(release, impact, alpha)
		"lifesteal":
			_draw_lifesteal(release, impact, alpha)
		"reflect":
			_draw_reflect(release, impact, alpha)
		_:
			_draw_bikaku(release, impact, alpha)

	_draw_impact(impact, residue, alpha)


func _draw_corridor(gather: float, release: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var width := 5.0 + gather * 10.0
	var end := source_point.lerp(target_point, release)
	if source_point.distance_to(end) > 1.0:
		var corridor := PackedVector2Array([
			source_point + normal * width,
			end + normal * width * 0.35,
			end - normal * width * 0.35,
			source_point - normal * width,
		])
		draw_colored_polygon(corridor, Color(0.16, 0.005, 0.035, 0.10 * alpha))
	for rain_index in range(5):
		var t := fmod(progress * (0.75 + float(rain_index) * 0.06) + float(rain_index) * 0.19, 1.0)
		var point := source_point.lerp(target_point, t)
		point += normal * sin(float(rain_index) * 2.1) * 16.0
		draw_line(point - Vector2(2.0, 7.0), point + Vector2(1.0, 7.0), Color(CITY_BLUE.r, CITY_BLUE.g, CITY_BLUE.b, CITY_BLUE.a * alpha), 1.0, true)


func _draw_source_pulse(gather: float, alpha: float) -> void:
	var heartbeat := 0.55 + 0.45 * sin(progress * TAU * 3.0)
	for ring_index in range(3):
		var radius := (8.0 + float(ring_index) * 8.0) * gather
		draw_arc(
			source_point,
			radius,
			-progress * 1.2 + float(ring_index),
			-progress * 1.2 + float(ring_index) + PI * 1.55,
			24,
			Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (0.22 + heartbeat * 0.18)),
			1.2 + float(ring_index) * 0.3,
			true
		)
	draw_circle(source_point, 3.0 + heartbeat * 2.0, Color(COLD.r, COLD.g, COLD.b, alpha * gather * 0.72))


func _draw_ukaku(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	for shard_index in range(7):
		var stagger := float(shard_index) * 0.055
		var flight := clampf((release - stagger) / maxf(1.0 - stagger, 0.01), 0.0, 1.0)
		var offset := normal * (float(shard_index) - 3.0) * 7.0
		var center := source_point.lerp(target_point, flight) + offset * sin(flight * PI)
		var length := 18.0 + float(shard_index % 3) * 5.0
		var tip := center + direction * length
		var shard := PackedVector2Array([
			center - direction * length * 0.42 + normal * 3.2,
			tip,
			center - direction * length * 0.42 - normal * 3.2,
		])
		draw_colored_polygon(shard, Color(0.76, 0.055, 0.19, alpha * (0.70 + impact * 0.18)))
		draw_polyline(_closed(shard), Color(COLD.r, COLD.g, COLD.b, alpha * 0.64), 1.0, true)


func _draw_koukaku(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var center := source_point.lerp(target_point, release)
	var length := 30.0 + impact * 18.0
	var width := 13.0 + impact * 6.0
	var blade := PackedVector2Array([
		center - direction * length * 0.62 + normal * width,
		center + direction * length,
		center - direction * length * 0.20,
		center - direction * length * 0.62 - normal * width,
		center - direction * length * 0.84,
	])
	draw_colored_polygon(blade, Color(0.30, 0.008, 0.045, alpha * 0.94))
	draw_polyline(_closed(blade), Color(COLD.r, 0.34, 0.42, alpha * 0.82), 2.4, true)
	draw_line(center - direction * length * 0.54, center + direction * length * 0.68, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.82), 3.0, true)


func _draw_rinkaku(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	for tendril_index in range(4):
		var side := float(tendril_index) - 1.5
		var end := source_point.lerp(target_point + normal * side * 5.0, release)
		var control := source_point.lerp(target_point, release * 0.52)
		control += normal * side * (18.0 + sin(progress * 9.0 + float(tendril_index)) * 6.0)
		var curve := _quadratic_points(source_point + normal * side * 2.5, control, end, 18)
		_draw_tapered_curve(curve, 6.8 - absf(side), Color(WINE.r, WINE.g, WINE.b, alpha * 0.94), Color(COLD.r, 0.18, 0.28, alpha * 0.68))
		for joint_index in range(3):
			var joint := _quadratic_point(source_point, control, end, (float(joint_index) + 1.0) / 4.0)
			draw_circle(joint, 2.3 + impact, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.82))


func _draw_bikaku(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var end := source_point.lerp(target_point, release)
	var control := source_point.lerp(target_point, 0.48 * release)
	control += normal * (34.0 * sin(release * PI) + sin(progress * 8.0) * 5.0)
	var curve := _quadratic_points(source_point, control, end, 24)
	_draw_tapered_curve(curve, 10.0, Color(DEEP.r, DEEP.g, DEEP.b, alpha), Color(0.94, 0.12, 0.23, alpha * 0.84))
	if curve.size() >= 2 and release > 0.02:
		var tip := curve[curve.size() - 1]
		var tip_direction := (tip - curve[curve.size() - 2]).normalized()
		var tangent := tip_direction.orthogonal()
		var barb := PackedVector2Array([
			tip + tip_direction * (17.0 + impact * 8.0),
			tip - tip_direction * 7.0 + tangent * 8.0,
			tip - tip_direction * 3.0,
			tip - tip_direction * 7.0 - tangent * 8.0,
		])
		draw_colored_polygon(barb, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.92))
		draw_polyline(_closed(barb), Color(COLD.r, COLD.g, COLD.b, alpha * 0.62), 1.2, true)


func _draw_centipede(release: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var previous := source_point
	for segment_index in range(12):
		var t := minf(release * 1.18 - float(segment_index) * 0.035, 1.0)
		if t <= 0.0:
			continue
		var center := source_point.lerp(target_point, t)
		center += normal * sin(t * 15.0 - progress * 8.0) * 10.0
		if segment_index > 0:
			draw_line(previous, center, Color(DEEP.r, DEEP.g, DEEP.b, alpha), 8.0, true)
		draw_circle(center, 5.4 - float(segment_index) * 0.14, Color(WINE.r, WINE.g, WINE.b, alpha * 0.94))
		draw_circle(center, 1.5, Color(COLD.r, COLD.g, COLD.b, alpha * 0.52))
		var leg := normal * (8.0 + float(segment_index % 2) * 3.0)
		draw_line(center - leg, center + leg, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.70), 1.4, true)
		previous = center


func _draw_dragon(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var center := source_point.lerp(target_point, release)
	for jaw_index in range(3):
		var spread := float(jaw_index) - 1.0
		var start := center - direction * 30.0 + normal * spread * 10.0
		var tip := center + direction * (28.0 + impact * 18.0) + normal * spread * 18.0
		var jaw := PackedVector2Array([
			start + normal * 6.0,
			tip,
			start - normal * 6.0,
		])
		draw_colored_polygon(jaw, Color(0.20 + float(jaw_index) * 0.04, 0.005, 0.035, alpha * 0.92))
		draw_polyline(_closed(jaw), Color(COLD.r, 0.24, 0.32, alpha * 0.72), 1.7, true)
	for shock_index in range(3):
		draw_arc(target_point, 16.0 + float(shock_index) * 11.0 * impact, -1.8, 1.8, 28, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (1.0 - impact) * 0.42), 2.2, true)


func _draw_saint_sword(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var end := source_point.lerp(target_point, release)
	draw_line(source_point, end, Color(0.30, 0.005, 0.08, alpha * 0.48), 15.0, true)
	draw_line(source_point, end, Color(0.94, 0.12, 0.25, alpha * 0.92), 5.0, true)
	draw_line(source_point, end, Color(1.0, 0.92, 0.95, alpha), 1.6, true)
	var blade_center := end - direction * 12.0
	var blade := PackedVector2Array([
		blade_center + direction * 25.0,
		blade_center - direction * 15.0 + normal * 7.0,
		blade_center - direction * 7.0,
		blade_center - direction * 15.0 - normal * 7.0,
	])
	draw_colored_polygon(blade, Color(COLD.r, COLD.g, COLD.b, alpha * 0.88))
	if impact > 0.0:
		for arc_index in range(3):
			var angle := direction.angle() + (float(arc_index) - 1.0) * 0.42
			draw_arc(target_point, 22.0 + float(arc_index) * 7.0, angle - 1.0, angle + 1.0, 24, Color(0.94, 0.16, 0.32, alpha * (1.0 - impact) * 0.82), 2.4, true)


func _draw_owl(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	var center := source_point.lerp(target_point, release)
	for wing_index in range(7):
		var side := -1.0 if wing_index % 2 == 0 else 1.0
		var rank := floorf(float(wing_index) / 2.0)
		var base := center - direction * (20.0 + rank * 3.0)
		var tip := center + direction * (18.0 + impact * 14.0) + normal * side * (14.0 + rank * 10.0)
		var feather := PackedVector2Array([
			base + normal * side * 3.0,
			tip,
			base - normal * side * 3.0,
		])
		draw_colored_polygon(feather, Color(0.36, 0.008, 0.08, alpha * 0.86))
		draw_polyline(_closed(feather), Color(COLD.r, 0.28, 0.38, alpha * 0.68), 1.2, true)


func _draw_furuta_fan(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	for ray_index in range(5):
		var lane := float(ray_index) - 2.0
		var lane_target := target_point + normal * lane * 23.0
		var end := source_point.lerp(lane_target, release)
		draw_line(source_point, end, Color(DEEP.r, DEEP.g, DEEP.b, alpha * 0.82), 6.0, true)
		draw_line(source_point, end, Color(0.94, 0.10, 0.22, alpha * (0.62 + impact * 0.22)), 1.8, true)
		var tip_direction := (lane_target - source_point).normalized()
		draw_line(end - tip_direction * 12.0, end + tip_direction * 5.0, Color(COLD.r, COLD.g, COLD.b, alpha * 0.76), 1.0, true)


func _draw_lifesteal(release: float, impact: float, alpha: float) -> void:
	var direction := (target_point - source_point).normalized()
	var normal := direction.orthogonal()
	for stream_index in range(5):
		var phase := clampf(release - float(stream_index) * 0.07, 0.0, 1.0)
		var start := source_point + normal * (float(stream_index) - 2.0) * 4.0
		var end := start.lerp(target_point, phase)
		var control := start.lerp(target_point, phase * 0.52) + normal * sin(float(stream_index) * 1.7 + progress * 8.0) * 12.0
		var curve := _quadratic_points(start, control, end, 14)
		draw_polyline(curve, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (0.42 + float(stream_index) * 0.08)), 2.0 + float(stream_index % 2), true)
	draw_circle(target_point, 5.0 + impact * 10.0, Color(0.95, 0.18, 0.30, alpha * (1.0 - impact) * 0.72))


func _draw_reflect(release: float, impact: float, alpha: float) -> void:
	var radius := 18.0 + release * 18.0
	var shield := PackedVector2Array([
		source_point + Vector2(0.0, -radius),
		source_point + Vector2(radius * 0.78, -radius * 0.45),
		source_point + Vector2(radius * 0.58, radius * 0.48),
		source_point + Vector2(0.0, radius),
		source_point + Vector2(-radius * 0.58, radius * 0.48),
		source_point + Vector2(-radius * 0.78, -radius * 0.45),
	])
	draw_colored_polygon(shield, Color(0.26, 0.005, 0.05, alpha * 0.62))
	draw_polyline(_closed(shield), Color(COLD.r, 0.34, 0.42, alpha * 0.92), 2.2, true)
	var reflected_end := source_point.lerp(target_point, release)
	draw_line(source_point, reflected_end, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.86), 5.0, true)
	draw_line(source_point, reflected_end, Color(COLD.r, COLD.g, COLD.b, alpha * 0.74), 1.2, true)


func _draw_impact(impact: float, residue: float, alpha: float) -> void:
	if impact <= 0.0:
		return
	var burst := sin(clampf(impact, 0.0, 1.0) * PI)
	for ray_index in range(9):
		var angle := TAU * float(ray_index) / 9.0 + float(ray_index % 2) * 0.19
		var direction := Vector2.from_angle(angle)
		var start := target_point + direction * (5.0 + impact * 5.0)
		var end := target_point + direction * (10.0 + burst * (18.0 + float(ray_index % 3) * 5.0))
		draw_line(start, end, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * burst * 0.76), 1.2 + float(ray_index % 2), true)
	for ring_index in range(2):
		draw_arc(target_point, 10.0 + impact * (18.0 + float(ring_index) * 9.0), 0.0, TAU, 36, Color(COLD.r, COLD.g, COLD.b, alpha * burst * (0.38 - float(ring_index) * 0.10)), 1.4, true)
	for mote_index in range(7):
		var mote_angle := float(mote_index) * 2.399963
		var mote := target_point + Vector2.from_angle(mote_angle) * (12.0 + residue * 24.0)
		draw_circle(mote, 1.2 + float(mote_index % 2), Color(0.82, 0.05, 0.16, alpha * residue * 0.72))


func _draw_tapered_curve(
	points: PackedVector2Array,
	base_width: float,
	outer_color: Color,
	inner_color: Color
) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		var t := float(index) / float(points.size() - 1)
		var width := maxf(base_width * (1.0 - t * 0.70), 1.2)
		draw_line(points[index], points[index + 1], outer_color, width, true)
		draw_line(points[index], points[index + 1], inner_color, maxf(width * 0.22, 1.0), true)


func _quadratic_points(start: Vector2, control: Vector2, end: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		points.append(_quadratic_point(start, control, end, float(index) / float(segments)))
	return points


func _quadratic_point(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + end * t * t


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _stage(start: float, finish: float) -> float:
	return smoothstep(start, finish, progress)
