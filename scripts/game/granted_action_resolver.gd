extends RefCounted
class_name GrantedActionResolver

# Dynamic board actions granted by current board state. This keeps special
# action sources out of ActionRegistry's fixed baseline action list.


func get_granted_actions(user: CardState, game_manager: GameManager) -> Array[CardAction]:
	var actions: Array[CardAction] = []
	if user == null or game_manager == null:
		return actions

	var inject_action := InjectVenomAction.new()
	if inject_action.can_start(user, game_manager):
		actions.append(inject_action)

	var burst_action := VenomBurstAction.new()
	if burst_action.can_start(user, game_manager):
		actions.append(burst_action)

	append_card_configured_actions(actions, user, game_manager)
	append_hand_granted_actions(actions, user, game_manager)
	return actions


func append_card_configured_actions(actions: Array[CardAction], user: CardState, game_manager: GameManager) -> void:
	if user == null or user.data == null:
		return

	for action_data in user.data.actions:
		var action := create_action_from_data(action_data)
		if action != null and action.can_start(user, game_manager):
			actions.append(action)


func append_hand_granted_actions(actions: Array[CardAction], user: CardState, game_manager: GameManager) -> void:
	var owner := game_manager.get_player_by_id(user.owner_id) as PlayerState
	if owner == null:
		return

	for card_entry in owner.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not is_grant_actions_effect(effect_data):
				continue
			if not EffectData.get_card_ids(effect_data).has(user.card_id):
				continue

			for action_data in EffectData.get_actions(effect_data):
				var action := create_action_from_data(action_data)
				if action != null:
					actions.append(action)


func is_grant_actions_effect(effect_data: Dictionary) -> bool:
	return (
		EffectData.get_id(effect_data) == EffectData.EFFECT_GRANT_ACTIONS
		and EffectData.is_active_in_hand(effect_data)
	)


func create_action_from_data(action_data: Dictionary) -> CardAction:
	match EffectData.get_action_id(action_data):
		FixedMeleeDamageAction.ACTION_ID, "claw_strike":
			return FixedMeleeDamageAction.new().setup(action_data)
		DirectionalMoveAction.ACTION_ID, "westward":
			return DirectionalMoveAction.new().setup(action_data)
		_:
			if action_data.has("effects"):
				return EffectAction.new().setup(action_data)
			return null
