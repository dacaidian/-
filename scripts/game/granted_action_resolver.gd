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

	return actions
