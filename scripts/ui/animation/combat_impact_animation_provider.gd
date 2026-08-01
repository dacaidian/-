extends RefCounted

const CombatAreaAttackVisualScript := preload(
	"res://scripts/ui/animation/combat_area_attack_visual.gd"
)

const VALID_KEYS: Array[String] = [
	"frontal_attack_impact",
	"fixed_splash_impact",
	"tokyo_saint_sword_splash",
]

var attack_animation_duration := 0.26


func setup(duration: float) -> void:
	attack_animation_duration = maxf(duration, 0.01)


func spawn_secondary_attack_visual(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	primary_rect: Rect2,
	secondary_rects: Array[Rect2],
	animation_key: String
) -> void:
	if (
		owner_node == null
		or effect_root == null
		or secondary_rects.is_empty()
		or animation_key not in VALID_KEYS
	):
		return

	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var source_center := inverse_transform * source_rect.get_center()
	var primary_center := inverse_transform * primary_rect.get_center()
	var secondary_centers := PackedVector2Array()
	for secondary_rect in secondary_rects:
		secondary_centers.append(inverse_transform * secondary_rect.get_center())

	var visual := CombatAreaAttackVisualScript.new()
	visual.name = "CombatAreaAttack_%s" % animation_key
	visual.position = Vector2.ZERO
	visual.size = effect_root.size if effect_root.size != Vector2.ZERO else effect_root.get_viewport_rect().size
	visual.z_index = 2480
	effect_root.add_child(visual)
	visual.configure(source_center, primary_center, secondary_centers, animation_key)

	var duration_scale := 2.05 if animation_key == "tokyo_saint_sword_splash" else 1.72
	var tween := visual.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		visual,
		"progress",
		1.0,
		maxf(attack_animation_duration * duration_scale, 0.38)
	)
	tween.finished.connect(_release_visual.bind(visual), CONNECT_ONE_SHOT)


func _release_visual(visual: Control) -> void:
	if visual != null and is_instance_valid(visual):
		visual.queue_free()
