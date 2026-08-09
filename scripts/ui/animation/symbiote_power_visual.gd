extends "res://scripts/ui/animation/throttled_progress_visual.gd"

# Shared high-pressure organic presentation for Venom combat spells, Fear and
# Knull liberation. Shapes grow from card anchors instead of reading as magic.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const VOID := Color(0.008, 0.004, 0.015, 0.98)
const BLACK_FLESH := Color(0.045, 0.012, 0.035, 0.96)
const DEEP_RED := Color(0.28, 0.008, 0.045, 0.94)
const RC_RED := Color(0.86, 0.025, 0.10, 0.94)
const HOT_RED := Color(1.0, 0.15, 0.22, 0.96)
const WET_WHITE := Color(1.0, 0.78, 0.82, 0.90)
const COSMIC_VIOLET := Color(0.28, 0.035, 0.42, 0.86)
const FEAR_BLUE := Color(0.16, 0.18, 0.38, 0.62)

var animation_key := ""
var source_center := Vector2.ZERO
var target_center := Vector2.ZERO
var source_card_size := Vector2(120.0, 168.0)
var target_card_size := Vector2(120.0, 168.0)
var multi_centers: Array[Vector2] = []


func configure(
	key: String,
	local_source_center: Vector2,
	local_target_center: Vector2,
	local_source_size: Vector2,
	local_target_size: Vector2,
	local_multi_centers: Array[Vector2] = []
) -> void:
	animation_key = key
	source_center = local_source_center
	target_center = local_target_center
	source_card_size = local_source_size
	target_card_size = local_target_size
	multi_centers = local_multi_centers.duplicate()
	set_visual_redraw_fps(24.0)
	request_visual_redraw(true)


func _draw() -> void:
	var appear := _ease_out(_phase(0.0, 0.14))
	var fade := 1.0 - _ease_in(_phase(0.82, 1.0))
	var alpha := appear * fade
	if alpha <= 0.002:
		return

	match animation_key:
		"symbiote_bite_ready":
			_draw_bite_ready(alpha)
		"symbiote_bite_strike":
			_draw_bite_strike(alpha)
		"symbiote_bite_restore":
			_draw_bite_restore(alpha)
		"symbiote_terrifying_scream":
			_draw_terrifying_scream(alpha)
		"symbiote_fear_apply":
			_draw_fear_targets(alpha)
		"symbiote_fear_flee":
			_draw_fear_flee(alpha)
		"symbiote_codex":
			_draw_codex(alpha)
		"symbiote_knull_liberation":
			_draw_knull_liberation(alpha)


func _draw_bite_ready(alpha: float) -> void:
	var gather := _ease_in_out(_phase(0.0, 0.48))
	var pulse := 0.92 + sin(progress * TAU * 3.0) * 0.08
	_draw_living_halo(target_center, _scale() * 0.52, gather, alpha)
	_draw_jaw(target_center, _scale() * 0.34 * pulse, gather, alpha)
	for strand_index in range(5):
		var angle := TAU * float(strand_index) / 5.0 + progress * 0.35
		var start_point := target_center + Vector2.from_angle(angle) * _scale() * 0.58
		var finish_point := target_center + Vector2.from_angle(angle + 0.42) * _scale() * 0.24
		var path := _curved_path(start_point, finish_point, _scale() * 0.18, gather, 14)
		Toolkit.draw_ribbon(
			self, path, _scale() * 0.035,
			Toolkit.with_alpha(DEEP_RED, alpha * 0.88),
			Toolkit.with_alpha(VOID, alpha * 0.92),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
			_scale() * 0.13, true, true, progress * 6.0 + strand_index
		)


func _draw_bite_strike(alpha: float) -> void:
	var launch := _ease_in_out(_phase(0.02, 0.58))
	var impact := _ease_out(_phase(0.48, 0.82))
	var start_point := source_center
	if start_point.distance_squared_to(target_center) < 4.0:
		start_point = target_center + Vector2(-_scale() * 0.92, _scale() * 0.34)
	var direction := (target_center - start_point).normalized()
	var normal := direction.orthogonal()
	var path := _cubic_curve(
		start_point,
		start_point.lerp(target_center, 0.34) + normal * _scale() * 0.26,
		start_point.lerp(target_center, 0.72) - normal * _scale() * 0.13,
		target_center,
		launch,
		24
	)
	Toolkit.draw_ribbon(
		self, path, _scale() * 0.095,
		Toolkit.with_alpha(RC_RED, alpha * 0.94),
		Toolkit.with_alpha(VOID, alpha * 0.98),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.68),
		_scale() * 0.30, true, true, progress * 7.0
	)
	var head := _cubic_point(
		start_point,
		start_point.lerp(target_center, 0.34) + normal * _scale() * 0.26,
		start_point.lerp(target_center, 0.72) - normal * _scale() * 0.13,
		target_center,
		launch
	)
	Toolkit.draw_soft_ellipse(
		self, head, Vector2(_scale() * 0.16, _scale() * 0.08),
		Toolkit.with_alpha(HOT_RED, alpha * 0.62),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.86), 6,
		direction.angle()
	)
	if impact > 0.01:
		_draw_jaw(target_center, _scale() * (0.38 - impact * 0.08), impact, alpha)
		_draw_cut_sparks(target_center, impact, alpha)


func _draw_bite_restore(alpha: float) -> void:
	var gather := _ease_in_out(_phase(0.0, 0.68))
	var pulse := _ease_out(_phase(0.52, 0.90))
	Toolkit.draw_soft_disc(
		self, target_center, _scale() * (0.22 + pulse * 0.12),
		Toolkit.with_alpha(RC_RED, alpha * 0.32),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.62), 7
	)
	for stream_index in range(9):
		var angle := TAU * float(stream_index) / 9.0 + float(stream_index % 2) * 0.16
		var start_point := target_center + Vector2.from_angle(angle) * _scale() * 0.62
		var finish_point := target_center + Vector2.from_angle(angle + 0.36) * _scale() * 0.10
		var path := _curved_path(start_point, finish_point, _scale() * 0.10, gather, 12)
		Toolkit.draw_ribbon(
			self, path, _scale() * 0.024,
			Toolkit.with_alpha(RC_RED, alpha * 0.76),
			Toolkit.with_alpha(BLACK_FLESH, alpha * 0.84),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
			_scale() * 0.09, true, true, progress * 5.0 + stream_index
		)


func _draw_terrifying_scream(alpha: float) -> void:
	var pressure := _ease_out(_phase(0.05, 0.82))
	var core_pulse := 0.90 + sin(progress * TAU * 4.0) * 0.10
	_draw_living_halo(target_center, _scale() * 0.46 * core_pulse, 1.0, alpha)
	Toolkit.draw_soft_disc(
		self, target_center, _scale() * 0.20 * core_pulse,
		Toolkit.with_alpha(HOT_RED, alpha * 0.34),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.60), 7
	)
	for ring_index in range(5):
		var ring_phase := clampf(pressure * 1.22 - float(ring_index) * 0.12, 0.0, 1.0)
		if ring_phase <= 0.01:
			continue
		var radius := _scale() * lerpf(0.34, 3.0, ring_phase)
		var points := PackedVector2Array()
		for point_index in range(37):
			var angle := TAU * float(point_index) / 36.0
			var ripple := 1.0 + sin(angle * 6.0 + progress * 8.0 + ring_index) * 0.035
			points.append(target_center + Vector2.from_angle(angle) * radius * ripple)
		Toolkit.draw_stroked_path(
			self, points, _scale() * (0.030 + ring_index * 0.004),
			Toolkit.with_alpha(RC_RED, alpha * (0.62 - ring_phase * 0.34)),
			Toolkit.with_alpha(VOID, alpha * 0.76),
			Toolkit.with_alpha(FEAR_BLUE, alpha * 0.42),
			_scale() * 0.16
		)


func _draw_fear_targets(alpha: float) -> void:
	var bind := _ease_out(_phase(0.0, 0.62))
	var centers := multi_centers if not multi_centers.is_empty() else [target_center]
	for center_point in centers:
		_draw_fear_eye(center_point, bind, alpha)


func _draw_fear_flee(alpha: float) -> void:
	var recoil := _ease_out(_phase(0.0, 0.72))
	_draw_fear_eye(target_center, 1.0, alpha)
	for streak_index in range(5):
		var vertical_offset := (float(streak_index) - 2.0) * _scale() * 0.11
		var start_point := target_center + Vector2(-_scale() * 0.12, vertical_offset)
		var finish_point := target_center + Vector2(_scale() * (0.30 + recoil * 0.58), vertical_offset * 0.48)
		Toolkit.draw_ribbon(
			self, _curved_path(start_point, finish_point, _scale() * 0.06, recoil, 12),
			_scale() * 0.025,
			Toolkit.with_alpha(FEAR_BLUE, alpha * 0.56),
			Toolkit.with_alpha(VOID, alpha * 0.84),
			Color.TRANSPARENT, _scale() * 0.10, true, true, progress * 5.0 + streak_index
		)


func _draw_codex(alpha: float) -> void:
	var awaken := _ease_out(_phase(0.0, 0.42))
	var split := _ease_in_out(_phase(0.30, 0.76))
	var radius := _scale() * (0.42 + split * 0.30)
	Toolkit.draw_soft_disc(
		self, target_center, radius,
		Toolkit.with_alpha(COSMIC_VIOLET, alpha * 0.28),
		Toolkit.with_alpha(VOID, alpha * 0.92), 8
	)
	for tendril_index in range(8):
		var angle := TAU * float(tendril_index) / 8.0 + progress * 0.24
		var start_point := target_center + Vector2.from_angle(angle) * _scale() * 0.13
		var finish_point := target_center + Vector2.from_angle(angle + 0.44) * radius
		Toolkit.draw_ribbon(
			self, _curved_path(start_point, finish_point, _scale() * 0.18, awaken, 16),
			_scale() * 0.038,
			Toolkit.with_alpha(DEEP_RED, alpha * 0.74),
			Toolkit.with_alpha(VOID, alpha * 0.96),
			Toolkit.with_alpha(COSMIC_VIOLET, alpha * 0.50),
			_scale() * 0.14, true, true, progress * 4.0 + tendril_index
		)
	_draw_prison_bands(target_center, radius * 0.72, 1.0 - split, alpha)


func _draw_knull_liberation(alpha: float) -> void:
	var break_phase := _ease_in_out(_phase(0.08, 0.50))
	var expand := _ease_out(_phase(0.36, 0.88))
	var radius := _scale() * (0.54 + expand * 0.44)
	_draw_prison_bands(target_center, _scale() * 0.48, 1.0 - break_phase, alpha)
	Toolkit.draw_soft_disc(
		self, target_center, radius,
		Toolkit.with_alpha(COSMIC_VIOLET, alpha * 0.32),
		Toolkit.with_alpha(HOT_RED, alpha * 0.54), 8
	)
	for tendril_index in range(10):
		var angle := TAU * float(tendril_index) / 10.0 + sin(float(tendril_index)) * 0.16
		var start_point := target_center + Vector2.from_angle(angle) * _scale() * 0.14
		var finish_point := target_center + Vector2.from_angle(angle + 0.52) * radius
		Toolkit.draw_ribbon(
			self, _curved_path(start_point, finish_point, _scale() * 0.24, expand, 18),
			_scale() * (0.042 + float(tendril_index % 3) * 0.009),
			Toolkit.with_alpha(RC_RED, alpha * 0.86),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.42),
			_scale() * 0.18, true, true, progress * 5.0 + tendril_index
		)
	_draw_crown(target_center - Vector2(0.0, _scale() * 0.24), expand, alpha)


func _draw_living_halo(center_point: Vector2, radius: float, growth: float, alpha: float) -> void:
	if growth <= 0.01:
		return
	for arc_index in range(4):
		var start_angle := float(arc_index) * PI * 0.5 + progress * 0.34
		Toolkit.draw_arc_ribbon(
			self, center_point, radius,
			start_angle, start_angle + PI * 0.36,
			_scale() * 0.040,
			Toolkit.with_alpha(DEEP_RED, alpha * 0.82),
			Toolkit.with_alpha(VOID, alpha * 0.94),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.34),
			_scale() * 0.14, 16, true, true, progress * 4.0 + arc_index
		)


func _draw_jaw(center_point: Vector2, radius: float, strength: float, alpha: float) -> void:
	if radius <= 0.1 or strength <= 0.01:
		return
	for jaw_sign in [-1.0, 1.0]:
		var jaw_center := center_point + Vector2(0.0, jaw_sign * radius * 0.30)
		Toolkit.draw_stroked_arc(
			self, jaw_center, radius,
			PI * (0.08 if jaw_sign < 0.0 else 1.08),
			PI * (0.92 if jaw_sign < 0.0 else 1.92),
			_scale() * 0.055,
			Toolkit.with_alpha(RC_RED, alpha * strength),
			Toolkit.with_alpha(VOID, alpha * 0.96),
			Toolkit.with_alpha(WET_WHITE, alpha * 0.52),
			_scale() * 0.17, 22
		)
		for fang_index in range(3):
			var x_offset := (float(fang_index) - 1.0) * radius * 0.42
			var root := jaw_center + Vector2(x_offset, -jaw_sign * radius * 0.16)
			var tip := root + Vector2(0.0, -jaw_sign * radius * 0.42 * strength)
			draw_line(root, tip, Toolkit.with_alpha(WET_WHITE, alpha * 0.88), _scale() * 0.025, true)


func _draw_cut_sparks(center_point: Vector2, impact: float, alpha: float) -> void:
	for spark_index in range(8):
		var angle := TAU * float(spark_index) / 8.0 + float(spark_index % 2) * 0.23
		var start_point := center_point + Vector2.from_angle(angle) * _scale() * 0.18
		var finish_point := center_point + Vector2.from_angle(angle) * _scale() * (0.24 + impact * 0.34)
		draw_line(start_point, finish_point, Toolkit.with_alpha(HOT_RED, alpha * 0.76), _scale() * 0.018, true)


func _draw_fear_eye(center_point: Vector2, strength: float, alpha: float) -> void:
	var radius := _scale() * (0.30 + strength * 0.12)
	Toolkit.draw_soft_ellipse(
		self, center_point, Vector2(radius, radius * 0.48),
		Toolkit.with_alpha(FEAR_BLUE, alpha * 0.30),
		Toolkit.with_alpha(VOID, alpha * 0.90), 7
	)
	Toolkit.draw_stroked_arc(
		self, center_point, radius,
		PI * 0.12, PI * 0.88, _scale() * 0.035,
		Toolkit.with_alpha(RC_RED, alpha * 0.76),
		Toolkit.with_alpha(VOID, alpha * 0.92),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.28), _scale() * 0.12, 20
	)
	Toolkit.draw_soft_disc(
		self, center_point, _scale() * (0.055 + strength * 0.018),
		Toolkit.with_alpha(HOT_RED, alpha * 0.46),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.76), 6
	)


func _draw_prison_bands(center_point: Vector2, radius: float, strength: float, alpha: float) -> void:
	if strength <= 0.01:
		return
	for band_index in range(4):
		var rotation_offset := float(band_index) * PI * 0.5 + progress * 0.10
		Toolkit.draw_stroked_arc(
			self, center_point, radius * (0.72 + float(band_index % 2) * 0.16),
			rotation_offset, rotation_offset + PI * 0.72,
			_scale() * 0.050,
			Toolkit.with_alpha(FEAR_BLUE, alpha * strength * 0.72),
			Toolkit.with_alpha(VOID, alpha * 0.94),
			Toolkit.with_alpha(COSMIC_VIOLET, alpha * strength * 0.48),
			_scale() * 0.16, 24
		)


func _draw_crown(center_point: Vector2, strength: float, alpha: float) -> void:
	if strength <= 0.01:
		return
	var crown_points := PackedVector2Array()
	for point_index in range(7):
		var ratio := float(point_index) / 6.0
		var x_value := lerpf(-_scale() * 0.31, _scale() * 0.31, ratio)
		var peak := 0.12 if point_index % 2 == 0 else 0.30
		crown_points.append(center_point + Vector2(x_value, -_scale() * peak * strength))
	Toolkit.draw_stroked_path(
		self, crown_points, _scale() * 0.045,
		Toolkit.with_alpha(HOT_RED, alpha * 0.84),
		Toolkit.with_alpha(VOID, alpha * 0.96),
		Toolkit.with_alpha(WET_WHITE, alpha * 0.42), _scale() * 0.15
	)


func _curved_path(
	start_point: Vector2,
	finish_point: Vector2,
	curve_amount: float,
	visible_ratio: float,
	segments: int
) -> PackedVector2Array:
	var direction := finish_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.01 else Vector2.UP
	return _cubic_curve(
		start_point,
		start_point.lerp(finish_point, 0.34) + normal * curve_amount,
		start_point.lerp(finish_point, 0.70) - normal * curve_amount * 0.52,
		finish_point,
		visible_ratio,
		segments
	)


func _cubic_curve(
	start_point: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	finish_point: Vector2,
	visible_ratio: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segments := maxi(segments, 4)
	var clamped_ratio := clampf(visible_ratio, 0.0, 1.0)
	for point_index in range(safe_segments + 1):
		var ratio := clamped_ratio * float(point_index) / float(safe_segments)
		points.append(_cubic_point(start_point, control_a, control_b, finish_point, ratio))
	return points


func _cubic_point(
	start_point: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	finish_point: Vector2,
	ratio: float
) -> Vector2:
	var inverse := 1.0 - ratio
	return (
		start_point * inverse * inverse * inverse
		+ control_a * 3.0 * inverse * inverse * ratio
		+ control_b * 3.0 * inverse * ratio * ratio
		+ finish_point * ratio * ratio * ratio
	)


func _scale() -> float:
	return maxf(minf(target_card_size.x, target_card_size.y), 72.0)


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
