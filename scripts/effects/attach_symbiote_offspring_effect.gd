extends CardEffect
class_name AttachSymbioteOffspringEffect

# Consumes one player-owned offspring entry only after the selected host is
# still legal, then performs an irreversible full-state evolution.

const DEFAULT_HOST_CARD_IDS: Array[String] = [
	"symbiote_shield_agent",
	"symbiote_biologist",
	"genetic_warrior",
]
const KEY_INHERIT_HOST_BASE_STATS_CARD_IDS := "inherit_host_base_stats_card_ids"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	var target_state := EffectData.get_selected_target_state(effect_data)
	if not can_attach_target(
		target_state,
		owner_id,
		get_host_card_ids(effect_data),
		allows_any_non_hero_minion(effect_data)
	):
		return
	if game_manager == null or not game_manager.has_method("draw_symbiote_offspring_card_id"):
		return

	var offspring_card_id := str(game_manager.draw_symbiote_offspring_card_id(owner_id))
	if offspring_card_id == "" or not game_manager.has_method("get_card_data_by_id"):
		return
	var offspring_data := game_manager.get_card_data_by_id(offspring_card_id) as CardData
	if offspring_data == null or not offspring_data.is_minion():
		return

	var inherited_stats := get_inherited_host_base_stats(target_state, effect_data)
	apply_permanent_evolution(target_state, offspring_data, owner_id)
	apply_inherited_host_base_stats(target_state, inherited_stats)
	if game_manager.has_method("refresh_action_available_hints"):
		game_manager.refresh_action_available_hints()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	var target_state := EffectData.get_selected_target_state(effect_data)
	if game_manager == null or not game_manager.has_method("get_symbiote_offspring_pool_card_ids"):
		return false
	if game_manager.get_symbiote_offspring_pool_card_ids(owner_id).is_empty():
		return false

	var host_card_ids := get_host_card_ids(effect_data)
	var allow_any_non_hero := allows_any_non_hero_minion(effect_data)
	if target_state != null:
		return can_attach_target(target_state, owner_id, host_card_ids, allow_any_non_hero)
	if not game_manager.has_method("get_all_board_states"):
		return false
	for board_state in game_manager.get_all_board_states():
		if can_attach_target(
			board_state as CardState,
			owner_id,
			host_card_ids,
			allow_any_non_hero
		):
			return true
	return false


func can_attach_target(
	target_state: CardState,
	owner_id: String,
	host_card_ids: Array[String],
	allow_any_non_hero := false
) -> bool:
	if (
		target_state == null
		or owner_id == ""
		or not BoardQuery.is_face_up_minion(target_state)
		or target_state.is_hero()
		or target_state.get_transform_status() != null
	):
		return false
	if allow_any_non_hero:
		return true
	if target_state.owner_id != owner_id:
		return false
	for host_card_id in host_card_ids:
		if target_state.represents_card_id(host_card_id):
			return true
	return false


func allows_any_non_hero_minion(effect_data: Dictionary) -> bool:
	return bool(effect_data.get(EffectData.KEY_ALLOW_ANY_NON_HERO_MINION, false))


func get_host_card_ids(effect_data: Dictionary) -> Array[String]:
	var configured_ids := EffectData.get_card_ids(effect_data)
	return configured_ids if not configured_ids.is_empty() else DEFAULT_HOST_CARD_IDS.duplicate()


func get_inherited_host_base_stats(
	target_state: CardState,
	effect_data: Dictionary
) -> Dictionary:
	if target_state == null or target_state.data == null:
		return {}
	var inheritance_ids := normalize_card_ids(
		effect_data.get(KEY_INHERIT_HOST_BASE_STATS_CARD_IDS, [])
	)
	if not inheritance_ids.has(target_state.card_id):
		return {}
	return {
		"attack": maxi(target_state.data.attack, 0),
		"health": maxi(target_state.data.health, 0),
	}


func apply_inherited_host_base_stats(target_state: CardState, inherited_stats: Dictionary) -> void:
	if target_state == null or inherited_stats.is_empty():
		return
	var attack_gain := maxi(int(inherited_stats.get("attack", 0)), 0)
	var health_gain := maxi(int(inherited_stats.get("health", 0)), 0)
	if attack_gain > 0:
		target_state.add_permanent_attack(attack_gain)
	if health_gain > 0:
		target_state.add_permanent_max_health(health_gain)


func normalize_card_ids(value: Variant) -> Array[String]:
	var card_ids: Array[String] = []
	if value is Array:
		for raw_card_id in value:
			var card_id := str(raw_card_id)
			if card_id != "" and not card_ids.has(card_id):
				card_ids.append(card_id)
	return card_ids


func apply_permanent_evolution(
	target_state: CardState,
	offspring_data: CardData,
	owner_id: String
) -> void:
	target_state.transform_to_card_data(offspring_data)
	target_state.owner_id = owner_id
	target_state.is_face_up = true
	target_state.state_changed.emit(target_state)
