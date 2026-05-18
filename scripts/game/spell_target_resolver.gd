extends RefCounted
class_name SpellTargetResolver

# SpellTargetResolver 统一解释法术目标规则。
# 随从 spell_actions 和手牌法术都走这里，避免未来扩展目标限制时两边分叉。

const TARGET_RULE_ALL_MINIONS := "all_minions"
const TARGET_RULE_ALL_UNITS := "all_units"
const TARGET_RULE_NONE := "none"


static func get_rule_from_spell_data(spell_data: Dictionary) -> String:
	return str(spell_data.get("target_rule", TARGET_RULE_ALL_MINIONS))


static func get_rule_from_card_data(card_data: CardData) -> String:
	if card_data == null:
		return TARGET_RULE_NONE

	if card_data.target_rule != "":
		return card_data.target_rule

	return TARGET_RULE_ALL_MINIONS


static func requires_target(target_rule: String) -> bool:
	return target_rule != TARGET_RULE_NONE


static func get_valid_targets(target_rule: String, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null or not requires_target(target_rule):
		return targets

	if target_rule == TARGET_RULE_ALL_MINIONS:
		return BoardQuery.get_face_up_minions(game_manager.board_states)

	for state in game_manager.board_states:
		if can_target(target_rule, state):
			targets.append(state)

	return targets


static func can_target(target_rule: String, target: CardState) -> bool:
	if not BoardQuery.is_face_up_board_card(target):
		return false

	match target_rule:
		TARGET_RULE_ALL_MINIONS:
			return target.is_minion()
		TARGET_RULE_ALL_UNITS:
			return target.is_unit()
		TARGET_RULE_NONE:
			return false
		_:
			push_warning("暂不支持的法术目标规则: %s" % target_rule)
			return false
