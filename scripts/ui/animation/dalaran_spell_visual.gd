extends Control

# Procedural school-language canvas for Dalaran spells. The animation provider
# owns timing and placement; this node only renders a deterministic key frame.

const ARCANE_EDGE := Color(0.56, 0.62, 1.0, 0.88)
const FIRE_RUNE := Color(1.0, 0.48, 0.12, 0.82)
const ICE_EDGE := Color(0.72, 0.94, 1.0, 0.88)
const WATER_EDGE := Color(0.42, 0.88, 1.0, 0.86)
const WATER_CORE := Color(0.42, 0.78, 1.0, 0.94)

var visual_key := ""
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var strength := 1.0:
	set(value):
		strength = maxf(value, 0.1)
		queue_redraw()


func configure(key: String, visual_strength := 1.0) -> void:
	visual_key = key
	strength = visual_strength
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	match visual_key:
		"arcane_aura_prepare", "arcane_aura", "arcane_aura_pulse":
			_draw_arcane_aura()
		"water_summon", "giant_water_summon":
			_draw_water_summon()
		"frost_shield":
			_draw_frost_shield()
		"arcane_wisdom":
			_draw_arcane_wisdom()
		"arcane_space", "arcane_space_anchor":
			_draw_arcane_space()
		"academy_summon":
			_draw_academy_summon()
		"blizzard":
			_draw_blizzard()
		"fireball_charge", "pyroblast_charge":
			_draw_fire_charge()
		"fireball_projectile", "pyroblast_projectile":
			_draw_fire_projectile()
		"fireball_impact", "pyroblast_impact":
			_draw_fire_impact()


func _draw_arcane_aura() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.35
	var arrival := _ease_out(progress, 0.0, 0.28)
	var phase := progress * TAU * 2.0
	var is_pulse := visual_key == "arcane_aura_pulse"
	var ring_count := 4 if visual_key == "arcane_aura" else 3

	_draw_arcane_array(center, radius * arrival, phase, ring_count, 0.92)
	_draw_orbiting_shards(center, radius * 0.88, 10, phase, ARCANE_EDGE)

	for stream_index in range(6):
		var stream := PackedVector2Array()
		for step in range(15):
			var t := float(step) / 14.0
			var angle := phase * 0.46 + float(stream_index) * TAU / 6.0 + t * 1.3
			var stream_radius := radius * (0.30 + t * 0.64)
			stream.append(
				center
				+ Vector2(cos(angle), sin(angle))
				* stream_radius
				* Vector2(1.0, 0.72)
			)
		draw_polyline(stream, Color(0.48, 0.68, 1.0, 0.28), 2.0, true)

	if is_pulse:
		var pulse := _ease_out(progress, 0.34, 1.0)
		for pulse_index in range(3):
			draw_arc(
				center,
				radius * (0.48 + pulse * (0.54 + float(pulse_index) * 0.18)),
				0.0,
				TAU,
				64,
				Color(0.64, 0.82, 1.0, 0.58 - float(pulse_index) * 0.13),
				2.4,
				true
			)
		var stream_start := center + Vector2(radius * 0.20, -radius * 0.12)
		var stream_end := center + Vector2(radius * 1.42, -radius * 1.02)
		_draw_energy_beam(stream_start, stream_end, Color(0.58, 0.80, 1.0, 0.88), 3.0)


func _draw_water_summon() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * (0.35 if visual_key == "water_summon" else 0.40)
	var arrival := _ease_out(progress, 0.0, 0.42)
	var phase := progress * TAU * 2.6
	var body_scale := lerpf(0.24, 1.0, arrival)

	for layer_index in range(3):
		var liquid_loop := PackedVector2Array()
		var points := 48
		for point_index in range(points + 1):
			var angle := TAU * float(point_index) / float(points)
			var ripple := 1.0 + sin(angle * 3.0 + phase + float(layer_index)) * 0.055
			var layer_radius := radius * body_scale * (0.74 + float(layer_index) * 0.13) * ripple
			liquid_loop.append(
				center
				+ Vector2(cos(angle), sin(angle))
				* layer_radius
				* Vector2(0.80, 1.08)
			)
		draw_polyline(
			liquid_loop,
			Color(0.24, 0.80, 1.0, 0.30 + float(layer_index) * 0.16),
			5.0 - float(layer_index),
			true
		)

	for spiral_index in range(4):
		var spiral := PackedVector2Array()
		for step in range(18):
			var t := float(step) / 17.0
			var angle := phase + float(spiral_index) * PI * 0.5 + t * TAU * 1.20
			var spiral_radius := radius * (0.16 + t * 0.72) * arrival
			spiral.append(
				center
				+ Vector2(cos(angle), sin(angle))
				* spiral_radius
				* Vector2(0.92, 0.68)
			)
		draw_polyline(spiral, Color(0.50, 0.92, 1.0, 0.44), 2.4, true)

	_draw_glow_circle(center, radius * 0.20 * arrival, WATER_CORE)
	draw_arc(center, radius * 1.08 * arrival, phase, phase + PI * 1.62, 64, WATER_EDGE, 2.8, true)
	_draw_water_droplets(center, radius, phase, 14)

	for mist_index in range(7):
		var drift := fmod(progress * 1.35 + float(mist_index) / 7.0, 1.0)
		var x := center.x + sin(float(mist_index) * 2.1 + phase * 0.16) * radius * 0.72
		var y := center.y + radius * 0.76 - drift * radius * 1.42
		draw_circle(
			Vector2(x, y),
			radius * (0.055 + float(mist_index % 3) * 0.018),
			Color(0.78, 0.96, 1.0, 0.10 + sin(drift * PI) * 0.16)
		)


func _draw_frost_shield() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var arrival := _ease_out(progress, 0.0, 0.34)
	var phase := progress * TAU * 1.8
	var shield_radius := radius * lerpf(0.26, 1.0, arrival)
	var hexagon := _regular_polygon(center, shield_radius, 6, -PI * 0.5, true)

	draw_colored_polygon(
		PackedVector2Array(hexagon.slice(0, hexagon.size() - 1)),
		Color(0.26, 0.74, 1.0, 0.13)
	)
	_draw_polyline_glow(hexagon, Color(0.70, 0.94, 1.0, 0.92), 3.2)
	var inner_hex := _regular_polygon(center, shield_radius * 0.72, 6, PI / 6.0, true)
	draw_polyline(inner_hex, Color(0.44, 0.84, 1.0, 0.62), 2.0, true)

	for facet_index in range(6):
		draw_line(center, hexagon[facet_index], Color(0.62, 0.90, 1.0, 0.24), 1.6, true)
	for crystal_index in range(12):
		var angle := phase + TAU * float(crystal_index) / 12.0
		var crystal_center := center + Vector2(cos(angle), sin(angle)) * shield_radius * 1.06
		_draw_ice_crystal(crystal_center, angle, radius * (0.08 + float(crystal_index % 3) * 0.016))

	for frost_index in range(3):
		var spread := _ease_out(progress, 0.22 + float(frost_index) * 0.08, 0.88)
		draw_arc(
			center,
			shield_radius * (0.46 + spread * (0.34 + float(frost_index) * 0.13)),
			phase * (-1.0 if frost_index % 2 == 0 else 1.0),
			phase + PI * 1.42,
			48,
			Color(0.82, 0.98, 1.0, 0.46 - float(frost_index) * 0.08),
			2.0,
			true
		)


func _draw_arcane_wisdom() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var arrival := _ease_out(progress, 0.0, 0.28)
	var absorb := _ease_out(progress, 0.34, 1.0)
	var phase := progress * TAU * 1.7

	_draw_arcane_array(center, radius * arrival, phase, 3, 0.74)
	for page_index in range(6):
		var angle := phase + TAU * float(page_index) / 6.0
		var orbit_radius := radius * lerpf(0.92, 0.24, absorb)
		var page_center := center + Vector2(cos(angle), sin(angle)) * orbit_radius * Vector2(1.0, 0.72)
		var page_size := Vector2(radius * 0.20, radius * 0.15) * (1.0 - absorb * 0.42)
		var page_rect := Rect2(page_center - page_size * 0.5, page_size)
		draw_rect(page_rect, Color(0.68, 0.74, 1.0, 0.16), true)
		draw_rect(page_rect, Color(0.78, 0.86, 1.0, 0.78), false, 1.6, true)
		draw_line(
			page_center + Vector2(0.0, -page_size.y * 0.42),
			page_center + Vector2(0.0, page_size.y * 0.42),
			Color(0.88, 0.92, 1.0, 0.48),
			1.0,
			true
		)
		draw_line(page_center, center, Color(0.48, 0.58, 1.0, 0.20), 1.2, true)

	_draw_glow_circle(center, radius * (0.10 + absorb * 0.10), Color(0.72, 0.82, 1.0, 0.94))
	_draw_orbiting_shards(center, radius * 0.62, 12, -phase * 1.2, ARCANE_EDGE)


func _draw_arcane_space() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var arrival := _ease_out(progress, 0.0, 0.30)
	var fold := _ease_out(progress, 0.34, 1.0)
	var phase := progress * TAU * 1.5

	for grid_index in range(-2, 3):
		var offset := float(grid_index) * radius * 0.24 * arrival
		var shear := sin(phase + float(grid_index)) * radius * 0.08 * fold
		draw_line(
			center + Vector2(-radius, offset - shear),
			center + Vector2(radius, offset + shear),
			Color(0.42, 0.58, 1.0, 0.20),
			1.4,
			true
		)
		draw_line(
			center + Vector2(offset + shear, -radius),
			center + Vector2(offset - shear, radius),
			Color(0.58, 0.42, 1.0, 0.20),
			1.4,
			true
		)

	for frame_index in range(3):
		var frame_radius := radius * (0.42 + float(frame_index) * 0.24) * arrival
		var frame := _regular_polygon(
			center,
			frame_radius,
			4,
			phase * (0.18 + float(frame_index) * 0.08) + PI * 0.25,
			true
		)
		_draw_polyline_glow(
			frame,
			Color(0.52 + float(frame_index) * 0.08, 0.56, 1.0, 0.72 - float(frame_index) * 0.12),
			2.4 - float(frame_index) * 0.3
		)
	_draw_orbiting_shards(center, radius * 0.92, 8, -phase, Color(0.74, 0.66, 1.0, 0.90))


func _draw_academy_summon() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var arrival := _ease_out(progress, 0.0, 0.32)
	var phase := progress * TAU * 1.35

	_draw_arcane_array(center, radius * arrival, phase, 4, 0.82)
	var school_colors: Array[Color] = [
		Color(0.66, 0.48, 1.0, 0.94),
		Color(1.0, 0.52, 0.12, 0.96),
		Color(0.48, 0.88, 1.0, 0.96)
	]
	for school_index in range(3):
		var angle := -PI * 0.5 + TAU * float(school_index) / 3.0 + phase * 0.08
		var school_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.66
		_draw_school_node(school_center, radius * 0.16, school_colors[school_index], school_index)
		draw_line(center, school_center, Color(school_colors[school_index], 0.34), 2.0, true)

	for apprentice_index in range(3):
		var angle := PI * 0.16 + PI * 0.34 * float(apprentice_index)
		var apprentice_center := center + Vector2(cos(angle), sin(angle)) * radius * 1.02
		draw_circle(apprentice_center, radius * 0.07, Color(0.48, 0.72, 1.0, 0.18))
		draw_arc(
			apprentice_center,
			radius * 0.10,
			phase + angle,
			phase + angle + PI * 1.72,
			20,
			Color(0.72, 0.86, 1.0, 0.76),
			1.8,
			true
		)


func _draw_blizzard() -> void:
	var area_rect := Rect2(Vector2.ZERO, size).grow(-minf(size.x, size.y) * 0.035)
	var center := area_rect.get_center()
	var radius := minf(area_rect.size.x, area_rect.size.y) * 0.43
	var arrival := _ease_out(progress, 0.0, 0.24)
	var phase := progress * TAU * 2.3

	draw_rect(area_rect, Color(0.14, 0.46, 0.72, 0.08 + arrival * 0.05), true)
	draw_rect(area_rect, Color(0.54, 0.88, 1.0, 0.66), false, 3.2, true)
	_draw_arcane_array(center, radius * arrival, -phase * 0.28, 2, 0.50)

	for crack_index in range(12):
		var angle := TAU * float(crack_index) / 12.0
		var crack_start := center + Vector2(cos(angle), sin(angle)) * radius * 0.18
		var crack_mid := center + Vector2(cos(angle + 0.10), sin(angle + 0.10)) * radius * 0.54
		var crack_end := center + Vector2(cos(angle - 0.05), sin(angle - 0.05)) * radius * 0.92
		draw_polyline(
			PackedVector2Array([crack_start, crack_mid, crack_end]),
			Color(0.72, 0.94, 1.0, 0.34),
			1.7,
			true
		)

	for shard_index in range(30):
		var x_ratio := fmod(float(shard_index) * 0.6180339 + 0.13, 1.0)
		var fall := fmod(progress * (1.4 + float(shard_index % 4) * 0.16) + float(shard_index) / 30.0, 1.0)
		var shard_position := Vector2(
			area_rect.position.x + area_rect.size.x * x_ratio,
			area_rect.position.y + area_rect.size.y * fall
		)
		var shard_length := 5.0 + float(shard_index % 4) * 2.0
		draw_line(
			shard_position + Vector2(-1.5, -shard_length),
			shard_position + Vector2(1.5, shard_length),
			Color(0.84, 0.98, 1.0, 0.52 + float(shard_index % 3) * 0.10),
			1.5,
			true
		)

	for mist_index in range(10):
		var angle := phase * 0.25 + TAU * float(mist_index) / 10.0
		var mist_center := center + Vector2(cos(angle), sin(angle)) * radius * (0.58 + float(mist_index % 3) * 0.12)
		draw_circle(
			mist_center,
			radius * (0.10 + float(mist_index % 2) * 0.04),
			Color(0.56, 0.84, 1.0, 0.08)
		)


func _draw_fire_charge() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var is_pyro := visual_key == "pyroblast_charge"
	var arrival := _ease_out(progress, 0.0, 0.74 if is_pyro else 0.48)
	var phase := progress * TAU * (2.7 if is_pyro else 2.1)
	var core_radius := radius * (0.12 + arrival * (0.22 if is_pyro else 0.16))

	_draw_arcane_array(
		center,
		radius * arrival,
		-phase * 0.24,
		3 if is_pyro else 2,
		0.52,
		FIRE_RUNE
	)
	_draw_glow_circle(center, core_radius * 1.72, Color(1.0, 0.24, 0.03, 0.22))
	_draw_glow_circle(center, core_radius, Color(1.0, 0.74, 0.14, 0.96))
	draw_circle(center, core_radius * 0.42, Color(1.0, 1.0, 0.82, 1.0))
	_draw_inward_sparks(center, radius, phase, 14 if is_pyro else 9)


func _draw_fire_projectile() -> void:
	var is_pyro := visual_key == "pyroblast_projectile"
	var center := Vector2(size.x * 0.68, size.y * 0.5)
	var radius := size.y * (0.27 if is_pyro else 0.23)
	var phase := progress * TAU * 4.0
	var tail_length := size.x * (0.62 if is_pyro else 0.52)

	for tail_index in range(5):
		var tail := PackedVector2Array()
		for step in range(12):
			var t := float(step) / 11.0
			var x := center.x - t * tail_length
			var y := center.y + sin(t * TAU * 1.4 + phase + float(tail_index)) * radius * (0.12 + t * 0.28)
			tail.append(Vector2(x, y))
		draw_polyline(
			tail,
			Color(1.0, 0.28 + float(tail_index) * 0.06, 0.03, 0.56 - float(tail_index) * 0.07),
			4.6 - float(tail_index) * 0.55,
			true
		)

	_draw_glow_circle(center, radius * 1.55, Color(1.0, 0.20, 0.02, 0.24))
	_draw_glow_circle(center, radius, Color(1.0, 0.58, 0.06, 0.98))
	draw_circle(center, radius * 0.43, Color(1.0, 1.0, 0.78, 1.0))
	for spark_index in range(10 if is_pyro else 6):
		var angle := phase + float(spark_index) * 2.399
		var spark_position := center + Vector2(cos(angle), sin(angle)) * radius * (1.1 + float(spark_index % 3) * 0.18)
		draw_circle(spark_position, 1.8 + float(spark_index % 2), Color(1.0, 0.68, 0.16, 0.88))


func _draw_fire_impact() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.35
	var is_pyro := visual_key == "pyroblast_impact"
	var burst := _ease_out(progress, 0.0, 0.62)
	var phase := progress * TAU * 2.2

	_draw_glow_circle(center, radius * (0.12 + burst * 0.28), Color(1.0, 0.92, 0.42, 0.96))
	for wave_index in range(3 if is_pyro else 2):
		draw_arc(
			center,
			radius * (0.24 + burst * (0.72 + float(wave_index) * 0.18)),
			0.0,
			TAU,
			64,
			Color(1.0, 0.40 + float(wave_index) * 0.10, 0.06, 0.72 - float(wave_index) * 0.18),
			4.2 - float(wave_index) * 0.8,
			true
		)

	for fragment_index in range(18 if is_pyro else 11):
		var angle := TAU * float(fragment_index) / float(18 if is_pyro else 11) + phase * 0.12
		var direction := Vector2(cos(angle), sin(angle))
		var fragment_start := center + direction * radius * (0.12 + burst * 0.30)
		var fragment_end := center + direction * radius * (0.28 + burst * (0.82 + float(fragment_index % 3) * 0.12))
		draw_line(
			fragment_start,
			fragment_end,
			Color(1.0, 0.48 + float(fragment_index % 3) * 0.12, 0.08, 0.82),
			3.2 if is_pyro else 2.4,
			true
		)


func _draw_arcane_array(
	center: Vector2,
	radius: float,
	phase: float,
	ring_count: int,
	alpha: float,
	color := ARCANE_EDGE
) -> void:
	if radius <= 0.1:
		return
	for ring_index in range(ring_count):
		var ring_radius := radius * (0.46 + float(ring_index) * 0.21)
		var direction := -1.0 if ring_index % 2 == 0 else 1.0
		var start := phase * direction + float(ring_index) * 0.34
		draw_arc(
			center,
			ring_radius,
			start,
			start + PI * (1.34 + float(ring_index % 2) * 0.32),
			56,
			Color(color.r, color.g, color.b, alpha * (0.88 - float(ring_index) * 0.12)),
			2.8 - float(ring_index) * 0.32,
			true
		)
		var tick_count := 8 + ring_index * 4
		for tick_index in range(tick_count):
			var angle := start + TAU * float(tick_index) / float(tick_count)
			var direction_vector := Vector2(cos(angle), sin(angle))
			var tick_length := radius * (0.045 + float(tick_index % 3) * 0.012)
			draw_line(
				center + direction_vector * (ring_radius - tick_length),
				center + direction_vector * (ring_radius + tick_length),
				Color(color.r, color.g, color.b, alpha * 0.72),
				1.4,
				true
			)

	var hexagon := _regular_polygon(center, radius * 0.68, 6, phase * 0.24, true)
	draw_polyline(hexagon, Color(color.r, color.g, color.b, alpha * 0.56), 1.8, true)
	var triangle := _regular_polygon(center, radius * 0.42, 3, -phase * 0.31 - PI * 0.5, true)
	draw_polyline(triangle, Color(0.78, 0.84, 1.0, alpha * 0.52), 1.5, true)


func _draw_school_node(center: Vector2, radius: float, color: Color, school_index: int) -> void:
	_draw_glow_circle(center, radius * 1.42, Color(color.r, color.g, color.b, 0.18))
	draw_circle(center, radius * 0.46, color)
	match school_index:
		0:
			var diamond := _regular_polygon(center, radius, 4, PI * 0.25, true)
			draw_polyline(diamond, color, 2.0, true)
		1:
			for flame_index in range(3):
				var angle := -PI * 0.5 + float(flame_index - 1) * 0.46
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * radius, color, 2.6, true)
		_:
			for crystal_index in range(3):
				var angle := TAU * float(crystal_index) / 3.0
				draw_line(
					center - Vector2(cos(angle), sin(angle)) * radius,
					center + Vector2(cos(angle), sin(angle)) * radius,
					color,
					2.0,
					true
				)


func _draw_orbiting_shards(
	center: Vector2,
	radius: float,
	count: int,
	phase: float,
	color: Color
) -> void:
	for shard_index in range(count):
		var angle := phase + TAU * float(shard_index) / float(maxi(count, 1))
		var shard_center := center + Vector2(cos(angle), sin(angle)) * radius * Vector2(1.0, 0.78)
		var tangent := Vector2(-sin(angle), cos(angle))
		var shard_length := 4.0 + float(shard_index % 3) * 2.0
		draw_line(
			shard_center - tangent * shard_length,
			shard_center + tangent * shard_length,
			color,
			1.8,
			true
		)


func _draw_water_droplets(center: Vector2, radius: float, phase: float, count: int) -> void:
	for droplet_index in range(count):
		var angle := phase * 0.42 + TAU * float(droplet_index) / float(maxi(count, 1))
		var orbit := radius * (0.74 + float(droplet_index % 4) * 0.10)
		var droplet_center := center + Vector2(cos(angle), sin(angle)) * orbit * Vector2(1.0, 0.78)
		draw_circle(
			droplet_center,
			2.0 + float(droplet_index % 3),
			Color(0.58, 0.94, 1.0, 0.82)
		)


func _draw_inward_sparks(center: Vector2, radius: float, phase: float, count: int) -> void:
	for spark_index in range(count):
		var travel := fmod(progress * 1.8 + float(spark_index) / float(maxi(count, 1)), 1.0)
		var angle := phase * 0.24 + float(spark_index) * 2.399
		var spark_radius := radius * lerpf(1.10, 0.24, travel)
		var spark_position := center + Vector2(cos(angle), sin(angle)) * spark_radius
		draw_circle(
			spark_position,
			1.8 + float(spark_index % 3),
			Color(1.0, 0.54 + float(spark_index % 2) * 0.20, 0.08, sin(travel * PI))
		)


func _draw_ice_crystal(center: Vector2, angle: float, radius: float) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	draw_line(center - direction * radius, center + direction * radius, ICE_EDGE, 1.8, true)
	draw_line(center - tangent * radius * 0.56, center + tangent * radius * 0.56, ICE_EDGE, 1.4, true)


func _draw_energy_beam(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, Color(color.r, color.g, color.b, color.a * 0.10), width * 5.0, true)
	draw_line(from, to, Color(color.r, color.g, color.b, color.a * 0.32), width * 2.4, true)
	draw_line(from, to, color, width, true)


func _draw_glow_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius * 2.2, Color(color.r, color.g, color.b, color.a * 0.08))
	draw_circle(center, radius * 1.45, Color(color.r, color.g, color.b, color.a * 0.20))
	draw_circle(center, radius, color)


func _draw_polyline_glow(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.10), width * 4.8, true)
	draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.32), width * 2.2, true)
	draw_polyline(points, color, width, true)


func _regular_polygon(
	center: Vector2,
	radius: float,
	point_count: int,
	rotation: float,
	closed: bool
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := rotation + TAU * float(point_index) / float(maxi(point_count, 1))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	if closed and not points.is_empty():
		points.append(points[0])
	return points


func _ease_out(value: float, from: float, to: float) -> float:
	var normalized := clampf(inverse_lerp(from, to, value), 0.0, 1.0)
	return 1.0 - pow(1.0 - normalized, 3.0)
