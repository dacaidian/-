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
		"faith_light",
		"healing_to_resolve",
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

	var formation_rects: Array[Rect2] = [
		Rect2(Vector2(380.0, 260.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(700.0, 260.0), Vector2(120.0, 168.0))
	]
	await provider.play_multi_rect(
		effect_root,
		effect_root,
		formation_rects,
		"faith_light"
	)
	await process_frame
	if effect_root.get_child_count() != 0:
		push_error(
			"Silver Hand synchronized formation animation leaked nodes: %d"
			% effect_root.get_child_count()
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

	var prevented_ids: Array[String] = []
	var prevented_amounts: Array[int] = []
	shield_state.damage_prevented.connect(
		func(_changed_state: CardState, prevention_id: String, prevented_amount: int) -> void:
			prevented_ids.append(prevention_id)
			prevented_amounts.append(prevented_amount)
	)
	shield_state.take_damage(5)
	status_overlay.refresh()
	if shield_state.damage_taken != 0:
		push_error("Divine Shield did not prevent the complete damage instance")
		quit(1)
		return
	if shield_state.has_status(CardStatus.STATUS_DIVINE_SHIELD):
		push_error("Divine Shield was not consumed after preventing damage")
		quit(1)
		return
	if prevented_ids != [CardStatus.STATUS_DIVINE_SHIELD]:
		push_error("Divine Shield did not emit the expected prevention event")
		quit(1)
		return
	if prevented_amounts != [5]:
		push_error("Divine Shield prevention event reported an incorrect amount")
		quit(1)
		return
	if status_overlay.is_processing():
		push_error("Divine Shield overlay kept processing after the status was removed")
		quit(1)
		return

	var vitality_status := CardStatus.new()
	vitality_status.status_id = CardStatus.STATUS_POWER_WORD_SHIELD
	vitality_status.stacks = 3
	shield_state.add_status(vitality_status)
	status_overlay.refresh()
	if not status_overlay.visible or not status_overlay.is_processing():
		push_error("Power Word: Shield overlay did not enable its layered refresh")
		quit(1)
		return

	shield_state.remove_status(CardStatus.STATUS_POWER_WORD_SHIELD)
	status_overlay.refresh()
	status_overlay.play_divine_shield_break()
	if not status_overlay.visible or not status_overlay.is_processing():
		push_error("Divine Shield break feedback did not start")
		quit(1)
		return
	await create_timer(0.65).timeout
	if status_overlay.is_divine_shield_break_active() or status_overlay.is_processing():
		push_error("Divine Shield break feedback did not stop after its duration")
		quit(1)
		return

	status_overlay.queue_free()
	await process_frame

	effect_root.queue_free()
	await process_frame
	print("SILVER_HAND_ANIMATION_TESTS_OK")
	quit()
