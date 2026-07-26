extends SceneTree

const SilverHandAnimationProviderScript := preload(
	"res://scripts/ui/animation/silver_hand_animation_provider.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "SilverHandAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := SilverHandAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))
	var animation_keys: Array[String] = [
		"divine_shield",
		"baptism",
		"holy_heal",
		"power_word_shield",
		"inner_fire",
		"resurrection"
	]

	for animation_key in animation_keys:
		await provider.play_at_rect(effect_root, effect_root, target_rect, animation_key)
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error(
				"Silver Hand animation leaked nodes after %s: %d"
				% [animation_key, effect_root.get_child_count()]
			)
			quit(1)
			return

	var shield_data := CardData.new()
	shield_data.id = "shield_test_unit"
	shield_data.type = CardData.TYPE_MINION
	shield_data.health = 5
	var shield_state := CardState.new()
	shield_state.set_card_data(shield_data)
	shield_state.set_face_up(true)
	var shield_status := CardStatus.new()
	shield_status.status_id = CardStatus.STATUS_DIVINE_SHIELD
	shield_state.add_status(shield_status)

	var status_overlay := CardStatusOverlay.new()
	status_overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(status_overlay)
	status_overlay.set_state(shield_state)
	if not status_overlay.visible or not status_overlay.is_processing():
		push_error("Divine Shield overlay did not enable its animated refresh")
		quit(1)
		return

	shield_state.remove_status(CardStatus.STATUS_DIVINE_SHIELD)
	status_overlay.refresh()
	if status_overlay.is_processing():
		push_error("Divine Shield overlay kept processing after the status was removed")
		quit(1)
		return
	status_overlay.queue_free()
	await process_frame

	effect_root.queue_free()
	await process_frame
	print("SILVER_HAND_ANIMATION_TESTS_OK")
	quit()
