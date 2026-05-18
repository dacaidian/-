extends CardEffect
class_name ResurrectEffect

# 通用复活效果：从坟场选择卡牌移入手牌（或其他目标区域）。
# 通过 filter_type / filter_owner / target_zone 配置，可复用于不同卡牌。


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var amount := get_amount(effect_data)
	if amount <= 0:
		return

	var target_zone := EffectData.get_target_zone(effect_data)
	if target_zone != EffectData.TARGET_ZONE_HAND:
		push_warning("暂不支持的复活目标区域: %s" % target_zone)
		return

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return

	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	if player == null:
		return

	var filter_type := EffectData.get_filter_type(effect_data)
	var filter_owner := EffectData.get_filter_owner(effect_data)

	var candidates: Array[Dictionary] = []
	var candidate_indices: Array[int] = []

	for i in range(player.graveyard.size()):
		var snapshot: Dictionary = player.graveyard[i]
		if _matches_filter(snapshot, filter_type, filter_owner, player.id):
			var origin: Dictionary = snapshot.get("origin", {})
			candidates.append({
				"name": str(origin.get("display_name", "???")) if origin.has("display_name") else str(origin.get("card_id", "???")),
				"attack": int(origin.get("attack", 0)),
				"health": int(origin.get("health", 0)),
				"front_texture_path": str(origin.get("front_texture_path", "")),
			})
			candidate_indices.append(i)

	if candidates.is_empty():
		return

	var max_select := mini(amount, candidates.size())
	var title := "选择要复活的随从（最多%d个）" % max_select

	var root := game_manager.get_parent()
	var controller := CardMultiSelectController.new()
	var selected_indices: Array[int] = await controller.show_panel(root, title, candidates, max_select)

	if selected_indices.is_empty():
		return

	# 从大到小排序，避免删除低索引后高索引偏移
	selected_indices.sort()
	selected_indices.reverse()

	for selection_order_index in selected_indices:
		var graveyard_index := candidate_indices[selection_order_index]
		var snapshot: Dictionary = player.graveyard[graveyard_index]
		var origin: Dictionary = snapshot.get("origin", {})
		var card_data: CardData = origin.get("data") as CardData
		if card_data != null:
			_add_resurrected_card_to_zone(player, card_data, target_zone)
		player.remove_from_graveyard_at(graveyard_index)

	if game_manager.has_method("update_hand_drawer_view"):
		game_manager.update_hand_drawer_view()
	if game_manager.has_method("refresh_debug_panel"):
		game_manager.refresh_debug_panel()


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var amount := get_amount(effect_data)
	if amount <= 0:
		return false

	var target_zone := EffectData.get_target_zone(effect_data)
	if target_zone != EffectData.TARGET_ZONE_HAND:
		return false

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "" or game_manager == null or not game_manager.has_method("get_player_by_id"):
		return false

	var player := game_manager.get_player_by_id(owner_id) as PlayerState
	if player == null:
		return false

	return has_candidates(player, effect_data)


func has_candidates(player: PlayerState, effect_data: Dictionary) -> bool:
	if player == null:
		return false

	var target_zone := EffectData.get_target_zone(effect_data)
	if target_zone != EffectData.TARGET_ZONE_HAND:
		return false

	var filter_type := EffectData.get_filter_type(effect_data)
	var filter_owner := EffectData.get_filter_owner(effect_data)
	for snapshot in player.graveyard:
		if _matches_filter(snapshot, filter_type, filter_owner, player.id):
			return true

	return false


func _add_resurrected_card_to_zone(player: PlayerState, card_data: CardData, target_zone: String) -> void:
	match target_zone:
		EffectData.TARGET_ZONE_HAND:
			player.add_to_hand(card_data)
		_:
			push_warning("暂不支持的复活目标区域: %s" % target_zone)


func _matches_filter(snapshot: Dictionary, filter_type: String, filter_owner: String, player_id: String) -> bool:
	var origin: Dictionary = snapshot.get("origin", {})
	var snapshot_type := str(origin.get("type", ""))

	if filter_type == "minion":
		if snapshot_type != "minion":
			return false
	elif filter_type == "building":
		if snapshot_type != "building":
			return false

	if filter_owner == "self":
		var last_state: Dictionary = snapshot.get("last_state", {})
		var owner_id := str(last_state.get("owner_id", ""))
		if owner_id != player_id:
			return false

	return true
