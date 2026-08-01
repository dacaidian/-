extends SceneTree

const BeastmenAnimationProviderScript := preload(
	"res://scripts/ui/animation/beastmen_animation_provider.gd"
)
const BeastmenCombatVisualScript := preload(
	"res://scripts/ui/animation/beastmen_combat_visual.gd"
)
const BeastmenRitualVisualScript := preload(
	"res://scripts/ui/animation/beastmen_ritual_visual.gd"
)
const BeastmenPathVisualScript := preload(
	"res://scripts/ui/animation/beastmen_path_visual.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "BeastmenAnimationTestRoot"
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
	print("BEASTMEN_ANIMATION_TESTS_OK")
	quit()


func _test_visual_frames(effect_root: Control) -> bool:
	for animation_key in [
		"beastmen_evolution",
		"beastmen_slaughter",
		"wanmo_charge",
		"savage_roar_buff",
	]:
		var combat_visual := BeastmenCombatVisualScript.new()
		combat_visual.size = effect_root.size
		combat_visual.configure(
			animation_key,
			Vector2(280.0, 420.0),
			Vector2(790.0, 310.0),
			Vector2(120.0, 168.0)
		)
		combat_visual.progress = 0.58
		effect_root.add_child(combat_visual)
		await process_frame
		combat_visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Beastmen combat visual leaked nodes after %s" % animation_key)

	for animation_key in [
		"savage_roar",
		"wild_call",
		"beast_path",
		"wanmo_ritual",
		"chaos_corruption_burst",
	]:
		var ritual_visual := BeastmenRitualVisualScript.new()
		ritual_visual.size = effect_root.size
		ritual_visual.configure(
			animation_key,
			Vector2(380.0, 420.0),
			Vector2(1050.0, 610.0),
			Rect2(Vector2(130.0, 70.0), Vector2(980.0, 560.0)),
			Vector2(120.0, 168.0)
		)
		ritual_visual.progress = 0.61
		effect_root.add_child(ritual_visual)
		await process_frame
		ritual_visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Beastmen ritual visual leaked nodes after %s" % animation_key)

	var path_visual := BeastmenPathVisualScript.new()
	path_visual.size = effect_root.size
	var path_rects: Array[Rect2] = []
	for path_index in range(5):
		path_rects.append(
			Rect2(
				Vector2(180.0 + float(path_index) * 150.0, 130.0 + float(path_index) * 78.0),
				Vector2(118.0, 164.0)
			)
		)
	path_visual.configure(path_rects)
	path_visual.progress = 0.64
	effect_root.add_child(path_visual)
	await process_frame
	path_visual.queue_free()
	await process_frame
	return effect_root.get_child_count() == 0 or _fail("Beast Path visual leaked nodes")


func _test_provider_lifecycle(effect_root: Control) -> bool:
	var provider := BeastmenAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(530.0, 250.0), Vector2(120.0, 168.0))

	await provider.play_at_rect(effect_root, effect_root, target_rect, "beastmen_evolution")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Beastmen provider leaked a completed combat visual")

	await provider.play_at_rect(effect_root, effect_root, target_rect, "wild_call")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Beastmen provider leaked a completed ritual visual")

	await provider.play_board(effect_root, effect_root, "chaos_corruption_burst")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Beastmen provider leaked a completed board visual")

	var path_rects: Array[Rect2] = []
	for path_index in range(5):
		path_rects.append(Rect2(Vector2(210.0 + float(path_index) * 120.0, 180.0), Vector2(110.0, 154.0)))
	await provider.play_path(effect_root, effect_root, path_rects, "beast_path")
	await process_frame
	return effect_root.get_child_count() == 0 or _fail("Beastmen provider leaked a completed path visual")


func _test_status_overlays(effect_root: Control) -> bool:
	var minion_data := CardData.new()
	minion_data.id = "beastmen_status_test"
	minion_data.type = CardData.TYPE_MINION
	minion_data.faction_id = "beastmen"
	minion_data.health = 8
	minion_data.chaos_corruption = 3
	var minion_state := CardState.new()
	minion_state.set_card_data(minion_data)
	minion_state.set_face_up(true)
	minion_state.set_beast_path(true)

	var roar_status := CardStatus.new()
	roar_status.status_id = "savage_roar_attack"
	roar_status.is_permanent = false
	roar_status.remaining_turns = 1
	minion_state.add_status(roar_status)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(minion_state)
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		return _fail("Beast Path, corruption, and Savage Roar overlays are not animated")

	var building_data := CardData.new()
	building_data.id = "wanmo_status_test"
	building_data.type = CardData.TYPE_BUILDING
	building_data.faction_id = "beastmen"
	building_data.health = 20
	var building_state := CardState.new()
	building_state.set_card_data(building_data)
	building_state.set_face_up(true)
	var charge_status := CardStatus.new()
	charge_status.status_id = CardStatus.STATUS_WANMO_CHARGE
	charge_status.stacks = 4
	charge_status.is_permanent = true
	building_state.add_status(charge_status)
	overlay.set_state(building_state)
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		return _fail("Wanmo charge overlay is not animated")

	overlay.queue_free()
	await process_frame
	return true


func _test_card_configuration() -> bool:
	var database := CardDatabase.new()
	if not database.load_from_json("res://data/cards.json"):
		return _fail("Beastmen animation test could not load card data")

	var beast_path := database.get_card("beast_path")
	var savage_roar := database.get_card("savage_roar")
	var shaman := database.get_card("shrieking_shaman")
	var wanmo := database.get_card("wanmo_rock")
	var corruption := database.get_card("chaos_corruption")
	if null in [beast_path, savage_roar, shaman, wanmo, corruption]:
		return _fail("Beastmen animation configuration is missing a required card")
	if beast_path.animation != "beast_path":
		return _fail("Beast Path does not use its faction path animation")
	if str(shaman.spell_actions[0].get("animation", "")) != "wild_call":
		return _fail("Wild Call does not use its faction animation")
	if str(wanmo.actions[0].get("animation", "")) != "wanmo_ritual":
		return _fail("Desolation Ritual does not use its faction animation")
	if str(corruption.effects[0].get("animation", "")) != "chaos_corruption_burst":
		return _fail("Chaos Corruption does not use its battlefield animation")

	var grant_effect: Dictionary = savage_roar.effects[0]
	var spell_actions: Array = grant_effect.get("spell_actions", [])
	if spell_actions.is_empty() or str(spell_actions[0].get("animation", "")) != "savage_roar":
		return _fail("Savage Roar cast animation is missing")
	var roar_effects: Array = spell_actions[0].get("effects", [])
	if roar_effects.is_empty() or str(roar_effects[0].get("apply_animation", "")) != "savage_roar_buff":
		return _fail("Savage Roar repeats the full cast instead of the local buff feedback")

	var rules := database.get_faction_evolution_rules("beastmen")
	if rules.is_empty():
		return _fail("Beastmen evolution rules are missing")
	for rule in rules:
		if str(rule.get("animation", "")) != "beastmen_evolution":
			return _fail("A Beastmen evolution rule does not use the evolution visual")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
