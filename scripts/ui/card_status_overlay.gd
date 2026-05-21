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
var freeze_ice_color := Color(0.30, 0.68, 0.96, 0.22)
var freeze_ice_edge_color := Color(0.44, 0.82, 1.0, 0.72)
var freeze_ice_glow_color := Color(0.24, 0.60, 0.96, 0.20)
var encourage_gu_color := Color(0.42, 1.0, 0.36, 0.16)
var encourage_gu_edge_color := Color(0.72, 1.0, 0.48, 0.72)
var encourage_gu_venom_color := Color(0.20, 0.95, 0.38, 0.58)
var encourage_gu_insect_color := Color(0.96, 1.0, 0.42, 0.82)


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
	return should_show_divine_shield() or should_show_arcane_aura() or should_show_freeze() or should_show_encourage_gu()


func should_show_divine_shield() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_DIVINE_SHIELD)


func should_show_arcane_aura() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ARCANE_AURA)


func should_show_freeze() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_FREEZE)


func should_show_encourage_gu() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ENCOURAGE_GU)


func _draw() -> void:
	if should_show_arcane_aura():
		draw_arcane_aura()
	if should_show_encourage_gu():
		draw_encourage_gu_overlay()
	if should_show_divine_shield():
		draw_divine_shield()
	if should_show_freeze():
		draw_freeze_overlay()


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


func draw_freeze_overlay() -> void:
	var freeze_rect := Rect2(Vector2.ZERO, size)
	var border_width := size.x * 0.06

	# Ice-blue border overlay
	var border_color := Color(freeze_ice_edge_color.r, freeze_ice_edge_color.g, freeze_ice_edge_color.b, freeze_ice_edge_color.a)
	var inner_border_width := border_width * 0.6
	draw_rect(freeze_rect, freeze_ice_color, true)
	draw_rect(freeze_rect, border_color, false, border_width)
	draw_rect(freeze_rect.grow(-border_width), Color(border_color.r, border_color.g, border_color.b, border_color.a * 0.45), false, inner_border_width)

	# Ice crystal pattern in the center
	var center := freeze_rect.get_center()
	var crystal_size := minf(freeze_rect.size.x, freeze_rect.size.y) * 0.19
	var crystal_color := Color(border_color.r, border_color.g, border_color.b, border_color.a * 0.62)
	var crystal_glow := Color(freeze_ice_glow_color.r, freeze_ice_glow_color.g, freeze_ice_glow_color.b, freeze_ice_glow_color.a * 0.40)

	# Draw a snowflake-like symbol
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var dir := Vector2(cos(angle), sin(angle))
		var inner_point := center + dir * crystal_size * 0.25
		var outer_point := center + dir * crystal_size
		var branch_angle := angle + PI * 0.32
		var branch_dir := Vector2(cos(branch_angle), sin(branch_angle))
		var branch_mid := center + dir * crystal_size * 0.55
		draw_line(center, outer_point, crystal_color, 3.0)
		draw_line(branch_mid, branch_mid + branch_dir * crystal_size * 0.32, crystal_color, 2.2)
		var opposite_branch_dir := Vector2(cos(branch_angle - PI * 0.64), sin(branch_angle - PI * 0.64))
		draw_line(branch_mid, branch_mid + opposite_branch_dir * crystal_size * 0.32, crystal_color, 2.2)

	draw_circle(center, crystal_size * 0.12, crystal_glow)


func draw_encourage_gu_overlay() -> void:
	var gu_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.05)
	var center := gu_rect.get_center()
	var status := state.get_status(CardStatus.STATUS_ENCOURAGE_GU) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var pulse_count: int = mini(maxi(stack_count, 1), 5)
	var edge_width := maxf(size.x * 0.025, 2.0)

	for index in range(pulse_count):
		var grow := float(index) * 4.0
		var pulse_alpha := encourage_gu_edge_color.a * (1.0 - float(index) * 0.12)
		draw_rect(gu_rect.grow(grow), Color(encourage_gu_edge_color.r, encourage_gu_edge_color.g, encourage_gu_edge_color.b, pulse_alpha), false, edge_width, true)

	draw_rect(gu_rect, encourage_gu_color, true)
	draw_gu_veins(center, gu_rect)
	draw_gu_insects(center, gu_rect, pulse_count)


func draw_gu_veins(center: Vector2, gu_rect: Rect2) -> void:
	var vein_count := 7
	var vein_length := minf(gu_rect.size.x, gu_rect.size.y) * 0.35
	for index in range(vein_count):
		var angle := -PI * 0.78 + float(index) * PI * 1.56 / float(vein_count - 1)
		var dir := Vector2(cos(angle), sin(angle))
		var start := center + dir * vein_length * 0.18
		var mid := center + dir * vein_length * 0.55 + Vector2(-dir.y, dir.x) * sin(float(index) * 1.7) * 7.0
		var end := center + dir * vein_length
		draw_line(start, mid, encourage_gu_venom_color, 2.2)
		draw_line(mid, end, Color(encourage_gu_venom_color.r, encourage_gu_venom_color.g, encourage_gu_venom_color.b, encourage_gu_venom_color.a * 0.72), 1.7)


func draw_gu_insects(center: Vector2, gu_rect: Rect2, count: int) -> void:
	var orbit_radius := minf(gu_rect.size.x, gu_rect.size.y) * 0.39
	var insect_count := mini(count + 2, 7)
	for index in range(insect_count):
		var angle := TAU * float(index) / float(insect_count) + 0.34
		var pos := center + Vector2(cos(angle), sin(angle)) * orbit_radius
		var wing_dir := Vector2(-sin(angle), cos(angle))
		draw_circle(pos, 2.4, encourage_gu_insect_color)
		draw_line(pos - wing_dir * 3.0, pos + wing_dir * 3.0, Color(encourage_gu_insect_color.r, encourage_gu_insect_color.g, encourage_gu_insect_color.b, 0.42), 1.4)
