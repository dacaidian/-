extends Control
class_name CardStatusOverlay

# CardStatusOverlay draws persistent visual markers for statuses attached to a board card.
# It is purely presentational: CardState remains the single source of truth.

var state: CardState
var divine_shield_color := Color(1.0, 0.84, 0.24, 0.26)
var divine_shield_edge_color := Color(1.0, 0.92, 0.48, 0.82)
var divine_shield_glow_color := Color(1.0, 0.78, 0.18, 0.34)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(new_state: CardState) -> void:
	state = new_state
	refresh()


func refresh() -> void:
	visible = has_visible_status()
	if visible:
		queue_redraw()


func has_visible_status() -> bool:
	return should_show_divine_shield()


func should_show_divine_shield() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_DIVINE_SHIELD)


func _draw() -> void:
	if should_show_divine_shield():
		draw_divine_shield()


func draw_divine_shield() -> void:
	var shield_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.07)
	var points := PackedVector2Array([
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.50, shield_rect.position.y + shield_rect.size.y * 0.04),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.88, shield_rect.position.y + shield_rect.size.y * 0.17),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.82, shield_rect.position.y + shield_rect.size.y * 0.66),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.50, shield_rect.position.y + shield_rect.size.y * 0.94),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.18, shield_rect.position.y + shield_rect.size.y * 0.66),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.12, shield_rect.position.y + shield_rect.size.y * 0.17)
	])

	draw_shield_glow(points, 6, 7.0, divine_shield_glow_color)
	draw_colored_polygon(points, divine_shield_color)
	draw_polyline(points, divine_shield_edge_color, 4.0, true)
	draw_polyline(PackedVector2Array([points[5], points[0], points[1]]), Color(1.0, 0.98, 0.70, 0.95), 6.0, true)

	var center := shield_rect.get_center()
	var ray_color := Color(1.0, 0.95, 0.56, 0.22)
	draw_line(Vector2(center.x, shield_rect.position.y + shield_rect.size.y * 0.18), Vector2(center.x, shield_rect.position.y + shield_rect.size.y * 0.78), ray_color, 2.0)
	draw_line(Vector2(shield_rect.position.x + shield_rect.size.x * 0.28, center.y), Vector2(shield_rect.position.x + shield_rect.size.x * 0.72, center.y), ray_color, 2.0)


func draw_shield_glow(points: PackedVector2Array, steps: int, spacing: float, color: Color) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())

	for step in range(steps, 0, -1):
		var grown := PackedVector2Array()
		var grow_amount := float(step) * spacing
		for point in points:
			grown.append(point + (point - center).normalized() * grow_amount)
		var alpha := color.a * pow(1.0 - float(step) / float(steps + 1), 1.3)
		draw_polyline(grown, Color(color.r, color.g, color.b, alpha), 5.0, true)
