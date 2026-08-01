extends Control
class_name MonkeySpellVisual

# Procedural visual language for the Monkey Immortals. The provider owns
# placement and timing; this node renders deterministic key frames only.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const AMBER := Color(1.0, 0.66, 0.10, 0.94)
const GOLD := Color(1.0, 0.86, 0.28, 0.96)
const HOT_GOLD := Color(1.0, 0.96, 0.62, 1.0)
const CINNABAR := Color(0.92, 0.16, 0.07, 0.88)
const COPPER := Color(0.62, 0.29, 0.09, 0.92)
const DARK_COPPER := Color(0.25, 0.08, 0.025, 0.88)
const CLOUD_WHITE := Color(0.90, 0.98, 1.0, 0.88)
const CLOUD_CYAN := Color(0.54, 0.84, 0.90, 0.68)
const JADE := Color(0.30, 0.82, 0.56, 0.78)
const PEACH := Color(1.0, 0.38, 0.52, 0.88)
const PEACH_LIGHT := Color(1.0, 0.72, 0.72, 0.94)
const INK := Color(0.12, 0.045, 0.018, 0.84)

var visual_key := ""
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var source_point := Vector2.ZERO
var target_point := Vector2.ZERO
var strength := 1.0


func configure(
	key: String,
	local_source: Vector2,
	local_target: Vector2,
	visual_strength := 1.0
) -> void:
	visual_key = key
	source_point = local_source
	target_point = local_target
	strength = maxf(visual_strength, 0.1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	_draw_material_atmosphere()
	match visual_key:
		"fiery_eyes_golden_gaze":
			_draw_fiery_eyes()
		"somersault_cloud", "monkey_somersault_move":
			_draw_somersault_cloud()
		"body_beyond_body", "hair_clone_enter":
			_draw_body_beyond_body()
		"monkey_hair_clone_assist":
			_draw_hair_clone_assist()
		"bronze_head_iron_arms", "bronze_head_iron_arms_reflect":
			_draw_bronze_body()
		"immortal_peach":
			_draw_immortal_peach()
		"drive_spirit":
			_draw_drive_spirit()
		"drive_spirit_battlefield":
			_draw_drive_spirit_battlefield()
		"immobilize":
			_draw_immobilize()
		"gather_scatter_qi":
			_draw_gather_scatter_qi()
		"dragon_palace_treasure":
			_draw_dragon_palace_treasure()
		"heavenly_form":
			_draw_heavenly_form()
		"monkey_westward_move":
			_draw_westward()


func _draw_material_atmosphere() -> void:
	var life := sin(clampf(progress, 0.0, 1.0) * PI)
	if life <= 0.01:
		return
	var atmosphere_color := AMBER
	match visual_key:
		"somersault_cloud", "monkey_somersault_move", "monkey_westward_move":
			atmosphere_color = CLOUD_CYAN
		"bronze_head_iron_arms", "bronze_head_iron_arms_reflect":
			atmosphere_color = COPPER
		"immortal_peach":
			atmosphere_color = PEACH_LIGHT
		"drive_spirit", "drive_spirit_battlefield":
			atmosphere_color = JADE
		"gather_scatter_qi":
			atmosphere_color = CLOUD_WHITE
	var radius := _card_radius()
	var breath := 0.88 + sin(progress * TAU * 1.7) * 0.12
	Toolkit.draw_soft_ellipse(
		self,
		source_point,
		Vector2(radius * 0.72, radius * 0.46) * breath,
		Color(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b, life * 0.10),
		Color.TRANSPARENT,
		5,
		progress * 0.18
	)
	for mote_index in range(7):
		var angle := TAU * float(mote_index) / 7.0 + progress * (1.6 + float(mote_index % 3) * 0.18)
		var orbit := radius * (0.48 + float(mote_index % 2) * 0.20)
		var mote_point := source_point + Vector2(cos(angle), sin(angle) * 0.64) * orbit
		Toolkit.draw_mote(
			self,
			mote_point,
			radius * (0.025 + float(mote_index % 3) * 0.007),
			Color(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b, life * 0.30),
			progress * 9.0 + float(mote_index)
		)


func _draw_fiery_eyes() -> void:
	var reveal := _ease_out(progress, 0.0, 0.24)
	var scan := _ease_in_out(progress, 0.18, 0.76)
	var residue := 1.0 - _ease_out(progress, 0.78, 1.0)
	var eye_center := source_point
	var eye_radius := _card_radius() * (0.34 + reveal * 0.22)

	# Two opposing brush arcs form an eye without an arcane circle.
	var upper := _quadratic_points(
		eye_center - Vector2(eye_radius, 0.0),
		eye_center + Vector2(0.0, -eye_radius * 0.58),
		eye_center + Vector2(eye_radius, 0.0),
		24
	)
	var lower := _quadratic_points(
		eye_center - Vector2(eye_radius, 0.0),
		eye_center + Vector2(0.0, eye_radius * 0.58),
		eye_center + Vector2(eye_radius, 0.0),
		24
	)
	Toolkit.draw_soft_ellipse(
		self,
		eye_center,
		Vector2(eye_radius * 1.04, eye_radius * 0.48),
		Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, reveal * residue * 0.20),
		Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, reveal * residue * 0.24),
		6
	)
	_draw_brush_curve(upper, Color(AMBER.r, AMBER.g, AMBER.b, reveal * residue), 4.4)
	_draw_brush_curve(lower, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, reveal * residue * 0.86), 3.4)
	draw_circle(eye_center, eye_radius * 0.22 * reveal, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, 0.92 * residue))
	draw_circle(eye_center, eye_radius * 0.085 * reveal, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, 0.96 * residue))

	# The scan is a narrow readable band; three trailing lines show inspected
	# card backs without pretending that they have been flipped.
	var scan_x := lerpf(size.x * 0.03, size.x * 0.97, scan)
	var band_alpha := sin(scan * PI) * residue
	for band_index in range(5):
		var band_width := maxf(size.x * (0.045 - float(band_index) * 0.007), 3.0)
		var band_offset := float(band_index) * maxf(size.x * 0.009, 3.0)
		draw_rect(
			Rect2(Vector2(scan_x - band_offset - band_width * 0.5, size.y * 0.05), Vector2(band_width, size.y * 0.90)),
			Color(AMBER.r, HOT_GOLD.g, HOT_GOLD.b, band_alpha * (0.055 - float(band_index) * 0.008)),
			true
		)
	for trail_index in range(3):
		var x_offset := float(trail_index) * maxf(size.x * 0.012, 4.0)
		var line_color := Color(
			HOT_GOLD.r,
			lerpf(HOT_GOLD.g, AMBER.g, float(trail_index) / 3.0),
			AMBER.b,
			band_alpha * (0.72 - float(trail_index) * 0.18)
		)
		draw_line(Vector2(scan_x - x_offset, size.y * 0.06), Vector2(scan_x - x_offset, size.y * 0.94), line_color, 2.5 - float(trail_index) * 0.5, true)

	for mark_index in range(7):
		var mark_y := size.y * (0.13 + float(mark_index) * 0.12)
		var mark_phase := clampf(1.0 - absf(scan_x - size.x * (0.16 + float(mark_index % 5) * 0.17)) / maxf(size.x * 0.18, 1.0), 0.0, 1.0)
		if mark_phase <= 0.01:
			continue
		var mark_center := Vector2(scan_x - size.x * 0.055, mark_y)
		draw_arc(mark_center, 5.0 + mark_phase * 5.0, -PI * 0.82, PI * 0.82, 14, Color(AMBER.r, AMBER.g, AMBER.b, mark_phase * residue * 0.62), 1.4, true)


func _draw_somersault_cloud() -> void:
	var gather := _ease_out(progress, 0.0, 0.22)
	var travel := _ease_in_out(progress, 0.18, 0.70)
	var arrival := _ease_out(progress, 0.62, 0.88)
	var fade := 1.0 - _ease_out(progress, 0.86, 1.0)
	var has_path := source_point.distance_to(target_point) > 8.0
	var cloud_center := source_point.lerp(target_point, travel) if has_path else target_point
	var cloud_radius := _card_radius() * (0.34 + gather * 0.16)

	if has_path:
		var path_direction := (target_point - source_point).normalized()
		var path_normal := path_direction.orthogonal()
		var trail := PackedVector2Array()
		for step in range(24):
			var t := float(step) / 23.0
			if t > travel:
				break
			trail.append(source_point.lerp(target_point, t) + path_normal * sin(t * PI * 3.0) * cloud_radius * 0.12)
		_draw_brush_curve(trail, Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, fade * 0.50), 6.0)
		_draw_brush_curve(trail, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, fade * 0.34), 1.5)
		_draw_cloud(source_point, cloud_radius * (1.0 - travel) * 0.75, fade * (1.0 - travel))

	_draw_cloud(cloud_center, cloud_radius, fade)
	if arrival > 0.0:
		for ring_index in range(3):
			var ring_radius := cloud_radius * (0.48 + arrival * (0.54 + float(ring_index) * 0.20))
			draw_arc(target_point, ring_radius, -PI * 0.15, PI * 1.65, 38, Color(GOLD.r, GOLD.g, GOLD.b, fade * arrival * (0.56 - float(ring_index) * 0.12)), 2.0, true)


func _draw_body_beyond_body() -> void:
	var gather := _ease_out(progress, 0.0, 0.20)
	var split := _ease_out(progress, 0.16, 0.58)
	var dispatch := _ease_in_out(progress, 0.48, 0.86)
	var fade := 1.0 - _ease_out(progress, 0.86, 1.0)
	var radius := _card_radius()
	var hair_start := source_point + Vector2(-radius * 0.12, radius * 0.12)
	var dispatch_target := target_point
	if source_point.distance_to(target_point) <= 8.0:
		dispatch_target = source_point + Vector2(radius * 1.15, -radius * 0.88)
	var direction := (dispatch_target - hair_start).normalized()
	var tangent := direction.orthogonal()

	for hair_index in range(7):
		var side := float(hair_index - 3)
		var root := hair_start + tangent * side * radius * 0.045
		var tip := root + direction.rotated(side * 0.055) * radius * (0.34 + split * 0.36)
		var hair_curve := _quadratic_points(root, root + tangent * side * radius * 0.05 - direction * radius * 0.08, tip, 12)
		_draw_brush_curve(hair_curve, Color(GOLD.r, GOLD.g, GOLD.b, gather * fade * (0.74 - absf(side) * 0.06)), 2.0)

	var clone_center := hair_start.lerp(dispatch_target, dispatch)
	var clone_alpha := sin(split * PI * 0.72) * fade
	_draw_monkey_silhouette(clone_center, radius * (0.24 + split * 0.12), clone_alpha)
	# A card-shaped imprint makes the graveyard-to-hand result legible.
	var imprint_size := Vector2(radius * 0.42, radius * 0.58)
	var imprint_rect := Rect2(clone_center - imprint_size * 0.5, imprint_size)
	draw_rect(imprint_rect, Color(AMBER.r, AMBER.g, AMBER.b, clone_alpha * 0.12), true)
	draw_rect(imprint_rect, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, clone_alpha * 0.66), false, 1.6, true)


func _draw_hair_clone_assist() -> void:
	var lock_phase := _ease_out(progress, 0.0, 0.22)
	var strike_phase := _ease_in_out(progress, 0.16, 0.62)
	var impact_phase := _ease_out(progress, 0.42, 0.80)
	var fade := 1.0 - _ease_out(progress, 0.84, 1.0)
	var radius := _card_radius()
	var cast_vector := target_point - source_point
	if cast_vector.length_squared() <= 1.0:
		return
	var direction := cast_vector.normalized()
	var normal := direction.orthogonal()

	# The normal melee lunge already communicates travel. This overlay remains
	# local to the target so a clone strike reads as a physical follow-up rather
	# than a second ranged projectile.
	for lock_index in range(3):
		var lock_radius := radius * (0.18 + float(lock_index) * 0.075 + impact_phase * 0.08)
		var lock_start := -PI * 0.18 + float(lock_index) * 0.64
		draw_arc(
			target_point,
			lock_radius,
			lock_start,
			lock_start + PI * 0.94,
			24,
			Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, lock_phase * fade * (0.68 - float(lock_index) * 0.12)),
			1.8,
			true
		)

	for stroke_index in range(3):
		var stroke_offset := (float(stroke_index) - 1.0) * radius * 0.10
		var stroke_start := target_point - direction * radius * 0.42 + normal * stroke_offset
		var stroke_end := target_point + direction * radius * (0.12 + strike_phase * 0.24) + normal * stroke_offset
		var stroke_curve := _quadratic_points(
			stroke_start,
			target_point - normal * radius * (0.12 - float(stroke_index) * 0.08),
			stroke_end,
			16
		)
		_draw_brush_curve(
			stroke_curve,
			Color(GOLD.r, GOLD.g, GOLD.b, strike_phase * fade * (0.86 - float(stroke_index) * 0.12)),
			4.0 - float(stroke_index) * 0.65
		)
		draw_polyline(
			stroke_curve,
			Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, strike_phase * fade * 0.46),
			1.2,
			true
		)

	if impact_phase > 0.0:
		for impact_index in range(5):
			var impact_angle := direction.angle() + PI + (-0.62 + float(impact_index) * 0.25)
			var impact_direction := Vector2.from_angle(impact_angle)
			draw_line(
				target_point,
				target_point + impact_direction * radius * (0.12 + impact_phase * 0.28),
				Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, (1.0 - impact_phase) * fade * 0.86),
				2.0,
				true
			)


func _draw_bronze_body() -> void:
	var forge := _ease_out(progress, 0.0, 0.28)
	var impact := _ease_out(progress, 0.32, 0.66)
	var rebound := _ease_in_out(progress, 0.54, 0.88)
	var fade := 1.0 - _ease_out(progress, 0.88, 1.0)
	var is_reflection := visual_key == "bronze_head_iron_arms_reflect"
	var center := source_point if is_reflection else target_point
	var radius := _card_radius() * (0.70 + forge * 0.10)

	draw_circle(center, radius * 0.78, Color(COPPER.r, COPPER.g, COPPER.b, forge * fade * 0.13))
	for ring_index in range(3):
		var ring_radius := radius * (0.54 + float(ring_index) * 0.16 + impact * 0.08)
		var start_angle := -PI * 0.22 + float(ring_index) * 0.37
		draw_arc(center, ring_radius, start_angle, start_angle + PI * 1.52, 42, Color(COPPER.r, lerpf(COPPER.g, GOLD.g, 0.35), GOLD.b, forge * fade * (0.70 - float(ring_index) * 0.12)), 3.8 - float(ring_index) * 0.6, true)

	for plate_index in range(8):
		var angle := TAU * float(plate_index) / 8.0 + progress * 0.18
		var radial := Vector2.from_angle(angle)
		var plate_center := center + radial * radius * 0.64
		var tangent := radial.orthogonal()
		draw_line(plate_center - tangent * radius * 0.09, plate_center + tangent * radius * 0.09, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, forge * fade * 0.82), 2.2, true)
		draw_circle(plate_center, radius * 0.025, Color(DARK_COPPER.r, DARK_COPPER.g, DARK_COPPER.b, forge * fade))

	if impact > 0.0:
		var impact_center := center + Vector2(-radius * 0.56, -radius * 0.08)
		for spark_index in range(7):
			var spark_direction := Vector2.from_angle(-PI * 0.70 + float(spark_index) * PI * 0.20)
			draw_line(impact_center, impact_center + spark_direction * radius * (0.18 + impact * 0.28), Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, fade * (1.0 - impact) * 0.88), 1.8, true)

	if is_reflection and rebound > 0.0 and source_point.distance_to(target_point) > 8.0:
		var reverse_curve := _quadratic_points(source_point, source_point.lerp(target_point, 0.5) + Vector2(0.0, -radius * 0.42), target_point, 26)
		_draw_brush_curve(reverse_curve, Color(AMBER.r, AMBER.g, AMBER.b, sin(rebound * PI) * fade * 0.82), 4.2)


func _draw_immortal_peach() -> void:
	var bloom := _ease_out(progress, 0.0, 0.28)
	var infuse := _ease_in_out(progress, 0.24, 0.76)
	var fade := 1.0 - _ease_out(progress, 0.82, 1.0)
	var center := source_point.lerp(target_point, infuse * 0.72)
	var radius := _card_radius() * (0.30 + bloom * 0.12)
	_draw_peach(center, radius, bloom * fade)

	var stat_left := target_point + Vector2(-_card_radius() * 0.58, _card_radius() * 0.62)
	var stat_right := target_point + Vector2(_card_radius() * 0.58, _card_radius() * 0.62)
	for stat_index in range(2):
		var stat_target := stat_left if stat_index == 0 else stat_right
		var control := center.lerp(stat_target, 0.5) + Vector2((float(stat_index) - 0.5) * radius * 0.28, -radius * 0.46)
		var stat_curve := _quadratic_points(center, control, center.lerp(stat_target, infuse), 18)
		var stream_color := AMBER if stat_index == 0 else PEACH_LIGHT
		_draw_brush_curve(stat_curve, Color(stream_color.r, stream_color.g, stream_color.b, infuse * fade * 0.74), 3.0)

	for leaf_index in range(5):
		var leaf_phase := fmod(progress * 0.58 + float(leaf_index) * 0.19, 1.0)
		var leaf_angle := -PI * 0.75 + float(leaf_index) * PI * 0.34
		var leaf_point := target_point + Vector2.from_angle(leaf_angle) * radius * (0.58 + leaf_phase * 1.10)
		draw_circle(leaf_point, 2.0 + float(leaf_index % 2), Color(JADE.r, JADE.g, JADE.b, sin(leaf_phase * PI) * fade * 0.62))


func _draw_drive_spirit() -> void:
	var gather := _ease_out(progress, 0.0, 0.20)
	var sweep := _ease_in_out(progress, 0.16, 0.70)
	var disperse := _ease_out(progress, 0.58, 0.92)
	var fade := 1.0 - _ease_out(progress, 0.88, 1.0)
	var direction := (target_point - source_point).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.RIGHT
	var normal := direction.orthogonal()
	var radius := _card_radius()
	var sweep_end := source_point.lerp(target_point, sweep)
	var control := source_point.lerp(target_point, 0.48) - normal * radius * 0.46
	var wind_curve := _quadratic_points(source_point, control, sweep_end, 28)
	_draw_brush_curve(wind_curve, Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, gather * fade * 0.74), 8.0)
	_draw_brush_curve(wind_curve, Color(GOLD.r, GOLD.g, GOLD.b, gather * fade * 0.82), 2.4)

	for fragment_index in range(8):
		var angle := TAU * float(fragment_index) / 8.0 + progress * 0.36
		var fragment_direction := Vector2.from_angle(angle)
		var fragment_start := target_point + fragment_direction * radius * 0.24
		var fragment_end := fragment_start + fragment_direction * radius * disperse * (0.46 + float(fragment_index % 3) * 0.12)
		draw_line(fragment_start, fragment_end, Color(AMBER.r, AMBER.g, AMBER.b, disperse * fade * 0.72), 2.2, true)
		draw_line(fragment_end, fragment_end + fragment_direction.orthogonal() * radius * 0.06, Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, disperse * fade * 0.54), 1.2, true)


func _draw_drive_spirit_battlefield() -> void:
	var gather := _ease_out(progress, 0.0, 0.18)
	var sweep := _ease_in_out(progress, 0.14, 0.76)
	var break_phase := _ease_out(progress, 0.48, 0.86)
	var fade := 1.0 - _ease_out(progress, 0.86, 1.0)
	var radius := _card_radius()
	var battlefield_radius := maxf(size.x, size.y) * (0.08 + sweep * 0.82)

	# The source gathers the spell, then incomplete brush rings sweep across the
	# board. Their gaps keep the effect airy and distinct from holy/arcane circles.
	for source_ring_index in range(3):
		var source_ring_radius := radius * (0.34 + float(source_ring_index) * 0.18 + gather * 0.16)
		var source_start := -PI * 0.88 + float(source_ring_index) * 0.46
		draw_arc(
			source_point,
			source_ring_radius,
			source_start,
			source_start + PI * 1.34,
			38,
			Color(GOLD.r, GOLD.g, GOLD.b, gather * fade * (0.78 - float(source_ring_index) * 0.14)),
			3.4 - float(source_ring_index) * 0.5,
			true
		)

	for wave_index in range(4):
		var lag := float(wave_index) * 0.12
		var wave_progress := clampf((sweep - lag) / maxf(1.0 - lag, 0.01), 0.0, 1.0)
		if wave_progress <= 0.0:
			continue
		var wave_radius := battlefield_radius * (0.72 + float(wave_index) * 0.09)
		var wave_start := -PI * 0.82 + float(wave_index) * 0.58
		var wave_alpha := sin(wave_progress * PI) * fade
		draw_arc(
			source_point,
			wave_radius,
			wave_start,
			wave_start + PI * 1.42,
			72,
			Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, wave_alpha * 0.46),
			8.0 - float(wave_index) * 0.8,
			true
		)
		draw_arc(
			source_point,
			wave_radius * 0.985,
			wave_start + 0.05,
			wave_start + PI * 1.28,
			72,
			Color(GOLD.r, GOLD.g, GOLD.b, wave_alpha * 0.72),
			2.2,
			true
		)

	# Fragments use two palettes: dark gold for hostile blessings being broken,
	# and pale cyan for friendly afflictions being carried away.
	for fragment_index in range(18):
		var angle := TAU * float(fragment_index) / 18.0 + float(fragment_index % 3) * 0.17
		var distance_factor := 0.28 + float((fragment_index * 7) % 13) / 16.0
		var fragment_center := source_point + Vector2.from_angle(angle) * battlefield_radius * distance_factor
		var outward := Vector2.from_angle(angle + sin(float(fragment_index)) * 0.18)
		var fragment_length := radius * (0.12 + float(fragment_index % 4) * 0.035) * break_phase
		var fragment_color := AMBER if fragment_index % 2 == 0 else CLOUD_WHITE
		var fragment_alpha := break_phase * fade * (0.58 if fragment_index % 2 == 0 else 0.44)
		draw_line(
			fragment_center - outward * fragment_length * 0.35,
			fragment_center + outward * fragment_length,
			Color(fragment_color.r, fragment_color.g, fragment_color.b, fragment_alpha),
			2.2 if fragment_index % 2 == 0 else 1.5,
			true
		)
		draw_line(
			fragment_center,
			fragment_center + outward.orthogonal() * fragment_length * 0.46,
			Color(fragment_color.r, fragment_color.g, fragment_color.b, fragment_alpha * 0.72),
			1.2,
			true
		)


func _draw_immobilize() -> void:
	var descend := _ease_out(progress, 0.0, 0.30)
	var lock := _ease_out(progress, 0.24, 0.62)
	var fade := 1.0 - _ease_out(progress, 0.88, 1.0)
	var center := target_point + Vector2(0.0, lerpf(-_card_radius() * 0.70, 0.0, descend))
	var radius := _card_radius() * 0.72
	var seal_rect := Rect2(center - Vector2(radius * 0.52, radius * 0.62), Vector2(radius * 1.04, radius * 1.24))

	draw_rect(seal_rect, Color(AMBER.r, AMBER.g, AMBER.b, descend * fade * 0.10), true)
	draw_rect(seal_rect, Color(GOLD.r, GOLD.g, GOLD.b, descend * fade * 0.88), false, 2.8, true)
	for corner_index in range(4):
		var corner := Vector2(
			seal_rect.position.x if corner_index % 2 == 0 else seal_rect.end.x,
			seal_rect.position.y if corner_index < 2 else seal_rect.end.y
		)
		var inward := (center - corner).normalized()
		draw_line(corner, corner + inward * radius * (0.18 + lock * 0.12), Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, lock * fade), 4.0, true)

	for script_index in range(9):
		var angle := progress * 0.24 + TAU * float(script_index) / 9.0
		var mark_center := center + Vector2.from_angle(angle) * radius * 0.72
		var tangent := Vector2.from_angle(angle).orthogonal()
		draw_line(mark_center - tangent * radius * 0.055, mark_center + tangent * radius * 0.055, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, lock * fade * 0.74), 1.7, true)

	_draw_center_character(center, String.chr(23450), radius * 0.72, lock * fade)


func _draw_gather_scatter_qi() -> void:
	var scatter := _ease_out(progress, 0.0, 0.44)
	var veil := _ease_in_out(progress, 0.28, 0.74)
	var reform := _ease_out(progress, 0.72, 1.0)
	var center := target_point
	var radius := _card_radius()

	for wisp_index in range(12):
		var angle := TAU * float(wisp_index) / 12.0 + sin(float(wisp_index) * 1.7) * 0.22
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var wisp_start := center + direction * radius * 0.18
		var wisp_end := center + direction * radius * (0.26 + scatter * (0.72 + float(wisp_index % 3) * 0.14))
		var wisp_control := wisp_start.lerp(wisp_end, 0.52) + tangent * radius * sin(progress * TAU + float(wisp_index)) * 0.16
		var wisp_curve := _quadratic_points(wisp_start, wisp_control, wisp_end, 14)
		var wisp_color := CLOUD_WHITE if wisp_index % 3 != 0 else GOLD
		_draw_brush_curve(wisp_curve, Color(wisp_color.r, wisp_color.g, wisp_color.b, veil * (1.0 - reform * 0.74) * 0.66), 3.2)

	var outline_alpha := (1.0 - scatter * 0.72) + reform * 0.36
	var outline_rect := Rect2(center - Vector2(radius * 0.58, radius * 0.78), Vector2(radius * 1.16, radius * 1.56))
	draw_rect(outline_rect, Color(GOLD.r, GOLD.g, GOLD.b, outline_alpha * 0.46), false, 2.0, true)
	for cloud_index in range(4):
		var cloud_angle := TAU * float(cloud_index) / 4.0 + progress * 0.34
		_draw_cloud(center + Vector2.from_angle(cloud_angle) * radius * 0.72, radius * 0.16, veil * 0.46)


func _draw_dragon_palace_treasure() -> void:
	var reveal := _ease_out(progress, 0.0, 0.26)
	var equip := _ease_in_out(progress, 0.20, 0.72)
	var fade := 1.0 - _ease_out(progress, 0.84, 1.0)
	var center := target_point
	var radius := _card_radius() * 0.82

	# Sea-jade undertone separates Dragon Palace artifacts from generic gold.
	for wave_index in range(3):
		var wave_radius := radius * (0.44 + float(wave_index) * 0.18 + equip * 0.10)
		draw_arc(center, wave_radius, PI * 0.08, PI * 0.92, 32, Color(0.24, 0.76, 0.88, reveal * fade * (0.48 - float(wave_index) * 0.10)), 2.0, true)

	var emblem_centers := [
		center + Vector2(-radius * 0.62, -radius * 0.50),
		center + Vector2(radius * 0.62, -radius * 0.50),
		center + Vector2(-radius * 0.62, radius * 0.50),
		center + Vector2(radius * 0.62, radius * 0.50),
	]
	_draw_staff_emblem(emblem_centers[0], radius * 0.28, reveal * fade)
	_draw_crown_emblem(emblem_centers[1], radius * 0.25, reveal * fade)
	_draw_armor_emblem(emblem_centers[2], radius * 0.25, reveal * fade)
	_draw_boot_emblem(emblem_centers[3], radius * 0.25, reveal * fade)

	for stream_index in range(4):
		var stream_start: Vector2 = emblem_centers[stream_index]
		var stream_end := stream_start.lerp(center, equip)
		draw_line(stream_start, stream_end, Color(GOLD.r, GOLD.g, GOLD.b, equip * fade * 0.68), 2.2, true)
	draw_arc(center, radius * (0.30 + equip * 0.12), 0.0, TAU, 48, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, equip * fade * 0.82), 3.0, true)


func _draw_heavenly_form() -> void:
	var summon := _ease_out(progress, 0.0, 0.30)
	var rise := _ease_out(progress, 0.18, 0.66)
	var settle := _ease_out(progress, 0.62, 0.90)
	var fade := 1.0 - _ease_out(progress, 0.90, 1.0)
	var center := target_point
	var radius := _card_radius() * 1.18
	var silhouette_center := center + Vector2(0.0, radius * lerpf(0.58, -0.10, rise))

	for cloud_index in range(6):
		var side := float(cloud_index - 2) - 0.5
		var cloud_center := center + Vector2(side * radius * 0.32, radius * (0.72 + sin(float(cloud_index)) * 0.08))
		_draw_cloud(cloud_center, radius * (0.16 + float(cloud_index % 2) * 0.04), summon * fade * 0.62)

	# Large avatar remains a silhouette behind the card, preserving board UI.
	var head_center := silhouette_center + Vector2(0.0, -radius * 0.50)
	draw_circle(head_center, radius * 0.17, Color(AMBER.r, AMBER.g, AMBER.b, rise * fade * 0.22))
	draw_arc(head_center, radius * 0.18, 0.0, TAU, 40, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, rise * fade * 0.80), 3.0, true)
	var shoulders := PackedVector2Array([
		silhouette_center + Vector2(-radius * 0.72, -radius * 0.16),
		silhouette_center + Vector2(-radius * 0.34, -radius * 0.38),
		silhouette_center + Vector2(0.0, -radius * 0.28),
		silhouette_center + Vector2(radius * 0.34, -radius * 0.38),
		silhouette_center + Vector2(radius * 0.72, -radius * 0.16),
	])
	_draw_brush_curve(shoulders, Color(GOLD.r, GOLD.g, GOLD.b, rise * fade * 0.84), 7.0)
	draw_line(silhouette_center + Vector2(-radius * 0.30, -radius * 0.18), silhouette_center + Vector2(-radius * 0.46, radius * 0.58), Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, rise * fade * 0.48), 6.0, true)
	draw_line(silhouette_center + Vector2(radius * 0.30, -radius * 0.18), silhouette_center + Vector2(radius * 0.46, radius * 0.58), Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, rise * fade * 0.48), 6.0, true)

	var staff_start := silhouette_center + Vector2(-radius * 0.84, radius * 0.58)
	var staff_end := silhouette_center + Vector2(radius * 0.82, -radius * 0.66)
	_draw_glow_line(staff_start, staff_end, Color(AMBER.r, AMBER.g, AMBER.b, rise * fade * 0.90), 7.0)
	if settle > 0.0:
		for shock_index in range(3):
			draw_arc(center, radius * (0.38 + settle * (0.32 + float(shock_index) * 0.18)), -PI * 0.92, -PI * 0.08, 32, Color(GOLD.r, GOLD.g, GOLD.b, (1.0 - settle) * fade * (0.72 - float(shock_index) * 0.14)), 2.6, true)


func _draw_westward() -> void:
	var charge := _ease_out(progress, 0.0, 0.20)
	var travel := _ease_in_out(progress, 0.14, 0.76)
	var fade := 1.0 - _ease_out(progress, 0.82, 1.0)
	var direction := (target_point - source_point).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.LEFT
	var normal := direction.orthogonal()
	var current_point := source_point.lerp(target_point, travel)
	var radius := _card_radius()
	var trail := _quadratic_points(
		source_point,
		source_point.lerp(target_point, 0.5) - normal * radius * 0.18,
		current_point,
		24
	)
	_draw_brush_curve(trail, Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, charge * fade * 0.76), 7.0)
	_draw_brush_curve(trail, Color(GOLD.r, GOLD.g, GOLD.b, charge * fade * 0.54), 1.8)
	var arrow_tip := current_point + direction * radius * 0.18
	var arrow_base := current_point - direction * radius * 0.12
	draw_line(arrow_base, arrow_tip, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, fade), 3.0, true)
	draw_line(arrow_tip, arrow_tip - direction.rotated(0.65) * radius * 0.16, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, fade), 3.0, true)
	draw_line(arrow_tip, arrow_tip - direction.rotated(-0.65) * radius * 0.16, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, fade), 3.0, true)


func _draw_cloud(cloud_center: Vector2, cloud_radius: float, alpha: float) -> void:
	if cloud_radius <= 0.1 or alpha <= 0.01:
		return
	var breath := 0.94 + sin(progress * TAU * 1.35) * 0.06
	Toolkit.draw_soft_ellipse(
		self,
		cloud_center + Vector2(0.0, cloud_radius * 0.06),
		Vector2(cloud_radius * 0.92, cloud_radius * 0.44) * breath,
		Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, alpha * 0.24),
		Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.26),
		7
	)
	for curl_index in range(5):
		var angle := TAU * float(curl_index) / 5.0 + progress * (0.34 + float(curl_index) * 0.025)
		var curl_center := cloud_center + Vector2(cos(angle), sin(angle) * 0.52) * cloud_radius * 0.42
		var curl_radius := cloud_radius * (0.32 + float(curl_index % 2) * 0.08)
		Toolkit.draw_soft_disc(
			self,
			curl_center,
			curl_radius,
			Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.18),
			Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.20),
			5
		)
		Toolkit.draw_arc_ribbon(
			self,
			curl_center,
			curl_radius,
			angle - PI * 0.82,
			angle + PI * 0.68,
			maxf(cloud_radius * 0.075, 1.8),
			Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.54),
			Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, alpha * 0.24),
			Color(1.0, 1.0, 1.0, alpha * 0.34),
			cloud_radius * 0.24,
			20,
			true,
			true,
			float(curl_index)
		)
	var cloud_base := PackedVector2Array([
		cloud_center - Vector2(cloud_radius * 0.78, -cloud_radius * 0.05),
		cloud_center - Vector2(cloud_radius * 0.24, 0.0),
		cloud_center + Vector2(cloud_radius * 0.26, cloud_radius * 0.01),
		cloud_center + Vector2(cloud_radius * 0.78, -cloud_radius * 0.04),
	])
	Toolkit.draw_ribbon(self, cloud_base, maxf(cloud_radius * 0.055, 1.6), Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, alpha * 0.34), Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.16), Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.28), cloud_radius * 0.18, true, true, progress * 2.0)


func _draw_peach(peach_center: Vector2, peach_radius: float, alpha: float) -> void:
	if peach_radius <= 0.1 or alpha <= 0.01:
		return
	var points := PackedVector2Array()
	for point_index in range(36):
		var angle := TAU * float(point_index) / 36.0 - PI * 0.5
		var lobe := 1.0 + 0.14 * cos(angle * 2.0) - 0.08 * sin(angle)
		points.append(peach_center + Vector2(cos(angle), sin(angle)) * peach_radius * lobe * Vector2(0.84, 1.0))
	draw_colored_polygon(points, Color(PEACH.r, PEACH.g, PEACH.b, alpha * 0.38))
	draw_polyline(_closed(points), Color(PEACH_LIGHT.r, PEACH_LIGHT.g, PEACH_LIGHT.b, alpha * 0.86), 2.4, true)
	draw_arc(peach_center + Vector2(peach_radius * 0.14, -peach_radius * 0.05), peach_radius * 0.52, -PI * 0.72, PI * 0.24, 22, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, alpha * 0.52), 1.8, true)
	var stem_top := peach_center + Vector2(0.0, -peach_radius * 1.02)
	draw_line(peach_center + Vector2(0.0, -peach_radius * 0.72), stem_top, Color(GOLD.r, GOLD.g, GOLD.b, alpha), 2.2, true)
	draw_line(stem_top, stem_top + Vector2(peach_radius * 0.44, -peach_radius * 0.22), Color(JADE.r, JADE.g, JADE.b, alpha * 0.88), 3.0, true)


func _draw_monkey_silhouette(silhouette_center: Vector2, silhouette_radius: float, alpha: float) -> void:
	if silhouette_radius <= 0.1 or alpha <= 0.01:
		return
	draw_circle(silhouette_center + Vector2(0.0, -silhouette_radius * 0.68), silhouette_radius * 0.22, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.44))
	draw_arc(silhouette_center + Vector2(0.0, -silhouette_radius * 0.68), silhouette_radius * 0.24, 0.0, TAU, 26, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, alpha * 0.82), 2.0, true)
	var body := PackedVector2Array([
		silhouette_center + Vector2(-silhouette_radius * 0.42, -silhouette_radius * 0.36),
		silhouette_center + Vector2(0.0, -silhouette_radius * 0.48),
		silhouette_center + Vector2(silhouette_radius * 0.42, -silhouette_radius * 0.36),
		silhouette_center + Vector2(silhouette_radius * 0.28, silhouette_radius * 0.50),
		silhouette_center + Vector2(-silhouette_radius * 0.28, silhouette_radius * 0.50),
	])
	draw_colored_polygon(body, Color(AMBER.r, AMBER.g, AMBER.b, alpha * 0.16))
	draw_polyline(_closed(body), Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.76), 2.0, true)


func _draw_staff_emblem(emblem_center: Vector2, emblem_radius: float, alpha: float) -> void:
	var staff_direction := Vector2(0.58, -0.82).normalized()
	draw_line(emblem_center - staff_direction * emblem_radius, emblem_center + staff_direction * emblem_radius, Color(AMBER.r, AMBER.g, AMBER.b, alpha), 4.0, true)
	draw_line(emblem_center - staff_direction * emblem_radius, emblem_center - staff_direction * emblem_radius * 0.70, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, alpha), 6.0, true)
	draw_line(emblem_center + staff_direction * emblem_radius * 0.70, emblem_center + staff_direction * emblem_radius, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, alpha), 6.0, true)


func _draw_crown_emblem(emblem_center: Vector2, emblem_radius: float, alpha: float) -> void:
	var crown := PackedVector2Array([
		emblem_center + Vector2(-emblem_radius, emblem_radius * 0.42),
		emblem_center + Vector2(-emblem_radius * 0.70, -emblem_radius * 0.56),
		emblem_center + Vector2(-emblem_radius * 0.22, emblem_radius * 0.02),
		emblem_center + Vector2(0.0, -emblem_radius * 0.82),
		emblem_center + Vector2(emblem_radius * 0.22, emblem_radius * 0.02),
		emblem_center + Vector2(emblem_radius * 0.70, -emblem_radius * 0.56),
		emblem_center + Vector2(emblem_radius, emblem_radius * 0.42),
	])
	draw_colored_polygon(crown, Color(0.52, 0.18, 0.62, alpha * 0.22))
	draw_polyline(crown, Color(GOLD.r, GOLD.g, GOLD.b, alpha * 0.88), 2.2, true)


func _draw_armor_emblem(emblem_center: Vector2, emblem_radius: float, alpha: float) -> void:
	var armor := PackedVector2Array([
		emblem_center + Vector2(0.0, -emblem_radius),
		emblem_center + Vector2(emblem_radius * 0.82, -emblem_radius * 0.52),
		emblem_center + Vector2(emblem_radius * 0.62, emblem_radius * 0.62),
		emblem_center + Vector2(0.0, emblem_radius),
		emblem_center + Vector2(-emblem_radius * 0.62, emblem_radius * 0.62),
		emblem_center + Vector2(-emblem_radius * 0.82, -emblem_radius * 0.52),
	])
	draw_colored_polygon(armor, Color(COPPER.r, COPPER.g, COPPER.b, alpha * 0.26))
	draw_polyline(_closed(armor), Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, alpha * 0.84), 2.2, true)


func _draw_boot_emblem(emblem_center: Vector2, emblem_radius: float, alpha: float) -> void:
	var boot := PackedVector2Array([
		emblem_center + Vector2(-emblem_radius * 0.54, -emblem_radius),
		emblem_center + Vector2(emblem_radius * 0.08, -emblem_radius * 0.72),
		emblem_center + Vector2(emblem_radius * 0.10, emblem_radius * 0.30),
		emblem_center + Vector2(emblem_radius, emblem_radius * 0.44),
		emblem_center + Vector2(emblem_radius * 0.74, emblem_radius),
		emblem_center + Vector2(-emblem_radius * 0.52, emblem_radius * 0.72),
	])
	draw_colored_polygon(boot, Color(CLOUD_CYAN.r, CLOUD_CYAN.g, CLOUD_CYAN.b, alpha * 0.22))
	draw_polyline(_closed(boot), Color(CLOUD_WHITE.r, CLOUD_WHITE.g, CLOUD_WHITE.b, alpha * 0.84), 2.2, true)


func _draw_center_character(character_center: Vector2, character: String, character_width: float, alpha: float) -> void:
	var font := get_theme_default_font()
	if font == null or character == "" or alpha <= 0.01:
		return
	var font_size := maxi(int(character_width), 20)
	var text_size := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var text_origin := character_center - text_size * 0.5
	text_origin.y += text_size.y * 0.82
	draw_string(font, text_origin + Vector2(2.0, 2.0), character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(INK.r, INK.g, INK.b, alpha * 0.82))
	draw_string(font, text_origin, character, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, alpha))


func _draw_glow_line(from_point: Vector2, to_point: Vector2, line_color: Color, line_width: float) -> void:
	Toolkit.draw_ribbon(
		self,
		PackedVector2Array([from_point, to_point]),
		line_width,
		line_color,
		Color(INK.r, INK.g, INK.b, line_color.a * 0.30),
		Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, line_color.a * 0.42),
		line_width * 4.5,
		true,
		true,
		progress * 5.0
	)


func _draw_brush_curve(points: PackedVector2Array, line_color: Color, line_width: float) -> void:
	if points.size() < 2 or line_color.a <= 0.01:
		return
	Toolkit.draw_ribbon(
		self,
		points,
		line_width,
		line_color,
		Color(INK.r, INK.g, INK.b, line_color.a * 0.28),
		Color(HOT_GOLD.r, HOT_GOLD.g, HOT_GOLD.b, line_color.a * 0.34),
		line_width * 4.2,
		true,
		true,
		progress * 4.0 + float(points.size()) * 0.13
	)


func _quadratic_points(from_point: Vector2, control_point: Vector2, to_point: Vector2, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count := maxi(point_count, 2)
	for point_index in range(safe_count):
		var t := float(point_index) / float(safe_count - 1)
		var inverse := 1.0 - t
		points.append(inverse * inverse * from_point + 2.0 * inverse * t * control_point + t * t * to_point)
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty() and result[0] != result[result.size() - 1]:
		result.append(result[0])
	return result


func _card_radius() -> float:
	return maxf(minf(size.x, size.y) * 0.18 * strength, 18.0)


func _ease_out(value: float, from_value: float, to_value: float) -> float:
	var normalized := clampf(inverse_lerp(from_value, to_value, value), 0.0, 1.0)
	return 1.0 - pow(1.0 - normalized, 3.0)


func _ease_in_out(value: float, from_value: float, to_value: float) -> float:
	var normalized := clampf(inverse_lerp(from_value, to_value, value), 0.0, 1.0)
	return normalized * normalized * (3.0 - 2.0 * normalized)
