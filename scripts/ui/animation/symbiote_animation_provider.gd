extends RefCounted
class_name SymbioteAnimationProvider

# Stable presentation facade for Symbiote actions. Rules publish semantic
# animation keys; this provider only translates card rectangles into a canvas.

const SeveranceVisualScript := preload(
	"res://scripts/ui/animation/symbiote_severance_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"symbiote_self_severance",
	"symbiote_artificial_severance",
	"symbiote_attachment",
]
const RECT_KEYS: Array[String] = [
	"symbiote_self_severance",
]
const SOURCE_RECT_KEYS: Array[String] = [
	"symbiote_artificial_severance",
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
	var visual := SeveranceVisualScript.new()
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

	var duration_scale := 3.05 if animation_key == "symbiote_attachment" else (
		2.75 if animation_key == "symbiote_artificial_severance" else 2.35
	)
	var duration := maxf(spell_animation_duration * duration_scale, 0.72)
	var tween := owner_node.create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "progress", 1.0, duration)
	await tween.finished
	if is_instance_valid(visual):
		visual.queue_free()


func _get_canvas_size(effect_root: Control) -> Vector2:
	return effect_root.size if effect_root.size != Vector2.ZERO else effect_root.get_viewport_rect().size
