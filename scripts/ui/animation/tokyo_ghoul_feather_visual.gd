extends Control

# Ukaku projectiles are light organic shards, not generic beams. Coordinates
# are local to the animation root so the effect remains independent of rules.

const MEMBRANE := Color(0.72, 0.045, 0.19, 0.86)
const BLOOD_EDGE := Color(0.98, 0.24, 0.38, 0.94)
const COLD_EDGE := Color(0.98, 0.84, 0.90, 0.94)
const RC_GLOW := Color(0.58, 0.10, 0.42, 0.62)

var source_point := Vector2.ZERO
var target_point := Vector2.ZERO
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func configure(source: Vector2, target: Vector2) -> void:
	source_point = source
	target_point = target
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var vector := target_point - source_point
	if vector.length() <= 0.1:
		return

	var direction := vector.normalized()
	var normal := direction.orthogonal()
	var distance := vector.length()
	var gather := _stage(0.0, 0.22)
	var flight := _stage(0.16, 0.70)
	var impact := _stage(0.64, 0.90)
	var fade := 1.0 - _stage(0.86, 1.0)

	_draw_source_fan(direction, normal, distance, gather, fade)
	for shard_index in range(5):
		var delay := float(shard_index) * 0.035
		var shard_progress := clampf((flight - delay) / maxf(1.0 - delay, 0.01), 0.0, 1.0)
		var offset := normal * float(shard_index - 2) * 6.0
		var curve := sin(shard_progress * PI) * float(shard_index - 2) * 3.2
		var position := source_point.lerp(target_point, shard_progress) + offset + normal * curve
		var shard_length := clampf(distance * 0.045, 11.0, 25.0)
		_draw_shard(position, direction, normal, shard_length, 2.8 + float(shard_index % 2), fade)
		var trail_start := position - direction * shard_length * (1.8 + flight)
		draw_line(
			trail_start,
			position - direction * shard_length * 0.36,
			Color(BLOOD_EDGE.r, BLOOD_EDGE.g, BLOOD_EDGE.b, 0.22 * fade * flight),
			1.1,
			true
		)

	if impact > 0.0:
		_draw_impact(direction, normal, impact, fade)


func _draw_source_fan(
	direction: Vector2,
	normal: Vector2,
	distance: float,
	gather: float,
	alpha: float
) -> void:
	var fan_length := clampf(distance * 0.065, 16.0, 34.0) * gather
	for fan_index in range(5):
		var spread := float(fan_index - 2) * 0.20
		var fan_direction := direction.rotated(spread)
		var fan_normal := fan_direction.orthogonal()
		var center := source_point - direction * 4.0 + fan_direction * fan_length * 0.44
		_draw_shard(center, fan_direction, fan_normal, fan_length, 3.2, alpha * (1.0 - progress * 0.45))
	draw_circle(source_point, 5.0 * gather, Color(RC_GLOW.r, RC_GLOW.g, RC_GLOW.b, RC_GLOW.a * alpha))
	draw_arc(source_point, 11.0 * gather, -PI * 0.72, PI * 0.72, 18, Color(BLOOD_EDGE.r, BLOOD_EDGE.g, BLOOD_EDGE.b, 0.52 * alpha), 1.5, true)


func _draw_shard(
	center: Vector2,
	direction: Vector2,
	normal: Vector2,
	length: float,
	half_width: float,
	alpha: float
) -> void:
	if length <= 0.1 or alpha <= 0.01:
		return
	var root := center - direction * length * 0.42
	var tip := center + direction * length * 0.58
	var points := PackedVector2Array([
		root - normal * half_width * 0.36,
		center - normal * half_width,
		tip,
		center + normal * half_width,
		root + normal * half_width * 0.36
	])
	draw_colored_polygon(points, Color(MEMBRANE.r, MEMBRANE.g, MEMBRANE.b, MEMBRANE.a * alpha))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(COLD_EDGE.r, COLD_EDGE.g, COLD_EDGE.b, COLD_EDGE.a * alpha), 1.0, true)
	draw_line(root, tip, Color(BLOOD_EDGE.r, BLOOD_EDGE.g, BLOOD_EDGE.b, BLOOD_EDGE.a * alpha), 1.0, true)


func _draw_impact(direction: Vector2, normal: Vector2, impact: float, alpha: float) -> void:
	var contraction := 1.0 - impact
	var pulse_radius := lerpf(4.0, 24.0, impact)
	draw_circle(target_point, pulse_radius * 1.25, Color(RC_GLOW.r, RC_GLOW.g, RC_GLOW.b, 0.10 * contraction * alpha))
	draw_arc(target_point, pulse_radius, 0.0, TAU, 30, Color(COLD_EDGE.r, COLD_EDGE.g, COLD_EDGE.b, 0.68 * contraction * alpha), 1.6, true)
	for spike_index in range(7):
		var angle := TAU * float(spike_index) / 7.0 + direction.angle() * 0.25
		var spike_direction := Vector2.from_angle(angle)
		var start := target_point + spike_direction * pulse_radius * 0.28
		var finish := target_point + spike_direction * pulse_radius * (0.58 + float(spike_index % 2) * 0.28)
		draw_line(start, finish, Color(BLOOD_EDGE.r, BLOOD_EDGE.g, BLOOD_EDGE.b, 0.72 * contraction * alpha), 1.8, true)

	for cut_index in range(3):
		var offset := normal * float(cut_index - 1) * 4.5
		draw_line(
			target_point - direction * 9.0 + offset,
			target_point + direction * 9.0 + offset,
			Color(COLD_EDGE.r, COLD_EDGE.g, COLD_EDGE.b, 0.74 * contraction * alpha),
			1.2,
			true
		)


func _stage(start: float, finish: float) -> float:
	if finish <= start:
		return 1.0 if progress >= finish else 0.0
	var value := clampf((progress - start) / (finish - start), 0.0, 1.0)
	return value * value * (3.0 - 2.0 * value)
