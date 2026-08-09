extends RefCounted
class_name SymbioteOffspringPoolResolver

# Player-owned runtime pool for Symbiote offspring. CardData remains immutable;
# this resolver only tracks which unique offspring definitions are available.

const FACTION_ID := "symbiote"
const POOL_ID := "symbiote_offspring"
const RUNTIME_KEY := "symbiote_offspring_pool"

const KEY_AVAILABLE_CARD_IDS := "available_card_ids"
const KEY_DEAD_CARD_IDS := "dead_card_ids"
const KEY_SEVERANCE_COUNT := "severance_count"
const KEY_UNLOCKED_RULE_IDS := "unlocked_rule_ids"
const KEY_IS_INITIALIZED := "is_initialized"
const KEY_WITH_REPLACEMENT_CARD_IDS := "with_replacement_card_ids"


func initialize_player(player: PlayerState, card_database: CardDatabase) -> void:
	if player == null or card_database == null or player.faction_id != FACTION_ID:
		return

	var config := get_pool_config(card_database)
	if config.is_empty():
		return

	var state := get_runtime_state(player)
	var did_change := normalize_state(state)
	if not bool(state.get(KEY_IS_INITIALIZED, false)):
		for card_id in normalize_string_array(config.get("initial_card_ids", [])):
			append_unique_card_id(state[KEY_AVAILABLE_CARD_IDS], card_id)
		state[KEY_IS_INITIALIZED] = true
		did_change = true

	if did_change or not player.effect_runtime_values.has(RUNTIME_KEY):
		store_runtime_state(player, state)


func get_available_card_ids(player: PlayerState, card_database: CardDatabase) -> Array[String]:
	initialize_player(player, card_database)
	if player == null:
		return []
	return normalize_string_array(get_runtime_state(player).get(KEY_AVAILABLE_CARD_IDS, []))


func get_severance_count(player: PlayerState, card_database: CardDatabase) -> int:
	initialize_player(player, card_database)
	if player == null:
		return 0
	return maxi(int(get_runtime_state(player).get(KEY_SEVERANCE_COUNT, 0)), 0)


func get_dead_card_ids(player: PlayerState, card_database: CardDatabase) -> Array[String]:
	initialize_player(player, card_database)
	if player == null:
		return []
	return normalize_string_array(get_runtime_state(player).get(KEY_DEAD_CARD_IDS, []))


func draw_random_card_id(player: PlayerState, card_database: CardDatabase) -> String:
	if player == null or card_database == null or player.faction_id != FACTION_ID:
		return ""

	initialize_player(player, card_database)
	var config := get_pool_config(card_database)
	var state := get_runtime_state(player)
	var candidates: Array[String] = []
	for card_id in normalize_string_array(state.get(KEY_AVAILABLE_CARD_IDS, [])):
		var card_data := card_database.get_card(card_id)
		if card_data != null and card_data.is_minion():
			candidates.append(card_id)
	if candidates.is_empty():
		return ""

	var selected_card_id := str(candidates.pick_random())
	var with_replacement_ids := normalize_string_array(
		config.get(KEY_WITH_REPLACEMENT_CARD_IDS, [])
	)
	if not with_replacement_ids.has(selected_card_id):
		var available_ids := normalize_string_array(state.get(KEY_AVAILABLE_CARD_IDS, []))
		available_ids.erase(selected_card_id)
		state[KEY_AVAILABLE_CARD_IDS] = available_ids
		store_runtime_state(player, state)
	return selected_card_id


func record_severance(player: PlayerState, card_database: CardDatabase) -> Array[String]:
	var unlocked_cards: Array[String] = []
	if player == null or card_database == null or player.faction_id != FACTION_ID:
		return unlocked_cards

	initialize_player(player, card_database)
	var config := get_pool_config(card_database)
	var state := get_runtime_state(player)
	state[KEY_SEVERANCE_COUNT] = maxi(int(state.get(KEY_SEVERANCE_COUNT, 0)), 0) + 1

	var unlock_config: Variant = config.get("severance_unlock", {})
	if unlock_config is Dictionary:
		unlock_cards_if_ready(
			state,
			unlock_config,
			int(state[KEY_SEVERANCE_COUNT]) >= maxi(int(unlock_config.get("threshold", 0)), 0),
			unlocked_cards
		)

	store_runtime_state(player, state)
	return unlocked_cards


func record_offspring_death(
	player: PlayerState,
	card_database: CardDatabase,
	card_id: String
) -> Array[String]:
	var unlocked_cards: Array[String] = []
	if player == null or card_database == null or player.faction_id != FACTION_ID or card_id == "":
		return unlocked_cards

	initialize_player(player, card_database)
	var config := get_pool_config(card_database)
	var state := get_runtime_state(player)
	append_unique_card_id(state[KEY_DEAD_CARD_IDS], card_id)

	for raw_unlock in config.get("death_unlocks", []):
		if not raw_unlock is Dictionary:
			continue
		var source_card_ids := normalize_string_array(raw_unlock.get("source_card_ids", []))
		unlock_cards_if_ready(state, raw_unlock, source_card_ids.has(card_id), unlocked_cards)

	var collection_unlock: Variant = config.get("death_collection_unlock", {})
	if collection_unlock is Dictionary:
		var required_ids := normalize_string_array(collection_unlock.get("required_card_ids", []))
		var dead_ids := normalize_string_array(state.get(KEY_DEAD_CARD_IDS, []))
		var has_all_required := not required_ids.is_empty()
		for required_id in required_ids:
			if not dead_ids.has(required_id):
				has_all_required = false
				break
		unlock_cards_if_ready(state, collection_unlock, has_all_required, unlocked_cards)

	store_runtime_state(player, state)
	return unlocked_cards


func get_pool_config(card_database: CardDatabase) -> Dictionary:
	if card_database == null:
		return {}
	for config in card_database.get_faction_card_pool_configs(FACTION_ID):
		if str(config.get("id", "")) == POOL_ID:
			return config
	return {}


func get_runtime_state(player: PlayerState) -> Dictionary:
	if player == null:
		return create_empty_state()
	var raw_state: Variant = player.get_effect_runtime_value(RUNTIME_KEY, {})
	if raw_state is Dictionary:
		return raw_state.duplicate(true)
	return create_empty_state()


func create_empty_state() -> Dictionary:
	return {
		KEY_AVAILABLE_CARD_IDS: [],
		KEY_DEAD_CARD_IDS: [],
		KEY_SEVERANCE_COUNT: 0,
		KEY_UNLOCKED_RULE_IDS: [],
		KEY_IS_INITIALIZED: false,
	}


func normalize_state(state: Dictionary) -> bool:
	var available_ids := normalize_string_array(state.get(KEY_AVAILABLE_CARD_IDS, []))
	var dead_ids := normalize_string_array(state.get(KEY_DEAD_CARD_IDS, []))
	var unlocked_rule_ids := normalize_string_array(state.get(KEY_UNLOCKED_RULE_IDS, []))
	var severance_count := maxi(int(state.get(KEY_SEVERANCE_COUNT, 0)), 0)
	var is_initialized := bool(state.get(KEY_IS_INITIALIZED, false))
	var did_change: bool = (
		state.get(KEY_AVAILABLE_CARD_IDS, null) != available_ids
		or state.get(KEY_DEAD_CARD_IDS, null) != dead_ids
		or state.get(KEY_UNLOCKED_RULE_IDS, null) != unlocked_rule_ids
		or int(state.get(KEY_SEVERANCE_COUNT, -1)) != severance_count
		or not state.has(KEY_IS_INITIALIZED)
	)
	state[KEY_AVAILABLE_CARD_IDS] = available_ids
	state[KEY_DEAD_CARD_IDS] = dead_ids
	state[KEY_SEVERANCE_COUNT] = severance_count
	state[KEY_UNLOCKED_RULE_IDS] = unlocked_rule_ids
	state[KEY_IS_INITIALIZED] = is_initialized
	return did_change


func unlock_cards_if_ready(
	state: Dictionary,
	unlock_config: Dictionary,
	is_ready: bool,
	unlocked_cards: Array[String]
) -> void:
	if not is_ready:
		return
	var rule_id := str(unlock_config.get("id", ""))
	var unlocked_rule_ids := normalize_string_array(state.get(KEY_UNLOCKED_RULE_IDS, []))
	if rule_id != "" and unlocked_rule_ids.has(rule_id):
		return

	for card_id in normalize_string_array(unlock_config.get("card_ids", [])):
		if append_unique_card_id(state[KEY_AVAILABLE_CARD_IDS], card_id):
			unlocked_cards.append(card_id)

	if rule_id != "":
		unlocked_rule_ids.append(rule_id)
		state[KEY_UNLOCKED_RULE_IDS] = unlocked_rule_ids


func append_unique_card_id(raw_ids: Variant, card_id: String) -> bool:
	if not raw_ids is Array or card_id == "":
		return false
	if raw_ids.has(card_id):
		return false
	raw_ids.append(card_id)
	return true


func normalize_string_array(raw_values: Variant) -> Array[String]:
	var values: Array[String] = []
	if not raw_values is Array:
		return values
	for raw_value in raw_values:
		var value := str(raw_value)
		if value != "" and not values.has(value):
			values.append(value)
	return values


func store_runtime_state(player: PlayerState, state: Dictionary) -> void:
	player.set_effect_runtime_value(RUNTIME_KEY, state.duplicate(true))
