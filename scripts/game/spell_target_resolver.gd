extends RefCounted
class_name SpellTargetResolver

# SpellTargetResolver 统一解释法术目标规则。
# 随从 spell_actions 和手牌法术都走这里，避免未来扩展目标限制时两边分叉。

const TARGET_RULE_ALL_MINIONS := "all_minions"
const TARGET_RULE_NON_HERO_MINIONS := "non_hero_minions"
const TARGET_RULE_FRIENDLY_NON_HERO_MINIONS := "friendly_non_hero_minions"
const TARGET_RULE_ENEMY_MINIONS := "enemy_minions"
const TARGET_RULE_ENEMY_UNITS := "enemy_units"
const TARGET_RULE_LOW_STAT_NON_HERO_MINIONS := "low_stat_non_hero_minions"
const TARGET_RULE_ALL_UNITS := "all_units"
const TARGET_RULE_NONE := "none"
const TARGET_RULE_AREA_3X3 := "area_3x3"
const TARGET_RULE_AREA_2X2 := "area_2x2"
const TARGET_RULE_EMPTY_OR_HIDDEN_SLOTS := "empty_or_hidden_slots"
const TARGET_RULE_MINIONS_BY_CARD_IDS := "minions_by_card_ids"
const TARGET_RULE_SPELLCASTER_MINIONS_OR_HEROES := "spellcaster_minions_or_heroes"
const TARGET_RULE_ADJACENT_MINIONS := "adjacent_minions"
const TARGET_RULE_DIRECTION_RAY := "direction_ray"


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


static func get_valid_targets(
	target_rule: String,
	game_manager: GameManager,
	card_ids: Array[String] = [],
	source_state: CardState = null,
	source_owner_id: String = ""
) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null or not requires_target(target_rule):
		return targets

	var candidate_states: Array[CardState] = game_manager.board_states
	if target_rule != TARGET_RULE_EMPTY_OR_HIDDEN_SLOTS and game_manager.has_method("get_all_board_states"):
		candidate_states = game_manager.get_all_board_states()

	for state in candidate_states:
		if target_rule == TARGET_RULE_EMPTY_OR_HIDDEN_SLOTS and game_manager.has_method("can_place_ground_card_on_slot"):
			if not game_manager.can_place_ground_card_on_slot(state.slot_index):
				continue
		if is_area_rule(target_rule) and not is_valid_area_target(target_rule, state, game_manager):
			continue
		if can_target(target_rule, state, card_ids, source_state, source_owner_id, game_manager):
			targets.append(state)

	return targets


static func can_target(
	target_rule: String,
	target: CardState,
	card_ids: Array[String] = [],
	source_state: CardState = null,
	source_owner_id: String = "",
	game_manager: GameManager = null,
	require_direct_selection := true
) -> bool:
	if target == null:
		return false

	var resolved_source_owner_id := resolve_source_owner_id(source_state, source_owner_id)
	if is_area_rule(target_rule):
		return can_select_area_center(target, resolved_source_owner_id)

	if target_rule == TARGET_RULE_EMPTY_OR_HIDDEN_SLOTS:
		return target.is_empty() or not target.is_face_up

	if not BoardQuery.is_face_up_board_card(target):
		return false

	if require_direct_selection and target.is_stealthed_from_player(resolved_source_owner_id):
		return false

	if target_rule == TARGET_RULE_ADJACENT_MINIONS:
		return is_adjacent_minion_target(source_state, target, game_manager)

	if require_direct_selection and is_magic_immune(target):
		return false

	match target_rule:
		TARGET_RULE_ALL_MINIONS:
			return target.is_minion()
		TARGET_RULE_NON_HERO_MINIONS:
			return target.is_minion() and not target.is_hero()
		TARGET_RULE_FRIENDLY_NON_HERO_MINIONS:
			return (
				target.is_minion()
				and not target.is_hero()
				and resolved_source_owner_id != ""
				and target.owner_id == resolved_source_owner_id
			)
		TARGET_RULE_ENEMY_MINIONS:
			return (
				target.is_minion()
				and resolved_source_owner_id != ""
				and target.owner_id != ""
				and target.owner_id != resolved_source_owner_id
			)
		TARGET_RULE_ENEMY_UNITS:
			return (
				target.is_unit()
				and resolved_source_owner_id != ""
				and target.owner_id != ""
				and target.owner_id != resolved_source_owner_id
			)
		TARGET_RULE_LOW_STAT_NON_HERO_MINIONS:
			return target.is_minion() and not target.is_hero() and get_current_attribute_total(target) <= 8
		TARGET_RULE_ALL_UNITS:
			return target.is_unit()
		TARGET_RULE_MINIONS_BY_CARD_IDS:
			return target.is_minion() and target != source_state and is_state_in_card_filter(target, card_ids)
		TARGET_RULE_SPELLCASTER_MINIONS_OR_HEROES:
			return target.is_hero() or (target.is_minion() and has_spell_action_capability(target, game_manager))
		TARGET_RULE_ADJACENT_MINIONS:
			return is_adjacent_minion_target(source_state, target, game_manager)
		TARGET_RULE_EMPTY_OR_HIDDEN_SLOTS:
			return target.is_empty() or not target.is_face_up
		TARGET_RULE_NONE:
			return false
		TARGET_RULE_DIRECTION_RAY:
			return false
		_:
			push_warning("暂不支持的法术目标规则: %s" % target_rule)
			return false


static func get_current_attribute_total(target: CardState) -> int:
	if target == null:
		return 0

	return target.current_attack + target.current_health


static func is_state_in_card_filter(state: CardState, card_ids: Array[String]) -> bool:
	if state == null:
		return false

	for card_id in card_ids:
		if state.represents_card_id(card_id):
			return true

	return false


static func has_spell_action_capability(target: CardState, game_manager: GameManager = null) -> bool:
	if target == null or target.data == null or not target.is_minion():
		return false

	if not target.data.spell_actions.is_empty():
		return true

	if game_manager == null:
		return false

	var granted_spell_resolver := GrantedSpellResolver.new()
	return not granted_spell_resolver.get_granted_spell_actions(target, game_manager).is_empty()


static func is_adjacent_minion_target(source_state: CardState, target: CardState, game_manager: GameManager = null) -> bool:
	if source_state == null or target == null or game_manager == null:
		return false
	if source_state == target:
		return false
	if not target.is_minion():
		return false
	if source_state.slot_index == target.slot_index:
		return true

	return BoardQuery.is_neighbor(source_state.slot_index, target.slot_index, game_manager.board_columns)


static func can_select_area_center(target: CardState, source_owner_id: String = "") -> bool:
	if target == null:
		return false

	if BoardQuery.is_face_up_board_card(target) and target.is_stealthed_from_player(source_owner_id):
		return false

	if BoardQuery.is_face_up_board_card(target) and is_magic_immune(target):
		return false

	return true


static func can_spell_affect(target: CardState) -> bool:
	return not is_magic_immune(target)


static func is_magic_immune(target: CardState) -> bool:
	return (
		target != null
		and BoardQuery.is_face_up_board_card(target)
		and target.has_keyword(CardData.KEYWORD_MAGIC_IMMUNE)
	)


static func resolve_source_owner_id(source_state: CardState, fallback_owner_id: String = "") -> String:
	if source_state != null and source_state.owner_id != "":
		return source_state.owner_id

	return fallback_owner_id


static func is_area_rule(target_rule: String) -> bool:
	return target_rule == TARGET_RULE_AREA_3X3 or target_rule == TARGET_RULE_AREA_2X2


static func is_valid_area_target(target_rule: String, target: CardState, game_manager: GameManager) -> bool:
	if target == null or game_manager == null:
		return false

	var dimensions := get_area_dimensions(target_rule)
	if dimensions.is_empty():
		return false

	var rows := int(dimensions.get("rows", 0))
	var cols := int(dimensions.get("cols", 0))
	if rows <= 0 or cols <= 0:
		return false

	return BoardQuery.is_full_area_inside_board(target.slot_index, rows, cols, game_manager.board_columns, game_manager.board_states.size())


static func get_area_dimensions(target_rule: String) -> Dictionary:
	match target_rule:
		TARGET_RULE_AREA_3X3:
			return {"rows": 3, "cols": 3}
		TARGET_RULE_AREA_2X2:
			return {"rows": 2, "cols": 2}
		_:
			return {}
