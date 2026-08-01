extends Control

const Palette := preload("res://scripts/ui/animation/beastmen_vfx_palette.gd")

var cell_rects: Array[Rect2] = []
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(local_cell_rects: Array[Rect2]) -> void:
	cell_rects = local_cell_rects.duplicate()
	queue_redraw()


func _draw() -> void:
	if cell_rects.is_empty():
		return
	var dig_progress := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.72))
	var seal_progress := Palette.ease_out(Palette.phase(progress, 0.48, 0.90))
	var fade := 1.0 - Palette.phase(progress, 0.88, 1.0) * 0.72
	var cell_scale := maxf(minf(cell_rects[0].size.x, cell_rects[0].size.y), 48.0)
	var centers := PackedVector2Array()
	for cell_rect in cell_rects:
		centers.append(cell_rect.get_center())

	_draw_excavated_trench(centers, cell_scale, dig_progress, fade)
	for cell_index in range(cell_rects.size()):
		var local_phase := clampf(dig_progress * float(cell_rects.size()) - float(cell_index) + 0.35, 0.0, 1.0)
		if local_phase <= 0.0:
			continue
		_draw_cell_excavation(cell_rects[cell_index], cell_index, local_phase, fade)
		_draw_path_mark(cell_rects[cell_index].get_center(), cell_scale, cell_index, seal_progress, fade)

	var head_center := _sample_polyline(centers, dig_progress)
	_draw_dig_head(head_center, cell_scale, dig_progress, fade)
	if seal_progress > 0.0:
		_draw_bone_stake(centers[0], cell_scale, -1.0, seal_progress * fade)
		_draw_bone_stake(centers[centers.size() - 1], cell_scale, 1.0, seal_progress * fade)


func _draw_excavated_trench(
	centers: PackedVector2Array,
	cell_scale: float,
	visible_progress: float,
	alpha: float
) -> void:
	if centers.size() < 2:
		return
	var visible_points := _partial_polyline(centers, visible_progress)
	if visible_points.size() < 2:
		return

	var trench_width := cell_scale * 0.28
	draw_polyline(visible_points, Palette.with_alpha(Palette.SOIL_BLACK, 0.90 * alpha), trench_width, true)
	draw_polyline(visible_points, Palette.with_alpha(Palette.DEEP_EARTH, 0.82 * alpha), trench_width * 0.64, true)

	for edge_sign in [-1.0, 1.0]:
		var edge_points := PackedVector2Array()
		for point_index in range(visible_points.size()):
			var previous_index := maxi(point_index - 1, 0)
			var next_index := mini(point_index + 1, visible_points.size() - 1)
			var tangent := (visible_points[next_index] - visible_points[previous_index]).normalized()
			if tangent == Vector2.ZERO:
				tangent = Vector2.RIGHT
			var normal := tangent.orthogonal()
			var jag := sin(float(point_index) * 2.41 + edge_sign) * cell_scale * 0.025
			edge_points.append(visible_points[point_index] + normal * (trench_width * 0.55 * edge_sign + jag))
		draw_polyline(edge_points, Palette.with_alpha(Palette.DUST, 0.80 * alpha), cell_scale * 0.045, true)
		draw_polyline(edge_points, Palette.with_alpha(Palette.COPPER, 0.56 * alpha), cell_scale * 0.014, true)


func _draw_cell_excavation(cell_rect: Rect2, cell_index: int, phase_value: float, alpha: float) -> void:
	var center := cell_rect.get_center()
	var half := cell_rect.size * (0.43 + phase_value * 0.03)
	var corners := PackedVector2Array([
		center + Vector2(-half.x, -half.y * 0.78),
		center + Vector2(-half.x * 0.82, -half.y),
		center + Vector2(half.x * 0.76, -half.y * 0.92),
		center + Vector2(half.x, -half.y * 0.60),
		center + Vector2(half.x * 0.91, half.y * 0.84),
		center + Vector2(half.x * 0.58, half.y),
		center + Vector2(-half.x * 0.88, half.y * 0.91),
		center + Vector2(-half.x, half.y * 0.54),
	])
	draw_colored_polygon(corners, Palette.with_alpha(Palette.DEEP_EARTH, 0.12 * phase_value * alpha))
	var outline := corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, Palette.with_alpha(Palette.DUST, 0.30 * phase_value * alpha), 2.0 + float(cell_index % 2), true)

	for debris_index in range(7):
		var angle := TAU * float(debris_index) / 7.0 + float(cell_index) * 0.37
		var direction := Vector2(cos(angle), sin(angle))
		var debris_center := center + direction * minf(half.x, half.y) * (0.72 + float(debris_index % 3) * 0.10)
		var debris_radius := minf(cell_rect.size.x, cell_rect.size.y) * (0.010 + float(debris_index % 3) * 0.004)
		draw_circle(debris_center, debris_radius, Palette.with_alpha(Palette.DUST, 0.48 * phase_value * alpha))


func _draw_path_mark(
	center: Vector2,
	cell_scale: float,
	cell_index: int,
	phase_value: float,
	alpha: float
) -> void:
	if phase_value <= 0.0:
		return
	var direction := _path_direction(cell_index)
	var side := direction.orthogonal()
	var step_offset := direction * cell_scale * 0.12
	for print_index in range(2):
		var print_center := center + step_offset * float(print_index * 2 - 1) + side * cell_scale * (0.05 if print_index == 0 else -0.05)
		_draw_hoof_print(print_center, cell_scale * 0.055, phase_value * alpha)


func _draw_dig_head(center: Vector2, cell_scale: float, phase_value: float, alpha: float) -> void:
	if phase_value <= 0.0 or phase_value >= 0.995:
		return
	for shard_index in range(12):
		var angle := TAU * float(shard_index) / 12.0 + sin(float(shard_index) * 1.77) * 0.24
		var direction := Vector2(cos(angle), sin(angle))
		var distance := cell_scale * (0.10 + float(shard_index % 4) * 0.045)
		var shard_center := center + direction * distance
		var shard := PackedVector2Array([
			shard_center - direction.orthogonal() * cell_scale * 0.020,
			shard_center + direction * cell_scale * 0.070,
			shard_center + direction.orthogonal() * cell_scale * 0.020,
		])
		draw_colored_polygon(shard, Palette.with_alpha(Palette.DUST, 0.76 * alpha))
	draw_circle(center, cell_scale * 0.085, Palette.with_alpha(Palette.SOIL_BLACK, 0.70 * alpha))


func _draw_bone_stake(center: Vector2, cell_scale: float, side_sign: float, alpha: float) -> void:
	var stake_center := center + Vector2(side_sign * cell_scale * 0.23, -cell_scale * 0.20)
	var direction := Vector2(0.14 * side_sign, 1.0).normalized()
	var start_point := stake_center - direction * cell_scale * 0.20
	var end_point := stake_center + direction * cell_scale * 0.22
	draw_line(start_point, end_point, Palette.with_alpha(Palette.SOIL_BLACK, 0.78 * alpha), cell_scale * 0.070, true)
	draw_line(start_point, end_point, Palette.with_alpha(Palette.BONE, 0.88 * alpha), cell_scale * 0.038, true)
	for tip_sign in [-1.0, 1.0]:
		var tip_side: Vector2 = direction.orthogonal() * tip_sign
		draw_line(start_point, start_point + tip_side * cell_scale * 0.085, Palette.with_alpha(Palette.BONE_HIGHLIGHT, 0.82 * alpha), cell_scale * 0.025, true)


func _draw_hoof_print(center: Vector2, radius: float, alpha: float) -> void:
	for side_sign in [-1.0, 1.0]:
		var hoof_center := center + Vector2(side_sign * radius * 0.34, 0.0)
		draw_arc(
			hoof_center,
			radius * 0.64,
			PI * 0.14,
			PI * 1.86,
			12,
			Palette.with_alpha(Palette.BONE, 0.68 * alpha),
			maxf(radius * 0.24, 1.2),
			true
		)


func _path_direction(cell_index: int) -> Vector2:
	if cell_rects.size() <= 1:
		return Vector2.RIGHT
	var previous_index := maxi(cell_index - 1, 0)
	var next_index := mini(cell_index + 1, cell_rects.size() - 1)
	var direction := cell_rects[next_index].get_center() - cell_rects[previous_index].get_center()
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _partial_polyline(points: PackedVector2Array, visible_progress: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty():
		return result
	if points.size() == 1:
		result.append(points[0])
		return result

	var scaled := clampf(visible_progress, 0.0, 1.0) * float(points.size() - 1)
	var full_segments := mini(int(floor(scaled)), points.size() - 1)
	for point_index in range(full_segments + 1):
		result.append(points[point_index])
	if full_segments < points.size() - 1:
		result.append(points[full_segments].lerp(points[full_segments + 1], scaled - float(full_segments)))
	return result


func _sample_polyline(points: PackedVector2Array, ratio: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled := clampf(ratio, 0.0, 1.0) * float(points.size() - 1)
	var point_index := mini(int(floor(scaled)), points.size() - 2)
	return points[point_index].lerp(points[point_index + 1], scaled - float(point_index))
