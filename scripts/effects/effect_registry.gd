extends RefCounted
class_name EffectRegistry

# EffectRegistry 把 JSON 里的 effect id 映射到真正的效果类。
# 以后新增效果时，在这里注册即可，不需要修改 Card 或 CardState。

var effects_by_id: Dictionary = {}

func _init() -> void:
	# 内置公共效果。以后扩展效果时继续在这里注册。
	register_effect("heal", HealEffect.new())
	register_effect("damage", DamageEffect.new())
	register_effect("shield", ShieldEffect.new())
	register_effect("increase_max_health", IncreaseMaxHealthEffect.new())
	register_effect("set_attack_to_current_health", SetAttackToCurrentHealthEffect.new())
	register_effect("gain_flips", GainFlipsEffect.new())
	register_effect("gain_resource_score", GainResourceScoreEffect.new())
	register_effect("gain_mana", GainManaEffect.new())
	register_effect(EffectData.EFFECT_GAIN_ATTACK, GainAttackEffect.new())
	register_effect(EffectData.EFFECT_PLAY_SPELL_ACTION, PlaySpellActionEffect.new())
	register_effect(EffectData.EFFECT_APPLY_STATUS, ApplyStatusEffect.new())
	register_effect(EffectData.EFFECT_RESURRECT, ResurrectEffect.new())
	register_effect(EffectData.EFFECT_ADD_CARD_TO_HAND, AddCardToHandEffect.new())
	register_effect(EffectData.EFFECT_CHOOSE_CARD_TO_HAND, ChooseCardToHandEffect.new())


func register_effect(effect_id: String, effect: CardEffect) -> void:
	# 注册一个效果 id 到效果实例的映射。
	effects_by_id[effect_id] = effect


func execute_effect(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	# 执行单条效果定义，例如 { id="heal", amount=2 }。
	var effect_id := EffectData.get_id(effect_data)
	var effect := effects_by_id.get(effect_id) as CardEffect

	if effect == null:
		push_warning("未注册的卡牌效果: %s" % effect_id)
		return

	await effect.execute(source_state, effect_data, game_manager)


func can_execute_effect(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	var effect_id := EffectData.get_id(effect_data)
	var effect := effects_by_id.get(effect_id) as CardEffect
	if effect == null:
		return false

	return effect.can_execute(source_state, effect_data, game_manager)


func execute_trigger(source_state: CardState, trigger: String, game_manager: Node, context: Dictionary = {}) -> void:
	# 执行某个触发时机下的全部效果，例如 on_reveal。
	if source_state == null or source_state.data == null:
		return

	for effect_data in source_state.data.effects:
		if EffectData.get_trigger(effect_data) == trigger:
			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
			await execute_effect(source_state, runtime_effect_data, game_manager)
