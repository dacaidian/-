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

		append_granted_spell_actions_from_card(granted_spell_actions, user, card_data, owner)

	return granted_spell_actions


func append_granted_spell_actions_from_card(
	granted_spell_actions: Array[Dictionary],
	user: CardState,
	card_data: CardData,
	owner: PlayerState
) -> void:
	for effect_data in card_data.effects:
		if not does_grant_apply_to_user(effect_data, user):
			continue

		if is_grant_spell_actions_effect(effect_data):
			for spell_data in EffectData.get_spell_actions(effect_data):
				granted_spell_actions.append(spell_data)
		elif is_grant_last_spell_action_effect(effect_data):
			var spell_data := get_last_spell_action_for_effect(effect_data, owner)
			if not spell_data.is_empty():
				granted_spell_actions.append(spell_data)


func is_grant_spell_actions_effect(effect_data: Dictionary) -> bool:
	return (
		EffectData.get_id(effect_data) == EffectData.EFFECT_GRANT_SPELL_ACTIONS
		and EffectData.is_active_in_hand(effect_data)
	)


func is_grant_last_spell_action_effect(effect_data: Dictionary) -> bool:
	return (
		EffectData.get_id(effect_data) == EffectData.EFFECT_GRANT_LAST_SPELL_ACTION
		and EffectData.is_active_in_hand(effect_data)
	)


func get_last_spell_action_for_effect(effect_data: Dictionary, owner: PlayerState) -> Dictionary:
	if owner == null:
		return {}

	return owner.get_latest_spell_action_for_sources(EffectData.get_source_card_ids(effect_data))


func does_grant_apply_to_user(effect_data: Dictionary, user: CardState) -> bool:
	if user == null:
		return false

	var card_ids := EffectData.get_card_ids(effect_data)
	if card_ids.is_empty():
		return true

	for card_id in card_ids:
		if user.represents_card_id(card_id):
			return true

	return false


func get_card_data_from_hand_entry(card_entry: Variant) -> CardData:
	return HandCardState.get_card_data(card_entry)
