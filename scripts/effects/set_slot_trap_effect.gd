extends CardEffect
class_name SetSlotTrapEffect

const BoardSlotEffectScript := preload("res://scripts/data/board_slot_effect.gd")

# Places a one-shot board slot effect on the selected slot.
# The slot effect lives on the board position, not on the card currently occupying it.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("set_board_slot_effect"):
		return

	var target_state := EffectData.get_selected_target_state(effect_data)
	if target_state == null:
		return

	var slot_effect := BoardSlotEffectScript.from_effect_data(target_state.slot_index, effect_data, source_state)
	game_manager.set_board_slot_effect(target_state.slot_index, slot_effect)
