extends Control

# Draws the wooden frame around the cropped board portrait.
# It is a visual overlay only; Card remains responsible for state and interaction.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var frame_rect := Rect2(Vector2.ZERO, size)
	var min_side := minf(size.x, size.y)
	var frame_width := maxf(min_side * 0.085, 5.0)
	var inner_rect := frame_rect.grow(-frame_width)
	var outer_color := Color(0.23, 0.12, 0.045, 0.94)
	var mid_color := Color(0.47, 0.26, 0.095, 0.92)
	var highlight_color := Color(0.82, 0.55, 0.25, 0.45)
	var shadow_color := Color(0.07, 0.035, 0.015, 0.70)

	draw_rect(frame_rect, outer_color, false, frame_width)
	draw_rect(frame_rect.grow(-frame_width * 0.28), mid_color, false, frame_width * 0.46)
	draw_rect(frame_rect.grow(-frame_width * 0.72), shadow_color, false, frame_width * 0.22)
	draw_rect(inner_rect, highlight_color, false, 1.4)

	draw_wood_grain(frame_rect, frame_width)


func draw_wood_grain(frame_rect: Rect2, frame_width: float) -> void:
	var grain_color := Color(0.93, 0.70, 0.36, 0.22)
	var dark_grain_color := Color(0.10, 0.045, 0.018, 0.34)
	var inset := frame_width * 0.34
	var line_width := 1.1

	for index in range(3):
		var offset := inset + float(index) * frame_width * 0.24
		draw_line(
			Vector2(frame_rect.position.x + offset, frame_rect.position.y + frame_width * 0.22),
			Vector2(frame_rect.position.x + offset + frame_rect.size.x * 0.08, frame_rect.position.y + frame_rect.size.y - frame_width * 0.22),
			grain_color if index % 2 == 0 else dark_grain_color,
			line_width
		)
		draw_line(
			Vector2(frame_rect.position.x + frame_rect.size.x - offset, frame_rect.position.y + frame_width * 0.22),
			Vector2(frame_rect.position.x + frame_rect.size.x - offset - frame_rect.size.x * 0.08, frame_rect.position.y + frame_rect.size.y - frame_width * 0.22),
			dark_grain_color if index % 2 == 0 else grain_color,
			line_width
		)

	for index in range(4):
		var y := frame_rect.position.y + frame_width * (0.30 + float(index) * 0.17)
		draw_line(
			Vector2(frame_rect.position.x + frame_width * 0.24, y),
			Vector2(frame_rect.position.x + frame_rect.size.x - frame_width * 0.24, y + sin(float(index)) * 1.8),
			grain_color if index % 2 == 0 else dark_grain_color,
			line_width
		)
