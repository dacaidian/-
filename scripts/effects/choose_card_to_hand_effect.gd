extends CardEffect
class_name ChooseCardToHandEffect

# Generic effect: choose one or more configured cards, then add the selected
# cards plus optional bonus cards to the effect owner's hand.

func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null:
		return

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return

	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	if player == null:
		return

	var candidate_cards := get_candidate_cards(effect_data, game_manager)
	if candidate_cards.is_empty():
		return

	var max_select: int = mini(get_select_amount(effect_data), candidate_cards.size())
	if max_select <= 0:
		return

	var controller := CardMultiSelectController.new()
	var selected_indices: Array[int] = await controller.show_panel(
		game_manager.get_parent(),
		EffectData.get_selection_title(effect_data),
		create_candidate_view_data(candidate_cards),
		max_select
	)

	if selected_indices.is_empty():
		return

	for index in selected_indices:
		if index < 0 or index >= candidate_cards.size():
			continue
		player.add_to_hand(candidate_cards[index])

	add_bonus_cards_to_hand(player, effect_data, game_manager)
	refresh_views(game_manager)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null:
		return false

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return false

	if game_manager.get_player_by_id(owner_id) == null:
		return false

	return not get_candidate_cards(effect_data, game_manager).is_empty()


func get_select_amount(effect_data: Dictionary) -> int:
	var amount := EffectData.get_amount(effect_data)
	return 1 if amount <= 0 else amount


func get_candidate_cards(effect_data: Dictionary, game_manager: Node) -> Array[CardData]:
	var cards: Array[CardData] = []
	if game_manager == null or not game_manager.has_method("get_card_data_by_id"):
		return cards

	for card_id in EffectData.get_card_ids(effect_data):
		var card_data := game_manager.get_card_data_by_id(card_id) as CardData
		if card_data != null:
			cards.append(card_data)

	return cards


func create_candidate_view_data(candidate_cards: Array[CardData]) -> Array[Dictionary]:
	var view_data: Array[Dictionary] = []
	for card_data in candidate_cards:
		if card_data == null:
			continue

		view_data.append({
			"name": card_data.display_name,
			"attack": card_data.attack,
			"health": card_data.health,
			"front_texture_path": card_data.front_texture_path,
		})

	return view_data


func add_bonus_cards_to_hand(player: PlayerState, effect_data: Dictionary, game_manager: Node) -> void:
	for bonus_card in EffectData.get_bonus_cards(effect_data):
		var card_id := str(bonus_card.get(EffectData.KEY_CARD_ID, ""))
		if card_id == "":
			continue

		var card_data := game_manager.get_card_data_by_id(card_id) as CardData
		if card_data == null:
			continue

		var amount: int = int(bonus_card.get(EffectData.KEY_AMOUNT, 1))
		for copy_index in range(maxi(amount, 0)):
			player.add_to_hand(card_data)


func refresh_views(game_manager: Node) -> void:
	if game_manager.has_method("update_hand_drawer_view"):
		game_manager.update_hand_drawer_view()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()
