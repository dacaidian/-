extends RefCounted
class_name ShadowmoonAnimationProvider

const ShadowmoonTargetVisualScript := preload(
	"res://scripts/ui/animation/shadowmoon_target_visual.gd"
)
const ShadowmoonRitualVisualScript := preload(
	"res://scripts/ui/animation/shadowmoon_ritual_visual.gd"
)

const TARGET_VISUAL_KEYS: Array[String] = [
	"fel_sacrifice",
	"fel_sacrifice_heavy",
	"fel_infusion",
	"fel_infusion_transfer",
	"fel_infusion_settle",
	"fel_overload",
	"fel_overload_transfer",
	"fel_overload_settle",
	"fel_overload_detonate",
	"fel_burst",
	"fel_burst_impact",
	"mana_burn",
	"fel_bite",
	"life_drain",
	"life_drain_receive",
	"curse",
	"curse_cast",
	"curse_mark",
	"curse_impact",
	"fel_madness",
	"fel_madness_chaos_orc",
	"fel_madness_hellhound",
	"fel_madness_succubus",
	"fel_madness_wolf_rider",
	"fel_madness_doomguard",
	"fel_madness_warlock",
	"kiljaeden_whisper",
	"kiljaeden_whisper_mark",
	"immolation_mark",
	"immolation_tick",
	"fire",
]
const RITUAL_KEYS: Array[String] = [
	"demon_summon",
	"dark_portal",
	"immolation",
	"immolation_cast",
]
const TARGETED_KEYS: Array[String] = TARGET_VISUAL_KEYS + RITUAL_KEYS
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const BOARD_KEYS: Array[String] = ["fel_madness_broadcast"]
const MULTI_RECT_KEYS: Array[String] = [
	"fel_madness",
	"fel_madness_chaos_orc",
	"fel_madness_hellhound",
	"fel_madness_succubus",
	"fel_madness_wolf_rider",
	"fel_madness_doomguard",
	"fel_madness_warlock",
	"kiljaeden_whisper",
	"kiljaeden_whisper_mark",
	"immolation_mark",
	"fel_burst_impact",
]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = maxf(duration, 0.04)


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)
	router.register_multi_rect(MULTI_RECT_KEYS, play_multi_rect)


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
	if RITUAL_KEYS.has(animation_key):
		var ritual_source := _resolve_ritual_source_rect(owner_node, source_rect, animation_key)
		await _play_ritual_visual(owner_node, effect_root, ritual_source, animation_key)
		return
	if animation_key == "life_drain":
		source_rect = _resolve_owner_card_rect(owner_node, "guldan", source_rect)
	await _play_target_visual(owner_node, effect_root, source_rect, target_rect, animation_key)


func play_from_rect(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	if RITUAL_KEYS.has(animation_key):
		var ritual_source := _resolve_ritual_source_rect(owner_node, source_rect, animation_key)
		await _play_ritual_visual(owner_node, effect_root, ritual_source, animation_key)
		return
	var semantic_source := source_rect
	if animation_key == "life_drain":
		semantic_source = _resolve_owner_card_rect(owner_node, "guldan", source_rect)
	await _play_target_visual(
		owner_node,
		effect_root,
		semantic_source,
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
	if RITUAL_KEYS.has(animation_key):
		var ritual_source := _resolve_ritual_source_rect(owner_node, target_rect, animation_key)
		await _play_ritual_visual(owner_node, effect_root, ritual_source, animation_key)
		return
	await _play_target_visual(owner_node, effect_root, target_rect, target_rect, animation_key)


func play_board(owner_node: Node, effect_root: Control, animation_key: String) -> void:
	if animation_key != "fel_madness_broadcast" or owner_node == null or effect_root == null:
		return
	var source_rect := _resolve_owner_card_rect(owner_node, "guldan", _get_board_rect(owner_node, effect_root))
	await _play_ritual_visual(owner_node, effect_root, source_rect, animation_key)


func play_multi_rect(
	owner_node: Node,
	effect_root: Control,
	target_global_rects: Array[Rect2],
	animation_key: String
) -> void:
	if (
		owner_node == null
		or effect_root == null
		or target_global_rects.is_empty()
		or not MULTI_RECT_KEYS.has(animation_key)
	):
		return
	var source_rect := _resolve_owner_card_rect(
		owner_node,
		"guldan",
		_bounds_for_rects(target_global_rects, 0.0)
	)
	await _play_ritual_visual(
		owner_node,
		effect_root,
		source_rect,
		animation_key,
		target_global_rects
	)


func _play_target_visual(
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
		_target_margin(animation_key)
	)
	var visual := ShadowmoonTargetVisualScript.new()
	visual.name = "Shadowmoon_%s" % animation_key
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2494
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		source_rect.get_center() - canvas_rect.position,
		target_rect.get_center() - canvas_rect.position,
		source_rect.size,
		target_rect.size
	)
	_apply_mix_material(visual)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_target_duration_scale(animation_key),
		_target_minimum_duration(animation_key),
		0.10,
		0.15
	)


func _play_ritual_visual(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	animation_key: String,
	target_global_rects: Array[Rect2] = []
) -> void:
	if owner_node == null or effect_root == null or source_rect.size == Vector2.ZERO:
		return
	var root_rect := _root_effect_rect(effect_root)
	var board_global_rect := _get_board_rect(owner_node, effect_root)
	var local_targets: Array[Rect2] = []
	for target_rect in target_global_rects:
		local_targets.append(Rect2(target_rect.position - root_rect.position, target_rect.size))
	var visual := ShadowmoonRitualVisualScript.new()
	visual.name = "Shadowmoon_%s" % animation_key
	visual.size = root_rect.size
	visual.global_position = root_rect.position
	visual.z_index = 2489
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		source_rect.get_center() - root_rect.position,
		_get_hand_destination(owner_node, root_rect) - root_rect.position,
		Rect2(board_global_rect.position - root_rect.position, board_global_rect.size),
		source_rect.size,
		local_targets
	)
	_apply_mix_material(visual)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_ritual_duration_scale(animation_key),
		_ritual_minimum_duration(animation_key),
		0.10,
		0.16
	)


func _run_visual(
	owner_node: Node,
	visual: Control,
	duration_scale: float,
	minimum_duration: float,
	rise_ratio: float,
	fade_ratio: float
) -> void:
	if owner_node == null or visual == null:
		return
	var total_duration := maxf(spell_animation_duration * duration_scale, minimum_duration)
	var rise_duration := total_duration * rise_ratio
	var fade_duration := total_duration * fade_ratio
	var hold_duration := maxf(total_duration - rise_duration - fade_duration, 0.0)

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


func _resolve_ritual_source_rect(owner_node: Node, fallback_rect: Rect2, animation_key: String) -> Rect2:
	if animation_key == "demon_summon":
		return _resolve_owner_card_rect(owner_node, "guldan", fallback_rect)
	return fallback_rect


func _resolve_owner_card_rect(owner_node: Node, card_id: String, fallback_rect: Rect2) -> Rect2:
	if owner_node == null or not owner_node.has_method("get_all_board_states"):
		return fallback_rect
	var current_player: PlayerState = null
	if owner_node.has_method("get_current_player"):
		current_player = owner_node.get_current_player() as PlayerState
	for state_value in owner_node.get_all_board_states():
		var state := state_value as CardState
		if state == null or not state.is_face_up or not state.represents_card_id(card_id):
			continue
		if current_player != null and state.owner_id != current_player.id:
			continue
		if not owner_node.has_method("get_card_for_state"):
			continue
		var card := owner_node.get_card_for_state(state) as Card
		if card != null:
			return card.get_global_rect()
	return fallback_rect


func _get_board_rect(owner_node: Node, effect_root: Control) -> Rect2:
	if owner_node != null:
		var board_node := owner_node.get_node_or_null("../CardBoard") as Control
		if board_node != null and board_node.is_visible_in_tree():
			return board_node.get_global_rect()
	var root_rect := _root_effect_rect(effect_root)
	return root_rect.grow(-minf(root_rect.size.x, root_rect.size.y) * 0.08)


func _get_hand_destination(owner_node: Node, fallback_rect: Rect2) -> Vector2:
	if owner_node != null:
		var drawer_controller: Variant = owner_node.get("hand_drawer_controller")
		if drawer_controller != null:
			var drawer_panel: Variant = drawer_controller.get("panel")
			if drawer_panel is Control:
				var panel_control := drawer_panel as Control
				if panel_control.is_visible_in_tree():
					return panel_control.get_global_rect().get_center()
	return Vector2(fallback_rect.position.x + fallback_rect.size.x * 0.25, fallback_rect.end.y - 68.0)


func _root_effect_rect(effect_root: Control) -> Rect2:
	var root_rect := effect_root.get_global_rect()
	if root_rect.size.x > 1.0 and root_rect.size.y > 1.0:
		return root_rect
	return Rect2(effect_root.global_position, Vector2(1280.0, 720.0))


func _merged_effect_rect(first_rect: Rect2, second_rect: Rect2, margin_scale: float) -> Rect2:
	var bounds := first_rect.merge(second_rect)
	var margin := maxf(maxf(first_rect.size.x, second_rect.size.x) * margin_scale, 26.0)
	return bounds.grow(margin)


func _bounds_for_rects(rects: Array[Rect2], margin_scale: float) -> Rect2:
	var bounds := rects[0]
	for rect_index in range(1, rects.size()):
		bounds = bounds.merge(rects[rect_index])
	var margin := maxf(maxf(bounds.size.x, bounds.size.y) * margin_scale, 0.0)
	return bounds.grow(margin)


func _apply_mix_material(visual: CanvasItem) -> void:
	var visual_material := CanvasItemMaterial.new()
	visual_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	visual.material = visual_material


func _target_margin(animation_key: String) -> float:
	if animation_key in ["fel_infusion_transfer", "fel_overload_transfer", "mana_burn", "fel_bite", "life_drain", "curse_cast", "curse"]:
		return 0.46
	if animation_key in ["fel_overload_detonate", "fel_burst", "immolation_tick"]:
		return 0.72
	return 0.38


func _target_duration_scale(animation_key: String) -> float:
	if animation_key == "fel_madness" or animation_key.begins_with("fel_madness_"):
		return 0.72
	match animation_key:
		"life_drain":
			return 2.65
		"fel_overload_transfer", "fel_overload_detonate", "fel_burst":
			return 2.35
		"mana_burn", "fel_bite", "curse_cast", "curse":
			return 1.95
		"fel_sacrifice_heavy":
			return 1.75
		_:
			return 1.35


func _target_minimum_duration(animation_key: String) -> float:
	if animation_key == "fel_madness" or animation_key.begins_with("fel_madness_"):
		return 0.24
	match animation_key:
		"life_drain":
			return 0.82
		"fel_overload_transfer", "fel_overload_detonate", "fel_burst":
			return 0.74
		"mana_burn", "fel_bite", "curse_cast", "curse":
			return 0.60
		_:
			return 0.38


func _ritual_duration_scale(animation_key: String) -> float:
	if (
		animation_key != "fel_madness_broadcast"
		and (animation_key == "fel_madness" or animation_key.begins_with("fel_madness_"))
	):
		return 0.72
	match animation_key:
		"dark_portal":
			return 3.65
		"demon_summon":
			return 2.85
		"immolation", "immolation_cast":
			return 2.55
		"fel_madness_broadcast":
			return 1.65
		_:
			return 1.55


func _ritual_minimum_duration(animation_key: String) -> float:
	if (
		animation_key != "fel_madness_broadcast"
		and (animation_key == "fel_madness" or animation_key.begins_with("fel_madness_"))
	):
		return 0.24
	match animation_key:
		"dark_portal":
			return 1.16
		"demon_summon":
			return 0.90
		"immolation", "immolation_cast":
			return 0.82
		"fel_madness_broadcast":
			return 0.52
		_:
			return 0.46
