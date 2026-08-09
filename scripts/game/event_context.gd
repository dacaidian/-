extends RefCounted
class_name EventContext

# 事件和触发上下文的公共 key。规则层和效果层都通过这里取值，避免字符串散落。

const TRIGGER_ON_REVEAL := "on_reveal"
const TRIGGER_ON_ENTER_BOARD := "on_enter_board"
const TRIGGER_ON_DESTROYED := "on_destroyed"
const TRIGGER_AFTER_ATTACK := "after_attack"
const TRIGGER_ON_KILL := "on_kill"
const TRIGGER_AFTER_FRIENDLY_ATTACK := "after_friendly_attack"
const TRIGGER_BEFORE_TURN_START := "before_turn_start"
const TRIGGER_AFTER_TURN_END := "after_turn_end"
const TRIGGER_ON_EFFECTIVE_HEAL := "on_effective_heal"

const DEAD_STATE := "_dead_state"
const DEATH := "_death"
const DESTROYER_PLAYER_ID := "_destroyer_player_id"
const SOURCE_STATE := "_source_state"
const SOURCE_CARD_ID := "_source_card_id"
const TURN_PLAYER_ID := "_turn_player_id"
const EFFECTIVE_HEAL_AMOUNT := "_effective_heal_amount"
const ATTACK_TARGET_STATE := "_attack_target_state"
