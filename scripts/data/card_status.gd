extends Resource
class_name CardStatus

# CardStatus 是附着在棋盘单位上的运行时状态。
# 它只记录“状态是什么、谁施加、多久后结束”，具体效果由后续状态/触发系统解释。

const DURATION_SCOPE_TARGET_OWNER := "target_owner"
const DURATION_SCOPE_SOURCE_OWNER := "source_owner"
const DURATION_SCOPE_GLOBAL := "global"

const DEFAULT_EXPIRES_ON_TRIGGER := EventContext.TRIGGER_AFTER_TURN_END
const STATUS_DIVINE_SHIELD := "divine_shield"
const STATUS_ARCANE_AURA := "arcane_aura"
const STATUS_ENCOURAGE_GU := "encourage_gu"
const TAG_DAMAGE_PREVENTION := "damage_prevention"
const TAG_AURA := "aura"
const TAG_ACTION_PREVENTION := "action_prevention"
const TAG_ATTACK_MODIFIER := "attack_modifier"
const STATUS_FREEZE := "freeze"

var status_id := ""
var display_name := ""
var description := ""
var tags: Array[String] = []
var stacks := 1
var is_permanent := true
var remaining_turns := -1
var duration_scope := DURATION_SCOPE_TARGET_OWNER
var expires_on_trigger := DEFAULT_EXPIRES_ON_TRIGGER
var persists_after_death := false
var source_card_id := ""
var source_owner_id := ""
var duration_owner_id := ""
var payload: Dictionary = {}


static func from_effect_data(effect_data: Dictionary, target_state: CardState, source_state: CardState) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = EffectData.get_status_id(effect_data)
	status.display_name = EffectData.get_status_name(effect_data, status.status_id)
	status.description = EffectData.get_status_description(effect_data)
	status.tags = EffectData.get_status_tags(effect_data)
	status.stacks = maxi(EffectData.get_status_stacks(effect_data), 1)
	status.is_permanent = EffectData.is_permanent_status(effect_data)
	status.remaining_turns = EffectData.get_status_duration_turns(effect_data)
	status.duration_scope = EffectData.get_status_duration_scope(effect_data)
	status.expires_on_trigger = EffectData.get_status_expires_on_trigger(effect_data)
	status.persists_after_death = EffectData.status_persists_after_death(effect_data)
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

	stacks += other.stacks
	if is_permanent or other.is_permanent:
		is_permanent = true
		remaining_turns = -1
	else:
		remaining_turns = maxi(remaining_turns, other.remaining_turns)

	payload.merge(other.payload, true)


func to_snapshot() -> Dictionary:
	return {
		"status_id": status_id,
		"display_name": display_name,
		"description": description,
		"tags": tags.duplicate(),
		"stacks": stacks,
		"is_permanent": is_permanent,
		"remaining_turns": remaining_turns,
		"duration_scope": duration_scope,
		"expires_on_trigger": expires_on_trigger,
		"persists_after_death": persists_after_death,
		"source_card_id": source_card_id,
		"source_owner_id": source_owner_id,
		"duration_owner_id": duration_owner_id,
		"payload": payload.duplicate(true)
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	status_id = str(snapshot.get("status_id", ""))
	display_name = str(snapshot.get("display_name", status_id))
	description = str(snapshot.get("description", ""))
	tags = normalize_string_array(snapshot.get("tags", []))
	stacks = maxi(int(snapshot.get("stacks", 1)), 1)
	is_permanent = bool(snapshot.get("is_permanent", true))
	remaining_turns = int(snapshot.get("remaining_turns", -1))
	duration_scope = str(snapshot.get("duration_scope", DURATION_SCOPE_TARGET_OWNER))
	expires_on_trigger = str(snapshot.get("expires_on_trigger", DEFAULT_EXPIRES_ON_TRIGGER))
	persists_after_death = bool(snapshot.get("persists_after_death", false))
	source_card_id = str(snapshot.get("source_card_id", ""))
	source_owner_id = str(snapshot.get("source_owner_id", ""))
	duration_owner_id = str(snapshot.get("duration_owner_id", ""))

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
