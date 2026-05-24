extends RefCounted
class_name ActionRegistry

# 行动注册表负责集中管理所有行动类型。
# 第一版所有随从都拥有移动能力；后续可从 JSON 或关键词决定可用行动。

var actions_by_id: Dictionary = {}
var granted_spell_resolver := GrantedSpellResolver.new()
var granted_action_resolver := GrantedActionResolver.new()


func _init() -> void:
	register_action(MoveAction.new())
	register_action(AttackAction.new())
	register_action(InjectVenomAction.new())
	register_action(VenomBurstAction.new())


func register_action(action: CardAction) -> void:
	if action == null or action.id == "":
		return

	actions_by_id[action.id] = action


func get_action(action_id: String) -> CardAction:
	return actions_by_id.get(action_id) as CardAction


func get_available_actions(user: CardState, game_manager: GameManager) -> Array[CardAction]:
	var actions: Array[CardAction] = []

	if user == null or user.data == null:
		return actions

	if user.is_minion():
		append_if_available(actions, get_action("move"), user, game_manager)
		append_if_available(actions, get_action("attack"), user, game_manager)
		append_spell_actions(actions, user, game_manager)

	for granted_action in granted_action_resolver.get_granted_actions(user, game_manager):
		append_if_available(actions, granted_action, user, game_manager)

	return actions


func append_spell_actions(actions: Array[CardAction], user: CardState, game_manager: GameManager) -> void:
	if user == null or user.data == null or game_manager == null:
		return

	if not game_manager.is_spell_turn_active:
		return

	for spell_data in get_spell_action_data_for_user(user, game_manager):
		var spell_action := SpellAction.new().setup(spell_data)
		register_action(spell_action)
		append_if_available(actions, spell_action, user, game_manager)


func get_spell_action_data_for_user(user: CardState, game_manager: GameManager) -> Array[Dictionary]:
	var spell_actions: Array[Dictionary] = []
	var known_spell_ids: Array[String] = []
	if user == null or user.data == null:
		return spell_actions

	append_unique_spell_data(spell_actions, known_spell_ids, user.data.spell_actions)
	append_unique_spell_data(
		spell_actions,
		known_spell_ids,
		granted_spell_resolver.get_granted_spell_actions(user, game_manager)
	)
	return spell_actions


func append_unique_spell_data(
	spell_actions: Array[Dictionary],
	known_spell_ids: Array[String],
	raw_spell_actions: Array
) -> void:
	for spell_data in raw_spell_actions:
		if not spell_data is Dictionary:
			continue

		var spell_id := str(spell_data.get("id", ""))
		if spell_id == "" or known_spell_ids.has(spell_id):
			continue

		known_spell_ids.append(spell_id)
		spell_actions.append(spell_data)


func append_if_available(
	actions: Array[CardAction],
	action: CardAction,
	user: CardState,
	game_manager: GameManager
) -> void:
	if action == null or not action.can_start(user, game_manager):
		return

	if action.requires_target() and action.get_valid_targets(user, game_manager).is_empty():
		return

	actions.append(action)
