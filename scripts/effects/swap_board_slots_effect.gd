extends CardEffect
class_name SwapBoardSlotsEffect

const BoardPairSelectionControllerScript := preload("res://scripts/game/board_pair_selection_controller.gd")

# Generic effect: repeatedly select two board slots and swap their contents.
# BoardCell properties stay attached to their physical slot; only CardState content moves.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null:
		return

	var max_swaps := EffectData.get_amount(effect_data)
	if max_swaps <= 0:
		max_swaps = 1

	var owner_id := get_effect_owner_id(source_state, effect_data)
	var owner := gm.get_player_by_id(owner_id) as PlayerState
	if owner != null and owner.is_ai:
		return

	var controller := BoardPairSelectionControllerScript.new() as BoardPairSelectionController
	await controller.select_and_swap_pairs(
		gm,
		max_swaps,
		EffectData.get_selection_title(effect_data, "选择两个单元格交换")
	)


func can_execute(source_state: CardState, _effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	if gm == null or gm.board_states.size() < 2:
		return false

	if source_state != null:
		var owner := gm.get_player_by_id(source_state.owner_id) as PlayerState
		if owner != null and owner.is_ai:
			return false

	return true
