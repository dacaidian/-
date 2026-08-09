extends SceneTree

const SymbioteAnimationProviderScript := preload(
	"res://scripts/ui/animation/symbiote_animation_provider.gd"
)
const SymbioteSeveranceVisualScript := preload(
	"res://scripts/ui/animation/symbiote_severance_visual.gd"
)
const SpellAnimationRouterScript := preload(
	"res://scripts/ui/animation/spell_animation_router.gd"
)

const PROGRESS_SAMPLES: Array[float] = [
	0.0, 0.001, 0.01, 0.12, 0.35, 0.61, 0.86, 1.0,
]


class PresentationProbe:
	extends Node

	var board_states: Array[CardState] = []
	var card_database: CardDatabase
	var player: PlayerState
	var calls: Array[String] = []

	func get_all_board_states() -> Array[CardState]:
		return board_states

	func get_card_data_by_id(card_id: String) -> CardData:
		return card_database.get_card(card_id) if card_database != null else null

	func get_player_by_id(player_id: String) -> PlayerState:
		return player if player != null and player.id == player_id else null

	func play_spell_cast_animation(
		_source_state: CardState,
		_target_state: CardState,
		spell_data: Dictionary
	) -> void:
		calls.append("source_to_target:%s" % str(spell_data.get("animation", "")))

	func play_status_apply_animation(
		_target_state: CardState,
		animation_key: String
	) -> void:
		calls.append("target:%s" % animation_key)

	func resolve_dead_states(
		_target_states: Array[CardState],
		_reason: String = "",
		_source_state: CardState = null,
		_owner_id: String = "",
		_slot_claim: Dictionary = {}
	) -> void:
		calls.append("resolve_dead")


class LethalSpellGameManager:
	extends GameManager

	var death_calls := 0

	func play_status_apply_animation(
		_target_state: CardState,
		_animation_key: String
	) -> void:
		pass

	func resolve_dead_states(
		states_to_check: Array,
		_reason: String = "damage",
		_source_state: CardState = null,
		_source_owner_id := "",
		_death_slot_claim: Dictionary = {}
	) -> bool:
		death_calls += 1
		for raw_state in states_to_check:
			var state := raw_state as CardState
			if state != null and state.current_health <= 0:
				var owner := get_player_by_id(state.owner_id)
				if owner != null and state.is_hero():
					owner.add_to_hand_with_cooldown(
						state.data,
						3,
						HandCardState.SOURCE_HERO_REVIVE,
						["hero_revive"],
						state.permanent_stat_overrides
					)
				state.clear_card()
		return true

	func update_hand_drawer_view() -> void:
		pass

	func refresh_debug_panel() -> void:
		pass

	func resolve_after_spell_cast(
		_owner_id: String,
		_caster_state: CardState,
		_spell_data: Dictionary
	) -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_database := CardDatabase.new()
	if not card_database.load_from_json("res://data/cards.json"):
		_fail("Could not load card data")
		return
	if not _test_card_configuration(card_database):
		return
	if not _test_permanent_attack_math(card_database):
		return
	if not await _test_lethal_self_severance(card_database):
		return
	if not await _test_effect_chains(card_database):
		return
	if not await _test_visual_frames():
		return
	if not await _test_provider_routes():
		return

	print("SYMBIOTE_TESTS_OK")
	quit()


func _test_card_configuration(card_database: CardDatabase) -> bool:
	var venom := card_database.get_card("venom")
	var agent := card_database.get_card("symbiote_shield_agent")
	var biologist := card_database.get_card("symbiote_biologist")
	var xenophage := card_database.get_card("xenophage")
	var warrior := card_database.get_card("genetic_warrior")
	var tissue := card_database.get_card("symbiote_tissue")
	if venom == null or agent == null or biologist == null or xenophage == null or warrior == null or tissue == null:
		return _fail("Symbiote card framework is incomplete")
	if venom.attack != 2 or venom.health != 20 or venom.role != CardData.ROLE_HERO:
		return _fail("Venom stats or hero role changed")
	if agent.level != 1 or agent.count != 5 or agent.attack != 1 or agent.health != 5 or not agent.has_keyword(CardData.KEYWORD_RANGED):
		return _fail("Symbiote SHIELD agent configuration is invalid")
	if biologist.level != 2 or biologist.count != 5 or biologist.attack != 2 or biologist.health != 6 or not biologist.has_keyword(CardData.KEYWORD_RANGED):
		return _fail("Symbiote biologist configuration is invalid")
	if xenophage.level != 2 or xenophage.count != 3 or xenophage.attack != 3 or xenophage.health != 8 or not xenophage.has_keyword(CardData.KEYWORD_GIANT):
		return _fail("Xenophage configuration is invalid")
	if warrior.level != 3 or warrior.count != 4 or warrior.attack != 3 or warrior.health != 7:
		return _fail("Genetic warrior configuration is invalid")
	if tissue.type != CardData.TYPE_SPELL or tissue.count != 0 or not tissue.effects.is_empty():
		return _fail("Symbiote tissue must remain an inert derived spell")

	var self_action := _find_action(venom, "self_severance")
	var artificial_action := _find_action(biologist, "artificial_severance")
	if self_action.is_empty() or artificial_action.is_empty():
		return _fail("A severance spell action is missing")
	if not bool(self_action.get(EffectData.KEY_EFFECT_HANDLES_ANIMATION, false)):
		return _fail("Self-severance would replay a generic cast animation")
	if not bool(artificial_action.get(EffectData.KEY_EFFECT_HANDLES_ANIMATION, false)):
		return _fail("Artificial severance would replay a generic cast animation")
	if _effect_ids(self_action) != ["play_animation", "gain_permanent_attack", "damage", "add_card_to_hand"]:
		return _fail("Self-severance effect order changed")
	if _effect_ids(artificial_action) != ["play_animation", "gain_permanent_attack", "damage", "add_card_to_hand"]:
		return _fail("Artificial severance effect order changed")
	return true


func _test_permanent_attack_math(card_database: CardDatabase) -> bool:
	var venom_state := _make_state(card_database.get_card("venom"), "math_owner", 3)
	venom_state.current_attack = 0
	venom_state.status_attack_floor_debt = -2
	venom_state.add_permanent_attack(1)
	if venom_state.current_attack != 0 or venom_state.status_attack_floor_debt != -1:
		return _fail("Permanent attack bypassed an active negative attack modifier")
	if int(venom_state.permanent_stat_overrides.get("attack", 0)) != 3:
		return _fail("Permanent attack override did not grow from the printed value")

	venom_state.add_permanent_attack(2)
	if venom_state.current_attack != 1 or venom_state.status_attack_floor_debt != 0:
		return _fail("Permanent attack did not correctly overcome attack floor debt")
	if int(venom_state.permanent_stat_overrides.get("attack", 0)) != 5:
		return _fail("Repeated permanent attack growth did not stack")

	venom_state.status_attack_override = 4
	venom_state.attack_before_status_override_raw = 1
	venom_state.current_attack = 4
	venom_state.add_permanent_attack(1)
	if venom_state.current_attack != 4 or venom_state.attack_before_status_override_raw != 2:
		return _fail("Permanent attack broke an active fixed attack override")
	return true


func _test_lethal_self_severance(card_database: CardDatabase) -> bool:
	var player := PlayerState.new()
	player.setup("lethal_owner", "Lethal Owner")
	player.set_faction("symbiote", "Symbiote")

	var game_manager := LethalSpellGameManager.new()
	game_manager.players = [player]
	game_manager.card_database = card_database
	var venom_state := _make_state(card_database.get_card("venom"), player.id, 4)
	venom_state.damage_taken = 18
	var action := SpellAction.new().setup(_find_action(venom_state.data, "self_severance"))

	await action.execute(venom_state, null, game_manager)
	if not venom_state.is_empty() or game_manager.death_calls != 1:
		return _fail("Lethal self-severance did not clear Venom")
	if player.hand.size() != 2:
		return _fail("Lethal self-severance did not preserve both revival and tissue cards")
	if _hand_card_id(player.hand[0]) != "venom" or _hand_card_id(player.hand[1]) != "symbiote_tissue":
		return _fail("Lethal self-severance lost its effect owner before adding tissue")
	var revived_venom := player.hand[0] as HandCardState
	if revived_venom == null or int(revived_venom.permanent_stat_overrides.get("attack", 0)) != 3:
		return _fail("Venom lost permanent severance attack growth on death")
	if is_instance_valid(game_manager.audio_manager):
		game_manager.audio_manager.free()
	game_manager.free()
	return true


func _test_effect_chains(card_database: CardDatabase) -> bool:
	var player := PlayerState.new()
	player.setup("player_one", "Player One")
	player.set_faction("symbiote", "共生体")

	var venom_state := _make_state(card_database.get_card("venom"), player.id, 8)
	var biologist_state := _make_state(card_database.get_card("symbiote_biologist"), player.id, 9)
	var probe := PresentationProbe.new()
	probe.card_database = card_database
	probe.player = player
	probe.board_states = [venom_state, biologist_state]
	root.add_child(probe)

	var registry := EffectRegistry.new()
	var self_action := _find_action(venom_state.data, "self_severance")
	await _execute_effect_chain(registry, venom_state, self_action, probe)
	if venom_state.current_health != 18:
		return _fail("Self-severance did not deal exactly 2 damage")
	if venom_state.current_attack != 3 or int(venom_state.permanent_stat_overrides.get("attack", 0)) != 3:
		return _fail("Self-severance did not grant permanent attack")
	if player.hand.size() != 1 or _hand_card_id(player.hand[0]) != "symbiote_tissue":
		return _fail("Self-severance did not add one Symbiote Tissue")
	if probe.calls != ["target:symbiote_self_severance", "resolve_dead"]:
		return _fail("Self-severance presentation or damage order changed")

	probe.calls.clear()
	var artificial_action := _find_action(biologist_state.data, "artificial_severance")
	var artificial_effects: Array = artificial_action.get("effects", [])
	var presentation_effect := artificial_effects[0] as Dictionary
	probe.board_states = [biologist_state]
	if registry.can_execute_effect(biologist_state, presentation_effect, probe):
		return _fail("Artificial severance remains available without Venom")

	probe.board_states = [venom_state, biologist_state]
	await _execute_effect_chain(registry, biologist_state, artificial_action, probe)
	if venom_state.current_health != 16:
		return _fail("Artificial severance did not deal exactly 2 damage to Venom")
	if venom_state.current_attack != 4 or int(venom_state.permanent_stat_overrides.get("attack", 0)) != 4:
		return _fail("Artificial severance did not stack permanent attack")
	if player.hand.size() != 2 or _hand_card_id(player.hand[1]) != "symbiote_tissue":
		return _fail("Artificial severance did not add one Symbiote Tissue")
	if probe.calls != ["source_to_target:symbiote_artificial_severance", "resolve_dead"]:
		return _fail("Artificial severance presentation or damage order changed")

	probe.queue_free()
	await process_frame
	return true


func _test_visual_frames() -> bool:
	var effect_root := Control.new()
	effect_root.name = "SymbioteVisualTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	for animation_key in ["symbiote_self_severance", "symbiote_artificial_severance"]:
		for progress_sample in PROGRESS_SAMPLES:
			var visual := SymbioteSeveranceVisualScript.new()
			visual.size = effect_root.size
			effect_root.add_child(visual)
			visual.configure(
				animation_key,
				Vector2(280.0, 500.0),
				Vector2(850.0, 260.0),
				Vector2(120.0, 168.0),
				Vector2(120.0, 168.0)
			)
			visual.progress = progress_sample
			visual.queue_redraw()
			await process_frame
			visual.queue_free()
			await process_frame
			if effect_root.get_child_count() != 0:
				return _fail("Symbiote visual leaked nodes at %s:%s" % [animation_key, progress_sample])

	effect_root.queue_free()
	await process_frame
	return true


func _test_provider_routes() -> bool:
	var effect_root := Control.new()
	effect_root.name = "SymbioteProviderTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := SymbioteAnimationProviderScript.new()
	provider.setup(0.01)
	var router := SpellAnimationRouterScript.new()
	provider.register_routes(router)
	if not router.has_rect_route("symbiote_self_severance"):
		return _fail("Self-severance rect route is missing")
	if not router.has_targeted_route("symbiote_artificial_severance"):
		return _fail("Artificial severance targeted route is missing")

	var source_rect := Rect2(Vector2(250.0, 450.0), Vector2(120.0, 168.0))
	var target_rect := Rect2(Vector2(820.0, 210.0), Vector2(120.0, 168.0))
	await provider.play_at_rect(
		effect_root,
		effect_root,
		target_rect,
		"symbiote_self_severance"
	)
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Self-severance provider leaked its visual")

	var target_card := Card.new()
	target_card.position = target_rect.position
	target_card.size = target_rect.size
	await provider.play_from_rect(
		effect_root,
		effect_root,
		source_rect,
		target_card,
		"symbiote_artificial_severance"
	)
	target_card.free()
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Artificial severance provider leaked its visual")

	effect_root.queue_free()
	await process_frame
	return true


func _execute_effect_chain(
	registry: EffectRegistry,
	source_state: CardState,
	action_data: Dictionary,
	probe: PresentationProbe
) -> void:
	for raw_effect in action_data.get("effects", []):
		var runtime_effect := (raw_effect as Dictionary).duplicate(true)
		EffectData.mark_effect_owner(runtime_effect, source_state.owner_id)
		await registry.execute_effect(source_state, runtime_effect, probe)


func _find_action(card_data: CardData, action_id: String) -> Dictionary:
	if card_data == null:
		return {}
	for raw_action in card_data.spell_actions:
		var action_data := raw_action as Dictionary
		if str(action_data.get("id", "")) == action_id:
			return action_data
	return {}


func _effect_ids(action_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for raw_effect in action_data.get("effects", []):
		ids.append(str((raw_effect as Dictionary).get("id", "")))
	return ids


func _make_state(card_data: CardData, owner_id: String, slot_index: int) -> CardState:
	var state := CardState.new()
	state.set_card_data(card_data)
	state.owner_id = owner_id
	state.slot_index = slot_index
	state.set_face_up(true)
	return state


func _hand_card_id(hand_entry: Variant) -> String:
	if hand_entry is CardData:
		return (hand_entry as CardData).id
	if hand_entry is HandCardState:
		var hand_state := hand_entry as HandCardState
		return hand_state.data.id if hand_state.data != null else ""
	return ""


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
