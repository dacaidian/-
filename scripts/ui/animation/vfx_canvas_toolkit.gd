extends RefCounted
class_name VfxCanvasToolkit

# Shared canvas primitives for code-native VFX. These helpers favor filled,
# tapered material shapes over stacks of equally weighted lines.

const MIN_PATH_POINT_DISTANCE := 0.05
const MIN_PATH_POINT_DISTANCE_SQUARED := MIN_PATH_POINT_DISTANCE * MIN_PATH_POINT_DISTANCE
const MIN_TRIANGLE_DOUBLE_AREA := 0.01
const MIN_ELLIPSE_RADIUS := 0.1
const MIN_ELLIPSE_AREA := 0.01


static func with_alpha(color: Color, alpha_scale: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * clampf(alpha_scale, 0.0, 1.0))


static func draw_soft_disc(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	color: Color,
	core_color := Color.TRANSPARENT,
	layers := 6
) -> void:
	if radius <= 0.1 or color.a <= 0.001:
		return
	var safe_layers := maxi(layers, 2)
	for layer_index in range(safe_layers):
		var ratio := float(layer_index) / float(safe_layers - 1)
		var layer_radius := radius * lerpf(1.42, 0.34, ratio)
		var layer_alpha := color.a * lerpf(0.035, 0.26, pow(ratio, 1.45))
		canvas.draw_circle(center, layer_radius, Color(color.r, color.g, color.b, layer_alpha))
	if core_color.a > 0.001:
		canvas.draw_circle(center, radius * 0.30, with_alpha(core_color, 0.72))
		canvas.draw_circle(center - Vector2(radius * 0.10, radius * 0.12), radius * 0.085, with_alpha(Color.WHITE, core_color.a * 0.78))


static func draw_soft_ellipse(
	canvas: CanvasItem,
	center: Vector2,
	radii: Vector2,
	color: Color,
	core_color := Color.TRANSPARENT,
	layers := 6,
	rotation_radians := 0.0
) -> void:
	if (
		canvas == null
		or not center.is_finite()
		or not radii.is_finite()
		or not is_finite(rotation_radians)
		or radii.x <= MIN_ELLIPSE_RADIUS
		or radii.y <= MIN_ELLIPSE_RADIUS
		or radii.x * radii.y * PI < MIN_ELLIPSE_AREA
		or color.a <= 0.001
	):
		return
	var safe_layers := maxi(layers, 2)
	for layer_index in range(safe_layers):
		var ratio := float(layer_index) / float(safe_layers - 1)
		var scale_value := lerpf(1.38, 0.38, ratio)
		var layer_alpha := color.a * lerpf(0.035, 0.25, pow(ratio, 1.4))
		_draw_transformed_disc(
			canvas,
			center,
			radii * scale_value,
			rotation_radians,
			Color(color.r, color.g, color.b, layer_alpha)
		)
	if core_color.a > 0.001:
		_draw_transformed_disc(
			canvas,
			center,
			radii * 0.32,
			rotation_radians,
			with_alpha(core_color, 0.70)
		)


static func _draw_transformed_disc(
	canvas: CanvasItem,
	center: Vector2,
	radii: Vector2,
	rotation_radians: float,
	color: Color
) -> void:
	if (
		canvas == null
		or not center.is_finite()
		or not radii.is_finite()
		or not is_finite(rotation_radians)
		or radii.x <= MIN_ELLIPSE_RADIUS
		or radii.y <= MIN_ELLIPSE_RADIUS
		or radii.x * radii.y * PI < MIN_ELLIPSE_AREA
		or color.a <= 0.001
	):
		return
	canvas.draw_set_transform(center, rotation_radians, radii)
	canvas.draw_circle(Vector2.ZERO, 1.0, color, true, -1.0, true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_ribbon(
	canvas: CanvasItem,
	points: PackedVector2Array,
	width: float,
	body_color: Color,
	edge_color := Color.TRANSPARENT,
	highlight_color := Color.TRANSPARENT,
	glow_width := 0.0,
	taper_start := true,
	taper_end := true,
	organic_phase := 0.0
) -> void:
	if (
		points.size() < 2
		or not is_finite(width)
		or not is_finite(glow_width)
		or not is_finite(organic_phase)
		or width <= 0.1
		or body_color.a <= 0.001
	):
		return
	var render_points := _sanitize_ribbon_points(points)
	if render_points.size() < 2:
		return
	if render_points.size() == 2:
		var start_point := render_points[0]
		var end_point := render_points[1]
		render_points = PackedVector2Array()
		for point_index in range(7):
			render_points.append(start_point.lerp(end_point, float(point_index) / 6.0))
	var safe_glow_width := maxf(glow_width, width * 2.8)
	_draw_ribbon_segments(
		canvas,
		render_points,
		safe_glow_width,
		Color(body_color.r, body_color.g, body_color.b, body_color.a * 0.075),
		taper_start,
		taper_end,
		organic_phase,
		0.0
	)
	if edge_color.a > 0.001:
		_draw_ribbon_segments(canvas, render_points, width * 1.34, edge_color, taper_start, taper_end, organic_phase + 0.37, 0.0)
	_draw_ribbon_segments(canvas, render_points, width, body_color, taper_start, taper_end, organic_phase, 0.0)
	if highlight_color.a > 0.001:
		_draw_ribbon_segments(canvas, render_points, width * 0.23, highlight_color, taper_start, taper_end, organic_phase + 0.71, -width * 0.18)


static func draw_stroked_path(
	canvas: CanvasItem,
	points: PackedVector2Array,
	width: float,
	body_color: Color,
	edge_color := Color.TRANSPARENT,
	highlight_color := Color.TRANSPARENT,
	glow_width := 0.0
) -> void:
	if not is_finite(width) or not is_finite(glow_width) or width <= 0.1 or body_color.a <= 0.001:
		return
	var render_points := _sanitize_ribbon_points(points)
	if render_points.size() < 2:
		return
	var safe_glow_width := maxf(glow_width, width * 2.8)
	canvas.draw_polyline(
		render_points,
		Color(body_color.r, body_color.g, body_color.b, body_color.a * 0.075),
		safe_glow_width,
		true
	)
	if edge_color.a > 0.001:
		canvas.draw_polyline(render_points, edge_color, width * 1.34, true)
	canvas.draw_polyline(render_points, body_color, width, true)
	if highlight_color.a > 0.001:
		canvas.draw_polyline(render_points, highlight_color, maxf(width * 0.23, 0.8), true)


static func draw_stroked_arc(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	width: float,
	body_color: Color,
	edge_color := Color.TRANSPARENT,
	highlight_color := Color.TRANSPARENT,
	glow_width := 0.0,
	segments := 24
) -> void:
	if not center.is_finite() or not is_finite(radius) or radius <= 0.1:
		return
	var points := PackedVector2Array()
	var safe_segments := maxi(segments, 4)
	for point_index in range(safe_segments + 1):
		var ratio := float(point_index) / float(safe_segments)
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_stroked_path(
		canvas,
		points,
		width,
		body_color,
		edge_color,
		highlight_color,
		glow_width
	)


static func draw_arc_ribbon(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	width: float,
	body_color: Color,
	edge_color := Color.TRANSPARENT,
	highlight_color := Color.TRANSPARENT,
	glow_width := 0.0,
	segments := 32,
	taper_start := true,
	taper_end := true,
	organic_phase := 0.0
) -> void:
	if radius <= 0.1:
		return
	var points := PackedVector2Array()
	var safe_segments := maxi(segments, 4)
	for point_index in range(safe_segments + 1):
		var ratio := float(point_index) / float(safe_segments)
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_ribbon(
		canvas,
		points,
		width,
		body_color,
		edge_color,
		highlight_color,
		glow_width,
		taper_start,
		taper_end,
		organic_phase
	)


static func draw_mote(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	color: Color,
	phase_value := 0.0
) -> void:
	if radius <= 0.1 or color.a <= 0.001:
		return
	var breath := 0.90 + sin(phase_value) * 0.10
	draw_soft_disc(canvas, center, radius * breath, with_alpha(color, 0.62), with_alpha(Color.WHITE, color.a * 0.66), 5)
	var direction := Vector2(cos(phase_value * 0.73), sin(phase_value * 0.73))
	canvas.draw_circle(center - direction * radius * 0.18, radius * 0.16, with_alpha(Color.WHITE, color.a * 0.54))


static func _draw_ribbon_segments(
	canvas: CanvasItem,
	points: PackedVector2Array,
	width: float,
	color: Color,
	taper_start: bool,
	taper_end: bool,
	organic_phase: float,
	lateral_offset: float
) -> void:
	if points.size() < 2 or not is_finite(width) or width <= 0.0 or color.a <= 0.001:
		return
	var last_index := points.size() - 1
	for segment_index in range(last_index):
		var start := points[segment_index]
		var finish := points[segment_index + 1]
		if not start.is_finite() or not finish.is_finite():
			continue
		var direction := finish - start
		if direction.length_squared() < MIN_PATH_POINT_DISTANCE_SQUARED:
			continue
		var normal := direction.normalized().orthogonal()
		var start_ratio := float(segment_index) / float(last_index)
		var end_ratio := float(segment_index + 1) / float(last_index)
		var start_half_width := _ribbon_half_width(width, start_ratio, taper_start, taper_end, organic_phase)
		var end_half_width := _ribbon_half_width(width, end_ratio, taper_start, taper_end, organic_phase)
		if not is_finite(start_half_width) or not is_finite(end_half_width):
			continue
		var shifted_start := start + normal * lateral_offset
		var shifted_finish := finish + normal * lateral_offset
		var start_outer := shifted_start + normal * start_half_width
		var finish_outer := shifted_finish + normal * end_half_width
		var finish_inner := shifted_finish - normal * end_half_width
		var start_inner := shifted_start - normal * start_half_width
		_draw_safe_quad(canvas, start_outer, finish_outer, finish_inner, start_inner, color)
	for point_index in range(1, last_index):
		if not points[point_index].is_finite():
			continue
		var ratio := float(point_index) / float(last_index)
		var joint_radius := _ribbon_half_width(width, ratio, taper_start, taper_end, organic_phase)
		if is_finite(joint_radius) and joint_radius > 0.1:
			canvas.draw_circle(points[point_index], joint_radius, color)


static func _sanitize_ribbon_points(points: PackedVector2Array) -> PackedVector2Array:
	var sanitized := PackedVector2Array()
	for point in points:
		if not point.is_finite():
			continue
		if sanitized.is_empty() or sanitized[-1].distance_squared_to(point) >= MIN_PATH_POINT_DISTANCE_SQUARED:
			sanitized.append(point)
	return sanitized


static func _draw_safe_quad(
	canvas: CanvasItem,
	point_a: Vector2,
	point_b: Vector2,
	point_c: Vector2,
	point_d: Vector2,
	color: Color
) -> void:
	if (
		not point_a.is_finite()
		or not point_b.is_finite()
		or not point_c.is_finite()
		or not point_d.is_finite()
	):
		return
	var first_double_area := absf((point_b - point_a).cross(point_c - point_a))
	var second_double_area := absf((point_c - point_a).cross(point_d - point_a))
	if (
		not is_finite(first_double_area)
		or not is_finite(second_double_area)
		or first_double_area < MIN_TRIANGLE_DOUBLE_AREA
		or second_double_area < MIN_TRIANGLE_DOUBLE_AREA
	):
		return
	canvas.draw_primitive(
		PackedVector2Array([point_a, point_b, point_c, point_d]),
		PackedColorArray([color, color, color, color]),
		PackedVector2Array()
	)


static func _ribbon_half_width(
	width: float,
	ratio: float,
	taper_start: bool,
	taper_end: bool,
	organic_phase: float
) -> float:
	var envelope := 1.0
	if taper_start:
		envelope *= maxf(_smooth_unit(clampf(ratio / 0.16, 0.0, 1.0)), 0.08)
	if taper_end:
		envelope *= maxf(_smooth_unit(clampf((1.0 - ratio) / 0.20, 0.0, 1.0)), 0.08)
	var organic_width := 0.94 + sin(ratio * TAU * 2.35 + organic_phase) * 0.055 + sin(ratio * TAU * 5.1 + organic_phase * 0.61) * 0.025
	return maxf(width * 0.5 * envelope * organic_width, 0.08)


static func _smooth_unit(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)
