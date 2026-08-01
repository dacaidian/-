extends SceneTree

const FoxSpiritAnimationProviderScript := preload(
	"res://scripts/ui/animation/fox_spirit_animation_provider.gd"
)
const FoxSpiritTargetVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_target_visual.gd"
)
const FoxSpiritAreaVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_area_visual.gd"
)
const FoxSpiritRitualVisualScript := preload(
	"res://scripts/ui/animation/fox_spirit_ritual_visual.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "FoxSpiritAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	if not await _test_visual_frames(effect_root):
		return
	if not await _test_provider_lifecycle(effect_root):
		return
	if not await _test_status_overlays(effect_root):
		return
	if not _test_card_configuration():
		return

	effect_root.queue_free()
	await process_frame
	print("FOX_SPIRIT_ANIMATION_TESTS_OK")
	quit()


func _test_visual_frames(effect_root: Control) -> bool:
	for animation_key in [
		"sacrifice",
		"nine_tail_sacrifice",
		"fox_reborn",
		"soul_hook",
		"charm",
		"fox_mind_art",
		"nine_tail_tail_enter",
	]:
		var target_visual := FoxSpiritTargetVisualScript.new() as FoxSpiritTargetVisual
		target_visual.size = effect_root.size
		target_visual.configure(
			animation_key,
			Vector2(290.0, 440.0),
			Vector2(980.0, 180.0),
			Vector2(120.0, 168.0),
			Vector2(120.0, 168.0),
			1.0,
			Vector2(620.0, 360.0),
			animation_key == "sacrifice"
		)
		target_visual.progress = 0.58
		effect_root.add_child(target_visual)
		await process_frame
		target_visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Fox Spirit target visual leaked nodes after %s" % animation_key)

	var area_visual := FoxSpiritAreaVisualScript.new() as FoxSpiritAreaVisual
	area_visual.size = effect_root.size
	area_visual.configure(Vector2(210.0, 520.0), Rect2(Vector2(530.0, 190.0), Vector2(360.0, 420.0)))
	area_visual.progress = 0.62
	effect_root.add_child(area_visual)
	await process_frame
	area_visual.queue_free()
	await process_frame

	for animation_key in [
		"ruin_country",
		"ruin_country_targets",
		"nine_tail_army",
		"celestial_fox_evolve",
	]:
		var ritual_visual := FoxSpiritRitualVisualScript.new() as FoxSpiritRitualVisual
		ritual_visual.size = effect_root.size
		var target_rects: Array[Rect2] = [
			Rect2(Vector2(420.0, 220.0), Vector2(120.0, 168.0)),
			Rect2(Vector2(610.0, 220.0), Vector2(120.0, 168.0)),
		]
		ritual_visual.configure(
			animation_key,
			Vector2(180.0, 600.0),
			Vector2(640.0, 330.0),
			target_rects
		)
		ritual_visual.progress = 0.60
		effect_root.add_child(ritual_visual)
		await process_frame
		ritual_visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Fox Spirit ritual visual leaked nodes after %s" % animation_key)
	return true


func _test_provider_lifecycle(effect_root: Control) -> bool:
	var provider := FoxSpiritAnimationProviderScript.new()
	provider.setup(0.01)
	await provider.play_at_rect(
		effect_root,
		effect_root,
		Rect2(Vector2(520.0, 260.0), Vector2(120.0, 168.0)),
		"charm"
	)
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Fox Spirit provider leaked a completed target visual")

	await provider.play_board(effect_root, effect_root, "nine_tail_army")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Fox Spirit provider leaked a completed ritual visual")
	return true


func _test_status_overlays(effect_root: Control) -> bool:
	var card_data := CardData.new()
	card_data.id = "fox_status_test"
	card_data.type = CardData.TYPE_MINION
	card_data.faction_id = "fox_spirit"
	card_data.health = 8
	var state := CardState.new()
	state.set_card_data(card_data)
	state.set_face_up(true)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)

	var soul_hook := CardStatus.new()
	soul_hook.status_id = CardStatus.STATUS_SOUL_HOOK
	soul_hook.is_permanent = false
	soul_hook.remaining_turns = 1
	state.add_status(soul_hook)
	overlay.refresh()
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		return _fail("Soul Hook persistent visual is not animated")
	state.remove_status(CardStatus.STATUS_SOUL_HOOK)

	var temporary_charm := CardStatus.new()
	temporary_charm.status_id = CardStatus.STATUS_CHARM
	temporary_charm.is_permanent = false
	temporary_charm.remaining_turns = 1
	state.add_status(temporary_charm)
	overlay.refresh()
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		return _fail("Fox Thought persistent visual is not animated")

	overlay.queue_free()
	await process_frame
	return true


func _test_card_configuration() -> bool:
	var database := CardDatabase.new()
	if not database.load_from_json("res://data/cards.json"):
		return _fail("Fox Spirit animation test could not load card data")

	var soul_hook := database.get_card("gou_po")
	var charm := database.get_card("charm_spell")
	var yousu := database.get_card("yousu_fox_spirit")
	var transformation := database.get_card("tianhu_transformation")
	var ruin_country := database.get_card("huo_guo")
	var tail_token := database.get_card("nine_tail_tail")
	if null in [soul_hook, charm, yousu, transformation, ruin_country, tail_token]:
		return _fail("Fox Spirit animation configuration is missing a required card")
	if soul_hook.animation != "soul_hook" or charm.animation != "charm":
		return _fail("Fox Spirit targeted spell animation keys are invalid")
	if str(yousu.spell_actions[0].get("animation", "")) != "fox_mind_art":
		return _fail("Fox Thought does not have its temporary-control visual key")
	if str(transformation.effects[0].get("animation", "")) != "celestial_fox_evolve":
		return _fail("Celestial Fox evolution does not have a multi-card visual key")
	if ruin_country.animation != "ruin_country":
		return _fail("Ruin Country does not have its ritual visual key")
	if str(ruin_country.effects[0].get("animation", "")) != "ruin_country_targets":
		return _fail("Ruin Country does not mark its resolved sacrifice targets")
	if str(ruin_country.effects[1].get("animation", "")) != "nine_tail_army":
		return _fail("Ruin Country token generation does not have its hand visual key")
	var nine_tails := database.get_card("nine_tails_upgrade")
	if nine_tails == null:
		return _fail("Nine Tails upgrade is missing")
	var skill_modifier: Dictionary = nine_tails.effects[0]
	var before_target_effects: Array = skill_modifier.get("before_target_effects", [])
	if before_target_effects.is_empty() or str(before_target_effects[0].get("animation", "")) != "fox_reborn":
		return _fail("Nine Tails does not use the faction-specific reborn grant visual")
	if tail_token.animation != "nine_tail_tail_enter":
		return _fail("Nine-Tail Tail does not have its board-entry visual key")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
