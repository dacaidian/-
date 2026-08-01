extends Control

const Palette := preload("res://scripts/ui/animation/beastmen_vfx_palette.gd")

var animation_key := ""
var source_center := Vector2.ZERO
var destination_center := Vector2.ZERO
var board_rect := Rect2()
var source_size := Vector2(120.0, 168.0)
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(
	key: String,
	local_source_center: Vector2,
	local_destination_center: Vector2,
	local_board_rect: Rect2,
	local_source_size: Vector2
) -> void:
	animation_key = key
	source_center = local_source_center
	destination_center = local_destination_center
	board_rect = local_board_rect
	source_size = local_source_size
	queue_redraw()


func _draw() -> void:
	match animation_key:
		"savage_roar":
			_draw_savage_roar()
		"wild_call":
			_draw_wild_call()
		"beast_path":
			_draw_beast_path_cast()
		"wanmo_ritual":
			_draw_wanmo_ritual()
		"chaos_corruption_burst":
			_draw_chaos_corruption_burst()


func _draw_savage_roar() -> void:
	var scale_value := _source_scale()
	var gather := Palette.ease_out(Palette.phase(progress, 0.0, 0.24))
	var release := Palette.ease_out(Palette.phase(progress, 0.18, 0.72))
	var echo := Palette.phase(progress, 0.62, 1.0)
	var alpha := 1.0 - echo * 0.72

	_draw_horned_skull(source_center + Vector2(0.0, -scale_value * 0.08), scale_value * (0.38 + gather * 0.10), gather * alpha)
	_draw_war_paint(source_center, scale_value, gather * alpha)

	var wave_bounds := board_rect if board_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, size)
	var max_radius := maxf(wave_bounds.size.x, wave_bounds.size.y) * 0.58
	for wave_index in range(4):
		var wave_phase := clampf(release - float(wave_index) * 0.13, 0.0, 1.0)
		if wave_phase <= 0.0:
			continue
		var radius := lerpf(scale_value * 0.24, max_radius, wave_phase)
		var wave_alpha := (1.0 - wave_phase) * (0.72 - float(wave_index) * 0.10) * alpha
		_draw_rough_wave(source_center, radius, wave_alpha, wave_index)

	_draw_dust_burst(source_center + Vector2(0.0, source_size.y * 0.36), scale_value, release, alpha, 18)


func _draw_wild_call() -> void:
	var scale_value := _source_scale()
	var invoke := Palette.ease_out(Palette.phase(progress, 0.0, 0.30))
	var converge := Palette.ease_in_out(Palette.phase(progress, 0.18, 0.70))
	var deliver := Palette.ease_in_out(Palette.phase(progress, 0.62, 0.94))
	var fade := 1.0 - Palette.phase(progress, 0.88, 1.0)

	_draw_bone_whistle(source_center, scale_value * 0.42, invoke * fade)
	for track_index in range(4):
		var start_point := _wild_track_origin(track_index)
		var control := start_point.lerp(source_center, 0.48) + Vector2(0.0, sin(float(track_index) * 1.7) * scale_value * 0.44)
		var track_curve := _quadratic_curve(start_point, control, source_center, 24)
		_draw_track_sequence(track_curve, converge, track_index, scale_value, fade)

	var token_start := source_center + Vector2(0.0, -scale_value * 0.08)
	var token_control := token_start.lerp(destination_center, 0.48) + Vector2(0.0, -scale_value * 1.05)
	var token_center := _quadratic_point(token_start, token_control, destination_center, deliver)
	_draw_hide_card(token_center, Vector2(scale_value * 0.30, scale_value * 0.42), fade * deliver)
	var token_trail := _quadratic_curve(token_start, token_control, destination_center, 28)
	_draw_partial_trail(token_trail, deliver, Palette.with_alpha(Palette.DUST, 0.52 * fade), scale_value * 0.022)


func _draw_beast_path_cast() -> void:
	var scale_value := _source_scale()
	var brace := Palette.ease_out(Palette.phase(progress, 0.0, 0.28))
	var dig := Palette.ease_out(Palette.phase(progress, 0.18, 0.70))
	var settle := 1.0 - Palette.phase(progress, 0.74, 1.0)
	var ground_center := source_center + Vector2(0.0, source_size.y * 0.42)

	for claw_index in range(3):
		var offset := Vector2(float(claw_index - 1) * scale_value * 0.12, 0.0)
		var start_point := source_center + offset + Vector2(0.0, -scale_value * 0.32)
		var end_point := ground_center + offset + Vector2(float(claw_index - 1) * scale_value * 0.03, scale_value * 0.26) * dig
		var claw := _jagged_segment(start_point, end_point, 9, scale_value * 0.018)
		_draw_layered_line(claw, Palette.with_alpha(Palette.SOIL_BLACK, 0.90 * settle), Palette.with_alpha(Palette.COPPER, 0.82 * settle), scale_value * 0.052, scale_value * 0.018)

	_draw_bone_pointer(source_center + Vector2(0.0, scale_value * 0.06), scale_value * (0.30 + brace * 0.08), brace * settle)
	_draw_dust_burst(ground_center, scale_value, dig, settle, 14)


func _draw_wanmo_ritual() -> void:
	var scale_value := _source_scale()
	var awaken := Palette.ease_out(Palette.phase(progress, 0.0, 0.28))
	var consume := Palette.ease_in_out(Palette.phase(progress, 0.18, 0.58))
	var summon := Palette.ease_out(Palette.phase(progress, 0.46, 0.82))
	var deliver := Palette.ease_in_out(Palette.phase(progress, 0.68, 0.96))
	var fade := 1.0 - Palette.phase(progress, 0.90, 1.0)

	_draw_wanmo_monolith(source_center, scale_value * 0.64, awaken, fade)
	for charge_index in range(7):
		var angle := TAU * float(charge_index) / 7.0 - PI * 0.5
		var start_point := source_center + Vector2(cos(angle), sin(angle)) * scale_value * 0.66
		var charge_center := start_point.lerp(source_center, consume)
		draw_circle(charge_center, scale_value * 0.022, Palette.with_alpha(Palette.EMBER, 0.84 * fade * (1.0 - consume * 0.34)))

	for beast_index in range(3):
		var x_shift := float(beast_index - 1) * scale_value * 0.34
		var beast_base := source_center + Vector2(x_shift, scale_value * 0.34)
		_draw_giant_beast_shadow(beast_base, scale_value * (0.38 + float(beast_index % 2) * 0.05), summon, fade)

	var transfer_start := source_center + Vector2(0.0, -scale_value * 0.36)
	var transfer_control := transfer_start.lerp(destination_center, 0.50) + Vector2(0.0, -scale_value * 0.94)
	var transfer_curve := _quadratic_curve(transfer_start, transfer_control, destination_center, 30)
	_draw_partial_trail(transfer_curve, deliver, Palette.with_alpha(Palette.DRIED_BLOOD, 0.62 * fade), scale_value * 0.050)
	_draw_partial_trail(transfer_curve, deliver, Palette.with_alpha(Palette.EMBER, 0.82 * fade), scale_value * 0.016)
	var token_center := _quadratic_point(transfer_start, transfer_control, destination_center, deliver)
	_draw_horned_token(token_center, scale_value * 0.26, deliver * fade)


func _draw_chaos_corruption_burst() -> void:
	var safe_board := board_rect if board_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, size)
	var center := safe_board.get_center()
	var scale_value := maxf(minf(safe_board.size.x, safe_board.size.y), 260.0)
	var seep := Palette.ease_out(Palette.phase(progress, 0.0, 0.34))
	var rupture := Palette.ease_out(Palette.phase(progress, 0.24, 0.72))
	var wash := Palette.phase(progress, 0.58, 1.0)
	var alpha := 1.0 - wash * 0.78

	draw_rect(safe_board, Palette.with_alpha(Palette.SOIL_BLACK, 0.22 * seep * alpha), true)
	_draw_corruption_core(center, scale_value * 0.12, seep, alpha)

	for branch_index in range(14):
		var angle := TAU * float(branch_index) / 14.0 + sin(float(branch_index) * 1.91) * 0.18
		var direction := Vector2(cos(angle), sin(angle))
		var reach := scale_value * (0.34 + float(branch_index % 4) * 0.07)
		var branch_end := center + direction * reach
		var branch := _jagged_segment(center, branch_end, 13, scale_value * 0.012)
		_draw_partial_trail(branch, rupture, Palette.with_alpha(Palette.SOIL_BLACK, 0.84 * alpha), scale_value * 0.025)
		_draw_partial_trail(branch, rupture, Palette.with_alpha(Palette.CHAOS_GREEN if branch_index % 3 == 0 else Palette.CHAOS_PURPLE, 0.62 * alpha), scale_value * 0.008)

	for wave_index in range(3):
		var wave_phase := clampf(rupture - float(wave_index) * 0.16, 0.0, 1.0)
		var radius := scale_value * (0.10 + wave_phase * (0.52 + float(wave_index) * 0.05))
		draw_arc(
			center,
			radius,
			PI * 0.06,
			PI * 0.94,
			64,
			Palette.with_alpha(Palette.DRIED_BLOOD, (0.66 - wave_phase * 0.42) * alpha),
			6.0 - float(wave_index),
			true
		)

	_draw_corruption_spores(safe_board, rupture, alpha, 28)


func _draw_horned_skull(center: Vector2, radius: float, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var skull := PackedVector2Array([
		center + Vector2(-radius * 0.30, -radius * 0.26),
		center + Vector2(-radius * 0.42, radius * 0.14),
		center + Vector2(-radius * 0.18, radius * 0.54),
		center + Vector2(0.0, radius * 0.68),
		center + Vector2(radius * 0.18, radius * 0.54),
		center + Vector2(radius * 0.42, radius * 0.14),
		center + Vector2(radius * 0.30, -radius * 0.26),
		center,
	])
	draw_colored_polygon(skull, Palette.with_alpha(Palette.BONE, 0.26 * alpha))
	var skull_outline := skull.duplicate()
	skull_outline.append(skull[0])
	draw_polyline(skull_outline, Palette.with_alpha(Palette.BONE_HIGHLIGHT, 0.76 * alpha), maxf(radius * 0.055, 2.0), true)

	for side_sign in [-1.0, 1.0]:
		var horn := _cubic_curve(
			center + Vector2(side_sign * radius * 0.24, -radius * 0.20),
			center + Vector2(side_sign * radius * 0.92, -radius * 0.30),
			center + Vector2(side_sign * radius * 1.12, -radius * 0.96),
			center + Vector2(side_sign * radius * 0.48, -radius * 1.28),
			18
		)
		_draw_tapered_curve(horn, radius * 0.12, Palette.with_alpha(Palette.BONE, 0.82 * alpha), Palette.with_alpha(Palette.SOIL_BLACK, 0.78 * alpha))

	for eye_sign in [-1.0, 1.0]:
		var eye_center := center + Vector2(eye_sign * radius * 0.16, radius * 0.06)
		draw_circle(eye_center, radius * 0.065, Palette.with_alpha(Palette.DRIED_BLOOD, 0.94 * alpha))


func _draw_war_paint(center: Vector2, scale_value: float, alpha: float) -> void:
	for stripe_index in range(3):
		var y_offset := float(stripe_index - 1) * scale_value * 0.11
		var stripe := _jagged_segment(
			center + Vector2(-scale_value * 0.42, y_offset + scale_value * 0.22),
			center + Vector2(scale_value * 0.42, y_offset - scale_value * 0.18),
			9,
			scale_value * 0.018
		)
		draw_polyline(stripe, Palette.with_alpha(Palette.DRIED_BLOOD, 0.72 * alpha), scale_value * 0.035, true)


func _draw_rough_wave(center: Vector2, radius: float, alpha: float, seed: int) -> void:
	var points := PackedVector2Array()
	for point_index in range(58):
		var ratio := float(point_index) / 57.0
		var angle := TAU * ratio
		var wobble := sin(angle * 5.0 + float(seed) * 1.7) * radius * 0.035
		points.append(center + Vector2(cos(angle), sin(angle) * 0.64) * (radius + wobble))
	draw_polyline(points, Palette.with_alpha(Palette.SOIL_BLACK, alpha * 0.52), 8.0, true)
	draw_polyline(points, Palette.with_alpha(Palette.DARK_ORANGE, alpha), 2.5, true)


func _draw_dust_burst(center: Vector2, scale_value: float, phase_value: float, alpha: float, count: int) -> void:
	for mote_index in range(count):
		var angle := TAU * float(mote_index) / float(count) + sin(float(mote_index) * 2.13) * 0.22
		var direction := Vector2(cos(angle), sin(angle) * 0.58)
		var distance := scale_value * (0.12 + phase_value * (0.30 + float(mote_index % 5) * 0.055))
		var mote_center := center + direction * distance
		var mote_size := scale_value * (0.012 + float(mote_index % 4) * 0.004) * (1.0 - phase_value * 0.32)
		draw_circle(mote_center, maxf(mote_size, 1.2), Palette.with_alpha(Palette.DUST, 0.62 * alpha * (1.0 - phase_value * 0.28)))


func _draw_bone_whistle(center: Vector2, length: float, alpha: float) -> void:
	var direction := Vector2(0.82, -0.38)
	var side := direction.orthogonal()
	var start_point := center - direction * length * 0.5
	var end_point := center + direction * length * 0.5
	draw_line(start_point, end_point, Palette.with_alpha(Palette.SOIL_BLACK, 0.72 * alpha), length * 0.15, true)
	draw_line(start_point, end_point, Palette.with_alpha(Palette.BONE, 0.86 * alpha), length * 0.095, true)
	for hole_index in range(3):
		var hole_center := start_point.lerp(end_point, 0.32 + float(hole_index) * 0.18) + side * length * 0.005
		draw_circle(hole_center, length * 0.024, Palette.with_alpha(Palette.DEEP_EARTH, 0.90 * alpha))


func _draw_track_sequence(path: PackedVector2Array, phase_value: float, track_index: int, scale_value: float, alpha: float) -> void:
	if path.size() < 2:
		return
	var visible_count := mini(int(floor(phase_value * 9.0)), 9)
	for mark_index in range(visible_count):
		var ratio := (float(mark_index) + 0.5) / 9.0
		var point := _sample_polyline(path, ratio)
		var mark_alpha := alpha * (0.34 + ratio * 0.52)
		if track_index % 2 == 0:
			_draw_hoof_print(point, scale_value * 0.040, mark_alpha)
		else:
			_draw_claw_print(point, scale_value * 0.042, mark_alpha)


func _draw_hoof_print(center: Vector2, radius: float, alpha: float) -> void:
	for side_sign in [-1.0, 1.0]:
		var hoof_center := center + Vector2(side_sign * radius * 0.38, 0.0)
		draw_arc(hoof_center, radius * 0.60, PI * 0.18, PI * 1.82, 12, Palette.with_alpha(Palette.DUST, 0.72 * alpha), maxf(radius * 0.22, 1.3), true)


func _draw_claw_print(center: Vector2, radius: float, alpha: float) -> void:
	draw_circle(center + Vector2(0.0, radius * 0.26), radius * 0.42, Palette.with_alpha(Palette.DUST, 0.40 * alpha))
	for toe_index in range(3):
		var x_shift := float(toe_index - 1) * radius * 0.62
		draw_circle(center + Vector2(x_shift, -radius * 0.42), radius * 0.20, Palette.with_alpha(Palette.DUST, 0.72 * alpha))


func _draw_hide_card(center: Vector2, token_size: Vector2, alpha: float) -> void:
	if alpha <= 0.001:
		return
	var half := token_size * 0.5
	var hide := PackedVector2Array([
		center + Vector2(-half.x * 0.82, -half.y),
		center + Vector2(half.x, -half.y * 0.76),
		center + Vector2(half.x * 0.82, half.y),
		center + Vector2(-half.x, half.y * 0.72),
	])
	draw_colored_polygon(hide, Palette.with_alpha(Palette.DEEP_EARTH, 0.82 * alpha))
	var outline := hide.duplicate()
	outline.append(hide[0])
	draw_polyline(outline, Palette.with_alpha(Palette.BONE, 0.84 * alpha), 2.2, true)
	_draw_claw_print(center, minf(token_size.x, token_size.y) * 0.16, alpha)


func _draw_bone_pointer(center: Vector2, length: float, alpha: float) -> void:
	var tip := center + Vector2(0.0, length * 0.58)
	var top := center - Vector2(0.0, length * 0.42)
	draw_line(top, tip, Palette.with_alpha(Palette.SOIL_BLACK, 0.78 * alpha), length * 0.15, true)
	draw_line(top, tip, Palette.with_alpha(Palette.BONE, 0.88 * alpha), length * 0.085, true)
	var arrow := PackedVector2Array([
		tip + Vector2(-length * 0.16, -length * 0.18),
		tip,
		tip + Vector2(length * 0.16, -length * 0.18),
	])
	draw_polyline(arrow, Palette.with_alpha(Palette.BONE_HIGHLIGHT, 0.92 * alpha), length * 0.075, true)


func _draw_wanmo_monolith(center: Vector2, scale_value: float, awaken: float, alpha: float) -> void:
	var half_width := scale_value * 0.30
	var half_height := scale_value * 0.56
	var rock := PackedVector2Array([
		center + Vector2(-half_width, half_height),
		center + Vector2(-half_width * 0.82, -half_height * 0.52),
		center + Vector2(-half_width * 0.22, -half_height),
		center + Vector2(half_width * 0.52, -half_height * 0.76),
		center + Vector2(half_width, half_height * 0.92),
	])
	draw_colored_polygon(rock, Palette.with_alpha(Palette.SOIL_BLACK, 0.72 * awaken * alpha))
	var outline := rock.duplicate()
	outline.append(rock[0])
	draw_polyline(outline, Palette.with_alpha(Palette.COPPER, 0.72 * awaken * alpha), 3.0, true)
	for crack_index in range(5):
		var start_point := center + Vector2(float(crack_index - 2) * scale_value * 0.08, -scale_value * 0.22)
		var end_point := center + Vector2(float(crack_index - 2) * scale_value * 0.14, scale_value * 0.34)
		var crack := _jagged_segment(start_point, end_point, 6, scale_value * 0.018)
		draw_polyline(crack, Palette.with_alpha(Palette.DARK_ORANGE, 0.72 * awaken * alpha), 1.8, true)


func _draw_giant_beast_shadow(base: Vector2, scale_value: float, rise: float, alpha: float) -> void:
	if rise <= 0.0:
		return
	var body_center := base - Vector2(0.0, scale_value * 0.32 * rise)
	var body_radius := scale_value * (0.14 + rise * 0.18)
	draw_circle(body_center, body_radius, Palette.with_alpha(Palette.DRIED_BLOOD, 0.24 * rise * alpha))
	for side_sign in [-1.0, 1.0]:
		var horn := PackedVector2Array([
			body_center + Vector2(side_sign * body_radius * 0.32, -body_radius * 0.34),
			body_center + Vector2(side_sign * body_radius * 1.16, -body_radius * 1.02),
			body_center + Vector2(side_sign * body_radius * 0.72, -body_radius * 1.34),
		])
		draw_polyline(horn, Palette.with_alpha(Palette.BONE, 0.74 * rise * alpha), maxf(scale_value * 0.025, 2.0), true)
	var shoulders := PackedVector2Array([
		body_center + Vector2(-body_radius * 1.18, body_radius * 1.45),
		body_center + Vector2(-body_radius * 0.72, body_radius * 0.26),
		body_center + Vector2(body_radius * 0.72, body_radius * 0.26),
		body_center + Vector2(body_radius * 1.18, body_radius * 1.45),
	])
	draw_polyline(shoulders, Palette.with_alpha(Palette.SOIL_BLACK, 0.78 * rise * alpha), maxf(scale_value * 0.08, 4.0), true)


func _draw_horned_token(center: Vector2, radius: float, alpha: float) -> void:
	if alpha <= 0.001:
		return
	draw_circle(center, radius * 0.62, Palette.with_alpha(Palette.DEEP_EARTH, 0.86 * alpha))
	for side_sign in [-1.0, 1.0]:
		var horn := PackedVector2Array([
			center + Vector2(side_sign * radius * 0.18, -radius * 0.20),
			center + Vector2(side_sign * radius * 0.86, -radius * 0.70),
			center + Vector2(side_sign * radius * 0.48, -radius),
		])
		draw_polyline(horn, Palette.with_alpha(Palette.BONE_HIGHLIGHT, 0.92 * alpha), maxf(radius * 0.16, 2.0), true)


func _draw_corruption_core(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	draw_circle(center, radius * (1.24 + phase_value * 0.22), Palette.with_alpha(Palette.CHAOS_PURPLE, 0.34 * phase_value * alpha))
	draw_circle(center, radius * (0.72 + phase_value * 0.16), Palette.with_alpha(Palette.CHAOS_GREEN, 0.64 * phase_value * alpha))
	for barb_index in range(8):
		var angle := TAU * float(barb_index) / 8.0 + 0.12
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * radius * 0.62, center + direction * radius * 1.30, Palette.with_alpha(Palette.DRIED_BLOOD, 0.72 * phase_value * alpha), 2.6, true)


func _draw_corruption_spores(area: Rect2, phase_value: float, alpha: float, count: int) -> void:
	for spore_index in range(count):
		var x_ratio := float((spore_index * 37 + 11) % 101) / 100.0
		var y_ratio := float((spore_index * 61 + 23) % 101) / 100.0
		var spore_center := area.position + Vector2(area.size.x * x_ratio, area.size.y * y_ratio)
		var drift := Vector2(sin(float(spore_index) * 1.71), -0.42 - float(spore_index % 3) * 0.10) * area.size.y * 0.05 * phase_value
		spore_center += drift
		var radius := 2.0 + float(spore_index % 4) * 1.4
		draw_circle(spore_center, radius, Palette.with_alpha(Palette.CHAOS_GREEN if spore_index % 3 == 0 else Palette.DUST, 0.40 * alpha * phase_value))


func _wild_track_origin(track_index: int) -> Vector2:
	var safe_board := board_rect if board_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, size)
	match track_index:
		0:
			return safe_board.position + Vector2(0.0, safe_board.size.y * 0.22)
		1:
			return safe_board.position + Vector2(safe_board.size.x, safe_board.size.y * 0.40)
		2:
			return safe_board.position + Vector2(safe_board.size.x * 0.18, safe_board.size.y)
		_:
			return safe_board.position + Vector2(safe_board.size.x * 0.78, 0.0)


func _draw_partial_trail(points: PackedVector2Array, visible_progress: float, color: Color, width: float) -> void:
	if points.size() < 2 or visible_progress <= 0.0:
		return
	var visible_count := clampi(int(ceil(float(points.size()) * visible_progress)), 2, points.size())
	var visible_points := PackedVector2Array()
	for point_index in range(visible_count):
		visible_points.append(points[point_index])
	draw_polyline(visible_points, color, maxf(width, 1.0), true)


func _draw_layered_line(points: PackedVector2Array, outer: Color, inner: Color, outer_width: float, inner_width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, outer, maxf(outer_width, 1.0), true)
	draw_polyline(points, inner, maxf(inner_width, 1.0), true)


func _draw_tapered_curve(points: PackedVector2Array, width: float, fill: Color, edge: Color) -> void:
	for point_index in range(points.size() - 1):
		var ratio := (float(point_index) + 0.5) / float(points.size() - 1)
		var segment_width := maxf(width * (1.0 - ratio * 0.74), 1.0)
		draw_line(points[point_index], points[point_index + 1], edge, segment_width + 4.0, true)
		draw_line(points[point_index], points[point_index + 1], fill, segment_width, true)


func _jagged_segment(start_point: Vector2, end_point: Vector2, segments: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var direction := end_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.001 else Vector2.UP
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		points.append(start_point.lerp(end_point, ratio) + normal * sin(float(point_index) * 2.19) * amplitude * sin(ratio * PI))
	return points


func _quadratic_curve(start_point: Vector2, control_point: Vector2, end_point: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		points.append(_quadratic_point(start_point, control_point, end_point, ratio))
	return points


func _quadratic_point(start_point: Vector2, control_point: Vector2, end_point: Vector2, ratio: float) -> Vector2:
	var inverse := 1.0 - clampf(ratio, 0.0, 1.0)
	var safe_ratio := clampf(ratio, 0.0, 1.0)
	return start_point * inverse * inverse + control_point * 2.0 * inverse * safe_ratio + end_point * safe_ratio * safe_ratio


func _cubic_curve(start_point: Vector2, control_a: Vector2, control_b: Vector2, end_point: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		var inverse := 1.0 - ratio
		points.append(
			start_point * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * ratio
			+ control_b * 3.0 * inverse * ratio * ratio
			+ end_point * ratio * ratio * ratio
		)
	return points


func _sample_polyline(points: PackedVector2Array, ratio: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var scaled := clampf(ratio, 0.0, 1.0) * float(points.size() - 1)
	var index := mini(int(floor(scaled)), points.size() - 2)
	return points[index].lerp(points[index + 1], scaled - float(index))


func _source_scale() -> float:
	return maxf(minf(source_size.x, source_size.y), 56.0)
