extends RefCounted
class_name BoardSlotEffectResolver

var effects_by_slot: Dictionary = {}


func add_slot_effect(effect: Variant) -> void:
	if effect == null or effect.slot_index < 0 or effect.effect_id == "":
		return

	var effects: Array = effects_by_slot.get(effect.slot_index, [])
	effects.append(effect)
	effects_by_slot[effect.slot_index] = effects


func get_slot_effects(slot_index: int) -> Array:
	return effects_by_slot.get(slot_index, [])


func resolve_unit_entered(game_manager: GameManager, state: CardState) -> void:
	if game_manager == null or state == null:
		return

	var slot_index := state.slot_index
	var effects: Array = effects_by_slot.get(slot_index, [])
	if effects.is_empty():
		return

	for effect_value in effects.duplicate():
		var slot_effect: Variant = effect_value
		if slot_effect == null:
			continue
		if not slot_effect.should_trigger_for_entering_unit(state):
			continue

		if slot_effect.consume_on_trigger:
			remove_slot_effect(slot_index, slot_effect)

		if slot_effect.trigger_animation != "":
			await game_manager.play_slot_effect_animation(state, slot_effect.trigger_animation)

		game_manager.destroy_card_with_refill(state, slot_effect.death_reason, null, true)
		return


func remove_slot_effect(slot_index: int, effect: Variant) -> void:
	var effects: Array = effects_by_slot.get(slot_index, [])
	if effects.is_empty():
		return

	effects.erase(effect)
	if effects.is_empty():
		effects_by_slot.erase(slot_index)
	else:
		effects_by_slot[slot_index] = effects
