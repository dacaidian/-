extends RefCounted
class_name DalaranSpaceSwapPlayer

const DalaranSpellVisualScript := preload(
	"res://scripts/ui/animation/dalaran_spell_visual.gd"
)

var spell_animation_duration := 0.32
var move_animation_duration := 0.24


func setup(spell_duration: float, move_duration: float) -> void:
	spell_animation_duration = spell_duration
	move_animation_duration = move_duration


func play(
	owner: Node,
	effect_root: Control,
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2
) -> void:
	if (
		owner == null
		or effect_root == null
		or first_card == null
		or second_card == null
	):
		return

	var first_rect := first_card.get_global_rect()
	var second_rect := second_card.get_global_rect()
	var first_anchor := _create_anchor(first_rect, "First")
	var second_anchor := _create_anchor(second_rect, "Second")
	var connection := _create_connection(first_rect.get_center(), second_rect.get_center())
	effect_root.add_child(connection)
	effect_root.add_child(first_anchor)
	effect_root.add_child(second_anchor)

	var charge_duration := maxf(spell_animation_duration * 0.74, 0.26)
	var charge := owner.create_tween()
	charge.set_parallel(true)
	charge.set_trans(Tween.TRANS_QUART)
	charge.set_ease(Tween.EASE_OUT)
	for anchor in [first_anchor, second_anchor]:
		charge.tween_property(anchor, "progress", 0.48, charge_duration)
		charge.tween_property(anchor, "scale", Vector2.ONE, charge_duration)
		charge.tween_property(anchor, "modulate:a", 0.96, charge_duration * 0.64)
	charge.tween_property(connection, "modulate:a", 0.78, charge_duration * 0.58)
	await charge.finished

	await _move_cards(
		owner,
		first_card,
		second_card,
		first_slot_position,
		second_slot_position,
		first_anchor,
		second_anchor,
		connection
	)

	var release_duration := maxf(spell_animation_duration * 0.74, 0.26)
	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_SINE)
	release.set_ease(Tween.EASE_OUT)
	for anchor in [first_anchor, second_anchor]:
		release.tween_property(anchor, "progress", 1.0, release_duration)
		release.tween_property(anchor, "scale", Vector2(1.18, 1.18), release_duration)
		release.tween_property(anchor, "modulate:a", 0.0, release_duration)
	release.tween_property(connection, "width", 0.8, release_duration)
	release.tween_property(connection, "modulate:a", 0.0, release_duration)
	await release.finished

	first_anchor.queue_free()
	second_anchor.queue_free()
	connection.queue_free()


func _move_cards(
	owner: Node,
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2,
	first_anchor: Control,
	second_anchor: Control,
	connection: Line2D
) -> void:
	var first_local_position := first_card.position
	var second_local_position := second_card.position
	var first_scale := first_card.scale
	var second_scale := second_card.scale
	var first_z_index := first_card.z_index
	var second_z_index := second_card.z_index

	first_card.is_animating = true
	second_card.is_animating = true
	first_card.set_as_top_level(true)
	second_card.set_as_top_level(true)
	first_card.z_index = 2502
	second_card.z_index = 2503
	first_card.global_position = second_slot_position
	second_card.global_position = first_slot_position

	var fold_duration := maxf(move_animation_duration, 0.24)
	var fold := owner.create_tween()
	fold.set_parallel(true)
	fold.set_trans(Tween.TRANS_QUART)
	fold.set_ease(Tween.EASE_IN_OUT)
	fold.tween_property(first_card, "global_position", first_slot_position, fold_duration)
	fold.tween_property(second_card, "global_position", second_slot_position, fold_duration)
	fold.tween_property(first_card, "scale", first_scale * 0.86, fold_duration * 0.48)
	fold.tween_property(second_card, "scale", second_scale * 0.86, fold_duration * 0.48)
	fold.tween_property(first_card, "scale", first_scale, fold_duration * 0.52).set_delay(fold_duration * 0.48)
	fold.tween_property(second_card, "scale", second_scale, fold_duration * 0.52).set_delay(fold_duration * 0.48)
	fold.tween_property(first_anchor, "rotation", PI * 0.66, fold_duration)
	fold.tween_property(second_anchor, "rotation", -PI * 0.66, fold_duration)
	fold.tween_property(connection, "width", 7.0, fold_duration * 0.44)
	await fold.finished

	first_card.set_as_top_level(false)
	second_card.set_as_top_level(false)
	first_card.position = first_local_position
	second_card.position = second_local_position
	first_card.scale = first_scale
	second_card.scale = second_scale
	first_card.z_index = first_z_index
	second_card.z_index = second_z_index
	first_card.is_animating = false
	second_card.is_animating = false


func _create_anchor(target_rect: Rect2, suffix: String) -> Control:
	var anchor := DalaranSpellVisualScript.new()
	anchor.name = "ArcaneSpace%sAnchor" % suffix
	anchor.configure("arcane_space_anchor")
	anchor.size = target_rect.size * 1.44
	anchor.pivot_offset = anchor.size * 0.5
	anchor.global_position = target_rect.get_center() - anchor.pivot_offset
	anchor.scale = Vector2(0.52, 0.52)
	anchor.modulate.a = 0.0
	anchor.z_index = 2492
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	anchor.material = material
	return anchor


func _create_connection(first_center: Vector2, second_center: Vector2) -> Line2D:
	var connection := Line2D.new()
	connection.name = "ArcaneSpaceConnection"
	connection.points = PackedVector2Array([first_center, second_center])
	connection.width = 2.4
	connection.default_color = Color(0.56, 0.62, 1.0, 0.92)
	connection.antialiased = true
	connection.modulate.a = 0.0
	connection.z_index = 2488
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.70, 0.54, 1.0, 0.84),
		Color(0.72, 0.90, 1.0, 0.98),
		Color(0.70, 0.54, 1.0, 0.84)
	])
	connection.gradient = gradient
	return connection
