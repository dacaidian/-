extends Control
class_name HudSymbolIcon

# Lightweight vector symbols used by the battle HUD. Keeping these code-native
# avoids coupling core HUD readability to faction-specific image assets.

var symbol_id := "status"
var icon_color := Color.WHITE
var secondary_color := Color(0.08, 0.09, 0.10, 0.95)


func setup(
	value: String,
	color: Color,
	icon_size := Vector2(20.0, 20.0),
	hint := ""
) -> HudSymbolIcon:
	symbol_id = value
	icon_color = color
	custom_minimum_size = icon_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = hint
	queue_redraw()
	return self


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side <= 0.0:
		return

	var origin := (size - Vector2(side, side)) * 0.5
	match symbol_id:
		"mana":
			draw_mana(origin, side)
		"flip":
			draw_flip(origin, side)
		"score":
			draw_score(origin, side)
		"turn":
			draw_turn(origin, side)
		"equipment", "weapon":
			draw_weapon(origin, side)
		"suit":
			draw_shield(origin, side)
		"skill":
			draw_skill(origin, side)
		"time":
			draw_time(origin, side)
		"tail":
			draw_tail(origin, side)
		_:
			draw_status(origin, side)


func point(origin: Vector2, side: float, x: float, y: float) -> Vector2:
	return origin + Vector2(x, y) * side


func draw_mana(origin: Vector2, side: float) -> void:
	var outer := PackedVector2Array([
		point(origin, side, 0.50, 0.04),
		point(origin, side, 0.88, 0.43),
		point(origin, side, 0.66, 0.94),
		point(origin, side, 0.34, 0.94),
		point(origin, side, 0.12, 0.43),
	])
	draw_colored_polygon(outer, icon_color)
	var inner := PackedVector2Array([
		point(origin, side, 0.50, 0.24),
		point(origin, side, 0.70, 0.46),
		point(origin, side, 0.59, 0.73),
		point(origin, side, 0.41, 0.73),
		point(origin, side, 0.30, 0.46),
	])
	draw_colored_polygon(inner, secondary_color)


func draw_flip(origin: Vector2, side: float) -> void:
	var stroke := maxf(1.5, side * 0.08)
	draw_rect(
		Rect2(point(origin, side, 0.12, 0.20), Vector2(side * 0.55, side * 0.68)),
		icon_color,
		false,
		stroke
	)
	draw_rect(
		Rect2(point(origin, side, 0.33, 0.08), Vector2(side * 0.55, side * 0.68)),
		icon_color,
		false,
		stroke
	)
	draw_line(
		point(origin, side, 0.45, 0.25),
		point(origin, side, 0.75, 0.25),
		icon_color,
		stroke,
		true
	)


func draw_score(origin: Vector2, side: float) -> void:
	var center := point(origin, side, 0.50, 0.50)
	draw_circle(center, side * 0.43, icon_color)
	draw_circle(center, side * 0.31, secondary_color)
	var star := PackedVector2Array()
	for index in range(10):
		var radius := side * (0.25 if index % 2 == 0 else 0.11)
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		star.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(star, icon_color)


func draw_turn(origin: Vector2, side: float) -> void:
	var center := point(origin, side, 0.50, 0.52)
	var stroke := maxf(1.5, side * 0.08)
	draw_arc(center, side * 0.38, -PI * 0.25, PI * 1.55, 28, icon_color, stroke, true)
	draw_line(
		point(origin, side, 0.22, 0.20),
		point(origin, side, 0.16, 0.43),
		icon_color,
		stroke,
		true
	)
	draw_line(
		point(origin, side, 0.22, 0.20),
		point(origin, side, 0.43, 0.27),
		icon_color,
		stroke,
		true
	)
	draw_line(center, point(origin, side, 0.50, 0.27), icon_color, stroke, true)
	draw_line(center, point(origin, side, 0.70, 0.62), icon_color, stroke, true)


func draw_weapon(origin: Vector2, side: float) -> void:
	var stroke := maxf(1.8, side * 0.09)
	draw_line(
		point(origin, side, 0.20, 0.82),
		point(origin, side, 0.76, 0.18),
		icon_color,
		stroke,
		true
	)
	draw_line(
		point(origin, side, 0.62, 0.15),
		point(origin, side, 0.82, 0.08),
		icon_color,
		stroke,
		true
	)
	draw_line(
		point(origin, side, 0.82, 0.08),
		point(origin, side, 0.78, 0.31),
		icon_color,
		stroke,
		true
	)
	draw_line(
		point(origin, side, 0.16, 0.67),
		point(origin, side, 0.34, 0.85),
		icon_color,
		stroke,
		true
	)
	draw_circle(point(origin, side, 0.16, 0.86), side * 0.08, icon_color)


func draw_shield(origin: Vector2, side: float) -> void:
	var shield := PackedVector2Array([
		point(origin, side, 0.18, 0.15),
		point(origin, side, 0.82, 0.15),
		point(origin, side, 0.78, 0.61),
		point(origin, side, 0.50, 0.93),
		point(origin, side, 0.22, 0.61),
	])
	draw_colored_polygon(shield, icon_color)
	var inner := PackedVector2Array([
		point(origin, side, 0.34, 0.30),
		point(origin, side, 0.66, 0.30),
		point(origin, side, 0.63, 0.56),
		point(origin, side, 0.50, 0.72),
		point(origin, side, 0.37, 0.56),
	])
	draw_colored_polygon(inner, secondary_color)


func draw_skill(origin: Vector2, side: float) -> void:
	var center := point(origin, side, 0.50, 0.50)
	var rays := [
		Vector2(0.0, -0.44),
		Vector2(0.30, -0.30),
		Vector2(0.44, 0.0),
		Vector2(0.30, 0.30),
		Vector2(0.0, 0.44),
		Vector2(-0.30, 0.30),
		Vector2(-0.44, 0.0),
		Vector2(-0.30, -0.30),
	]
	for ray in rays:
		draw_line(
			center + ray * side * 0.48,
			center + ray * side,
			icon_color,
			maxf(1.3, side * 0.06),
			true
		)
	draw_circle(center, side * 0.18, icon_color)
	draw_circle(center, side * 0.08, secondary_color)


func draw_time(origin: Vector2, side: float) -> void:
	var center := point(origin, side, 0.50, 0.50)
	draw_circle(center, side * 0.42, icon_color)
	draw_circle(point(origin, side, 0.65, 0.38), side * 0.38, secondary_color)
	draw_circle(point(origin, side, 0.24, 0.22), side * 0.055, icon_color)


func draw_tail(origin: Vector2, side: float) -> void:
	var stroke := maxf(1.5, side * 0.07)
	for index in range(3):
		var center := point(origin, side, 0.42 + float(index) * 0.09, 0.62)
		draw_arc(
			center,
			side * (0.22 + float(index) * 0.06),
			PI * 0.82,
			PI * 1.82,
			20,
			icon_color,
			stroke,
			true
		)
	draw_circle(point(origin, side, 0.30, 0.72), side * 0.08, icon_color)


func draw_status(origin: Vector2, side: float) -> void:
	var center := point(origin, side, 0.50, 0.50)
	var stroke := maxf(1.5, side * 0.07)
	draw_arc(center, side * 0.38, 0.0, TAU, 28, icon_color, stroke, true)
	for angle in [-PI * 0.5, PI / 6.0, PI * 5.0 / 6.0]:
		var node_point := center + Vector2(cos(angle), sin(angle)) * side * 0.27
		draw_line(center, node_point, icon_color, stroke, true)
		draw_circle(node_point, side * 0.08, icon_color)
