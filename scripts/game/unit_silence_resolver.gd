extends RefCounted
class_name UnitSilenceResolver

# Silence is an enemy aura rule, not a status copied onto every unit. This keeps
# the source authoritative and makes the effect disappear immediately with it.


func is_unit_silenced(state: CardState, game_manager: Node) -> bool:
	if state == null or game_manager == null or state.owner_id == "":
		return false
	if not BoardQuery.is_face_up_unit(state):
		return false
	return has_enemy_silence_aura(state.owner_id, game_manager)


func is_hero_attached_spell_silenced(
	owner_id: String,
	hero_card_id: String,
	game_manager: Node
) -> bool:
	if owner_id == "" or hero_card_id == "" or game_manager == null:
		return false
	for state in game_manager.get_all_board_states():
		if (
			BoardQuery.is_face_up_unit(state)
			and state.owner_id == owner_id
			and state.represents_card_id(hero_card_id)
		):
			return is_unit_silenced(state, game_manager)
	return false


func has_enemy_silence_aura(owner_id: String, game_manager: Node) -> bool:
	if owner_id == "" or game_manager == null or not game_manager.has_method("get_all_board_states"):
		return false
	for source_state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_unit(source_state):
			continue
		if source_state.current_health <= 0 or source_state.is_pending_death:
			continue
		if source_state.owner_id == "" or source_state.owner_id == owner_id:
			continue
		if source_state.has_keyword(CardData.KEYWORD_SILENCE_AURA):
			return true
	return false
