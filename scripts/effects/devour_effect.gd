extends CardEffect
class_name DevourEffect

# 通用吞噬效果：目标单位离场，施法者获得可驱散的“吞噬”状态。
# 状态负责承载属性加成和攻击后毒性触发；以后驱散移除状态时，属性会自动回滚。

const DEVOUR_TARGET_POISON_SCORPION := "poison_scorpion"
const DEVOUR_TARGET_GU_POISON_SNAKE := "gu_poison_snake"
const DEVOUR_TARGET_GU_KING_SNAKE := "gu_king_snake"
const DEVOUR_TARGET_GU_GIANT_LIZARD := "gu_giant_lizard"

const POISON_LEVEL_NONE := 0
const POISON_LEVEL_SCORPION := 1
const POISON_LEVEL_SNAKE := 2
const POISON_LEVEL_KING := 3


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if source_state == null or game_manager == null:
		return

	var target_state := EffectData.get_selected_target_state(effect_data)
	var allowed_card_ids := EffectData.get_card_ids(effect_data)
	if allowed_card_ids.is_empty():
		allowed_card_ids = [
			DEVOUR_TARGET_POISON_SCORPION,
			DEVOUR_TARGET_GU_POISON_SNAKE,
			DEVOUR_TARGET_GU_KING_SNAKE,
			DEVOUR_TARGET_GU_GIANT_LIZARD
		]

	if not can_devour_target(source_state, target_state, allowed_card_ids):
		return

	var attack_bonus := target_state.current_attack * 2
	var max_health_bonus := target_state.max_health * 2
	var poison_attack_level := get_poison_attack_level(target_state)
	apply_devour_status(source_state, attack_bonus, max_health_bonus, poison_attack_level)

	var death_reason := EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_SPELL)
	if game_manager.has_method("destroy_card_with_refill"):
		game_manager.destroy_card_with_refill(target_state, death_reason, source_state, true)


func can_devour_target(source_state: CardState, target_state: CardState, allowed_card_ids: Array[String]) -> bool:
	return (
		source_state != null
		and target_state != null
		and source_state != target_state
		and BoardQuery.is_face_up_board_card(target_state)
		and target_state.is_minion()
		and is_state_in_card_filter(target_state, allowed_card_ids)
		and not target_state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION)
	)


func is_state_in_card_filter(state: CardState, card_ids: Array[String]) -> bool:
	if state == null:
		return false

	for card_id in card_ids:
		if state.represents_card_id(card_id):
			return true

	return false


func apply_devour_status(
	source_state: CardState,
	attack_bonus: int,
	max_health_bonus: int,
	poison_attack_level: int
) -> void:
	var existing_status := source_state.get_status(CardStatus.STATUS_DEVOUR)
	if existing_status == null:
		var status := create_devour_status(source_state, attack_bonus, max_health_bonus, poison_attack_level)
		source_state.add_status(status)
		return

	existing_status.stacks += 1
	existing_status.payload[EffectData.KEY_ATTACK_BONUS] = (
		int(existing_status.payload.get(EffectData.KEY_ATTACK_BONUS, 0)) + attack_bonus
	)
	existing_status.payload[EffectData.KEY_MAX_HEALTH_BONUS] = (
		int(existing_status.payload.get(EffectData.KEY_MAX_HEALTH_BONUS, 0)) + max_health_bonus
	)

	var current_poison_level := int(existing_status.payload.get(EffectData.KEY_POISON_ATTACK_LEVEL, POISON_LEVEL_NONE))
	if poison_attack_level > current_poison_level:
		existing_status.payload[EffectData.KEY_POISON_ATTACK_LEVEL] = poison_attack_level
		existing_status.payload[EffectData.KEY_STATUS_TRIGGER_EFFECTS] = create_poison_attack_trigger_effects(poison_attack_level)

	source_state.recalculate_status_modifiers(false)
	source_state.state_changed.emit(source_state)


func create_devour_status(
	source_state: CardState,
	attack_bonus: int,
	max_health_bonus: int,
	poison_attack_level: int
) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = CardStatus.STATUS_DEVOUR
	status.display_name = "吞噬"
	status.description = "吞噬毒虫获得属性，并继承最高级毒性攻击。"
	status.tags = [CardStatus.TAG_ATTACK_MODIFIER, CardStatus.TAG_HEALTH_MODIFIER]
	status.stacks = 1
	status.stack_policy = CardStatus.STACK_POLICY_STACK
	status.is_permanent = true
	status.remaining_turns = -1
	status.source_card_id = source_state.card_id
	status.source_owner_id = source_state.owner_id
	status.duration_owner_id = source_state.owner_id
	status.payload = {
		EffectData.KEY_ATTACK_BONUS: attack_bonus,
		EffectData.KEY_MAX_HEALTH_BONUS: max_health_bonus,
		EffectData.KEY_CUMULATIVE_STATUS_MODIFIER: true,
		EffectData.KEY_POISON_ATTACK_LEVEL: poison_attack_level,
		EffectData.KEY_STATUS_TRIGGER_EFFECTS: create_poison_attack_trigger_effects(poison_attack_level)
	}
	return status


func get_poison_attack_level(target_state: CardState) -> int:
	if target_state == null:
		return POISON_LEVEL_NONE

	match target_state.card_id:
		DEVOUR_TARGET_POISON_SCORPION:
			return POISON_LEVEL_SCORPION
		DEVOUR_TARGET_GU_POISON_SNAKE:
			return POISON_LEVEL_SNAKE
		DEVOUR_TARGET_GU_KING_SNAKE:
			return POISON_LEVEL_KING
		DEVOUR_TARGET_GU_GIANT_LIZARD:
			var devour_status := target_state.get_status(CardStatus.STATUS_DEVOUR)
			if devour_status != null:
				return int(devour_status.payload.get(EffectData.KEY_POISON_ATTACK_LEVEL, POISON_LEVEL_NONE))
			return POISON_LEVEL_NONE
		_:
			return POISON_LEVEL_NONE


func create_poison_attack_trigger_effects(poison_attack_level: int) -> Array[Dictionary]:
	match poison_attack_level:
		POISON_LEVEL_SCORPION:
			return [create_poison_status_effect("蝎毒", EffectData.TARGET_ATTACK_TARGET_ENEMY_UNIT, 1, 3)]
		POISON_LEVEL_SNAKE:
			return [
				create_poison_status_effect("蛇毒", EffectData.TARGET_ATTACK_TARGET_ENEMY_MINION, 2, 3),
				create_snake_venom_status_effect()
			]
		POISON_LEVEL_KING:
			return [create_poison_status_effect("王毒", EffectData.TARGET_ATTACK_TARGET_ENEMY_MINION, 3, 3)]
		_:
			return []


func create_poison_status_effect(
	status_name: String,
	target: String,
	damage_per_turn: int,
	duration_turns: int
) -> Dictionary:
	return {
		EffectData.KEY_ID: EffectData.EFFECT_APPLY_STATUS,
		EffectData.KEY_TRIGGER: EventContext.TRIGGER_AFTER_ATTACK,
		EffectData.KEY_TARGET: target,
		EffectData.KEY_STATUS_ID: CardStatus.STATUS_POISON,
		EffectData.KEY_STATUS_NAME: status_name,
		EffectData.KEY_STATUS_DESCRIPTION: "回合结束时受到%d点毒性伤害，持续%d回合。" % [damage_per_turn, duration_turns],
		EffectData.KEY_STATUS_TAGS: [CardStatus.TAG_DAMAGE_OVER_TIME],
		EffectData.KEY_STATUS_DURATION_TURNS: duration_turns,
		EffectData.KEY_STATUS_EXPIRES_ON_TRIGGER: EventContext.TRIGGER_AFTER_TURN_END,
		EffectData.KEY_STATUS_DURATION_SCOPE: CardStatus.DURATION_SCOPE_TARGET_OWNER,
		EffectData.KEY_STATUS_PAYLOAD: {
			EffectData.KEY_POISON_DAMAGE: damage_per_turn
		}
	}


func create_snake_venom_status_effect() -> Dictionary:
	return {
		EffectData.KEY_ID: EffectData.EFFECT_APPLY_STATUS,
		EffectData.KEY_TRIGGER: EventContext.TRIGGER_AFTER_ATTACK,
		EffectData.KEY_TARGET: EffectData.TARGET_ATTACK_TARGET_ENEMY_MINION,
		EffectData.KEY_STATUS_ID: CardStatus.STATUS_SNAKE_VENOM,
		EffectData.KEY_STATUS_NAME: "蛇毒",
		EffectData.KEY_STATUS_DESCRIPTION: "攻击-1，持续3回合。",
		EffectData.KEY_STATUS_TAGS: [CardStatus.TAG_ATTACK_MODIFIER],
		EffectData.KEY_STATUS_DURATION_TURNS: 3,
		EffectData.KEY_STATUS_EXPIRES_ON_TRIGGER: EventContext.TRIGGER_AFTER_TURN_END,
		EffectData.KEY_STATUS_DURATION_SCOPE: CardStatus.DURATION_SCOPE_TARGET_OWNER,
		"apply_animation": "gu_infusion",
		EffectData.KEY_STATUS_PAYLOAD: {
			EffectData.KEY_ATTACK_BONUS: -1
		},
		EffectData.KEY_STATUS_STACK_POLICY: CardStatus.STACK_POLICY_REFRESH
	}
