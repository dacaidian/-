extends RefCounted
class_name MonkeyAnimationProvider

const MonkeySpellVisualScript := preload(
	"res://scripts/ui/animation/monkey_spell_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"fiery_eyes_golden_gaze",
	"somersault_cloud",
	"body_beyond_body",
	"bronze_head_iron_arms",
	"bronze_head_iron_arms_reflect",
	"immortal_peach",
	"drive_spirit",
	"drive_spirit_battlefield",
	"immobilize",
	"gather_scatter_qi",
	"dragon_palace_treasure",
	"heavenly_form",
	"hair_clone_enter",
	"monkey_hair_clone_assist",
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const BOARD_KEYS: Array[String] = [
	"fiery_eyes_golden_gaze",
	"drive_spirit_battlefield",
]
const MOVEMENT_KEYS: Array[String] = [
	"monkey_somersault_move",
	"monkey_westward_move",
]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func is_movement_key(animation_key: String) -> bool:
	return MOVEMENT_KEYS.has(animation_key)


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)
	router.register_from_rect(MOVEMENT_KEYS, play_from_rect)


func play_targeted(
	owner_node: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	var target_rect := target_card.get_global_rect()
	var source_rect := caster_card.get_global_rect() if caster_card != null else target_rect
	await _play_between_rects(
		owner_node,
		effect_root,
		source_rect,
		target_rect,
		animation_key
	)


func play_from_rect(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	await _play_between_rects(
		owner_node,
		effect_root,
		source_rect,
		target_card.get_global_rect(),
		animation_key
	)


func play_at_rect(
	owner_node: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	var canvas_rect := _single_effect_rect(target_rect, animation_key)
	if animation_key in BOARD_KEYS:
		canvas_rect = _root_effect_rect(effect_root, canvas_rect)
	await _play_visual(
		owner_node,
		effect_root,
		canvas_rect,
		target_rect.get_center(),
		target_rect.get_center(),
		animation_key
	)


func play_board(
	owner_node: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null:
		return
	var canvas_rect := _root_effect_rect(
		effect_root,
		Rect2(effect_root.global_position, effect_root.size)
	)
	await _play_visual(
		owner_node,
		effect_root,
		canvas_rect,
		canvas_rect.get_center(),
		canvas_rect.get_center(),
		animation_key
	)


func spawn_movement_path(
	owner_node: Node,
	effect_root: Control,
	from_rect: Rect2,
	to_rect: Rect2,
	animation_key: String,
	duration: float
) -> void:
	if (
		owner_node == null
		or effect_root == null
		or not MOVEMENT_KEYS.has(animation_key)
		or from_rect.size == Vector2.ZERO
		or to_rect.size == Vector2.ZERO
	):
		return
	var canvas_rect := _merged_effect_rect(from_rect, to_rect, 0.58)
	var visual := _create_visual(
		effect_root,
		canvas_rect,
		from_rect.get_center(),
		to_rect.get_center(),
		animation_key
	)
	if visual == null:
		return
	var total_duration := maxf(duration, 0.18)
	var fade_in_duration := minf(total_duration * 0.20, 0.06)
	var fade_out_duration := total_duration * 0.28
	var hold_duration := maxf(total_duration - fade_in_duration - fade_out_duration, 0.0)

	var progress_tween := owner_node.create_tween()
	progress_tween.set_trans(Tween.TRANS_SINE)
	progress_tween.set_ease(Tween.EASE_IN_OUT)
	progress_tween.tween_property(visual, "progress", 1.0, total_duration)

	var presentation_tween := owner_node.create_tween()
	presentation_tween.set_trans(Tween.TRANS_QUART)
	presentation_tween.set_ease(Tween.EASE_OUT)
	presentation_tween.tween_property(visual, "modulate:a", 1.0, fade_in_duration)
	if hold_duration > 0.0:
		presentation_tween.tween_interval(hold_duration)
	presentation_tween.set_trans(Tween.TRANS_SINE)
	presentation_tween.set_ease(Tween.EASE_IN)
	presentation_tween.tween_property(visual, "modulate:a", 0.0, fade_out_duration)
	presentation_tween.finished.connect(visual.queue_free)


func _play_between_rects(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if (
		owner_node == null
		or effect_root == null
		or source_rect.size == Vector2.ZERO
		or target_rect.size == Vector2.ZERO
	):
		return
	var canvas_rect := _merged_effect_rect(
		source_rect,
		target_rect,
		get_margin_scale(animation_key)
	)
	if animation_key in BOARD_KEYS and source_rect == target_rect:
		canvas_rect = _root_effect_rect(effect_root, canvas_rect)
	await _play_visual(
		owner_node,
		effect_root,
		canvas_rect,
		source_rect.get_center(),
		target_rect.get_center(),
		animation_key
	)


func _play_visual(
	owner_node: Node,
	effect_root: Control,
	canvas_rect: Rect2,
	global_source: Vector2,
	global_target: Vector2,
	animation_key: String
) -> void:
	var visual := _create_visual(
		effect_root,
		canvas_rect,
		global_source,
		global_target,
		animation_key
	)
	if visual == null:
		return

	var total_duration := maxf(
		spell_animation_duration * get_duration_scale(animation_key),
		get_minimum_duration(animation_key)
	)
	var rise_duration := total_duration * 0.18
	var hold_duration := total_duration * 0.60
	var fade_duration := total_duration - rise_duration - hold_duration

	var progress_tween := owner_node.create_tween()
	progress_tween.set_trans(Tween.TRANS_SINE)
	progress_tween.set_ease(Tween.EASE_IN_OUT)
	progress_tween.tween_property(visual, "progress", 1.0, total_duration)

	var presentation_tween := owner_node.create_tween()
	presentation_tween.set_trans(Tween.TRANS_QUART)
	presentation_tween.set_ease(Tween.EASE_OUT)
	presentation_tween.tween_property(visual, "modulate:a", 1.0, rise_duration)
	presentation_tween.tween_interval(hold_duration)
	presentation_tween.set_trans(Tween.TRANS_SINE)
	presentation_tween.set_ease(Tween.EASE_IN)
	presentation_tween.tween_property(visual, "modulate:a", 0.0, fade_duration)
	await presentation_tween.finished
	if is_instance_valid(visual):
		visual.queue_free()


func _create_visual(
	effect_root: Control,
	canvas_rect: Rect2,
	global_source: Vector2,
	global_target: Vector2,
	animation_key: String
) -> MonkeySpellVisual:
	if effect_root == null or canvas_rect.size == Vector2.ZERO:
		return null
	var visual := MonkeySpellVisualScript.new() as MonkeySpellVisual
	visual.name = "Monkey_%s" % animation_key
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2490
	visual.modulate.a = 0.0
	# Normal alpha blending preserves copper, cinnabar, ink shadows, and cloud
	# translucency. Individual helpers draw their own controlled glow layers.
	var visual_material := CanvasItemMaterial.new()
	visual_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	visual.material = visual_material
	visual.configure(
		animation_key,
		global_source - canvas_rect.position,
		global_target - canvas_rect.position,
		get_strength(animation_key)
	)
	effect_root.add_child(visual)
	return visual


func _single_effect_rect(target_rect: Rect2, animation_key: String) -> Rect2:
	var scale_multiplier := get_size_scale(animation_key)
	var effect_size := target_rect.size * scale_multiplier
	return Rect2(target_rect.get_center() - effect_size * 0.5, effect_size)


func _merged_effect_rect(first_rect: Rect2, second_rect: Rect2, margin_scale: float) -> Rect2:
	var left := minf(first_rect.position.x, second_rect.position.x)
	var top := minf(first_rect.position.y, second_rect.position.y)
	var right := maxf(first_rect.end.x, second_rect.end.x)
	var bottom := maxf(first_rect.end.y, second_rect.end.y)
	var margin := maxf(
		maxf(first_rect.size.x, second_rect.size.x) * margin_scale,
		18.0
	)
	return Rect2(
		Vector2(left - margin, top - margin),
		Vector2(right - left + margin * 2.0, bottom - top + margin * 2.0)
	)


func _root_effect_rect(effect_root: Control, fallback: Rect2) -> Rect2:
	if effect_root == null:
		return fallback
	var root_rect := effect_root.get_global_rect()
	if root_rect.size.x <= 1.0 or root_rect.size.y <= 1.0:
		return fallback
	return root_rect


func get_size_scale(animation_key: String) -> float:
	match animation_key:
		"heavenly_form":
			return 2.65
		"body_beyond_body", "dragon_palace_treasure":
			return 2.05
		"gather_scatter_qi", "somersault_cloud":
			return 1.82
		"bronze_head_iron_arms", "bronze_head_iron_arms_reflect":
			return 1.68
		_:
			return 1.58


func get_margin_scale(animation_key: String) -> float:
	if animation_key in ["body_beyond_body", "heavenly_form"]:
		return 0.82
	if animation_key in ["somersault_cloud", "drive_spirit", "bronze_head_iron_arms_reflect"]:
		return 0.60
	return 0.44


func get_duration_scale(animation_key: String) -> float:
	match animation_key:
		"heavenly_form":
			return 3.35
		"fiery_eyes_golden_gaze", "dragon_palace_treasure":
			return 2.65
		"body_beyond_body", "gather_scatter_qi":
			return 2.35
		"drive_spirit_battlefield":
			return 2.55
		_:
			return 1.95


func get_minimum_duration(animation_key: String) -> float:
	if animation_key == "heavenly_form":
		return 1.10
	if animation_key in ["fiery_eyes_golden_gaze", "dragon_palace_treasure"]:
		return 0.86
	return 0.62


func get_strength(animation_key: String) -> float:
	if animation_key == "heavenly_form":
		return 1.18
	if animation_key in ["drive_spirit_battlefield", "fiery_eyes_golden_gaze"]:
		return 1.08
	return 1.0
