extends SceneTree

const MonkeyAnimationProviderScript := preload(
	"res://scripts/ui/animation/monkey_animation_provider.gd"
)
const MonkeySpellVisualScript := preload(
	"res://scripts/ui/animation/monkey_spell_visual.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "MonkeyAnimationTestRoot"
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
	print("MONKEY_ANIMATION_TESTS_OK")
	quit()


func _test_visual_frames(effect_root: Control) -> bool:
	var visual_keys: Array[String] = [
		"fiery_eyes_golden_gaze",
		"somersault_cloud",
		"monkey_somersault_move",
		"body_beyond_body",
		"hair_clone_enter",
		"monkey_hair_clone_assist",
		"bronze_head_iron_arms",
		"bronze_head_iron_arms_reflect",
		"immortal_peach",
		"drive_spirit",
		"drive_spirit_battlefield",
		"immobilize",
		"gather_scatter_qi",
		"dragon_palace_treasure",
		"heavenly_form",
		"monkey_westward_move",
	]
	for animation_key in visual_keys:
		var visual := MonkeySpellVisualScript.new() as MonkeySpellVisual
		visual.size = effect_root.size
		visual.configure(
			animation_key,
			Vector2(300.0, 390.0),
			Vector2(900.0, 310.0)
		)
		visual.progress = 0.56
		effect_root.add_child(visual)
		await process_frame
		visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error("Monkey visual leaked nodes after %s" % animation_key)
			quit(1)
			return false
	return true


func _test_provider_lifecycle(effect_root: Control) -> bool:
	var provider := MonkeyAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(550.0, 260.0), Vector2(120.0, 168.0))
	await provider.play_at_rect(
		effect_root,
		effect_root,
		target_rect,
		"immortal_peach"
	)
	await process_frame
	if effect_root.get_child_count() != 0:
		push_error("Monkey provider leaked a completed spell visual")
		quit(1)
		return false

	provider.spawn_movement_path(
		effect_root,
		effect_root,
		Rect2(Vector2(170.0, 330.0), Vector2(96.0, 132.0)),
		Rect2(Vector2(920.0, 250.0), Vector2(96.0, 132.0)),
		"monkey_somersault_move",
		0.02
	)
	await create_timer(0.06).timeout
	if effect_root.get_child_count() != 1:
		push_error("Monkey movement visual was not created")
		quit(1)
		return false
	var movement_visual := effect_root.get_child(0) as MonkeySpellVisual
	if movement_visual == null or movement_visual.modulate.a <= 0.05:
		push_error("Monkey movement visual remained transparent")
		quit(1)
		return false
	await create_timer(0.36).timeout
	await process_frame
	if effect_root.get_child_count() != 0:
		push_error("Monkey movement visual was not reclaimed")
		quit(1)
		return false
	return true


func _test_status_overlays(effect_root: Control) -> bool:
	var card_data := CardData.new()
	card_data.id = "monkey_status_test"
	card_data.type = CardData.TYPE_MINION
	card_data.faction_id = "monkey_spirit"
	card_data.health = 8
	var state := CardState.new()
	state.set_card_data(card_data)
	state.set_face_up(true)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)
	var status_specs: Array[Dictionary] = [
		{"id": CardStatus.STATUS_BRONZE_HEAD_IRON_ARMS, "tags": []},
		{"id": CardStatus.STATUS_IMMORTAL_PEACH, "tags": []},
		{"id": CardStatus.STATUS_ROOTED, "tags": []},
		{"id": "gather_scatter_qi", "tags": [CardStatus.TAG_STEALTH]},
		{"id": CardStatus.STATUS_FIERY_EYES_VISION, "tags": []},
		{"id": CardStatus.STATUS_SOMERSAULT_CLOUD, "tags": []},
	]
	for status_spec in status_specs:
		var status := CardStatus.new()
		status.status_id = str(status_spec["id"])
		for tag_value in status_spec["tags"] as Array:
			status.tags.append(str(tag_value))
		status.stacks = 2
		state.add_status(status)
		overlay.refresh()
		await process_frame
		if not overlay.visible or not overlay.is_processing():
			push_error("Monkey status overlay did not animate: %s" % status.status_id)
			quit(1)
			return false
		state.remove_status(status.status_id)
		overlay.refresh()
		if (
			status.status_id == CardStatus.STATUS_ROOTED
			and not overlay.is_rooted_break_active()
		):
			push_error("Rooted removal did not start the seal-break feedback")
			quit(1)
			return false

	overlay.queue_free()
	await process_frame
	if effect_root.get_child_count() != 0:
		push_error("Monkey status overlay was not reclaimed")
		quit(1)
		return false
	return true


func _test_card_configuration() -> bool:
	var database := CardDatabase.new()
	if not database.load_from_json("res://data/cards.json"):
		push_error("Monkey animation test could not load card data")
		quit(1)
		return false

	var wukong := database.get_card("sun_wukong")
	var gather_qi := database.get_card("gather_scatter_qi")
	var heavenly_form := database.get_card("heavenly_form")
	var treasure := database.get_card("dragon_palace_treasure")
	var hair_clone := database.get_card("hair_clone")
	if null in [wukong, gather_qi, heavenly_form, treasure, hair_clone]:
		push_error("Monkey animation configuration is missing a required card")
		quit(1)
		return false

	var fiery_eyes_action := _find_config_by_id(wukong.spell_actions, "fiery_eyes_golden_gaze")
	if fiery_eyes_action.is_empty():
		push_error("Fiery Eyes action configuration is missing")
		quit(1)
		return false
	var vision_marker_found := false
	for effect_data in fiery_eyes_action.get(EffectData.KEY_EFFECTS, []) as Array:
		if (
			effect_data is Dictionary
			and EffectData.get_status_id(effect_data) == CardStatus.STATUS_FIERY_EYES_VISION
		):
			vision_marker_found = EffectData.get_status_tags(effect_data).has(CardStatus.TAG_UNCLEANSEABLE)
	if not vision_marker_found:
		push_error("Fiery Eyes is missing its uncleanseable turn marker")
		quit(1)
		return false

	for spell_card in [gather_qi, heavenly_form]:
		var effect_data: Dictionary = spell_card.effects[0]
		if str(effect_data.get(EffectData.KEY_PRESENTATION_TARGET, "")) != EffectData.PRESENTATION_TARGET_EFFECT_TARGET:
			push_error("Monkey owner-card spell has no board presentation target: %s" % spell_card.id)
			quit(1)
			return false
	if treasure.animation != "dragon_palace_treasure":
		push_error("Dragon Palace Treasure has no equipment animation")
		quit(1)
		return false
	var sync_effect := _find_config_by_id(hair_clone.effects, EffectData.EFFECT_SYNC_STATS_FROM_OWNER_CARD)
	if str(sync_effect.get(EffectData.KEY_ANIMATION, "")) != "hair_clone_enter":
		push_error("Hair Clone entry trigger has no animation")
		quit(1)
		return false
	return true


func _find_config_by_id(configs: Array[Dictionary], config_id: String) -> Dictionary:
	for config in configs:
		var resolved_id := str(config.get("id", config.get("action_id", "")))
		if resolved_id == config_id:
			return config
	return {}
