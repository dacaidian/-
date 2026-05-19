extends Control
class_name CardStatusOverlay

# CardStatusOverlay draws persistent visual markers for statuses attached to a board card.
# It is purely presentational: CardState remains the single source of truth.

var state: CardState
var divine_shield_color := Color(1.0, 0.84, 0.24, 0.26)
var divine_shield_edge_color := Color(1.0, 0.92, 0.48, 0.82)
var divine_shield_glow_color := Color(1.0, 0.78, 0.18, 0.34)
var arcane_aura_color := Color(0.45, 0.35, 1.0, 0.18)
var arcane_aura_edge_color := Color(0.72, 0.66, 1.0, 0.72)
var arcane_aura_glow_color := Color(0.40, 0.72, 1.0, 0.28)


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
	return should_show_divine_shield() or should_show_arcane_aura()


func should_show_divine_shield() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_DIVINE_SHIELD)


func should_show_arcane_aura() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ARCANE_AURA)


func _draw() -> void:
	if should_show_arcane_aura():
		draw_arcane_aura()
	if should_show_divine_shield():
		draw_divine_shield()


func draw_arcane_aura() -> void:
	var aura_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.04)
	var center := aura_rect.get_center()
	var radius := minf(aura_rect.size.x, aura_rect.size.y) * 0.44
	var status := state.get_status(CardStatus.STATUS_ARCANE_AURA) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)

	for index in range(ring_count):
		var ring_radius := radius + float(index) * 5.0
		var alpha := arcane_aura_edge_color.a * (1.0 - float(index) * 0.13)
		draw_arc(center, ring_radius, 0.0, TAU, 96, Color(arcane_aura_edge_color.r, arcane_aura_edge_color.g, arcane_aura_edge_color.b, alpha), 2.4, true)

	for index in range(8):
		var angle := TAU * float(index) / 8.0 + 0.18
		var from_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.72
		var to_point := center + Vector2(cos(angle), sin(angle)) * radius * 1.08
		draw_line(from_point, to_point, arcane_aura_glow_color, 2.0)

	draw_circle(center, radius * 0.74, arcane_aura_color)


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
