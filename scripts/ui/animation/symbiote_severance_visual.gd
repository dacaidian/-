extends "res://scripts/ui/animation/throttled_progress_visual.gd"

# Organic severance material shared by Venom and the biologist. The two
# profiles deliberately diverge: self-severance is muscular and instinctive,
# while artificial severance adds cold restraints and a sealed specimen pod.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const VOID := Color(0.012, 0.008, 0.020, 0.98)
const BLACK_FLESH := Color(0.055, 0.020, 0.045, 0.96)
const DEEP_RED := Color(0.28, 0.012, 0.055, 0.96)
const LIVING_RED := Color(0.78, 0.035, 0.12, 0.94)
const HOT_TISSUE := Color(1.0, 0.16, 0.24, 0.96)
const WET_HIGHLIGHT := Color(1.0, 0.78, 0.82, 0.90)
const CELL_VIOLET := Color(0.34, 0.08, 0.42, 0.72)
const DEVICE_DARK := Color(0.035, 0.075, 0.095, 0.94)
const DEVICE_BLUE := Color(0.12, 0.72, 0.78, 0.90)
const DEVICE_CORE := Color(0.72, 1.0, 0.96, 0.94)

var animation_key := "symbiote_self_severance"
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
	var appear := _ease_out(_phase(0.0, 0.13))
	var fade := 1.0 - _ease_in(_phase(0.84, 1.0))
	var alpha := appear * fade
	if alpha <= 0.002:
		return

	_draw_target_atmosphere(alpha)
	if animation_key == "symbiote_artificial_severance":
		_draw_artificial_severance(alpha)
	else:
		_draw_self_severance(alpha)


func _draw_self_severance(alpha: float) -> void:
	var gather := _ease_in_out(_phase(0.0, 0.28))
	var separate := _ease_out(_phase(0.18, 0.64))
	var seal := _ease_in_out(_phase(0.54, 0.82))
	var release := _ease_out(_phase(0.70, 0.96))
	var scale_value := _target_scale()
	var wound := target_center + Vector2(target_card_size.x * 0.10, -target_card_size.y * 0.05)
	var release_side := -1.0 if target_center.x > size.x * 0.72 else 1.0
	var release_point := target_center + Vector2(
		release_side * target_card_size.x * 0.72,
		-target_card_size.y * 0.64
	)

	_draw_living_frame(target_center, target_card_size, gather, alpha)
	_draw_inward_veins(wound, gather, alpha)
	_draw_wound(wound, scale_value * 0.19, separate, seal, alpha, false)

	var clot_center := _cubic_point(
		wound,
		wound + Vector2(release_side * scale_value * 0.18, -scale_value * 0.06),
		release_point + Vector2(-release_side * scale_value * 0.16, scale_value * 0.12),
		release_point,
		separate
	)
	_draw_severing_membranes(wound, clot_center, separate, seal, alpha, false)
	_draw_tissue_clot(clot_center, scale_value * lerpf(0.12, 0.18, separate), separate, alpha)
	_draw_rc_droplets(wound, clot_center, separate, release, alpha)

	if release > 0.02:
		_draw_organization_seed(clot_center, scale_value, release, alpha)


func _draw_artificial_severance(alpha: float) -> void:
	var lock_phase := _ease_out(_phase(0.0, 0.26))
	var extraction := _ease_in_out(_phase(0.20, 0.70))
	var seal := _ease_out(_phase(0.58, 0.88))
	var release := _ease_out(_phase(0.78, 0.98))
	var scale_value := _target_scale()
	var direction := source_center - target_center
	if direction.length_squared() <= 0.01:
		direction = Vector2(0.8, -0.6)
	direction = direction.normalized()
	var normal := direction.orthogonal()
	var wound := target_center + direction * minf(target_card_size.x, target_card_size.y) * 0.08
	var pod_center := source_center - Vector2(0.0, source_card_size.y * 0.48)

	_draw_living_frame(target_center, target_card_size, lock_phase, alpha * 0.82)
	_draw_device_restraints(target_center, target_card_size, lock_phase, alpha)
	_draw_source_instrument(source_center, source_card_size, lock_phase, alpha)
	_draw_wound(wound, scale_value * 0.18, extraction, seal, alpha, true)

	var clot_center := _cubic_point(
		wound,
		wound.lerp(pod_center, 0.33) + normal * scale_value * 0.25,
		wound.lerp(pod_center, 0.70) - normal * scale_value * 0.18,
		pod_center,
		extraction
	)
	_draw_extraction_tethers(wound, pod_center, extraction, seal, alpha)
	_draw_tissue_clot(clot_center, scale_value * 0.15, extraction, alpha)
	_draw_specimen_pod(pod_center, scale_value, seal, release, alpha)
	_draw_rc_droplets(wound, clot_center, extraction, release, alpha * 0.72)


func _draw_target_atmosphere(alpha: float) -> void:
	var breath := 0.94 + sin(progress * TAU * 2.2) * 0.06
	Toolkit.draw_soft_ellipse(
		self,
		target_center,
		Vector2(target_card_size.x * 0.54, target_card_size.y * 0.48) * breath,
		Toolkit.with_alpha(DEEP_RED, alpha * 0.16),
		Toolkit.with_alpha(VOID, alpha * 0.18),
		7,
		sin(progress * TAU) * 0.04
	)
	for mote_index in range(9):
		var angle := TAU * float(mote_index) / 9.0 + progress * (0.9 + float(mote_index % 3) * 0.14)
		var mote_center := target_center + Vector2(
			cos(angle) * target_card_size.x * 0.50,
			sin(angle) * target_card_size.y * 0.44
		)
		Toolkit.draw_mote(
			self,
			mote_center,
			_target_scale() * (0.010 + float(mote_index % 3) * 0.004),
			Toolkit.with_alpha(LIVING_RED if mote_index % 2 == 0 else CELL_VIOLET, alpha * 0.42),
			progress * 8.0 + float(mote_index)
		)


func _draw_living_frame(
	center_point: Vector2,
	card_size: Vector2,
	growth: float,
	alpha: float
) -> void:
	if growth <= 0.01:
		return
	var rect := Rect2(center_point - card_size * 0.48, card_size * 0.96)
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for edge_index in range(4):
		var start_point: Vector2 = corners[edge_index]
		var end_point: Vector2 = corners[(edge_index + 1) % 4]
		var edge_direction := end_point - start_point
		var inward := (center_point - start_point.lerp(end_point, 0.5)).normalized()
		var path := _cubic_curve(
			start_point,
			start_point + edge_direction * 0.32 + inward * _target_scale() * 0.07,
			start_point + edge_direction * 0.68 - inward * _target_scale() * 0.05,
			end_point,
			growth,
			18
		)
		Toolkit.draw_ribbon(
			self,
			path,
			_target_scale() * 0.045,
			Toolkit.with_alpha(BLACK_FLESH, alpha * 0.88),
			Toolkit.with_alpha(DEEP_RED, alpha * 0.78),
			Toolkit.with_alpha(WET_HIGHLIGHT, alpha * 0.34),
			_target_scale() * 0.16,
			true,
			true,
			progress * 5.0 + float(edge_index)
		)


func _draw_inward_veins(wound: Vector2, growth: float, alpha: float) -> void:
	for vein_index in range(7):
		var angle := TAU * float(vein_index) / 7.0 + 0.28
		var start_point := target_center + Vector2(
			cos(angle) * target_card_size.x * 0.40,
			sin(angle) * target_card_size.y * 0.36
		)
		var tangent := (wound - start_point).normalized().orthogonal()
		var path := _cubic_curve(
			start_point,
			start_point.lerp(wound, 0.34) + tangent * _target_scale() * sin(float(vein_index) * 2.1) * 0.10,
			start_point.lerp(wound, 0.74) - tangent * _target_scale() * 0.06,
			wound,
			growth,
			15
		)
		Toolkit.draw_ribbon(
			self,
			path,
			_target_scale() * (0.025 + float(vein_index % 3) * 0.007),
			Toolkit.with_alpha(DEEP_RED, alpha * 0.72),
			Toolkit.with_alpha(VOID, alpha * 0.72),
			Toolkit.with_alpha(HOT_TISSUE, alpha * 0.35),
			_target_scale() * 0.10,
			true,
			false,
			progress * 7.0 + float(vein_index)
		)


func _draw_wound(
	wound: Vector2,
	radius: float,
	open_phase: float,
	seal_phase: float,
	alpha: float,
	is_clamped: bool
) -> void:
	if open_phase <= 0.01:
		return
	var closure := 1.0 - seal_phase * 0.72
	var radii := Vector2(radius * (0.58 + open_phase * 0.42), radius * 0.24 * closure)
	var wound_angle := -0.72 if is_clamped else 0.34
	Toolkit.draw_soft_ellipse(
		self,
		wound,
		radii * 1.42,
		Toolkit.with_alpha(LIVING_RED, alpha * 0.40 * open_phase),
		Toolkit.with_alpha(VOID, alpha * 0.94),
		8,
		wound_angle
	)
	Toolkit.draw_stroked_arc(
		self,
		wound,
		radius * (0.72 + open_phase * 0.18),
		-2.68 + wound_angle,
		-0.48 + wound_angle,
		radius * 0.10,
		Toolkit.with_alpha(HOT_TISSUE, alpha * 0.78),
		Toolkit.with_alpha(VOID, alpha * 0.80),
		Toolkit.with_alpha(WET_HIGHLIGHT, alpha * 0.55),
		radius * 0.32,
		20
	)


func _draw_severing_membranes(
	wound: Vector2,
	clot_center: Vector2,
	separate: float,
	seal: float,
	alpha: float,
	is_artificial: bool
) -> void:
	if separate <= 0.02 or seal >= 0.98:
		return
	var direction := clot_center - wound
	if direction.length_squared() <= 0.01:
		return
	var normal := direction.normalized().orthogonal()
	for strand_index in range(5):
		var offset_ratio := float(strand_index) - 2.0
		var start_point := wound + normal * _target_scale() * offset_ratio * 0.035
		var finish := clot_center + normal * _target_scale() * offset_ratio * 0.022
		var bend := normal * _target_scale() * sin(float(strand_index) * 1.9 + progress * 5.0) * 0.12
		var path := _cubic_curve(
			start_point,
			start_point.lerp(finish, 0.34) + bend,
			start_point.lerp(finish, 0.72) - bend * 0.55,
			finish,
			1.0 - seal,
			16
		)
		Toolkit.draw_ribbon(
			self,
			path,
			_target_scale() * (0.038 - absf(offset_ratio) * 0.004),
			Toolkit.with_alpha(DEEP_RED, alpha * 0.90 * (1.0 - seal)),
			Toolkit.with_alpha(DEVICE_BLUE if is_artificial else VOID, alpha * (0.48 if is_artificial else 0.74) * (1.0 - seal)),
			Toolkit.with_alpha(WET_HIGHLIGHT, alpha * 0.38 * (1.0 - seal)),
			_target_scale() * 0.13,
			false,
			true,
			progress * 8.0 + float(strand_index)
		)


func _draw_extraction_tethers(
	wound: Vector2,
	pod_center: Vector2,
	extraction: float,
	seal: float,
	alpha: float
) -> void:
	if extraction <= 0.01:
		return
	var direction := (pod_center - wound).normalized()
	var normal := direction.orthogonal()
	for tether_index in range(3):
		var offset_ratio := float(tether_index) - 1.0
		var offset := normal * _target_scale() * offset_ratio * 0.08
		var path := _cubic_curve(
			wound + offset * 0.40,
			wound.lerp(pod_center, 0.34) + normal * _target_scale() * (0.22 + offset_ratio * 0.04),
			wound.lerp(pod_center, 0.72) - normal * _target_scale() * (0.14 - offset_ratio * 0.03),
			pod_center + offset,
			extraction,
			24
		)
		Toolkit.draw_ribbon(
			self,
			path,
			_target_scale() * (0.052 if tether_index == 1 else 0.036),
			Toolkit.with_alpha(DEEP_RED, alpha * (0.92 - seal * 0.36)),
			Toolkit.with_alpha(DEVICE_DARK, alpha * 0.94),
			Toolkit.with_alpha(DEVICE_CORE if tether_index == 1 else DEVICE_BLUE, alpha * 0.62),
			_target_scale() * 0.17,
			true,
			true,
			progress * 6.0 + float(tether_index)
		)
		for pulse_index in range(3):
			var pulse_ratio := fmod(extraction * 1.35 + float(pulse_index) * 0.26 + float(tether_index) * 0.08, 1.0)
			var pulse_center := _sample_path(path, pulse_ratio)
			Toolkit.draw_mote(
				self,
				pulse_center,
				_target_scale() * 0.018,
				Toolkit.with_alpha(DEVICE_CORE, alpha * 0.58),
				progress * 10.0 + float(pulse_index)
			)


func _draw_tissue_clot(
	clot_center: Vector2,
	radius: float,
	formation: float,
	alpha: float
) -> void:
	if formation <= 0.01:
		return
	var pulse := 0.92 + sin(progress * TAU * 3.0) * 0.08
	Toolkit.draw_soft_disc(
		self,
		clot_center,
		radius * 1.42 * pulse,
		Toolkit.with_alpha(DEEP_RED, alpha * 0.54),
		Toolkit.with_alpha(BLACK_FLESH, alpha * 0.92),
		8
	)
	for lobe_index in range(7):
		var angle := TAU * float(lobe_index) / 7.0 + progress * 0.52
		var lobe_radius := radius * (0.34 + float(lobe_index % 3) * 0.05)
		var lobe_center := clot_center + Vector2.from_angle(angle) * radius * (0.34 + sin(progress * 5.0 + float(lobe_index)) * 0.05)
		draw_circle(lobe_center, lobe_radius, Toolkit.with_alpha(DEEP_RED if lobe_index % 2 == 0 else LIVING_RED, alpha * 0.82))
		draw_circle(
			lobe_center - Vector2(lobe_radius * 0.18, lobe_radius * 0.22),
			lobe_radius * 0.14,
			Toolkit.with_alpha(WET_HIGHLIGHT, alpha * 0.62)
		)


func _draw_organization_seed(
	clot_center: Vector2,
	scale_value: float,
	release: float,
	alpha: float
) -> void:
	var ring_alpha := alpha * (1.0 - release * 0.28)
	for orbit_index in range(3):
		var orbit_radius := scale_value * (0.16 + float(orbit_index) * 0.055) * (0.72 + release * 0.38)
		var start_angle := progress * (2.0 + float(orbit_index) * 0.4) + float(orbit_index) * 1.7
		Toolkit.draw_stroked_arc(
			self,
			clot_center,
			orbit_radius,
			start_angle,
			start_angle + PI * (0.82 + float(orbit_index) * 0.08),
			scale_value * 0.018,
			Toolkit.with_alpha(LIVING_RED, ring_alpha * 0.72),
			Toolkit.with_alpha(VOID, ring_alpha * 0.74),
			Toolkit.with_alpha(WET_HIGHLIGHT, ring_alpha * 0.44),
			scale_value * 0.08,
			18
		)


func _draw_device_restraints(
	center_point: Vector2,
	card_size: Vector2,
	lock_phase: float,
	alpha: float
) -> void:
	if lock_phase <= 0.01:
		return
	var half_size := card_size * Vector2(0.49, 0.47)
	for clamp_index in range(4):
		var angle := PI * 0.5 * float(clamp_index)
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var extent := half_size.x if absf(direction.x) > 0.5 else half_size.y
		var anchor := center_point + direction * extent
		var jaw_center := anchor - direction * _target_scale() * 0.08 * lock_phase
		var jaw_size := Vector2(_target_scale() * 0.16, _target_scale() * 0.055)
		draw_set_transform(jaw_center, angle, Vector2.ONE)
		draw_rect(Rect2(-jaw_size * 0.5, jaw_size), Toolkit.with_alpha(DEVICE_DARK, alpha * 0.94), true)
		draw_rect(Rect2(-jaw_size * 0.5, jaw_size), Toolkit.with_alpha(DEVICE_BLUE, alpha * 0.82), false, 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Toolkit.draw_soft_disc(
			self,
			jaw_center + tangent * _target_scale() * 0.045,
			_target_scale() * 0.026,
			Toolkit.with_alpha(DEVICE_BLUE, alpha * 0.38),
			Toolkit.with_alpha(DEVICE_CORE, alpha * 0.78),
			5
		)


func _draw_source_instrument(
	center_point: Vector2,
	card_size: Vector2,
	lock_phase: float,
	alpha: float
) -> void:
	if lock_phase <= 0.01:
		return
	var radius := minf(card_size.x, card_size.y) * (0.35 + lock_phase * 0.10)
	for arc_index in range(4):
		var start_angle := float(arc_index) * PI * 0.5 + progress * 0.34
		Toolkit.draw_stroked_arc(
			self,
			center_point,
			radius,
			start_angle,
			start_angle + PI * 0.30,
			_target_scale() * 0.024,
			Toolkit.with_alpha(DEVICE_BLUE, alpha * 0.66),
			Toolkit.with_alpha(DEVICE_DARK, alpha * 0.88),
			Toolkit.with_alpha(DEVICE_CORE, alpha * 0.44),
			_target_scale() * 0.10,
			14
		)


func _draw_specimen_pod(
	pod_center: Vector2,
	scale_value: float,
	seal: float,
	release: float,
	alpha: float
) -> void:
	if seal <= 0.01:
		return
	var lift := Vector2(0.0, -scale_value * 0.16 * release)
	var center_point := pod_center + lift
	var pod_radii := Vector2(scale_value * 0.22, scale_value * 0.14) * (0.78 + seal * 0.22)
	Toolkit.draw_soft_ellipse(
		self,
		center_point,
		pod_radii * 1.28,
		Toolkit.with_alpha(DEVICE_BLUE, alpha * 0.26),
		Toolkit.with_alpha(VOID, alpha * 0.76),
		7,
		-0.12
	)
	draw_arc(center_point, pod_radii.x, PI * 0.18, PI * 0.82, 24, Toolkit.with_alpha(DEVICE_CORE, alpha * 0.72), 2.2, true)
	draw_arc(center_point, pod_radii.x, PI * 1.18, PI * 1.82, 24, Toolkit.with_alpha(DEVICE_BLUE, alpha * 0.68), 2.2, true)
	var cap_size := Vector2(scale_value * 0.12, scale_value * 0.035)
	draw_rect(Rect2(center_point - Vector2(cap_size.x * 0.5, pod_radii.y * 1.02), cap_size), Toolkit.with_alpha(DEVICE_DARK, alpha * 0.96), true)


func _draw_rc_droplets(
	start_point: Vector2,
	finish_point: Vector2,
	travel: float,
	release: float,
	alpha: float
) -> void:
	if travel <= 0.01:
		return
	var direction := finish_point - start_point
	var normal := direction.normalized().orthogonal() if direction.length_squared() > 0.01 else Vector2.UP
	for droplet_index in range(11):
		var ratio := fmod(travel * 1.28 + float(droplet_index) * 0.087, 1.0)
		var drift := normal * sin(float(droplet_index) * 2.17 + progress * 4.0) * _target_scale() * 0.09
		var droplet_center := start_point.lerp(finish_point, ratio) + drift - Vector2(0.0, release * _target_scale() * 0.08)
		Toolkit.draw_mote(
			self,
			droplet_center,
			_target_scale() * (0.010 + float(droplet_index % 3) * 0.004),
			Toolkit.with_alpha(LIVING_RED if droplet_index % 3 != 0 else WET_HIGHLIGHT, alpha * (1.0 - ratio * 0.34)),
			progress * 9.0 + float(droplet_index)
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


func _sample_path(points: PackedVector2Array, ratio: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled := clampf(ratio, 0.0, 1.0) * float(points.size() - 1)
	var first_index := mini(int(floor(scaled)), points.size() - 1)
	var second_index := mini(first_index + 1, points.size() - 1)
	return points[first_index].lerp(points[second_index], scaled - float(first_index))


func _target_scale() -> float:
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
