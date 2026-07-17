extends RefCounted
class_name EffectData

# EffectData 集中管理 JSON 效果配置的字段名和基础读取逻辑。
# 它不执行效果，只让各个 resolver 使用同一套配置语言。

const KEY_ID := "id"
const KEY_TRIGGER := "trigger"
const KEY_ACTIVE_ZONE := "active_zone"
const KEY_CARD_IDS := "card_ids"
const KEY_SOURCE_CARD_IDS := "source_card_ids"
const KEY_SPELL_IDS := "spell_ids"
const KEY_SPELL_TAGS := "spell_tags"
const KEY_REQUIRED_SPELL_TAGS := "required_spell_tags"
const KEY_SPELL_ACTIONS := "spell_actions"
const KEY_SPELL_MODIFIERS := "spell_modifiers"
const KEY_ACTIONS := "actions"
const KEY_ACTION_ID := "action_id"
const KEY_DIRECTION := "direction"
const KEY_MOUNTED_ATTACKS := "mounted_attacks"
const KEY_RIDER_CARD_ID := "rider_card_id"
const KEY_ATTACK_SPEED := "attack_speed"
const KEY_RANGE := "range"
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
const KEY_STATUS_VALENCE := "status_valence"
const KEY_STATUS_PAYLOAD := "payload"
const KEY_STATUS_TURN_EFFECTS := "turn_effects"
const KEY_STATUS_TRIGGER_EFFECTS := "trigger_effects"
const KEY_EFFECTS := "effects"
const KEY_TRIGGER_STATUS := "_trigger_status"
const KEY_ATTACK_BONUS := "attack_bonus"
const KEY_ARMOR_BONUS := "armor_bonus"
const KEY_MOVEMENT_BONUS := "movement_bonus"
const KEY_DAMAGE_AMPLIFY := "damage_amplify"
const KEY_MAX_HEALTH_BONUS := "max_health_bonus"
const KEY_CUMULATIVE_STATUS_MODIFIER := "cumulative_status_modifier"
const KEY_POISON_ATTACK_LEVEL := "poison_attack_level"
const KEY_POISON_DAMAGE := "poison_damage"
const KEY_FIRE_DAMAGE := "fire_damage"
const KEY_STORED_VENOM_DAMAGE := "stored_venom_damage"
const KEY_FILTER_TYPE := "filter_type"
const KEY_FILTER_OWNER := "filter_owner"
const KEY_TARGET_ZONE := "target_zone"
const KEY_AMOUNT_SOURCE := "amount_source"
const KEY_CARD_ID := "card_id"
const KEY_TARGET_CARD_ID := "target_card_id"
const KEY_TARGET_FACTION_ID := "target_faction_id"
const KEY_TRANSFORM_MODE := "transform_mode"
const KEY_PRESERVE_ORIGINAL_IDENTITY := "preserve_original_identity"
const KEY_TRIGGER_PLAYER := "trigger_player"
const KEY_BONUS_CARDS := "bonus_cards"
const KEY_SELECTION_TITLE := "selection_title"
const KEY_REPLACE_EFFECTS := "replace_effects"
const KEY_APPEND_EFFECTS := "append_effects"
const KEY_TARGET_RELATION := "target_relation"
const KEY_TARGET_RULE := "target_rule"
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
const KEY_SCALE_AMOUNT_BY_STATUS_STACKS := "scale_amount_by_status_stacks"
const KEY_RUNTIME_STATE_ID := "runtime_state_id"
const KEY_RUNTIME_STATE_IDS := "runtime_state_ids"
const KEY_FALLBACK_RUNTIME_STATE_ID := "fallback_runtime_state_id"
const KEY_REQUIRED_RUNTIME_STATE_ID := "required_runtime_state_id"
const KEY_EFFECT_HANDLES_ANIMATION := "effect_handles_animation"
const KEY_SECOND_SELECTION_TITLE := "second_selection_title"
const KEY_SKILL_IDS := "skill_ids"
const KEY_RESOURCE_ID := "resource_id"
const KEY_MAX_AMOUNT := "max_amount"
const KEY_KEYWORDS := "keywords"
const KEY_REQUIRED_RESOURCE_ID := "required_resource_id"
const KEY_REQUIRED_RESOURCE_MIN := "required_resource_min"
const KEY_HEALTH_VALUES := "health_values"
const KEY_BEFORE_TARGET_EFFECTS := "before_target_effects"
const KEY_SUPPRESS_RESOURCE_GAIN := "suppress_resource_gain"
const KEY_BREAKS_STEALTH := "breaks_stealth"
const KEY_CLEANSE_MODE := "cleanse_mode"
const KEY_THRESHOLD := "threshold"
const KEY_DAMAGE_PER_THRESHOLD := "damage_per_threshold"
const KEY_CONSUME_SOURCE_STATUS := "consume_source_status"
const KEY_CYCLE_LENGTH := "cycle_length"
const KEY_ACTIVE_PHASES := "active_phases"
const KEY_ADVANCE_PHASE := "advance_phase"
const KEY_RESET_PHASE := "reset_phase"
const KEY_RESERVE_ID := "reserve_id"
const KEY_CAPACITY := "capacity"
const KEY_COOLDOWN_TURNS := "cooldown_turns"
const KEY_COUNT_ZONES := "count_zones"
const KEY_DRAW_MODE := "draw_mode"
const KEY_RESTOCK_MODE := "restock_mode"
const KEY_POOL := "pool"
const KEY_ONCE_PER_LIFETIME := "once_per_lifetime"

const ACTIVE_ZONE_HAND := "hand"
const TARGET_ZONE_HAND := "hand"

const EFFECT_GRANT_SPELL_ACTIONS := "grant_spell_actions"
const EFFECT_GRANT_ACTIONS := "grant_actions"
const EFFECT_GRANT_LAST_SPELL_ACTION := "grant_last_spell_action"
const EFFECT_MODIFY_FLIP_CAPACITY := "modify_flip_capacity"
const EFFECT_PASSIVE_FLIP_BONUS := "passive_flip_bonus"
const EFFECT_APPLY_STATUS := "apply_status"
const EFFECT_APPLY_KAGUNE_POWER := "apply_kagune_power"
const EFFECT_DAMAGE := "damage"
const EFFECT_SET_UNIT_MOVEMENT := "set_unit_movement"
const EFFECT_MODIFY_UNIT_MOVEMENT := "modify_unit_movement"
const EFFECT_SET_UNIT_ATTACK_TO_RESOURCE := "set_unit_attack_to_resource"
const EFFECT_MODIFY_UNIT_ATTACK := "modify_unit_attack"
const EFFECT_MODIFY_UNIT_ARMOR := "modify_unit_armor"
const EFFECT_MODIFY_UNIT_ATTACK_SPEED := "modify_unit_attack_speed"
const EFFECT_MODIFY_SPELL_POWER := "modify_spell_power"
const EFFECT_MODIFY_HAND_SPELL_EFFECTS := "modify_hand_spell_effects"
const EFFECT_MODIFY_SPELL_ABILITY := "modify_spell_ability"
const EFFECT_MODIFY_APPLIED_STATUS := "modify_applied_status"
const EFFECT_GRANT_UNIT_TRIGGER_EFFECTS := "grant_unit_trigger_effects"
const EFFECT_DESTROY_UNITS := "destroy_units"
const EFFECT_LIFE_DRAIN := "life_drain"
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
const EFFECT_SET_FACTION_RUNTIME_STATE := "set_faction_runtime_state"
const EFFECT_RESTRICT_FACTION_RUNTIME_CYCLE := "restrict_faction_runtime_cycle"
const EFFECT_MOONBLADE := "moonblade"
const EFFECT_GRANT_FACTION_SKILLS := "grant_faction_skills"
const EFFECT_GRANT_UNIT_KEYWORDS := "grant_unit_keywords"
const EFFECT_GRANT_REBORN := "grant_reborn"
const EFFECT_MODIFY_FACTION_SKILL := "modify_faction_skill"
const EFFECT_CLEANSE := "cleanse"
const EFFECT_EVOLVE_UNITS := "evolve_units"
const EFFECT_TRANSFORM_UNIT := "transform_unit"
const EFFECT_SACRIFICE_FRIENDLY_MINIONS := "sacrifice_friendly_minions"
const EFFECT_GRANT_BOARD_VISION := "grant_board_vision"
const EFFECT_MODIFY_HERO_REVIVE_COOLDOWN := "modify_hero_revive_cooldown"
const EFFECT_SYNC_STATS_FROM_OWNER_CARD := "sync_stats_from_owner_card"
const EFFECT_ASSIST_ATTACK_ATTACK_TARGET := "assist_attack_attack_target"
const EFFECT_CHAOS_CORRUPTION_BURST := "chaos_corruption_burst"
const EFFECT_SET_BEAST_PATH := "set_beast_path"
const EFFECT_PERIODIC_STATUS_AURA := "periodic_status_aura"
const EFFECT_PERIODIC_TRIGGER := "periodic_trigger"
const EFFECT_MAINTAIN_CARD_RESERVE := "maintain_card_reserve"
const EFFECT_MODIFY_CARD_RESERVE_CAPACITY := "modify_card_reserve_capacity"

const AMOUNT_SOURCE_EFFECTIVE_HEAL := "effective_heal"
const AMOUNT_SOURCE_MISSING_HEALTH := "missing_health"
const AMOUNT_SOURCE_STATUS_STACKS := "status_stacks"

const TRIGGER_WHILE_IN_HAND := "while_in_hand"
const TRIGGER_WHILE_EQUIPPED := "while_equipped"
const TRIGGER_WHILE_ON_BOARD := "while_on_board"
const TRIGGER_PASSIVE := "passive"
const TRIGGER_AFTER_SPELL_CAST := "after_spell_cast"

const COUNT_ZONE_HAND := "hand"
const COUNT_ZONE_BOARD := "board"
const DRAW_MODE_WITHOUT_REPLACEMENT := "without_replacement"
const RESTOCK_MODE_FINITE := "finite"

const TARGET_SELF := "self"
const TARGET_SELECTED := "selected"
const TARGET_OWNER := "owner"
const TARGET_DESTROYER := "destroyer"
const TARGET_TURN_PLAYER := "turn_player"
const TARGET_CURRENT_PLAYER := "current_player"
const TARGET_ADJACENT_TURN_PLAYER_MINIONS := "adjacent_turn_player_minions"
const TARGET_ADJACENT_MINIONS := "adjacent_minions"
const TARGET_ADJACENT_ENEMY_MINIONS := "adjacent_enemy_minions"
const TARGET_ADJACENT_ENEMY_NON_HERO_MINIONS := "adjacent_enemy_non_hero_minions"
const TARGET_TURN_PLAYER_MINIONS_BY_CARD_IDS := "turn_player_minions_by_card_ids"
const TARGET_SELECTED_ADJACENT_ENEMY_MINIONS := "selected_adjacent_enemy_minions"
const TARGET_SELECTED_AREA_ENEMY_MINIONS := "selected_area_enemy_minions"
const TARGET_SELECTED_AREA_ALL_MINIONS := "selected_area_all_minions"
const TARGET_OWNER_CARD_BY_ID := "owner_card_by_id"
const TARGET_ATTACK_TARGET_ENEMY_UNIT := "attack_target_enemy_unit"
const TARGET_ATTACK_TARGET_ENEMY_MINION := "attack_target_enemy_minion"
const TARGET_ATTACK_TARGET_UNIT := "attack_target_unit"
const TARGET_ENEMY_AND_NEUTRAL_UNITS := "enemy_and_neutral_units"
const TARGET_FRIENDLY_UNITS := "friendly_units"
const TARGET_FRIENDLY_MINIONS := "friendly_minions"
const TARGET_FRIENDLY_MINIONS_BY_CARD_IDS := "friendly_minions_by_card_ids"
const TARGET_FRIENDLY_MINIONS_BY_FACTION := "friendly_minions_by_faction"
const TARGET_ENEMY_UNITS := "enemy_units"

const STATUS_VALENCE_POSITIVE := "positive"
const STATUS_VALENCE_NEGATIVE := "negative"
const STATUS_VALENCE_NEUTRAL := "neutral"

const CLEANSE_MODE_ALL := "all"
const CLEANSE_MODE_POSITIVE := "positive"
const CLEANSE_MODE_NEGATIVE := "negative"

const TRIGGER_PLAYER_ANY := "any"
const TRIGGER_PLAYER_SOURCE_OWNER := "source_owner"

const TARGET_RELATION_ANY := "any"
const TARGET_RELATION_FRIENDLY := "friendly"
const TARGET_RELATION_ENEMY := "enemy"

const RANGE_MELEE := "melee"
const RANGE_RANGED := "ranged"

const DEATH_REASON_EFFECT := "effect"
const DEATH_REASON_ATTACK := "attack"
const DEATH_REASON_SPELL := "spell"
const DEATH_REASON_HAND_SPELL := "hand_spell"
const DEATH_REASON_POISON := "poison"
const DEATH_REASON_FIRE := "fire"
const DEATH_REASON_TRAP := "trap"
const DEATH_REASON_LINKED := "linked_death"
const DEATH_REASON_STATUS_EXPIRED := "status_expired"


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


static func should_break_stealth_after_spell(spell_data: Dictionary) -> bool:
	return bool(spell_data.get(KEY_BREAKS_STEALTH, true))


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


static func get_spell_ids(effect_data: Dictionary) -> Array[String]:
	var spell_ids: Array[String] = []
	var raw_spell_ids: Variant = effect_data.get(KEY_SPELL_IDS, [])
	if raw_spell_ids is Array:
		for spell_id in raw_spell_ids:
			var normalized_spell_id := str(spell_id)
			if normalized_spell_id != "":
				spell_ids.append(normalized_spell_id)

	return spell_ids


static func get_spell_tags(spell_data: Dictionary) -> Array[String]:
	var spell_tags: Array[String] = []
	var raw_spell_tags: Variant = spell_data.get(KEY_SPELL_TAGS, [])
	if raw_spell_tags is Array:
		for spell_tag in raw_spell_tags:
			var normalized_spell_tag := str(spell_tag)
			if normalized_spell_tag != "" and not spell_tags.has(normalized_spell_tag):
				spell_tags.append(normalized_spell_tag)

	return spell_tags


static func get_required_spell_tags(effect_data: Dictionary) -> Array[String]:
	var spell_tags: Array[String] = []
	var raw_spell_tags: Variant = effect_data.get(KEY_REQUIRED_SPELL_TAGS, [])
	if raw_spell_tags is Array:
		for spell_tag in raw_spell_tags:
			var normalized_spell_tag := str(spell_tag)
			if normalized_spell_tag != "" and not spell_tags.has(normalized_spell_tag):
				spell_tags.append(normalized_spell_tag)

	return spell_tags


static func get_runtime_state_ids(effect_data: Dictionary) -> Array[String]:
	var state_ids: Array[String] = []
	var raw_state_ids: Variant = effect_data.get(KEY_RUNTIME_STATE_IDS, [])
	if raw_state_ids is Array:
		for state_id in raw_state_ids:
			var normalized_state_id := str(state_id)
			if normalized_state_id != "":
				state_ids.append(normalized_state_id)

	var single_state_id := str(effect_data.get(KEY_RUNTIME_STATE_ID, ""))
	if single_state_id != "" and not state_ids.has(single_state_id):
		state_ids.append(single_state_id)

	return state_ids


static func get_skill_ids(effect_data: Dictionary) -> Array[String]:
	var skill_ids: Array[String] = []
	var raw_skill_ids: Variant = effect_data.get(KEY_SKILL_IDS, [])
	if raw_skill_ids is Array:
		for skill_id in raw_skill_ids:
			var normalized_skill_id := str(skill_id)
			if normalized_skill_id != "":
				skill_ids.append(normalized_skill_id)

	var single_skill_id := str(effect_data.get("skill_id", ""))
	if single_skill_id != "" and not skill_ids.has(single_skill_id):
		skill_ids.append(single_skill_id)

	return skill_ids


static func get_keywords(effect_data: Dictionary) -> Array[String]:
	var keywords: Array[String] = []
	var raw_keywords: Variant = effect_data.get(KEY_KEYWORDS, [])
	if raw_keywords is Array:
		for keyword in raw_keywords:
			var normalized_keyword := str(keyword)
			if normalized_keyword != "" and not keywords.has(normalized_keyword):
				keywords.append(normalized_keyword)

	return keywords


static func get_health_values(effect_data: Dictionary) -> Array[int]:
	var values: Array[int] = []
	var raw_values: Variant = effect_data.get(KEY_HEALTH_VALUES, [])
	if raw_values is Array:
		for value in raw_values:
			values.append(maxi(int(value), 0))

	return values


static func get_before_target_effects(effect_data: Dictionary) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var raw_effects: Variant = effect_data.get(KEY_BEFORE_TARGET_EFFECTS, [])
	if raw_effects is Array:
		for item in raw_effects:
			if item is Dictionary:
				effects.append(item)

	return effects


static func should_suppress_resource_gain(effect_data: Dictionary) -> bool:
	return bool(effect_data.get(KEY_SUPPRESS_RESOURCE_GAIN, false))


static func get_resource_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_RESOURCE_ID, ""))


static func get_required_resource_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_REQUIRED_RESOURCE_ID, ""))


static func get_required_resource_min(effect_data: Dictionary) -> int:
	return int(effect_data.get(KEY_REQUIRED_RESOURCE_MIN, 0))


static func get_max_amount(effect_data: Dictionary, default_value := 0) -> int:
	return int(effect_data.get(KEY_MAX_AMOUNT, default_value))


static func get_card_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_CARD_ID, ""))


static func get_target_card_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TARGET_CARD_ID, ""))


static func get_transform_mode(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TRANSFORM_MODE, "cover"))


static func should_preserve_original_identity(effect_data: Dictionary) -> bool:
	return bool(effect_data.get(KEY_PRESERVE_ORIGINAL_IDENTITY, true))


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


static func get_reserve_id(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_RESERVE_ID, ""))


static func get_reserve_capacity(effect_data: Dictionary) -> int:
	return maxi(int(effect_data.get(KEY_CAPACITY, 0)), 0)


static func get_reserve_cooldown_turns(effect_data: Dictionary) -> int:
	return maxi(int(effect_data.get(KEY_COOLDOWN_TURNS, 0)), 0)


static func get_reserve_count_zones(effect_data: Dictionary) -> Array[String]:
	var zones: Array[String] = []
	var raw_zones: Variant = effect_data.get(KEY_COUNT_ZONES, [COUNT_ZONE_HAND, COUNT_ZONE_BOARD])
	if raw_zones is Array:
		for raw_zone in raw_zones:
			var zone := str(raw_zone)
			if zone != "" and not zones.has(zone):
				zones.append(zone)

	return zones


static func get_reserve_pool(effect_data: Dictionary) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var raw_pool: Variant = effect_data.get(KEY_POOL, [])
	if raw_pool is Array:
		for raw_entry in raw_pool:
			if raw_entry is Dictionary:
				pool.append(raw_entry)

	return pool


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


static func get_target_rule(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_TARGET_RULE, ""))


static func get_spell_actions(effect_data: Dictionary) -> Array[Dictionary]:
	var spell_actions: Array[Dictionary] = []
	var raw_spell_actions: Variant = effect_data.get(KEY_SPELL_ACTIONS, [])
	if raw_spell_actions is Array:
		for spell_data in raw_spell_actions:
			if spell_data is Dictionary:
				spell_actions.append(spell_data)

	return spell_actions


static func get_actions(effect_data: Dictionary) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var raw_actions: Variant = effect_data.get(KEY_ACTIONS, [])
	if raw_actions is Array:
		for action_data in raw_actions:
			if action_data is Dictionary:
				actions.append(action_data)

	return actions


static func get_mounted_attacks(card_data: CardData) -> Array[Dictionary]:
	if card_data == null:
		return []

	return card_data.mounted_attacks


static func get_action_id(action_data: Dictionary) -> String:
	return str(action_data.get(KEY_ACTION_ID, action_data.get(KEY_ID, "")))


static func get_direction(action_data: Dictionary) -> String:
	return str(action_data.get(KEY_DIRECTION, ""))


static func get_rider_card_id(action_data: Dictionary) -> String:
	return str(action_data.get(KEY_RIDER_CARD_ID, ""))


static func get_attack_speed(action_data: Dictionary) -> int:
	return int(action_data.get(KEY_ATTACK_SPEED, 1))


static func get_range(action_data: Dictionary) -> String:
	return str(action_data.get(KEY_RANGE, RANGE_MELEE))


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


static func get_status_valence(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_STATUS_VALENCE, STATUS_VALENCE_NEUTRAL))


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


static func get_cleanse_mode(effect_data: Dictionary) -> String:
	return str(effect_data.get(KEY_CLEANSE_MODE, CLEANSE_MODE_ALL))
