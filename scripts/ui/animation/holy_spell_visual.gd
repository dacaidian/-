extends Control

# Procedural canvas used by Silver Hand spell animations. It intentionally owns
# no rule state; the provider only drives progress and opacity.

var animation_key := ""
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func configure(key: String) -> void:
	animation_key = key
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	match animation_key:
		"divine_shield":
			_draw_divine_shield()
		"holy_heal":
			_draw_holy_heal()
		"power_word_shield":
			_draw_power_word_shield()
		"baptism":
			_draw_baptism()
		"inner_fire":
			_draw_inner_fire()
		"resurrection":
			_draw_resurrection()


func _draw_divine_shield() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var arrival := _ease_out(progress, 0.0, 0.34)
	var pulse := 0.5 + 0.5 * sin(progress * TAU * 2.4)
	var shield_scale := lerpf(0.32, 1.0 + pulse * 0.025, arrival)
	var points := _shield_points(center, radius * shield_scale)

	draw_colored_polygon(points, Color(1.0, 0.78, 0.16, 0.13 + arrival * 0.10))
	_draw_polyline_glow(points, Color(1.0, 0.84, 0.22, 0.84), 3.0, true)

	var inner_points := _shield_points(center, radius * shield_scale * 0.80)
	draw_polyline(inner_points, Color(1.0, 0.96, 0.58, 0.54), 1.7, true)
	var flow_phase := progress * TAU * 2.0
	for strand_index in range(3):
		var strand := PackedVector2Array()
		for step in range(13):
			var t := float(step) / 12.0
			var y := center.y - radius * 0.58 + t * radius * 1.18
			var width_at_y := radius * (0.46 - absf(t - 0.5) * 0.42)
			var x := center.x + sin(t * TAU * 1.35 + flow_phase + float(strand_index) * 2.1) * width_at_y
			strand.append(Vector2(x, y))
		draw_polyline(
			strand,
			Color(1.0, 0.92, 0.34, 0.20 + 0.08 * pulse),
			2.0,
			true
		)
	_draw_orbiting_motes(center, radius * 0.93, 10, flow_phase, Color(1.0, 0.94, 0.54, 0.90))


func _draw_holy_heal() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.31
	var arrival := _ease_out(progress, 0.0, 0.24)
	var release := _ease_out(progress, 0.18, 1.0)
	var phase := progress * TAU * 2.2

	for ribbon_index in range(5):
		var ribbon := PackedVector2Array()
		for step in range(18):
			var t := float(step) / 17.0
			var x_offset := (float(ribbon_index) - 2.0) * radius * 0.18
			var x := center.x + x_offset + sin(t * TAU * 1.2 + phase + float(ribbon_index)) * radius * 0.10
			var y := center.y + radius * 0.82 - t * radius * (1.48 + release * 0.32)
			ribbon.append(Vector2(x, y))
		draw_polyline(
			ribbon,
			Color(0.30, 1.0, 0.48, 0.18 + arrival * 0.18),
			2.0 + float(ribbon_index % 2),
			true
		)

	var cross_scale := lerpf(0.36, 1.0, arrival)
	var cross_half := radius * 0.34 * cross_scale
	_draw_glow_line(
		Vector2(center.x - cross_half, center.y),
		Vector2(center.x + cross_half, center.y),
		Color(0.72, 1.0, 0.62, 0.92),
		4.0
	)
	_draw_glow_line(
		Vector2(center.x, center.y - cross_half),
		Vector2(center.x, center.y + cross_half),
		Color(0.72, 1.0, 0.62, 0.92),
		4.0
	)
	for ring_index in range(3):
		var ring_radius := radius * (0.32 + release * (0.42 + float(ring_index) * 0.16))
		draw_arc(
			center,
			ring_radius,
			0.0,
			TAU,
			48,
			Color(0.42, 1.0, 0.60, 0.34 - float(ring_index) * 0.07),
			2.0,
			true
		)
	_draw_rising_motes(center, radius, 12, phase, Color(0.58, 1.0, 0.48, 0.92))


func _draw_power_word_shield() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var arrival := _ease_out(progress, 0.0, 0.30)
	var phase := progress * TAU * 1.8
	var diamond_radius := radius * lerpf(0.28, 0.86, arrival)
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -diamond_radius),
		center + Vector2(diamond_radius * 0.74, 0.0),
		center + Vector2(0.0, diamond_radius),
		center + Vector2(-diamond_radius * 0.74, 0.0),
		center + Vector2(0.0, -diamond_radius)
	])
	draw_colored_polygon(
		PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3]]),
		Color(1.0, 0.78, 0.20, 0.10)
	)
	_draw_polyline_glow(diamond, Color(1.0, 0.90, 0.36, 0.90), 3.0, false)

	var rune_color := Color(1.0, 0.97, 0.66, 0.88)
	for rune_index in range(4):
		var angle := phase + TAU * float(rune_index) / 4.0
		var rune_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.78
		var tangent := Vector2(-sin(angle), cos(angle))
		var radial := Vector2(cos(angle), sin(angle))
		var rune := PackedVector2Array([
			rune_center - tangent * radius * 0.10,
			rune_center + radial * radius * 0.08,
			rune_center + tangent * radius * 0.10
		])
		_draw_polyline_glow(rune, rune_color, 2.0, false)

	for chevron_index in range(3):
		var lift := fmod(progress * 1.8 + float(chevron_index) / 3.0, 1.0)
		var y := center.y + radius * 0.58 - lift * radius * 1.16
		var chevron := PackedVector2Array([
			Vector2(center.x - radius * 0.17, y + radius * 0.09),
			Vector2(center.x, y),
			Vector2(center.x + radius * 0.17, y + radius * 0.09)
		])
		draw_polyline(chevron, Color(1.0, 0.86, 0.30, 0.28 + (1.0 - lift) * 0.40), 2.4, true)
	_draw_orbiting_motes(center, radius, 8, -phase, Color(1.0, 0.94, 0.54, 0.90))


func _draw_baptism() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.29
	var arrival := _ease_out(progress, 0.0, 0.30)
	var impact := _ease_out(progress, 0.24, 0.70)
	var release := _ease_out(progress, 0.48, 1.0)
	var phase := progress * TAU * 2.0

	for beam_index in range(7):
		var x := center.x + (float(beam_index) - 3.0) * radius * 0.15
		var wave := sin(phase + float(beam_index) * 0.8) * radius * 0.04
		var beam_color := Color(1.0, 0.92, 0.46, 0.12 + arrival * 0.12)
		_draw_glow_line(
			Vector2(x + wave, center.y - radius * 1.35),
			Vector2(x - wave, center.y + radius * 0.10),
			beam_color,
			2.0 + float(beam_index % 2)
		)
	draw_circle(center, radius * (0.12 + impact * 0.16), Color(0.78, 1.0, 0.66, 0.40))
	draw_circle(center, radius * (0.05 + impact * 0.10), Color(1.0, 1.0, 0.84, 0.92))

	for ring_index in range(3):
		var ring_radius := radius * (0.22 + release * (0.68 + float(ring_index) * 0.18))
		draw_arc(
			center,
			ring_radius,
			0.0,
			TAU,
			56,
			Color(1.0, 0.82, 0.22, 0.64 - float(ring_index) * 0.13),
			3.0 - float(ring_index) * 0.5,
			true
		)
	for ray_index in range(16):
		var angle := TAU * float(ray_index) / 16.0
		var direction := Vector2(cos(angle), sin(angle))
		var ray_start := center + direction * radius * (0.20 + release * 0.26)
		var ray_end := center + direction * radius * (0.34 + release * 0.92)
		draw_line(ray_start, ray_end, Color(1.0, 0.88, 0.34, 0.52), 2.0, true)
	_draw_rising_motes(center, radius * 1.1, 14, phase, Color(0.66, 1.0, 0.54, 0.88))


func _draw_inner_fire() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var arrival := _ease_out(progress, 0.0, 0.30)
	var surge := _ease_out(progress, 0.30, 1.0)
	var phase := progress * TAU * 2.8
	var flame_center := center + Vector2(0.0, radius * 0.16 - surge * radius * 0.12)
	var flame_scale := lerpf(0.30, 1.0, arrival)
	var sway := sin(phase) * radius * 0.07

	var outer_flame := PackedVector2Array([
		flame_center + Vector2(-radius * 0.42, radius * 0.62) * flame_scale,
		flame_center + Vector2(-radius * 0.36, radius * 0.08) * flame_scale,
		flame_center + Vector2(-radius * 0.10 + sway, -radius * 0.34) * flame_scale,
		flame_center + Vector2(radius * 0.02 - sway * 0.35, -radius * 0.94) * flame_scale,
		flame_center + Vector2(radius * 0.22, -radius * 0.30) * flame_scale,
		flame_center + Vector2(radius * 0.38, radius * 0.02) * flame_scale,
		flame_center + Vector2(radius * 0.43, radius * 0.62) * flame_scale
	])
	draw_colored_polygon(outer_flame, Color(1.0, 0.48, 0.05, 0.48))
	_draw_polyline_glow(outer_flame, Color(1.0, 0.82, 0.18, 0.92), 3.0, false)

	var inner_flame := PackedVector2Array([
		flame_center + Vector2(-radius * 0.19, radius * 0.55),
		flame_center + Vector2(-radius * 0.14, radius * 0.08),
		flame_center + Vector2(radius * 0.04 + sway * 0.25, -radius * 0.48),
		flame_center + Vector2(radius * 0.19, radius * 0.06),
		flame_center + Vector2(radius * 0.20, radius * 0.55)
	])
	draw_colored_polygon(inner_flame, Color(1.0, 0.94, 0.50, 0.78))
	draw_polyline(inner_flame, Color(1.0, 1.0, 0.82, 0.96), 2.0, true)
	for spark_index in range(12):
		var spark_phase := fmod(progress * 2.2 + float(spark_index) / 12.0, 1.0)
		var angle := float(spark_index) * 2.399
		var start := flame_center + Vector2(cos(angle), 0.55) * radius * 0.45
		var spark := start + Vector2(sin(angle) * radius * 0.22, -spark_phase * radius * 1.45)
		draw_circle(spark, 1.8 + float(spark_index % 3), Color(1.0, 0.78, 0.18, 0.86 - spark_phase * 0.56))


func _draw_resurrection() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.27
	var descent := _ease_out(progress, 0.0, 0.42)
	var release := _ease_out(progress, 0.34, 1.0)
	var phase := progress * TAU * 1.8
	var naaru_center := Vector2(center.x, lerpf(-radius * 0.70, center.y - radius * 0.16, descent))

	for beam_index in range(9):
		var spread := (float(beam_index) - 4.0) * radius * 0.16
		var beam_end := center + Vector2(spread * (1.0 + release * 0.35), radius * 0.98)
		draw_line(
			naaru_center + Vector2(spread * 0.18, 0.0),
			beam_end,
			Color(1.0, 0.90, 0.42, 0.10 + descent * 0.12),
			2.0 + float(beam_index % 3),
			true
		)

	_draw_naaru(naaru_center, radius * (0.52 + descent * 0.48), phase)
	for ring_index in range(4):
		var ring_radius := radius * (0.22 + release * (0.72 + float(ring_index) * 0.17))
		draw_arc(
			center + Vector2(0.0, radius * 0.72),
			ring_radius,
			PI * 0.10,
			PI * 0.90,
			36,
			Color(1.0, 0.84, 0.30, 0.64 - float(ring_index) * 0.11),
			3.0,
			true
		)
	_draw_rising_motes(center + Vector2(0.0, radius * 0.72), radius * 1.35, 20, phase, Color(1.0, 0.92, 0.48, 0.94))


func _draw_naaru(center: Vector2, radius: float, phase: float) -> void:
	var core := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.42),
		center + Vector2(radius * 0.25, 0.0),
		center + Vector2(0.0, radius * 0.42),
		center + Vector2(-radius * 0.25, 0.0)
	])
	draw_colored_polygon(core, Color(1.0, 0.94, 0.58, 0.72))
	_draw_polyline_glow(
		PackedVector2Array([core[0], core[1], core[2], core[3], core[0]]),
		Color(1.0, 0.98, 0.78, 0.98),
		2.6,
		false
	)
	for arm_index in range(6):
		var angle := phase * 0.10 + TAU * float(arm_index) / 6.0
		var direction := Vector2(cos(angle), sin(angle))
		var tangent := Vector2(-direction.y, direction.x)
		var arm := PackedVector2Array([
			center + direction * radius * 0.24,
			center + direction * radius * 0.72 + tangent * radius * 0.12,
			center + direction * radius,
			center + direction * radius * 0.72 - tangent * radius * 0.12
		])
		_draw_polyline_glow(arm, Color(1.0, 0.82, 0.24, 0.88), 2.4, false)
		var gem_center := center + direction * radius
		draw_circle(gem_center, radius * 0.055, Color(1.0, 1.0, 0.86, 0.96))


func _draw_orbiting_motes(
	center: Vector2,
	radius: float,
	count: int,
	phase: float,
	color: Color
) -> void:
	for mote_index in range(count):
		var angle := phase + TAU * float(mote_index) / float(maxi(count, 1))
		var orbit_scale := 0.82 + 0.12 * sin(angle * 2.0)
		var position := center + Vector2(cos(angle), sin(angle)) * radius * orbit_scale
		var mote_radius := 1.6 + float(mote_index % 3)
		draw_circle(position, mote_radius * 2.4, Color(color.r, color.g, color.b, color.a * 0.12))
		draw_circle(position, mote_radius, color)


func _draw_rising_motes(
	center: Vector2,
	radius: float,
	count: int,
	phase: float,
	color: Color
) -> void:
	for mote_index in range(count):
		var travel := fmod(progress * 1.7 + float(mote_index) / float(maxi(count, 1)), 1.0)
		var angle := phase * 0.18 + float(mote_index) * 2.399
		var horizontal := sin(angle) * radius * (0.18 + float(mote_index % 4) * 0.07)
		var position := center + Vector2(horizontal, radius * 0.52 - travel * radius * 1.38)
		var alpha := color.a * sin(travel * PI)
		draw_circle(position, 1.5 + float(mote_index % 3), Color(color.r, color.g, color.b, alpha))


func _draw_polyline_glow(points: PackedVector2Array, color: Color, width: float, closed: bool) -> void:
	if points.size() < 2:
		return
	var line_points := points
	if closed and points[0] != points[points.size() - 1]:
		line_points = points.duplicate()
		line_points.append(points[0])
	draw_polyline(line_points, Color(color.r, color.g, color.b, color.a * 0.12), width * 4.5, true)
	draw_polyline(line_points, Color(color.r, color.g, color.b, color.a * 0.34), width * 2.2, true)
	draw_polyline(line_points, color, width, true)


func _draw_glow_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, Color(color.r, color.g, color.b, color.a * 0.12), width * 5.0, true)
	draw_line(from, to, Color(color.r, color.g, color.b, color.a * 0.36), width * 2.4, true)
	draw_line(from, to, color, width, true)


func _shield_points(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.76, -radius * 0.68),
		center + Vector2(radius * 0.68, radius * 0.42),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.68, radius * 0.42),
		center + Vector2(-radius * 0.76, -radius * 0.68)
	])


func _ease_out(value: float, from: float, to: float) -> float:
	var normalized := clampf(inverse_lerp(from, to, value), 0.0, 1.0)
	return 1.0 - pow(1.0 - normalized, 3.0)
