extends Control

# Board-scale faction events: RC concentration transitions and intelligence
# reserve restocks. These are deliberately brief and readable over the board.

const BLOOD := Color(0.92, 0.055, 0.15, 0.94)
const WINE := Color(0.44, 0.012, 0.075, 0.92)
const DEEP := Color(0.018, 0.008, 0.022, 0.76)
const COLD := Color(0.97, 0.84, 0.89, 0.90)
const CITY_BLUE := Color(0.18, 0.40, 0.64, 0.46)
const DOSSIER := Color(0.13, 0.11, 0.12, 0.96)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var profile := "rc_rise_medium"


func configure(visual_profile: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile = visual_profile
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var appear := _stage(0.0, 0.16)
	var resolve := _stage(0.14, 0.72)
	var fade := 1.0 - _stage(0.78, 1.0)
	var alpha := appear * fade

	_draw_rain(alpha)
	if profile.begins_with("rc_"):
		_draw_rc_transition(resolve, alpha)
	else:
		_draw_intelligence_restock(resolve, alpha, profile == "sss_rank_intelligence")


func _draw_rain(alpha: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(DEEP.r, DEEP.g, DEEP.b, DEEP.a * alpha), true)
	for rain_index in range(28):
		var x := fmod(float(rain_index) * 0.61803398875, 1.0) * size.x
		var y := fmod(progress * (1.1 + float(rain_index % 4) * 0.12) + float(rain_index) * 0.147, 1.0) * size.y
		var start := Vector2(x, y)
		draw_line(start, start + Vector2(-4.0, 18.0 + float(rain_index % 5) * 3.0), Color(0.44, 0.58, 0.72, alpha * 0.11), 1.0, true)


func _draw_rc_transition(resolve: float, alpha: float) -> void:
	var center := size * Vector2(0.50, 0.49)
	var base_radius := minf(size.x, size.y) * 0.095
	var is_rise := profile.begins_with("rc_rise")
	var target_level := 1
	if profile.ends_with("high"):
		target_level = 2
	elif profile.ends_with("low"):
		target_level = 0

	for level_index in range(3):
		var level_center := center + Vector2((float(level_index) - 1.0) * base_radius * 1.72, 0.0)
		var active_amount := clampf(resolve * 3.0 - absf(float(level_index - target_level)) * 0.42, 0.0, 1.0)
		var cell_radius := base_radius * (0.42 + active_amount * 0.16)
		var cell_color := Color(0.22 + float(level_index) * 0.18, 0.01, 0.045 + float(level_index) * 0.025, alpha * (0.36 + active_amount * 0.46))
		_draw_rc_cell(level_center, cell_radius, cell_color, alpha * (0.36 + active_amount * 0.58), level_index)
		if level_index == target_level:
			for ring_index in range(3):
				var phase := fmod(resolve + float(ring_index) * 0.26, 1.0)
				draw_arc(level_center, cell_radius * (1.15 + phase * 1.35), 0.0, TAU, 42, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * (1.0 - phase) * 0.35), 1.8, true)

	var line_y := center.y + base_radius * 0.98
	var line_start := center + Vector2(-base_radius * 1.72, base_radius * 0.98)
	var line_end := center + Vector2(base_radius * 1.72, base_radius * 0.98)
	draw_line(line_start, line_end, Color(CITY_BLUE.r, CITY_BLUE.g, CITY_BLUE.b, alpha * 0.42), 1.4, true)
	var direction_sign := 1.0 if is_rise else -1.0
	var arrow_start := Vector2(center.x - direction_sign * base_radius * 0.86, line_y)
	var arrow_end := arrow_start + Vector2(direction_sign * base_radius * 1.20 * resolve, 0.0)
	draw_line(arrow_start, arrow_end, Color(COLD.r, COLD.g, COLD.b, alpha * 0.78), 2.2, true)
	var arrow_direction := Vector2(direction_sign, 0.0)
	var arrow_normal := arrow_direction.orthogonal()
	var arrow := PackedVector2Array([
		arrow_end + arrow_direction * 10.0,
		arrow_end - arrow_direction * 6.0 + arrow_normal * 6.0,
		arrow_end - arrow_direction * 6.0 - arrow_normal * 6.0,
	])
	draw_colored_polygon(arrow, Color(COLD.r, COLD.g, COLD.b, alpha * 0.82))

	for pulse_index in range(18):
		var angle := float(pulse_index) * 2.399963
		var travel := fmod(resolve * (0.72 + float(pulse_index % 4) * 0.09) + float(pulse_index) * 0.097, 1.0)
		var origin := center + Vector2((float(target_level) - 1.0) * base_radius * 1.72, 0.0)
		var particle := origin + Vector2.from_angle(angle) * base_radius * (0.36 + travel * 1.48)
		draw_circle(particle, 1.4 + float(pulse_index % 3), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * sin(travel * PI) * 0.62))


func _draw_rc_cell(center: Vector2, radius: float, color: Color, alpha: float, level: int) -> void:
	var points := PackedVector2Array()
	var vertex_count := 7 + level
	for vertex_index in range(vertex_count):
		var angle := TAU * float(vertex_index) / float(vertex_count) - PI * 0.5
		var variance := 0.86 + 0.12 * sin(float(vertex_index) * 2.3 + float(level))
		points.append(center + Vector2.from_angle(angle) * radius * variance)
	draw_colored_polygon(points, color)
	draw_polyline(_closed(points), Color(COLD.r, 0.22 + float(level) * 0.06, 0.30 + float(level) * 0.05, alpha), 1.4 + float(level) * 0.4, true)
	draw_circle(center, radius * (0.16 + float(level) * 0.045), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.78))
	for vein_index in range(5 + level):
		var direction := Vector2.from_angle(TAU * float(vein_index) / float(5 + level))
		draw_line(center + direction * radius * 0.18, center + direction * radius * 0.72, Color(WINE.r, WINE.g, WINE.b, alpha * 0.58), 1.0, true)


func _draw_intelligence_restock(resolve: float, alpha: float, is_sss: bool) -> void:
	var center := size * Vector2(0.50, 0.48)
	var dossier_size := Vector2(minf(size.x * 0.20, 220.0), minf(size.y * 0.36, 260.0))
	var dossier_center := center + Vector2(0.0, lerpf(34.0, 0.0, resolve))
	var dossier := Rect2(dossier_center - dossier_size * 0.5, dossier_size)
	draw_rect(dossier, Color(DOSSIER.r, DOSSIER.g, DOSSIER.b, alpha * 0.94), true)
	draw_rect(dossier, Color(COLD.r, 0.24, 0.31, alpha * 0.62), false, 2.0, true)
	draw_rect(Rect2(dossier.position + Vector2(dossier.size.x * 0.10, dossier.size.y * 0.12), Vector2(dossier.size.x * 0.80, dossier.size.y * 0.05)), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.72), true)

	var silhouette_count := 4
	for silhouette_index in range(silhouette_count):
		var row_y := dossier.position.y + dossier.size.y * (0.30 + float(silhouette_index) * 0.15)
		var portrait_center := Vector2(dossier.position.x + dossier.size.x * 0.20, row_y)
		var rank_scale := 1.18 if is_sss else 1.0
		draw_circle(portrait_center + Vector2(0.0, -6.0 * rank_scale), 5.0 * rank_scale, Color(0.02, 0.01, 0.02, alpha * 0.94))
		draw_arc(portrait_center + Vector2(0.0, 4.0), 9.0 * rank_scale, PI, TAU, 16, Color(WINE.r, WINE.g, WINE.b, alpha * 0.78), 4.0, true)
		draw_line(Vector2(dossier.position.x + dossier.size.x * 0.32, row_y - 4.0), Vector2(dossier.position.x + dossier.size.x * 0.82, row_y - 4.0), Color(0.56, 0.47, 0.50, alpha * 0.42), 2.0, true)
		draw_line(Vector2(dossier.position.x + dossier.size.x * 0.32, row_y + 5.0), Vector2(dossier.position.x + dossier.size.x * 0.68, row_y + 5.0), Color(0.56, 0.47, 0.50, alpha * 0.28), 1.4, true)

	var stamp_radius := dossier_size.x * 0.15
	var stamp_center := dossier.position + Vector2(dossier.size.x * 0.78, dossier.size.y * 0.80)
	draw_arc(stamp_center, stamp_radius, -0.22, TAU - 0.22, 36, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.68), 3.0, true)
	draw_line(stamp_center - Vector2(stamp_radius * 0.66, 0.0), stamp_center + Vector2(stamp_radius * 0.66, 0.0), Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.62), 2.0, true)

	var hand_target := Vector2(size.x * 0.82, size.y * 0.84)
	for card_index in range(3 if is_sss else 2):
		var delay := float(card_index) * 0.12
		var flight := clampf((resolve - delay) / maxf(1.0 - delay, 0.01), 0.0, 1.0)
		var start := dossier.get_center() + Vector2((float(card_index) - 1.0) * 12.0, 0.0)
		var control := start.lerp(hand_target, 0.52) - Vector2(0.0, size.y * 0.18)
		var point := _quadratic_point(start, control, hand_target, flight)
		var card_rect := Rect2(point - Vector2(9.0, 13.0), Vector2(18.0, 26.0))
		draw_rect(card_rect, Color(0.18, 0.04, 0.07, alpha * 0.86), true)
		draw_rect(card_rect, Color(COLD.r, 0.24, 0.34, alpha * 0.62), false, 1.0, true)
		draw_line(start, point, Color(BLOOD.r, BLOOD.g, BLOOD.b, alpha * 0.16), 1.0, true)


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
