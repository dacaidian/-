extends SceneTree

const SymbioteOffspringPoolResolverScript := preload(
	"res://scripts/game/symbiote_offspring_pool_resolver.gd"
)
const RandomNormalAttacksEffectScript := preload(
	"res://scripts/effects/random_normal_attacks_effect.gd"
)
const SymbioteWhipEffectScript := preload("res://scripts/effects/symbiote_whip_effect.gd")
const SymbioteAbsorbEffectScript := preload("res://scripts/effects/symbiote_absorb_effect.gd")
const AttachSymbioteOffspringEffectScript := preload(
	"res://scripts/effects/attach_symbiote_offspring_effect.gd"
)

const INITIAL_POOL_IDS: Array[String] = [
	"symbiote_riot",
	"symbiote_scream",
	"symbiote_lasher",
	"symbiote_extreme",
	"symbiote_devour",
	"anti_venom",
	"symbiote_warrior",
]


class RuleProbe:
	extends GameManager

	var occupy_flags: Array[bool] = []
	var after_attack_count := 0
	var board_animation_keys: Array[String] = []

	func play_card_attack_animation(
		_attacker_state: CardState,
		_target_state: CardState,
		_is_melee_attack := true,
		_attack_animation_key := ""
	) -> void:
		pass

	func resolve_attack_kill(
		_attacker_state: CardState,
		defeated_state: CardState,
		can_occupy := true
	) -> void:
		occupy_flags.append(can_occupy)
		defeated_state.clear_card()

	func resolve_dead_states(
		states_to_check: Array,
		_reason: String = "damage",
		_source_state: CardState = null,
		_source_owner_id := "",
		_death_slot_claim: Dictionary = {}
	) -> bool:
		var destroyed_any := false
		for raw_state in states_to_check:
			var state := raw_state as CardState
			if state != null and not state.is_empty() and state.current_health <= 0:
				state.clear_card()
				destroyed_any = true
		return destroyed_any

	func resolve_after_attack_triggers(
		_attacker_state: CardState,
		_attacked_state: CardState
	) -> void:
		after_attack_count += 1

	func refresh_action_available_hints() -> void:
		pass

	func refresh_debug_panel() -> void:
		pass

	func play_board_effect_animation(animation_key: String) -> void:
		board_animation_keys.append(animation_key)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_database := CardDatabase.new()
	if not card_database.load_from_json("res://data/cards.json"):
		_fail("Could not load card data")
		return
	if not test_pool_state(card_database):
		return
	if not test_pool_draw_modes(card_database):
		return
	if not await test_configured_death_unlock(card_database):
		return
	if not test_card_definitions(card_database):
		return
	if not await test_random_normal_attacks(card_database):
		return
	if not await test_whip_and_absorption(card_database):
		return
	if not await test_tissue_attachment(card_database):
		return
	if not await test_genetic_warrior_attachment(card_database):
		return
	if not test_silence_rules(card_database):
		return
	if not await test_carnage_progress(card_database):
		return

	print("SYMBIOTE_OFFSPRING_POOL_TESTS_OK")
	quit()


func test_pool_state(card_database: CardDatabase) -> bool:
	var resolver = SymbioteOffspringPoolResolverScript.new()
	var player := make_player("pool_owner", "symbiote")
	resolver.initialize_player(player, card_database)
	if resolver.get_available_card_ids(player, card_database) != INITIAL_POOL_IDS:
		return _fail("Initial Symbiote offspring pool is invalid")

	for index in range(4):
		if not resolver.record_severance(player, card_database).is_empty():
			return _fail("Advanced offspring unlocked before five severances")
	if resolver.get_severance_count(player, card_database) != 4:
		return _fail("Severance count did not advance")
	var fifth_unlock: Array[String] = resolver.record_severance(player, card_database)
	if fifth_unlock != ["toxin", "carnage", "sleeper"]:
		return _fail("Five severances did not unlock all advanced offspring once")
	resolver.record_severance(player, card_database)
	var available_ids: Array[String] = resolver.get_available_card_ids(player, card_database)
	for advanced_id in ["toxin", "carnage", "sleeper"]:
		if available_ids.count(advanced_id) != 1:
			return _fail("Advanced offspring was duplicated: %s" % advanced_id)

	var death_player := make_player("death_owner", "symbiote")
	resolver.initialize_player(death_player, card_database)
	var scream_unlock: Array[String] = resolver.record_offspring_death(
		death_player,
		card_database,
		"symbiote_scream"
	)
	if scream_unlock != ["symbiote_silence"]:
		return _fail("Howl death did not unlock Silence")
	for card_id in [
		"symbiote_riot",
		"symbiote_devour",
		"symbiote_lasher",
		"symbiote_extreme",
	]:
		resolver.record_offspring_death(death_player, card_database, card_id)
	available_ids = resolver.get_available_card_ids(death_player, card_database)
	if not available_ids.has("symbiote_hybrid"):
		return _fail("Five foundation deaths did not unlock Hybrid")
	resolver.record_offspring_death(death_player, card_database, "symbiote_scream")
	if resolver.get_available_card_ids(death_player, card_database).count("symbiote_silence") != 1:
		return _fail("Repeated death duplicated an offspring unlock")
	return true


func test_pool_draw_modes(card_database: CardDatabase) -> bool:
	var resolver = SymbioteOffspringPoolResolverScript.new()
	var finite_player := make_player("finite_draw_owner", "symbiote")
	finite_player.set_effect_runtime_value("symbiote_offspring_pool", make_pool_state([
		"symbiote_riot",
	]))
	if resolver.draw_random_card_id(finite_player, card_database) != "symbiote_riot":
		return _fail("Finite offspring draw returned the wrong card")
	if not resolver.get_available_card_ids(finite_player, card_database).is_empty():
		return _fail("Finite offspring was not removed after drawing")

	var replacement_player := make_player("replacement_draw_owner", "symbiote")
	replacement_player.set_effect_runtime_value("symbiote_offspring_pool", make_pool_state([
		"symbiote_warrior",
	]))
	if resolver.draw_random_card_id(replacement_player, card_database) != "symbiote_warrior":
		return _fail("Replacement offspring draw returned the wrong card")
	if resolver.get_available_card_ids(replacement_player, card_database) != ["symbiote_warrior"]:
		return _fail("Symbiote Warrior was removed despite replacement draw")
	return true


func test_configured_death_unlock(card_database: CardDatabase) -> bool:
	var player := make_player("death_trigger_owner", "symbiote")
	var manager := RuleProbe.new()
	manager.players = [player]
	manager.card_database = card_database
	var scream := make_state(card_database.get_card("symbiote_scream"), player.id, 24)
	await manager.effect_registry.execute_trigger(
		scream,
		EventContext.TRIGGER_ON_DESTROYED,
		manager
	)
	if not manager.get_symbiote_offspring_pool_card_ids(player.id).has("symbiote_silence"):
		cleanup_manager(manager)
		return _fail("Configured Howl deathrattle did not update the player pool")
	if manager.board_animation_keys != ["symbiote_pool_unlock_silence"]:
		cleanup_manager(manager)
		return _fail("Howl deathrattle did not publish its pool-unlock animation")
	cleanup_manager(manager)
	return true


func test_card_definitions(card_database: CardDatabase) -> bool:
	var expected_stats := {
		"symbiote_riot": [3, 7],
		"symbiote_scream": [2, 5],
		"symbiote_lasher": [3, 6],
		"symbiote_extreme": [4, 8],
		"symbiote_devour": [1, 3],
		"anti_venom": [10, 4],
		"symbiote_warrior": [5, 8],
		"symbiote_silence": [6, 10],
		"symbiote_hybrid": [7, 15],
		"toxin": [5, 14],
		"carnage": [8, 8],
		"sleeper": [4, 10],
		"symbiote_cat": [3, 9],
	}
	for card_id in expected_stats:
		var card_data := card_database.get_card(card_id)
		if card_data == null or card_data.count != 0:
			return _fail("Missing offspring token: %s" % card_id)
		var stats: Array = expected_stats[card_id]
		if card_data.attack != int(stats[0]) or card_data.health != int(stats[1]):
			return _fail("Offspring stats changed: %s" % card_id)

	var silence := card_database.get_card("symbiote_silence")
	if not silence.has_keyword(CardData.KEYWORD_RANGED) or not silence.has_keyword(CardData.KEYWORD_SILENCE_AURA):
		return _fail("Silence aura keywords are incomplete")
	var cat := card_database.get_card("symbiote_cat")
	if cat.attack_speed != 2 or cat.movement != 5 or not cat.has_keyword(CardData.KEYWORD_MOBILE_ASSAULT):
		return _fail("Cat action economy is invalid")
	var sleeper := card_database.get_card("sleeper")
	if sleeper.effects.is_empty() or EffectData.get_trigger(sleeper.effects[0]) != EventContext.TRIGGER_ON_ENTER_BOARD:
		return _fail("Sleeper does not generate Cat through the unified board-entry trigger")
	return true


func test_random_normal_attacks(card_database: CardDatabase) -> bool:
	var player_one := make_player("attacker", "symbiote")
	var player_two := make_player("defender", "symbiote")
	var manager := RuleProbe.new()
	manager.players = [player_one, player_two]
	manager.card_database = card_database

	var source := make_state(card_database.get_card("symbiote_hybrid"), player_one.id, 24)
	var targets: Array[CardState] = [
		make_state(card_database.get_card("symbiote_extreme"), player_one.id, 16),
		make_state(card_database.get_card("symbiote_extreme"), player_two.id, 17),
		make_state(card_database.get_card("symbiote_extreme"), "", 23),
		make_state(card_database.get_card("symbiote_extreme"), player_two.id, 25),
	]
	for target_state in targets:
		target_state.damage_taken = target_state.max_health - 1
	manager.board_states = [source]
	manager.board_states.append_array(targets)

	var effect = RandomNormalAttacksEffectScript.new()
	var legal_targets: Array[CardState] = effect.get_legal_targets(source, manager, AttackAction.new())
	if legal_targets.size() != 4:
		cleanup_manager(manager)
		return _fail("Riot did not recognize friendly, enemy and neutral legal targets")
	var attacks_before := source.current_attacks
	await effect.execute(source, {"max_targets": 3}, manager)
	if manager.occupy_flags.size() != 3 or manager.occupy_flags.has(true):
		cleanup_manager(manager)
		return _fail("Riot attacks did not suppress occupation")
	if source.current_attacks != attacks_before or manager.after_attack_count != 3:
		cleanup_manager(manager)
		return _fail("Riot spent attack resources or skipped normal attack triggers")
	var destroyed_target_count := 0
	for target_state in targets:
		if target_state.is_empty():
			destroyed_target_count += 1
	if destroyed_target_count != 3:
		cleanup_manager(manager)
		return _fail("Riot did not resolve exactly three normal attacks")
	var normal_target := make_state(card_database.get_card("symbiote_extreme"), player_two.id, 32)
	normal_target.damage_taken = normal_target.max_health - 1
	manager.board_states.append(normal_target)
	await AttackAction.new().execute(source, normal_target, manager)
	if source.current_attacks != attacks_before - 1 or not manager.occupy_flags.back():
		cleanup_manager(manager)
		return _fail("Normal attack cost or occupation changed after shared resolution refactor")
	cleanup_manager(manager)
	return true


func test_whip_and_absorption(card_database: CardDatabase) -> bool:
	var player_one := make_player("whip_owner", "symbiote")
	var player_two := make_player("whip_enemy", "symbiote")
	var manager := RuleProbe.new()
	manager.players = [player_one, player_two]
	manager.card_database = card_database

	var source := make_state(card_database.get_card("symbiote_lasher"), player_one.id, 24)
	var friendly := make_state(card_database.get_card("symbiote_extreme"), player_one.id, 23)
	var enemy := make_state(card_database.get_card("symbiote_extreme"), player_two.id, 25)
	var whip = SymbioteWhipEffectScript.new()
	var friendly_data := {
		EffectData.KEY_SELECTED_TARGET_STATE: friendly,
		"enemy_damage": 3,
		"friendly_damage": 1,
		"friendly_attack_bonus": 3,
	}
	await whip.execute(source, friendly_data, manager)
	if friendly.current_health != 7 or friendly.current_attack != 7:
		cleanup_manager(manager)
		return _fail("Friendly Whip branch resolved incorrectly")
	var enemy_data := friendly_data.duplicate(true)
	enemy_data[EffectData.KEY_SELECTED_TARGET_STATE] = enemy
	await whip.execute(source, enemy_data, manager)
	if enemy.current_health != 5 or enemy.current_attack != 4:
		cleanup_manager(manager)
		return _fail("Enemy Whip branch resolved incorrectly")

	var devourer := make_state(card_database.get_card("symbiote_devour"), player_one.id, 31)
	var scream := make_state(card_database.get_card("symbiote_scream"), player_two.id, 32)
	var absorption = SymbioteAbsorbEffectScript.new()
	absorption.apply_absorption(devourer, scream)
	if devourer.current_attack != 3 or devourer.max_health != 8:
		cleanup_manager(manager)
		return _fail("Devour did not absorb target combat stats")
	if not devourer.has_keyword(CardData.KEYWORD_RANGED):
		cleanup_manager(manager)
		return _fail("Devour did not absorb target keywords")
	var granted_spells := GrantedSpellResolver.new().get_granted_spell_actions(devourer, manager)
	if not has_action_id(granted_spells, "scream"):
		cleanup_manager(manager)
		return _fail("Devour did not absorb target spell actions")
	cleanup_manager(manager)
	return true


func test_tissue_attachment(card_database: CardDatabase) -> bool:
	var player_one := make_player("attachment_owner", "symbiote")
	var player_two := make_player("attachment_enemy", "symbiote")
	player_one.set_effect_runtime_value("symbiote_offspring_pool", make_pool_state([
		"symbiote_riot",
	]))
	var manager := RuleProbe.new()
	manager.players = [player_one, player_two]
	manager.card_database = card_database
	var host := make_state(card_database.get_card("symbiote_shield_agent"), player_one.id, 24)
	var enemy_host := make_state(card_database.get_card("symbiote_biologist"), player_two.id, 25)
	var invalid_friendly := make_state(card_database.get_card("xenophage"), player_one.id, 23)
	manager.board_states = [host, enemy_host, invalid_friendly]

	var tissue := card_database.get_card("symbiote_tissue")
	var hand_resolver := HandPlayResolver.new()
	player_one.hand.append(tissue)
	if not hand_resolver.can_play_hand_card(player_one, tissue, manager):
		cleanup_manager(manager)
		return _fail("Symbiote Tissue was disabled before target selection")
	var valid_targets := HandPlayResolver.new().get_valid_targets(tissue, manager, player_one)
	if valid_targets != [host]:
		cleanup_manager(manager)
		return _fail("Symbiote Tissue did not restrict selection to friendly human hosts")

	host.current_attacks = 0
	host.used_action_groups = ["attack"]
	host.refresh_current_main_actions()
	var old_status := CardStatus.new()
	old_status.status_id = "attachment_probe_status"
	old_status.display_name = "Attachment Probe"
	host.statuses.append(old_status)
	var effect_data := tissue.effects[0].duplicate(true)
	EffectData.mark_effect_owner(effect_data, player_one.id)
	effect_data[EffectData.KEY_SELECTED_TARGET_STATE] = host
	var effect = AttachSymbioteOffspringEffectScript.new()
	if not effect.can_execute(null, effect_data, manager):
		cleanup_manager(manager)
		return _fail("Symbiote Tissue rejected a legal host and available offspring")
	await effect.execute(null, effect_data, manager)
	if host.card_id != "symbiote_riot" or host.owner_id != player_one.id:
		cleanup_manager(manager)
		return _fail("Symbiote Tissue did not permanently evolve the selected host")
	if not host.statuses.is_empty() or host.get_transform_status() != null:
		cleanup_manager(manager)
		return _fail("Symbiote attachment retained host statuses or created a reversible transform")
	if host.current_attacks != 0 or host.current_main_actions != 0:
		cleanup_manager(manager)
		return _fail("Symbiote attachment refreshed spent action economy")
	if manager.get_symbiote_offspring_pool_card_ids(player_one.id).has("symbiote_riot"):
		cleanup_manager(manager)
		return _fail("Symbiote attachment did not consume a finite offspring")
	if hand_resolver.can_play_hand_card(player_one, tissue, manager):
		cleanup_manager(manager)
		return _fail("Symbiote Tissue remained playable with an empty offspring pool")
	cleanup_manager(manager)
	return true


func test_genetic_warrior_attachment(card_database: CardDatabase) -> bool:
	var player := make_player("genetic_attachment_owner", "symbiote")
	player.set_effect_runtime_value("symbiote_offspring_pool", make_pool_state([
		"symbiote_riot",
	]))
	var manager := RuleProbe.new()
	manager.players = [player]
	manager.card_database = card_database
	var host := make_state(card_database.get_card("genetic_warrior"), player.id, 24)
	manager.board_states = [host]

	var tissue := card_database.get_card("symbiote_tissue")
	var effect_data := tissue.effects[0].duplicate(true)
	EffectData.mark_effect_owner(effect_data, player.id)
	effect_data[EffectData.KEY_SELECTED_TARGET_STATE] = host
	var effect = AttachSymbioteOffspringEffectScript.new()
	await effect.execute(null, effect_data, manager)
	if host.card_id != "symbiote_riot":
		cleanup_manager(manager)
		return _fail("Genetic Warrior did not evolve into the forced offspring")
	if host.current_attack != 6 or host.max_health != 14 or host.current_health != 14:
		cleanup_manager(manager)
		return _fail("Genetic Warrior base stats were not inherited by the offspring")
	if (
		int(host.permanent_stat_overrides.get("attack", 0)) != 6
		or int(host.permanent_stat_overrides.get("health", 0)) != 14
	):
		cleanup_manager(manager)
		return _fail("Inherited genetic stats were not stored as permanent overrides")
	if not manager.get_symbiote_offspring_pool_card_ids(player.id).is_empty():
		cleanup_manager(manager)
		return _fail("Genetic attachment did not consume its finite offspring")
	cleanup_manager(manager)
	return true


func test_silence_rules(card_database: CardDatabase) -> bool:
	var player_one := make_player("silenced_owner", "symbiote")
	var player_two := make_player("silence_owner", "symbiote")
	var manager := RuleProbe.new()
	manager.players = [player_one, player_two]
	manager.card_database = card_database
	manager.current_player_index = 0

	var hero := make_state(card_database.get_card("venom"), player_one.id, 24)
	var silence := make_state(card_database.get_card("symbiote_silence"), player_two.id, 25)
	manager.board_states = [hero, silence]
	if not manager.is_unit_silenced(hero):
		cleanup_manager(manager)
		return _fail("Enemy Silence aura did not suppress a unit")
	var spell_action := SpellAction.new().setup({
		"id": "silence_probe",
		"name": "Silence Probe",
		"target_rule": "none",
		"effects": [{"id": "gain_attack", "target": "self", "amount": 1}],
	})
	if spell_action.can_start(hero, manager):
		cleanup_manager(manager)
		return _fail("A silenced unit can still start a spell action")

	var hero_spell := CardData.new()
	hero_spell.id = "hero_silence_probe"
	hero_spell.display_name = "Hero Silence Probe"
	hero_spell.type = CardData.TYPE_SPELL
	hero_spell.owner_hero_card_id = "venom"
	hero_spell.target_rule = SpellTargetResolver.TARGET_RULE_NONE
	hero_spell.effects = [{"id": "add_card_to_hand", "card_id": "symbiote_tissue", "amount": 1}]
	player_one.add_to_hand(hero_spell)
	var hand_resolver := HandPlayResolver.new()
	if hand_resolver.can_play_hand_card(player_one, hero_spell, manager):
		cleanup_manager(manager)
		return _fail("A spell attached to a silenced hero remains playable")

	silence.clear_card()
	if not spell_action.can_start(hero, manager):
		cleanup_manager(manager)
		return _fail("Spell action did not recover after Silence aura left play")
	if not hand_resolver.can_play_hand_card(player_one, hero_spell, manager):
		cleanup_manager(manager)
		return _fail("Hero spell did not recover after Silence aura left play")
	cleanup_manager(manager)
	return true


func test_carnage_progress(card_database: CardDatabase) -> bool:
	var player_one := make_player("carnage_owner", "symbiote")
	var player_two := make_player("enemy_owner", "symbiote")
	var manager := RuleProbe.new()
	manager.players = [player_one, player_two]
	manager.card_database = card_database
	var carnage := make_state(card_database.get_card("carnage"), "carnage_owner", 24)
	var enemy := make_state(card_database.get_card("symbiote_extreme"), "enemy_owner", 25)
	var death_resolver := DeathResolver.new()
	await death_resolver.resolve_kill_trigger(manager, {
		"source_state": carnage,
		"state": enemy,
		"destroy_context": {EventContext.DEAD_STATE: enemy},
	})
	await manager.trigger_resolver.resolve_queued(manager)
	if carnage.max_attack_speed != 1 or carnage.get_runtime_counter("carnage_enemy_minion_kills") != 1:
		cleanup_manager(manager)
		return _fail("Carnage first kill progress is invalid")

	var friendly := make_state(card_database.get_card("symbiote_extreme"), "carnage_owner", 23)
	await death_resolver.resolve_kill_trigger(manager, {
		"source_state": carnage,
		"state": friendly,
		"destroy_context": {EventContext.DEAD_STATE: friendly},
	})
	await manager.trigger_resolver.resolve_queued(manager)
	var enemy_hero := make_state(card_database.get_card("venom"), "enemy_owner", 26)
	await death_resolver.resolve_kill_trigger(manager, {
		"source_state": carnage,
		"state": enemy_hero,
		"destroy_context": {EventContext.DEAD_STATE: enemy_hero},
	})
	await manager.trigger_resolver.resolve_queued(manager)
	if carnage.get_runtime_counter("carnage_enemy_minion_kills") != 1:
		cleanup_manager(manager)
		return _fail("Carnage counted a friendly or hero death")

	var second_enemy := make_state(card_database.get_card("symbiote_extreme"), "enemy_owner", 27)
	await death_resolver.resolve_kill_trigger(manager, {
		"source_state": carnage,
		"state": second_enemy,
		"destroy_context": {EventContext.DEAD_STATE: second_enemy},
	})
	await manager.trigger_resolver.resolve_queued(manager)
	if carnage.max_attack_speed != 2 or carnage.current_attacks != 2:
		cleanup_manager(manager)
		return _fail("Carnage did not gain attack speed on the second kill")
	if int(carnage.permanent_stat_overrides.get("attack_speed", 0)) != 2:
		cleanup_manager(manager)
		return _fail("Carnage attack speed growth was not snapshot-safe")
	cleanup_manager(manager)
	return true


func make_player(player_id: String, faction_id: String) -> PlayerState:
	var player := PlayerState.new()
	player.setup(player_id, player_id)
	player.set_faction(faction_id, faction_id)
	return player


func make_pool_state(available_card_ids: Array) -> Dictionary:
	return {
		"available_card_ids": available_card_ids.duplicate(),
		"dead_card_ids": [],
		"severance_count": 0,
		"unlocked_rule_ids": [],
		"is_initialized": true,
	}


func make_state(card_data: CardData, owner_id: String, slot_index: int) -> CardState:
	var state := CardState.new()
	state.set_card_data(card_data)
	state.owner_id = owner_id
	state.slot_index = slot_index
	state.set_face_up(true)
	return state


func has_action_id(actions: Array[Dictionary], action_id: String) -> bool:
	for action_data in actions:
		if str(action_data.get("id", "")) == action_id:
			return true
	return false


func cleanup_manager(manager: GameManager) -> void:
	if manager == null:
		return
	if is_instance_valid(manager.audio_manager):
		manager.audio_manager.free()
	manager.free()


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
