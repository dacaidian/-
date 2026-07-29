extends SceneTree

const NightElfAnimationProviderScript := preload(
	"res://scripts/ui/animation/night_elf_animation_provider.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "NightElfAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := NightElfAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))

	for animation_key in [
		"moonblade",
		"tranquil_spring",
		"precision_shot",
		"full_moon_cover",
		"meteor_aura",
		"meteor_strike",
		"claw_strike",
		"elune_grace"
	]:
		await provider.play_at_rect(effect_root, effect_root, target_rect, animation_key)
		await process_frame
		_assert_no_children(effect_root, animation_key)

	var claw_target := Card.new()
	claw_target.size = Vector2(96.0, 132.0)
	claw_target.global_position = Vector2(760.0, 260.0)
	await provider.play_from_rect(
		effect_root,
		effect_root,
		Rect2(Vector2(120.0, 260.0), Vector2(80.0, 120.0)),
		claw_target,
		"claw_strike"
	)
	claw_target.free()
	await process_frame
	_assert_no_children(effect_root, "claw_strike_source_rect")

	var moonblade_caster := Card.new()
	moonblade_caster.size = Vector2(96.0, 132.0)
	moonblade_caster.global_position = Vector2(160.0, 360.0)
	var moonblade_first := Card.new()
	moonblade_first.size = Vector2(96.0, 132.0)
	moonblade_first.global_position = Vector2(520.0, 210.0)
	var moonblade_second := Card.new()
	moonblade_second.size = Vector2(96.0, 132.0)
	moonblade_second.global_position = Vector2(820.0, 360.0)
	await provider.play_moonblade(
		effect_root,
		effect_root,
		moonblade_caster,
		moonblade_first,
		moonblade_second
	)
	moonblade_caster.free()
	moonblade_first.free()
	moonblade_second.free()
	await process_frame
	_assert_no_children(effect_root, "moonblade_chain")

	var spring_target := Card.new()
	spring_target.size = Vector2(96.0, 132.0)
	spring_target.global_position = Vector2(820.0, 270.0)
	await provider.play_from_rect(
		effect_root,
		effect_root,
		Rect2(Vector2(180.0, 280.0), Vector2(96.0, 132.0)),
		spring_target,
		"tranquil_spring"
	)
	spring_target.free()
	await process_frame
	_assert_no_children(effect_root, "tranquil_spring_transfer")

	await provider.play_multi_rect(
		effect_root,
		effect_root,
		[
			Rect2(Vector2(120.0, 120.0), Vector2(90.0, 126.0)),
			Rect2(Vector2(760.0, 120.0), Vector2(90.0, 126.0))
		],
		"meteor_strike"
	)
	await process_frame
	_assert_no_children(effect_root, "meteor_strike_multi_rect")

	for time_animation_key in [
		"night_elf_time_transition",
		"night_elf_time_transition_sunrise",
		"night_elf_time_transition_noon",
		"night_elf_time_transition_dusk",
		"night_elf_time_transition_moonrise",
		"night_elf_time_transition_full_moon",
		"night_elf_time_transition_moonset"
	]:
		await provider.play_board(
			effect_root,
			effect_root,
			time_animation_key
		)
		await process_frame
		_assert_no_children(effect_root, time_animation_key)

	var state := CardState.new()
	var card_data := CardData.new()
	card_data.id = "night_elf_overlay_test"
	card_data.type = CardData.TYPE_MINION
	card_data.health = 5
	state.set_card_data(card_data)
	state.set_face_up(true)
	var precision_status := CardStatus.new()
	precision_status.status_id = CardStatus.STATUS_PRECISION_SHOT
	state.add_status(precision_status)
	var meteor_status := CardStatus.new()
	meteor_status.status_id = CardStatus.STATUS_METEOR_AURA
	state.add_status(meteor_status)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)
	if not overlay.visible or not overlay.is_processing():
		push_error("Night Elf persistent overlays did not enable animated refresh")
		quit(1)
		return

	state.remove_status(CardStatus.STATUS_PRECISION_SHOT)
	overlay.refresh()
	if not overlay.is_processing():
		push_error("Meteor aura did not keep the overlay animation active")
		quit(1)
		return

	state.remove_status(CardStatus.STATUS_METEOR_AURA)
	overlay.refresh()
	if overlay.is_processing():
		push_error("Night Elf overlays kept processing after all statuses were removed")
		quit(1)
		return
	overlay.queue_free()

	effect_root.queue_free()
	await process_frame
	print("NIGHT_ELF_ANIMATION_TESTS_OK")
	quit()


func _assert_no_children(effect_root: Control, animation_key: String) -> void:
	if effect_root.get_child_count() != 0:
		push_error(
			"Night Elf animation leaked nodes after %s: %d"
			% [animation_key, effect_root.get_child_count()]
		)
		quit(1)
