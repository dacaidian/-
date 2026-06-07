extends RefCounted
class_name ActionResourceResolver

# Centralizes main action resource and action-group compatibility rules.
# CardState keeps the public API, while this resolver owns how keywords,
# cached pairs, and current usage combine into the final answer.

const ACTION_GROUP_MOVE := "move"
const ACTION_GROUP_ATTACK := "attack"
const ACTION_GROUP_SPELL := "spell"


static func can_take_action_group(state: CardState, action_group: String, can_reuse_used_group := true) -> bool:
	if state == null:
		return false
	if state.has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION):
		return false
	if action_group == "":
		return true

	if state.used_action_groups.has(action_group):
		return can_reuse_used_group

	var effective_max_main_actions := get_effective_max_main_actions(state)
	if effective_max_main_actions <= 0:
		return false

	if state.used_action_groups.size() >= effective_max_main_actions:
		return false

	for used_group in state.used_action_groups:
		if not can_combine_action_groups(state, used_group, action_group):
			return false

	return true


static func can_combine_action_groups(state: CardState, first_group: String, second_group: String) -> bool:
	if state == null:
		return false
	if first_group == second_group:
		return true

	if state.allowed_action_group_pairs.has(create_action_group_pair_key(first_group, second_group)):
		return true

	return can_combine_action_groups_from_current_keywords(state, first_group, second_group)


static func get_effective_max_main_actions(state: CardState) -> int:
	if state == null:
		return 0

	var value := state.max_main_actions
	if has_move_attack_compatibility(state):
		value = maxi(value, 2)
	if state.has_keyword(CardData.KEYWORD_SPELL_MOVE):
		value = maxi(value, 2)
	if state.has_keyword(CardData.KEYWORD_SPELL_ATTACK):
		value = maxi(value, 2)

	return value


static func refresh_action_keyword_passives(state: CardState) -> void:
	if state == null or state.data == null or not state.data.is_unit():
		return

	state.max_main_actions = int(state.origin.get("main_actions", state.max_main_actions))
	state.allowed_action_group_pairs = normalize_string_array(state.origin.get("allowed_action_group_pairs", []))

	if has_move_attack_compatibility(state):
		state.max_main_actions = maxi(state.max_main_actions, 2)
		add_action_group_pair(state.allowed_action_group_pairs, ACTION_GROUP_MOVE, ACTION_GROUP_ATTACK)
	if state.has_keyword(CardData.KEYWORD_SPELL_MOVE):
		state.max_main_actions = maxi(state.max_main_actions, 2)
		add_action_group_pair(state.allowed_action_group_pairs, ACTION_GROUP_MOVE, ACTION_GROUP_SPELL)
	if state.has_keyword(CardData.KEYWORD_SPELL_ATTACK):
		state.max_main_actions = maxi(state.max_main_actions, 2)
		add_action_group_pair(state.allowed_action_group_pairs, ACTION_GROUP_ATTACK, ACTION_GROUP_SPELL)

	state.refresh_current_main_actions()


static func can_combine_action_groups_from_current_keywords(
	state: CardState,
	first_group: String,
	second_group: String
) -> bool:
	if state == null:
		return false

	var pair_key := create_action_group_pair_key(first_group, second_group)
	if pair_key == create_action_group_pair_key(ACTION_GROUP_MOVE, ACTION_GROUP_ATTACK):
		return has_move_attack_compatibility(state)
	if pair_key == create_action_group_pair_key(ACTION_GROUP_MOVE, ACTION_GROUP_SPELL):
		return state.has_keyword(CardData.KEYWORD_SPELL_MOVE)
	if pair_key == create_action_group_pair_key(ACTION_GROUP_ATTACK, ACTION_GROUP_SPELL):
		return state.has_keyword(CardData.KEYWORD_SPELL_ATTACK)

	return false


static func has_move_attack_compatibility(state: CardState) -> bool:
	if state == null:
		return false

	return state.has_keyword(CardData.KEYWORD_CAVALRY) or state.has_keyword(CardData.KEYWORD_MOBILE_ASSAULT)


static func add_action_group_pair(pairs: Array[String], first_group: String, second_group: String) -> void:
	var pair_key := create_action_group_pair_key(first_group, second_group)
	if not pairs.has(pair_key):
		pairs.append(pair_key)


static func create_action_group_pair_key(first_group: String, second_group: String) -> String:
	var groups := [first_group, second_group]
	groups.sort()
	return "%s|%s" % [groups[0], groups[1]]


static func normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))

	return result
