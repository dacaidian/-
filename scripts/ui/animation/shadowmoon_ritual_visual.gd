extends Control

const Palette := preload("res://scripts/ui/animation/shadowmoon_vfx_palette.gd")

var animation_key := ""
var source_center := Vector2.ZERO
var destination_center := Vector2.ZERO
var board_rect := Rect2()
var source_card_size := Vector2(120.0, 168.0)
var target_rects: Array[Rect2] = []
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
	local_source_card_size: Vector2,
	local_target_rects: Array[Rect2] = []
) -> void:
	animation_key = key
	source_center = local_source_center
	destination_center = local_destination_center
	board_rect = local_board_rect
	source_card_size = local_source_card_size
	target_rects = local_target_rects.duplicate()
	queue_redraw()


func _draw() -> void:
	match animation_key:
		"fel_madness_broadcast":
			_draw_madness_broadcast()
		"demon_summon":
			_draw_demon_summon(false)
		"dark_portal":
			_draw_demon_summon(true)
		"immolation", "immolation_cast":
			_draw_immolation_cast()
		"kiljaeden_whisper", "kiljaeden_whisper_mark":
			_draw_kiljaeden_whisper()
		"immolation_mark":
			_draw_multi_immolation()
		"fel_burst_impact":
			_draw_multi_burst()
		"fel_madness", "fel_madness_chaos_orc":
			_draw_multi_madness("chaos_orc")
		"fel_madness_hellhound":
			_draw_multi_madness("hellhound")
		"fel_madness_succubus":
			_draw_multi_madness("succubus")
		"fel_madness_wolf_rider":
			_draw_multi_madness("wolf_rider")
		"fel_madness_doomguard":
			_draw_multi_madness("doomguard")
		"fel_madness_warlock":
			_draw_multi_madness("warlock")


func _draw_madness_broadcast() -> void:
	var reveal := Palette.ease_out(Palette.phase(progress, 0.0, 0.24))
	var sweep := Palette.ease_in_out(Palette.phase(progress, 0.14, 0.68))
	var recoil := Palette.ease_out(Palette.phase(progress, 0.54, 0.86))
	var settle := 1.0 - Palette.phase(progress, 0.78, 1.0)
	var safe_board := _safe_board_rect()
	var wave_y := safe_board.position.y + safe_board.size.y * sweep

	# The broadcast is a low pressure front, not a full-screen green flash.
	var wave := PackedVector2Array()
	for point_index in range(25):
		var ratio := float(point_index) / 24.0
		var x := lerpf(safe_board.position.x, safe_board.end.x, ratio)
		var y := wave_y + sin(ratio * TAU * 3.0 + progress * 5.0) * safe_board.size.y * 0.018
		wave.append(Vector2(x, y))
	_draw_layered_line(wave, Palette.with_alpha(Palette.VOID, 0.72 * settle), Palette.with_alpha(Palette.ACID, 0.52 * reveal * settle), 14.0, 3.0)

	for fissure_index in range(11):
		var ratio := float(fissure_index) / 10.0
		var start := Vector2(lerpf(safe_board.position.x, safe_board.end.x, ratio), wave_y)
		var direction_sign := -1.0 if fissure_index % 2 == 0 else 1.0
		var length := safe_board.size.y * (0.10 + 0.05 * float(fissure_index % 3)) * recoil
		var fissure := _jagged_segment(start, start + Vector2(sin(float(fissure_index) * 1.7) * 18.0, direction_sign * length), 7, 5.0)
		draw_polyline(fissure, Palette.with_alpha(Palette.CHARCOAL, 0.72 * settle), 5.0, true)
		draw_polyline(fissure, Palette.with_alpha(Palette.FEL_GREEN if fissure_index % 3 else Palette.CURSE_RED, 0.48 * settle), 1.5, true)

	for pulse_index in range(4):
		var pulse_radius := minf(safe_board.size.x, safe_board.size.y) * (0.08 + float(pulse_index) * 0.07 + recoil * 0.10)
		draw_arc(source_center, pulse_radius, -PI * 0.16, PI * 1.18, 52, Palette.with_alpha(Palette.BLOOD_PURPLE if pulse_index % 2 == 0 else Palette.FEL_GREEN, (0.34 - float(pulse_index) * 0.055) * settle), 3.2, true)


func _draw_demon_summon(is_portal: bool) -> void:
	var scale_value := maxf(minf(source_card_size.x, source_card_size.y), 52.0)
	var tear := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.38 if is_portal else 0.32))
	var emerge := Palette.ease_out(Palette.phase(progress, 0.24, 0.70))
	var bind := Palette.ease_in_out(Palette.phase(progress, 0.50, 0.84))
	var travel := Palette.ease_out(Palette.phase(progress, 0.68, 0.96))
	var settle := 1.0 - Palette.phase(progress, 0.90, 1.0)
	var portal_height := scale_value * (1.12 if is_portal else 0.78)
	var portal_width := scale_value * (0.46 if is_portal else 0.34)

	_draw_asymmetric_rift(source_center, portal_width, portal_height, tear, settle, is_portal)
	_draw_horned_shadow(source_center, scale_value * (0.48 if is_portal else 0.36), emerge, settle, is_portal)

	var seal_start := source_center + Vector2(0.0, scale_value * 0.12)
	var lift := Vector2(0.0, -scale_value * (0.74 if is_portal else 0.54))
	var seal_center := seal_start + lift * bind
	_draw_contract_seal(seal_center, scale_value * (0.18 if is_portal else 0.14), bind, settle)
	if travel > 0.0:
		var normal := (destination_center - seal_center).normalized().orthogonal()
		var path := _quadratic_curve(seal_center, seal_center.lerp(destination_center, 0.5) + normal * scale_value * 0.42, destination_center, 30, travel)
		_draw_layered_line(path, Palette.with_alpha(Palette.DEEP_PURPLE, 0.74 * settle), Palette.with_alpha(Palette.ACID, 0.70 * settle), scale_value * 0.042, scale_value * 0.012)
		var moving_center := _quadratic_point(seal_center, seal_center.lerp(destination_center, 0.5) + normal * scale_value * 0.42, destination_center, travel)
		_draw_contract_seal(moving_center, scale_value * (0.14 if is_portal else 0.11), 1.0, settle)

	for spark_index in range(10 if is_portal else 6):
		var angle := TAU * float(spark_index) / float(10 if is_portal else 6) + progress * (0.8 if spark_index % 2 else -0.6)
		var spark_center := source_center + Vector2(cos(angle), sin(angle)) * scale_value * (0.36 + emerge * 0.32)
		draw_circle(spark_center, scale_value * 0.018, Palette.with_alpha(Palette.ACID if spark_index % 3 else Palette.DEMON_ORANGE, 0.72 * settle))


func _draw_immolation_cast() -> void:
	var scale_value := maxf(minf(source_card_size.x, source_card_size.y), 52.0)
	var heat := Palette.ease_out(Palette.phase(progress, 0.0, 0.30))
	var spread := Palette.ease_in_out(Palette.phase(progress, 0.18, 0.70))
	var slam := Palette.ease_out(Palette.phase(progress, 0.46, 0.86))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var ground_center := source_center + Vector2(0.0, source_card_size.y * 0.38)

	for ring_index in range(4):
		var radius := scale_value * (0.18 + spread * (0.28 + float(ring_index) * 0.16))
		draw_arc(ground_center, radius, PI * 0.04, PI * 0.96, 46, Palette.with_alpha(Palette.DEMON_ORANGE if ring_index % 2 == 0 else Palette.FEL_GREEN, (0.62 - float(ring_index) * 0.10) * settle), 4.0 - float(ring_index) * 0.55, true)

	for flame_index in range(14):
		var angle := PI * (0.04 + float(flame_index) / 15.0)
		var direction := Vector2(cos(angle), sin(angle))
		var base := ground_center + direction * scale_value * (0.16 + spread * 0.52)
		var height := scale_value * (0.16 + float(flame_index % 4) * 0.045) * heat
		_draw_fel_flame(base, direction, height, scale_value * 0.055, settle)

	for crack_index in range(12):
		var angle := TAU * float(crack_index) / 12.0 + 0.12
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(ground_center, ground_center + direction * scale_value * (0.18 + slam * 0.58), 8, scale_value * 0.020)
		draw_polyline(crack, Palette.with_alpha(Palette.CHARCOAL, 0.90 * settle), 5.0, true)
		draw_polyline(crack, Palette.with_alpha(Palette.ACID if crack_index % 3 != 0 else Palette.EMBER, 0.72 * settle), 1.7, true)


func _draw_kiljaeden_whisper() -> void:
	if target_rects.is_empty():
		return
	var gather := Palette.ease_out(Palette.phase(progress, 0.0, 0.30))
	var whisper := Palette.ease_in_out(Palette.phase(progress, 0.16, 0.76))
	var bind := Palette.ease_out(Palette.phase(progress, 0.52, 0.90))
	var settle := 1.0 - Palette.phase(progress, 0.84, 1.0)
	var bounds := _bounds_for_targets()
	var eye_center := Vector2(bounds.get_center().x, bounds.position.y - maxf(bounds.size.y * 0.16, 42.0))
	var eye_radius := maxf(minf(bounds.size.x * 0.18, bounds.size.y * 0.22), 44.0)
	_draw_whisper_eye(eye_center, eye_radius, gather, settle)

	for target_index in range(target_rects.size()):
		var target := target_rects[target_index]
		var end := target.get_center() - Vector2(0.0, target.size.y * 0.22)
		var side := -1.0 if target_index % 2 == 0 else 1.0
		var control := eye_center.lerp(end, 0.52) + Vector2(side * eye_radius * (0.34 + float(target_index % 3) * 0.10), 0.0)
		var thread := _quadratic_curve(eye_center, control, end, 24, whisper)
		_draw_layered_line(thread, Palette.with_alpha(Palette.VOID, 0.72 * settle), Palette.with_alpha(Palette.CURSE_RED if target_index % 2 == 0 else Palette.FEL_GREEN, 0.50 * settle), 4.4, 1.4)
		_draw_target_whisper_mark(target, bind, settle, target_index)


func _draw_multi_madness(response_type: String) -> void:
	var mutate := Palette.ease_out(Palette.phase(progress, 0.0, 0.62))
	var pulse := Palette.ease_in_out(Palette.phase(progress, 0.20, 0.82))
	var settle := 1.0 - Palette.phase(progress, 0.78, 1.0)
	for target_index in range(target_rects.size()):
		var target := target_rects[target_index]
		var stagger := clampf(mutate * 1.18 - float(target_index % 4) * 0.07, 0.0, 1.0)
		_draw_corroded_target_frame(target, stagger, settle)
		match response_type:
			"hellhound":
				_draw_jaw_mark(target.get_center(), minf(target.size.x, target.size.y) * 0.34, pulse, settle)
				_draw_action_mark(target.position + Vector2(target.size.x * 0.82, target.size.y * 0.18), minf(target.size.x, target.size.y) * 0.10, pulse, settle)
			"succubus":
				_draw_soul_vortex(target.get_center(), minf(target.size.x, target.size.y) * 0.30, pulse, settle)
			"wolf_rider":
				_draw_jaw_mark(target.get_center() + Vector2(0.0, target.size.y * 0.12), minf(target.size.x, target.size.y) * 0.40, pulse, settle)
			"doomguard":
				_draw_horn_mark(target.get_center() - Vector2(0.0, target.size.y * 0.12), minf(target.size.x, target.size.y) * 0.42, stagger, settle)
			"warlock":
				_draw_whisper_eye(target.get_center(), minf(target.size.x, target.size.y) * 0.30, pulse, settle)
			_:
				_draw_claw_mark(target.get_center(), minf(target.size.x, target.size.y) * 0.72, stagger, settle)


func _draw_multi_immolation() -> void:
	var ignite := Palette.ease_out(Palette.phase(progress, 0.0, 0.58))
	var settle := 1.0 - Palette.phase(progress, 0.72, 1.0)
	for target_index in range(target_rects.size()):
		var target := target_rects[target_index]
		var local_phase := clampf(ignite * 1.16 - float(target_index % 4) * 0.06, 0.0, 1.0)
		var ground := target.position + Vector2(target.size.x * 0.5, target.size.y * 0.88)
		for flame_index in range(5):
			var ratio := float(flame_index) / 4.0
			var base := Vector2(lerpf(target.position.x + target.size.x * 0.14, target.end.x - target.size.x * 0.14, ratio), ground.y)
			_draw_fel_flame(base, Vector2.UP, target.size.y * (0.12 + 0.035 * float(flame_index % 3)) * local_phase, target.size.x * 0.045, settle)
		_draw_ground_cracks(ground, minf(target.size.x, target.size.y) * 0.36, local_phase, settle, 6)


func _draw_multi_burst() -> void:
	var impact := Palette.ease_out(Palette.phase(progress, 0.0, 0.58))
	var settle := 1.0 - Palette.phase(progress, 0.62, 1.0)
	for target_index in range(target_rects.size()):
		var target := target_rects[target_index]
		var center := target.get_center()
		var radius := minf(target.size.x, target.size.y)
		var local_phase := clampf(impact * 1.18 - float(target_index % 5) * 0.055, 0.0, 1.0)
		for ring_index in range(3):
			draw_arc(center, radius * (0.08 + local_phase * (0.13 + float(ring_index) * 0.10)), 0.0, TAU, 42, Palette.with_alpha(Palette.ACID if ring_index != 1 else Palette.CURSE_RED, (0.68 - float(ring_index) * 0.15) * settle), 3.0, true)
		_draw_ground_cracks(center, radius * 0.42, local_phase, settle, 8)


func _draw_asymmetric_rift(center: Vector2, half_width: float, half_height: float, phase_value: float, alpha: float, is_portal: bool) -> void:
	# The opening frame collapses every vertex onto one line; skip that degenerate
	# polygon until the spatial membrane has enough area to triangulate reliably.
	if phase_value <= 0.01 or alpha <= 0.01:
		return
	var height := half_height * phase_value
	var width := half_width * (0.30 + phase_value * 0.70)
	var membrane := PackedVector2Array([
		center + Vector2(0.0, -height),
		center + Vector2(width * 0.72, -height * 0.62),
		center + Vector2(width, -height * 0.08),
		center + Vector2(width * 0.64, height * 0.58),
		center + Vector2(-width * 0.08, height),
		center + Vector2(-width * 0.82, height * 0.54),
		center + Vector2(-width, -height * 0.12),
		center + Vector2(-width * 0.56, -height * 0.70),
	])
	draw_colored_polygon(membrane, Palette.with_alpha(Palette.VOID, (0.90 if is_portal else 0.80) * alpha))
	var closed := membrane.duplicate()
	closed.append(membrane[0])
	draw_polyline(closed, Palette.with_alpha(Palette.ACID, (0.92 if is_portal else 0.78) * alpha), 6.0 if is_portal else 4.0, true)
	for split_index in range(5):
		var x_offset := width * lerpf(-0.44, 0.44, float(split_index) / 4.0)
		var split := _jagged_segment(center + Vector2(x_offset, -height * 0.76), center + Vector2(x_offset * 0.48, height * 0.72), 9, half_width * 0.055)
		draw_polyline(split, Palette.with_alpha(Palette.DEEP_PURPLE if split_index % 2 == 0 else Palette.INK_GREEN, 0.70 * alpha), 2.0, true)


func _draw_horned_shadow(center: Vector2, radius: float, phase_value: float, alpha: float, is_portal: bool) -> void:
	var body_alpha := (0.60 if is_portal else 0.44) * phase_value * alpha
	var body := PackedVector2Array([
		center + Vector2(-radius * 0.42, radius * 0.62),
		center + Vector2(-radius * 0.30, -radius * 0.10),
		center + Vector2(0.0, -radius * 0.36),
		center + Vector2(radius * 0.32, -radius * 0.08),
		center + Vector2(radius * 0.44, radius * 0.62),
	])
	draw_colored_polygon(body, Palette.with_alpha(Palette.DEEP_PURPLE, body_alpha))
	for side_sign_value in [-1.0, 1.0]:
		var side_sign: float = float(side_sign_value)
		var horn := _quadratic_curve(
			center + Vector2(side_sign * radius * 0.12, -radius * 0.30),
			center + Vector2(side_sign * radius * 0.76, -radius * 0.68),
			center + Vector2(side_sign * radius * 0.52, -radius),
			18,
			phase_value
		)
		draw_polyline(horn, Palette.with_alpha(Palette.SICK_YELLOW, 0.66 * alpha), radius * 0.075, true)


func _draw_contract_seal(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	for arc_index in range(3):
		var start := -PI * 0.65 + float(arc_index) * TAU / 3.0
		draw_arc(center, radius * (0.72 + float(arc_index) * 0.15), start, start + PI * 0.82 * phase_value, 20, Palette.with_alpha(Palette.ACID if arc_index != 1 else Palette.CURSE_RED, (0.82 - float(arc_index) * 0.14) * alpha), 2.4, true)
	var triangle := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.66),
		center + Vector2(radius * 0.58, radius * 0.40),
		center + Vector2(-radius * 0.58, radius * 0.40),
		center + Vector2(0.0, -radius * 0.66),
	])
	draw_polyline(triangle, Palette.with_alpha(Palette.SICK_YELLOW, 0.72 * phase_value * alpha), 2.0, true)


func _draw_whisper_eye(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	var eye_height := radius * (0.12 + phase_value * 0.28)
	var left := center - Vector2(radius, 0.0)
	var right := center + Vector2(radius, 0.0)
	var upper := _quadratic_curve(left, center - Vector2(0.0, eye_height), right, 24, 1.0)
	var lower := _quadratic_curve(left, center + Vector2(0.0, eye_height), right, 24, 1.0)
	_draw_layered_line(upper, Palette.with_alpha(Palette.VOID, 0.82 * alpha), Palette.with_alpha(Palette.CURSE_RED, 0.68 * alpha), radius * 0.09, radius * 0.026)
	_draw_layered_line(lower, Palette.with_alpha(Palette.VOID, 0.82 * alpha), Palette.with_alpha(Palette.CURSE_RED, 0.68 * alpha), radius * 0.09, radius * 0.026)
	draw_circle(center, radius * 0.16 * phase_value, Palette.with_alpha(Palette.ACID, 0.76 * alpha))
	draw_circle(center, radius * 0.07 * phase_value, Palette.with_alpha(Palette.VOID, 0.94 * alpha))


func _draw_target_whisper_mark(target: Rect2, phase_value: float, alpha: float, target_index: int) -> void:
	var center := target.get_center()
	var radius := minf(target.size.x, target.size.y) * (0.34 + phase_value * 0.05)
	for wave_index in range(3):
		var start := -PI * 0.16 + float(wave_index) * 0.38 + float(target_index % 2) * 0.12
		draw_arc(center, radius * (0.70 + float(wave_index) * 0.16), start, start + PI * 1.14, 34, Palette.with_alpha(Palette.BLOOD_PURPLE if wave_index % 2 == 0 else Palette.FEL_GREEN, (0.54 - float(wave_index) * 0.12) * alpha), 2.0, true)


func _draw_corroded_target_frame(target: Rect2, phase_value: float, alpha: float) -> void:
	var corners := [target.position, Vector2(target.end.x, target.position.y), target.end, Vector2(target.position.x, target.end.y)]
	for edge_index in range(4):
		var start: Vector2 = corners[edge_index]
		var finish: Vector2 = corners[(edge_index + 1) % 4]
		var edge := _jagged_segment(start, start.lerp(finish, phase_value), 9, minf(target.size.x, target.size.y) * 0.014)
		_draw_layered_line(edge, Palette.with_alpha(Palette.VOID, 0.76 * alpha), Palette.with_alpha(Palette.FEL_GREEN if edge_index % 2 else Palette.BLOOD_PURPLE, 0.56 * alpha), 4.0, 1.3)


func _draw_jaw_mark(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	var gap := radius * (0.38 - phase_value * 0.28)
	for jaw_sign_value in [-1.0, 1.0]:
		var jaw_sign: float = float(jaw_sign_value)
		var jaw := _quadratic_curve(center + Vector2(-radius * 0.68, jaw_sign * gap), center + Vector2(0.0, jaw_sign * (gap + radius * 0.34)), center + Vector2(radius * 0.68, jaw_sign * gap), 18, 1.0)
		_draw_layered_line(jaw, Palette.with_alpha(Palette.VOID, 0.82 * alpha), Palette.with_alpha(Palette.CURSE_RED, 0.70 * alpha), radius * 0.12, radius * 0.040)


func _draw_action_mark(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	draw_arc(center, radius, -PI * 0.70, PI * 0.82, 26, Palette.with_alpha(Palette.ACID, 0.76 * alpha), 2.4, true)
	draw_line(center + Vector2(-radius * 0.12, -radius * 0.46), center + Vector2(radius * 0.14, radius * 0.44) * phase_value, Palette.with_alpha(Palette.HOT_CORE, 0.84 * alpha), 2.2, true)


func _draw_soul_vortex(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	for loop_index in range(4):
		var loop_radius := radius * (0.42 + float(loop_index) * 0.18 + phase_value * 0.08)
		draw_arc(center, loop_radius, -PI * 0.22 + float(loop_index) * 0.42, PI * 1.36 + float(loop_index) * 0.42, 34, Palette.with_alpha(Palette.SOUL_PURPLE if loop_index % 2 == 0 else Palette.SOUL_BLUE, (0.62 - float(loop_index) * 0.10) * alpha), 2.0, true)
	draw_circle(center, radius * 0.13, Palette.with_alpha(Palette.CURSE_RED, 0.70 * alpha))


func _draw_horn_mark(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	for side_sign_value in [-1.0, 1.0]:
		var side_sign: float = float(side_sign_value)
		var horn := _quadratic_curve(center + Vector2(side_sign * radius * 0.12, radius * 0.22), center + Vector2(side_sign * radius * 0.82, -radius * 0.08), center + Vector2(side_sign * radius * 0.42, -radius * phase_value), 18, 1.0)
		_draw_layered_line(horn, Palette.with_alpha(Palette.VOID, 0.82 * alpha), Palette.with_alpha(Palette.SICK_YELLOW, 0.68 * alpha), radius * 0.13, radius * 0.045)


func _draw_claw_mark(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	for slash_index in range(3):
		var shift := Vector2(float(slash_index - 1) * radius * 0.16, float(slash_index - 1) * radius * 0.04)
		var slash := _jagged_segment(center + shift + Vector2(-radius * 0.34, radius * 0.30), center + shift + Vector2(radius * 0.28, -radius * 0.34) * phase_value, 8, radius * 0.025)
		_draw_layered_line(slash, Palette.with_alpha(Palette.VOID, 0.86 * alpha), Palette.with_alpha(Palette.CURSE_RED if slash_index != 1 else Palette.FEL_GREEN, 0.76 * alpha), radius * 0.075, radius * 0.024)


func _draw_fel_flame(base: Vector2, direction: Vector2, height: float, half_width: float, alpha: float) -> void:
	if height <= 0.0:
		return
	var forward := direction.normalized()
	var side := forward.orthogonal()
	var tip := base + forward * height
	var outer := PackedVector2Array([
		base - side * half_width,
		base + forward * height * 0.42 - side * half_width * 0.46,
		tip + side * sin(progress * 8.0 + base.x * 0.01) * half_width * 0.42,
		base + forward * height * 0.34 + side * half_width * 0.52,
		base + side * half_width,
	])
	draw_colored_polygon(outer, Palette.with_alpha(Palette.DEMON_ORANGE, 0.60 * alpha))
	draw_line(base, base + forward * height * 0.72, Palette.with_alpha(Palette.ACID, 0.84 * alpha), half_width * 0.62, true)


func _draw_ground_cracks(center: Vector2, radius: float, phase_value: float, alpha: float, count: int) -> void:
	for crack_index in range(count):
		var angle := TAU * float(crack_index) / float(count) + 0.13
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(center, center + direction * radius * phase_value, 6, radius * 0.045)
		draw_polyline(crack, Palette.with_alpha(Palette.CHARCOAL, 0.86 * alpha), 4.0, true)
		draw_polyline(crack, Palette.with_alpha(Palette.FEL_GREEN if crack_index % 3 else Palette.DEMON_ORANGE, 0.66 * alpha), 1.4, true)


func _safe_board_rect() -> Rect2:
	if board_rect.size.x > 1.0 and board_rect.size.y > 1.0:
		return board_rect
	return Rect2(Vector2(size.x * 0.08, size.y * 0.08), size * 0.84)


func _bounds_for_targets() -> Rect2:
	if target_rects.is_empty():
		return _safe_board_rect()
	var bounds := target_rects[0]
	for target_index in range(1, target_rects.size()):
		bounds = bounds.merge(target_rects[target_index])
	return bounds


func _draw_layered_line(points: PackedVector2Array, outer: Color, inner: Color, outer_width: float, inner_width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, outer, maxf(outer_width, 1.0), true)
	draw_polyline(points, inner, maxf(inner_width, 1.0), true)


func _jagged_segment(start_point: Vector2, end_point: Vector2, segments: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var direction := end_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.001 else Vector2.UP
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		var offset := sin(float(point_index) * 2.31 + ratio * 2.8) * amplitude * sin(ratio * PI)
		points.append(start_point.lerp(end_point, ratio) + normal * offset)
	return points


func _quadratic_curve(start_point: Vector2, control: Vector2, end_point: Vector2, segments: int, visible_progress: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_progress := clampf(visible_progress, 0.0, 1.0)
	var visible_segments := maxi(int(ceil(float(segments) * safe_progress)), 1)
	for point_index in range(visible_segments + 1):
		var ratio := float(point_index) / float(visible_segments) * safe_progress
		points.append(_quadratic_point(start_point, control, end_point, ratio))
	return points


func _quadratic_point(start_point: Vector2, control: Vector2, end_point: Vector2, ratio: float) -> Vector2:
	var inverse := 1.0 - ratio
	return start_point * inverse * inverse + control * 2.0 * inverse * ratio + end_point * ratio * ratio
