extends RefCounted
class_name BoardSlotEffect

const TRIGGER_UNIT_ENTERED := "unit_entered"
const EFFECT_KILL_ENTERING_MINION := "kill_entering_minion"

var effect_id := ""
var display_name := ""
var owner_id := ""
var source_card_id := ""
var source_display_name := ""
var trigger := TRIGGER_UNIT_ENTERED
var consume_on_trigger := true
var death_reason := EffectData.DEATH_REASON_EFFECT
var trigger_animation := ""
var slot_index := -1


static func from_effect_data(
	slot: int,
	effect_data: Dictionary,
	source_state: CardState = null
) -> BoardSlotEffect:
	var slot_effect := BoardSlotEffect.new()
	slot_effect.slot_index = slot
	slot_effect.effect_id = str(effect_data.get(EffectData.KEY_SLOT_EFFECT_ID, EFFECT_KILL_ENTERING_MINION))
	slot_effect.display_name = str(effect_data.get(EffectData.KEY_SLOT_EFFECT_NAME, slot_effect.effect_id))
	slot_effect.owner_id = EffectData.get_effect_owner_id(effect_data)
	slot_effect.source_card_id = str(effect_data.get(EffectData.KEY_SOURCE_CARD_ID, ""))
	slot_effect.source_display_name = str(effect_data.get(EffectData.KEY_SOURCE_DISPLAY_NAME, ""))
	slot_effect.trigger = str(effect_data.get(EffectData.KEY_SLOT_EFFECT_TRIGGER, TRIGGER_UNIT_ENTERED))
	slot_effect.consume_on_trigger = bool(effect_data.get(EffectData.KEY_CONSUME_ON_TRIGGER, true))
	slot_effect.death_reason = EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_EFFECT)
	slot_effect.trigger_animation = str(effect_data.get(EffectData.KEY_TRIGGER_ANIMATION, ""))

	if source_state != null:
		if slot_effect.owner_id == "":
			slot_effect.owner_id = source_state.owner_id
		if slot_effect.source_card_id == "":
			slot_effect.source_card_id = source_state.card_id
		if slot_effect.source_display_name == "":
			slot_effect.source_display_name = source_state.display_name

	return slot_effect


func should_trigger_for_entering_unit(state: CardState) -> bool:
	return (
		trigger == TRIGGER_UNIT_ENTERED
		and effect_id == EFFECT_KILL_ENTERING_MINION
		and state != null
		and not state.is_empty()
		and state.is_face_up
		and state.is_minion()
	)
