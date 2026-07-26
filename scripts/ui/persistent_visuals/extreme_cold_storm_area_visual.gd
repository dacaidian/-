extends PersistentBoardAreaVisual
class_name ExtremeColdStormAreaVisual

const VISUAL_KEY := "extreme_cold_storm"
const STORM_FILL := Color(0.08, 0.30, 0.62, 0.105)
const STORM_MIST := Color(0.30, 0.72, 1.0, 0.085)
const STORM_OUTER := Color(0.48, 0.86, 1.0, 0.38)
const STORM_INNER := Color(0.76, 0.96, 1.0, 0.54)
const STORM_CORE := Color(0.92, 1.0, 1.0, 0.72)


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return

	var center := size * 0.5
	var radius_x := size.x * 0.48
	var radius_y := size.y * 0.48
	var vertical_scale := radius_y / maxf(radius_x, 1.0)
	var clockwise_phase := animation_time * 0.62
	var counter_phase := -animation_time * 0.44

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

	for index in range(12):
		var angle := clockwise_phase + TAU * float(index) / 12.0
		var wave := 0.82 + 0.10 * sin(animation_time * 1.7 + float(index))
		var mist_center := center + Vector2(
			cos(angle) * radius_x * wave,
			sin(angle) * radius_y * wave
		)
		var mist_radius := minf(size.x, size.y) * (0.075 + float(index % 3) * 0.012)
		draw_circle(mist_center, mist_radius, STORM_MIST)

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
