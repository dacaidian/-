extends Control
class_name FoxSpiritRitualVisual

# Large-scale and multi-card Fox Spirit rituals. The provider supplies resolved
# rectangles; this renderer only stages the presentation.

const CRIMSON := Color(0.78, 0.035, 0.17, 1.0)
const ROUGE := Color(0.96, 0.18, 0.43, 1.0)
const VIOLET := Color(0.58, 0.14, 0.82, 1.0)
const DEEP_PURPLE := Color(0.10, 0.008, 0.16, 1.0)
const MOON_WHITE := Color(0.96, 0.94, 1.0, 1.0)
const PEARL_GOLD := Color(0.94, 0.80, 0.48, 1.0)
const GHOST_BLUE := Color(0.30, 0.72, 0.98, 1.0)

var animation_key := ""
var source_point := Vector2.ZERO
var destination_point := Vector2.ZERO
var target_rects: Array[Rect2] = []
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(
	key: String,
	local_source: Vector2,
	local_destination: Vector2,
	local_target_rects: Array[Rect2] = []
) -> void:
	animation_key = key
	source_point = local_source
	destination_point = local_destination
	target_rects = local_target_rects.duplicate()
	queue_redraw()


func _draw() -> void:
	match animation_key:
		"celestial_fox_evolve":
			_draw_celestial_fox_evolution()
		"ruin_country_targets":
			_draw_ruin_country_targets()
		"nine_tail_army":
			_draw_nine_tail_army()
		_:
			_draw_ruin_country()


func _draw_ruin_country() -> void:
	var gather := _phase(0.0, 0.26)
	var awaken := _phase(0.18, 0.62)
	var fade := _phase(0.78, 1.0)
	var alpha := 1.0 - fade
	var ritual_center := destination_point if destination_point != Vector2.ZERO else size * 0.5
	var radius := minf(size.x, size.y) * 0.20

	draw_rect(Rect2(Vector2.ZERO, size), Color(DEEP_PURPLE.r, DEEP_PURPLE.g, DEEP_PURPLE.b, 0.10 * awaken * alpha), true)

	if source_point.distance_to(ritual_center) > 4.0:
		var direction := _safe_normal(ritual_center - source_point)
		var tangent := direction.orthogonal()
		var control_a := source_point.lerp(ritual_center, 0.34) + tangent * radius * 0.66
		var control_b := source_point.lerp(ritual_center, 0.68) - tangent * radius * 0.38
		var path := _cubic_curve(source_point, control_a, control_b, ritual_center, gather, 34)
		_draw_layered_line(path, Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.72 * alpha), 2.8, 10.0)

	# Nine independent tails make the final-state resource language explicit.
	var tail_base := ritual_center + Vector2(0.0, radius * 0.36)
	for tail_index in range(9):
		var stagger := clampf((awaken - float(tail_index) * 0.035) / 0.72, 0.0, 1.0)
		var angle := lerpf(-PI * 0.94, -PI * 0.06, float(tail_index) / 8.0)
		var tail_length := radius * (0.84 + 0.08 * float(tail_index % 3)) * stagger
		var tail_fill := _tail_stage_color(tail_index, alpha * (0.30 + stagger * 0.38))
		var tail_edge := Color(
			MOON_WHITE.r if tail_index >= 5 else ROUGE.r,
			MOON_WHITE.g if tail_index >= 5 else ROUGE.g,
			MOON_WHITE.b if tail_index >= 5 else ROUGE.b,
			alpha * (0.52 + stagger * 0.30)
		)
		_draw_tail_shape(tail_base, angle, tail_length, radius * 0.085, tail_fill, tail_edge)

	_draw_fox_eye(
		ritual_center,
		radius * 0.54,
		awaken,
		Color(0.12, 0.005, 0.18, 0.66 * alpha),
		Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.88 * alpha),
		Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, 0.92 * alpha)
	)



func _draw_ruin_country_targets() -> void:
	var gather := _phase(0.0, 0.34)
	var bind := _phase(0.18, 0.80)
	var fade := _phase(0.74, 1.0)
	var alpha := 1.0 - fade
	var ritual_center := size * 0.5
	var center_radius := maxf(minf(size.x, size.y) * 0.085, 24.0)

	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color(DEEP_PURPLE.r, DEEP_PURPLE.g, DEEP_PURPLE.b, 0.08 * gather * alpha),
		true
	)
	for target_index in range(target_rects.size()):
		var target_rect := target_rects[target_index]
		var target_progress := clampf((bind - float(target_index) * 0.035) / 0.82, 0.0, 1.0)
		if target_progress <= 0.0:
			continue
		var target_center := target_rect.get_center()
		var radius := maxf(minf(target_rect.size.x, target_rect.size.y) * 0.38, 18.0)
		var direction := _safe_normal(ritual_center - target_center)
		var tangent := direction.orthogonal()
		var control_a := target_center.lerp(ritual_center, 0.34) + tangent * radius * (0.55 if target_index % 2 == 0 else -0.55)
		var control_b := target_center.lerp(ritual_center, 0.74) - tangent * radius * 0.30
		var thread := _cubic_curve(target_center, control_a, control_b, ritual_center, target_progress, 24)
		_draw_layered_line(
			thread,
			Color(ROUGE.r, ROUGE.g, ROUGE.b, alpha * (0.44 + target_progress * 0.26)),
			1.8,
			6.0
		)
		draw_rect(
			target_rect.grow(-target_rect.size.x * 0.06),
			Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, alpha * 0.52 * target_progress),
			false,
			2.0,
			true
		)
		_draw_fox_eye(
			target_center,
			radius,
			target_progress,
			Color(0.16, 0.005, 0.20, 0.38 * alpha),
			Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.78 * alpha),
			Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.82 * alpha)
		)

	_draw_fox_eye(
		ritual_center,
		center_radius,
		gather,
		Color(0.12, 0.005, 0.18, 0.48 * alpha),
		Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.74 * alpha),
		Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, 0.88 * alpha)
	)


func _draw_nine_tail_army() -> void:
	var gather := _phase(0.0, 0.24)
	var form := _phase(0.18, 0.62)
	var dispatch := _phase(0.52, 0.92)
	var fade := _phase(0.86, 1.0)
	var alpha := 1.0 - fade
	var center := source_point if source_point != Vector2.ZERO else size * 0.5
	var destination := destination_point if destination_point != Vector2.ZERO else Vector2(size.x * 0.32, size.y * 0.88)
	var radius := minf(size.x, size.y) * 0.16

	for seed_index in range(9):
		var angle := lerpf(-PI * 0.92, -PI * 0.08, float(seed_index) / 8.0)
		var orbit_point := center + Vector2(cos(angle), sin(angle)) * radius * (0.72 + 0.08 * float(seed_index % 2)) * form
		var dispatch_progress := clampf((dispatch - float(seed_index % 3) * 0.08) / 0.84, 0.0, 1.0)
		var seed_row := floori(float(seed_index) / 3.0)
		var lane_offset := Vector2((float(seed_index % 3) - 1.0) * 42.0, float(seed_row) * 16.0)
		var end := destination + lane_offset
		var direction := _safe_normal(end - orbit_point)
		var tangent := direction.orthogonal()
		var control_a := orbit_point.lerp(end, 0.30) + tangent * radius * (0.50 - float(seed_index % 3) * 0.20)
		var control_b := orbit_point.lerp(end, 0.72) - tangent * radius * 0.22
		var seed_point := _point_on_cubic(orbit_point, control_a, control_b, end, _ease_in_out(dispatch_progress))
		if dispatch_progress > 0.02:
			var path := _cubic_curve(orbit_point, control_a, control_b, end, dispatch_progress, 22)
			_draw_layered_line(path, Color(0.58, 0.34, 0.92, alpha * 0.26), 1.3, 4.5)
		_draw_tail_shape(
			seed_point,
			angle - dispatch_progress * 0.60,
			radius * 0.30 * gather,
			radius * 0.055,
			_tail_stage_color(seed_index, alpha * 0.72),
			Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, alpha * 0.78)
		)

	_draw_fox_eye(
		center,
		radius * 0.42,
		form * (1.0 - dispatch * 0.42),
		Color(0.12, 0.005, 0.18, 0.46 * alpha),
		Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.74 * alpha),
		Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, 0.86 * alpha)
	)
	_draw_count_label(center + Vector2(radius * 0.58, radius * 0.40), "x9", radius * 0.28, alpha * form)


func _draw_celestial_fox_evolution() -> void:
	var global_fade := _phase(0.84, 1.0)
	var global_alpha := 1.0 - global_fade
	for target_index in range(target_rects.size()):
		var target_rect := target_rects[target_index]
		var stagger := float(target_index) * 0.055
		var cocoon := clampf((progress - stagger) / 0.48, 0.0, 1.0)
		var reveal := clampf((progress - 0.34 - stagger) / 0.40, 0.0, 1.0)
		var center := target_rect.get_center()
		var radius := maxf(minf(target_rect.size.x, target_rect.size.y) * 0.58, 20.0)
		var base := center + Vector2(0.0, radius * 0.42)

		for tail_index in range(6):
			var angle := lerpf(-PI * 0.94, -PI * 0.06, float(tail_index) / 5.0)
			var side_cocoon := sin(cocoon * PI * 0.86)
			var inward_angle := lerpf(angle, -PI * 0.5, reveal * 0.72)
			_draw_tail_shape(
				base,
				inward_angle,
				radius * (0.88 + 0.08 * float(tail_index % 2)) * side_cocoon,
				radius * 0.13,
				Color(0.78, 0.62, 0.96, global_alpha * (0.24 + cocoon * 0.38)),
				Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, global_alpha * (0.44 + reveal * 0.40))
			)

		var silhouette_rect := Rect2(center - target_rect.size * 0.38, target_rect.size * 0.76)
		draw_rect(
			silhouette_rect,
			Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, global_alpha * sin(reveal * PI) * 0.18),
			true
		)
		draw_rect(
			silhouette_rect,
			Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, global_alpha * reveal * 0.72),
			false,
			2.4,
			true
		)
		_draw_fox_eye(
			center,
			radius * 0.42,
			reveal,
			Color(0.12, 0.01, 0.18, global_alpha * 0.48),
			Color(0.86, 0.70, 1.0, global_alpha * 0.82),
			Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, global_alpha * 0.90)
		)


func _draw_count_label(label_center: Vector2, label_text: String, font_size_value: float, alpha: float) -> void:
	var font := get_theme_default_font()
	if font == null or alpha <= 0.01:
		return
	var font_size := maxi(int(font_size_value), 18)
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var text_origin := label_center - text_size * 0.5
	text_origin.y += text_size.y * 0.80
	draw_string(font, text_origin + Vector2(2.0, 2.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.08, 0.0, 0.12, alpha * 0.88))
	draw_string(font, text_origin, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, alpha))


func _tail_stage_color(tail_index: int, alpha: float) -> Color:
	if tail_index >= 8:
		return Color(0.94, 0.88, 1.0, alpha)
	if tail_index >= 5:
		return Color(0.82, 0.58, 0.94, alpha)
	if tail_index >= 2:
		return Color(0.90, 0.18, 0.46, alpha)
	return Color(0.56, 0.04, 0.16, alpha)


func _draw_fox_eye(
	center: Vector2,
	radius: float,
	openness: float,
	fill: Color,
	edge: Color,
	core: Color
) -> void:
	var safe_open := clampf(openness, 0.0, 1.0)
	var eye_height := radius * (0.08 + safe_open * 0.32)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for point_index in range(23):
		var t := float(point_index) / 22.0
		var x := lerpf(-radius, radius, t)
		var arch := sin(t * PI) * eye_height
		upper.append(center + Vector2(x, -arch))
		lower.append(center + Vector2(x, arch))
	var polygon := PackedVector2Array()
	for point in upper:
		polygon.append(point)
	for point_index in range(lower.size() - 1, -1, -1):
		polygon.append(lower[point_index])
	draw_colored_polygon(polygon, fill)
	_draw_layered_line(upper, edge, 2.2, 6.0)
	_draw_layered_line(lower, edge, 2.2, 6.0)
	if safe_open > 0.16:
		_draw_ellipse(center, Vector2(radius * 0.10, eye_height * 0.72), Color(core.r, core.g, core.b, core.a * safe_open))


func _draw_tail_shape(
	base: Vector2,
	angle: float,
	length: float,
	width: float,
	fill: Color,
	edge: Color
) -> void:
	if length <= 1.0:
		return
	var centerline := _tail_centerline(base, angle, length, width)
	for point_index in range(centerline.size() - 1):
		var t := (float(point_index) + 0.5) / float(centerline.size() - 1)
		var stroke_width := maxf(width * 2.0 * pow(sin(t * PI), 0.58), 1.0)
		draw_line(
			centerline[point_index],
			centerline[point_index + 1],
			Color(edge.r, edge.g, edge.b, edge.a * 0.18),
			stroke_width + 7.0,
			true
		)
	for point_index in range(centerline.size() - 1):
		var t := (float(point_index) + 0.5) / float(centerline.size() - 1)
		var stroke_width := maxf(width * 2.0 * pow(sin(t * PI), 0.58), 1.0)
		draw_line(centerline[point_index], centerline[point_index + 1], edge, stroke_width + 2.0, true)
		draw_line(centerline[point_index], centerline[point_index + 1], fill, stroke_width, true)
	draw_circle(centerline[centerline.size() - 1], maxf(width * 0.12, 0.8), edge)


func _tail_centerline(base: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := direction.orthogonal()
	var centers := PackedVector2Array()
	for point_index in range(13):
		var t := float(point_index) / 12.0
		centers.append(base + direction * length * t + tangent * (sin(t * PI) * width * 0.82 + t * t * width * 0.28))
	return centers


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_layered_line(points: PackedVector2Array, color: Color, width: float, glow_width: float) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.10), glow_width, true)
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.34), width * 1.8, true)
	draw_polyline(points, color, width, true)


func _cubic_curve(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	destination: Vector2,
	visible_progress: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_progress := clampf(visible_progress, 0.0, 1.0)
	var visible_segments := maxi(int(ceil(float(segments) * safe_progress)), 1)
	for point_index in range(visible_segments + 1):
		var t := float(point_index) / float(visible_segments) * safe_progress
		points.append(_point_on_cubic(start, control_a, control_b, destination, t))
	return points


func _point_on_cubic(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	destination: Vector2,
	t: float
) -> Vector2:
	var inverse := 1.0 - t
	return (
		start * inverse * inverse * inverse
		+ control_a * 3.0 * inverse * inverse * t
		+ control_b * 3.0 * inverse * t * t
		+ destination * t * t * t
	)


func _phase(start: float, end: float) -> float:
	return clampf((progress - start) / maxf(end - start, 0.0001), 0.0, 1.0)


func _ease_in_out(value: float) -> float:
	var safe_value := clampf(value, 0.0, 1.0)
	return safe_value * safe_value * (3.0 - 2.0 * safe_value)


func _safe_normal(vector: Vector2) -> Vector2:
	return vector.normalized() if vector.length_squared() > 0.0001 else Vector2.RIGHT
