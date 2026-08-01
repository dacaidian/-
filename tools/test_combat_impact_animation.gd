extends SceneTree

const CombatImpactAnimationProviderScript := preload(
	"res://scripts/ui/animation/combat_impact_animation_provider.gd"
)
const CombatAreaAttackVisualScript := preload(
	"res://scripts/ui/animation/combat_area_attack_visual.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "CombatImpactAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	if not await _test_visual_frames(effect_root):
		return
	if not await _test_provider_lifecycle(effect_root):
		return
	if not _test_semantic_resolution():
		return

	effect_root.queue_free()
	await process_frame
	print("COMBAT_IMPACT_ANIMATION_TESTS_OK")
	quit()


func _test_visual_frames(effect_root: Control) -> bool:
	var source_center := Vector2(420.0, 520.0)
	var primary_center := Vector2(620.0, 330.0)
	var secondary_centers := PackedVector2Array([
		Vector2(480.0, 300.0),
		Vector2(760.0, 300.0),
		Vector2(520.0, 450.0),
		Vector2(720.0, 450.0),
	])
	for animation_key in [
		GameAnimationResolver.SECONDARY_ATTACK_FRONTAL,
		GameAnimationResolver.SECONDARY_ATTACK_FIXED_SPLASH,
		GameAnimationResolver.SECONDARY_ATTACK_SAINT_SWORD,
	]:
		var visual := CombatAreaAttackVisualScript.new()
		visual.size = effect_root.size
		visual.configure(source_center, primary_center, secondary_centers, animation_key)
		visual.progress = 0.56
		effect_root.add_child(visual)
		await process_frame
		visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error("Combat area visual leaked nodes after %s" % animation_key)
			quit(1)
			return false
	return true


func _test_provider_lifecycle(effect_root: Control) -> bool:
	var provider := CombatImpactAnimationProviderScript.new()
	provider.setup(0.01)
	var source_rect := Rect2(Vector2(250.0, 470.0), Vector2(96.0, 132.0))
	var primary_rect := Rect2(Vector2(590.0, 290.0), Vector2(96.0, 132.0))
	var secondary_rects: Array[Rect2] = [
		Rect2(Vector2(450.0, 270.0), Vector2(96.0, 132.0)),
		Rect2(Vector2(730.0, 270.0), Vector2(96.0, 132.0)),
	]
	for animation_key in [
		GameAnimationResolver.SECONDARY_ATTACK_FRONTAL,
		GameAnimationResolver.SECONDARY_ATTACK_FIXED_SPLASH,
		GameAnimationResolver.SECONDARY_ATTACK_SAINT_SWORD,
	]:
		provider.spawn_secondary_attack_visual(
			effect_root,
			effect_root,
			source_rect,
			primary_rect,
			secondary_rects,
			animation_key
		)
		await process_frame
		if effect_root.get_child_count() != 1:
			push_error("Combat impact provider did not create %s" % animation_key)
			quit(1)
			return false
		await create_timer(0.46).timeout
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error("Combat impact provider leaked %s" % animation_key)
			quit(1)
			return false
	return true


func _test_semantic_resolution() -> bool:
	var resolver := GameAnimationResolver.new()
	var giant := _create_state("giant_test", [CardData.KEYWORD_GIANT])
	var frontal := _create_state("frontal_test", ["frontal_width_5"])
	var splash := _create_state("splash_test", ["splash_4"])
	var saint_sword := _create_state("kaneki_saint_sword_form", ["splash_4"])
	if (
		resolver.resolve_secondary_attack_animation_key(giant)
		!= GameAnimationResolver.SECONDARY_ATTACK_FRONTAL
	):
		return _fail("Giant did not resolve to the shared frontal impact")
	if (
		resolver.resolve_secondary_attack_animation_key(frontal)
		!= GameAnimationResolver.SECONDARY_ATTACK_FRONTAL
	):
		return _fail("frontal_width_N did not resolve to the shared frontal impact")
	if (
		resolver.resolve_secondary_attack_animation_key(splash)
		!= GameAnimationResolver.SECONDARY_ATTACK_FIXED_SPLASH
	):
		return _fail("splash_N did not resolve to the shared fixed splash impact")
	if (
		resolver.resolve_secondary_attack_animation_key(saint_sword)
		!= GameAnimationResolver.SECONDARY_ATTACK_SAINT_SWORD
	):
		return _fail("Kaneki Saint Sword did not resolve to its RC sword splash")
	return true


func _create_state(card_id: String, keywords: Array[String]) -> CardState:
	var card_data := CardData.new()
	card_data.id = card_id
	card_data.type = CardData.TYPE_MINION
	card_data.attack = 4
	card_data.health = 8
	card_data.keywords = keywords.duplicate()
	var state := CardState.new()
	state.set_card_data(card_data)
	state.set_face_up(true)
	return state


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
