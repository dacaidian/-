extends PersistentBoardAreaVisual
class_name ExtremeColdStormAreaVisual

const VISUAL_KEY := "extreme_cold_storm"
const STORM_FILL := Color(0.08, 0.30, 0.62, 0.105)
const STORM_MIST := Color(0.30, 0.72, 1.0, 0.085)
const STORM_OUTER := Color(0.48, 0.86, 1.0, 0.38)
const STORM_INNER := Color(0.76, 0.96, 1.0, 0.54)
const STORM_CORE := Color(0.92, 1.0, 1.0, 0.72)
const FROST_GRID := Color(0.50, 0.84, 1.0, 0.18)
const RUNE_SILVER := Color(0.82, 0.94, 1.0, 0.62)


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return

	var center := size * 0.5
	var radius_x := size.x * 0.48
	var radius_y := size.y * 0.48
	var vertical_scale := radius_y / maxf(radius_x, 1.0)
	var clockwise_phase := animation_time * 0.62
	var counter_phase := -animation_time * 0.44
	var pulse := 0.5 + 0.5 * sin(animation_time * 1.85)

	var boundary_rect := Rect2(Vector2.ZERO, size).grow(-maxf(minf(size.x, size.y) * 0.025, 3.0))
	draw_rect(
		boundary_rect,
		Color(STORM_OUTER.r, STORM_OUTER.g, STORM_OUTER.b, 0.20 + pulse * 0.10),
		false,
		2.2,
		true
	)
	draw_rect(
		boundary_rect.grow(-maxf(minf(size.x, size.y) * 0.018, 2.0)),
		FROST_GRID,
		false,
		1.2,
		true
	)

	var corner_length := minf(size.x, size.y) * 0.075
	for corner_index in range(4):
		var corner := Vector2(
			boundary_rect.end.x if corner_index % 2 == 1 else boundary_rect.position.x,
			boundary_rect.end.y if corner_index >= 2 else boundary_rect.position.y
		)
		var horizontal_direction := -1.0 if corner_index % 2 == 1 else 1.0
		var vertical_direction := -1.0 if corner_index >= 2 else 1.0
		draw_line(corner, corner + Vector2(horizontal_direction * corner_length, 0.0), RUNE_SILVER, 2.4, true)
		draw_line(corner, corner + Vector2(0.0, vertical_direction * corner_length), RUNE_SILVER, 2.4, true)

	draw_set_transform(center, 0.0, Vector2(1.0, vertical_scale))
	draw_circle(Vector2.ZERO, radius_x, STORM_FILL)
	draw_arc(
		Vector2.ZERO,
		radius_x * 0.94,
		clockwise_phase,
		clockwise_phase + PI * 1.52,
		96,
		STORM_OUTER,
		4.2,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius_x * 0.76,
		counter_phase + PI * 0.24,
		counter_phase + PI * 1.68,
		84,
		STORM_INNER,
		3.1,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius_x * 0.54,
		clockwise_phase * 1.35 + PI * 0.66,
		clockwise_phase * 1.35 + PI * 2.02,
		72,
		Color(STORM_CORE.r, STORM_CORE.g, STORM_CORE.b, 0.42),
		2.3,
		true
	)
	draw_circle(Vector2.ZERO, radius_x * 0.15, Color(0.78, 0.96, 1.0, 0.13))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for crack_index in range(8):
		var crack_angle := TAU * float(crack_index) / 8.0 + PI * 0.125
		var crack_direction := Vector2(cos(crack_angle) * radius_x, sin(crack_angle) * radius_y).normalized()
		var crack_start := center + crack_direction * minf(radius_x, radius_y) * 0.18
		var crack_mid := center + crack_direction * minf(radius_x, radius_y) * (0.42 + 0.03 * float(crack_index % 2))
		var tangent := crack_direction.orthogonal()
		var crack_end := center + crack_direction * minf(radius_x, radius_y) * 0.67 + tangent * (4.0 if crack_index % 2 == 0 else -4.0)
		var crack_color := Color(STORM_INNER.r, STORM_INNER.g, STORM_INNER.b, 0.18 + pulse * 0.10)
		draw_line(crack_start, crack_mid, crack_color, 1.2, true)
		draw_line(crack_mid, crack_end, crack_color, 1.0, true)
		draw_line(crack_mid, crack_mid + tangent * (7.0 if crack_index % 2 == 0 else -7.0), crack_color, 0.9, true)

	for index in range(12):
		var angle := clockwise_phase + TAU * float(index) / 12.0
		var wave := 0.82 + 0.10 * sin(animation_time * 1.7 + float(index))
		var mist_center := center + Vector2(
			cos(angle) * radius_x * wave,
			sin(angle) * radius_y * wave
		)
		var mist_radius := minf(size.x, size.y) * (0.075 + float(index % 3) * 0.012)
		draw_circle(mist_center, mist_radius, STORM_MIST)

		var rune_radial := Vector2(cos(angle), sin(angle))
		var rune_tangent := rune_radial.orthogonal()
		var rune_center := center + Vector2(rune_radial.x * radius_x * 0.91, rune_radial.y * radius_y * 0.91)
		var rune_length := 4.0 + float(index % 2) * 1.5
		draw_line(rune_center - rune_tangent * rune_length, rune_center + rune_tangent * rune_length, RUNE_SILVER, 1.4, true)
		draw_line(rune_center, rune_center - rune_radial * 5.0, RUNE_SILVER, 1.2, true)

	for index in range(18):
		var angle := counter_phase * 1.28 + TAU * float(index) / 18.0
		var orbit_ratio := 0.40 + float(index % 4) * 0.14
		var shard_center := center + Vector2(
			cos(angle) * radius_x * orbit_ratio,
			sin(angle) * radius_y * orbit_ratio
		)
		var tangent := Vector2(-sin(angle), cos(angle)).normalized()
		var shard_length := 4.5 + float(index % 3) * 2.0
		draw_line(
			shard_center - tangent * shard_length,
			shard_center + tangent * shard_length,
			STORM_CORE,
			1.6,
			true
		)
		if index % 3 == 0:
			var radial := Vector2(cos(angle), sin(angle)).normalized()
			draw_line(
				shard_center - radial * 3.2,
				shard_center + radial * 3.2,
				Color(STORM_CORE.r, STORM_CORE.g, STORM_CORE.b, 0.56),
				1.2,
				true
			)
