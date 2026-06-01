extends CardEffect
class_name GrantBoardVisionEffect

# Grants temporary board-card preview access to the effect owner.
# Current card data uses scope="global"; future cards can grant individual
# slot vision by passing runtime-selected slot indices through this effect.

const SCOPE_GLOBAL := "global"
const SCOPE_SELECTED_SLOT := "selected_slot"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" and source_state != null:
		owner_id = source_state.owner_id
	if owner_id == "":
		return

	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	if player == null:
		return

	var scope := str(effect_data.get("scope", SCOPE_GLOBAL))
	match scope:
		SCOPE_SELECTED_SLOT:
			var selected_state := EffectData.get_selected_target_state(effect_data)
			if selected_state != null:
				player.grant_board_slot_vision_until_turn_end(selected_state.slot_index)
		_:
			player.grant_global_board_vision_until_turn_end()
