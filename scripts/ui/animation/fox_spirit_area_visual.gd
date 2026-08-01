extends Control
class_name FoxSpiritAreaVisual

# A board-space renderer for the 2x2 Foxfire selector and impact. The selected
# rectangle is supplied by the router; this class never resolves legal targets.

const FIRE_CORE := Color(0.70, 0.84, 1.0, 1.0)
const FIRE_BLUE := Color(0.24, 0.46, 0.96, 1.0)
const FIRE_VIOLET := Color(0.52, 0.12, 0.86, 1.0)
const FIRE_ROUGE := Color(0.92, 0.12, 0.48, 1.0)
const FIELD_DARK := Color(0.08, 0.01, 0.16, 1.0)

var source_point := Vector2.ZERO
var area_rect := Rect2()
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(local_source: Vector2, local_area_rect: Rect2) -> void:
	source_point = local_source
	area_rect = local_area_rect
	queue_redraw()


func _draw() -> void:
	if area_rect.size == Vector2.ZERO:
		return
	var gather := _phase(0.0, 0.22)
	var cast := _phase(0.14, 0.54)
	var burn := _phase(0.42, 0.82)
	var fade := _phase(0.76, 1.0)
	var alpha := 1.0 - fade
	var center := area_rect.get_center()
	var cell_size := area_rect.size * 0.5

	_draw_field_boundary(gather, burn, alpha)
	_draw_casting_arcs(cast, alpha)

	for cell_y in range(2):
		for cell_x in range(2):
			var cell_index := cell_y * 2 + cell_x
			var cell_center := area_rect.position + Vector2(
				(float(cell_x) + 0.5) * cell_size.x,
				(float(cell_y) + 0.5) * cell_size.y
			)
			_draw_cell_eye(cell_center, minf(cell_size.x, cell_size.y) * 0.22, gather, alpha)
			_draw_corner_flame(cell_center, cell_size, cell_index, burn, alpha)

	if burn > 0.0:
		var inward := sin(burn * PI)
		for flame_index in range(8):
			var angle := TAU * float(flame_index) / 8.0 + 0.24
			var edge_point := center + Vector2(cos(angle), sin(angle)) * minf(area_rect.size.x, area_rect.size.y) * 0.46
			var curled_point := edge_point.lerp(center, burn * 0.56)
			_draw_spirit_flame(
				curled_point,
				angle + PI + sin(progress * TAU + float(flame_index)) * 0.18,
				minf(cell_size.x, cell_size.y) * (0.34 + inward * 0.10),
				Color(FIRE_VIOLET.r, FIRE_VIOLET.g, FIRE_VIOLET.b, alpha * 0.46),
				Color(FIRE_CORE.r, FIRE_CORE.g, FIRE_CORE.b, alpha * 0.72)
			)


func _draw_field_boundary(gather: float, burn: float, alpha: float) -> void:
	var pulse := 0.82 + sin(progress * PI * 4.0) * 0.10
	var field_fill := Color(FIELD_DARK.r, FIELD_DARK.g, FIELD_DARK.b, alpha * (0.08 + burn * 0.08))
	draw_rect(area_rect, field_fill, true)

	var corners := [
		area_rect.position,
		Vector2(area_rect.end.x, area_rect.position.y),
		area_rect.end,
		Vector2(area_rect.position.x, area_rect.end.y),
	]
	for edge_index in range(4):
		var edge_start: Vector2 = corners[edge_index]
		var edge_end: Vector2 = corners[(edge_index + 1) % 4]
		var visible_end := edge_start.lerp(edge_end, gather)
		draw_line(
			edge_start,
			visible_end,
			Color(FIRE_BLUE.r, FIRE_BLUE.g, FIRE_BLUE.b, alpha * 0.18),
			9.0,
			true
		)
		draw_line(
			edge_start,
			visible_end,
			Color(FIRE_ROUGE.r, FIRE_ROUGE.g, FIRE_ROUGE.b, alpha * 0.54 * pulse),
			3.2,
			true
		)
		draw_line(
			edge_start,
			visible_end,
			Color(FIRE_CORE.r, FIRE_CORE.g, FIRE_CORE.b, alpha * 0.80),
			1.2,
			true
		)

	var vertical_mid_x := area_rect.position.x + area_rect.size.x * 0.5
	var horizontal_mid_y := area_rect.position.y + area_rect.size.y * 0.5
	draw_line(
		Vector2(vertical_mid_x, area_rect.position.y),
		Vector2(vertical_mid_x, area_rect.end.y),
		Color(0.46, 0.34, 0.88, alpha * 0.22 * gather),
		1.2,
		true
	)
	draw_line(
		Vector2(area_rect.position.x, horizontal_mid_y),
		Vector2(area_rect.end.x, horizontal_mid_y),
		Color(0.46, 0.34, 0.88, alpha * 0.22 * gather),
		1.2,
		true
	)


func _draw_casting_arcs(cast: float, alpha: float) -> void:
	if cast <= 0.0:
		return
	var destinations := [
		area_rect.position,
		Vector2(area_rect.end.x, area_rect.position.y),
		area_rect.end,
		Vector2(area_rect.position.x, area_rect.end.y),
	]
	var center := area_rect.get_center()
	for arc_index in range(destinations.size()):
		var destination: Vector2 = destinations[arc_index]
		var direction := _safe_normal(destination - source_point)
		var tangent := direction.orthogonal()
		var arc_side := -1.0 if arc_index % 2 == 0 else 1.0
		var control_a := source_point.lerp(destination, 0.30) + tangent * area_rect.size.x * 0.16 * arc_side
		var control_b := source_point.lerp(destination, 0.72) - tangent * area_rect.size.x * 0.10 * arc_side
		var points := _cubic_curve(source_point, control_a, control_b, destination, cast, 24)
		_draw_layered_line(
			points,
			Color(
				FIRE_BLUE.r if arc_index % 2 == 0 else FIRE_ROUGE.r,
				FIRE_BLUE.g if arc_index % 2 == 0 else FIRE_ROUGE.g,
				FIRE_BLUE.b if arc_index % 2 == 0 else FIRE_ROUGE.b,
				alpha * 0.72
			),
			2.0,
			7.0
		)
		if cast > 0.08:
			var flame_point := _point_on_cubic(source_point, control_a, control_b, destination, cast)
			_draw_spirit_flame(
				flame_point,
				(direction.angle() - PI * 0.5),
				minf(area_rect.size.x, area_rect.size.y) * 0.10,
				Color(FIRE_VIOLET.r, FIRE_VIOLET.g, FIRE_VIOLET.b, alpha * 0.64),
				Color(FIRE_CORE.r, FIRE_CORE.g, FIRE_CORE.b, alpha * 0.82)
			)

	if source_point.distance_to(center) > 3.0:
		var source_radius := minf(area_rect.size.x, area_rect.size.y) * 0.075
		draw_arc(
			source_point,
			source_radius * (0.72 + cast * 0.28),
			-PI * 0.88,
			PI * 0.88,
			32,
			Color(FIRE_ROUGE.r, FIRE_ROUGE.g, FIRE_ROUGE.b, alpha * 0.64),
			2.0,
			true
		)


func _draw_cell_eye(center: Vector2, radius: float, reveal: float, alpha: float) -> void:
	var eye_height := radius * 0.34 * reveal
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for point_index in range(19):
		var t := float(point_index) / 18.0
		var x := lerpf(-radius, radius, t)
		var arch := sin(t * PI) * eye_height
		upper.append(center + Vector2(x, -arch))
		lower.append(center + Vector2(x, arch))
	_draw_layered_line(upper, Color(FIRE_VIOLET.r, FIRE_VIOLET.g, FIRE_VIOLET.b, alpha * 0.38), 1.3, 4.0)
	_draw_layered_line(lower, Color(FIRE_ROUGE.r, FIRE_ROUGE.g, FIRE_ROUGE.b, alpha * 0.30), 1.3, 4.0)
	if reveal > 0.30:
		draw_circle(center, maxf(radius * 0.055, 1.0), Color(FIRE_CORE.r, FIRE_CORE.g, FIRE_CORE.b, alpha * 0.44))


func _draw_corner_flame(
	cell_center: Vector2,
	cell_size: Vector2,
	cell_index: int,
	burn: float,
	alpha: float
) -> void:
	if burn <= 0.0:
		return
	var phase_offset := float(cell_index) * 0.43
	var flame_count := 4
	for flame_index in range(flame_count):
		var angle := -PI * 0.78 + float(flame_index) * PI * 0.52 + phase_offset
		var orbit := minf(cell_size.x, cell_size.y) * (0.18 + 0.045 * float(flame_index % 2))
		var point := cell_center + Vector2(cos(angle), sin(angle)) * orbit
		var flicker := 0.88 + 0.12 * sin(progress * 13.0 + float(flame_index + cell_index * 3))
		_draw_spirit_flame(
			point,
			angle - PI * 0.5,
			minf(cell_size.x, cell_size.y) * 0.24 * burn * flicker,
			Color(
				FIRE_VIOLET.r if flame_index % 2 == 0 else FIRE_ROUGE.r,
				FIRE_VIOLET.g if flame_index % 2 == 0 else FIRE_ROUGE.g,
				FIRE_VIOLET.b if flame_index % 2 == 0 else FIRE_ROUGE.b,
				alpha * 0.54
			),
			Color(FIRE_CORE.r, FIRE_CORE.g, FIRE_CORE.b, alpha * 0.82)
		)


func _draw_spirit_flame(
	base: Vector2,
	angle: float,
	length: float,
	fill: Color,
	core: Color
) -> void:
	if length <= 1.0:
		return
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := direction.orthogonal()
	var points := PackedVector2Array([
		base - tangent * length * 0.18,
		base + direction * length * 0.34 - tangent * length * 0.24,
		base + direction * length * 0.82 - tangent * length * 0.08,
		base + direction * length,
		base + direction * length * 0.60 + tangent * length * 0.12,
		base + direction * length * 0.30 + tangent * length * 0.25,
		base + tangent * length * 0.18,
	])
	draw_colored_polygon(points, fill)
	var core_points := PackedVector2Array([
		base - tangent * length * 0.06,
		base + direction * length * 0.68,
		base + tangent * length * 0.06,
	])
	draw_colored_polygon(core_points, core)
	draw_polyline(points, Color(core.r, core.g, core.b, core.a * 0.62), 1.2, true)


func _draw_layered_line(points: PackedVector2Array, color: Color, width: float, glow_width: float) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.12), glow_width, true)
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.36), width * 1.8, true)
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


func _safe_normal(vector: Vector2) -> Vector2:
	return vector.normalized() if vector.length_squared() > 0.0001 else Vector2.RIGHT
