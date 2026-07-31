extends SceneTree

const TokyoGhoulAnimationProviderScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_animation_provider.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "TokyoGhoulAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := TokyoGhoulAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))

	for animation_key in [
		"centipede_form",
		"dragon_form",
		"saint_sword_form",
		"bikaku_volley"
	]:
		await provider.play_at_rect(effect_root, effect_root, target_rect, animation_key)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			return

	await provider.play_board(effect_root, effect_root, "kagune_release")
	await process_frame
	if not _assert_no_children(effect_root, "kagune_release"):
		return

	var caster := Card.new()
	caster.size = Vector2(96.0, 132.0)
	caster.global_position = Vector2(180.0, 300.0)
	var target := Card.new()
	target.size = Vector2(96.0, 132.0)
	target.global_position = Vector2(880.0, 260.0)
	await provider.play_targeted(effect_root, effect_root, caster, target, "feather_needle")
	await process_frame
	if not _assert_no_children(effect_root, "feather_needle"):
		caster.free()
		target.free()
		return


	for animation_key in [
		"rc_forced_feeding",
		"bikaku_volley",
		"free_meal",
		"kakuja_form",
		"restore_form"
	]:
		await provider.play_targeted(effect_root, effect_root, caster, target, animation_key)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			caster.free()
			target.free()
			return

	caster.free()
	target.free()
	await process_frame
	if not _assert_no_children(effect_root, "targeted_cleanup"):
		return

	var state := CardState.new()
	var card_data := CardData.new()
	card_data.id = "tokyo_ghoul_overlay_test"
	card_data.type = CardData.TYPE_MINION
	card_data.health = 8
	state.set_card_data(card_data)
	state.set_face_up(true)

	var status := CardStatus.new()
	status.status_id = KagunePowerResolver.STATUS_ID
	status.tags = [KagunePowerResolver.STATUS_TAG]
	status.payload = {
		KagunePowerResolver.PAYLOAD_KAGUNE_TYPES: [
			CardData.KEYWORD_KAGUNE_BIKAKU,
			CardData.KEYWORD_KAGUNE_RINKAKU,
			CardData.KEYWORD_KAGUNE_KOUKAKU,
			CardData.KEYWORD_KAGUNE_UKAKU
		],
		KagunePowerResolver.PAYLOAD_IS_HIGH_CONCENTRATION: true
	}
	state.add_status(status)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)
	if not overlay.visible or not overlay.is_processing():
		push_error("Tokyo Ghoul kagune overlay did not enable animated refresh")
		quit(1)
		return

	state.remove_status(status.status_id)
	overlay.refresh()
	if overlay.visible or overlay.is_processing():
		push_error("Tokyo Ghoul kagune overlay stayed active after status removal")
		quit(1)
		return

	overlay.queue_free()
	effect_root.queue_free()
	await process_frame
	print("TOKYO_GHOUL_ANIMATION_TESTS_OK")
	quit()


func _assert_no_children(effect_root: Control, animation_key: String) -> bool:
	if effect_root.get_child_count() == 0:
		return true
	push_error(
		"Tokyo Ghoul animation leaked nodes after %s: %d"
		% [animation_key, effect_root.get_child_count()]
	)
	quit(1)
	return false
