extends SceneTree

const DalaranAnimationProviderScript := preload(
	"res://scripts/ui/animation/dalaran_animation_provider.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "DalaranAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := DalaranAnimationProviderScript.new()
	provider.setup(0.01, 0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))
	var animation_keys: Array[String] = [
		"arcane_aura_prepare",
		"arcane_aura_pulse",
		"water_summon",
		"giant_water_summon",
		"academy_summon",
		"frost_shield",
		"arcane_wisdom",
		"arcane_space",
		"blizzard"
	]

	for animation_key in animation_keys:
		await provider.play_school_visual_at_rect(
			effect_root,
			effect_root,
			target_rect,
			animation_key
		)
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error(
				"Dalaran animation leaked nodes after %s: %d"
				% [animation_key, effect_root.get_child_count()]
			)
			quit(1)
			return

	var aura_data := CardData.new()
	aura_data.id = "arcane_aura_test_unit"
	aura_data.type = CardData.TYPE_MINION
	aura_data.health = 5
	var aura_state := CardState.new()
	aura_state.set_card_data(aura_data)
	aura_state.set_face_up(true)
	var aura_status := CardStatus.new()
	aura_status.status_id = CardStatus.STATUS_ARCANE_AURA
	aura_status.stacks = 2
	aura_state.add_status(aura_status)

	var status_overlay := CardStatusOverlay.new()
	status_overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(status_overlay)
	status_overlay.set_state(aura_state)
	if not status_overlay.visible or not status_overlay.is_processing():
		push_error("Brilliant Aura overlay did not enable animated refresh")
		quit(1)
		return

	aura_state.remove_status(CardStatus.STATUS_ARCANE_AURA)
	status_overlay.refresh()
	if status_overlay.is_processing():
		push_error("Brilliant Aura overlay kept processing after status removal")
		quit(1)
		return
	status_overlay.queue_free()
	await process_frame

	effect_root.queue_free()
	await process_frame
	print("DALARAN_ANIMATION_TESTS_OK")
	quit()
