extends RefCounted
class_name BeastmenAnimationProvider

const BeastmenCombatVisualScript := preload(
	"res://scripts/ui/animation/beastmen_combat_visual.gd"
)
const BeastmenRitualVisualScript := preload(
	"res://scripts/ui/animation/beastmen_ritual_visual.gd"
)
const BeastmenPathVisualScript := preload(
	"res://scripts/ui/animation/beastmen_path_visual.gd"
)

const COMBAT_KEYS: Array[String] = [
	"beastmen_evolution",
	"beastmen_slaughter",
	"wanmo_charge",
	"savage_roar_buff",
]
const RITUAL_KEYS: Array[String] = [
	"savage_roar",
	"wild_call",
	"beast_path",
	"wanmo_ritual",
]
const TARGETED_KEYS: Array[String] = COMBAT_KEYS + RITUAL_KEYS
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const BOARD_KEYS: Array[String] = ["chaos_corruption_burst"]
const PATH_KEYS: Array[String] = ["beast_path"]

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
	router.register_path(PATH_KEYS, play_path)


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
	if COMBAT_KEYS.has(animation_key):
		await _play_combat_visual(owner_node, effect_root, source_rect, target_rect, animation_key)
	else:
		await _play_ritual_visual(owner_node, effect_root, source_rect, animation_key)


func play_from_rect(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if target_card == null:
		return
	if COMBAT_KEYS.has(animation_key):
		await _play_combat_visual(
			owner_node,
			effect_root,
			source_rect,
			target_card.get_global_rect(),
			animation_key
		)
	else:
		await _play_ritual_visual(owner_node, effect_root, source_rect, animation_key)


func play_at_rect(
	owner_node: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	if COMBAT_KEYS.has(animation_key):
		await _play_combat_visual(owner_node, effect_root, target_rect, target_rect, animation_key)
	else:
		await _play_ritual_visual(owner_node, effect_root, target_rect, animation_key)


func play_board(
	owner_node: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	if animation_key != "chaos_corruption_burst" or owner_node == null or effect_root == null:
		return
	var root_rect := _root_effect_rect(effect_root)
	var board_global_rect := _get_board_rect(owner_node, root_rect)
	var visual := BeastmenRitualVisualScript.new()
	visual.name = "Beastmen_ChaosCorruptionBurst"
	visual.size = root_rect.size
	visual.global_position = root_rect.position
	visual.z_index = 2486
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		board_global_rect.get_center() - root_rect.position,
		board_global_rect.get_center() - root_rect.position,
		Rect2(board_global_rect.position - root_rect.position, board_global_rect.size),
		Vector2(120.0, 168.0)
	)
	effect_root.add_child(visual)
	await _run_visual(owner_node, visual, 3.15, 1.02, 0.16, 0.19)


func play_path(
	owner_node: Node,
	effect_root: Control,
	target_global_rects: Array[Rect2],
	animation_key: String
) -> void:
	if (
		animation_key != "beast_path"
		or owner_node == null
		or effect_root == null
		or target_global_rects.is_empty()
	):
		return
	var canvas_rect := _bounds_for_rects(target_global_rects, 0.32)
	var local_rects: Array[Rect2] = []
	for target_rect in target_global_rects:
		local_rects.append(Rect2(target_rect.position - canvas_rect.position, target_rect.size))
	var visual := BeastmenPathVisualScript.new()
	visual.name = "Beastmen_BeastPath"
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2478
	visual.modulate.a = 0.0
	visual.configure(local_rects)
	effect_root.add_child(visual)
	await _run_visual(owner_node, visual, 3.35, 1.08, 0.12, 0.18)


func _play_combat_visual(
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
	var canvas_rect := _merged_effect_rect(source_rect, target_rect, _combat_margin(animation_key))
	var visual := BeastmenCombatVisualScript.new()
	visual.name = "Beastmen_%s" % animation_key
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2492
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		source_rect.get_center() - canvas_rect.position,
		target_rect.get_center() - canvas_rect.position,
		target_rect.size
	)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_combat_duration_scale(animation_key),
		_combat_minimum_duration(animation_key),
		0.12,
		0.20
	)


func _play_ritual_visual(
	owner_node: Node,
	effect_root: Control,
	source_rect: Rect2,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or source_rect.size == Vector2.ZERO:
		return
	var root_rect := _root_effect_rect(effect_root)
	var board_global_rect := _get_board_rect(owner_node, root_rect)
	var destination := source_rect.get_center()
	if animation_key in ["wild_call", "wanmo_ritual"]:
		destination = _get_hand_destination(owner_node, root_rect)
	var visual := BeastmenRitualVisualScript.new()
	visual.name = "Beastmen_%s" % animation_key
	visual.size = root_rect.size
	visual.global_position = root_rect.position
	visual.z_index = 2488
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		source_rect.get_center() - root_rect.position,
		destination - root_rect.position,
		Rect2(board_global_rect.position - root_rect.position, board_global_rect.size),
		source_rect.size
	)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_ritual_duration_scale(animation_key),
		_ritual_minimum_duration(animation_key),
		0.14,
		0.18
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


func _get_board_rect(owner_node: Node, fallback_rect: Rect2) -> Rect2:
	if owner_node != null:
		var board_node := owner_node.get_node_or_null("../CardBoard") as Control
		if board_node != null and board_node.is_visible_in_tree():
			return board_node.get_global_rect()
	return fallback_rect.grow(-minf(fallback_rect.size.x, fallback_rect.size.y) * 0.08)


func _get_hand_destination(owner_node: Node, fallback_rect: Rect2) -> Vector2:
	if owner_node != null:
		var drawer_controller: Variant = owner_node.get("hand_drawer_controller")
		if drawer_controller != null:
			var drawer_panel: Variant = drawer_controller.get("panel")
			if drawer_panel is Control:
				var panel_control := drawer_panel as Control
				if panel_control.is_visible_in_tree():
					return panel_control.get_global_rect().get_center()
	return Vector2(fallback_rect.position.x + fallback_rect.size.x * 0.26, fallback_rect.end.y - 68.0)


func _root_effect_rect(effect_root: Control) -> Rect2:
	var root_rect := effect_root.get_global_rect()
	if root_rect.size.x > 1.0 and root_rect.size.y > 1.0:
		return root_rect
	return Rect2(effect_root.global_position, Vector2(1280.0, 720.0))


func _merged_effect_rect(first_rect: Rect2, second_rect: Rect2, margin_scale: float) -> Rect2:
	var bounds := first_rect.merge(second_rect)
	var margin := maxf(maxf(first_rect.size.x, second_rect.size.x) * margin_scale, 28.0)
	return bounds.grow(margin)


func _bounds_for_rects(rects: Array[Rect2], margin_scale: float) -> Rect2:
	var bounds := rects[0]
	for rect_index in range(1, rects.size()):
		bounds = bounds.merge(rects[rect_index])
	var margin := maxf(maxf(bounds.size.x, bounds.size.y) * margin_scale, 28.0)
	return bounds.grow(margin)


func _combat_margin(animation_key: String) -> float:
	if animation_key == "beastmen_evolution":
		return 0.86
	if animation_key == "beastmen_slaughter":
		return 0.74
	return 0.58


func _combat_duration_scale(animation_key: String) -> float:
	match animation_key:
		"beastmen_evolution":
			return 2.80
		"beastmen_slaughter":
			return 2.55
		"wanmo_charge":
			return 1.95
		_:
			return 1.55


func _combat_minimum_duration(animation_key: String) -> float:
	match animation_key:
		"beastmen_evolution":
			return 0.92
		"beastmen_slaughter":
			return 0.82
		"wanmo_charge":
			return 0.62
		_:
			return 0.48


func _ritual_duration_scale(animation_key: String) -> float:
	match animation_key:
		"wanmo_ritual":
			return 4.40
		"wild_call":
			return 3.10
		"savage_roar":
			return 2.65
		_:
			return 2.10


func _ritual_minimum_duration(animation_key: String) -> float:
	match animation_key:
		"wanmo_ritual":
			return 1.42
		"wild_call":
			return 1.00
		"savage_roar":
			return 0.82
		_:
			return 0.68
