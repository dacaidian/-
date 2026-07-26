extends CardEffect
class_name DestroyLinkedUnitsEffect

# Destroys all currently linked partners for the status that triggered this effect.
# It is used by life_link status on on_destroyed and intentionally deals no damage.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null or source_state == null:
		return

	var link_id := get_link_id(effect_data)
	if link_id == "":
		return

	var animation_key := str(effect_data.get(EffectData.KEY_ANIMATION, "gu_life_link_death"))
	for linked_state in get_linked_states(gm, source_state, link_id):
		if animation_key != "" and gm.has_method("play_link_units_animation"):
			await gm.play_link_units_animation(source_state, linked_state, animation_key)
		await gm.destroy_card_with_refill(linked_state, EffectData.DEATH_REASON_LINKED, source_state, true)


func get_link_id(effect_data: Dictionary) -> String:
	var trigger_status := EffectData.get_trigger_status(effect_data)
	if trigger_status != null:
		return str(trigger_status.payload.get(EffectData.KEY_LINK_ID, ""))

	return str(effect_data.get(EffectData.KEY_LINK_ID, ""))


func get_linked_states(gm: GameManager, source_state: CardState, link_id: String) -> Array[CardState]:
	var linked_states: Array[CardState] = []
	for state in gm.get_all_board_states():
		if state == null or state == source_state:
			continue
		if state.is_empty() or not state.is_unit() or state.is_pending_death:
			continue
		if has_life_link_status(state, link_id):
			linked_states.append(state)

	return linked_states


func has_life_link_status(state: CardState, link_id: String) -> bool:
	for status in state.statuses:
		if status == null or status.status_id != CardStatus.STATUS_LIFE_LINK:
			continue
		if str(status.payload.get(EffectData.KEY_LINK_ID, "")) == link_id:
			return true

	return false
