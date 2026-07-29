extends RefCounted

# Shared lifecycle, timing, coordinate, and path math for Night Elf transient VFX.
const VFX_Z_INDEX := 2470
const PROJECTILE_Z_INDEX := 2490
const TIME_VFX_Z_INDEX := 2450

var _base_duration := 0.32


func setup(duration: float) -> void:
	_base_duration = maxf(duration, 0.04)


func scaled_duration(multiplier: float, minimum: float) -> float:
	return maxf(_base_duration * multiplier, minimum)


func finish_root(owner: Node, root: Control, duration: float) -> void:
	if owner == null or not is_instance_valid(root):
		return
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(root, "modulate:a", 0.0, maxf(duration, 0.04))
	await tween.finished
	if is_instance_valid(root):
		root.queue_free()


func card_scale(target_rect: Rect2) -> float:
	return maxf(minf(target_rect.size.x, target_rect.size.y), 52.0)


func to_root_local(root: Control, global_point: Vector2) -> Vector2:
	return global_point - root.global_position


func quadratic_bezier(
	start_point: Vector2,
	control_point: Vector2,
	end_point: Vector2,
	t: float
) -> Vector2:
	var clamped_t := clampf(t, 0.0, 1.0)
	var inverse := 1.0 - clamped_t
	return (
		start_point * inverse * inverse
		+ control_point * 2.0 * inverse * clamped_t
		+ end_point * clamped_t * clamped_t
	)
