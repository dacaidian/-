extends "res://scripts/ui/animation/throttled_progress_visual.gd"

# Mutation, offspring-pool and passive milestone presentation. These events
# use a biological grammar distinct from combat so board-wide unlocks remain
# readable without turning every action into another attack effect.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const VOID := Color(0.006, 0.003, 0.014, 0.98)
const BLACK_FLESH := Color(0.035, 0.008, 0.028, 0.97)
const DEEP_RED := Color(0.24, 0.008, 0.05, 0.96)
const LIVING_RED := Color(0.76, 0.02, 0.10, 0.95)
const HOT_RED := Color(1.0, 0.12, 0.19, 0.96)
const WET_WHITE := Color(1.0, 0.78, 0.82, 0.88)
const CELL_VIOLET := Color(0.34, 0.035, 0.46, 0.76)
const SILENCE_BLUE := Color(0.09, 0.20, 0.32, 0.76)
const SILENCE_WHITE := Color(0.68, 0.88, 0.92, 0.82)
const COSMIC_RED := Color(0.50, 0.012, 0.09, 0.92)

var animation_key := ""
var center := Vector2.ZERO
var card_size := Vector2(120.0, 168.0)
var is_board_event := false
var multi_centers: Array[Vector2] = []


func configure(
	key: String,
	local_center: Vector2,
	local_card_size: Vector2,
	board_event := false,
	local_multi_centers: Array[Vector2] = []
) -> void:
	animation_key = key
	center = local_center
	card_size = local_card_size
	is_board_event = board_event
	multi_centers = local_multi_centers.duplicate()
	set_visual_redraw_fps(24.0)
	request_visual_redraw(true)


func _draw() -> void:
	var appear := _ease_out(_phase(0.0, 0.13))
	var fade := 1.0 - _ease_in(_phase(0.84, 1.0))
	var alpha := appear * fade
	if alpha <= 0.002:
		return

	match animation_key:
		"symbiote_pool_unlock_silence":
			_draw_pool_unlock(alpha, "silence")
		"symbiote_pool_unlock_hybrid":
			_draw_pool_unlock(alpha, "hybrid")
		"symbiote_pool_unlock_advanced":
			_draw_pool_unlock(alpha, "advanced")
		"symbiote_offspring_emergence":
			_draw_offspring_emergence(alpha)
		"symbiote_carnage_escalation":
			_draw_carnage_escalation(alpha)
		"symbiote_silence_manifest":
			_draw_silence_manifest(alpha)
		"symbiote_sleeper_spawn":
			_draw_sleeper_spawn(alpha)
		"symbiote_knull_aura_awaken":
			_draw_knull_awaken(alpha, false, center)
		"symbiote_knull_aura_receive":
			if multi_centers.is_empty():
				_draw_knull_awaken(alpha, true, center)
			else:
				for receiver_center in multi_centers:
					_draw_knull_awaken(alpha, true, receiver_center)


func _draw_pool_unlock(alpha: float, profile: String) -> void:
	var gather := _ease_in_out(_phase(0.0, 0.34))
	var rupture := _ease_out(_phase(0.28, 0.68))
	var reveal := _ease_out(_phase(0.58, 0.92))
	var board_scale := maxf(minf(size.x, size.y) * 0.16, 96.0)
	var event_center := center if center != Vector2.ZERO else size * 0.5
	var pod_count := 3 if profile == "advanced" else 1

	Toolkit.draw_soft_ellipse(
		self,
		event_center,
		Vector2(board_scale * (1.45 + rupture * 0.24), board_scale * (0.58 + rupture * 0.10)),
		Toolkit.with_alpha(CELL_VIOLET if profile == "silence" else DEEP_RED, alpha * 0.30),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
		8
	)

	for vein_index in range(12):
		var angle := TAU * float(vein_index) / 12.0 + sin(float(vein_index) * 1.7) * 0.14
		var start_point := event_center + Vector2.from_angle(angle + 0.36) * board_scale * 0.12
		var finish_point := event_center + Vector2.from_angle(angle) * board_scale * (0.62 + gather * 1.25)
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, board_scale * 0.22, gather, 18, -1.0 if vein_index % 2 else 1.0),
			board_scale * (0.026 + float(vein_index % 3) * 0.006),
			Toolkit.with_alpha(LIVING_RED, alpha * 0.74),
			Toolkit.with_alpha(VOID, alpha * 0.94),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.22),
			board_scale * 0.11,
			true,
			true,
			progress * 5.0 + vein_index
		)

	for pod_index in range(pod_count):
		var x_offset := (float(pod_index) - float(pod_count - 1) * 0.5) * board_scale * 0.72
		var pod_center := event_center + Vector2(x_offset, sin(float(pod_index) * 2.1) * board_scale * 0.08)
		_draw_mutation_pod(pod_center, board_scale * (0.34 if pod_count > 1 else 0.48), gather, rupture, alpha, profile, pod_index)

	if reveal > 0.01:
		var ring_color := SILENCE_WHITE if profile == "silence" else WET_WHITE
		for ring_index in range(3):
			var ring_phase := clampf(reveal * 1.18 - float(ring_index) * 0.12, 0.0, 1.0)
			Toolkit.draw_stroked_arc(
				self,
				event_center,
				board_scale * (0.52 + ring_phase * (0.80 + ring_index * 0.16)),
				float(ring_index) * 1.9,
				float(ring_index) * 1.9 + PI * 1.38,
				board_scale * 0.020,
				Toolkit.with_alpha(ring_color, alpha * (0.52 - ring_phase * 0.28)),
				Toolkit.with_alpha(VOID, alpha * 0.55),
				Color.TRANSPARENT,
				board_scale * 0.09,
				32
			)


func _draw_mutation_pod(
	pod_center: Vector2,
	radius: float,
	growth: float,
	rupture: float,
	alpha: float,
	profile: String,
	pod_index: int
) -> void:
	var pod_color := SILENCE_BLUE if profile == "silence" else DEEP_RED
	if profile == "advanced":
		pod_color = [LIVING_RED, Color(0.50, 0.018, 0.24, 0.94), Color(0.16, 0.04, 0.22, 0.94)][pod_index % 3]
	Toolkit.draw_soft_ellipse(
		self,
		pod_center,
		Vector2(radius * (0.76 + growth * 0.18), radius * (1.10 + growth * 0.22)),
		Toolkit.with_alpha(pod_color, alpha * (0.44 + growth * 0.18)),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
		7
	)
	for seam_index in range(4):
		var seam_offset := (float(seam_index) - 1.5) * radius * 0.18
		var seam_start := pod_center + Vector2(seam_offset, -radius * 0.82)
		var seam_end := pod_center + Vector2(-seam_offset * 0.62, radius * 0.82)
		var split := seam_start.lerp(seam_end, clampf(growth + rupture * 0.18, 0.0, 1.0))
		Toolkit.draw_ribbon(
			self,
			_curved_path(seam_start, split, radius * 0.13, 1.0, 12, -1.0 if seam_index % 2 else 1.0),
			radius * 0.055,
			Toolkit.with_alpha(BLACK_FLESH, alpha * 0.90),
			Toolkit.with_alpha(VOID, alpha * 0.96),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.32),
			radius * 0.18,
			true,
			true,
			progress * 4.0 + seam_index
		)
	if rupture > 0.01:
		for shard_index in range(7):
			var angle := TAU * float(shard_index) / 7.0 + pod_index * 0.24
			var direction := Vector2.from_angle(angle)
			var point := pod_center + direction * radius * (0.56 + rupture * 0.84)
			var tangent := direction.orthogonal()
			var shard := PackedVector2Array([
				point - tangent * radius * 0.11,
				point + direction * radius * 0.28,
				point + tangent * radius * 0.11,
			])
			draw_colored_polygon(shard, Toolkit.with_alpha(pod_color, alpha * (1.0 - rupture * 0.34)))
			draw_polyline(_closed(shard), Toolkit.with_alpha(WET_WHITE, alpha * 0.30), maxf(radius * 0.025, 1.0), true)


func _draw_offspring_emergence(alpha: float) -> void:
	var root_phase := _ease_in_out(_phase(0.0, 0.34))
	var peel := _ease_out(_phase(0.24, 0.72))
	var settle := _ease_out(_phase(0.62, 0.94))
	var scale_value := _scale()
	Toolkit.draw_soft_ellipse(
		self,
		center,
		Vector2(scale_value * (0.42 + root_phase * 0.16), scale_value * (0.62 + root_phase * 0.18)),
		Toolkit.with_alpha(DEEP_RED, alpha * 0.38),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.40),
		7
	)
	for peel_index in range(8):
		var angle := TAU * float(peel_index) / 8.0 + 0.18
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var root := center + direction * scale_value * 0.12
		var tip := center + direction * scale_value * (0.40 + peel * 0.34)
		var membrane := PackedVector2Array([
			root - tangent * scale_value * 0.07,
			tip,
			root + tangent * scale_value * 0.07,
		])
		draw_colored_polygon(membrane, Toolkit.with_alpha(LIVING_RED, alpha * (0.56 - peel * 0.16)))
		draw_polyline(_closed(membrane), Toolkit.with_alpha(WET_WHITE, alpha * 0.28), scale_value * 0.010, true)
	if settle > 0.01:
		_draw_card_seams(center, card_size, settle, alpha, LIVING_RED)


func _draw_carnage_escalation(alpha: float) -> void:
	var notch := _ease_in_out(_phase(0.0, 0.38))
	var surge := _ease_out(_phase(0.30, 0.84))
	var scale_value := _scale()
	for side in [-1.0, 1.0]:
		var side_sign := float(side)
		var start_point := center + Vector2(side_sign * scale_value * 0.52, -scale_value * 0.38)
		var finish_point := center + Vector2(side_sign * scale_value * 0.08, scale_value * 0.10)
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, scale_value * 0.16, notch, 14, -side_sign),
			scale_value * 0.060,
			Toolkit.with_alpha(HOT_RED, alpha * 0.92),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.52),
			scale_value * 0.22,
			true,
			true,
			progress * 7.0 + side_sign
		)
	Toolkit.draw_soft_disc(
		self,
		center,
		scale_value * (0.14 + surge * 0.16),
		Toolkit.with_alpha(DEEP_RED, alpha * 0.46),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.70),
		7
	)
	for scythe_index in range(4):
		var start_angle := float(scythe_index) * PI * 0.5 + progress * 0.26
		Toolkit.draw_arc_ribbon(
			self,
			center,
			scale_value * (0.34 + surge * 0.22),
			start_angle,
			start_angle + PI * 0.62,
			scale_value * 0.045,
			Toolkit.with_alpha(LIVING_RED, alpha * surge * 0.82),
			Toolkit.with_alpha(VOID, alpha * 0.94),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.38),
			scale_value * 0.17,
			20,
			true,
			true,
			progress * 5.0 + scythe_index
		)


func _draw_silence_manifest(alpha: float) -> void:
	var expand := _ease_out(_phase(0.0, 0.54))
	var mute := _ease_in_out(_phase(0.42, 0.86))
	var scale_value := _scale()
	Toolkit.draw_soft_ellipse(
		self,
		center,
		Vector2(scale_value * (0.32 + expand * 0.22), scale_value * (0.18 + expand * 0.08)),
		Toolkit.with_alpha(SILENCE_BLUE, alpha * 0.48),
		Toolkit.with_alpha(SILENCE_WHITE, alpha * 0.48),
		7
	)
	for membrane_index in range(4):
		var radius := scale_value * (0.28 + membrane_index * 0.10)
		var collapse := lerpf(1.0, 0.44, mute)
		Toolkit.draw_stroked_arc(
			self,
			center,
			radius * collapse,
			float(membrane_index) * 0.72,
			float(membrane_index) * 0.72 + PI * 1.45,
			scale_value * (0.030 - membrane_index * 0.003),
			Toolkit.with_alpha(SILENCE_WHITE, alpha * (0.72 - membrane_index * 0.10)),
			Toolkit.with_alpha(VOID, alpha * 0.86),
			Color.TRANSPARENT,
			scale_value * 0.11,
			26
		)
	var mouth_width := scale_value * (0.34 - mute * 0.12)
	draw_line(
		center - Vector2(mouth_width, 0.0),
		center + Vector2(mouth_width, 0.0),
		Toolkit.with_alpha(VOID, alpha * 0.96),
		scale_value * (0.050 + mute * 0.025),
		true
	)


func _draw_sleeper_spawn(alpha: float) -> void:
	var grow := _ease_in_out(_phase(0.0, 0.52))
	var hatch := _ease_out(_phase(0.44, 0.86))
	var scale_value := _scale()
	var pod_center := center + Vector2(0.0, scale_value * 0.08)
	Toolkit.draw_soft_ellipse(
		self,
		pod_center,
		Vector2(scale_value * (0.20 + grow * 0.10), scale_value * (0.27 + grow * 0.14)),
		Toolkit.with_alpha(Color(0.13, 0.025, 0.16, 0.92), alpha * 0.54),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.44),
		7
	)
	for crack_index in range(5):
		var angle := -PI * 0.80 + float(crack_index) * PI * 0.40
		var start_point := pod_center + Vector2.from_angle(angle) * scale_value * 0.05
		var finish_point := pod_center + Vector2.from_angle(angle) * scale_value * (0.12 + hatch * 0.28)
		draw_line(start_point, finish_point, Toolkit.with_alpha(HOT_RED, alpha * hatch * 0.72), scale_value * 0.018, true)
	if hatch > 0.01:
		var paw_center := pod_center - Vector2(0.0, scale_value * 0.07)
		draw_circle(paw_center, scale_value * 0.075 * hatch, Toolkit.with_alpha(BLACK_FLESH, alpha * 0.92))
		for toe_index in range(4):
			var toe_angle := lerpf(-PI * 0.85, -PI * 0.15, float(toe_index) / 3.0)
			var toe := paw_center + Vector2.from_angle(toe_angle) * scale_value * 0.12
			draw_circle(toe, scale_value * 0.030 * hatch, Toolkit.with_alpha(LIVING_RED, alpha * 0.82))


func _draw_knull_awaken(
	alpha: float,
	receiver: bool,
	effect_center: Vector2
) -> void:
	var awaken := _ease_out(_phase(0.0, 0.48))
	var bind := _ease_in_out(_phase(0.36, 0.84))
	var scale_value := _scale()
	var radius_multiplier := 0.72 if receiver else 1.0
	Toolkit.draw_soft_disc(
		self,
		effect_center,
		scale_value * (0.20 + awaken * 0.18) * radius_multiplier,
		Toolkit.with_alpha(CELL_VIOLET, alpha * 0.34),
		Toolkit.with_alpha(HOT_RED, alpha * 0.54),
		7
	)
	for tendril_index in range(8 if not receiver else 5):
		var angle := TAU * float(tendril_index) / float(8 if not receiver else 5) + 0.20
		var start_point := effect_center + Vector2.from_angle(angle + 0.38) * scale_value * 0.10
		var finish_point := effect_center + Vector2.from_angle(angle) * scale_value * (0.48 + awaken * 0.34) * radius_multiplier
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, scale_value * 0.18, awaken, 16, -1.0 if tendril_index % 2 else 1.0),
			scale_value * 0.038,
			Toolkit.with_alpha(COSMIC_RED, alpha * 0.82),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
			scale_value * 0.15,
			true,
			true,
			progress * 5.0 + tendril_index
		)
	if bind > 0.01:
		_draw_crown(effect_center - Vector2(0.0, scale_value * 0.22), scale_value * 0.42 * radius_multiplier, bind, alpha)
		_draw_card_seams(effect_center, card_size, bind, alpha, COSMIC_RED)


func _draw_crown(crown_center: Vector2, radius: float, strength: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for point_index in range(9):
		var ratio := float(point_index) / 8.0
		var x_value := lerpf(-radius, radius, ratio)
		var peak := 0.32 if point_index % 2 == 0 else 0.76
		points.append(crown_center + Vector2(x_value, -radius * peak * strength))
	Toolkit.draw_stroked_path(
		self,
		points,
		maxf(radius * 0.075, 1.4),
		Toolkit.with_alpha(HOT_RED, alpha * 0.84),
		Toolkit.with_alpha(VOID, alpha * 0.96),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.38),
		radius * 0.22
	)


func _draw_card_seams(
	card_center: Vector2,
	local_card_size: Vector2,
	strength: float,
	alpha: float,
	seam_color: Color
) -> void:
	var half_size := local_card_size * Vector2(0.47, 0.47)
	var corners := [
		card_center + Vector2(-half_size.x, -half_size.y),
		card_center + Vector2(half_size.x, -half_size.y),
		card_center + Vector2(half_size.x, half_size.y),
		card_center + Vector2(-half_size.x, half_size.y),
	]
	for edge_index in range(4):
		var start_point: Vector2 = corners[edge_index]
		var finish_point: Vector2 = corners[(edge_index + 1) % 4]
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, _scale() * 0.04, strength, 12, -1.0 if edge_index % 2 else 1.0),
			_scale() * 0.027,
			Toolkit.with_alpha(seam_color, alpha * 0.74),
			Toolkit.with_alpha(VOID, alpha * 0.90),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.24),
			_scale() * 0.10,
			true,
			true,
			progress * 3.0 + edge_index
		)


func _curved_path(
	start_point: Vector2,
	finish_point: Vector2,
	curve_amount: float,
	visible_ratio: float,
	segments: int,
	curve_sign := 1.0
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var clamped_ratio := clampf(visible_ratio, 0.0, 1.0)
	if clamped_ratio <= 0.0001:
		return points
	var direction := finish_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.01 else Vector2.UP
	var control_a := start_point.lerp(finish_point, 0.32) + normal * curve_amount * curve_sign
	var control_b := start_point.lerp(finish_point, 0.72) - normal * curve_amount * 0.42 * curve_sign
	var safe_segments := maxi(segments, 4)
	for point_index in range(safe_segments + 1):
		var ratio := clamped_ratio * float(point_index) / float(safe_segments)
		var inverse := 1.0 - ratio
		points.append(
			start_point * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * ratio
			+ control_b * 3.0 * inverse * ratio * ratio
			+ finish_point * ratio * ratio * ratio
		)
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result


func _scale() -> float:
	return maxf(minf(card_size.x, card_size.y), 72.0)


func _phase(start_value: float, end_value: float) -> float:
	if end_value <= start_value:
		return 1.0 if progress >= end_value else 0.0
	return clampf((progress - start_value) / (end_value - start_value), 0.0, 1.0)


func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - clampf(value, 0.0, 1.0), 3.0)


func _ease_in(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * clamped


func _ease_in_out(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)
