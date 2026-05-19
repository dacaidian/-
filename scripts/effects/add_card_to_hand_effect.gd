extends CardEffect
class_name AddCardToHandEffect

# Generic effect: add configured cards to the effect owner's hand.
# Tokens and reward cards that do not enter the pool should use this path.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null:
		return

	var card_id := EffectData.get_card_id(effect_data)
	if card_id == "":
		return

	if not game_manager.has_method("get_card_data_by_id"):
		return

	var card_data := game_manager.get_card_data_by_id(card_id) as CardData
	if card_data == null:
		return

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return

	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	if player == null:
		return

	var amount := int(effect_data.get(EffectData.KEY_AMOUNT, 1))
	if amount <= 0:
		return

	for copy_index in range(amount):
		player.add_to_hand(card_data)

	if game_manager.has_method("update_hand_drawer_view"):
		game_manager.update_hand_drawer_view()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var card_id := EffectData.get_card_id(effect_data)
	if card_id == "":
		return false

	if game_manager == null or not game_manager.has_method("get_card_data_by_id"):
		return false

	return game_manager.get_card_data_by_id(card_id) != null
