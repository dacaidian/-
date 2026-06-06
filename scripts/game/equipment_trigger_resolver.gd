extends RefCounted
class_name EquipmentTriggerResolver

# 解析玩家已装备卡牌上的触发效果。装备本身不在棋盘上，
# 因此由装备拥有者和触发来源共同提供上下文。

func resolve_after_attack(game_manager: GameManager, attacker_state: CardState, attacked_state: CardState) -> void:
	if game_manager == null or attacker_state == null:
		return
	if attacker_state.owner_id == "":
		return

	var owner := game_manager.get_player_by_id(attacker_state.owner_id)
	if owner == null:
		return

	for equipment_data in owner.get_equipped_cards():
		if not can_equipment_trigger_for_attacker(equipment_data, attacker_state):
			continue

		for effect_data in equipment_data.effects:
			if EffectData.get_trigger(effect_data) != EventContext.TRIGGER_AFTER_ATTACK:
				continue

			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, {
				EventContext.SOURCE_STATE: attacker_state,
				EventContext.ATTACK_TARGET_STATE: attacked_state
			})
			EffectData.mark_effect_owner(runtime_effect_data, owner.id)
			EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
			await game_manager.effect_registry.execute_effect(attacker_state, runtime_effect_data, game_manager)


func can_equipment_trigger_for_attacker(equipment_data: CardData, attacker_state: CardState) -> bool:
	if equipment_data == null or attacker_state == null:
		return false
	if not equipment_data.is_equipment():
		return false

	var hero_id := equipment_data.owner_hero_card_id
	if hero_id != "" and not attacker_state.represents_card_id(hero_id):
		return false

	return true
