extends Resource
class_name CardStatus

# CardStatus 是附着在棋盘单位上的运行时状态。
# 它只记录“状态是什么、谁施加、多久后结束”，具体效果由后续状态/触发系统解释。

const DURATION_SCOPE_TARGET_OWNER := "target_owner"
const DURATION_SCOPE_SOURCE_OWNER := "source_owner"
const DURATION_SCOPE_GLOBAL := "global"

const DEFAULT_EXPIRES_ON_TRIGGER := EventContext.TRIGGER_AFTER_TURN_END
const STATUS_DIVINE_SHIELD := "divine_shield"
const STATUS_POWER_WORD_SHIELD := "power_word_shield"
const STATUS_ARCANE_AURA := "arcane_aura"
const STATUS_ENCOURAGE_GU := "encourage_gu"
const STATUS_POISON := "poison"
const STATUS_SNAKE_VENOM := "snake_venom"
const STATUS_DEVOUR := "devour"
const STATUS_LIFE_LINK_LARVA := "life_link_larva"
const STATUS_LIFE_LINK := "life_link"
const STATUS_DEATH_IMMUNITY := "death_immunity"
const STATUS_STORED_VENOM := "stored_venom"
const STATUS_PRECISION_SHOT := "precision_shot"
const STATUS_METEOR_AURA := "meteor_aura"
const STATUS_SOUL_HOOK := "soul_hook"
const STATUS_CHARM := "charm"
const STATUS_SOMERSAULT_CLOUD := "somersault_cloud"
const STATUS_BRONZE_HEAD_IRON_ARMS := "bronze_head_iron_arms"
const STATUS_IMMORTAL_PEACH := "immortal_peach"
const STATUS_ROOTED := "rooted"
const STATUS_GATHER_SCATTER_QI := "gather_scatter_qi"
const STATUS_TRANSFORM := "transform"
const STATUS_SAVAGE_ROAR_ATTACK := "savage_roar_attack"
const STATUS_WANMO_CHARGE := "wanmo_charge"
const STATUS_FEL_INFUSION := "fel_infusion"
const STATUS_FEL_OVERLOAD := "fel_overload"
const STATUS_FEL_MADNESS_CHAOS_ORC := "fel_madness_chaos_orc"
const STATUS_FEL_MADNESS_HELLHOUND := "fel_madness_hellhound"
const STATUS_FEL_MADNESS_SUCCUBUS := "fel_madness_succubus"
const STATUS_FEL_MADNESS_CHAOS_WOLF_RIDER := "fel_madness_chaos_wolf_rider"
const STACK_POLICY_STACK := "stack"
const STACK_POLICY_REFRESH := "refresh"
const STACK_POLICY_REPLACE := "replace"
const STACK_POLICY_IGNORE := "ignore"
const TAG_DAMAGE_PREVENTION := "damage_prevention"
const TAG_AURA := "aura"
const TAG_ACTION_PREVENTION := "action_prevention"
const TAG_ATTACK_MODIFIER := "attack_modifier"
const TAG_HEALTH_MODIFIER := "health_modifier"
const TAG_DAMAGE_OVER_TIME := "damage_over_time"
const TAG_DEATH_LINK := "death_link"
const TAG_MANA_GENERATION := "mana_generation"
const TAG_DEATH_PREVENTION := "death_prevention"
const TAG_STORED_RESOURCE := "stored_resource"
const TAG_CONTROL := "control"
const TAG_STEALTH := "stealth"
const TAG_BREAKS_ON_ATTACK_OR_SPELL := "breaks_on_attack_or_spell"
const TAG_TRANSFORM := "transform"
const TAG_UNCLEANSEABLE := "uncleanseable"
const STATUS_FREEZE := "freeze"

var status_id := ""
var display_name := ""
var description := ""
var tags: Array[String] = []
var stacks := 1
var stack_policy := STACK_POLICY_STACK
var is_permanent := true
var remaining_turns := -1
var duration_scope := DURATION_SCOPE_TARGET_OWNER
var expires_on_trigger := DEFAULT_EXPIRES_ON_TRIGGER
var persists_after_death := false
var source_card_id := ""
var source_owner_id := ""
var duration_owner_id := ""
var valence := EffectData.STATUS_VALENCE_NEUTRAL
var payload: Dictionary = {}


static func from_effect_data(effect_data: Dictionary, target_state: CardState, source_state: CardState) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = EffectData.get_status_id(effect_data)
	status.display_name = EffectData.get_status_name(effect_data, status.status_id)
	status.description = EffectData.get_status_description(effect_data)
	status.tags = EffectData.get_status_tags(effect_data)
	status.stacks = maxi(EffectData.get_status_stacks(effect_data), 1)
	status.stack_policy = EffectData.get_status_stack_policy(effect_data)
	status.is_permanent = EffectData.is_permanent_status(effect_data)
	status.remaining_turns = EffectData.get_status_duration_turns(effect_data)
	status.duration_scope = EffectData.get_status_duration_scope(effect_data)
	status.expires_on_trigger = EffectData.get_status_expires_on_trigger(effect_data)
	status.persists_after_death = EffectData.status_persists_after_death(effect_data)
	status.valence = EffectData.get_status_valence(effect_data)
	status.payload = EffectData.get_status_payload(effect_data)

	if source_state != null:
		status.source_card_id = source_state.card_id
		status.source_owner_id = source_state.owner_id
	else:
		status.source_owner_id = EffectData.get_effect_owner_id(effect_data)

	status.duration_owner_id = status.resolve_duration_owner_id(target_state)
	return status


func resolve_duration_owner_id(target_state: CardState) -> String:
	match duration_scope:
		DURATION_SCOPE_SOURCE_OWNER:
			return source_owner_id
		DURATION_SCOPE_GLOBAL:
			return ""
		_:
			return target_state.owner_id if target_state != null else ""


func should_tick(trigger: String, turn_player_id: String) -> bool:
	if is_permanent:
		return false
	if trigger != expires_on_trigger:
		return false
	if duration_scope == DURATION_SCOPE_GLOBAL:
		return true

	return duration_owner_id != "" and duration_owner_id == turn_player_id


func tick_turn() -> bool:
	if is_permanent:
		return false
	if remaining_turns < 0:
		return false

	remaining_turns -= 1
	return remaining_turns <= 0


func is_same_stack_key(other: CardStatus) -> bool:
	if other == null:
		return false

	return (
		status_id == other.status_id
		and source_card_id == other.source_card_id
		and source_owner_id == other.source_owner_id
	)


func merge_from(other: CardStatus) -> void:
	if other == null:
		return

	match other.stack_policy:
		STACK_POLICY_IGNORE:
			return
		STACK_POLICY_REPLACE:
			stacks = other.stacks
			is_permanent = other.is_permanent
			remaining_turns = other.remaining_turns
			payload = other.payload.duplicate(true)
		STACK_POLICY_REFRESH:
			stacks = maxi(stacks, other.stacks)
			if is_permanent or other.is_permanent:
				is_permanent = true
				remaining_turns = -1
			else:
				remaining_turns = maxi(remaining_turns, other.remaining_turns)
			payload.merge(other.payload, true)
		_:
			stacks += other.stacks
			if is_permanent or other.is_permanent:
				is_permanent = true
				remaining_turns = -1
			else:
				remaining_turns = maxi(remaining_turns, other.remaining_turns)
			payload.merge(other.payload, true)

	stack_policy = other.stack_policy
	if is_permanent or other.is_permanent:
		is_permanent = true
		remaining_turns = -1


func get_poison_damage() -> int:
	return int(payload.get(EffectData.KEY_POISON_DAMAGE, 0))


func get_poison_total_remaining_damage() -> int:
	if status_id != STATUS_POISON:
		return 0

	return get_poison_damage() * maxi(remaining_turns, 0)


func get_stored_venom_damage() -> int:
	return int(payload.get(EffectData.KEY_STORED_VENOM_DAMAGE, 0))


func get_wanmo_charge() -> int:
	if status_id != STATUS_WANMO_CHARGE:
		return 0

	return maxi(stacks, 0)


func is_stronger_poison_than(other: CardStatus) -> bool:
	if status_id != STATUS_POISON:
		return false
	if other == null:
		return true

	var total_damage := get_poison_total_remaining_damage()
	var other_total_damage := other.get_poison_total_remaining_damage()
	if total_damage != other_total_damage:
		return total_damage > other_total_damage

	return get_poison_damage() > other.get_poison_damage()


func to_snapshot() -> Dictionary:
	return {
		"status_id": status_id,
		"display_name": display_name,
		"description": description,
		"tags": tags.duplicate(),
		"stacks": stacks,
		"stack_policy": stack_policy,
		"is_permanent": is_permanent,
		"remaining_turns": remaining_turns,
		"duration_scope": duration_scope,
		"expires_on_trigger": expires_on_trigger,
		"persists_after_death": persists_after_death,
		"source_card_id": source_card_id,
		"source_owner_id": source_owner_id,
		"duration_owner_id": duration_owner_id,
		"valence": valence,
		"payload": payload.duplicate(true)
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	status_id = str(snapshot.get("status_id", ""))
	display_name = str(snapshot.get("display_name", status_id))
	description = str(snapshot.get("description", ""))
	tags = normalize_string_array(snapshot.get("tags", []))
	stacks = maxi(int(snapshot.get("stacks", 1)), 1)
	stack_policy = str(snapshot.get("stack_policy", STACK_POLICY_STACK))
	is_permanent = bool(snapshot.get("is_permanent", true))
	remaining_turns = int(snapshot.get("remaining_turns", -1))
	duration_scope = str(snapshot.get("duration_scope", DURATION_SCOPE_TARGET_OWNER))
	expires_on_trigger = str(snapshot.get("expires_on_trigger", DEFAULT_EXPIRES_ON_TRIGGER))
	persists_after_death = bool(snapshot.get("persists_after_death", false))
	source_card_id = str(snapshot.get("source_card_id", ""))
	source_owner_id = str(snapshot.get("source_owner_id", ""))
	duration_owner_id = str(snapshot.get("duration_owner_id", ""))
	valence = str(snapshot.get("valence", EffectData.STATUS_VALENCE_NEUTRAL))

	var snapshot_payload: Variant = snapshot.get("payload", {})
	if snapshot_payload is Dictionary:
		payload = snapshot_payload.duplicate(true)
	else:
		payload = {}


func normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))

	return result


func get_cleanse_valence() -> String:
	if valence != "" and valence != EffectData.STATUS_VALENCE_NEUTRAL:
		return valence

	var positive_status_ids := [
		STATUS_DIVINE_SHIELD,
		STATUS_POWER_WORD_SHIELD,
		STATUS_ARCANE_AURA,
		STATUS_ENCOURAGE_GU,
		STATUS_DEVOUR,
		STATUS_DEATH_IMMUNITY,
		STATUS_STORED_VENOM,
		STATUS_PRECISION_SHOT,
		STATUS_METEOR_AURA,
		STATUS_SOMERSAULT_CLOUD,
		STATUS_BRONZE_HEAD_IRON_ARMS,
		STATUS_IMMORTAL_PEACH,
		STATUS_GATHER_SCATTER_QI,
		STATUS_SAVAGE_ROAR_ATTACK,
		STATUS_FEL_INFUSION,
		STATUS_FEL_MADNESS_CHAOS_ORC,
		STATUS_FEL_MADNESS_HELLHOUND,
		STATUS_FEL_MADNESS_SUCCUBUS,
		STATUS_FEL_MADNESS_CHAOS_WOLF_RIDER
	]
	if positive_status_ids.has(status_id):
		return EffectData.STATUS_VALENCE_POSITIVE

	var negative_status_ids := [
		STATUS_POISON,
		STATUS_SNAKE_VENOM,
		STATUS_LIFE_LINK_LARVA,
		STATUS_LIFE_LINK,
		STATUS_SOUL_HOOK,
		STATUS_CHARM,
		STATUS_ROOTED,
		STATUS_FREEZE
	]
	if negative_status_ids.has(status_id):
		return EffectData.STATUS_VALENCE_NEGATIVE

	var attack_bonus := int(payload.get(EffectData.KEY_ATTACK_BONUS, 0))
	var max_health_bonus := int(payload.get(EffectData.KEY_MAX_HEALTH_BONUS, 0))
	if tags.has(TAG_ATTACK_MODIFIER) or tags.has(TAG_HEALTH_MODIFIER):
		if attack_bonus > 0 or max_health_bonus > 0:
			return EffectData.STATUS_VALENCE_POSITIVE
		if attack_bonus < 0 or max_health_bonus < 0:
			return EffectData.STATUS_VALENCE_NEGATIVE

	if tags.has(TAG_ACTION_PREVENTION) or tags.has(TAG_DAMAGE_OVER_TIME) or tags.has(TAG_DEATH_LINK) or tags.has(TAG_CONTROL):
		return EffectData.STATUS_VALENCE_NEGATIVE
	if (
		tags.has(TAG_DAMAGE_PREVENTION)
		or tags.has(TAG_AURA)
		or tags.has(TAG_MANA_GENERATION)
		or tags.has(TAG_DEATH_PREVENTION)
		or tags.has(TAG_STORED_RESOURCE)
		or tags.has(TAG_STEALTH)
	):
		return EffectData.STATUS_VALENCE_POSITIVE

	return EffectData.STATUS_VALENCE_NEUTRAL
