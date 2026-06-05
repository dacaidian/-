extends CardEffect
class_name SyncStatsFromOwnerCardEffect

# Copies current attack and max health from one of the owner's board cards.
# Current use: Hair copies Sun Wukong when entering the board.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if source_state == null or game_manager == null:
		return

	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id == "":
		target_card_id = EffectData.get_card_id(effect_data)
	if target_card_id == "":
		return

	var reference_state := find_owner_card(source_state, target_card_id, game_manager)
	if reference_state == null:
		return

	source_state.set_current_attack(reference_state.current_attack)
	source_state.max_health = maxi(reference_state.max_health, 0)
	source_state.damage_taken = mini(source_state.damage_taken, source_state.max_health)
	source_state.state_changed.emit(source_state)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if source_state == null or game_manager == null:
		return false

	var target_card_id := EffectData.get_target_card_id(effect_data)
	if target_card_id == "":
		target_card_id = EffectData.get_card_id(effect_data)

	return target_card_id != "" and find_owner_card(source_state, target_card_id, game_manager) != null


func find_owner_card(source_state: CardState, card_id: String, game_manager: Node) -> CardState:
	if source_state == null or card_id == "" or game_manager == null or not game_manager.has_method("get_all_board_states"):
		return null

	for value in game_manager.get_all_board_states():
		var candidate := value as CardState
		if not BoardQuery.is_face_up_unit(candidate):
			continue
		if candidate.owner_id == source_state.owner_id and candidate.card_id == card_id:
			return candidate

	return null
