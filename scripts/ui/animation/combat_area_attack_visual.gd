extends Control

# Shared canvas for secondary damage caused by a normal attack. It renders only
# presentation snapshots supplied by the animation layer and never discovers
# targets or applies damage itself.

const KEY_FRONTAL := "frontal_attack_impact"
const KEY_FIXED_SPLASH := "fixed_splash_impact"
const KEY_SAINT_SWORD := "tokyo_saint_sword_splash"

const PHYSICAL_CORE := Color(1.0, 0.91, 0.66, 0.96)
const PHYSICAL_EDGE := Color(0.92, 0.48, 0.16, 0.84)
const PHYSICAL_SHADOW := Color(0.32, 0.12, 0.045, 0.46)
const SPLASH_CORE := Color(1.0, 0.82, 0.48, 0.94)
const SPLASH_EDGE := Color(0.84, 0.28, 0.10, 0.78)
const SWORD_CORE := Color(0.98, 0.94, 1.0, 0.98)
const SWORD_EDGE := Color(0.78, 0.10, 0.25, 0.90)
const SWORD_DEEP := Color(0.25, 0.01, 0.09, 0.72)
const SWORD_REFLECTION := Color(0.34, 0.48, 0.72, 0.46)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var source_point := Vector2.ZERO
var primary_point := Vector2.ZERO
var secondary_points := PackedVector2Array()
var visual_key := ""


func configure(
	source_center: Vector2,
	primary_center: Vector2,
	secondary_centers: PackedVector2Array,
	animation_key: String
) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_point = source_center
	primary_point = primary_center
	secondary_points = secondary_centers
	visual_key = animation_key
	queue_redraw()


func _draw() -> void:
	if source_point.distance_to(primary_point) <= 0.01 or secondary_points.is_empty():
		return

	match visual_key:
		KEY_FRONTAL:
			_draw_frontal_wave()
		KEY_SAINT_SWORD:
			_draw_saint_sword_splash()
		KEY_FIXED_SPLASH:
			_draw_fixed_splash()


func _draw_frontal_wave() -> void:
	var release := _stage(0.0, 0.42)
	var impact := _stage(0.30, 0.68)
	var fade := 1.0 - _stage(0.70, 1.0)
	var attack_vector := primary_point - source_point
	var attack_direction := attack_vector.normalized()
	var base_angle := attack_direction.angle()
	var reach := maxf(attack_vector.length(), 30.0)
	var spread := clampf(0.34 + float(secondary_points.size()) * 0.08, 0.42, 0.86)

	# A broad physical front communicates one attack covering several cells. It
	# stays low and translucent so actual affected cards remain readable.
	for wave_index in range(3):
		var wave_radius := reach * (0.48 + release * 0.50 + float(wave_index) * 0.055)
		var wave_alpha := fade * (0.48 - float(wave_index) * 0.11)
		draw_arc(
			source_point,
			wave_radius,
			base_angle - spread,
			base_angle + spread,
			48,
			Color(PHYSICAL_EDGE.r, PHYSICAL_EDGE.g, PHYSICAL_EDGE.b, wave_alpha),
			6.0 - float(wave_index) * 1.3,
			true
		)

	var central_start := source_point.lerp(primary_point, 0.32)
	var central_end := source_point.lerp(primary_point, 0.88 + release * 0.12)
	draw_line(
		central_start,
		central_end,
		Color(PHYSICAL_CORE.r, PHYSICAL_CORE.g, PHYSICAL_CORE.b, release * fade * 0.52),
		4.0,
		true
	)
	for point_index in range(secondary_points.size()):
		var impact_point := secondary_points[point_index]
		var local_direction := (impact_point - source_point).normalized()
		var sweep_start := primary_point.lerp(impact_point, 0.34)
		var sweep_end := impact_point - local_direction * 8.0
		draw_line(
			sweep_start,
			sweep_end,
			Color(PHYSICAL_SHADOW.r, PHYSICAL_SHADOW.g, PHYSICAL_SHADOW.b, impact * fade),
			7.0,
			true
		)
		_draw_impact_marker(impact_point, local_direction, PHYSICAL_CORE, PHYSICAL_EDGE, impact, fade, point_index)


func _draw_fixed_splash() -> void:
	var expansion := _stage(0.0, 0.52)
	var impact := _stage(0.24, 0.70)
	var fade := 1.0 - _stage(0.72, 1.0)
	var radius := _maximum_secondary_distance() * (0.28 + expansion * 0.72)

	for ring_index in range(3):
		var ring_radius := radius + float(ring_index) * 8.0
		draw_arc(
			primary_point,
			ring_radius,
			-progress * 0.28 + float(ring_index) * 0.34,
			TAU - progress * 0.28 + float(ring_index) * 0.34,
			56,
			Color(SPLASH_EDGE.r, SPLASH_EDGE.g, SPLASH_EDGE.b, fade * (0.48 - float(ring_index) * 0.12)),
			4.6 - float(ring_index) * 0.9,
			true
		)

	for point_index in range(secondary_points.size()):
		var impact_point := secondary_points[point_index]
		var direction := (impact_point - primary_point).normalized()
		var travel_end := primary_point.lerp(impact_point, expansion)
		draw_line(
			primary_point + direction * 10.0,
			travel_end,
			Color(SPLASH_CORE.r, SPLASH_CORE.g, SPLASH_CORE.b, expansion * fade * 0.58),
			3.2,
			true
		)
		_draw_impact_marker(impact_point, direction, SPLASH_CORE, SPLASH_EDGE, impact, fade, point_index)


func _draw_saint_sword_splash() -> void:
	var gather := _stage(0.0, 0.22)
	var release := _stage(0.10, 0.54)
	var impact := _stage(0.38, 0.72)
	var fade := 1.0 - _stage(0.76, 1.0)
	var attack_direction := (primary_point - source_point).normalized()
	var base_angle := attack_direction.angle()
	var radius := maxf(_maximum_secondary_distance() * (0.52 + release * 0.52), 28.0)

	# The sword form blooms from the primary hit as two controlled RC crescents;
	# it is a target-centered splash, not a second projectile from the attacker.
	for crescent_index in range(3):
		var crescent_radius := radius * (0.72 + float(crescent_index) * 0.15)
		var arc_offset := (-0.20 + float(crescent_index) * 0.19) * (0.7 + release * 0.3)
		var arc_color := SWORD_CORE if crescent_index == 1 else SWORD_EDGE
		draw_arc(
			primary_point,
			crescent_radius,
			base_angle - PI * 0.92 + arc_offset,
			base_angle + PI * 0.34 + arc_offset,
			54,
			Color(arc_color.r, arc_color.g, arc_color.b, gather * fade * (0.82 - float(crescent_index) * 0.12)),
			5.4 - float(crescent_index) * 0.8,
			true
		)

	draw_circle(
		primary_point,
		12.0 + gather * 12.0,
		Color(SWORD_DEEP.r, SWORD_DEEP.g, SWORD_DEEP.b, gather * fade * 0.44)
	)
	for point_index in range(secondary_points.size()):
		var impact_point := secondary_points[point_index]
		var direction := (impact_point - primary_point).normalized()
		var tangent := direction.orthogonal()
		var curve_points := _quadratic_points(
			primary_point + tangent * (10.0 + float(point_index % 3) * 4.0),
			primary_point.lerp(impact_point, 0.54) + tangent * (22.0 if point_index % 2 == 0 else -22.0),
			primary_point.lerp(impact_point, release),
			18
		)
		draw_polyline(
			curve_points,
			Color(SWORD_EDGE.r, SWORD_EDGE.g, SWORD_EDGE.b, release * fade * 0.76),
			4.2,
			true
		)
		draw_polyline(
			curve_points,
			Color(SWORD_REFLECTION.r, SWORD_REFLECTION.g, SWORD_REFLECTION.b, release * fade * 0.54),
			1.5,
			true
		)
		_draw_impact_marker(impact_point, direction, SWORD_CORE, SWORD_EDGE, impact, fade, point_index)


func _draw_impact_marker(
	impact_point: Vector2,
	attack_direction: Vector2,
	core_color: Color,
	edge_color: Color,
	impact: float,
	fade: float,
	seed: int
) -> void:
	if impact <= 0.0:
		return
	var marker_radius := 9.0 + impact * 18.0
	draw_circle(
		impact_point,
		marker_radius * 0.42,
		Color(core_color.r, core_color.g, core_color.b, (1.0 - impact) * fade * 0.36)
	)
	draw_arc(
		impact_point,
		marker_radius,
		attack_direction.angle() - PI * 0.74,
		attack_direction.angle() + PI * 0.74,
		28,
		Color(edge_color.r, edge_color.g, edge_color.b, (1.0 - impact * 0.48) * fade * 0.84),
		3.2,
		true
	)
	for ray_index in range(5):
		var ray_angle := attack_direction.angle() + PI + (-0.58 + float(ray_index) * 0.29) + float(seed % 3) * 0.05
		var ray_direction := Vector2.from_angle(ray_angle)
		draw_line(
			impact_point,
			impact_point + ray_direction * marker_radius * (0.70 + float(ray_index % 2) * 0.22),
			Color(core_color.r, core_color.g, core_color.b, (1.0 - impact) * fade * 0.92),
			2.2,
			true
		)


func _maximum_secondary_distance() -> float:
	var maximum_distance := 32.0
	for impact_point in secondary_points:
		maximum_distance = maxf(maximum_distance, primary_point.distance_to(impact_point))
	return maximum_distance


func _quadratic_points(
	start_point: Vector2,
	control_point: Vector2,
	end_point: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for segment_index in range(segment_count + 1):
		var ratio := float(segment_index) / float(segment_count)
		var inverse_ratio := 1.0 - ratio
		points.append(
			inverse_ratio * inverse_ratio * start_point
			+ 2.0 * inverse_ratio * ratio * control_point
			+ ratio * ratio * end_point
		)
	return points


func _stage(start_value: float, end_value: float) -> float:
	if progress <= start_value:
		return 0.0
	if progress >= end_value:
		return 1.0
	return smoothstep(start_value, end_value, progress)
