extends SceneTree

const MiaoAnimationProviderScript := preload(
	"res://scripts/ui/animation/miao_animation_provider.gd"
)
const StatusModifierResolverScript := preload(
	"res://scripts/game/status_modifier_resolver.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "MiaoAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := MiaoAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))
	var animation_keys: Array[String] = [
		"medical_practice",
		"gu_herb_poison",
		"gu_infusion",
		"gu_lure",
		"gu_life_link_larva",
		"gu_life_link",
		"gu_life_link_death",
		"thin_burial",
		"thin_burial_release",
		"thin_burial_break",
		"gu_summon",
		"gu_scorpion_breeding",
		"gu_trap_trigger",
		"gu_snake_venom_apply",
		"gu_devour",
		"gu_venom_inject",
		"gu_venom_burst",
		"gu_scorpion_venom_apply",
		"gu_king_venom_apply",
		"gu_poison_tick_scorpion",
		"gu_poison_tick_snake",
		"gu_poison_tick_king",
		"gu_poison_burst"
	]

	for animation_key in animation_keys:
		await provider.play_at_rect(effect_root, effect_root, target_rect, animation_key)
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error(
				"Miao animation leaked nodes after %s: %d"
				% [animation_key, effect_root.get_child_count()]
			)
			quit(1)
			return

	var target_rects: Array[Rect2] = [
		Rect2(Vector2(380.0, 260.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(700.0, 260.0), Vector2(120.0, 168.0))
	]
	for animation_key in MiaoAnimationProvider.MULTI_RECT_KEYS:
		await provider.play_multi_rect(effect_root, effect_root, target_rects, animation_key)
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error(
				"Miao multi-target animation leaked nodes after %s: %d"
				% [animation_key, effect_root.get_child_count()]
			)
			quit(1)
			return

	var first_card := Card.new()
	first_card.position = Vector2(360.0, 260.0)
	first_card.size = Vector2(120.0, 168.0)
	var second_card := Card.new()
	second_card.position = Vector2(760.0, 260.0)
	second_card.size = Vector2(120.0, 168.0)
	for animation_key in ["gu_life_link_larva", "gu_life_link", "gu_life_link_death"]:
		await provider.play_life_link(
			effect_root,
			effect_root,
			first_card,
			second_card,
			{"animation": animation_key}
		)
		await process_frame
		if effect_root.get_child_count() != 0:
			push_error(
				"Miao life-link animation leaked nodes after %s: %d"
				% [animation_key, effect_root.get_child_count()]
			)
			quit(1)
			return
	first_card.free()
	second_card.free()

	if not _test_status_overlays(effect_root):
		quit(1)
		return
	if not _test_poison_compression():
		quit(1)
		return
	if not _test_link_and_slot_animation_metadata():
		quit(1)
		return

	effect_root.queue_free()
	await process_frame
	print("MIAO_ANIMATION_TESTS_OK")
	quit()


func _test_status_overlays(effect_root: Control) -> bool:
	var data := CardData.new()
	data.id = "miao_overlay_test"
	data.type = CardData.TYPE_MINION
	data.attack = 4
	data.health = 10
	var state := CardState.new()
	state.set_card_data(data)
	state.set_face_up(true)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)

	var statuses: Array[CardStatus] = []
	statuses.append(_create_status(CardStatus.STATUS_ENCOURAGE_GU))
	statuses.append(_create_status(CardStatus.STATUS_SNAKE_VENOM, 3))
	var larva := _create_status(CardStatus.STATUS_LIFE_LINK_LARVA)
	larva.payload[EffectData.KEY_LINK_ID] = "miao:test:larva"
	statuses.append(larva)
	var link := _create_status(CardStatus.STATUS_LIFE_LINK)
	link.payload[EffectData.KEY_LINK_ID] = "miao:test:mature"
	statuses.append(link)
	var burial := _create_status(CardStatus.STATUS_DEATH_IMMUNITY, 4)
	burial.tags = [CardStatus.TAG_DEATH_PREVENTION]
	statuses.append(burial)
	var devour := _create_status(CardStatus.STATUS_DEVOUR)
	devour.stacks = 2
	devour.payload[EffectData.KEY_POISON_ATTACK_LEVEL] = 3
	statuses.append(devour)

	for status in statuses:
		state.add_status(status)
	overlay.refresh()
	if not overlay.visible or not overlay.is_processing():
		push_error("Miao persistent status overlays did not enable animated refresh")
		return false

	for status in statuses:
		state.remove_status_instance(status)
	overlay.refresh()
	if overlay.visible or overlay.is_processing():
		push_error("Miao persistent status overlays did not stop after status removal")
		return false

	overlay.queue_free()
	return true


func _test_poison_compression() -> bool:
	var modifier_resolver := StatusModifierResolverScript.new()
	var poison_effect := {
		EffectData.KEY_STATUS_ID: CardStatus.STATUS_POISON,
		EffectData.KEY_STATUS_DURATION_TURNS: 3,
		EffectData.KEY_STATUS_PAYLOAD: {
			EffectData.KEY_POISON_DAMAGE: 2,
			EffectData.KEY_TICK_ANIMATION: "gu_poison_tick_snake"
		}
	}
	var modifier := {
		EffectData.KEY_SET_DURATION_TURNS: 1,
		EffectData.KEY_PRESERVE_TOTAL_DAMAGE: true
	}
	var compressed := modifier_resolver.apply_modifier(poison_effect, modifier)
	var payload := EffectData.get_status_payload(compressed)
	if int(payload.get(EffectData.KEY_POISON_DAMAGE, 0)) != 6:
		push_error("Poison compression did not preserve total damage")
		return false
	if not bool(payload.get(EffectData.KEY_STATUS_COMPRESSED, false)):
		push_error("Poison compression did not publish its visual marker")
		return false

	var poison := CardStatus.new()
	poison.status_id = CardStatus.STATUS_POISON
	poison.payload = payload
	var status_resolver := StatusResolver.new()
	if status_resolver.get_poison_tick_animation(poison) != "gu_poison_burst":
		push_error("Compressed poison did not select the burst animation")
		return false
	return true


func _test_link_and_slot_animation_metadata() -> bool:
	var first_data := CardData.new()
	first_data.id = "miao_link_first"
	first_data.type = CardData.TYPE_MINION
	first_data.health = 4
	var second_data := CardData.new()
	second_data.id = "miao_link_second"
	second_data.type = CardData.TYPE_MINION
	second_data.health = 4
	var first_state := CardState.new()
	first_state.set_card_data(first_data)
	first_state.owner_id = "player_1"
	var second_state := CardState.new()
	second_state.set_card_data(second_data)
	second_state.owner_id = "player_2"

	var status_resolver := StatusResolver.new()
	status_resolver.apply_mature_life_link_status(
		first_state,
		second_state,
		"miao:test:death",
		"player_1",
		"gu_life_link_death"
	)
	var link_status := first_state.get_status(CardStatus.STATUS_LIFE_LINK)
	if link_status == null:
		push_error("Mature life link did not create its status")
		return false
	var trigger_effects: Array = link_status.payload.get(EffectData.KEY_STATUS_TRIGGER_EFFECTS, [])
	if trigger_effects.is_empty():
		push_error("Mature life link did not create its death trigger")
		return false
	if str(trigger_effects[0].get(EffectData.KEY_ANIMATION, "")) != "gu_life_link_death":
		push_error("Life-link death trigger lost its animation metadata")
		return false

	var slot_effect := BoardSlotEffect.from_effect_data(
		7,
		{
			EffectData.KEY_SLOT_EFFECT_ID: BoardSlotEffect.EFFECT_KILL_ENTERING_MINION,
			EffectData.KEY_PERSISTENT_ANIMATION: "gu_lure_waiting",
			EffectData.KEY_TRIGGER_ANIMATION: "gu_trap_trigger"
		},
		null
	)
	if slot_effect.persistent_animation != "gu_lure_waiting":
		push_error("Gu lure slot effect lost its owner-visible marker metadata")
		return false
	if slot_effect.trigger_animation != "gu_trap_trigger":
		push_error("Gu lure slot effect lost its trigger animation metadata")
		return false
	return true


func _create_status(status_id: String, remaining_turns := -1) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = status_id
	status.is_permanent = remaining_turns < 0
	status.remaining_turns = remaining_turns
	status.source_card_id = "miao_test_source"
	status.source_owner_id = "player_1"
	status.duration_owner_id = "player_1"
	return status
