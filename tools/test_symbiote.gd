extends SceneTree

const SymbioteAnimationProviderScript := preload(
	"res://scripts/ui/animation/symbiote_animation_provider.gd"
)
const SymbioteSeveranceVisualScript := preload(
	"res://scripts/ui/animation/symbiote_severance_visual.gd"
)
const SymbiotePowerVisualScript := preload(
	"res://scripts/ui/animation/symbiote_power_visual.gd"
)
const SpellAnimationRouterScript := preload(
	"res://scripts/ui/animation/spell_animation_router.gd"
)
const AttachSymbioteOffspringEffectScript := preload(
	"res://scripts/effects/attach_symbiote_offspring_effect.gd"
)
const LiberateCardEffectScript := preload(
	"res://scripts/effects/liberate_card_effect.gd"
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


class SymbioteRuleProbe:
	extends GameManager

	var animation_keys: Array[String] = []
	var refilled_slots: Array[int] = []
	var next_offspring_card_id := ""

	func play_card_attack_animation(
		_attacker_state: CardState,
		_target_state: CardState,
		_is_melee_attack := true,
		_attack_animation_key := ""
	) -> void:
		pass

	func play_spell_cast_animation(
		_caster_state: CardState,
		_target_state: CardState,
		spell_data: Dictionary
	) -> void:
		animation_keys.append(str(spell_data.get(EffectData.KEY_ANIMATION, "")))

	func play_status_apply_animation(
		_target_state: CardState,
		animation_key: String
	) -> void:
		animation_keys.append(animation_key)

	func play_multi_target_effect_animation(
		_target_states: Array[CardState],
		animation_key: String
	) -> bool:
		animation_keys.append(animation_key)
		return true

	func resolve_dead_states(
		states_to_check: Array,
		_reason: String = "damage",
		_source_state: CardState = null,
		_source_owner_id := "",
		_death_slot_claim: Dictionary = {}
	) -> bool:
		var destroyed_any := false
		for raw_state in states_to_check:
			var target_state := raw_state as CardState
			if target_state != null and not target_state.is_empty() and target_state.current_health <= 0:
				target_state.clear_card()
				destroyed_any = true
		return destroyed_any

	func resolve_after_attack_triggers(
		_attacker_state: CardState,
		_attacked_state: CardState
	) -> void:
		pass

	func queue_card_trigger(
		_source_state: CardState,
		_trigger: String,
		_context: Dictionary = {}
	) -> void:
		pass

	func resolve_queued_triggers() -> void:
		pass

	func can_place_ground_card_on_slot(slot_index: int) -> bool:
		return slot_index >= 0 and slot_index < board_states.size()

	func swap_board_slot_contents(
		first_state: CardState,
		second_state: CardState,
		_animation_key := ""
	) -> void:
		first_state.swap_card_content_with(second_state)

	func refill_board_slot_from_pool(slot_index: int) -> bool:
		refilled_slots.append(slot_index)
		return true

	func refresh_hand_passives_for_player(
		player_state: PlayerState,
		should_adjust_remaining_flips := false
	) -> void:
		hand_passive_resolver.refresh_player_passives(
			player_state,
			should_adjust_remaining_flips,
			self
		)

	func draw_symbiote_offspring_card_id(_owner_id: String) -> String:
		return next_offspring_card_id

	func update_card_pool_view() -> void:
		pass

	func update_hand_drawer_view() -> void:
		pass

	func refresh_action_available_hints() -> void:
		pass

	func refresh_debug_panel() -> void:
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
	if not await _test_bite_runtime(card_database):
		return
	if not await _test_fear_runtime(card_database):
		return
	if not await _test_terrifying_scream_runtime(card_database):
		return
	if not _test_knull_runtime_rules(card_database):
		return
	if not await _test_codex_zones(card_database):
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
	var bite := card_database.get_card("venom_bite")
	var scream := card_database.get_card("terrifying_scream")
	var codex := card_database.get_card("knull_codex")
	var imprisoned_knull := card_database.get_card("knull_imprisoned")
	var liberated_knull := card_database.get_card("knull_liberated")
	if venom == null or agent == null or biologist == null or xenophage == null or warrior == null or tissue == null or bite == null or scream == null or codex == null or imprisoned_knull == null or liberated_knull == null:
		return _fail("Symbiote card framework is incomplete")
	if venom.attack != 2 or venom.health != 20 or venom.role != CardData.ROLE_HERO:
		return _fail("Venom stats or hero role changed")
	if agent.level != 1 or agent.count != 5 or agent.attack != 1 or agent.health != 5 or not agent.has_keyword(CardData.KEYWORD_RANGED):
		return _fail("Symbiote SHIELD agent configuration is invalid")
	if biologist.level != 2 or biologist.count != 5 or biologist.attack != 2 or biologist.health != 6 or not biologist.has_keyword(CardData.KEYWORD_RANGED):
		return _fail("Symbiote biologist configuration is invalid")
	if xenophage.level != 2 or xenophage.count != 3 or xenophage.attack != 3 or xenophage.health != 8 or not xenophage.has_keyword(CardData.KEYWORD_GIANT):
		return _fail("Xenophage configuration is invalid")
	if warrior.level != 3 or warrior.count != 6 or warrior.attack != 3 or warrior.health != 7:
		return _fail("Genetic warrior configuration is invalid")
	if tissue.type != CardData.TYPE_SPELL or tissue.count != 0:
		return _fail("Symbiote Tissue derived spell configuration is invalid")
	if (
		tissue.target_rule != SpellTargetResolver.TARGET_RULE_FRIENDLY_MINIONS_BY_CARD_IDS
		or tissue.target_card_ids != [
			"symbiote_shield_agent",
			"symbiote_biologist",
			"genetic_warrior",
		]
		or tissue.animation != "symbiote_attachment"
		or tissue.effects.size() != 1
		or EffectData.get_id(tissue.effects[0]) != EffectData.EFFECT_ATTACH_SYMBIOTE_OFFSPRING
	):
		return _fail("Symbiote Tissue attachment rules are incomplete")
	if bite.level != 1 or bite.count != 3 or bite.owner_hero_card_id != "venom":
		return _fail("Venom Bite ownership or card count is invalid")
	if scream.level != 2 or scream.count != 2 or scream.owner_hero_card_id != "venom":
		return _fail("Terrifying Scream ownership or card count is invalid")
	if codex.level != 3 or codex.count != 1 or codex.owner_hero_card_id != "venom":
		return _fail("Knull Codex ownership or card count is invalid")
	if imprisoned_knull.attack != 2 or imprisoned_knull.health != 14 or imprisoned_knull.count != 1:
		return _fail("Imprisoned Knull configuration is invalid")
	if liberated_knull.attack != 4 or liberated_knull.health != 16 or liberated_knull.count != 0:
		return _fail("Liberated Knull configuration is invalid")
	for symbiote_card_id in [
		"venom",
		"symbiote_riot",
		"symbiote_scream",
		"symbiote_lasher",
		"symbiote_extreme",
		"symbiote_devour",
		"anti_venom",
		"symbiote_warrior",
		"symbiote_silence",
		"symbiote_hybrid",
		"toxin",
		"carnage",
		"sleeper",
		"symbiote_cat",
	]:
		var symbiote_data := card_database.get_card(symbiote_card_id)
		if symbiote_data == null or not symbiote_data.has_unit_trait(CardData.UNIT_TRAIT_SYMBIOTE):
			return _fail("Actual Symbiote is missing its unit trait: %s" % symbiote_card_id)
	for excluded_card_id in [
		"symbiote_shield_agent",
		"symbiote_biologist",
		"genetic_warrior",
		"xenophage",
		"knull_imprisoned",
		"knull_liberated",
	]:
		var excluded_data := card_database.get_card(excluded_card_id)
		if excluded_data == null or excluded_data.has_unit_trait(CardData.UNIT_TRAIT_SYMBIOTE):
			return _fail("Knull aura exclusion has an invalid unit trait: %s" % excluded_card_id)
	if (
		imprisoned_knull.effects.is_empty()
		or EffectData.get_id(imprisoned_knull.effects[0]) != EffectData.EFFECT_MODIFY_UNIT_ATTACK
		or EffectData.get_amount(imprisoned_knull.effects[0]) != 2
		or EffectData.get_target_unit_traits(imprisoned_knull.effects[0]) != [CardData.UNIT_TRAIT_SYMBIOTE]
	):
		return _fail("Imprisoned Knull aura is incomplete")
	if liberated_knull.effects.size() != 2:
		return _fail("Liberated Knull board effects are incomplete")
	var liberated_tissue_modifier := liberated_knull.effects[1]
	var replacement_effects := EffectData.get_replace_effects(liberated_tissue_modifier)
	if (
		EffectData.get_amount(liberated_knull.effects[0]) != 4
		or EffectData.get_target_unit_traits(liberated_knull.effects[0]) != [CardData.UNIT_TRAIT_SYMBIOTE]
		or EffectData.get_target_rule(liberated_tissue_modifier) != SpellTargetResolver.TARGET_RULE_NON_HERO_MINIONS
		or replacement_effects.size() != 1
		or not bool(replacement_effects[0].get(EffectData.KEY_ALLOW_ANY_NON_HERO_MINION, false))
	):
		return _fail("Liberated Knull aura or Tissue override is incomplete")

	var self_action := _find_action(venom, "self_severance")
	var artificial_action := _find_action(biologist, "artificial_severance")
	if self_action.is_empty() or artificial_action.is_empty():
		return _fail("A severance spell action is missing")
	if not bool(self_action.get(EffectData.KEY_EFFECT_HANDLES_ANIMATION, false)):
		return _fail("Self-severance would replay a generic cast animation")
	if not bool(artificial_action.get(EffectData.KEY_EFFECT_HANDLES_ANIMATION, false)):
		return _fail("Artificial severance would replay a generic cast animation")
	if _effect_ids(self_action) != [
		"play_animation",
		"gain_permanent_attack",
		"update_symbiote_offspring_pool",
		"damage",
		"add_card_to_hand",
	]:
		return _fail("Self-severance effect order changed")
	if _effect_ids(artificial_action) != [
		"play_animation",
		"gain_permanent_attack",
		"update_symbiote_offspring_pool",
		"damage",
		"add_card_to_hand",
	]:
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
	var lethal_pool_state: Dictionary = player.get_effect_runtime_value(
		"symbiote_offspring_pool",
		{}
	)
	if int(lethal_pool_state.get("severance_count", 0)) != 1:
		return _fail("Lethal self-severance did not advance the offspring pool")
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
	var pool_state: Dictionary = player.get_effect_runtime_value("symbiote_offspring_pool", {})
	if int(pool_state.get("severance_count", 0)) != 2:
		return _fail("Both severance actions did not share one player-level counter")

	probe.queue_free()
	await process_frame
	return true


func _test_bite_runtime(card_database: CardDatabase) -> bool:
	var attacker_player := _make_player("bite_owner", "symbiote")
	var defender_player := _make_player("bite_target", "symbiote")
	var manager := SymbioteRuleProbe.new()
	manager.players = [attacker_player, defender_player]
	manager.card_database = card_database
	manager.board_columns = 7

	var venom_state := _make_state(card_database.get_card("venom"), attacker_player.id, 24)
	var target_state := _make_state(card_database.get_card("symbiote_shield_agent"), defender_player.id, 25)
	venom_state.damage_taken = 6
	manager.board_states = [venom_state, target_state]
	venom_state.add_status(_make_bite_status(attacker_player.id))

	var attack := AttackAction.new()
	if not await attack.perform_attack(venom_state, target_state, manager, false):
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite could not perform a legal adjacent attack")
	if target_state.damage_taken != 4:
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite did not add exactly 2 damage to its primary target")
	if venom_state.current_health != 18:
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite did not restore exactly 4 health")
	if venom_state.has_status(CardStatus.STATUS_VENOM_BITE_READY):
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite was not consumed by the next attack")
	if not manager.animation_keys.has("symbiote_bite_strike") or not manager.animation_keys.has("symbiote_bite_restore"):
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite combat feedback is incomplete")

	var building_data := CardData.new()
	building_data.id = "bite_test_building"
	building_data.display_name = "Bite Test Building"
	building_data.type = CardData.TYPE_BUILDING
	building_data.attack = 0
	building_data.health = 12
	var building_state := _make_state(building_data, defender_player.id, 25)
	manager.board_states = [venom_state, building_state]
	venom_state.damage_taken = 6
	venom_state.add_status(_make_bite_status(attacker_player.id))
	await attack.perform_attack(venom_state, building_state, manager, false)
	if building_state.damage_taken != venom_state.current_attack:
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite incorrectly increased damage against a building")
	if venom_state.current_health != 14:
		_cleanup_rule_probe(manager)
		return _fail("Venom Bite incorrectly healed after attacking a building")
	if venom_state.has_status(CardStatus.STATUS_VENOM_BITE_READY):
		_cleanup_rule_probe(manager)
		return _fail("A building attack did not consume the prepared Venom Bite")

	_cleanup_rule_probe(manager)
	return true


func _test_fear_runtime(card_database: CardDatabase) -> bool:
	var resolver := StatusResolver.new()
	if resolver.get_fear_destination_slot(24, 16, 7, 7) != 32:
		return _fail("Fear did not calculate a diagonal tile directly away from its source")
	if resolver.get_fear_destination_slot(48, 40, 7, 7) != -1:
		return _fail("Fear allowed forced movement beyond the board")

	var source_player := _make_player("fear_source", "symbiote")
	var target_player := _make_player("fear_target", "symbiote")
	var manager := SymbioteRuleProbe.new()
	manager.players = [source_player, target_player]
	manager.card_database = card_database
	manager.board_columns = 7
	manager.board_rows = 7
	manager.board_states = _make_empty_board(49)

	var source_state := _make_state(card_database.get_card("venom"), source_player.id, 16)
	var feared_state := _make_state(card_database.get_card("symbiote_shield_agent"), target_player.id, 24)
	manager.board_states[16] = source_state
	manager.board_states[24] = feared_state
	var fear_status := CardStatus.new()
	fear_status.status_id = CardStatus.STATUS_FEAR
	fear_status.tags = [CardStatus.TAG_ACTION_PREVENTION]
	fear_status.source_owner_id = source_player.id
	fear_status.source_card_id = source_state.card_id
	fear_status.payload = {EffectData.KEY_FEAR_SOURCE_SLOT: source_state.slot_index}
	feared_state.add_status(fear_status)
	if feared_state.can_take_action_group(CardState.ACTION_GROUP_ATTACK):
		_cleanup_rule_probe(manager)
		return _fail("Fear did not prevent all actions")

	await resolver.resolve_fear_movements(manager, target_player.id)
	var destination_state := manager.board_states[32]
	if destination_state.card_id != "symbiote_shield_agent" or not manager.board_states[24].is_empty():
		_cleanup_rule_probe(manager)
		return _fail("Fear did not move the target exactly one tile away")
	if not manager.animation_keys.has("symbiote_fear_flee"):
		_cleanup_rule_probe(manager)
		return _fail("Fear forced movement did not publish presentation feedback")

	_cleanup_rule_probe(manager)
	return true


func _test_terrifying_scream_runtime(card_database: CardDatabase) -> bool:
	var source_player := _make_player("scream_source", "symbiote")
	var enemy_player := _make_player("scream_enemy", "symbiote")
	var manager := SymbioteRuleProbe.new()
	manager.players = [source_player, enemy_player]
	manager.card_database = card_database
	manager.board_columns = 7
	manager.board_rows = 7
	manager.board_states = _make_empty_board(49)
	manager.aerial_board_states = _make_empty_board(49)

	var venom_state := _make_state(card_database.get_card("venom"), source_player.id, 24)
	var ground_enemy := _make_state(card_database.get_card("symbiote_shield_agent"), enemy_player.id, 16)
	var aerial_enemy := _make_state(card_database.get_card("symbiote_shield_agent"), enemy_player.id, 25)
	var friendly_state := _make_state(card_database.get_card("symbiote_shield_agent"), source_player.id, 17)
	manager.board_states[24] = venom_state
	manager.board_states[16] = ground_enemy
	manager.board_states[17] = friendly_state
	manager.aerial_board_states[25] = aerial_enemy

	var scream_data := card_database.get_card("terrifying_scream")
	var effect_data := scream_data.effects[0].duplicate(true)
	EffectData.mark_effect_owner(effect_data, source_player.id)
	if not manager.effect_registry.can_execute_effect(null, effect_data, manager):
		_cleanup_rule_probe(manager)
		return _fail("Terrifying Scream was unavailable with adjacent enemies")
	await manager.effect_registry.execute_effect(null, effect_data, manager)
	for raw_target_state in [ground_enemy, aerial_enemy]:
		var target_state := raw_target_state as CardState
		if target_state.damage_taken != 2 or not target_state.has_status(CardStatus.STATUS_FEAR):
			_cleanup_rule_probe(manager)
			return _fail("Terrifying Scream did not damage and Fear both board layers")
		var fear_status: CardStatus = target_state.get_status(CardStatus.STATUS_FEAR)
		if int(fear_status.payload.get(EffectData.KEY_FEAR_SOURCE_SLOT, -1)) != venom_state.slot_index:
			_cleanup_rule_probe(manager)
			return _fail("Terrifying Scream did not retain the Fear source slot")
	if friendly_state.damage_taken != 0 or friendly_state.has_status(CardStatus.STATUS_FEAR):
		_cleanup_rule_probe(manager)
		return _fail("Terrifying Scream affected a friendly minion")
	if not manager.animation_keys.has("symbiote_fear_apply"):
		_cleanup_rule_probe(manager)
		return _fail("Terrifying Scream did not publish its multi-target effect")

	_cleanup_rule_probe(manager)
	return true


func _test_knull_runtime_rules(card_database: CardDatabase) -> bool:
	var player := _make_player("knull_owner", "symbiote")
	var enemy := _make_player("knull_enemy", "symbiote")
	var manager := SymbioteRuleProbe.new()
	manager.players = [player, enemy]
	manager.card_database = card_database
	var knull_state := _make_state(card_database.get_card("knull_imprisoned"), player.id, 8)
	var human_state := _make_state(card_database.get_card("symbiote_shield_agent"), player.id, 9)
	var xenophage_state := _make_state(card_database.get_card("xenophage"), player.id, 10)
	var venom_state := _make_state(card_database.get_card("venom"), player.id, 11)
	var offspring_state := _make_state(card_database.get_card("symbiote_riot"), player.id, 12)
	var enemy_state := _make_state(card_database.get_card("symbiote_riot"), enemy.id, 13)
	manager.board_states = [
		knull_state,
		human_state,
		xenophage_state,
		venom_state,
		offspring_state,
		enemy_state,
	]

	var passive_resolver := HandPassiveResolver.new()
	var passives := passive_resolver.collect_active_passive_effects(player, manager)
	passive_resolver.refresh_unit_attack_passives(player, manager, passives)
	if venom_state.current_attack != 4 or offspring_state.current_attack != 5:
		_cleanup_rule_probe(manager)
		return _fail("Imprisoned Knull did not grant +2 attack to friendly Symbiote-trait units")
	if knull_state.current_attack != 2 or human_state.current_attack != 1 or xenophage_state.current_attack != 3:
		_cleanup_rule_probe(manager)
		return _fail("Imprisoned Knull aura affected Knull, a human host, or Xenophage")
	if enemy_state.current_attack != 3:
		_cleanup_rule_probe(manager)
		return _fail("Knull aura affected an enemy Symbiote")

	knull_state.transform_to_card_data(card_database.get_card("knull_liberated"))
	passives = passive_resolver.collect_active_passive_effects(player, manager)
	passive_resolver.refresh_unit_attack_passives(player, manager, passives)
	if venom_state.current_attack != 6 or offspring_state.current_attack != 7:
		_cleanup_rule_probe(manager)
		return _fail("Liberated Knull did not replace its aura with +4 attack")
	if knull_state.current_attack != 4 or human_state.current_attack != 1 or xenophage_state.current_attack != 3:
		_cleanup_rule_probe(manager)
		return _fail("Liberated Knull aura affected an excluded unit")

	var tissue := card_database.get_card("symbiote_tissue")
	var resolved_spell := HandSpellModifierResolver.new().resolve_hand_spell(
		player,
		tissue,
		enemy_state,
		manager
	)
	var resolved_effects: Array = resolved_spell.get("effects", [])
	if str(resolved_spell.get("target_rule", "")) != SpellTargetResolver.TARGET_RULE_NON_HERO_MINIONS or resolved_effects.size() != 1:
		_cleanup_rule_probe(manager)
		return _fail("Liberated Knull did not broaden Symbiote Tissue targeting")
	var resolved_effect := resolved_effects[0] as Dictionary
	if not bool(resolved_effect.get(EffectData.KEY_ALLOW_ANY_NON_HERO_MINION, false)):
		_cleanup_rule_probe(manager)
		return _fail("Liberated Knull Tissue effect lost its open-host rule")
	var attach_effect := AttachSymbioteOffspringEffectScript.new()
	if not attach_effect.can_attach_target(enemy_state, player.id, [], true):
		_cleanup_rule_probe(manager)
		return _fail("Liberated Knull could not attach Tissue to an enemy non-hero minion")

	var genetic_host := _make_state(card_database.get_card("genetic_warrior"), player.id, 14)
	manager.board_states.append(genetic_host)
	manager.next_offspring_card_id = "symbiote_riot"
	var attachment_effect_data := resolved_effect.duplicate(true)
	EffectData.mark_effect_owner(attachment_effect_data, player.id)
	EffectData.mark_selected_target(attachment_effect_data, genetic_host)
	attach_effect.execute(null, attachment_effect_data, manager)
	if genetic_host.card_id != "symbiote_riot":
		_cleanup_rule_probe(manager)
		return _fail("Symbiote Tissue did not evolve the genetic warrior")
	if genetic_host.current_attack != 10 or genetic_host.max_health != 14:
		_cleanup_rule_probe(manager)
		return _fail("A newly attached Symbiote did not combine host stats with Knull's live aura")

	_cleanup_rule_probe(manager)
	return true


func _test_codex_zones(card_database: CardDatabase) -> bool:
	var player := _make_player("codex_owner", "symbiote")
	var manager := SymbioteRuleProbe.new()
	manager.players = [player]
	manager.card_database = card_database
	var imprisoned := card_database.get_card("knull_imprisoned")
	var effect_data := {
		EffectData.KEY_ID: EffectData.EFFECT_LIBERATE_CARD,
		EffectData.KEY_CARD_ID: "knull_imprisoned",
		EffectData.KEY_TARGET_CARD_ID: "knull_liberated",
	}
	EffectData.mark_effect_owner(effect_data, player.id)
	var liberate_effect := LiberateCardEffectScript.new()

	var board_state := _make_state(imprisoned, player.id, 8)
	manager.board_states = [board_state]
	if not liberate_effect.can_execute(null, effect_data, manager):
		_cleanup_rule_probe(manager)
		return _fail("Codex did not recognize face-up imprisoned Knull")
	await liberate_effect.execute(null, effect_data, manager)
	if board_state.card_id != "knull_liberated" or not player.hand.is_empty():
		_cleanup_rule_probe(manager)
		return _fail("Codex did not evolve face-up Knull in place")

	manager.board_states = []
	player.hand.clear()
	player.add_to_hand(imprisoned)
	await liberate_effect.execute(null, effect_data, manager)
	if player.hand.size() != 1 or _hand_card_id(player.hand[0]) != "knull_liberated":
		_cleanup_rule_probe(manager)
		return _fail("Codex did not replace imprisoned Knull in hand")

	player.hand.clear()
	player.graveyard.clear()
	player.add_to_graveyard(_make_state(imprisoned, player.id, 8).create_card_snapshot())
	await liberate_effect.execute(null, effect_data, manager)
	if not player.graveyard.is_empty() or player.hand.size() != 1 or _hand_card_id(player.hand[0]) != "knull_liberated":
		_cleanup_rule_probe(manager)
		return _fail("Codex did not revive liberated Knull from the graveyard")

	player.hand.clear()
	var hidden_state := _make_state(imprisoned, "", 12)
	hidden_state.set_face_up(false)
	manager.board_states = [hidden_state]
	await liberate_effect.execute(null, effect_data, manager)
	if not hidden_state.is_empty() or player.hand.size() != 1 or _hand_card_id(player.hand[0]) != "knull_liberated" or manager.refilled_slots != [12]:
		_cleanup_rule_probe(manager)
		return _fail("Codex did not replace hidden Knull and refill its board slot")

	player.hand.clear()
	manager.board_states = []
	manager.card_pool = CardPool.new("", card_database)
	manager.card_pool.add_card(imprisoned, false)
	await liberate_effect.execute(null, effect_data, manager)
	if manager.card_pool.has_card_id("knull_imprisoned") or player.hand.size() != 1 or _hand_card_id(player.hand[0]) != "knull_liberated":
		_cleanup_rule_probe(manager)
		return _fail("Codex did not replace imprisoned Knull in the shared pool")

	_cleanup_rule_probe(manager)
	return true


func _test_visual_frames() -> bool:
	var effect_root := Control.new()
	effect_root.name = "SymbioteVisualTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	for animation_key in [
		"symbiote_self_severance",
		"symbiote_artificial_severance",
		"symbiote_attachment",
	]:
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

	for animation_key in [
		"symbiote_bite_ready",
		"symbiote_bite_strike",
		"symbiote_bite_restore",
		"symbiote_terrifying_scream",
		"symbiote_fear_apply",
		"symbiote_fear_flee",
		"symbiote_codex",
		"symbiote_knull_liberation",
	]:
		for progress_sample in PROGRESS_SAMPLES:
			var visual := SymbiotePowerVisualScript.new()
			visual.size = effect_root.size
			effect_root.add_child(visual)
			visual.configure(
				animation_key,
				Vector2(280.0, 500.0),
				Vector2(850.0, 260.0),
				Vector2(120.0, 168.0),
				Vector2(120.0, 168.0),
				[Vector2(850.0, 260.0), Vector2(630.0, 190.0)]
			)
			visual.progress = progress_sample
			visual.queue_redraw()
			await process_frame
			visual.queue_free()
			await process_frame
			if effect_root.get_child_count() != 0:
				return _fail("Symbiote power visual leaked nodes at %s:%s" % [animation_key, progress_sample])

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
	if not router.has_targeted_route("symbiote_attachment"):
		return _fail("Symbiote attachment targeted route is missing")
	if not router.has_targeted_route("symbiote_bite_strike"):
		return _fail("Venom Bite targeted route is missing")
	if not router.has_rect_route("symbiote_codex"):
		return _fail("Knull Codex rect route is missing")
	if not router.has_multi_rect_route("symbiote_fear_apply"):
		return _fail("Fear multi-target route is missing")

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

	var source_card := Card.new()
	source_card.position = source_rect.position
	source_card.size = source_rect.size
	var attachment_target := Card.new()
	attachment_target.position = target_rect.position
	attachment_target.size = target_rect.size
	await provider.play_targeted(
		effect_root,
		effect_root,
		source_card,
		attachment_target,
		"symbiote_attachment"
	)
	source_card.free()
	attachment_target.free()
	await process_frame
	if effect_root.get_child_count() != 0:
		return _fail("Symbiote attachment provider leaked its visual")

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


func _make_player(player_id: String, faction_id: String) -> PlayerState:
	var player := PlayerState.new()
	player.setup(player_id, player_id)
	player.set_faction(faction_id, faction_id)
	return player


func _make_bite_status(owner_id: String) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = CardStatus.STATUS_VENOM_BITE_READY
	status.tags = [CardStatus.TAG_NEXT_ATTACK_MODIFIER]
	status.source_card_id = "venom"
	status.source_owner_id = owner_id
	status.payload = {
		EffectData.KEY_NEXT_ATTACK_BONUS_DAMAGE: 2,
		EffectData.KEY_NEXT_ATTACK_HEAL: 4,
		EffectData.KEY_NEXT_ATTACK_EXCLUDES_BUILDINGS: true,
		EffectData.KEY_TRIGGER_ANIMATION: "symbiote_bite_strike",
		EffectData.KEY_LIFESTEAL_ANIMATION: "symbiote_bite_restore",
	}
	return status


func _make_empty_board(slot_count: int) -> Array[CardState]:
	var states: Array[CardState] = []
	for slot_index in range(slot_count):
		var state := CardState.new()
		state.slot_index = slot_index
		states.append(state)
	return states


func _cleanup_rule_probe(manager: SymbioteRuleProbe) -> void:
	if manager == null:
		return
	if is_instance_valid(manager.audio_manager):
		manager.audio_manager.free()
	manager.free()


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
