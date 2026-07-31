extends Control

# Procedural visual language for Miao gu arts. Animation providers own timing
# and placement; this canvas only draws a deterministic frame for one key.

const DARK_JADE := Color(0.08, 0.30, 0.20, 0.92)
const VENOM_LIME := Color(0.62, 0.92, 0.18, 0.92)
const DEEP_TEAL := Color(0.10, 0.42, 0.36, 0.90)
const OXIDIZED_COPPER := Color(0.30, 0.60, 0.46, 0.78)
const BLACK_VIOLET := Color(0.22, 0.08, 0.28, 0.92)
const CINNABAR := Color(0.82, 0.16, 0.13, 0.92)
const DARK_RED := Color(0.44, 0.05, 0.08, 0.92)
const AMBER := Color(0.90, 0.56, 0.16, 0.92)
const HERBAL_GREEN := Color(0.34, 0.66, 0.30, 0.88)
const MILK_WHITE := Color(0.92, 0.92, 0.78, 0.88)
const ROYAL_GOLD := Color(0.68, 0.54, 0.22, 0.82)

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
		"medical_practice":
			_draw_medical_practice()
		"gu_herb_poison":
			_draw_herb_poison()
		"gu_infusion":
			_draw_gu_infusion()
		"gu_scorpion_breeding":
			_draw_scorpion_breeding()
		"gu_lure":
			_draw_lure(false)
		"gu_trap_trigger":
			_draw_lure(true)
		"gu_life_link_larva":
			_draw_life_link_larva()
		"gu_life_link":
			_draw_life_link_seal(false)
		"gu_life_link_death":
			_draw_life_link_seal(true)
		"thin_burial":
			_draw_thin_burial(false, false)
		"thin_burial_release":
			_draw_thin_burial(true, false)
		"thin_burial_break":
			_draw_thin_burial(true, true)
		"gu_summon":
			_draw_king_snake_summon()
		"gu_snake_venom_apply":
			_draw_snake_venom()
		"gu_devour":
			_draw_devour()
		"gu_venom_inject":
			_draw_venom_transfer()
		"gu_venom_burst":
			_draw_venom_burst()
		"gu_poison_tick_scorpion":
			_draw_poison_tick(1, false)
		"gu_scorpion_venom_apply":
			_draw_poison_tick(1, false)
		"gu_poison_tick_snake":
			_draw_poison_tick(2, false)
		"gu_poison_tick_king":
			_draw_poison_tick(3, false)
		"gu_king_venom_apply":
			_draw_poison_tick(3, false)
		"gu_poison_burst":
			_draw_poison_tick(3, true)


func _draw_medical_practice() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var gather := _ease_out(progress, 0.0, 0.34)
	var release := _ease_out(progress, 0.32, 1.0)
	var phase := progress * TAU * 1.5

	_draw_imperfect_seal(center, radius * gather, phase, AMBER, 2)
	var bowl_center := center + Vector2(0.0, radius * 0.18)
	var bowl := PackedVector2Array([
		bowl_center + Vector2(-radius * 0.42, -radius * 0.10),
		bowl_center + Vector2(-radius * 0.26, radius * 0.24),
		bowl_center + Vector2(radius * 0.26, radius * 0.24),
		bowl_center + Vector2(radius * 0.42, -radius * 0.10)
	])
	draw_colored_polygon(bowl, Color(0.25, 0.14, 0.08, 0.54))
	draw_polyline(bowl, Color(0.76, 0.48, 0.22, 0.82), 2.4, true)

	for leaf_index in range(7):
		var angle := phase * 0.12 + TAU * float(leaf_index) / 7.0
		var leaf_center := center + Vector2(cos(angle), sin(angle)) * radius * (0.18 + gather * 0.42)
		_draw_leaf(leaf_center, angle, radius * 0.10, HERBAL_GREEN)

	for smoke_index in range(9):
		var rise := fmod(progress * (0.76 + float(smoke_index % 3) * 0.12) + float(smoke_index) / 9.0, 1.0)
		var smoke_center := bowl_center + Vector2(
			sin(float(smoke_index) * 1.9 + phase * 0.18) * radius * 0.26,
			-radius * (0.10 + rise * 1.12)
		)
		draw_circle(
			smoke_center,
			radius * (0.045 + float(smoke_index % 3) * 0.016),
			Color(AMBER.r, AMBER.g, AMBER.b, sin(rise * PI) * 0.22)
		)

	_draw_glow_circle(center, radius * (0.08 + release * 0.10), Color(0.96, 0.78, 0.36, 0.74))


func _draw_herb_poison() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var gather := _ease_out(progress, 0.0, 0.38)
	var press := _ease_out(progress, 0.34, 0.92)
	var phase := progress * TAU * 1.7

	_draw_imperfect_seal(center, radius * gather, -phase, DEEP_TEAL, 2)
	_draw_branching_veins(center, radius * (0.24 + press * 0.72), 8, phase, DEEP_TEAL)
	for drop_index in range(8):
		var angle := TAU * float(drop_index) / 8.0 + phase * 0.16
		var drop_center := center + Vector2(cos(angle), sin(angle)) * radius * lerpf(0.92, 0.24, press)
		_draw_venom_drop(drop_center, angle + PI * 0.5, radius * 0.09, VENOM_LIME)
	_draw_glow_circle(center, radius * (0.10 + press * 0.12), Color(0.48, 0.84, 0.20, 0.72))


func _draw_gu_infusion() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.37
	var inject := _ease_out(progress, 0.0, 0.42)
	var spread := _ease_out(progress, 0.34, 1.0)
	var phase := progress * TAU * 2.0

	_draw_imperfect_seal(center, radius * inject, phase * 0.24, DARK_JADE, 3)
	for larva_index in range(6):
		var angle := TAU * float(larva_index) / 6.0 + phase * 0.18
		var travel := lerpf(radius * 1.04, radius * 0.18, inject)
		var larva_center := center + Vector2(cos(angle), sin(angle)) * travel
		_draw_segmented_larva(larva_center, angle + PI, radius * 0.12, VENOM_LIME)

	_draw_branching_veins(center, radius * spread, 9, phase, DARK_JADE)
	for pulse_index in range(3):
		var pulse := fmod(spread + float(pulse_index) * 0.22, 1.0)
		draw_arc(
			center,
			radius * (0.22 + pulse * 0.76),
			phase * 0.12 + float(pulse_index),
			phase * 0.12 + float(pulse_index) + PI * 1.58,
			48,
			Color(VENOM_LIME.r, VENOM_LIME.g, VENOM_LIME.b, (1.0 - pulse) * 0.48),
			2.0,
			true
		)


func _draw_scorpion_breeding() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var unseal := _ease_out(progress, 0.0, 0.34)
	var hatch := _ease_out(progress, 0.30, 0.86)
	var phase := progress * TAU * 1.4

	_draw_imperfect_seal(center, radius * unseal, -phase * 0.18, OXIDIZED_COPPER, 2)
	var jar_rect := Rect2(
		center - Vector2(radius * 0.30, radius * 0.26),
		Vector2(radius * 0.60, radius * 0.60)
	)
	draw_rect(jar_rect, Color(0.18, 0.13, 0.07, 0.42), true)
	draw_rect(jar_rect, Color(0.58, 0.42, 0.20, 0.82), false, 2.6, true)
	draw_line(
		jar_rect.position + Vector2(radius * 0.10, 0.0),
		jar_rect.end - Vector2(radius * 0.10, jar_rect.size.y),
		CINNABAR,
		3.0,
		true
	)

	var egg_radius := radius * lerpf(0.16, 0.28, hatch)
	draw_circle(center, egg_radius, Color(0.36, 0.52, 0.18, 0.30))
	draw_arc(center, egg_radius, 0.0, TAU, 48, VENOM_LIME, 2.2, true)
	for crack_index in range(5):
		var angle := -PI * 0.76 + float(crack_index) * PI * 0.38
		var start := center + Vector2(cos(angle), sin(angle)) * egg_radius * 0.18
		var end := center + Vector2(cos(angle + sin(float(crack_index)) * 0.18), sin(angle + sin(float(crack_index)) * 0.18)) * egg_radius
		draw_line(start, end, Color(0.78, 0.96, 0.36, hatch * 0.82), 1.6, true)

	if hatch > 0.34:
		_draw_scorpion(center, radius * (0.18 + hatch * 0.24), Color(VENOM_LIME.r, VENOM_LIME.g, VENOM_LIME.b, hatch))


func _draw_lure(triggered: bool) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.40
	var close := _ease_out(progress, 0.0, 0.72 if triggered else 0.48)
	var phase := progress * TAU * (2.4 if triggered else 1.1)
	var seal_color := CINNABAR if triggered else DARK_JADE

	_draw_imperfect_seal(center, radius * lerpf(1.10, 0.74, close), phase * 0.18, seal_color, 3)
	for tunnel_index in range(10):
		var angle := TAU * float(tunnel_index) / 10.0 + phase * 0.08
		var outer := center + Vector2(cos(angle), sin(angle)) * radius * lerpf(1.06, 0.36, close)
		var bend := center + Vector2(cos(angle + 0.18), sin(angle + 0.18)) * radius * 0.64
		var inner := center + Vector2(cos(angle - 0.12), sin(angle - 0.12)) * radius * 0.18
		draw_polyline(
			PackedVector2Array([outer, bend, inner]),
			Color(seal_color.r, seal_color.g, seal_color.b, 0.38 + close * 0.40),
			2.0 + (1.0 if triggered else 0.0),
			true
		)

	for eye_index in range(4):
		var angle := phase * 0.16 + TAU * float(eye_index) / 4.0
		var eye_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.52
		draw_circle(eye_center, radius * 0.035, Color(0.04, 0.02, 0.02, 0.84))
		draw_circle(eye_center, radius * 0.014, Color(VENOM_LIME.r, VENOM_LIME.g, VENOM_LIME.b, 0.78))

	if triggered:
		_draw_glow_circle(center, radius * (0.10 + close * 0.18), Color(0.54, 0.04, 0.08, 0.62))


func _draw_life_link_larva() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var inject := _ease_out(progress, 0.0, 0.42)
	var crawl := _ease_out(progress, 0.26, 1.0)
	var phase := progress * TAU * 1.8

	_draw_imperfect_seal(center, radius * inject, phase * 0.12, CINNABAR, 2)
	draw_circle(center, radius * (0.13 + inject * 0.06), Color(0.28, 0.18, 0.06, 0.48))
	draw_arc(center, radius * 0.19, 0.0, TAU, 42, Color(0.80, 0.66, 0.26, 0.86), 2.2, true)
	for larva_index in range(3):
		var angle := phase * 0.22 + TAU * float(larva_index) / 3.0
		var larva_center := center + Vector2(cos(angle), sin(angle)) * radius * (0.20 + crawl * 0.44)
		_draw_segmented_larva(larva_center, angle + PI * 0.5, radius * 0.14, Color(0.70, 0.82, 0.24, 0.86))
	draw_circle(center + Vector2(radius * 0.12, -radius * 0.10), radius * 0.035, CINNABAR)


func _draw_life_link_seal(is_death: bool) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.37
	var bind := _ease_out(progress, 0.0, 0.48)
	var tension := _ease_out(progress, 0.36, 0.96) if is_death else 0.0
	var phase := progress * TAU * 1.2

	_draw_imperfect_seal(center, radius * bind, phase * 0.10, DARK_RED, 2)
	for knot_index in range(4):
		var angle := TAU * float(knot_index) / 4.0 + phase * 0.08
		var knot_center := center + Vector2(cos(angle), sin(angle)) * radius * lerpf(0.68, 0.34, tension)
		draw_circle(knot_center, radius * 0.06, Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, 0.72))
		draw_arc(knot_center, radius * 0.10, angle, angle + PI * 1.54, 18, DEEP_TEAL, 1.8, true)
	_draw_branching_veins(center, radius * lerpf(0.74, 0.40, tension), 6, phase, DARK_RED)
	if is_death:
		for slash_index in range(5):
			var offset := float(slash_index - 2) * radius * 0.14
			draw_line(
				center + Vector2(-radius * 0.42, offset - radius * 0.18),
				center + Vector2(radius * 0.42, offset + radius * 0.18),
				Color(0.98, 0.36, 0.26, 0.72 * tension),
				2.4,
				true
			)


func _draw_thin_burial(is_release: bool, is_break: bool) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var binding_progress := _ease_out(progress, 0.0, 0.46)
	var release := _ease_out(progress, 0.40, 1.0) if is_release else 0.0
	var phase := progress * TAU

	for talisman_index in range(5):
		var angle := -PI * 0.86 + float(talisman_index) * PI * 0.43 + phase * 0.05
		var orbit := radius * lerpf(1.08, 0.66, binding_progress)
		var paper_center := center + Vector2(cos(angle), sin(angle)) * orbit
		var paper_size := Vector2(radius * 0.18, radius * 0.42)
		var paper_rect := Rect2(paper_center - paper_size * 0.5, paper_size)
		draw_rect(paper_rect, Color(0.72, 0.72, 0.58, 0.18 * (1.0 - release)), true)
		draw_rect(paper_rect, Color(0.82, 0.84, 0.68, 0.60 * (1.0 - release)), false, 1.6, true)
		draw_line(
			paper_center + Vector2(0.0, -paper_size.y * 0.30),
			paper_center + Vector2(0.0, paper_size.y * 0.28),
			Color(CINNABAR.r, CINNABAR.g, CINNABAR.b, 0.68 * (1.0 - release)),
			1.8,
			true
		)

	var shroud := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.72),
		center + Vector2(radius * 0.34, -radius * 0.34),
		center + Vector2(radius * 0.28, radius * 0.68),
		center + Vector2(-radius * 0.28, radius * 0.68),
		center + Vector2(-radius * 0.34, -radius * 0.34)
	])
	draw_colored_polygon(shroud, Color(0.42, 0.46, 0.38, 0.12 * binding_progress * (1.0 - release)))
	draw_polyline(shroud, Color(0.70, 0.76, 0.64, 0.72 * binding_progress * (1.0 - release)), 2.2, true)
	for stitch_index in range(7):
		var t := float(stitch_index) / 6.0
		var x := lerpf(center.x - radius * 0.28, center.x + radius * 0.28, t)
		var y := center.y + sin(t * TAU * 1.5) * radius * 0.18
		var stress := 1.0 + (0.8 if is_break else 0.0) * release
		draw_line(
			Vector2(x, y - radius * 0.20 * stress),
			Vector2(x, y + radius * 0.20 * stress),
			Color(0.05, 0.04, 0.04, 0.70 * binding_progress * (1.0 - release * 0.36)),
			1.7,
			true
		)

	for segment_index in range(4):
		var segment_center := center + Vector2(
			(float(segment_index) - 1.5) * radius * 0.22,
			radius * 0.82
		)
		draw_circle(
			segment_center,
			radius * 0.045,
			Color(0.66, 0.82, 0.46, 0.74 * (1.0 - release))
		)
	if is_break:
		for crack_index in range(6):
			var angle := TAU * float(crack_index) / 6.0
			draw_line(
				center + Vector2(cos(angle), sin(angle)) * radius * 0.16,
				center + Vector2(cos(angle + 0.10), sin(angle + 0.10)) * radius * (0.46 + release * 0.52),
				Color(0.12, 0.06, 0.06, 0.82 * release),
				2.2,
				true
			)


func _draw_king_snake_summon() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.40
	var invoke := _ease_out(progress, 0.0, 0.38)
	var hatch := _ease_out(progress, 0.30, 0.92)
	var phase := progress * TAU * 1.25

	_draw_imperfect_seal(center, radius * invoke, -phase * 0.14, BLACK_VIOLET, 3)
	for coil_index in range(4):
		var coil_radius := radius * (0.22 + float(coil_index) * 0.15) * hatch
		draw_arc(
			center,
			coil_radius,
			phase * (0.18 + float(coil_index) * 0.04),
			phase * 0.18 + PI * (1.28 + float(coil_index) * 0.12),
			56,
			Color(
				DEEP_TEAL.r,
				DEEP_TEAL.g,
				DEEP_TEAL.b,
				0.74 - float(coil_index) * 0.10
			),
			4.0 - float(coil_index) * 0.48,
			true
		)
	for scale_index in range(9):
		var angle := phase * 0.12 + TAU * float(scale_index) / 9.0
		var scale_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.72
		_draw_scale(scale_center, angle, radius * 0.08, ROYAL_GOLD)
	_draw_glow_circle(center, radius * (0.10 + hatch * 0.14), Color(0.18, 0.52, 0.30, 0.76))


func _draw_snake_venom() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var bite := _ease_out(progress, 0.0, 0.38)
	var coil := _ease_out(progress, 0.30, 1.0)
	var phase := progress * TAU * 1.8

	for fang_index in range(2):
		var x := center.x + (-1.0 if fang_index == 0 else 1.0) * radius * 0.18
		var top := Vector2(x, center.y - radius * 0.44)
		_draw_fang(top, radius * 0.10, radius * 0.42 * bite, Color(0.72, 0.92, 0.46, 0.88))

	for coil_index in range(2):
		var points := PackedVector2Array()
		for step in range(24):
			var t := float(step) / 23.0
			points.append(Vector2(
				center.x + sin(t * TAU * 1.8 + phase + float(coil_index) * PI) * radius * (0.24 + float(coil_index) * 0.08),
				center.y + lerpf(-radius * 0.20, radius * 0.74, t) * coil
			))
		draw_polyline(
			points,
			Color(DEEP_TEAL.r, DEEP_TEAL.g, DEEP_TEAL.b, 0.72 - float(coil_index) * 0.16),
			3.0 - float(coil_index) * 0.6,
			true
		)
	_draw_branching_veins(center, radius * coil, 6, phase, DEEP_TEAL)


func _draw_devour() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.40
	var consume := _ease_out(progress, 0.0, 0.62)
	var grow := _ease_out(progress, 0.46, 1.0)
	var phase := progress * TAU * 1.7

	for fragment_index in range(14):
		var angle := TAU * float(fragment_index) / 14.0 + phase * 0.10
		var travel := lerpf(radius * 1.08, radius * 0.20, consume)
		var fragment_center := center + Vector2(cos(angle), sin(angle)) * travel
		_draw_chitin_fragment(
			fragment_center,
			angle,
			radius * (0.07 + float(fragment_index % 3) * 0.016),
			Color(0.34, 0.58, 0.26, 0.84)
		)
	_draw_glow_circle(center, radius * (0.10 + grow * 0.24), Color(0.24, 0.52, 0.20, 0.64))
	for plate_index in range(6):
		var angle := TAU * float(plate_index) / 6.0
		var plate_center := center + Vector2(cos(angle), sin(angle)) * radius * (0.20 + grow * 0.34)
		_draw_scale(plate_center, angle, radius * (0.06 + grow * 0.06), OXIDIZED_COPPER)


func _draw_venom_transfer() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var fill := _ease_out(progress, 0.0, 0.72)
	var phase := progress * TAU * 1.5

	_draw_imperfect_seal(center, radius * fill, phase * 0.14, DEEP_TEAL, 2)
	var reservoir_center := center + Vector2(0.0, radius * 0.08)
	_draw_venom_drop(reservoir_center, PI * 0.5, radius * (0.20 + fill * 0.18), VENOM_LIME)
	for stream_index in range(6):
		var angle := -PI * 0.84 + float(stream_index) * PI * 0.336
		var start := center + Vector2(cos(angle), sin(angle)) * radius * 0.86
		var end := reservoir_center + Vector2(cos(angle), sin(angle)) * radius * 0.12
		draw_line(start, end, Color(DEEP_TEAL.r, DEEP_TEAL.g, DEEP_TEAL.b, 0.42), 2.0, true)


func _draw_venom_burst() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	var compress := _ease_out(progress, 0.0, 0.32)
	var burst := _ease_out(progress, 0.28, 1.0)
	var phase := progress * TAU * 1.6

	_draw_glow_circle(center, radius * lerpf(0.24, 0.10, compress), Color(0.26, 0.62, 0.18, 0.64))
	for jet_index in range(12):
		var angle := TAU * float(jet_index) / 12.0 + phase * 0.08
		var direction := Vector2(cos(angle), sin(angle))
		var start := center + direction * radius * 0.08
		var end := center + direction * radius * (0.18 + burst * (0.62 + float(jet_index % 3) * 0.10))
		draw_line(
			start,
			end,
			Color(VENOM_LIME.r, VENOM_LIME.g, VENOM_LIME.b, 0.74 - float(jet_index % 3) * 0.12),
			4.2 - float(jet_index % 3) * 0.6,
			true
		)
		draw_circle(end, radius * (0.035 + float(jet_index % 2) * 0.014), Color(DEEP_TEAL.r, DEEP_TEAL.g, DEEP_TEAL.b, 0.64))
	draw_arc(center, radius * burst, 0.0, TAU, 64, Color(0.42, 0.82, 0.22, 0.56), 3.0, true)


func _draw_poison_tick(level: int, compressed: bool) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	var pressure := _ease_out(progress, 0.0, 0.46)
	var rupture := _ease_out(progress, 0.42, 1.0)
	var phase := progress * TAU * (1.5 + float(level) * 0.22)
	var primary := _poison_level_color(level)
	var sac_count := 1 if compressed else level + 1

	_draw_branching_veins(center, radius * (0.34 + pressure * 0.58), 6 + level * 2, phase, primary)
	for sac_index in range(sac_count):
		var angle := TAU * float(sac_index) / float(maxi(sac_count, 1)) + phase * 0.10
		var sac_center := center + Vector2(cos(angle), sin(angle)) * radius * (0.12 + float(sac_index % 2) * 0.16)
		var sac_radius := radius * (0.10 + float(level) * 0.025) * (1.0 + pressure * 0.36)
		_draw_glow_circle(sac_center, sac_radius, Color(primary.r, primary.g, primary.b, 0.58))

	if level == 1:
		_draw_scorpion(center, radius * 0.28, Color(primary.r, primary.g, primary.b, 0.72))
	elif level == 2:
		draw_arc(center, radius * 0.44, phase, phase + PI * 1.66, 50, Color(primary.r, primary.g, primary.b, 0.72), 3.0, true)
	else:
		for scale_index in range(6):
			var angle := TAU * float(scale_index) / 6.0 + phase * 0.10
			_draw_scale(center + Vector2(cos(angle), sin(angle)) * radius * 0.48, angle, radius * 0.07, ROYAL_GOLD)

	for rupture_index in range(10 + level * 2):
		var angle := TAU * float(rupture_index) / float(10 + level * 2) + phase * 0.06
		var start := center + Vector2(cos(angle), sin(angle)) * radius * 0.14
		var end := center + Vector2(cos(angle + 0.06), sin(angle + 0.06)) * radius * (0.28 + rupture * 0.72)
		draw_line(start, end, Color(primary.r, primary.g, primary.b, rupture * 0.72), 2.0 + float(level) * 0.35, true)

	if compressed:
		for ring_index in range(3):
			draw_arc(
				center,
				radius * (0.22 + rupture * (0.56 + float(ring_index) * 0.14)),
				phase * 0.10,
				phase * 0.10 + TAU,
				64,
				Color(primary.r, primary.g, primary.b, 0.72 - float(ring_index) * 0.18),
				3.2 - float(ring_index) * 0.5,
				true
			)


func _draw_imperfect_seal(
	center: Vector2,
	radius: float,
	phase: float,
	color: Color,
	layers: int
) -> void:
	if radius <= 0.1:
		return
	for layer_index in range(layers):
		var layer_radius := radius * (0.56 + float(layer_index) * 0.20)
		var points := PackedVector2Array()
		var point_count := 52
		for point_index in range(point_count + 1):
			var angle := TAU * float(point_index) / float(point_count) + phase * (0.14 + float(layer_index) * 0.04)
			var wobble := 1.0 + sin(angle * (3.0 + float(layer_index)) + float(layer_index)) * 0.035
			points.append(center + Vector2(cos(angle), sin(angle)) * layer_radius * wobble)
		draw_polyline(
			points,
			Color(color.r, color.g, color.b, color.a * (0.76 - float(layer_index) * 0.16)),
			2.5 - float(layer_index) * 0.35,
			true
		)
		var node_count := 6 + layer_index * 3
		for node_index in range(node_count):
			var angle := TAU * float(node_index) / float(node_count) + phase * 0.12
			var direction := Vector2(cos(angle), sin(angle))
			draw_circle(
				center + direction * layer_radius,
				2.0 + float(node_index % 2),
				Color(color.r, color.g, color.b, color.a * 0.68)
			)


func _draw_branching_veins(
	center: Vector2,
	radius: float,
	count: int,
	phase: float,
	color: Color
) -> void:
	for vein_index in range(count):
		var angle := TAU * float(vein_index) / float(maxi(count, 1)) + phase * 0.08
		var direction := Vector2(cos(angle), sin(angle))
		var tangent := Vector2(-direction.y, direction.x)
		var start := center + direction * radius * 0.12
		var middle := center + direction * radius * 0.54 + tangent * sin(float(vein_index) * 1.73 + phase) * radius * 0.08
		var end := center + direction * radius
		draw_polyline(
			PackedVector2Array([start, middle, end]),
			Color(color.r, color.g, color.b, color.a * 0.62),
			2.2,
			true
		)
		var branch_direction := (end - middle).normalized()
		var branch_tangent := Vector2(-branch_direction.y, branch_direction.x)
		draw_line(
			middle,
			middle + branch_direction * radius * 0.20 + branch_tangent * radius * 0.12,
			Color(color.r, color.g, color.b, color.a * 0.42),
			1.4,
			true
		)


func _draw_segmented_larva(center: Vector2, angle: float, length: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	for segment_index in range(5):
		var t := float(segment_index) / 4.0
		var segment_center := (
			center
			+ direction * (t - 0.5) * length
			+ tangent * sin(t * PI * 2.0 + progress * TAU) * length * 0.08
		)
		draw_circle(
			segment_center,
			length * (0.085 + float(segment_index % 2) * 0.018),
			Color(color.r, color.g, color.b, color.a * (0.58 + t * 0.08))
		)


func _draw_scorpion(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius * 0.22, color)
	draw_circle(center + Vector2(0.0, radius * 0.28), radius * 0.28, color)
	for leg_index in range(3):
		var y := center.y + radius * (-0.08 + float(leg_index) * 0.20)
		draw_line(
			Vector2(center.x - radius * 0.16, y),
			Vector2(center.x - radius * (0.54 + float(leg_index) * 0.05), y + radius * 0.14),
			color,
			2.0,
			true
		)
		draw_line(
			Vector2(center.x + radius * 0.16, y),
			Vector2(center.x + radius * (0.54 + float(leg_index) * 0.05), y + radius * 0.14),
			color,
			2.0,
			true
		)
	var tail := PackedVector2Array([
		center + Vector2(0.0, radius * 0.46),
		center + Vector2(radius * 0.28, radius * 0.62),
		center + Vector2(radius * 0.34, radius * 0.22),
		center + Vector2(radius * 0.12, -radius * 0.24)
	])
	draw_polyline(tail, color, 3.0, true)


func _draw_leaf(center: Vector2, angle: float, radius: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		center - direction * radius,
		center + tangent * radius * 0.42,
		center + direction * radius,
		center - tangent * radius * 0.42
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.34))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 1.5, true)
	draw_line(center - direction * radius * 0.78, center + direction * radius * 0.78, color, 1.1, true)


func _draw_venom_drop(center: Vector2, angle: float, radius: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		center - direction * radius,
		center + tangent * radius * 0.62 + direction * radius * 0.22,
		center + direction * radius,
		center - tangent * radius * 0.62 + direction * radius * 0.22
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.30))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 1.8, true)


func _draw_fang(top_center: Vector2, half_width: float, height: float, color: Color) -> void:
	var points := PackedVector2Array([
		top_center + Vector2(-half_width, 0.0),
		top_center + Vector2(half_width, 0.0),
		top_center + Vector2(0.0, height)
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.24))
	draw_polyline(PackedVector2Array([points[0], points[2], points[1]]), color, 2.0, true)


func _draw_scale(center: Vector2, angle: float, radius: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		center - direction * radius,
		center + tangent * radius * 0.72,
		center + direction * radius,
		center - tangent * radius * 0.72
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.20))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 1.5, true)


func _draw_chitin_fragment(center: Vector2, angle: float, radius: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		center - direction * radius,
		center + tangent * radius * 0.68,
		center + direction * radius * 0.82,
		center - tangent * radius * 0.52
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * 0.28))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 1.6, true)


func _draw_glow_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius * 1.72, Color(color.r, color.g, color.b, color.a * 0.08))
	draw_circle(center, radius * 1.26, Color(color.r, color.g, color.b, color.a * 0.16))
	draw_circle(center, radius, color)


func _poison_level_color(level: int) -> Color:
	match level:
		1:
			return Color(0.68, 0.90, 0.16, 0.90)
		2:
			return DEEP_TEAL
		_:
			return Color(0.30, 0.16, 0.38, 0.94)


func _ease_out(value: float, start: float, finish: float) -> float:
	if finish <= start:
		return 1.0 if value >= finish else 0.0
	var normalized := clampf((value - start) / (finish - start), 0.0, 1.0)
	return 1.0 - pow(1.0 - normalized, 3.0)
