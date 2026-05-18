extends RefCounted
class_name GrantedSpellResolver

# 解析手牌升级牌授予的法术动作。
# ActionRegistry 只负责把动作变成 CardAction，这里负责解释升级牌 JSON。

func get_granted_spell_actions(user: CardState, game_manager: GameManager) -> Array[Dictionary]:
	var granted_spell_actions: Array[Dictionary] = []
	if user == null or game_manager == null:
		return granted_spell_actions

	var owner := game_manager.get_player_by_id(user.owner_id) as PlayerState
	if owner == null:
		return granted_spell_actions

	for card_entry in owner.hand:
		var card_data := get_card_data_from_hand_entry(card_entry)
		if card_data == null or not card_data.is_upgrade():
			continue

		append_granted_spell_actions_from_card(granted_spell_actions, user, card_data)

	return granted_spell_actions


func append_granted_spell_actions_from_card(
	granted_spell_actions: Array[Dictionary],
	user: CardState,
	card_data: CardData
) -> void:
	for effect_data in card_data.effects:
		if not is_grant_spell_actions_effect(effect_data):
			continue
		if not does_grant_apply_to_user(effect_data, user):
			continue

		for spell_data in EffectData.get_spell_actions(effect_data):
			granted_spell_actions.append(spell_data)


func is_grant_spell_actions_effect(effect_data: Dictionary) -> bool:
	return (
		EffectData.get_id(effect_data) == EffectData.EFFECT_GRANT_SPELL_ACTIONS
		and EffectData.is_active_in_hand(effect_data)
	)


func does_grant_apply_to_user(effect_data: Dictionary, user: CardState) -> bool:
	if user == null:
		return false

	var card_ids := EffectData.get_card_ids(effect_data)
	if card_ids.is_empty():
		return true

	return card_ids.has(user.card_id)


func get_card_data_from_hand_entry(card_entry: Variant) -> CardData:
	return HandCardState.get_card_data(card_entry)
