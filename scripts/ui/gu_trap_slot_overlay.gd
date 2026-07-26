extends Control
class_name GuTrapSlotOverlay

# Owner-visible board-slot marker for a hidden gu trap. It belongs to the
# slot container, never to the card currently occupying that slot.

var visual_key := ""
var animation_time := 0.0
var redraw_accumulator := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(visual_key != "")


func configure(key: String) -> void:
	visual_key = key
	visible = visual_key != ""
	set_process(visible)
	queue_redraw()


func apply_card_size(next_size: Vector2) -> void:
	custom_minimum_size = next_size
	size = next_size
	queue_redraw()


func _process(delta: float) -> void:
	animation_time = fmod(animation_time + delta, 1000.0)
	redraw_accumulator += delta
	if redraw_accumulator >= 1.0 / 20.0:
		redraw_accumulator = 0.0
		queue_redraw()


func _draw() -> void:
	if visual_key != "gu_lure_waiting":
		return

	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.47
	var phase := animation_time * 0.46
	var breath := 0.5 + 0.5 * sin(phase * 1.4)

	var points := PackedVector2Array()
	for point_index in range(49):
		var angle := TAU * float(point_index) / 48.0 + phase * 0.04
		var wobble := 1.0 + sin(angle * 5.0 + phase) * 0.035
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * wobble)
	draw_polyline(points, Color(0.22, 0.52, 0.26, 0.24 + breath * 0.07), 2.2, true)

	for vein_index in range(8):
		var angle := TAU * float(vein_index) / 8.0 + phase * 0.05
		var direction := Vector2(cos(angle), sin(angle))
		var tangent := Vector2(-direction.y, direction.x)
		var outer := center + direction * radius * 0.92
		var middle := center + direction * radius * 0.58 + tangent * sin(phase + float(vein_index)) * radius * 0.06
		var inner := center + direction * radius * 0.22
		draw_polyline(
			PackedVector2Array([outer, middle, inner]),
			Color(0.18, 0.46, 0.24, 0.18 + breath * 0.06),
			1.5,
			true
		)

	for eye_index in range(3):
		var angle := phase * 0.10 + TAU * float(eye_index) / 3.0
		var eye_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.48
		draw_circle(eye_center, maxf(size.x * 0.015, 1.8), Color(0.06, 0.08, 0.03, 0.52))
		draw_circle(eye_center, maxf(size.x * 0.006, 0.8), Color(0.62, 0.86, 0.18, 0.42 + breath * 0.12))
