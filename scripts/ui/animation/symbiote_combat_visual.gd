extends "res://scripts/ui/animation/throttled_progress_visual.gd"

# Short-lived combat material for Symbiote offspring. The visual language is
# grown tissue, wet chitin and pressurized cellular motion rather than magic.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const VOID := Color(0.006, 0.004, 0.012, 0.99)
const BLACK_FLESH := Color(0.035, 0.009, 0.026, 0.98)
const WINE_FLESH := Color(0.22, 0.008, 0.045, 0.96)
const LIVING_RED := Color(0.74, 0.018, 0.085, 0.96)
const HOT_TISSUE := Color(1.0, 0.10, 0.16, 0.96)
const WET_EDGE := Color(1.0, 0.74, 0.78, 0.88)
const VEIN_VIOLET := Color(0.32, 0.025, 0.40, 0.78)
const ANTI_FLESH := Color(0.86, 0.84, 0.76, 0.94)
const ANTI_EDGE := Color(1.0, 0.98, 0.88, 0.94)
const SILENCE_BLUE := Color(0.10, 0.18, 0.30, 0.72)

var animation_key := ""
var source_center := Vector2.ZERO
var target_center := Vector2.ZERO
var source_card_size := Vector2(120.0, 168.0)
var target_card_size := Vector2(120.0, 168.0)


func configure(
	key: String,
	local_source_center: Vector2,
	local_target_center: Vector2,
	local_source_size: Vector2,
	local_target_size: Vector2
) -> void:
	animation_key = key
	source_center = local_source_center
	target_center = local_target_center
	source_card_size = local_source_size
	target_card_size = local_target_size
	set_visual_redraw_fps(24.0)
	request_visual_redraw(true)


func _draw() -> void:
	var appear := _ease_out(_phase(0.0, 0.12))
	var fade := 1.0 - _ease_in(_phase(0.84, 1.0))
	var alpha := appear * fade
	if alpha <= 0.002:
		return

	match animation_key:
		"symbiote_living_weapon_attack", "symbiote_carnage_attack", \
		"symbiote_anti_venom_attack", "symbiote_hybrid_attack":
			_draw_living_weapon_attack(alpha)
		"symbiote_riot":
			_draw_riot(alpha)
		"symbiote_offspring_scream":
			_draw_scream(alpha)
		"symbiote_lash":
			_draw_lash(alpha)
		"symbiote_lash_empower":
			_draw_lash_empower(alpha)
		"symbiote_devour":
			_draw_devour(alpha)
		"symbiote_absorption_gain":
			_draw_absorption_gain(alpha)


func _draw_living_weapon_attack(alpha: float) -> void:
	var launch := _ease_in_out(_phase(0.02, 0.58))
	var impact := _ease_out(_phase(0.46, 0.82))
	var direction := _safe_direction(source_center, target_center)
	var normal := direction.orthogonal()
	var profile_count := 2
	var body_color := LIVING_RED
	var edge_color := WET_EDGE
	var arc_spread := 0.16
	if animation_key == "symbiote_carnage_attack":
		profile_count = 4
		body_color = HOT_TISSUE
		arc_spread = 0.24
	elif animation_key == "symbiote_anti_venom_attack":
		profile_count = 3
		body_color = ANTI_FLESH
		edge_color = ANTI_EDGE
		arc_spread = 0.13
	elif animation_key == "symbiote_hybrid_attack":
		profile_count = 3
		body_color = Color(0.58, 0.025, 0.18, 0.96)
		arc_spread = 0.30

	for tendril_index in range(profile_count):
		var centered_index := float(tendril_index) - float(profile_count - 1) * 0.5
		var offset := centered_index * _scale() * arc_spread
		var start_point := source_center + normal * offset * 0.35
		var finish_point := target_center + normal * offset * 0.18
		var path := _cubic_curve(
			start_point,
			start_point.lerp(finish_point, 0.32) + normal * offset,
			start_point.lerp(finish_point, 0.72) - normal * offset * 0.45,
			finish_point,
			launch,
			20
		)
		Toolkit.draw_ribbon(
			self,
			path,
			_scale() * (0.052 + float(tendril_index % 2) * 0.014),
			Toolkit.with_alpha(body_color, alpha * 0.90),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(edge_color, alpha * 0.56),
			_scale() * 0.22,
			true,
			true,
			progress * 7.0 + tendril_index
		)

	if impact > 0.01:
		_draw_claw_impact(target_center, direction, impact, alpha, body_color, edge_color)
		_draw_cell_spray(target_center, direction, impact, alpha, body_color)


func _draw_riot(alpha: float) -> void:
	var tense := _ease_in_out(_phase(0.0, 0.34))
	var release := _ease_out(_phase(0.26, 0.82))
	var scale_value := _scale()
	Toolkit.draw_soft_disc(
		self,
		target_center,
		scale_value * (0.24 + tense * 0.14),
		Toolkit.with_alpha(WINE_FLESH, alpha * 0.44),
		Toolkit.with_alpha(HOT_TISSUE, alpha * 0.58),
		7
	)
	for arm_index in range(6):
		var angle := TAU * float(arm_index) / 6.0 + sin(float(arm_index) * 1.83) * 0.20
		var start_point := target_center + Vector2.from_angle(angle + 0.5) * scale_value * 0.10
		var finish_point := target_center + Vector2.from_angle(angle) * scale_value * (0.58 + release * 0.52)
		var path := _curved_path(
			start_point,
			finish_point,
			scale_value * (0.16 + float(arm_index % 2) * 0.08),
			release,
			18,
			-1.0 if arm_index % 2 == 0 else 1.0
		)
		Toolkit.draw_ribbon(
			self,
			path,
			scale_value * (0.046 + float(arm_index % 3) * 0.010),
			Toolkit.with_alpha(LIVING_RED, alpha * 0.90),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.44),
			scale_value * 0.20,
			true,
			true,
			progress * 8.0 + arm_index
		)
		if release > 0.28:
			_draw_bone_hook(finish_point, Vector2.from_angle(angle), scale_value * 0.11, alpha * release)

	for ring_index in range(3):
		var ring_phase := clampf(release * 1.18 - float(ring_index) * 0.16, 0.0, 1.0)
		if ring_phase <= 0.01:
			continue
		Toolkit.draw_stroked_arc(
			self,
			target_center,
			scale_value * (0.34 + ring_phase * (0.42 + ring_index * 0.12)),
			-progress * 0.7 + ring_index,
			-progress * 0.7 + ring_index + PI * 1.45,
			scale_value * 0.026,
			Toolkit.with_alpha(HOT_TISSUE, alpha * (0.62 - ring_phase * 0.28)),
			Toolkit.with_alpha(VOID, alpha * 0.78),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.22),
			scale_value * 0.12,
			30
		)


func _draw_scream(alpha: float) -> void:
	var pressure := _ease_out(_phase(0.03, 0.84))
	var mouth_open := _ease_in_out(_phase(0.0, 0.34))
	var scale_value := _scale()
	_draw_maw(target_center, scale_value * 0.28, mouth_open, alpha)
	Toolkit.draw_soft_ellipse(
		self,
		target_center,
		Vector2(scale_value * 0.33, scale_value * 0.17),
		Toolkit.with_alpha(HOT_TISSUE, alpha * 0.34),
		Toolkit.with_alpha(WET_EDGE, alpha * 0.60),
		7
	)

	var max_radius := maxf(size.x, size.y) * 0.72
	for wave_index in range(5):
		var wave_phase := clampf(pressure * 1.24 - float(wave_index) * 0.13, 0.0, 1.0)
		if wave_phase <= 0.01:
			continue
		var radius := lerpf(scale_value * 0.30, max_radius, wave_phase)
		var points := PackedVector2Array()
		for point_index in range(49):
			var angle := TAU * float(point_index) / 48.0
			var membrane := (
				1.0
				+ sin(angle * 3.0 + wave_index * 0.9) * 0.045
				+ sin(angle * 7.0 - progress * 5.0) * 0.018
			)
			points.append(target_center + Vector2.from_angle(angle) * radius * membrane)
		Toolkit.draw_stroked_path(
			self,
			points,
			scale_value * (0.030 + float(wave_index % 2) * 0.008),
			Toolkit.with_alpha(VEIN_VIOLET, alpha * (0.58 - wave_phase * 0.35)),
			Toolkit.with_alpha(VOID, alpha * 0.62),
			Toolkit.with_alpha(HOT_TISSUE, alpha * 0.28),
			scale_value * 0.16
		)

	for shard_index in range(12):
		var angle := TAU * float(shard_index) / 12.0 + float(shard_index % 3) * 0.09
		var shard_phase := clampf(pressure * 1.2 - float(shard_index % 4) * 0.08, 0.0, 1.0)
		var point := target_center + Vector2.from_angle(angle) * scale_value * lerpf(0.28, 1.72, shard_phase)
		Toolkit.draw_soft_ellipse(
			self,
			point,
			Vector2(scale_value * 0.045, scale_value * 0.016),
			Toolkit.with_alpha(LIVING_RED, alpha * sin(shard_phase * PI) * 0.64),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.36),
			4,
			angle
		)


func _draw_lash(alpha: float) -> void:
	var crack := _ease_in_out(_phase(0.02, 0.62))
	var recoil := _ease_out(_phase(0.60, 0.92))
	var direction := _safe_direction(source_center, target_center)
	var normal := direction.orthogonal()
	var curve_side := -1.0 if source_center.x < target_center.x else 1.0
	var control_a := source_center.lerp(target_center, 0.28) + normal * _scale() * 0.60 * curve_side
	var control_b := source_center.lerp(target_center, 0.74) - normal * _scale() * 0.36 * curve_side
	var path := _cubic_curve(source_center, control_a, control_b, target_center, crack, 28)
	Toolkit.draw_ribbon(
		self,
		path,
		_scale() * 0.090,
		Toolkit.with_alpha(LIVING_RED, alpha * 0.94),
		Toolkit.with_alpha(VOID, alpha * 0.99),
		Toolkit.with_alpha(WET_EDGE, alpha * 0.62),
		_scale() * 0.34,
		true,
		true,
		progress * 9.0
	)
	if crack > 0.08:
		var head := _cubic_point(source_center, control_a, control_b, target_center, crack)
		_draw_bone_hook(head, direction, _scale() * 0.17, alpha)
	if recoil > 0.01:
		_draw_claw_impact(target_center, direction, recoil, alpha, HOT_TISSUE, WET_EDGE)


func _draw_lash_empower(alpha: float) -> void:
	var infuse := _ease_out(_phase(0.0, 0.72))
	var scale_value := _scale()
	_draw_living_frame(target_center, target_card_size, infuse, alpha, LIVING_RED)
	for vein_index in range(7):
		var angle := TAU * float(vein_index) / 7.0 + 0.18
		var start_point := target_center + Vector2.from_angle(angle) * scale_value * 0.54
		var finish_point := target_center + Vector2.from_angle(angle + 0.28) * scale_value * 0.12
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, scale_value * 0.09, infuse, 12),
			scale_value * 0.026,
			Toolkit.with_alpha(HOT_TISSUE, alpha * 0.78),
			Toolkit.with_alpha(BLACK_FLESH, alpha * 0.90),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.32),
			scale_value * 0.10,
			true,
			true,
			progress * 5.0 + vein_index
		)
	Toolkit.draw_soft_disc(
		self,
		target_center,
		scale_value * (0.15 + infuse * 0.10),
		Toolkit.with_alpha(WINE_FLESH, alpha * 0.44),
		Toolkit.with_alpha(WET_EDGE, alpha * 0.72),
		6
	)


func _draw_devour(alpha: float) -> void:
	var bind := _ease_in_out(_phase(0.02, 0.46))
	var consume := _ease_in_out(_phase(0.34, 0.78))
	var settle := _ease_out(_phase(0.70, 0.96))
	var scale_value := _scale()
	var direction := _safe_direction(source_center, target_center)
	var normal := direction.orthogonal()
	_draw_maw(target_center, scale_value * (0.34 + bind * 0.10), bind, alpha)

	for tendril_index in range(6):
		var centered_index := float(tendril_index) - 2.5
		var target_anchor := target_center + normal * centered_index * scale_value * 0.11
		var source_anchor := source_center + normal * centered_index * scale_value * 0.035
		var path := _curved_path(
			target_anchor,
			source_anchor,
			scale_value * (0.22 + float(tendril_index % 2) * 0.08),
			consume,
			20,
			-1.0 if tendril_index % 2 == 0 else 1.0
		)
		Toolkit.draw_ribbon(
			self,
			path,
			scale_value * (0.040 + float(tendril_index % 3) * 0.009),
			Toolkit.with_alpha(WINE_FLESH, alpha * 0.90),
			Toolkit.with_alpha(VOID, alpha * 0.99),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.40),
			scale_value * 0.18,
			true,
			true,
			progress * 7.0 + tendril_index
		)

	if settle > 0.01:
		_draw_absorption_core(source_center, scale_value, settle, alpha)
		for mote_index in range(8):
			var ratio := clampf(settle * 1.15 - float(mote_index % 3) * 0.08, 0.0, 1.0)
			var start_point := target_center + normal * (float(mote_index) - 3.5) * scale_value * 0.045
			var point := start_point.lerp(source_center, ratio)
			Toolkit.draw_mote(
				self,
				point,
				scale_value * 0.025,
				Toolkit.with_alpha(HOT_TISSUE, alpha * sin(ratio * PI)),
				progress * 8.0 + mote_index
			)


func _draw_absorption_gain(alpha: float) -> void:
	var settle := _ease_out(_phase(0.0, 0.76))
	var scale_value := _scale()
	_draw_absorption_core(target_center, scale_value, settle, alpha)
	_draw_living_frame(target_center, target_card_size, settle, alpha, WINE_FLESH)
	for plate_index in range(6):
		var angle := TAU * float(plate_index) / 6.0 + 0.32
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var anchor := target_center + radial * scale_value * (0.34 + settle * 0.22)
		var plate := PackedVector2Array([
			anchor - tangent * scale_value * 0.09,
			anchor + radial * scale_value * 0.16,
			anchor + tangent * scale_value * 0.09,
			anchor - radial * scale_value * 0.05,
		])
		draw_colored_polygon(plate, Toolkit.with_alpha(BLACK_FLESH, alpha * 0.72))
		draw_polyline(_closed(plate), Toolkit.with_alpha(WET_EDGE, alpha * 0.34), scale_value * 0.012, true)


func _draw_absorption_core(center_point: Vector2, scale_value: float, strength: float, alpha: float) -> void:
	Toolkit.draw_soft_disc(
		self,
		center_point,
		scale_value * (0.16 + strength * 0.13),
		Toolkit.with_alpha(WINE_FLESH, alpha * 0.48),
		Toolkit.with_alpha(HOT_TISSUE, alpha * 0.72),
		7
	)
	for ring_index in range(3):
		Toolkit.draw_arc_ribbon(
			self,
			center_point,
			scale_value * (0.24 + float(ring_index) * 0.09),
			float(ring_index) * 1.7 - progress * 0.7,
			float(ring_index) * 1.7 - progress * 0.7 + PI * 1.15,
			scale_value * 0.030,
			Toolkit.with_alpha(LIVING_RED, alpha * strength * (0.70 - ring_index * 0.12)),
			Toolkit.with_alpha(VOID, alpha * 0.92),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.28),
			scale_value * 0.12,
			22,
			true,
			true,
			progress * 4.0 + ring_index
		)


func _draw_living_frame(
	center_point: Vector2,
	card_size: Vector2,
	strength: float,
	alpha: float,
	body_color: Color
) -> void:
	if strength <= 0.01:
		return
	var half_size := card_size * Vector2(0.48, 0.48)
	var corners := [
		center_point + Vector2(-half_size.x, -half_size.y),
		center_point + Vector2(half_size.x, -half_size.y),
		center_point + Vector2(half_size.x, half_size.y),
		center_point + Vector2(-half_size.x, half_size.y),
	]
	for edge_index in range(4):
		var start_point: Vector2 = corners[edge_index]
		var finish_point: Vector2 = corners[(edge_index + 1) % 4]
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, _scale() * 0.04, strength, 12, -1.0 if edge_index % 2 else 1.0),
			_scale() * 0.030,
			Toolkit.with_alpha(body_color, alpha * 0.74),
			Toolkit.with_alpha(VOID, alpha * 0.88),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.24),
			_scale() * 0.11,
			true,
			true,
			progress * 3.0 + edge_index
		)


func _draw_maw(center_point: Vector2, radius: float, strength: float, alpha: float) -> void:
	if radius <= 0.1 or strength <= 0.01:
		return
	Toolkit.draw_soft_ellipse(
		self,
		center_point,
		Vector2(radius * 1.10, radius * 0.58),
		Toolkit.with_alpha(VOID, alpha * 0.86),
		Toolkit.with_alpha(WINE_FLESH, alpha * 0.56),
		6
	)
	for jaw_sign in [-1.0, 1.0]:
		var jaw_center := center_point + Vector2(0.0, jaw_sign * radius * 0.22)
		Toolkit.draw_stroked_arc(
			self,
			jaw_center,
			radius,
			PI * (0.08 if jaw_sign < 0.0 else 1.08),
			PI * (0.92 if jaw_sign < 0.0 else 1.92),
			_scale() * 0.045,
			Toolkit.with_alpha(LIVING_RED, alpha * strength),
			Toolkit.with_alpha(VOID, alpha * 0.98),
			Toolkit.with_alpha(WET_EDGE, alpha * 0.54),
			_scale() * 0.15,
			24
		)
		for fang_index in range(5):
			var ratio := float(fang_index) / 4.0
			var root := jaw_center + Vector2(lerpf(-radius * 0.72, radius * 0.72, ratio), -jaw_sign * radius * 0.12)
			var tip := root + Vector2(0.0, -jaw_sign * radius * (0.20 + absf(ratio - 0.5) * 0.18) * strength)
			draw_line(root, tip, Toolkit.with_alpha(WET_EDGE, alpha * 0.84), _scale() * 0.020, true)


func _draw_claw_impact(
	center_point: Vector2,
	direction: Vector2,
	strength: float,
	alpha: float,
	body_color: Color,
	edge_color: Color
) -> void:
	var normal := direction.orthogonal()
	for slash_index in range(3):
		var offset := (float(slash_index) - 1.0) * _scale() * 0.12
		var start_point := center_point - direction * _scale() * (0.36 + slash_index * 0.04) + normal * offset
		var finish_point := center_point + direction * _scale() * (0.42 - slash_index * 0.03) + normal * offset * 0.42
		Toolkit.draw_ribbon(
			self,
			_curved_path(start_point, finish_point, _scale() * 0.06, strength, 12, -1.0 if slash_index % 2 else 1.0),
			_scale() * (0.042 - slash_index * 0.005),
			Toolkit.with_alpha(body_color, alpha * 0.88),
			Toolkit.with_alpha(VOID, alpha * 0.92),
			Toolkit.with_alpha(edge_color, alpha * 0.68),
			_scale() * 0.16,
			true,
			true,
			progress * 8.0 + slash_index
		)


func _draw_cell_spray(
	center_point: Vector2,
	direction: Vector2,
	strength: float,
	alpha: float,
	color: Color
) -> void:
	var normal := direction.orthogonal()
	for mote_index in range(8):
		var fan := (float(mote_index) - 3.5) / 3.5
		var spray_direction := (direction + normal * fan * 0.72).normalized()
		var point := center_point + spray_direction * _scale() * (0.16 + strength * (0.24 + absf(fan) * 0.12))
		Toolkit.draw_mote(
			self,
			point,
			_scale() * (0.014 + float(mote_index % 3) * 0.004),
			Toolkit.with_alpha(color, alpha * 0.58),
			progress * 10.0 + mote_index
		)


func _draw_bone_hook(
	tip: Vector2,
	direction: Vector2,
	length: float,
	alpha: float
) -> void:
	var safe_direction := direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var normal := safe_direction.orthogonal()
	var hook := PackedVector2Array([
		tip - safe_direction * length * 0.10 - normal * length * 0.15,
		tip + safe_direction * length,
		tip - safe_direction * length * 0.08 + normal * length * 0.15,
		tip - safe_direction * length * 0.36,
	])
	draw_colored_polygon(hook, Toolkit.with_alpha(WET_EDGE, alpha * 0.72))
	draw_polyline(_closed(hook), Toolkit.with_alpha(VOID, alpha * 0.92), maxf(length * 0.08, 1.0), true)


func _curved_path(
	start_point: Vector2,
	finish_point: Vector2,
	curve_amount: float,
	visible_ratio: float,
	segments: int,
	curve_sign := 1.0
) -> PackedVector2Array:
	var direction := finish_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.01 else Vector2.UP
	return _cubic_curve(
		start_point,
		start_point.lerp(finish_point, 0.32) + normal * curve_amount * curve_sign,
		start_point.lerp(finish_point, 0.72) - normal * curve_amount * 0.42 * curve_sign,
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
	if clamped_ratio <= 0.0001:
		return points
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


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result


func _safe_direction(from_point: Vector2, to_point: Vector2) -> Vector2:
	var direction := to_point - from_point
	return direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT


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
