extends Control
class_name FoxSpiritTargetVisual

# Procedural single-card VFX for the Fox Spirit faction. This node owns drawing
# only; rule state and animation routing stay outside it.

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

const CRIMSON := Color(0.72, 0.035, 0.16, 1.0)
const ROUGE := Color(0.95, 0.16, 0.40, 1.0)
const VIOLET := Color(0.56, 0.16, 0.78, 1.0)
const DEEP_PURPLE := Color(0.12, 0.015, 0.18, 1.0)
const MOON_WHITE := Color(0.95, 0.94, 1.0, 1.0)
const GHOST_BLUE := Color(0.26, 0.76, 0.92, 1.0)
const PEARL_GOLD := Color(0.92, 0.78, 0.46, 1.0)

var animation_key := ""
var source_point := Vector2.ZERO
var target_point := Vector2.ZERO
var source_extent := Vector2(48.0, 66.0)
var target_extent := Vector2(48.0, 66.0)
var strength := 1.0
var secondary_point := Vector2.ZERO
var has_secondary_point := false
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(
	key: String,
	local_source: Vector2,
	local_target: Vector2,
	new_source_extent: Vector2,
	new_target_extent: Vector2,
	new_strength := 1.0,
	new_secondary_point := Vector2.ZERO,
	use_secondary_point := false
) -> void:
	animation_key = key
	source_point = local_source
	target_point = local_target
	source_extent = new_source_extent
	target_extent = new_target_extent
	strength = maxf(new_strength, 0.1)
	secondary_point = new_secondary_point
	has_secondary_point = use_secondary_point
	queue_redraw()


func _draw() -> void:
	_draw_perfume_veil()
	match animation_key:
		"sacrifice", "nine_tail_sacrifice":
			_draw_sacrifice()
		"fox_reborn":
			_draw_reborn_seal()
		"soul_hook":
			_draw_soul_hook()
		"fox_mind_art":
			_draw_charm(true)
		"nine_tail_tail_enter":
			_draw_tail_avatar_entry()
		_:
			_draw_charm(false)


func _draw_perfume_veil() -> void:
	var life := sin(progress * PI)
	if life <= 0.01:
		return
	var anchor := target_point if target_point != Vector2.ZERO else source_point
	var radius := maxf(minf(target_extent.x, target_extent.y), 36.0)
	var veil_color := VIOLET
	match animation_key:
		"sacrifice", "nine_tail_sacrifice":
			veil_color = CRIMSON
		"fox_reborn", "nine_tail_tail_enter":
			veil_color = MOON_WHITE
	Toolkit.draw_soft_ellipse(
		self,
		anchor,
		Vector2(radius * 0.72, radius * 1.02),
		Color(veil_color.r, veil_color.g, veil_color.b, life * 0.11),
		Color(ROUGE.r, ROUGE.g, ROUGE.b, life * 0.10),
		7,
		sin(progress * TAU) * 0.08
	)
	for mote_index in range(8):
		var angle := TAU * float(mote_index) / 8.0 + progress * (0.72 + float(mote_index % 3) * 0.08)
		var orbit := Vector2(radius * (0.48 + float(mote_index % 2) * 0.16), radius * 0.82)
		var mote_point := anchor + Vector2(cos(angle) * orbit.x, sin(angle) * orbit.y)
		Toolkit.draw_mote(
			self,
			mote_point,
			radius * (0.018 + float(mote_index % 3) * 0.006),
			Color(veil_color.r, veil_color.g, veil_color.b, life * 0.28),
			progress * 7.0 + float(mote_index)
		)


func _draw_sacrifice() -> void:
	var is_nine_tail := animation_key == "nine_tail_sacrifice"
	var ritual_edge := MOON_WHITE if is_nine_tail else ROUGE
	var ritual_core := VIOLET if is_nine_tail else CRIMSON
	var gather := _phase(0.0, 0.30)
	var transfer := _phase(0.20, 0.82)
	var release := _phase(0.68, 1.0)
	var card_radius := maxf(minf(source_extent.x, source_extent.y) * 0.48, 18.0)
	var eye_open := clampf(1.0 - gather * 0.76, 0.12, 1.0)

	_draw_card_frame(
		source_point,
		source_extent,
		Color(DEEP_PURPLE.r, DEEP_PURPLE.g, DEEP_PURPLE.b, 0.30 * (1.0 - release)),
		Color(ritual_edge.r, ritual_edge.g, ritual_edge.b, 0.78 * (1.0 - release)),
		gather
	)
	_draw_fox_eye(
		source_point,
		card_radius * 0.72,
		eye_open,
		Color(0.20, 0.005, 0.05, 0.72 * (1.0 - release)),
		Color(ritual_core.r, ritual_core.g, ritual_core.b, 0.90 * (1.0 - release)),
		Color(ritual_edge.r, ritual_edge.g, ritual_edge.b, 0.94 * (1.0 - release))
	)

	# Organic soul threads first collapse into the card, then carry a fox-tail
	# seed toward the resource meter.
	for thread_index in range(4):
		var side := -1.0 + float(thread_index) * (2.0 / 3.0)
		var start := source_point + Vector2(side * card_radius * 0.72, card_radius * (0.24 + absf(side) * 0.16))
		var end := target_point
		var tangent := _safe_normal(target_point - source_point).orthogonal()
		var control_a := start + Vector2(0.0, -card_radius * (0.70 + 0.12 * thread_index))
		var control_b := source_point.lerp(end, 0.58) + tangent * side * card_radius * 0.90
		var points := _cubic_curve(start, control_a, control_b, end, transfer, 28)
		var thread_color := Color(
			ritual_edge.r if thread_index % 2 == 0 else ritual_core.r,
			ritual_edge.g if thread_index % 2 == 0 else ritual_core.g,
			ritual_edge.b if thread_index % 2 == 0 else ritual_core.b,
			(0.62 - float(thread_index) * 0.07) * (1.0 - release * 0.72)
		)
		_draw_layered_line(points, thread_color, 2.3 + float(thread_index % 2), 7.0)

	for mote_index in range(16):
		var mote_phase := clampf((transfer - float(mote_index % 5) * 0.055), 0.0, 1.0)
		if mote_phase <= 0.0:
			continue
		var angle := float(mote_index) * 2.39996
		var origin := source_point + Vector2(cos(angle), sin(angle)) * card_radius * (0.26 + 0.06 * float(mote_index % 4))
		var destination := target_point + Vector2(cos(angle), sin(angle)) * 5.0
		var mote_point := origin.lerp(destination, _ease_in_out(mote_phase))
		var mote_alpha := (1.0 - release) * (0.46 + 0.30 * sin(mote_phase * PI))
		draw_circle(
			mote_point,
			1.4 + float(mote_index % 3) * 0.55,
			Color(ritual_edge.r, ritual_edge.g, ritual_edge.b, mote_alpha)
		)

	if transfer > 0.02:
		var travel_point := _point_on_cubic(
			source_point,
			source_point + Vector2(0.0, -card_radius),
			source_point.lerp(target_point, 0.58) + _safe_normal(target_point - source_point).orthogonal() * card_radius,
			target_point,
			_ease_in_out(transfer)
		)
		_draw_tail_shape(
			travel_point,
			-PI * 0.52 + transfer * 0.42,
			card_radius * 0.42,
			card_radius * 0.13,
			Color(ritual_core.r, ritual_core.g, ritual_core.b, 0.84 * (1.0 - release * 0.72)),
			Color(ritual_edge.r, ritual_edge.g, ritual_edge.b, 0.78 * (1.0 - release))
		)

	if transfer > 0.72:
		var pulse := sin(_phase(0.72, 1.0) * PI)
		for ring_index in range(3):
			draw_arc(
				target_point,
				card_radius * (0.20 + float(ring_index) * 0.14 + release * 0.18),
				-PI,
				0.0,
				30,
				Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, pulse * (0.62 - float(ring_index) * 0.14)),
				1.8,
				true
			)

	if has_secondary_point and transfer > 0.64:
		var sync := _phase(0.68, 0.98)
		var sync_direction := _safe_normal(secondary_point - target_point)
		var sync_tangent := sync_direction.orthogonal()
		var sync_control_a := target_point.lerp(secondary_point, 0.30) + sync_tangent * card_radius * 0.46
		var sync_control_b := target_point.lerp(secondary_point, 0.72) - sync_tangent * card_radius * 0.28
		var sync_path := _cubic_curve(
			target_point,
			sync_control_a,
			sync_control_b,
			secondary_point,
			sync,
			24
		)
		var sync_alpha := sin(sync * PI) * 0.82
		_draw_layered_line(
			sync_path,
			Color(ROUGE.r, ROUGE.g, ROUGE.b, sync_alpha),
			1.8,
			6.0
		)
		if sync > 0.62:
			var imprint := clampf((sync - 0.62) / 0.38, 0.0, 1.0)
			_draw_fox_eye(
				secondary_point,
				card_radius * 0.26,
				imprint,
				Color(0.16, 0.005, 0.20, 0.30 * sync_alpha),
				Color(ROUGE.r, ROUGE.g, ROUGE.b, 0.72 * sync_alpha),
				Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.82 * sync_alpha)
			)


func _draw_reborn_seal() -> void:
	var gather := _phase(0.0, 0.32)
	var imprint := _phase(0.22, 0.76)
	var fade := _phase(0.72, 1.0)
	var radius := maxf(minf(target_extent.x, target_extent.y) * 0.55, 22.0)
	var alpha := 1.0 - fade

	for tail_index in range(5):
		var angle := lerpf(-PI * 0.90, -PI * 0.10, float(tail_index) / 4.0)
		var tail_alpha := alpha * (0.34 + imprint * 0.48)
		_draw_tail_shape(
			target_point + Vector2(0.0, radius * 0.30),
			angle,
			radius * (0.92 + 0.06 * float(tail_index % 2)) * gather,
			radius * 0.16,
			Color(0.88, 0.72, 1.0, tail_alpha),
			Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, tail_alpha * 0.82)
		)

	var seal_radius := radius * (0.34 + imprint * 0.16)
	draw_circle(target_point, seal_radius, Color(0.22, 0.03, 0.30, 0.30 * alpha))
	for ring_index in range(3):
		draw_arc(
			target_point,
			seal_radius + float(ring_index) * 4.0,
			-PI * 0.80 + float(ring_index) * 0.34,
			PI * 1.22 + float(ring_index) * 0.34,
			46,
			Color(
				MOON_WHITE.r if ring_index == 0 else PEARL_GOLD.r,
				MOON_WHITE.g if ring_index == 0 else PEARL_GOLD.g,
				MOON_WHITE.b if ring_index == 0 else PEARL_GOLD.b,
				alpha * (0.80 - float(ring_index) * 0.16)
			),
			2.2,
			true
		)
	_draw_fox_eye(
		target_point,
		seal_radius * 0.76,
		imprint,
		Color(0.12, 0.01, 0.18, 0.62 * alpha),
		Color(0.92, 0.70, 1.0, 0.92 * alpha),
		Color(PEARL_GOLD.r, PEARL_GOLD.g, PEARL_GOLD.b, 0.96 * alpha)
	)


func _draw_soul_hook() -> void:
	var gather := _phase(0.0, 0.25)
	var pull := _phase(0.18, 0.78)
	var settle := _phase(0.68, 1.0)
	var radius := maxf(minf(target_extent.x, target_extent.y) * 0.48, 20.0)
	var direction := _safe_normal(target_point - source_point)
	if source_point.distance_to(target_point) < 2.0:
		direction = Vector2(-0.70, -0.72)
	var tangent := direction.orthogonal()
	var thread_end := target_point - direction * radius * 0.08
	var thread_start := source_point + direction * minf(radius * 0.55, source_point.distance_to(target_point) * 0.12)
	var control_a := thread_start.lerp(thread_end, 0.34) + tangent * radius * 0.70
	var control_b := thread_start.lerp(thread_end, 0.72) - tangent * radius * 0.48
	var thread_points := _cubic_curve(thread_start, control_a, control_b, thread_end, pull, 30)
	_draw_layered_line(thread_points, Color(0.62, 0.16, 0.76, 0.82 * (1.0 - settle)), 2.6, 9.0)

	if source_point.distance_to(target_point) > 3.0:
		_draw_fox_eye(
			source_point,
			radius * 0.42,
			gather,
			Color(0.12, 0.005, 0.16, 0.58 * (1.0 - settle)),
			Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.84 * (1.0 - settle)),
			Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.90 * (1.0 - settle))
		)

	_draw_card_frame(
		target_point,
		target_extent,
		Color(0.18, 0.01, 0.24, 0.20 * (1.0 - settle)),
		Color(0.72, 0.22, 0.90, 0.70 * (1.0 - settle)),
		gather
	)

	# The displaced translucent card silhouette reads as a fragment of the
	# target's spirit being pulled out, without relying on a literal character.
	var soul_offset := -direction * radius * 0.72 * pull + tangent * radius * 0.12 * sin(pull * PI)
	var soul_rect := Rect2(target_point - target_extent * 0.34 + soul_offset, target_extent * 0.68)
	draw_rect(soul_rect, Color(0.72, 0.42, 0.92, 0.10 * (1.0 - settle)), true)
	draw_rect(soul_rect, Color(0.90, 0.70, 1.0, 0.48 * pull * (1.0 - settle)), false, 2.0, true)
	_draw_fox_eye(
		soul_rect.get_center(),
		minf(soul_rect.size.x, soul_rect.size.y) * 0.24,
		pull,
		Color(0.18, 0.01, 0.24, 0.34 * (1.0 - settle)),
		Color(0.76, 0.36, 0.94, 0.64 * (1.0 - settle)),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.72 * (1.0 - settle))
	)

	var attack_anchor := target_point + Vector2(-target_extent.x * 0.31, target_extent.y * 0.31)
	for crack_index in range(4):
		var crack_angle := -PI * 0.92 + float(crack_index) * 0.42
		var crack_length := radius * (0.22 + 0.05 * float(crack_index % 2)) * gather
		draw_line(
			attack_anchor,
			attack_anchor + Vector2(cos(crack_angle), sin(crack_angle)) * crack_length,
			Color(0.96, 0.30, 0.62, 0.82 * (1.0 - settle)),
			2.0,
			true
		)


func _draw_charm(is_temporary: bool) -> void:
	var gather := _phase(0.0, 0.26)
	var rewrite := _phase(0.18, 0.76)
	var settle := _phase(0.72, 1.0)
	var radius := maxf(minf(target_extent.x, target_extent.y) * 0.52, 22.0)
	var alpha := 1.0 - settle
	var line_direction := _safe_normal(target_point - source_point)
	if source_point.distance_to(target_point) < 2.0:
		line_direction = Vector2(0.0, -1.0)
	var tangent := line_direction.orthogonal()

	if source_point.distance_to(target_point) > 3.0:
		for ribbon_index in range(3):
			var offset := (float(ribbon_index) - 1.0) * radius * 0.15
			var start := source_point + tangent * offset
			var end := target_point + tangent * offset * 0.35
			var control_a := start.lerp(end, 0.30) + tangent * radius * (0.42 - 0.12 * ribbon_index)
			var control_b := start.lerp(end, 0.72) - tangent * radius * (0.24 + 0.08 * ribbon_index)
			var ribbon := _cubic_curve(start, control_a, control_b, end, rewrite, 28)
			var ribbon_color := Color(
				0.88 if ribbon_index != 1 else 0.56,
				0.16,
				0.62 if ribbon_index != 1 else 0.86,
				alpha * (0.48 + 0.12 * float(ribbon_index == 1))
			)
			_draw_layered_line(ribbon, ribbon_color, 2.2, 7.0)

	_draw_card_frame(
		target_point,
		target_extent,
		Color(0.24, 0.02, 0.26, 0.16 * alpha),
		Color(0.94, 0.24, 0.68, (0.76 if not is_temporary else 0.56) * alpha),
		gather,
		is_temporary
	)

	for ripple_index in range(3):
		var ripple_radius := radius * (0.38 + float(ripple_index) * 0.20 + rewrite * 0.15)
		draw_arc(
			target_point,
			ripple_radius,
			-PI * 0.82 + float(ripple_index) * 0.30,
			PI * 0.82 + float(ripple_index) * 0.30,
			36,
			Color(0.70, 0.32, 0.92, alpha * (0.42 - float(ripple_index) * 0.09)),
			1.8,
			true
		)

	_draw_fox_eye(
		target_point,
		radius * 0.72,
		(rewrite * 0.62 if is_temporary else rewrite),
		Color(0.12, 0.005, 0.16, 0.58 * alpha),
		Color(0.96, 0.26, 0.72, 0.88 * alpha),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.92 * alpha),
		is_temporary
	)

	# A lower-edge ownership ribbon is more legible than romance imagery. The
	# temporary variant keeps the old-color underlay visible as a second band.
	var ribbon_y := target_point.y + target_extent.y * 0.36
	var ribbon_half := target_extent.x * 0.34
	if is_temporary:
		draw_line(
			Vector2(target_point.x - ribbon_half, ribbon_y + 4.0),
			Vector2(target_point.x + ribbon_half, ribbon_y + 4.0),
			Color(0.24, 0.58, 0.92, 0.52 * alpha),
			3.0,
			true
		)
	draw_line(
		Vector2(target_point.x - ribbon_half * rewrite, ribbon_y),
		Vector2(target_point.x + ribbon_half * rewrite, ribbon_y),
		Color(0.96, 0.24, 0.66, 0.86 * alpha),
		3.5,
		true
	)


func _draw_tail_avatar_entry() -> void:
	var gather := _phase(0.0, 0.34)
	var form := _phase(0.24, 0.78)
	var fade := _phase(0.76, 1.0)
	var radius := maxf(minf(target_extent.x, target_extent.y) * 0.58, 24.0)
	var alpha := 1.0 - fade
	var base := target_point + Vector2(0.0, radius * 0.42)

	for trail_index in range(3):
		var trail_progress := clampf(form - float(trail_index) * 0.08, 0.0, 1.0)
		var start := base + Vector2(-radius * 0.38 + radius * 0.38 * trail_index, -radius * 1.30)
		var control_a := start + Vector2(radius * (0.42 - trail_index * 0.22), radius * 0.34)
		var control_b := base + Vector2(radius * (-0.40 + trail_index * 0.40), -radius * 0.34)
		var trail := _cubic_curve(start, control_a, control_b, base, trail_progress, 22)
		_draw_layered_line(trail, Color(0.48, 0.64, 1.0, 0.44 * alpha), 2.1, 7.0)

	_draw_tail_shape(
		base,
		-PI * 0.50,
		radius * 1.25 * gather,
		radius * 0.30,
		Color(0.82, 0.66, 1.0, 0.56 * alpha),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.90 * alpha)
	)
	_draw_fox_eye(
		target_point,
		radius * 0.34,
		form,
		Color(0.12, 0.02, 0.22, 0.48 * alpha),
		Color(0.52, 0.70, 1.0, 0.72 * alpha),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, 0.90 * alpha)
	)
	for ring_index in range(2):
		draw_arc(
			target_point + Vector2(0.0, radius * 0.22),
			radius * (0.54 + float(ring_index) * 0.12) * form,
			-PI * 0.98,
			-PI * 0.02,
			34,
			Color(0.82, 0.68, 1.0, alpha * (0.52 - float(ring_index) * 0.14)),
			2.0,
			true
		)


func _draw_card_frame(
	center: Vector2,
	extent: Vector2,
	fill: Color,
	edge: Color,
	reveal: float,
	dual := false
) -> void:
	var safe_extent := Vector2(maxf(extent.x, 16.0), maxf(extent.y, 20.0))
	var frame_rect := Rect2(center - safe_extent * 0.43, safe_extent * 0.86)
	draw_rect(frame_rect, fill, true)
	var edge_alpha := edge.a * clampf(reveal, 0.0, 1.0)
	draw_rect(frame_rect, Color(edge.r, edge.g, edge.b, edge_alpha * 0.46), false, 7.0, true)
	draw_rect(frame_rect, Color(edge.r, edge.g, edge.b, edge_alpha), false, 2.0, true)
	if dual:
		draw_rect(
			frame_rect.grow(-4.0),
			Color(0.30, 0.62, 0.96, edge_alpha * 0.44),
			false,
			1.7,
			true
		)


func _draw_fox_eye(
	center: Vector2,
	radius: float,
	openness: float,
	fill: Color,
	edge: Color,
	core: Color,
	partial := false
) -> void:
	var safe_open := clampf(openness, 0.0, 1.0)
	var eye_height := radius * (0.10 + safe_open * 0.34)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for point_index in range(25):
		var t := float(point_index) / 24.0
		var x := lerpf(-radius, radius, t)
		var arch := sin(t * PI) * eye_height
		upper.append(center + Vector2(x, -arch))
		lower.append(center + Vector2(x, arch * (0.86 if partial else 1.0)))
	var eye_polygon := PackedVector2Array()
	for point in upper:
		eye_polygon.append(point)
	for point_index in range(lower.size() - 1, -1, -1):
		eye_polygon.append(lower[point_index])
	draw_colored_polygon(eye_polygon, fill)
	_draw_layered_line(upper, edge, 2.2, 6.5)
	_draw_layered_line(lower, Color(edge.r, edge.g, edge.b, edge.a * (0.56 if partial else 1.0)), 2.2, 6.5)
	if safe_open > 0.16:
		_draw_ellipse(
			center + Vector2(0.0, eye_height * 0.04),
			Vector2(radius * 0.105, eye_height * (0.78 if not partial else 0.52)),
			Color(core.r, core.g, core.b, core.a * safe_open)
		)
		draw_circle(center + Vector2(-radius * 0.025, -eye_height * 0.16), maxf(radius * 0.022, 1.2), Color(1.0, 1.0, 1.0, core.a * 0.88))


func _draw_tail_shape(
	base: Vector2,
	angle: float,
	length: float,
	width: float,
	fill: Color,
	edge: Color
) -> void:
	if length <= 1.0:
		return
	var centerline := _tail_centerline(base, angle, length, width)
	Toolkit.draw_ribbon(
		self,
		centerline,
		width * 2.05,
		fill,
		Color(edge.r, edge.g, edge.b, edge.a * 0.72),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, fill.a * 0.30),
		width * 3.6,
		true,
		true,
		progress * 3.0 + angle
	)
	Toolkit.draw_soft_disc(
		self,
		centerline[centerline.size() - 1],
		maxf(width * 0.34, 1.2),
		Color(edge.r, edge.g, edge.b, edge.a * 0.30),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, edge.a * 0.24),
		5
	)


func _tail_centerline(base: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var centers := PackedVector2Array()
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := direction.orthogonal()
	for point_index in range(13):
		var t := float(point_index) / 12.0
		var bend := sin(t * PI) * width * 0.78 + t * t * width * 0.34
		centers.append(base + direction * length * t + tangent * bend)
	return centers


func _draw_layered_line(points: PackedVector2Array, color: Color, width: float, glow_width: float) -> void:
	if points.size() < 2 or color.a <= 0.001:
		return
	Toolkit.draw_ribbon(
		self,
		points,
		width,
		color,
		Color(DEEP_PURPLE.r, DEEP_PURPLE.g, DEEP_PURPLE.b, color.a * 0.38),
		Color(MOON_WHITE.r, MOON_WHITE.g, MOON_WHITE.b, color.a * 0.24),
		glow_width,
		true,
		true,
		progress * 3.6 + float(points.size()) * 0.11
	)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _cubic_curve(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end: Vector2,
	visible_progress: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_progress := clampf(visible_progress, 0.0, 1.0)
	var visible_segments := maxi(int(ceil(float(segments) * safe_progress)), 1)
	for point_index in range(visible_segments + 1):
		var local_t := float(point_index) / float(visible_segments)
		var curve_t := local_t * safe_progress
		points.append(_point_on_cubic(start, control_a, control_b, end, curve_t))
	return points


func _point_on_cubic(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end: Vector2,
	t: float
) -> Vector2:
	var inverse := 1.0 - t
	return (
		start * inverse * inverse * inverse
		+ control_a * 3.0 * inverse * inverse * t
		+ control_b * 3.0 * inverse * t * t
		+ end * t * t * t
	)


func _phase(start: float, end: float) -> float:
	return clampf((progress - start) / maxf(end - start, 0.0001), 0.0, 1.0)


func _ease_in_out(value: float) -> float:
	var safe_value := clampf(value, 0.0, 1.0)
	return safe_value * safe_value * (3.0 - 2.0 * safe_value)


func _safe_normal(vector: Vector2) -> Vector2:
	return vector.normalized() if vector.length_squared() > 0.0001 else Vector2.RIGHT
