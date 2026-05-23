extends RefCounted
class_name EffectData

# EffectData 集中管理 JSON 效果配置的字段名和基础读取逻辑。
# 它不执行效果，只让各个 resolver 使用同一套配置语言。

const KEY_ID := "id"
const KEY_TRIGGER := "trigger"
const KEY_ACTIVE_ZONE := "active_zone"
const KEY_CARD_IDS := "card_ids"
const KEY_SOURCE_CARD_IDS := "source_card_ids"
const KEY_SPELL_ACTIONS := "spell_actions"
const KEY_AMOUNT := "amount"
const KEY_TARGET := "target"
const KEY_SELECTED_TARGET_STATE := "_selected_target_state"
const KEY_EFFECT_OWNER_ID := "_effect_owner_id"
const KEY_DEATH_REASON := "death_reason"
const KEY_APPLY_SPELL_POWER := "_apply_spell_power"
const KEY_SPELL_POWER_SCALING := "spell_power_scaling"
const KEY_STATUS_ID := "status_id"
const KEY_STATUS_IDS := "status_ids"
const KEY_STATUS_NAME := "status_name"
const KEY_STATUS_DESCRIPTION := "status_description"
const KEY_STATUS_TAGS := "status_tags"
const KEY_STATUS_STACKS := "stacks"
const KEY_STATUS_STACK_POLICY := "stack_policy"
const KEY_STATUS_PERMANENT := "permanent"
const KEY_STATUS_DURATION_TURNS := "duration_turns"
const KEY_STATUS_DURATION_SCOPE := "duration_scope"
const KEY_STATUS_EXPIRES_ON_TRIGGER := "expires_on_trigger"
const KEY_STATUS_PERSISTS_AFTER_DEATH := "persists_after_death"
const KEY_STATUS_PAYLOAD := "payload"
const KEY_STATUS_TURN_EFFECTS := "turn_effects"
const KEY_STATUS_TRIGGER_EFFECTS := "trigger_effects"
const KEY_TRIGGER_STATUS := "_trigger_status"
const KEY_ATTACK_BONUS := "attack_bonus"
const KEY_MAX_HEALTH_BONUS := "max_health_bonus"
const KEY_CUMULATIVE_STATUS_MODIFIER := "cumulative_status_modifier"
const KEY_POISON_ATTACK_LEVEL := "poison_attack_level"
const KEY_POISON_DAMAGE := "poison_damage"
const KEY_FILTER_TYPE := "filter_type"
const KEY_FILTER_OWNER := "filter_owner"
const KEY_TARGET_ZONE := "target_zone"
const KEY_AMOUNT_SOURCE := "amount_source"
const KEY_CARD_ID := "card_id"
const KEY_TARGET_CARD_ID := "target_card_id"
const KEY_TRIGGER_PLAYER := "trigger_player"
const KEY_BONUS_CARDS := "bonus_cards"
const KEY_SELECTION_TITLE := "selection_title"
const KEY_REPLACE_EFFECTS := "replace_effects"
const KEY_APPEND_EFFECTS := "append_effects"
const KEY_TARGET_RELATION := "target_relation"
const KEY_AREA_ROWS := "area_rows"
const KEY_AREA_COLS := "area_cols"
const KEY_SLOT_EFFECT_ID := "slot_effect_id"
const KEY_SLOT_EFFECT_NAME := "slot_effect_name"
const KEY_SLOT_EFFECT_TRIGGER := "slot_effect_trigger"
const KEY_CONSUME_ON_TRIGGER := "consume_on_trigger"
const KEY_TRIGGER_ANIMATION := "trigger_animation"
const KEY_SOURCE_CARD_ID := "source_card_id"
const KEY_SOURCE_DISPLAY_NAME := "source_display_name"
const KEY_SET_DURATION_TURNS := "set_duration_turns"
const KEY_PRESERVE_TOTAL_DAMAGE := "preserve_total_damage"
const KEY_GRANTED_TRIGGER := "granted_trigger"
const KEY_GRANTED_EFFECTS := "granted_effects"
const KEY_LINK_ID := "link_id"

const ACTIVE_ZONE_HAND := "hand"
const TARGET_ZONE_HAND := "hand"

const EFFECT_GRANT_SPELL_ACTIONS := "grant_spell_actions"
const EFFECT_GRANT_LAST_SPELL_ACTION := "grant_last_spell_action"
const EFFECT_MODIFY_FLIP_CAPACITY := "modify_flip_capacity"
const EFFECT_PASSIVE_FLIP_BONUS := "passive_flip_bonus"
const EFFECT_APPLY_STATUS := "apply_status"
const EFFECT_SET_UNIT_MOVEMENT := "set_unit_movement"
const EFFECT_MODIFY_UNIT_ATTACK := "modify_unit_attack"
const EFFECT_MODIFY_SPELL_POWER := "modify_spell_power"
const EFFECT_MODIFY_HAND_SPELL_EFFECTS := "modify_hand_spell_effects"
const EFFECT_MODIFY_APPLIED_STATUS := "modify_applied_status"
const EFFECT_GRANT_UNIT_TRIGGER_EFFECTS := "grant_unit_trigger_effects"
const EFFECT_RESURRECT := "resurrect"
const EFFECT_GAIN_ATTACK := "gain_attack"
const EFFECT_PLAY_SPELL_ACTION := "play_spell_action"
const EFFECT_ADD_CARD_TO_HAND := "add_card_to_hand"
const EFFECT_CHOOSE_CARD_TO_HAND := "choose_card_to_hand"
const EFFECT_SET_SLOT_TRAP := "set_slot_trap"
const EFFECT_SWAP_BOARD_SLOTS := "swap_board_slots"
const EFFECT_DEVOUR := "devour"
const EFFECT_LINK_UNITS := "link_units"
const EFFECT_DESTROY_LINKED_UNITS := "destroy_linked_units"

const AMOUNT_SOURCE_EFFECTIVE_HEAL := "effective_heal"

const TRIGGER_WHILE_IN_HAND := "while_in_hand"
const TRIGGER_PASSIVE := "passive"

const TARGET_SELF := "self"
const TARGET_SELECTED := "selected"
const TARGET_OWNER := "owner"
const TARGET_DESTROYER := "destroyer"
const TARGET_TURN_PLAYER := "turn_player"
const TARGET_CURRENT_PLAYER := "current_player"
const TARGET_ADJACENT_TURN_PLAYER_MINIONS := "adjacent_turn_player_minions"
const TARGET_TURN_PLAYER_MINIONS_BY_CARD_IDS := "turn_player_minions_by_card_ids"
const TARGET_SELECTED_ADJACENT_ENEMY_MINIONS := "selected_adjacent_enemy_minions"
const TARGET_SELECTED_AREA_ENEMY_MINIONS := "selected_area_enemy_minions"
const TARGET_SELECTED_AREA_ALL_MINIONS := "selected_area_all_minions"
const TARGET_OWNER_CARD_BY_ID := "owner_card_by_id"
const TARGET_ATTACK_TARGET_ENEMY_UNIT := "attack_target_enemy_unit"
const TARGET_ATTACK_TARGET_ENEMY_MINION := "attack_target_enemy_minion"

const TRIGGER_PLAYER_ANY := "any"
const TRIGGER_PLAYER_SOURCE_OWNER := "source_owner"

const TARGET_RELATION_ANY := "any"
const TARGET_RELATION_FRIENDLY := "friendly"
const TARGET_RELATION_ENEMY := "enemy"

const DEATH_REASON_EFFECT := "effect"
const DEATH_REASON_SPELL := "spell"
const DEATH_REASON_HAND_SPELL := "hand_spell"
const DEATH_REASON_POISON := "poison"
const DEATH_REASON_TRAP := "trap"
const DEATH_REASON_LINKED := "linked_death"


static func get_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_ID, ""))


static func get_trigger(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TRIGGER, ""))


static func get_granted_trigger(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_GRANTED_TRIGGER, ""))


static func get_active_zone(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_ACTIVE_ZONE, ""))


static func get_amount(effect_data: Dictionary) -> int:
	return int(effect_data.get(KEY_AMOUNT, 0))


static func get_contextual_amount(effect_data: Dictionary, context_key: String, default_amount := 0) -> int:
	var amount_source := str(effect_data.get(KEY_AMOUNT_SOURCE, ""))
	if amount_source == context_key:
		return int(effect_data.get(context_key, default_amount))
	if amount_source == AMOUNT_SOURCE_EFFECTIVE_HEAL and context_key == EventContext.EFFECTIVE_HEAL_AMOUNT:
		return int(effect_data.get(context_key, default_amount))

	return int(effect_data.get(KEY_AMOUNT, default_amount))


static func get_target(effect_data: Dictionary, default_target := TARGET_SELF) -> String:
	return str(effect_data.get(KEY_TARGET, default_target))


static func get_selected_target_state(effect_data: Dictionary) -> CardState:
	return effect_data.get(KEY_SELECTED_TARGET_STATE) as CardState


static func get_trigger_status(effect_data: Dictionary) -> CardStatus:
	return effect_data.get(KEY_TRIGGER_STATUS) as CardStatus


static func get_effect_owner_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_EFFECT_OWNER_ID, ""))


static func get_death_reason(effect_data: Dictionary, default_reason := DEATH_REASON_EFFECT) -> String:
	return str(effect_data.get(KEY_DEATH_REASON, default_reason))


static func should_apply_spell_power(effect_data: Dictionary) -> bool:
	return bool(effect_data.get(KEY_APPLY_SPELL_POWER, false)) and bool(effect_data.get(KEY_SPELL_POWER_SCALING, true))


static func is_spell_effect(effect_data: Dictionary) -> bool:
	if bool(effect_data.get(KEY_APPLY_SPELL_POWER, false)):
		return true

	var death_reason := get_death_reason(effect_data, "")
	return death_reason == DEATH_REASON_SPELL or death_reason == DEATH_REASON_HAND_SPELL


static func is_active_in_hand(effect_data: Dictionary) -> bool:
	return get_active_zone(effect_data) == ACTIVE_ZONE_HAND


static func has_trigger(effect_data: Dictionary) -> bool:
	return get_trigger(effect_data) != ""


static func get_card_ids(effect_data: Dictionary) -> Array[String]:
	var card_ids: Array[String] = []
	var raw_card_ids: Variant = effect_data.get(KEY_CARD_IDS, [])
	if raw_card_ids is Array:
		for card_id in raw_card_ids:
			var normalized_card_id := str(card_id)
			if normalized_card_id != "":
				card_ids.append(normalized_card_id)

	return card_ids


static func get_source_card_ids(effect_data: Dictionary) -> Array[String]:
	var card_ids: Array[String] = []
	var raw_card_ids: Variant = effect_data.get(KEY_SOURCE_CARD_IDS, [])
	if raw_card_ids is Array:
		for card_id in raw_card_ids:
			var normalized_card_id := str(card_id)
			if normalized_card_id != "":
				card_ids.append(normalized_card_id)

	return card_ids


static func get_card_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_CARD_ID, ""))


static func get_target_card_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TARGET_CARD_ID, ""))


static func get_selection_title(effect_data: Dictionary, default_title := "选择一张卡牌") -> String:
	return str(effect_data.get(KEY_SELECTION_TITLE, default_title))


static func get_bonus_cards(effect_data: Dictionary) -> Array[Dictionary]:
	var bonus_cards: Array[Dictionary] = []
	var raw_bonus_cards: Variant = effect_data.get(KEY_BONUS_CARDS, [])
	if raw_bonus_cards is Array:
		for bonus_card in raw_bonus_cards:
			if bonus_card is Dictionary:
				bonus_cards.append(bonus_card)

	return bonus_cards


static func get_replace_effects(effect_data: Dictionary) -> Array[Dictionary]:
	var replace_effects: Array[Dictionary] = []
	var raw_replace_effects: Variant = effect_data.get(KEY_REPLACE_EFFECTS, [])
	if raw_replace_effects is Array:
		for replace_effect in raw_replace_effects:
			if replace_effect is Dictionary:
				replace_effects.append(replace_effect)

	return replace_effects


static func get_append_effects(effect_data: Dictionary) -> Array[Dictionary]:
	var append_effects: Array[Dictionary] = []
	var raw_append_effects: Variant = effect_data.get(KEY_APPEND_EFFECTS, [])
	if raw_append_effects is Array:
		for append_effect in raw_append_effects:
			if append_effect is Dictionary:
				append_effects.append(append_effect)

	return append_effects


static func get_granted_effects(effect_data: Dictionary) -> Array[Dictionary]:
	var granted_effects: Array[Dictionary] = []
	var raw_granted_effects: Variant = effect_data.get(KEY_GRANTED_EFFECTS, [])
	if raw_granted_effects is Array:
		for granted_effect in raw_granted_effects:
			if granted_effect is Dictionary:
				granted_effects.append(granted_effect)

	return granted_effects


static func get_target_relation(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TARGET_RELATION, TARGET_RELATION_ANY))


static func get_spell_actions(effect_data: Dictionary) -> Array[Dictionary]:
	var spell_actions: Array[Dictionary] = []
	var raw_spell_actions: Variant = effect_data.get(KEY_SPELL_ACTIONS, [])
	if raw_spell_actions is Array:
		for spell_data in raw_spell_actions:
			if spell_data is Dictionary:
				spell_actions.append(spell_data)

	return spell_actions


static func duplicate_with_context(effect_data: Dictionary, context: Dictionary) -> Dictionary:
	var runtime_effect_data := effect_data.duplicate(true)
	for key in context:
		runtime_effect_data[key] = context[key]

	return runtime_effect_data


static func mark_selected_target(effect_data: Dictionary, target_state: CardState) -> void:
	if not effect_data.has(KEY_TARGET):
		effect_data[KEY_TARGET] = TARGET_SELECTED
	effect_data[KEY_SELECTED_TARGET_STATE] = target_state


static func mark_effect_owner(effect_data: Dictionary, owner_id: String) -> void:
	if owner_id != "":
		effect_data[KEY_EFFECT_OWNER_ID] = owner_id


static func mark_trigger_status(effect_data: Dictionary, status: CardStatus) -> void:
	if status != null:
		effect_data[KEY_TRIGGER_STATUS] = status


static func mark_spell_power_enabled(effect_data: Dictionary) -> void:
	effect_data[KEY_APPLY_SPELL_POWER] = true


static func ensure_death_reason(effect_data: Dictionary, death_reason: String) -> void:
	if not effect_data.has(KEY_DEATH_REASON):
		effect_data[KEY_DEATH_REASON] = death_reason


static func get_status_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_ID, ""))


static func get_status_ids(effect_data: Dictionary) -> Array[String]:
	var status_ids: Array[String] = []
	var raw_status_ids: Variant = effect_data.get(KEY_STATUS_IDS, [])
	if raw_status_ids is Array:
		for status_id in raw_status_ids:
			var normalized_status_id := str(status_id)
			if normalized_status_id != "":
				status_ids.append(normalized_status_id)

	var single_status_id := get_status_id(effect_data)
	if single_status_id != "" and not status_ids.has(single_status_id):
		status_ids.append(single_status_id)

	return status_ids


static func get_status_name(effect_data: Dictionary, default_name := "") -> String:
	return str(effect_data.get(KEY_STATUS_NAME, default_name))


static func get_status_description(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_DESCRIPTION, ""))


static func get_status_tags(effect_data: Dictionary) -> Array[String]:
	var status_tags: Array[String] = []
	var raw_tags: Variant = effect_data.get(KEY_STATUS_TAGS, [])
	if raw_tags is Array:
		for tag in raw_tags:
			var normalized_tag := str(tag)
			if normalized_tag != "":
				status_tags.append(normalized_tag)

	return status_tags


static func get_status_stacks(effect_data: Dictionary) -> int:
	return int(effect_data.get(KEY_STATUS_STACKS, 1))


static func get_status_stack_policy(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_STACK_POLICY, CardStatus.STACK_POLICY_STACK))


static func is_permanent_status(effect_data: Dictionary) -> bool:
	if effect_data.has(KEY_STATUS_PERMANENT):
		return bool(effect_data.get(KEY_STATUS_PERMANENT))

	return get_status_duration_turns(effect_data) < 0


static func get_status_duration_turns(effect_data: Dictionary) -> int:
	return int(effect_data.get(KEY_STATUS_DURATION_TURNS, -1))


static func get_status_duration_scope(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_DURATION_SCOPE, CardStatus.DURATION_SCOPE_TARGET_OWNER))


static func get_status_expires_on_trigger(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_EXPIRES_ON_TRIGGER, CardStatus.DEFAULT_EXPIRES_ON_TRIGGER))


static func get_status_payload(effect_data: Dictionary) -> Dictionary:
	var raw_payload: Variant = effect_data.get(KEY_STATUS_PAYLOAD, {})
	if raw_payload is Dictionary:
		return raw_payload.duplicate(true)

	return {}


static func get_status_turn_effects(status: CardStatus) -> Array[Dictionary]:
	var turn_effects: Array[Dictionary] = []
	if status == null:
		return turn_effects

	var raw_turn_effects: Variant = status.payload.get(KEY_STATUS_TURN_EFFECTS, [])
	if raw_turn_effects is Array:
		for effect_data in raw_turn_effects:
			if effect_data is Dictionary:
				turn_effects.append(effect_data)

	return turn_effects


static func get_status_trigger_effects(status: CardStatus, trigger: String) -> Array[Dictionary]:
	var trigger_effects: Array[Dictionary] = []
	if status == null:
		return trigger_effects

	var raw_trigger_effects: Variant = status.payload.get(KEY_STATUS_TRIGGER_EFFECTS, [])
	if raw_trigger_effects is Array:
		for effect_data in raw_trigger_effects:
			if not effect_data is Dictionary:
				continue
			if get_trigger(effect_data) != trigger:
				continue
			trigger_effects.append(effect_data)

	return trigger_effects


static func get_trigger_player(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TRIGGER_PLAYER, TRIGGER_PLAYER_ANY))


static func status_persists_after_death(effect_data: Dictionary) -> bool:
	return bool(effect_data.get(KEY_STATUS_PERSISTS_AFTER_DEATH, false))


static func get_filter_type(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_FILTER_TYPE, "minion"))


static func get_filter_owner(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_FILTER_OWNER, "self"))


static func get_target_zone(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TARGET_ZONE, TARGET_ZONE_HAND))
