extends Control

# Local mutation and support effects. Shapes are organic and directional so
# they remain readable on a dense board without relying on generic glow rings.

const BLOOD := Color(0.93, 0.06, 0.16, 0.96)
const WINE := Color(0.48, 0.012, 0.08, 0.94)
const DEEP := Color(0.075, 0.004, 0.022, 0.97)
const COLD := Color(0.98, 0.84, 0.89, 0.94)
const COFFEE := Color(0.48, 0.20, 0.10, 0.92)
const AMBER := Color(0.96, 0.63, 0.28, 0.90)
const CITY_BLUE := Color(0.18, 0.39, 0.61, 0.42)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var source_point := Vector2.ZERO
var target_point := Vector2.ZERO
var target_size := Vector2(96.0, 132.0)
var profile := "centipede_form"


func configure(
	visual_profile: String,
	target: Vector2,
	visual_size: Vector2,
	source := Vector2.ZERO
) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile = visual_profile
	target_point = target
	target_size = visual_size
	source_point = source if source != Vector2.ZERO else target
	queue_redraw()


func _draw() -> void:
	var gather := _stage(0.0, 0.22)
	var emerge := _stage(0.16, 0.58)
	var settle := _stage(0.54, 0.78)
	var fade := 1.0 - _stage(0.80, 1.0)
	var alpha := _stage(0.0, 0.10) * fade
	var radius := maxf(minf(target_size.x, target_size.y) * 0.48, 34.0)

	match profile:
		"centipede_form":
			_draw_centipede(target_point, radius, gather, emerge, settle, alpha)
		"dragon_form":
			_draw_dragon(target_point, radius, gather, emerge, settle, alpha)
		"saint_sword_form":
			_draw_saint_sword(target_point, radius, gather, emerge, settle, alpha)
		"bikaku_volley":
			_draw_bikaku_release(target_point, radius, gather, emerge, settle, alpha)
		"kakuja_form":
			_draw_kakuja(target_point, radius, gather, emerge, settle, alpha)
		"restore_form":
			_draw_restore(target_point, radius, gather, emerge, settle, alpha)
		"rc_forced_feeding":
			_draw_forced_feeding(target_point, radius, gather, emerge, settle, alpha)
		"free_meal":
			_draw_free_meal(target_point, radius, gather, emerge, settle, alpha)
		"special_blend":
			_draw_special_blend(target_point, radius, emerge, settle, alpha)
		"sugar_cube_coffee":
			_draw_sugar_coffee(source_point, target_point, radius, gather, emerge, settle, alpha)


func _draw_centipede(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius, gather, alpha)
	var previous := center + Vector2(0.0, -radius * 0.48)
	for segment_index in range(13):
		var t := float(segment_index) / 12.0
		var phase := clampf(emerge * 1.35 - t * 0.28, 0.0, 1.0)
		var point := center + Vector2(
			sin(t * TAU * 1.7 + progress * 3.2) * radius * 0.24,
			lerpf(-radius * 0.52, radius * 0.62, t)
		) * phase
		if segment_index > 0:
			draw_line(previous, point, Color(DEEP.r, DEEP.g, DEEP.b, alpha * 0.94), radius * (0.13 - t * 0.055), true)
		var segment_radius := radius * (0.095 - t * 0.035) * phase
		draw_circle(point, maxf(segment_radius, 1.0), Color(WINE.r, WINE.g, WINE.b, alpha * 0.92))
		draw_arc(point, maxf(segment_radius, 1.0), 0.0, TAU, 16, Color(COLD.r, 0.25, 0.34, alpha * 0.42), 1.0, true)
		var leg_direction := Vector2(1.0, sin(t * 9.0) * 0.18).normalized()
		var leg_length := radius * (0.12 + settle * 0.05) * phase
		draw_line(point - leg_direction * leg_length, point + leg_direction * leg_length, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.74), 1.5, true)
		previous = point


func _draw_dragon(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius * 1.12, gather, alpha)
	if emerge <= 0.02:
		return
	for wing_index in range(6):
		var side := -1.0 if wing_index % 2 == 0 else 1.0
		var rank := floorf(float(wing_index) / 2.0)
		var anchor := center + Vector2(side * radius * 0.10, -radius * (0.25 - rank * 0.18))
		var tip := center + Vector2(side * radius * (0.70 + rank * 0.20), -radius * (0.42 - rank * 0.28)) * emerge
		var membrane := PackedVector2Array([
			anchor + Vector2(0.0, radius * 0.10),
			tip,
			anchor - Vector2(0.0, radius * 0.10),
		])
		draw_colored_polygon(membrane, Color(0.27, 0.005, 0.05, alpha * (0.58 + settle * 0.18)))
		draw_polyline(_closed(membrane), Color(COLD.r, 0.23, 0.33, alpha * 0.68), 1.6, true)
		draw_line(anchor, tip, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.78), 2.2, true)

	var jaw_center := center + Vector2(0.0, radius * 0.04)
	for jaw_index in range(5):
		var angle := lerpf(-2.66, -0.48, float(jaw_index) / 4.0)
		var direction := Vector2.from_angle(angle)
		var tip := jaw_center + direction * radius * (0.50 + settle * 0.22) * emerge
		draw_line(jaw_center, tip, Color(WINE.r, WINE.g, WINE.b, alpha * 0.92), 5.0, true)
		draw_line(jaw_center, tip, Color(COLD.r, 0.18, 0.28, alpha * 0.58), 1.0, true)


func _draw_saint_sword(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius, gather, alpha)
	var blade_top := center + Vector2(0.0, -radius * (0.98 + settle * 0.20) * emerge)
	var blade_bottom := center + Vector2(0.0, radius * 0.54 * emerge)
	draw_line(blade_bottom, blade_top, Color(0.26, 0.006, 0.07, alpha * 0.68), radius * 0.18, true)
	draw_line(blade_bottom, blade_top, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.92), radius * 0.065, true)
	draw_line(blade_bottom, blade_top, Color(COLD.r, COLD.g, COLD.b, alpha), maxf(radius * 0.018, 1.3), true)
	var tangent := Vector2.RIGHT
	var guard_center := center + Vector2(0.0, radius * 0.30)
	draw_line(guard_center - tangent * radius * 0.42 * emerge, guard_center + tangent * radius * 0.42 * emerge, Color(COLD.r, 0.28, 0.38, alpha * 0.88), radius * 0.055, true)
	for arc_index in range(3):
		var phase := fmod(progress * 0.55 + float(arc_index) * 0.29, 1.0)
		draw_arc(center, radius * (0.30 + phase * 0.76), -PI * 0.84, -PI * 0.16, 28, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (1.0 - phase) * 0.36), 1.5, true)


func _draw_bikaku_release(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius, gather, alpha)
	for tail_index in range(5):
		var angle := TAU * float(tail_index) / 5.0 - PI * 0.5
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var end := center + direction * radius * (0.72 + float(tail_index % 2) * 0.18) * emerge
		var control := center + direction * radius * 0.34 + tangent * radius * sin(progress * 6.0 + float(tail_index)) * 0.20
		var curve := _quadratic_points(center, control, end, 18)
		_draw_tapered_curve(curve, radius * 0.13, Color(DEEP.r, DEEP.g, DEEP.b, alpha), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.82))
		if curve.size() > 1:
			var tip := curve[curve.size() - 1]
			draw_circle(tip, radius * (0.045 + settle * 0.025), Color(COLD.r, 0.22, 0.32, alpha * 0.72))


func _draw_kakuja(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius * 1.18, gather, alpha)
	if emerge <= 0.02:
		return
	for plate_index in range(8):
		var angle := TAU * float(plate_index) / 8.0 + progress * 0.22
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var anchor := center + direction * radius * 0.18
		var tip := center + direction * radius * (0.74 + float(plate_index % 3) * 0.10) * emerge
		var plate := PackedVector2Array([
			anchor + tangent * radius * 0.12,
			tip + direction * radius * (0.14 + settle * 0.08),
			anchor - tangent * radius * 0.12,
		])
		draw_colored_polygon(plate, Color(0.25, 0.004, 0.045, alpha * 0.92))
		draw_polyline(_closed(plate), Color(COLD.r, 0.24, 0.34, alpha * 0.72), 1.4, true)
		draw_line(anchor, tip, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.76), 1.8, true)


func _draw_restore(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius * 0.90, gather, alpha)
	var contraction := 1.0 - settle
	for strand_index in range(12):
		var angle := TAU * float(strand_index) / 12.0 + progress * 0.7
		var outer := center + Vector2.from_angle(angle) * radius * (0.82 - emerge * 0.28)
		var inner := outer.lerp(center, emerge * 0.82)
		draw_line(outer, inner, Color(WINE.r, WINE.g, WINE.b, alpha * (0.42 + contraction * 0.34)), 2.0 + float(strand_index % 3), true)
	var shell_radius := radius * (0.72 - settle * 0.46)
	draw_arc(center, shell_radius, progress * 0.9, progress * 0.9 + PI * 1.74, 48, Color(COLD.r, 0.30, 0.39, alpha * 0.72), 2.0, true)
	draw_circle(center, radius * 0.08 * contraction, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.84))


func _draw_forced_feeding(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	_draw_rc_veins(center, radius * 1.08, gather, alpha)
	var close_amount := clampf(emerge + settle * 0.35, 0.0, 1.0)
	for jaw_index in range(10):
		var angle := TAU * float(jaw_index) / 10.0
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var outer := center + direction * radius * (1.10 - close_amount * 0.52)
		var inner := center + direction * radius * (0.22 + (1.0 - close_amount) * 0.26)
		var tooth := PackedVector2Array([
			outer + tangent * radius * 0.09,
			inner,
			outer - tangent * radius * 0.09,
		])
		draw_colored_polygon(tooth, Color(0.28, 0.004, 0.04, alpha * 0.94))
		draw_polyline(_closed(tooth), Color(COLD.r, 0.20, 0.28, alpha * 0.66), 1.0, true)
	for tendril_index in range(5):
		var angle := TAU * float(tendril_index) / 5.0 + progress * 0.32
		var start := center + Vector2.from_angle(angle) * radius * 0.72
		var control := center + Vector2.from_angle(angle + 0.72) * radius * 0.44
		var curve := _quadratic_points(start, control, center, 12)
		draw_polyline(curve, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.68), 2.2, true)
	draw_circle(center, radius * (0.20 - settle * 0.12), Color(DEEP.r, DEEP.g, DEEP.b, alpha * 0.88))
	draw_circle(center, radius * 0.055, Color(COLD.r, COLD.g, COLD.b, alpha * (1.0 - settle) * 0.78))


func _draw_free_meal(
	center: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	var shelter_width := radius * 1.22 * emerge
	var roof_y := center.y - radius * 0.30
	var shelter := PackedVector2Array([
		center + Vector2(-shelter_width, radius * 0.44),
		center + Vector2(-shelter_width * 0.72, -radius * 0.05),
		center + Vector2(0.0, -radius * 0.55),
		center + Vector2(shelter_width * 0.72, -radius * 0.05),
		center + Vector2(shelter_width, radius * 0.44),
	])
	draw_polyline(shelter, Color(0.80, 0.20, 0.25, alpha * 0.64), 3.0, true)
	draw_line(Vector2(center.x - shelter_width * 0.66, roof_y), Vector2(center.x + shelter_width * 0.66, roof_y), Color(COLD.r, COLD.g, COLD.b, alpha * 0.36), 1.2, true)
	for pulse_index in range(4):
		var phase := fmod(progress * 0.55 + float(pulse_index) * 0.22, 1.0)
		var field_radius := maxf(size.x, size.y) * (0.04 + phase * 0.72)
		draw_arc(center, field_radius, 0.0, TAU, 72, Color(0.84, 0.12, 0.20, alpha * (1.0 - phase) * 0.22), 1.6, true)
	for cell_index in range(12):
		var angle := float(cell_index) * 2.399963
		var reach := lerpf(radius * 0.30, minf(size.x, size.y) * 0.48, settle)
		var point := center + Vector2.from_angle(angle) * reach * (0.58 + float(cell_index % 3) * 0.18)
		draw_circle(point, 2.0 + float(cell_index % 3), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (0.38 + gather * 0.30)))
		draw_line(center, point, Color(WINE.r, WINE.g, WINE.b, alpha * (1.0 - settle) * 0.12), 1.0, true)


func _draw_special_blend(
	center: Vector2,
	radius: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	var cup_rect := Rect2(center + Vector2(-radius * 0.42, -radius * 0.12), Vector2(radius * 0.72, radius * 0.56) * emerge)
	draw_rect(cup_rect, Color(COFFEE.r, COFFEE.g, COFFEE.b, alpha * 0.46), true)
	draw_arc(cup_rect.get_center(), cup_rect.size.x * 0.55, 0.0, PI, 24, Color(COLD.r, COLD.g, COLD.b, alpha * 0.74), 2.0, true)
	draw_arc(center + Vector2(radius * 0.29, radius * 0.10), radius * 0.22 * emerge, -PI * 0.5, PI * 0.5, 20, Color(AMBER.r, AMBER.g, AMBER.b, alpha * 0.72), 2.4, true)
	for steam_index in range(3):
		var start := center + Vector2((float(steam_index) - 1.0) * radius * 0.16, -radius * 0.15)
		var control := start + Vector2(radius * sin(progress * 5.0 + float(steam_index)) * 0.11, -radius * 0.38)
		var end := start + Vector2(0.0, -radius * (0.54 + settle * 0.18))
		draw_polyline(_quadratic_points(start, control, end, 16), Color(0.84, 0.72, 0.68, alpha * 0.46), 2.0, true)
	for sugar_index in range(3):
		var angle := -PI * 0.72 + float(sugar_index) * 0.26
		var point := center + Vector2.from_angle(angle) * radius * (0.64 + settle * 0.25)
		draw_rect(Rect2(point - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(COLD.r, COLD.g, COLD.b, alpha * 0.82), true)


func _draw_sugar_coffee(
	source: Vector2,
	target: Vector2,
	radius: float,
	gather: float,
	emerge: float,
	settle: float,
	alpha: float
) -> void:
	var direction := (target - source).normalized()
	var normal := direction.orthogonal()
	var control := source.lerp(target, 0.48) - Vector2(0.0, radius * 0.58)
	var stream_end := source.lerp(target, emerge)
	var curve := _quadratic_points(source, source.lerp(control, emerge), stream_end, 24)
	draw_polyline(curve, Color(COFFEE.r, COFFEE.g, COFFEE.b, alpha * 0.78), 7.0, true)
	draw_polyline(curve, Color(AMBER.r, AMBER.g, AMBER.b, alpha * 0.64), 2.0, true)
	for cell_index in range(7):
		var angle := TAU * float(cell_index) / 7.0 + progress * 0.8
		var point := target + Vector2.from_angle(angle) * radius * (0.24 + settle * 0.44)
		draw_circle(point, 2.0 + float(cell_index % 2), Color(0.96, 0.52, 0.30, alpha * (1.0 - settle * 0.35)))
	for repair_index in range(3):
		var offset := normal * (float(repair_index) - 1.0) * radius * 0.18
		draw_line(target + offset - direction * radius * 0.18, target + offset + direction * radius * 0.18, Color(COLD.r, COLD.g, COLD.b, alpha * gather * 0.62), 1.5, true)


func _draw_rc_veins(center: Vector2, radius: float, amount: float, alpha: float) -> void:
	var heartbeat := 0.55 + 0.45 * sin(progress * TAU * 3.1)
	for vein_index in range(12):
		var angle := TAU * float(vein_index) / 12.0 + sin(float(vein_index) * 1.9) * 0.16
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var start := center + direction * radius * 0.08
		var control := center + direction * radius * 0.36 * amount + tangent * radius * sin(float(vein_index) * 1.4) * 0.16
		var end := center + direction * radius * (0.34 + amount * 0.54)
		draw_polyline(_quadratic_points(start, control, end, 10), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (0.20 + heartbeat * 0.24)), 1.0 + float(vein_index % 3) * 0.45, true)
	draw_circle(center, radius * (0.055 + heartbeat * 0.018) * amount, Color(COLD.r, COLD.g, COLD.b, alpha * amount * 0.76))


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
		var width := maxf(base_width * (1.0 - t * 0.72), 1.0)
		draw_line(points[index], points[index + 1], outer_color, width, true)
		draw_line(points[index], points[index + 1], inner_color, maxf(width * 0.20, 1.0), true)


func _quadratic_points(start: Vector2, control: Vector2, end: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var t := float(index) / float(segments)
		var inverse := 1.0 - t
		points.append(start * inverse * inverse + control * 2.0 * inverse * t + end * t * t)
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _stage(start: float, finish: float) -> float:
	return smoothstep(start, finish, progress)
