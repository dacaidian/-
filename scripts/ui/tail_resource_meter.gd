extends Control
class_name TailResourceMeter

# Compact nine-slot Fox Spirit resource display. It animates from the previous
# committed value to the new value but never owns or mutates faction resources.

const INACTIVE_FILL := Color(0.12, 0.075, 0.11, 0.90)
const INACTIVE_EDGE := Color(0.38, 0.22, 0.32, 0.56)
const DARK_RED := Color(0.58, 0.055, 0.16, 1.0)
const ROUGE := Color(0.92, 0.16, 0.40, 1.0)
const VIOLET := Color(0.60, 0.24, 0.84, 1.0)
const MOON_WHITE := Color(0.94, 0.92, 1.0, 1.0)
const PEARL_GOLD := Color(0.92, 0.76, 0.42, 1.0)

var current_value := 0
var previous_value := 0
var maximum_value := 9
var animation_elapsed := 0.0
var animation_duration := 0.82
var animation_progress := 1.0
var pulse_time := 0.0


func _ready() -> void:
	name = "TailResourceMeter"
	add_to_group("fox_tail_resource_meter")
	mouse_filter = Control.MOUSE_FILTER_PASS
	# The containing HUD panel owns horizontal sizing. A fixed minimum width here
	# would include both HUD and inset safe areas and could widen the whole column.
	custom_minimum_size = Vector2(0.0, 48.0)
	set_process(current_value != previous_value)
	queue_redraw()


func configure(new_value: int, max_value: int, old_value: int, hint: String) -> TailResourceMeter:
	maximum_value = clampi(max_value, 1, 9)
	current_value = clampi(new_value, 0, maximum_value)
	previous_value = clampi(old_value, 0, maximum_value)
	tooltip_text = hint
	animation_elapsed = 0.0
	animation_duration = 1.08 if _crossed_threshold(previous_value, current_value) else 0.82
	animation_progress = 0.0 if current_value != previous_value else 1.0
	set_process(animation_progress < 1.0)
	queue_redraw()
	return self


func _process(delta: float) -> void:
	pulse_time = fmod(pulse_time + delta, 1000.0)
	if animation_progress < 1.0:
		animation_elapsed += delta
		animation_progress = clampf(animation_elapsed / maxf(animation_duration, 0.01), 0.0, 1.0)
		if animation_progress >= 1.0:
			set_process(false)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.50, size.y * 0.82)
	var max_length := minf(size.x * 0.18, size.y * 0.72)
	var base_width := maxf(size.x * 0.018, 4.2)
	var displayed_value := _displayed_value()

	# Inactive silhouettes are drawn first so the nine-slot capacity is always
	# legible, even at one tail.
	for tail_index in range(maximum_value):
		var angle := _tail_angle(tail_index)
		var length_scale := 0.86 + 0.06 * float(tail_index % 3)
		_draw_tail(
			center,
			angle,
			max_length * length_scale,
			base_width,
			INACTIVE_FILL,
			INACTIVE_EDGE
		)

	for tail_index in range(maximum_value):
		var activation := clampf(displayed_value - float(tail_index), 0.0, 1.0)
		if activation <= 0.0:
			continue
		var angle := _tail_angle(tail_index)
		var length_scale := 0.86 + 0.06 * float(tail_index % 3)
		var pulse := 1.0
		if tail_index == current_value - 1 and current_value != previous_value:
			pulse += sin(animation_progress * PI) * 0.16
		var fill := _active_color(tail_index, 0.54 + activation * 0.30)
		var edge := _active_edge_color(tail_index, 0.66 + activation * 0.30)
		_draw_tail(
			center,
			angle,
			max_length * length_scale * activation * pulse,
			base_width * (0.92 + activation * 0.14),
			fill,
			edge
		)

	_draw_threshold_marker(center, max_length, 2, Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.86))
	_draw_threshold_marker(center, max_length, 5, Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.82))
	_draw_threshold_marker(center, max_length, 8, Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, 0.92))
	_draw_center_eye(center, max_length * 0.42)
	_draw_value(center, current_value)


func _displayed_value() -> float:
	if current_value == previous_value:
		return float(current_value)
	var eased := animation_progress * animation_progress * (3.0 - 2.0 * animation_progress)
	return lerpf(float(previous_value), float(current_value), eased)


func _tail_angle(tail_index: int) -> float:
	if maximum_value <= 1:
		return -PI * 0.5
	return lerpf(-PI * 0.94, -PI * 0.06, float(tail_index) / float(maximum_value - 1))


func _active_color(tail_index: int, alpha: float) -> Color:
	if tail_index >= 8:
		return Color(0.94, 0.88, 1.0, alpha)
	if tail_index >= 5:
		return Color(0.82, 0.62, 0.96, alpha)
	if tail_index >= 2:
		return Color(ROUGE.r, ROUGE.g, ROUGE.b, alpha)
	return Color(DARK_RED.r, DARK_RED.g, DARK_RED.b, alpha)


func _active_edge_color(tail_index: int, alpha: float) -> Color:
	if tail_index >= 8:
		return Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, alpha)
	if tail_index >= 5:
		return Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, alpha)
	if tail_index >= 2:
		return Color(1.0, 0.38, 0.66, alpha)
	return Color(0.88, 0.20, 0.36, alpha)


func _draw_threshold_marker(center: Vector2, max_length: float, tail_index: int, color: Color) -> void:
	if tail_index >= maximum_value:
		return
	var angle := _tail_angle(tail_index)
	var marker_point := center + Vector2(cos(angle), sin(angle)) * max_length * 1.05
	var active := current_value > tail_index
	draw_circle(marker_point, 3.0, Color(color.r, color.g, color.b, color.a * (0.94 if active else 0.30)))
	draw_arc(marker_point, 5.0, 0.0, TAU, 18, Color(color.r, color.g, color.b, color.a * (0.62 if active else 0.20)), 1.2, true)


func _draw_center_eye(center: Vector2, radius: float) -> void:
	var stage_color := _active_edge_color(maxi(current_value - 1, 0), 0.92)
	var eye_height := radius * 0.38
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for point_index in range(19):
		var t := float(point_index) / 18.0
		var x := lerpf(-radius, radius, t)
		var arch := sin(t * PI) * eye_height
		upper.append(center + Vector2(x, -arch))
		lower.append(center + Vector2(x, arch))
	var polygon := PackedVector2Array()
	for point in upper:
		polygon.append(point)
	for point_index in range(lower.size() - 1, -1, -1):
		polygon.append(lower[point_index])
	draw_colored_polygon(polygon, Color(0.055, 0.018, 0.06, 0.96))
	draw_polyline(upper, Color(stage_color.r, stage_color.g, stage_color.b, 0.34), 5.0, true)
	draw_polyline(lower, Color(stage_color.r, stage_color.g, stage_color.b, 0.34), 5.0, true)
	draw_polyline(upper, stage_color, 1.5, true)
	draw_polyline(lower, stage_color, 1.5, true)


func _draw_value(center: Vector2, value: int) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var value_text := str(value)
	var font_size := maxi(int(size.y * 0.25), 17)
	var text_size := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var text_origin := center - text_size * 0.5
	text_origin.y += text_size.y * 0.78
	draw_string(font, text_origin + Vector2(1.0, 1.0), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.0, 0.0, 0.0, 0.90))
	draw_string(font, text_origin, value_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.98, 0.96, 1.0, 0.98))


func _draw_tail(
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
		var stroke_width := maxf(width * 2.0 * pow(sin(t * PI), 0.60), 1.0)
		draw_line(centerline[point_index], centerline[point_index + 1], edge, stroke_width + 1.8, true)
		draw_line(centerline[point_index], centerline[point_index + 1], fill, stroke_width, true)


func _tail_centerline(base: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := direction.orthogonal()
	var centers := PackedVector2Array()
	for point_index in range(11):
		var t := float(point_index) / 10.0
		var bend := sin(t * PI) * width * 0.72 + t * t * width * 0.22
		centers.append(base + direction * length * t + tangent * bend)
	return centers


func _crossed_threshold(old_value: int, new_value: int) -> bool:
	for threshold in [3, 6, 9]:
		if old_value < threshold and new_value >= threshold:
			return true
	return false
