extends RefCounted
class_name EffectRegistry

# EffectRegistry 把 JSON 里的 effect id 映射到真正的效果类。
# 以后新增效果时，在这里注册即可，不需要修改 Card 或 CardState。

const GrantedUnitTriggerResolverScript := preload("res://scripts/game/granted_unit_trigger_resolver.gd")
const SyncStatsFromOwnerCardEffectScript := preload("res://scripts/effects/sync_stats_from_owner_card_effect.gd")
const AssistAttackAttackTargetEffectScript := preload("res://scripts/effects/assist_attack_attack_target_effect.gd")
const TransformUnitEffectScript := preload("res://scripts/effects/transform_unit_effect.gd")
const RestoreTransformEffectScript := preload("res://scripts/effects/restore_transform_effect.gd")
const ChaosCorruptionBurstEffectScript := preload("res://scripts/effects/chaos_corruption_burst_effect.gd")
const SetBeastPathEffectScript := preload("res://scripts/effects/set_beast_path_effect.gd")
const DestroyUnitsEffectScript := preload("res://scripts/effects/destroy_units_effect.gd")
const LifeDrainEffectScript := preload("res://scripts/effects/life_drain_effect.gd")
const PeriodicStatusAuraEffectScript := preload("res://scripts/effects/periodic_status_aura_effect.gd")
const PeriodicTriggerEffectScript := preload("res://scripts/effects/periodic_trigger_effect.gd")
const ApplyKagunePowerEffectScript := preload("res://scripts/effects/apply_kagune_power_effect.gd")
const ClaimDeathSlotEffectScript := preload("res://scripts/effects/claim_death_slot_effect.gd")
const PlayAnimationEffectScript := preload("res://scripts/effects/play_animation_effect.gd")
const GainPermanentAttackEffectScript := preload(
	"res://scripts/effects/gain_permanent_attack_effect.gd"
)
const UpdateSymbioteOffspringPoolEffectScript := preload(
	"res://scripts/effects/update_symbiote_offspring_pool_effect.gd"
)
const RandomNormalAttacksEffectScript := preload(
	"res://scripts/effects/random_normal_attacks_effect.gd"
)
const SymbioteWhipEffectScript := preload("res://scripts/effects/symbiote_whip_effect.gd")
const SymbioteAbsorbEffectScript := preload("res://scripts/effects/symbiote_absorb_effect.gd")
const CarnageKillProgressEffectScript := preload(
	"res://scripts/effects/carnage_kill_progress_effect.gd"
)
const AttachSymbioteOffspringEffectScript := preload(
	"res://scripts/effects/attach_symbiote_offspring_effect.gd"
)

var effects_by_id: Dictionary = {}
var granted_unit_trigger_resolver := GrantedUnitTriggerResolverScript.new()

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
	register_effect(
		EffectData.EFFECT_GAIN_PERMANENT_ATTACK,
		GainPermanentAttackEffectScript.new()
	)
	register_effect(
		EffectData.EFFECT_UPDATE_SYMBIOTE_OFFSPRING_POOL,
		UpdateSymbioteOffspringPoolEffectScript.new()
	)
	register_effect(
		EffectData.EFFECT_RANDOM_NORMAL_ATTACKS,
		RandomNormalAttacksEffectScript.new()
	)
	register_effect(EffectData.EFFECT_SYMBIOTE_WHIP, SymbioteWhipEffectScript.new())
	register_effect(EffectData.EFFECT_SYMBIOTE_ABSORB, SymbioteAbsorbEffectScript.new())
	register_effect(
		EffectData.EFFECT_CARNAGE_KILL_PROGRESS,
		CarnageKillProgressEffectScript.new()
	)
	register_effect(
		EffectData.EFFECT_ATTACH_SYMBIOTE_OFFSPRING,
		AttachSymbioteOffspringEffectScript.new()
	)
	register_effect(EffectData.EFFECT_PLAY_SPELL_ACTION, PlaySpellActionEffect.new())
	register_effect(EffectData.EFFECT_APPLY_STATUS, ApplyStatusEffect.new())
	register_effect(EffectData.EFFECT_APPLY_KAGUNE_POWER, ApplyKagunePowerEffectScript.new())
	register_effect(EffectData.EFFECT_DESTROY_UNITS, DestroyUnitsEffectScript.new())
	register_effect(EffectData.EFFECT_LIFE_DRAIN, LifeDrainEffectScript.new())
	register_effect(EffectData.EFFECT_RESURRECT, ResurrectEffect.new())
	register_effect(EffectData.EFFECT_ADD_CARD_TO_HAND, AddCardToHandEffect.new())
	register_effect(EffectData.EFFECT_CHOOSE_CARD_TO_HAND, ChooseCardToHandEffect.new())
	register_effect(EffectData.EFFECT_SET_SLOT_TRAP, SetSlotTrapEffect.new())
	register_effect(EffectData.EFFECT_SWAP_BOARD_SLOTS, SwapBoardSlotsEffect.new())
	register_effect(EffectData.EFFECT_DEVOUR, DevourEffect.new())
	register_effect(EffectData.EFFECT_LINK_UNITS, LinkUnitsEffect.new())
	register_effect(EffectData.EFFECT_DESTROY_LINKED_UNITS, DestroyLinkedUnitsEffect.new())
	register_effect(EffectData.EFFECT_SET_FACTION_RUNTIME_STATE, SetFactionRuntimeStateEffect.new())
	register_effect(EffectData.EFFECT_MOONBLADE, MoonbladeEffect.new())
	register_effect(EffectData.EFFECT_GRANT_REBORN, GrantRebornEffect.new())
	register_effect(EffectData.EFFECT_CLEANSE, CleanseEffect.new())
	register_effect(EffectData.EFFECT_EVOLVE_UNITS, EvolveUnitsEffect.new())
	register_effect(EffectData.EFFECT_TRANSFORM_UNIT, TransformUnitEffectScript.new())
	register_effect(EffectData.EFFECT_RESTORE_TRANSFORM, RestoreTransformEffectScript.new())
	register_effect(EffectData.EFFECT_SACRIFICE_FRIENDLY_MINIONS, SacrificeFriendlyMinionsEffect.new())
	register_effect(EffectData.EFFECT_GRANT_BOARD_VISION, GrantBoardVisionEffect.new())
	register_effect(EffectData.EFFECT_SYNC_STATS_FROM_OWNER_CARD, SyncStatsFromOwnerCardEffectScript.new())
	register_effect(EffectData.EFFECT_ASSIST_ATTACK_ATTACK_TARGET, AssistAttackAttackTargetEffectScript.new())
	register_effect(EffectData.EFFECT_CHAOS_CORRUPTION_BURST, ChaosCorruptionBurstEffectScript.new())
	register_effect(EffectData.EFFECT_SET_BEAST_PATH, SetBeastPathEffectScript.new())
	register_effect(EffectData.EFFECT_PERIODIC_STATUS_AURA, PeriodicStatusAuraEffectScript.new())
	register_effect(EffectData.EFFECT_PERIODIC_TRIGGER, PeriodicTriggerEffectScript.new())
	register_effect(EffectData.EFFECT_CLAIM_DEATH_SLOT, ClaimDeathSlotEffectScript.new())
	register_effect(EffectData.EFFECT_PLAY_ANIMATION, PlayAnimationEffectScript.new())


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
			if not matches_trigger_source(effect_data, context):
				continue
			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
			await execute_effect(source_state, runtime_effect_data, game_manager)

	await granted_unit_trigger_resolver.execute_granted_triggers(source_state, trigger, game_manager, context)
	await execute_status_triggers(source_state, trigger, game_manager, context)


func execute_status_triggers(source_state: CardState, trigger: String, game_manager: Node, context: Dictionary = {}) -> void:
	for status in source_state.statuses.duplicate():
		if status == null:
			continue

		var did_trigger := false
		for effect_data in EffectData.get_status_trigger_effects(status, trigger):
			var runtime_effect_data := EffectData.duplicate_with_context(effect_data, context)
			scale_status_trigger_amount(runtime_effect_data, status)
			EffectData.mark_effect_owner(runtime_effect_data, source_state.owner_id)
			EffectData.mark_trigger_status(runtime_effect_data, status)
			EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
			await execute_effect(source_state, runtime_effect_data, game_manager)
			did_trigger = true

		if did_trigger and bool(status.payload.get(EffectData.KEY_CONSUME_ON_TRIGGER, false)):
			source_state.remove_status_instance(status)


func matches_trigger_source(effect_data: Dictionary, context: Dictionary) -> bool:
	var source_card_ids := EffectData.get_source_card_ids(effect_data)
	if source_card_ids.is_empty():
		return true

	var source_card_id := str(context.get(EventContext.SOURCE_CARD_ID, ""))
	if source_card_id == "":
		var source_state := context.get(EventContext.SOURCE_STATE) as CardState
		if source_state != null:
			for card_id in source_card_ids:
				if source_state.represents_card_id(card_id):
					return true
			source_card_id = source_state.card_id

	return source_card_ids.has(source_card_id)


func scale_status_trigger_amount(effect_data: Dictionary, status: CardStatus) -> void:
	if status == null:
		return

	if not bool(effect_data.get(EffectData.KEY_SCALE_AMOUNT_BY_STATUS_STACKS, false)):
		return

	var amount := EffectData.get_amount(effect_data)
	if amount == 0:
		return

	effect_data[EffectData.KEY_AMOUNT] = amount * maxi(status.stacks, 1)
