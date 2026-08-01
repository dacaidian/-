extends RefCounted
class_name FoxSpiritAnimationProvider

const FoxSpiritTargetVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_target_visual.gd"
)
const FoxSpiritAreaVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_area_visual.gd"
)
const FoxSpiritRitualVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_ritual_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"sacrifice",
	"nine_tail_sacrifice",
	"fox_reborn",
	"soul_hook",
	"charm",
	"fox_mind_art",
	"nine_tail_tail_enter",
]
const RECT_KEYS: Array[String] = [
	"sacrifice",
	"nine_tail_sacrifice",
	"fox_reborn",
	"soul_hook",
	"charm",
	"fox_mind_art",
	"nine_tail_tail_enter",
	"ruin_country",
]
const SOURCE_RECT_KEYS: Array[String] = TARGETED_KEYS
const AREA_KEYS: Array[String] = ["foxfire"]
const BOARD_KEYS: Array[String] = ["nine_tail_army"]
const MULTI_RECT_KEYS: Array[String] = ["celestial_fox_evolve", "ruin_country_targets"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_area(AREA_KEYS, play_area)
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
	if animation_key == "nine_tail_sacrifice":
		var daji_rect := _get_daji_rect(owner_node)
		if daji_rect.size != Vector2.ZERO:
			target_rect = daji_rect
	await _play_target_visual(
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
	await _play_target_visual(
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
	if animation_key == "ruin_country":
		await _play_ritual_visual(
			owner_node,
			effect_root,
			animation_key,
			target_rect.get_center(),
			_get_board_center(owner_node, effect_root),
			[]
		)
		return
	await _play_target_visual(
		owner_node,
		effect_root,
		target_rect,
		target_rect,
		animation_key
	)


func play_area(
	owner_node: Node,
	effect_root: Control,
	caster_card: Card,
	center_card: Card,
	spell_data: Dictionary,
	animation_key: String
) -> void:
	if (
		animation_key != "foxfire"
		or owner_node == null
		or effect_root == null
		or caster_card == null
		or center_card == null
	):
		return
	var area_rows := maxi(int(spell_data.get("area_rows", 2)), 1)
	var area_cols := maxi(int(spell_data.get("area_cols", 2)), 1)
	var area_global_rect := _get_area_rect(center_card, area_rows, area_cols)
	var caster_rect := caster_card.get_global_rect()
	var canvas_rect := _merged_effect_rect(caster_rect, area_global_rect, 0.18)
	var visual := FoxSpiritAreaVisualScript.new() as FoxSpiritAreaVisual
	visual.name = "FoxSpirit_Foxfire"
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2490
	visual.modulate.a = 0.0
	visual.configure(
		caster_rect.get_center() - canvas_rect.position,
		Rect2(area_global_rect.position - canvas_rect.position, area_global_rect.size)
	)
	_apply_mix_material(visual)
	effect_root.add_child(visual)
	await _run_visual(owner_node, visual, 2.75, 0.90)


func play_board(
	owner_node: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null:
		return
	var root_rect := _root_effect_rect(effect_root)
	await _play_ritual_visual(
		owner_node,
		effect_root,
		animation_key,
		root_rect.get_center(),
		_get_hand_destination(owner_node, root_rect),
		[]
	)


func play_multi_rect(
	owner_node: Node,
	effect_root: Control,
	target_global_rects: Array[Rect2],
	animation_key: String
) -> void:
	if owner_node == null or effect_root == null or target_global_rects.is_empty():
		return
	var canvas_rect := _bounds_for_rects(target_global_rects, 0.46)
	var local_rects: Array[Rect2] = []
	for target_rect in target_global_rects:
		local_rects.append(Rect2(target_rect.position - canvas_rect.position, target_rect.size))
	await _play_ritual_visual(
		owner_node,
		effect_root,
		animation_key,
		canvas_rect.get_center(),
		canvas_rect.get_center(),
		local_rects,
		canvas_rect
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
	var visual_target_rect := target_rect
	var daji_rect := Rect2()
	if animation_key == "sacrifice":
		var tail_meter_rect := _get_tail_meter_rect(owner_node)
		if tail_meter_rect.size != Vector2.ZERO:
			visual_target_rect = tail_meter_rect
		daji_rect = _get_daji_rect(owner_node)
	var canvas_rect := _merged_effect_rect(source_rect, visual_target_rect, _target_margin(animation_key))
	if daji_rect.size != Vector2.ZERO:
		canvas_rect = _merged_effect_rect(canvas_rect, daji_rect, 0.12)
	var visual := FoxSpiritTargetVisualScript.new() as FoxSpiritTargetVisual
	visual.name = "FoxSpirit_%s" % animation_key
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2490
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		source_rect.get_center() - canvas_rect.position,
		visual_target_rect.get_center() - canvas_rect.position,
		source_rect.size,
		target_rect.size,
		1.0,
		daji_rect.get_center() - canvas_rect.position,
		daji_rect.size != Vector2.ZERO
	)
	_apply_mix_material(visual)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_target_duration_scale(animation_key),
		_target_minimum_duration(animation_key)
	)


func _play_ritual_visual(
	owner_node: Node,
	effect_root: Control,
	animation_key: String,
	global_source: Vector2,
	global_destination: Vector2,
	local_target_rects: Array[Rect2],
	canvas_override := Rect2()
) -> void:
	var canvas_rect: Rect2 = canvas_override
	if canvas_rect.size == Vector2.ZERO:
		canvas_rect = _root_effect_rect(effect_root)
	var visual := FoxSpiritRitualVisualScript.new() as FoxSpiritRitualVisual
	visual.name = "FoxSpirit_%s" % animation_key
	visual.size = canvas_rect.size
	visual.global_position = canvas_rect.position
	visual.z_index = 2488
	visual.modulate.a = 0.0
	visual.configure(
		animation_key,
		global_source - canvas_rect.position,
		global_destination - canvas_rect.position,
		local_target_rects
	)
	_apply_mix_material(visual)
	effect_root.add_child(visual)
	await _run_visual(
		owner_node,
		visual,
		_ritual_duration_scale(animation_key),
		_ritual_minimum_duration(animation_key)
	)


func _run_visual(
	owner_node: Node,
	visual: Control,
	duration_scale: float,
	minimum_duration: float
) -> void:
	if owner_node == null or visual == null:
		return
	var total_duration := maxf(spell_animation_duration * duration_scale, minimum_duration)
	var rise_duration := total_duration * 0.15
	var hold_duration := total_duration * 0.68
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


func _get_area_rect(anchor_card: Card, area_rows: int, area_cols: int) -> Rect2:
	var anchor_rect := anchor_card.get_global_rect()
	var area_size := Vector2(anchor_card.size.x * area_cols, anchor_card.size.y * area_rows)
	if area_rows % 2 == 0 or area_cols % 2 == 0:
		return Rect2(anchor_rect.position, area_size)
	return Rect2(anchor_rect.get_center() - area_size * 0.5, area_size)


func _get_tail_meter_rect(owner_node: Node) -> Rect2:
	if owner_node == null or owner_node.get_tree() == null:
		return Rect2()
	var meter := owner_node.get_tree().get_first_node_in_group("fox_tail_resource_meter") as Control
	if meter == null or not meter.is_visible_in_tree():
		return Rect2()
	return meter.get_global_rect()


func _get_daji_rect(owner_node: Node) -> Rect2:
	if owner_node == null or not owner_node.has_method("get_all_board_states"):
		return Rect2()
	var current_player: PlayerState = null
	if owner_node.has_method("get_current_player"):
		current_player = owner_node.get_current_player() as PlayerState
	for state in owner_node.get_all_board_states():
		if state == null or state.card_id != "su_daji" or not state.is_face_up:
			continue
		if current_player != null and state.owner_id != current_player.id:
			continue
		if not owner_node.has_method("get_card_for_state"):
			continue
		var daji_card := owner_node.get_card_for_state(state) as Card
		if daji_card != null:
			return daji_card.get_global_rect()
	return Rect2()


func _get_hand_destination(owner_node: Node, fallback_rect: Rect2) -> Vector2:
	if owner_node != null:
		var drawer_controller: Variant = owner_node.get("hand_drawer_controller")
		if drawer_controller != null:
			var drawer_panel: Variant = drawer_controller.get("panel")
			if drawer_panel is Control:
				var panel_control := drawer_panel as Control
				if panel_control.is_visible_in_tree():
					return panel_control.get_global_rect().get_center()
	return Vector2(fallback_rect.position.x + fallback_rect.size.x * 0.28, fallback_rect.end.y - 72.0)


func _get_board_center(owner_node: Node, effect_root: Control) -> Vector2:
	if owner_node != null:
		var board_node := owner_node.get_node_or_null("../CardBoard") as Control
		if board_node != null:
			return board_node.get_global_rect().get_center()
	return _root_effect_rect(effect_root).get_center()


func _root_effect_rect(effect_root: Control) -> Rect2:
	var root_rect := effect_root.get_global_rect()
	if root_rect.size.x > 1.0 and root_rect.size.y > 1.0:
		return root_rect
	return Rect2(effect_root.global_position, Vector2(1280.0, 720.0))


func _merged_effect_rect(first_rect: Rect2, second_rect: Rect2, margin_scale: float) -> Rect2:
	var left := minf(first_rect.position.x, second_rect.position.x)
	var top := minf(first_rect.position.y, second_rect.position.y)
	var right := maxf(first_rect.end.x, second_rect.end.x)
	var bottom := maxf(first_rect.end.y, second_rect.end.y)
	var margin := maxf(maxf(first_rect.size.x, second_rect.size.x) * margin_scale, 20.0)
	return Rect2(
		Vector2(left - margin, top - margin),
		Vector2(right - left + margin * 2.0, bottom - top + margin * 2.0)
	)


func _bounds_for_rects(rects: Array[Rect2], margin_scale: float) -> Rect2:
	var bounds := rects[0]
	for rect_index in range(1, rects.size()):
		bounds = bounds.merge(rects[rect_index])
	var margin := maxf(bounds.size.x, bounds.size.y) * margin_scale
	return bounds.grow(maxf(margin, 24.0))


func _apply_mix_material(visual: CanvasItem) -> void:
	var visual_material := CanvasItemMaterial.new()
	visual_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	visual.material = visual_material


func _target_margin(animation_key: String) -> float:
	if animation_key == "sacrifice":
		return 0.28
	if animation_key in ["charm", "fox_mind_art", "soul_hook"]:
		return 0.46
	return 0.58


func _target_duration_scale(animation_key: String) -> float:
	match animation_key:
		"sacrifice":
			return 3.25
		"charm":
			return 2.90
		"fox_mind_art", "soul_hook":
			return 2.55
		"fox_reborn":
			return 2.35
		_:
			return 2.10


func _target_minimum_duration(animation_key: String) -> float:
	if animation_key == "sacrifice":
		return 1.00
	if animation_key == "charm":
		return 0.88
	return 0.68


func _ritual_duration_scale(animation_key: String) -> float:
	if animation_key == "ruin_country":
		return 4.10
	if animation_key == "ruin_country_targets":
		return 2.05
	if animation_key == "nine_tail_army":
		return 3.20
	return 3.15


func _ritual_minimum_duration(animation_key: String) -> float:
	if animation_key == "ruin_country":
		return 1.34
	if animation_key == "ruin_country_targets":
		return 0.68
	return 1.02
