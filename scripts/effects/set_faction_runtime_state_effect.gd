extends CardEffect
class_name SetFactionRuntimeStateEffect

# Generic effect for faction runtime state jumps, such as Night Elf time changes.
# It changes the effect owner's faction runtime state by state id; the normal
# cycle order remains unchanged because PlayerState keeps using the same cycle.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var player := get_effect_owner_player(source_state, effect_data, game_manager)
	if player == null:
		return

	var state_id := str(effect_data.get(EffectData.KEY_RUNTIME_STATE_ID, ""))
	if state_id == "":
		return

	var previous_state_id := player.faction_runtime_state_id
	if not player.set_faction_runtime_state_by_id(state_id):
		return

	if game_manager.has_method("refresh_hand_passives_for_player"):
		game_manager.refresh_hand_passives_for_player(player, false)
	if game_manager.has_method("update_faction_time_panel_view"):
		game_manager.update_faction_time_panel_view()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()
	if (
		previous_state_id != player.faction_runtime_state_id
		and player.faction_id == "night_elf_sentinels"
		and game_manager.has_method("play_board_effect_animation")
	):
		var time_animation_key := "night_elf_time_transition"
		if player.faction_runtime_state_id != "":
			time_animation_key += "_%s" % player.faction_runtime_state_id
		await game_manager.play_board_effect_animation(time_animation_key)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var player := get_effect_owner_player(source_state, effect_data, game_manager)
	if player == null:
		return false

	var state_id := str(effect_data.get(EffectData.KEY_RUNTIME_STATE_ID, ""))
	return player.find_faction_runtime_state_index(state_id) >= 0


func get_effect_owner_player(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		return null

	return game_manager.get_player_by_id(owner_id) as PlayerState
