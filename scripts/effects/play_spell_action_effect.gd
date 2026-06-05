extends CardEffect
class_name PlaySpellActionEffect

# 让某个来源单位自动释放一张已存在的手牌法术定义。
# 当前用于装备触发复用英雄配套法术，避免复制洗礼等多段效果配置。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if source_state == null or game_manager == null:
		return
	if not game_manager.has_method("get_card_data_by_id"):
		return

	var card_id := EffectData.get_card_id(effect_data)
	var spell_card := game_manager.get_card_data_by_id(card_id) as CardData
	if spell_card == null or not spell_card.is_spell():
		return

	var target_rule := SpellTargetResolver.get_rule_from_card_data(spell_card)
	var target_state := get_auto_spell_target(source_state, effect_data)
	if SpellTargetResolver.requires_target(target_rule):
		if target_state == null or not SpellTargetResolver.can_target(target_rule, target_state, [], source_state):
			return

	await game_manager.play_spell_cast_animation(source_state, target_state if target_state != null else source_state, {
		"animation": spell_card.animation
	})

	for spell_effect_data in spell_card.effects:
		var runtime_effect_data := spell_effect_data.duplicate(true)
		EffectData.mark_effect_owner(runtime_effect_data, source_state.owner_id)
		if SpellTargetResolver.requires_target(target_rule):
			EffectData.mark_selected_target(runtime_effect_data, target_state)
		EffectData.mark_spell_power_enabled(runtime_effect_data)
		EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
		await game_manager.effect_registry.execute_effect(source_state, runtime_effect_data, game_manager)


func get_auto_spell_target(source_state: CardState, effect_data: Dictionary) -> CardState:
	var target := EffectData.get_target(effect_data, EffectData.TARGET_SELF)
	match target:
		EffectData.TARGET_SELF:
			return source_state
		_:
			return EffectData.get_selected_target_state(effect_data)
