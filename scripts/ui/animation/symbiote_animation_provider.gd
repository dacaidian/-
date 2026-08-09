extends RefCounted
class_name SymbioteAnimationProvider

# Stable presentation facade for Symbiote actions. Rules publish semantic
# animation keys; this provider only translates card rectangles into a canvas.

const SeveranceVisualScript := preload(
	"res://scripts/ui/animation/symbiote_severance_visual.gd"
)
const PowerVisualScript := preload(
	"res://scripts/ui/animation/symbiote_power_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"symbiote_self_severance",
	"symbiote_artificial_severance",
	"symbiote_attachment",
	"symbiote_bite_ready",
	"symbiote_bite_strike",
	"symbiote_terrifying_scream",
]
const RECT_KEYS: Array[String] = [
	"symbiote_self_severance",
	"symbiote_bite_ready",
	"symbiote_bite_restore",
	"symbiote_fear_apply",
	"symbiote_fear_flee",
	"symbiote_codex",
	"symbiote_knull_liberation",
]
const SOURCE_RECT_KEYS: Array[String] = [
	"symbiote_artificial_severance",
	"symbiote_bite_ready",
	"symbiote_terrifying_scream",
]
const MULTI_RECT_KEYS: Array[String] = [
	"symbiote_fear_apply",
]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_multi_rect(MULTI_RECT_KEYS, play_multi_rect)


func play_targeted(
	owner_node: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_card == null:
		return
	var target_rect := target_card.get_global_rect()
	var source_rect := caster_card.get_global_rect() if caster_card != null else target_rect
	await _play(owner_node, effect_root, source_rect, target_rect, animation_key)


func play_at_rect(
	owner_node: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	await _play(owner_node, effect_root, target_rect, target_rect, animation_key)


func play_from_rect(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_card == null:
		return
	await _play(
		owner_node,
		effect_root,
		source_rect,
		target_card.get_global_rect(),
		animation_key
	)


func play_multi_rect(
	owner_node: Node,
	effect_root: Control,
	target_rects: Array[Rect2],
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_rects.is_empty():
		return
	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var local_centers: Array[Vector2] = []
	for target_rect in target_rects:
		if target_rect.size != Vector2.ZERO:
			local_centers.append(inverse_transform * target_rect.get_center())
	if local_centers.is_empty():
		return

	var visual := PowerVisualScript.new()
	visual.name = "SymbiotePower_%s" % animation_key
	visual.position = Vector2.ZERO
	visual.size = _get_canvas_size(effect_root)
	visual.z_index = 2470
	effect_root.add_child(visual)
	visual.configure(
		animation_key,
		local_centers[0],
		local_centers[0],
		target_rects[0].size,
		target_rects[0].size,
		local_centers
	)
	await _tween_and_free(owner_node, visual, animation_key)


func _play(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2,
	animation_key: String
) -> void:
	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var local_source := inverse_transform * source_rect.get_center()
	var local_target := inverse_transform * target_rect.get_center()
	var visual = (
		SeveranceVisualScript.new()
		if animation_key in [
			"symbiote_self_severance",
			"symbiote_artificial_severance",
			"symbiote_attachment",
		]
		else PowerVisualScript.new()
	)
	visual.name = "SymbioteSeverance_%s" % animation_key
	visual.position = Vector2.ZERO
	visual.size = _get_canvas_size(effect_root)
	visual.z_index = 2470
	effect_root.add_child(visual)
	visual.configure(
		animation_key,
		local_source,
		local_target,
		source_rect.size,
		target_rect.size
	)
	await _tween_and_free(owner_node, visual, animation_key)


func _tween_and_free(owner_node: Node, visual: Control, animation_key: String) -> void:
	if owner_node == null or visual == null:
		return

	var duration_scale := get_duration_scale(animation_key)
	var duration := maxf(spell_animation_duration * duration_scale, 0.72)
	var tween := owner_node.create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "progress", 1.0, duration)
	await tween.finished
	if is_instance_valid(visual):
		visual.queue_free()


func get_duration_scale(animation_key: String) -> float:
	match animation_key:
		"symbiote_attachment":
			return 3.05
		"symbiote_artificial_severance":
			return 2.75
		"symbiote_terrifying_scream", "symbiote_knull_liberation":
			return 3.0
		"symbiote_codex":
			return 2.75
		"symbiote_bite_strike", "symbiote_fear_apply":
			return 2.15
		_:
			return 2.35


func _get_canvas_size(effect_root: Control) -> Vector2:
	return effect_root.size if effect_root.size != Vector2.ZERO else effect_root.get_viewport_rect().size
