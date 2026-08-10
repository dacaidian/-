extends CardEffect
class_name UpdateSymbioteOffspringPoolEffect

const SymbioteOffspringPoolResolverScript := preload(
	"res://scripts/game/symbiote_offspring_pool_resolver.gd"
)

const OPERATION_RECORD_SEVERANCE := "record_severance"
const OPERATION_RECORD_DEATH := "record_death"
const KEY_OPERATION := "operation"
const KEY_POOL_CARD_ID := "pool_card_id"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or game_manager == null:
		return
	var unlocked_cards: Array[String] = []

	match str(effect_data.get(KEY_OPERATION, "")):
		OPERATION_RECORD_SEVERANCE:
			if game_manager.has_method("record_symbiote_severance"):
				unlocked_cards = normalize_card_ids(
					game_manager.record_symbiote_severance(owner_id)
				)
			else:
				unlocked_cards = record_with_local_resolver(game_manager, owner_id, "")
		OPERATION_RECORD_DEATH:
			var pool_card_id := str(effect_data.get(KEY_POOL_CARD_ID, ""))
			if pool_card_id == "" and source_state != null:
				pool_card_id = source_state.card_id
			if game_manager.has_method("record_symbiote_offspring_death"):
				unlocked_cards = normalize_card_ids(
					game_manager.record_symbiote_offspring_death(owner_id, pool_card_id)
				)
			else:
				unlocked_cards = record_with_local_resolver(
					game_manager,
					owner_id,
					pool_card_id
				)

	var animation_key := get_unlock_animation_key(unlocked_cards)
	if animation_key != "" and game_manager.has_method("play_board_effect_animation"):
		await game_manager.play_board_effect_animation(animation_key)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null or get_effect_owner_id(source_state, effect_data) == "":
		return false
	return str(effect_data.get(KEY_OPERATION, "")) in [
		OPERATION_RECORD_SEVERANCE,
		OPERATION_RECORD_DEATH,
	]


func record_with_local_resolver(
	game_manager: Node,
	owner_id: String,
	pool_card_id: String
) -> Array[String]:
	var unlocked_cards: Array[String] = []
	if not game_manager.has_method("get_player_by_id"):
		return unlocked_cards
	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	var card_database := game_manager.get("card_database") as CardDatabase
	if player == null or card_database == null:
		return unlocked_cards
	var resolver := SymbioteOffspringPoolResolverScript.new()
	if pool_card_id == "":
		return resolver.record_severance(player, card_database)
	else:
		return resolver.record_offspring_death(player, card_database, pool_card_id)


func get_unlock_animation_key(unlocked_cards: Array[String]) -> String:
	if unlocked_cards.has("symbiote_hybrid"):
		return "symbiote_pool_unlock_hybrid"
	if unlocked_cards.has("symbiote_silence"):
		return "symbiote_pool_unlock_silence"
	for card_id in ["toxin", "carnage", "sleeper"]:
		if unlocked_cards.has(card_id):
			return "symbiote_pool_unlock_advanced"
	return ""


func normalize_card_ids(raw_values: Variant) -> Array[String]:
	var card_ids: Array[String] = []
	if not raw_values is Array:
		return card_ids
	for raw_value in raw_values:
		var card_id := str(raw_value)
		if card_id != "" and not card_ids.has(card_id):
			card_ids.append(card_id)
	return card_ids
