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

	match str(effect_data.get(KEY_OPERATION, "")):
		OPERATION_RECORD_SEVERANCE:
			if game_manager.has_method("record_symbiote_severance"):
				game_manager.record_symbiote_severance(owner_id)
			else:
				record_with_local_resolver(game_manager, owner_id, "")
		OPERATION_RECORD_DEATH:
			var pool_card_id := str(effect_data.get(KEY_POOL_CARD_ID, ""))
			if pool_card_id == "" and source_state != null:
				pool_card_id = source_state.card_id
			if game_manager.has_method("record_symbiote_offspring_death"):
				game_manager.record_symbiote_offspring_death(owner_id, pool_card_id)
			else:
				record_with_local_resolver(game_manager, owner_id, pool_card_id)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null or get_effect_owner_id(source_state, effect_data) == "":
		return false
	return str(effect_data.get(KEY_OPERATION, "")) in [
		OPERATION_RECORD_SEVERANCE,
		OPERATION_RECORD_DEATH,
	]


func record_with_local_resolver(game_manager: Node, owner_id: String, pool_card_id: String) -> void:
	if not game_manager.has_method("get_player_by_id"):
		return
	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	var card_database := game_manager.get("card_database") as CardDatabase
	if player == null or card_database == null:
		return
	var resolver := SymbioteOffspringPoolResolverScript.new()
	if pool_card_id == "":
		resolver.record_severance(player, card_database)
	else:
		resolver.record_offspring_death(player, card_database, pool_card_id)
