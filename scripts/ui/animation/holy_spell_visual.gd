extends Control

# Procedural canvas used by Silver Hand spell animations. It intentionally owns
# no rule state; the provider only drives progress and opacity.

const HOLY_CORE := Color(1.0, 0.995, 0.90, 0.98)
const HOLY_WHITE := Color(1.0, 0.96, 0.78, 0.92)
const HOLY_IVORY := Color(1.0, 0.88, 0.56, 0.84)
const HOLY_GOLD := Color(1.0, 0.72, 0.16, 0.92)
const HOLY_EDGE := Color(0.96, 0.79, 0.34, 0.96)
const PEARL_SILVER := Color(0.88, 0.92, 0.90, 0.88)
const HOLY_AMBER := Color(1.0, 0.56, 0.10, 0.86)

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
		"faith_light":
			_draw_faith_light()
		"healing_to_resolve":
			_draw_healing_to_resolve()
		"resurrection":
			_draw_resurrection()


func _draw_divine_shield() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var prayer := _ease_out(progress, 0.0, 0.20)
	var descent := _ease_out(progress, 0.14, 0.42)
	var lock_in := _ease_out(progress, 0.32, 0.66)
	var pulse := 0.5 + 0.5 * sin(progress * TAU * 1.35)
	var shield_scale := lerpf(0.28, 1.0 + pulse * 0.012, lock_in)
	var points := _shield_points(center, radius * shield_scale)

	_draw_holy_seal(center + Vector2(0.0, radius * 0.72), radius * 0.72 * prayer, 0.0, 0.58)
	_draw_vertical_light(
		Rect2(
			Vector2(center.x - radius * 0.52, center.y - radius * 1.65),
			Vector2(radius * 1.04, radius * 2.12)
		),
		descent,
		0.34
	)

	draw_colored_polygon(points, Color(0.88, 0.91, 0.82, 0.08 + lock_in * 0.13))
	_draw_polyline_glow(points, Color(HOLY_EDGE.r, HOLY_EDGE.g, HOLY_EDGE.b, 0.70 + lock_in * 0.24), 3.8, true)

	var inner_points := _shield_points(center, radius * shield_scale * 0.80)
	draw_polyline(inner_points, Color(PEARL_SILVER.r, PEARL_SILVER.g, PEARL_SILVER.b, 0.48 + lock_in * 0.24), 2.0, true)

	for brace_index in range(3):
		var brace_y := center.y - radius * 0.38 + float(brace_index) * radius * 0.38
		var half_width := radius * (0.34 - absf(float(brace_index) - 1.0) * 0.05)
		draw_line(
			Vector2(center.x - half_width, brace_y),
			Vector2(center.x + half_width, brace_y),
			Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.22 + lock_in * 0.28),
			1.8,
			true
		)
	_draw_hammer_mark(center, radius * 0.30 * lock_in, Color(HOLY_CORE.r, HOLY_CORE.g, HOLY_CORE.b, 0.86))
	_draw_ordered_motes(center, radius * 0.92, 8, progress * TAU * 0.45, HOLY_WHITE)


func _draw_holy_heal() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.31
	var prayer := _ease_out(progress, 0.0, 0.18)
	var descent := _ease_out(progress, 0.12, 0.38)
	var absorb := _ease_out(progress, 0.34, 0.76)
	var release := _ease_out(progress, 0.56, 1.0)
	var phase := progress * TAU * 1.2

	_draw_holy_seal(center + Vector2(0.0, radius * 0.64), radius * 0.62 * prayer, phase * 0.08, 0.50)
	_draw_vertical_light(
		Rect2(
			Vector2(center.x - radius * 0.44, center.y - radius * 1.55),
			Vector2(radius * 0.88, radius * 2.02)
		),
		descent,
		0.40
	)

	for ribbon_index in range(5):
		var ribbon := PackedVector2Array()
		for step in range(18):
			var t := float(step) / 17.0
			var x_offset := (float(ribbon_index) - 2.0) * radius * 0.13
			var spiral := sin(t * TAU * 0.85 + phase + float(ribbon_index) * 0.84)
			var x := center.x + x_offset * (1.0 - absorb * 0.70) + spiral * radius * 0.055
			var y := center.y + radius * 0.74 - t * radius * (1.26 + absorb * 0.22)
			ribbon.append(Vector2(x, y))
		draw_polyline(ribbon, Color(1.0, 0.91, 0.58, 0.20 + descent * 0.20), 2.2, true)

	_draw_glow_circle(center, radius * (0.10 + absorb * 0.13), HOLY_CORE)
	for ring_index in range(3):
		var ring_radius := radius * (0.20 + release * (0.48 + float(ring_index) * 0.14))
		draw_arc(
			center,
			ring_radius,
			0.0,
			TAU,
			48,
			Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.36 - float(ring_index) * 0.08),
			2.2,
			true
		)
	_draw_rising_motes(center, radius, 10, phase, HOLY_WHITE)


func _draw_power_word_shield() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var prayer := _ease_out(progress, 0.0, 0.20)
	var reinforce := _ease_out(progress, 0.18, 0.56)
	var life_rise := _ease_out(progress, 0.42, 0.92)
	var phase := progress * TAU * 0.75

	_draw_holy_seal(center, radius * 0.86 * prayer, phase * 0.10, 0.58)
	var armor_points := _shield_points(center, radius * lerpf(0.32, 0.90, reinforce))
	draw_colored_polygon(armor_points, Color(1.0, 0.82, 0.30, 0.07 + reinforce * 0.08))
	_draw_polyline_glow(armor_points, Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, 0.78), 3.0, true)
	var inner_armor := _shield_points(center, radius * 0.72 * reinforce)
	draw_polyline(inner_armor, Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, 0.46), 1.8, true)

	for oath_index in range(6):
		var angle := phase + TAU * float(oath_index) / 6.0
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var oath_center := center + radial * radius * 0.86
		var rune_size := radius * 0.085
		draw_line(oath_center - tangent * rune_size, oath_center + tangent * rune_size, HOLY_EDGE, 1.8, true)
		draw_line(oath_center, oath_center + radial * rune_size * 1.4, HOLY_EDGE, 1.5, true)

	for chevron_index in range(3):
		var lift := fmod(life_rise + float(chevron_index) / 3.0, 1.0)
		var y := center.y + radius * 0.58 - lift * radius * 1.16
		var chevron := PackedVector2Array([
			Vector2(center.x - radius * 0.17, y + radius * 0.09),
			Vector2(center.x, y),
			Vector2(center.x + radius * 0.17, y + radius * 0.09)
		])
		draw_polyline(chevron, Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.24 + (1.0 - lift) * 0.46), 2.4, true)
	_draw_ordered_motes(center, radius, 8, -phase, HOLY_WHITE)


func _draw_baptism() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.29
	var prayer := _ease_out(progress, 0.0, 0.16)
	var descent := _ease_out(progress, 0.10, 0.36)
	var healing := _ease_out(progress, 0.26, 0.56)
	var judgment := _ease_out(progress, 0.50, 0.88)
	var phase := progress * TAU * 0.95

	_draw_holy_seal(center, radius * 0.84 * prayer, phase * 0.08, 0.66)
	_draw_vertical_light(
		Rect2(
			Vector2(center.x - radius * 0.60, center.y - radius * 1.55),
			Vector2(radius * 1.20, radius * 1.92)
		),
		descent,
		0.54
	)
	for inward_index in range(8):
		var angle := TAU * float(inward_index) / 8.0
		var direction := Vector2.from_angle(angle)
		var inward_start := center + direction * radius * lerpf(0.78, 0.22, healing)
		var inward_end := center + direction * radius * lerpf(0.52, 0.10, healing)
		draw_line(inward_start, inward_end, Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, 0.52), 2.2, true)
	_draw_glow_circle(center, radius * (0.08 + healing * 0.16), HOLY_CORE)

	for ring_index in range(3):
		var ring_radius := radius * (0.30 + judgment * (0.82 + float(ring_index) * 0.20))
		draw_arc(
			center,
			ring_radius,
			0.0,
			TAU,
			56,
			Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, 0.72 - float(ring_index) * 0.15),
			3.8 - float(ring_index) * 0.6,
			true
		)
	for ray_index in range(12):
		var angle := TAU * float(ray_index) / 12.0
		var direction := Vector2(cos(angle), sin(angle))
		var ray_start := center + direction * radius * (0.24 + judgment * 0.30)
		var ray_end := center + direction * radius * (0.40 + judgment * 1.02)
		var width := 3.2 if ray_index % 3 == 0 else 2.0
		draw_line(ray_start, ray_end, Color(HOLY_EDGE.r, HOLY_EDGE.g, HOLY_EDGE.b, 0.60), width, true)
	_draw_hammer_mark(center, radius * 0.24 * healing, Color(HOLY_CORE.r, HOLY_CORE.g, HOLY_CORE.b, 0.88))
	_draw_rising_motes(center, radius * 1.1, 12, phase, HOLY_WHITE)


func _draw_inner_fire() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var prayer := _ease_out(progress, 0.0, 0.18)
	var compression := _ease_out(progress, 0.16, 0.52)
	var surge := _ease_out(progress, 0.46, 0.88)
	var phase := progress * TAU * 1.75
	var flame_center := center + Vector2(0.0, radius * 0.16 - surge * radius * 0.12)
	var flame_scale := lerpf(0.24, 1.0, surge)
	var sway := sin(phase) * radius * 0.035

	_draw_holy_seal(center, radius * 0.76 * prayer, -phase * 0.05, 0.54)
	for band_index in range(8):
		var angle := TAU * float(band_index) / 8.0
		var direction := Vector2.from_angle(angle)
		var band_start := center + direction * radius * lerpf(0.92, 0.22, compression)
		var band_end := center + direction * radius * lerpf(0.62, 0.08, compression)
		_draw_glow_line(
			band_start,
			band_end,
			Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.52),
			1.8
		)
	_draw_glow_circle(center, radius * (0.08 + compression * 0.15), HOLY_CORE)

	var outer_flame := PackedVector2Array([
		flame_center + Vector2(-radius * 0.42, radius * 0.62) * flame_scale,
		flame_center + Vector2(-radius * 0.36, radius * 0.08) * flame_scale,
		flame_center + Vector2(-radius * 0.10 + sway, -radius * 0.34) * flame_scale,
		flame_center + Vector2(radius * 0.02 - sway * 0.35, -radius * 0.94) * flame_scale,
		flame_center + Vector2(radius * 0.22, -radius * 0.30) * flame_scale,
		flame_center + Vector2(radius * 0.38, radius * 0.02) * flame_scale,
		flame_center + Vector2(radius * 0.43, radius * 0.62) * flame_scale
	])
	draw_colored_polygon(outer_flame, Color(1.0, 0.72, 0.12, 0.34))
	_draw_polyline_glow(outer_flame, Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, 0.94), 3.2, false)

	var inner_flame := PackedVector2Array([
		flame_center + Vector2(-radius * 0.19, radius * 0.55),
		flame_center + Vector2(-radius * 0.14, radius * 0.08),
		flame_center + Vector2(radius * 0.04 + sway * 0.25, -radius * 0.48),
		flame_center + Vector2(radius * 0.19, radius * 0.06),
		flame_center + Vector2(radius * 0.20, radius * 0.55)
	])
	draw_colored_polygon(inner_flame, Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, 0.76))
	draw_polyline(inner_flame, HOLY_CORE, 2.2, true)
	_draw_hammer_mark(flame_center + Vector2(0.0, radius * 0.18), radius * 0.20 * surge, HOLY_CORE)
	for spark_index in range(10):
		var spark_phase := fmod(progress * 1.6 + float(spark_index) / 10.0, 1.0)
		var angle := float(spark_index) * 2.399
		var start := flame_center + Vector2(cos(angle), 0.55) * radius * 0.45
		var spark := start + Vector2(sin(angle) * radius * 0.22, -spark_phase * radius * 1.45)
		draw_circle(spark, 1.6 + float(spark_index % 3), Color(HOLY_AMBER.r, HOLY_AMBER.g, HOLY_AMBER.b, 0.78 - spark_phase * 0.50))


func _draw_faith_light() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.32
	var answer := _ease_out(progress, 0.0, 0.24)
	var pulse := _ease_out(progress, 0.18, 0.62)
	var settle := _ease_out(progress, 0.54, 1.0)
	var phase := progress * TAU * 0.70

	_draw_holy_seal(center + Vector2(0.0, radius * 0.58), radius * 0.58 * answer, phase * 0.08, 0.46)
	_draw_vertical_light(
		Rect2(
			Vector2(center.x - radius * 0.24, center.y - radius * 1.42),
			Vector2(radius * 0.48, radius * 1.80)
		),
		answer,
		0.32
	)
	_draw_hammer_mark(center - Vector2(0.0, radius * 0.05), radius * 0.22 * pulse, HOLY_CORE)
	for ring_index in range(2):
		draw_arc(
			center,
			radius * (0.22 + pulse * (0.42 + float(ring_index) * 0.16)),
			0.0,
			TAU,
			44,
			Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.42 - float(ring_index) * 0.11),
			2.2,
			true
		)
	for mote_index in range(6):
		var travel := fmod(settle + float(mote_index) / 6.0, 1.0)
		var mote_position := center + Vector2(
			(float(mote_index % 3) - 1.0) * radius * 0.18,
			radius * 0.44 - travel * radius * 1.06
		)
		draw_circle(mote_position, 1.8 + float(mote_index % 2), Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, sin(travel * PI) * 0.74))


func _draw_healing_to_resolve() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var gather := _ease_out(progress, 0.0, 0.36)
	var arm := _ease_out(progress, 0.30, 0.70)
	var strike_ready := _ease_out(progress, 0.58, 1.0)
	var phase := progress * TAU * 0.90

	for ray_index in range(8):
		var angle := TAU * float(ray_index) / 8.0 + phase * 0.08
		var direction := Vector2.from_angle(angle)
		var start := center + direction * radius * lerpf(0.94, 0.28, gather)
		var finish := center + direction * radius * lerpf(0.58, 0.10, gather)
		_draw_glow_line(start, finish, Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, 0.56), 1.8)
	_draw_glow_circle(center, radius * (0.07 + gather * 0.14), HOLY_CORE)

	var weapon_base := center + Vector2(0.0, radius * 0.48)
	var weapon_tip := center + Vector2(0.0, -radius * (0.16 + arm * 0.64))
	_draw_glow_line(weapon_base, weapon_tip, Color(HOLY_EDGE.r, HOLY_EDGE.g, HOLY_EDGE.b, 0.94), 4.0)
	var guard_half := radius * 0.28 * arm
	_draw_glow_line(
		center + Vector2(-guard_half, radius * 0.10),
		center + Vector2(guard_half, radius * 0.10),
		Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.90),
		3.2
	)
	for oath_index in range(4):
		var angle := PI * 0.25 + TAU * float(oath_index) / 4.0
		var mark_center := center + Vector2.from_angle(angle) * radius * (0.38 + strike_ready * 0.36)
		var tangent := Vector2.from_angle(angle).orthogonal()
		draw_line(mark_center - tangent * 4.0, mark_center + tangent * 4.0, HOLY_GOLD, 1.8, true)
	draw_arc(
		center,
		radius * (0.24 + strike_ready * 0.64),
		-PI * 0.12,
		PI * 1.12,
		48,
		Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, 0.62),
		3.0,
		true
	)


func _draw_resurrection() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.27
	var prayer := _ease_out(progress, 0.0, 0.20)
	var descent := _ease_out(progress, 0.12, 0.42)
	var reform := _ease_out(progress, 0.34, 0.70)
	var recall := _ease_out(progress, 0.62, 1.0)
	var phase := progress * TAU * 0.78
	var naaru_center := Vector2(center.x, lerpf(-radius * 0.70, center.y - radius * 0.16, descent))

	_draw_holy_seal(center + Vector2(0.0, radius * 0.78), radius * 1.28 * prayer, phase * 0.06, 0.64)
	for beam_index in range(9):
		var spread := (float(beam_index) - 4.0) * radius * 0.16
		var beam_end := center + Vector2(spread * (1.0 + reform * 0.35), radius * 0.98)
		draw_line(
			naaru_center + Vector2(spread * 0.18, 0.0),
			beam_end,
			Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, 0.08 + descent * 0.16),
			2.0 + float(beam_index % 3),
			true
		)

	_draw_naaru(naaru_center, radius * (0.52 + descent * 0.48), phase)
	var formation_center := center + Vector2(0.0, radius * 0.80)
	for unit_index in range(6):
		var column := float(unit_index % 3) - 1.0
		var row := floorf(float(unit_index) / 3.0)
		var origin := formation_center + Vector2(column * radius * 0.62, row * radius * 0.40)
		var rise_offset := Vector2(0.0, lerpf(radius * 0.24, -radius * 0.08, reform))
		var silhouette_center := origin + rise_offset
		var silhouette_alpha := sin(clampf(reform, 0.0, 1.0) * PI * 0.72) * (1.0 - recall * 0.54)
		_draw_unit_silhouette(
			silhouette_center,
			radius * 0.20,
			Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, silhouette_alpha)
		)
		draw_arc(
			origin + Vector2(0.0, radius * 0.15),
			radius * 0.24,
			0.0,
			TAU,
			28,
			Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, 0.34 + reform * 0.32),
			1.8,
			true
		)

		if recall > 0.0:
			var target := center + Vector2(radius * 2.15, -radius * 1.18 + float(unit_index) * radius * 0.10)
			var current := silhouette_center.lerp(target, recall)
			_draw_holy_seal(current, radius * 0.16 * (1.0 - recall * 0.35), phase, 0.52)
			draw_line(
				silhouette_center,
				current,
				Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, 0.24 * recall),
				1.5,
				true
			)
	_draw_rising_motes(formation_center, radius * 1.35, 18, phase, HOLY_WHITE)


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


func _draw_holy_seal(
	center: Vector2,
	radius: float,
	seal_rotation: float,
	alpha: float
) -> void:
	if radius <= 0.1:
		return

	draw_circle(center, radius * 0.72, Color(1.0, 0.84, 0.28, alpha * 0.055))
	draw_arc(center, radius, 0.0, TAU, 64, Color(HOLY_EDGE.r, HOLY_EDGE.g, HOLY_EDGE.b, alpha), 2.6, true)
	draw_arc(center, radius * 0.72, 0.0, TAU, 56, Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, alpha * 0.68), 1.7, true)

	var shield := _shield_points(center, radius * 0.42)
	draw_polyline(shield, Color(HOLY_IVORY.r, HOLY_IVORY.g, HOLY_IVORY.b, alpha * 0.62), 1.5, true)
	for mark_index in range(8):
		var angle := seal_rotation + TAU * float(mark_index) / 8.0
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var mark_center := center + radial * radius * 0.86
		var mark_size := radius * (0.065 + float(mark_index % 2) * 0.018)
		draw_line(
			mark_center - tangent * mark_size,
			mark_center + tangent * mark_size,
			Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, alpha * 0.84),
			1.6,
			true
		)
		draw_line(
			mark_center,
			mark_center - radial * mark_size * 1.3,
			Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, alpha * 0.66),
			1.2,
			true
		)


func _draw_vertical_light(beam_rect: Rect2, reveal: float, alpha: float) -> void:
	if reveal <= 0.0 or beam_rect.size == Vector2.ZERO:
		return

	var visible_rect := Rect2(
		beam_rect.position,
		Vector2(beam_rect.size.x, beam_rect.size.y * reveal)
	)
	var center_x := visible_rect.get_center().x
	draw_rect(visible_rect, Color(1.0, 0.92, 0.58, alpha * 0.055), true)
	draw_rect(
		Rect2(
			Vector2(center_x - visible_rect.size.x * 0.24, visible_rect.position.y),
			Vector2(visible_rect.size.x * 0.48, visible_rect.size.y)
		),
		Color(HOLY_WHITE.r, HOLY_WHITE.g, HOLY_WHITE.b, alpha * 0.12),
		true
	)
	_draw_glow_line(
		Vector2(center_x, visible_rect.position.y),
		Vector2(center_x, visible_rect.end.y),
		Color(HOLY_CORE.r, HOLY_CORE.g, HOLY_CORE.b, alpha * 0.62),
		maxf(visible_rect.size.x * 0.055, 2.0)
	)
	draw_line(
		Vector2(visible_rect.position.x, visible_rect.end.y),
		Vector2(visible_rect.end.x, visible_rect.end.y),
		Color(HOLY_GOLD.r, HOLY_GOLD.g, HOLY_GOLD.b, alpha * 0.54),
		2.0,
		true
	)


func _draw_hammer_mark(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.1:
		return
	var head_rect := Rect2(
		center + Vector2(-radius * 0.58, -radius * 0.48),
		Vector2(radius * 1.16, radius * 0.42)
	)
	draw_rect(head_rect, Color(color.r, color.g, color.b, color.a * 0.14), true)
	draw_rect(head_rect, color, false, 2.2, true)
	_draw_glow_line(
		center + Vector2(0.0, -radius * 0.10),
		center + Vector2(0.0, radius * 0.68),
		color,
		2.8
	)
	draw_line(
		center + Vector2(-radius * 0.22, radius * 0.62),
		center + Vector2(radius * 0.22, radius * 0.62),
		Color(HOLY_EDGE.r, HOLY_EDGE.g, HOLY_EDGE.b, color.a),
		2.0,
		true
	)


func _draw_unit_silhouette(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.1 or color.a <= 0.0:
		return
	draw_circle(center - Vector2(0.0, radius * 0.55), radius * 0.22, color)
	var body := PackedVector2Array([
		center + Vector2(-radius * 0.42, radius * 0.52),
		center + Vector2(-radius * 0.32, -radius * 0.18),
		center + Vector2(0.0, -radius * 0.34),
		center + Vector2(radius * 0.32, -radius * 0.18),
		center + Vector2(radius * 0.42, radius * 0.52)
	])
	draw_colored_polygon(body, Color(color.r, color.g, color.b, color.a * 0.24))
	draw_polyline(body, color, 1.8, true)


func _draw_ordered_motes(
	center: Vector2,
	radius: float,
	count: int,
	phase: float,
	color: Color
) -> void:
	for mote_index in range(count):
		var angle := phase + TAU * float(mote_index) / float(maxi(count, 1))
		var orbit_radius := radius * (0.82 + float(mote_index % 2) * 0.08)
		var mote_position := center + Vector2.from_angle(angle) * orbit_radius
		var mote_radius := 1.5 + float(mote_index % 2)
		draw_circle(mote_position, mote_radius * 2.6, Color(color.r, color.g, color.b, color.a * 0.10))
		draw_circle(mote_position, mote_radius, color)


func _draw_glow_circle(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.1:
		return
	draw_circle(center, radius * 2.20, Color(color.r, color.g, color.b, color.a * 0.06))
	draw_circle(center, radius * 1.46, Color(color.r, color.g, color.b, color.a * 0.18))
	draw_circle(center, radius, color)


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
