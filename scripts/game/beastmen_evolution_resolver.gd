extends RefCounted
class_name BeastmenEvolutionResolver

# 野兽人同系斩杀进化。
# 规则由 faction.evolution_rules 配置；resolver 只负责在死亡事件后匹配并执行永久进化。

const FACTION_ID := "beastmen"
const KEY_KILLER_CARD_IDS := "killer_card_ids"
const KEY_VICTIM_OWNER := "victim_owner"
const KEY_VICTIM_EVOLUTION_LINE := "victim_evolution_line"
const KEY_DEATH_REASONS := "death_reasons"
const KEY_TRANSFORM_TO := "transform_to"
const KEY_ANIMATION := "animation"

const VICTIM_OWNER_FRIENDLY := "friendly"
const DEFAULT_ANIMATION := "beastmen_evolution"


func resolve_after_death_batch(game_manager: GameManager, death_events: Array[Dictionary]) -> void:
	if game_manager == null or game_manager.card_database == null:
		return

	for death_event in death_events:
		await resolve_death_event(game_manager, death_event)


func resolve_death_event(game_manager: GameManager, death_event: Dictionary) -> void:
	var killer := death_event.get("source_state") as CardState
	var victim := death_event.get("state") as CardState
	if killer == null or victim == null:
		return
	if killer == victim or killer.is_empty() or victim.is_empty():
		return
	if killer.is_pending_death:
		return

	var killer_player := game_manager.get_player_by_id(killer.owner_id)
	if killer_player == null or killer_player.faction_id != FACTION_ID:
		return

	for rule in game_manager.card_database.get_faction_evolution_rules(FACTION_ID):
		if not can_apply_rule(rule, death_event, killer, victim):
			continue

		var target_card_id := str(rule.get(KEY_TRANSFORM_TO, ""))
		var target_data := game_manager.get_card_data_by_id(target_card_id) as CardData
		if target_data == null or not target_data.is_minion():
			continue

		apply_permanent_evolution(killer, target_data)
		var animation_key := str(rule.get(KEY_ANIMATION, DEFAULT_ANIMATION))
		if animation_key != "" and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(killer, animation_key)
		game_manager.refresh_action_available_hints()
		game_manager.refresh_debug_panel()
		return


func can_apply_rule(rule: Dictionary, death_event: Dictionary, killer: CardState, victim: CardState) -> bool:
	if rule.is_empty():
		return false

	var death_reason := str(death_event.get("reason", ""))
	var allowed_reasons := normalize_string_array(rule.get(KEY_DEATH_REASONS, []))
	if not allowed_reasons.is_empty() and not allowed_reasons.has(death_reason):
		return false

	var killer_card_ids := normalize_string_array(rule.get(KEY_KILLER_CARD_IDS, []))
	if not killer_card_ids.is_empty() and not killer_card_ids.has(killer.card_id):
		return false

	if str(rule.get(KEY_VICTIM_OWNER, VICTIM_OWNER_FRIENDLY)) == VICTIM_OWNER_FRIENDLY:
		if victim.owner_id != killer.owner_id:
			return false

	var required_line := str(rule.get(KEY_VICTIM_EVOLUTION_LINE, ""))
	if required_line != "":
		if victim.data == null or victim.data.evolution_line != required_line:
			return false

	return true


func apply_permanent_evolution(state: CardState, target_data: CardData) -> void:
	var owner_id := state.owner_id
	state.transform_to_card_data(target_data)
	state.owner_id = owner_id
	state.is_face_up = true
	state.state_changed.emit(state)


func normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result

	for entry in value:
		var text := str(entry)
		if text != "" and not result.has(text):
			result.append(text)

	return result
