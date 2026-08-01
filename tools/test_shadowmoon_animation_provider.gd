extends SceneTree

const ShadowmoonAnimationProviderScript := preload(
	"res://scripts/ui/animation/shadowmoon_animation_provider.gd"
)
const ShadowmoonTargetVisualScript := preload(
	"res://scripts/ui/animation/shadowmoon_target_visual.gd"
)
const ShadowmoonRitualVisualScript := preload(
	"res://scripts/ui/animation/shadowmoon_ritual_visual.gd"
)

const TARGET_VISUAL_KEYS: Array[String] = [
	"fel_sacrifice", "fel_sacrifice_heavy", "fel_infusion_transfer",
	"fel_infusion_settle", "fel_overload_transfer", "fel_overload_settle",
	"fel_overload_detonate", "fel_burst_impact", "mana_burn", "fel_bite",
	"life_drain", "life_drain_receive", "curse_cast", "curse_mark", "curse_impact",
	"fel_madness_chaos_orc", "fel_madness_hellhound", "fel_madness_succubus",
	"fel_madness_wolf_rider", "fel_madness_doomguard", "fel_madness_warlock",
	"kiljaeden_whisper_mark", "immolation_mark", "immolation_tick",
]
const RITUAL_VISUAL_KEYS: Array[String] = [
	"fel_madness_broadcast", "demon_summon", "dark_portal", "immolation_cast",
	"kiljaeden_whisper_mark", "immolation_mark", "fel_burst_impact",
	"fel_madness_chaos_orc", "fel_madness_hellhound", "fel_madness_succubus",
	"fel_madness_wolf_rider", "fel_madness_doomguard", "fel_madness_warlock",
]


class PresentationProbe:
	extends Node

	var board_states: Array[CardState] = []
	var calls: Array[String] = []

	func get_all_board_states() -> Array[CardState]:
		return board_states

	func play_board_effect_animation(animation_key: String) -> void:
		calls.append("board:%s" % animation_key)

	func play_multi_target_effect_animation(
		target_states: Array[CardState],
		animation_key: String
	) -> bool:
		calls.append("multi:%s:%d" % [animation_key, target_states.size()])
		return true

	func play_spell_cast_animation(
		_source_state: CardState,
		_target_state: CardState,
		spell_data: Dictionary
	) -> void:
		calls.append("source_to_target:%s" % str(spell_data.get("animation", "")))

	func play_status_apply_animation(_target_state: CardState, animation_key: String) -> void:
		calls.append("target:%s" % animation_key)

	func resolve_dead_states(
		_target_states: Array[CardState],
		_reason: String = "",
		_source_state: CardState = null,
		_owner_id: String = "",
		_slot_claim: Dictionary = {}
	) -> void:
		calls.append("resolve_dead")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "ShadowmoonAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	if not await _test_visual_frames(effect_root):
		return
	if not await _test_provider_lifecycle(effect_root):
		return
	if not await _test_status_overlays(effect_root):
		return
	if not await _test_presentation_contracts():
		return
	if not _test_once_per_turn_trigger_groups():
		return
	if not _test_card_configuration():
		return

	effect_root.queue_free()
	await process_frame
	print("SHADOWMOON_ANIMATION_TESTS_OK")
	quit()


func _test_visual_frames(effect_root: Control) -> bool:
	for animation_key in TARGET_VISUAL_KEYS:
		var visual := ShadowmoonTargetVisualScript.new()
		visual.size = effect_root.size
		visual.configure(
			animation_key,
			Vector2(250.0, 480.0),
			Vector2(920.0, 230.0),
			Vector2(120.0, 168.0),
			Vector2(120.0, 168.0)
		)
		visual.progress = 0.58
		effect_root.add_child(visual)
		await process_frame
		visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Shadowmoon target visual leaked nodes after %s" % animation_key)

	var target_rects: Array[Rect2] = [
		Rect2(Vector2(420.0, 190.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(610.0, 250.0), Vector2(120.0, 168.0)),
		Rect2(Vector2(800.0, 180.0), Vector2(120.0, 168.0)),
	]
	for animation_key in RITUAL_VISUAL_KEYS:
		var visual := ShadowmoonRitualVisualScript.new()
		visual.size = effect_root.size
		visual.configure(
			animation_key,
			Vector2(280.0, 510.0),
			Vector2(250.0, 660.0),
			Rect2(Vector2(110.0, 70.0), Vector2(1040.0, 560.0)),
			Vector2(120.0, 168.0),
			target_rects
		)
		visual.progress = 0.61
		effect_root.add_child(visual)
		await process_frame
		visual.queue_free()
		await process_frame
		if effect_root.get_child_count() != 0:
			return _fail("Shadowmoon ritual visual leaked nodes after %s" % animation_key)
	return true


func _test_once_per_turn_trigger_groups() -> bool:
	var ledger := TurnEventLedger.new()
	var resolver := SpellCastTriggerResolver.new()
	var grouped_effects: Array[Dictionary] = [
		{EffectData.KEY_ONCE_PER_TURN_GROUP: "shadowmoon_fel_madness"},
		{EffectData.KEY_ONCE_PER_TURN_GROUP: "shadowmoon_fel_madness"},
	]
	ledger.begin_turn("player_one")
	var first_permissions := resolver.claim_once_per_turn_groups(
		ledger,
		"player_one",
		grouped_effects
	)
	if not bool(first_permissions.get("shadowmoon_fel_madness", false)):
		return _fail("Fel Madness did not activate on the first fel cast")
	var repeated_permissions := resolver.claim_once_per_turn_groups(
		ledger,
		"player_one",
		grouped_effects
	)
	if bool(repeated_permissions.get("shadowmoon_fel_madness", false)):
		return _fail("Fel Madness activated more than once in the same turn")
	var other_owner_permissions := resolver.claim_once_per_turn_groups(
		ledger,
		"player_two",
		grouped_effects
	)
	if not bool(other_owner_permissions.get("shadowmoon_fel_madness", false)):
		return _fail("Once-per-turn trigger groups are not isolated by owner")

	ledger.begin_turn("player_two")
	var next_turn_permissions := resolver.claim_once_per_turn_groups(
		ledger,
		"player_one",
		grouped_effects
	)
	if not bool(next_turn_permissions.get("shadowmoon_fel_madness", false)):
		return _fail("Fel Madness did not reset when a new turn began")
	return true


func _test_provider_lifecycle(effect_root: Control) -> bool:
	var provider := ShadowmoonAnimationProviderScript.new()
	provider.setup(0.01)
	var source_rect := Rect2(Vector2(260.0, 420.0), Vector2(120.0, 168.0))
	var target_rect := Rect2(Vector2(830.0, 210.0), Vector2(120.0, 168.0))

	var target_card := _make_card(target_rect)
	await provider.play_from_rect(effect_root, effect_root, source_rect, target_card, "life_drain")
	target_card.free()
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Shadowmoon provider leaked a completed target visual")

	await provider.play_at_rect(effect_root, effect_root, source_rect, "dark_portal")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Shadowmoon provider leaked a completed ritual visual")

	await provider.play_board(effect_root, effect_root, "fel_madness_broadcast")
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Shadowmoon provider leaked a completed battlefield visual")

	var target_rects: Array[Rect2] = [source_rect, target_rect]
	await provider.play_multi_rect(effect_root, effect_root, target_rects, "fel_madness_hellhound")
	await process_frame
	return effect_root.get_child_count() == 0 or _fail("Shadowmoon provider leaked a multi-target visual")


func _test_status_overlays(effect_root: Control) -> bool:
	var card_data := CardData.new()
	card_data.id = "shadowmoon_status_test"
	card_data.type = CardData.TYPE_MINION
	card_data.faction_id = "shadowmoon_council"
	card_data.health = 12
	var state := CardState.new()
	state.set_card_data(card_data)
	state.set_face_up(true)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)

	for status_id in [
		CardStatus.STATUS_FEL_INFUSION,
		CardStatus.STATUS_FEL_OVERLOAD,
		CardStatus.STATUS_FEL_MADNESS_HELLHOUND,
		CardStatus.STATUS_KILJAEDEN_WHISPER,
	]:
		var status := CardStatus.new()
		status.status_id = status_id
		status.is_permanent = false
		status.remaining_turns = 1
		state.add_status(status)
		overlay.refresh()
		await process_frame
		if not overlay.visible or not overlay.is_processing():
			return _fail("Shadowmoon status overlay is not animated for %s" % status_id)
		state.remove_status(status_id)

	var fire := CardStatus.new()
	fire.status_id = CardStatus.STATUS_FIRE
	fire.source_card_id = "infernal"
	fire.is_permanent = false
	fire.remaining_turns = 2
	fire.payload = {EffectData.KEY_FIRE_DAMAGE: 3}
	state.add_status(fire)
	overlay.refresh()
	await process_frame
	if not overlay.visible or not overlay.is_processing():
		return _fail("Infernal fire overlay is not animated")

	overlay.queue_free()
	await process_frame
	return true


func _test_presentation_contracts() -> bool:
	var probe := PresentationProbe.new()
	root.add_child(probe)
	var source := _make_state("presentation_source", "player_one", 10)
	var ally := _make_state("presentation_ally", "player_one", 10)
	probe.board_states = [source, ally]
	var registry := EffectRegistry.new()

	var transfer_effect := {
		EffectData.KEY_ID: EffectData.EFFECT_PLAY_ANIMATION,
		EffectData.KEY_TARGET: EffectData.TARGET_SELECTED,
		EffectData.KEY_ANIMATION: "fel_infusion_transfer",
		EffectData.KEY_PRESENTATION_SCOPE: EffectData.PRESENTATION_SCOPE_SOURCE_TO_TARGET,
	}
	EffectData.mark_selected_target(transfer_effect, ally)
	if not registry.can_execute_effect(source, transfer_effect, probe):
		return _fail("Explicit source-to-target presentation step is not executable")
	await registry.execute_effect(source, transfer_effect, probe)
	if probe.calls != ["source_to_target:fel_infusion_transfer"]:
		return _fail("Explicit source-to-target presentation was routed incorrectly")

	probe.calls.clear()
	await registry.execute_effect(source, {
		EffectData.KEY_ID: EffectData.EFFECT_PLAY_ANIMATION,
		EffectData.KEY_ANIMATION: "fel_madness_broadcast",
		EffectData.KEY_PRESENTATION_SCOPE: EffectData.PRESENTATION_SCOPE_BOARD,
	}, probe)
	if probe.calls != ["board:fel_madness_broadcast"]:
		return _fail("Explicit board presentation was routed incorrectly")

	probe.calls.clear()
	await ApplyStatusEffect.new().execute(source, {
		EffectData.KEY_ID: EffectData.EFFECT_APPLY_STATUS,
		EffectData.KEY_TARGET: EffectData.TARGET_FRIENDLY_MINIONS,
		EffectData.KEY_STATUS_ID: "shadowmoon_grouped_status_test",
		EffectData.KEY_STATUS_DURATION_TURNS: 1,
		"apply_animation": "fel_madness_chaos_orc",
		EffectData.KEY_PRESENTATION_SCOPE: EffectData.PRESENTATION_SCOPE_MULTI,
	}, probe)
	if not source.has_status("shadowmoon_grouped_status_test") or not ally.has_status("shadowmoon_grouped_status_test"):
		return _fail("Grouped status presentation changed the resolved target set")
	if probe.calls != ["multi:fel_madness_chaos_orc:2"]:
		return _fail("Grouped status presentation repeated or fell back per target")

	probe.calls.clear()
	var source_health := source.current_health
	var ally_health := ally.current_health
	await DamageEffect.new().execute(source, {
		EffectData.KEY_ID: "damage",
		EffectData.KEY_TARGET: EffectData.TARGET_FRIENDLY_MINIONS,
		EffectData.KEY_AMOUNT: 1,
		EffectData.KEY_SPELL_POWER_SCALING: false,
		EffectData.KEY_ANIMATION: "fel_burst_impact",
		EffectData.KEY_PRESENTATION_SCOPE: EffectData.PRESENTATION_SCOPE_MULTI,
	}, probe)
	if source.current_health != source_health - 1 or ally.current_health != ally_health - 1:
		return _fail("Grouped damage presentation changed damage resolution")
	if probe.calls != ["multi:fel_burst_impact:2", "resolve_dead"]:
		return _fail("Grouped damage presentation repeated or changed death ordering")

	probe.queue_free()
	await process_frame
	return true


func _test_card_configuration() -> bool:
	var database := CardDatabase.new()
	if not database.load_from_json("res://data/cards.json"):
		return _fail("Shadowmoon animation test could not load card data")

	var guldan := database.get_card("guldan")
	var madness := database.get_card("fel_madness")
	var siphon := database.get_card("soul_siphon")
	var warlock := database.get_card("warlock")
	var whisper := database.get_card("kiljaeden_whisper")
	var infernal := database.get_card("infernal")
	var staff := database.get_card("staff_of_guldan")
	var portal := database.get_card("dark_portal")
	var summon := database.get_card("demon_summon")
	if null in [guldan, madness, siphon, warlock, whisper, infernal, staff, portal, summon]:
		return _fail("Shadowmoon animation configuration is missing a required card")

	var infusion: Dictionary = guldan.spell_actions[0]
	if not bool(infusion.get("effect_handles_animation", false)):
		return _fail("Fel Infusion does not delegate its ordered presentation to effects")
	var infusion_effects: Array = infusion.get("effects", [])
	if _effect_ids(infusion_effects) != ["damage", "play_animation", "apply_status"]:
		return _fail("Fel Infusion presentation order is not sacrifice -> transfer -> status")
	if str(infusion_effects[0].get("source_animation", "")) != "fel_sacrifice":
		return _fail("Fel Infusion does not show Gul'dan's health sacrifice first")
	if str(infusion_effects[1].get("animation", "")) != "fel_infusion_transfer":
		return _fail("Fel Infusion transfer step is missing")
	if str(infusion_effects[2].get("apply_animation", "")) != "fel_infusion_settle":
		return _fail("Fel Infusion status settlement is missing")

	var madness_effects: Array = madness.effects
	if madness_effects.size() != 7:
		return _fail("Fel Madness must have one broadcast and six unit responses")
	if str(madness_effects[0].get("id", "")) != EffectData.EFFECT_PLAY_ANIMATION:
		return _fail("Fel Madness broadcast is not an explicit presentation step")
	if str(madness_effects[0].get("animation", "")) != "fel_madness_broadcast":
		return _fail("Fel Madness battlefield broadcast is missing")
	var response_keys: Array[String] = []
	var unique_response_keys: Dictionary = {}
	for effect_index in range(madness_effects.size()):
		var response: Dictionary = madness_effects[effect_index]
		if EffectData.get_once_per_turn_group(response) != "shadowmoon_fel_madness":
			return _fail("Fel Madness effects do not share one once-per-turn trigger group")
		if effect_index == 0:
			continue
		if EffectData.get_presentation_scope(response) != EffectData.PRESENTATION_SCOPE_MULTI:
			return _fail("A Fel Madness unit response is not grouped as one multi-target visual")
		var response_key := str(response.get("apply_animation", ""))
		response_keys.append(response_key)
		unique_response_keys[response_key] = true
	if unique_response_keys.size() != 6 or response_keys.has(""):
		return _fail("Fel Madness unit responses are missing dedicated visual keys")

	if str(siphon.effects[0].get("recipient_animation", "")) != "life_drain_receive":
		return _fail("Soul Siphon does not distinguish extraction from reception")
	var curse: Dictionary = warlock.spell_actions[0]
	if str(curse.get("animation", "")) != "curse_cast":
		return _fail("Curse does not use its cast visual")
	if str(curse.get("effects", [])[0].get("apply_animation", "")) != "curse_mark":
		return _fail("Curse does not leave its persistent mark")

	for effect in whisper.effects:
		if str(effect.get("apply_animation", "")) != "kiljaeden_whisper_mark":
			return _fail("Kil'jaeden's Whisper is missing its periodic mark")
		if EffectData.get_presentation_scope(effect) != EffectData.PRESENTATION_SCOPE_MULTI:
			return _fail("Kil'jaeden's Whisper repeats its ritual per target")

	var immolation: Dictionary = infernal.spell_actions[0]
	var fire_effect: Dictionary = immolation.get("effects", [])[0]
	if str(immolation.get("animation", "")) != "immolation_cast":
		return _fail("Immolation does not use its cast visual")
	if str(fire_effect.get("apply_animation", "")) != "immolation_mark":
		return _fail("Immolation does not mark all affected targets")
	if str(fire_effect.get("payload", {}).get("tick_animation", "")) != "immolation_tick":
		return _fail("Infernal fire ticks do not have a configured impact")

	var staff_modifier: Dictionary = staff.effects[0]
	var replacement: Array = staff_modifier.get("replace_effects", [])
	if _effect_ids(replacement) != ["damage", "play_animation", "apply_status"]:
		return _fail("Fel Overload presentation order is not sacrifice -> transfer -> status")
	if str(replacement[0].get("source_animation", "")) != "fel_sacrifice_heavy":
		return _fail("Fel Overload does not show its heavier life payment")
	if str(replacement[1].get("animation", "")) != "fel_overload_transfer":
		return _fail("Fel Overload transfer step is missing")
	var turn_effects: Array = replacement[2].get("payload", {}).get("turn_effects", [])
	if turn_effects.is_empty():
		return _fail("Fel Overload detonation effects are missing")
	if str(turn_effects[0].get("source_animation", "")) != "fel_overload_detonate":
		return _fail("Fel Overload detonation source feedback is missing")
	if str(turn_effects[0].get("animation", "")) != "fel_burst_impact":
		return _fail("Fel Overload adjacent impacts are missing")

	if portal.effects.size() != 2:
		return _fail("Dark Portal must keep reveal and periodic triggers")
	for effect in portal.effects:
		if str(effect.get("animation", "")) != "dark_portal":
			return _fail("A Dark Portal trigger does not use the portal ritual")
	if summon.animation != "demon_summon":
		return _fail("Demon Summon does not use the demonic contract ritual")
	return true


func _make_card(card_rect: Rect2) -> Card:
	var card := Card.new()
	card.position = card_rect.position
	card.size = card_rect.size
	return card


func _make_state(card_id: String, owner_id: String, health: int) -> CardState:
	var card_data := CardData.new()
	card_data.id = card_id
	card_data.type = CardData.TYPE_MINION
	card_data.faction_id = "shadowmoon_council"
	card_data.attack = 2
	card_data.health = health
	var state := CardState.new()
	state.set_card_data(card_data)
	state.owner_id = owner_id
	state.set_face_up(true)
	return state


func _effect_ids(effects: Array) -> Array[String]:
	var ids: Array[String] = []
	for effect_value in effects:
		var effect: Dictionary = effect_value
		ids.append(str(effect.get("id", "")))
	return ids


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
