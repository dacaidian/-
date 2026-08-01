extends RefCounted
class_name TokyoGhoulAnimationProvider

# Stable animation-key facade for the faction. Rendering lives in focused
# canvases so rules only publish semantic keys and never construct VFX nodes.

const KaguneReleaseVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_kagune_visual.gd"
)
const FeatherNeedleVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_feather_visual.gd"
)
const CombatVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_combat_visual.gd"
)
const RitualVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_ritual_visual.gd"
)
const EventVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_event_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"centipede_form",
	"dragon_form",
	"saint_sword_form",
	"feather_needle",
	"rc_forced_feeding",
	"bikaku_volley",
	"free_meal",
	"kakuja_form",
	"restore_form",
	"special_blend",
	"sugar_cube_coffee",
	"kagune_lifesteal",
	"koukaku_reflect",
]
const RECT_KEYS: Array[String] = [
	"centipede_form",
	"dragon_form",
	"saint_sword_form",
	"bikaku_volley",
]
const ATTACK_KEYS: Array[String] = [
	"tokyo_bikaku_attack",
	"tokyo_rinkaku_attack",
	"tokyo_koukaku_attack",
	"tokyo_ukaku_attack",
	"tokyo_chimera_attack",
	"tokyo_centipede_attack",
	"tokyo_dragon_attack",
	"tokyo_saint_sword_attack",
	"tokyo_owl_attack",
	"tokyo_furuta_attack",
]
const SOURCE_RECT_KEYS: Array[String] = [
	"centipede_form",
	"dragon_form",
	"saint_sword_form",
	"tokyo_bikaku_attack",
	"tokyo_rinkaku_attack",
	"tokyo_koukaku_attack",
	"tokyo_ukaku_attack",
	"tokyo_chimera_attack",
	"tokyo_centipede_attack",
	"tokyo_dragon_attack",
	"tokyo_saint_sword_attack",
	"tokyo_owl_attack",
	"tokyo_furuta_attack",
	"kagune_lifesteal",
	"koukaku_reflect",
]
const BOARD_KEYS: Array[String] = [
	"kagune_release",
	"rc_rise_medium",
	"rc_rise_high",
	"rc_fall_medium",
	"rc_fall_low",
	"s_rank_intelligence",
	"sss_rank_intelligence",
]

const ATTACK_PROFILES := {
	"tokyo_bikaku_attack": "bikaku",
	"tokyo_rinkaku_attack": "rinkaku",
	"tokyo_koukaku_attack": "koukaku",
	"tokyo_ukaku_attack": "ukaku",
	"tokyo_chimera_attack": "chimera",
	"tokyo_centipede_attack": "centipede",
	"tokyo_dragon_attack": "dragon",
	"tokyo_saint_sword_attack": "saint_sword",
	"tokyo_owl_attack": "owl",
	"tokyo_furuta_attack": "furuta",
	"kagune_lifesteal": "lifesteal",
	"koukaku_reflect": "reflect",
}

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)


func is_replacement_attack_key(animation_key: String) -> bool:
	return ATTACK_KEYS.has(animation_key)


func play_at_rect(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	await play_ritual_visual(owner, effect_root, target_rect, animation_key)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return
	if animation_key == "feather_needle":
		if caster_card != null:
			await play_feather_needle(
				owner,
				effect_root,
				caster_card.get_global_rect(),
				target_card.get_global_rect()
			)
		return
	if animation_key in ["kagune_lifesteal", "koukaku_reflect"]:
		if caster_card != null:
			await play_from_rect(
				owner,
				effect_root,
				caster_card.get_global_rect(),
				target_card,
				animation_key
			)
		return

	await play_ritual_visual(
		owner,
		effect_root,
		target_card.get_global_rect(),
		animation_key,
		caster_card.get_global_rect() if caster_card != null else Rect2()
	)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return
	var profile := str(ATTACK_PROFILES.get(animation_key, ""))
	if profile == "":
		if animation_key in RECT_KEYS:
			await play_ritual_visual(
				owner,
				effect_root,
				target_card.get_global_rect(),
				animation_key,
				source_rect
			)
		return
	await play_attack_from_rect(
		owner,
		effect_root,
		source_rect,
		target_card,
		animation_key,
		false
	)


func play_attack_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String,
	is_melee_impact: bool
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return
	var profile := str(ATTACK_PROFILES.get(animation_key, ""))
	if profile == "":
		return

	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var source_point := inverse_transform * source_rect.get_center()
	var target_point := inverse_transform * target_card.get_global_rect().get_center()
	var visual := CombatVisualScript.new()
	visual.name = "TokyoGhoulCombat_%s" % profile
	visual.position = Vector2.ZERO
	visual.size = _get_canvas_size(effect_root)
	visual.z_index = 2470
	effect_root.add_child(visual)
	visual.configure(source_point, target_point, profile, is_melee_impact)

	var high_impact_profiles := ["dragon", "saint_sword", "owl", "furuta"]
	var duration_scale := 1.48 if is_melee_impact else (1.85 if profile in high_impact_profiles else 1.48)
	await _animate_and_release(owner, visual, maxf(spell_animation_duration * duration_scale, 0.40))


func play_board(owner: Node, effect_root: Control, animation_key: String) -> void:
	if owner == null or effect_root == null:
		return
	if animation_key == "kagune_release":
		var release_visual := KaguneReleaseVisualScript.new()
		release_visual.name = "TokyoGhoulKaguneRelease"
		release_visual.position = Vector2.ZERO
		release_visual.size = _get_canvas_size(effect_root)
		release_visual.z_index = 2445
		effect_root.add_child(release_visual)
		release_visual.configure()
		await _animate_and_release(
			owner,
			release_visual,
			maxf(spell_animation_duration * 3.2, 0.88)
		)
		return

	var event_visual := EventVisualScript.new()
	event_visual.name = "TokyoGhoulEvent_%s" % animation_key
	event_visual.position = Vector2.ZERO
	event_visual.size = _get_canvas_size(effect_root)
	event_visual.z_index = 2440
	effect_root.add_child(event_visual)
	event_visual.configure(animation_key)
	await _animate_and_release(
		owner,
		event_visual,
		maxf(spell_animation_duration * 2.65, 0.72)
	)


func play_feather_needle(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_rect: Rect2
) -> void:
	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var source_point := inverse_transform * source_rect.get_center()
	var target_point := inverse_transform * target_rect.get_center()
	if source_point.distance_to(target_point) <= 0.01:
		return

	var visual := FeatherNeedleVisualScript.new()
	visual.name = "TokyoGhoulUkakuNeedles"
	visual.position = Vector2.ZERO
	visual.size = _get_canvas_size(effect_root)
	visual.z_index = 2462
	effect_root.add_child(visual)
	visual.configure(source_point, target_point)
	await _animate_and_release(
		owner,
		visual,
		maxf(spell_animation_duration * 1.55, 0.42)
	)


func play_ritual_visual(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String,
	source_rect := Rect2()
) -> void:
	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var local_target := inverse_transform * target_rect.get_center()
	var local_source := local_target
	if source_rect.size != Vector2.ZERO:
		local_source = inverse_transform * source_rect.get_center()

	var visual := RitualVisualScript.new()
	visual.name = "TokyoGhoulRitual_%s" % animation_key
	visual.position = Vector2.ZERO
	visual.size = _get_canvas_size(effect_root)
	visual.z_index = 2455
	effect_root.add_child(visual)
	visual.configure(animation_key, local_target, target_rect.size, local_source)

	var long_profiles := [
		"centipede_form",
		"dragon_form",
		"saint_sword_form",
		"kakuja_form",
		"restore_form",
	]
	var duration_scale := 2.15 if animation_key in long_profiles else 1.65
	await _animate_and_release(
		owner,
		visual,
		maxf(spell_animation_duration * duration_scale, 0.46)
	)


func _animate_and_release(owner: Node, visual: Control, duration: float) -> void:
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "progress", 1.0, duration)
	await tween.finished
	visual.queue_free()


func _get_canvas_size(effect_root: Control) -> Vector2:
	return effect_root.size if effect_root.size != Vector2.ZERO else effect_root.get_viewport_rect().size
