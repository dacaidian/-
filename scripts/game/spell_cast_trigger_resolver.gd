extends RefCounted
class_name SpellCastTriggerResolver

# Resolves hand-zone upgrade effects that listen to successful spell casts.
# The spell itself only declares semantic tags such as "fel"; hand upgrades decide
# what those tags mean for the current faction.


func resolve_after_spell_cast(
	game_manager: GameManager,
	owner_id: String,
	caster_state: CardState,
	spell_data: Dictionary
) -> void:
	if game_manager == null or owner_id == "" or spell_data.is_empty():
		return

	var owner := game_manager.get_player_by_id(owner_id)
	if owner == null:
		return

	for card_entry in owner.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null or not card_data.is_upgrade():
			continue

		for effect_data in card_data.effects:
			if not is_after_spell_cast_hand_effect(effect_data, caster_state, spell_data):
				continue

			var runtime_effect_data := effect_data.duplicate(true)
			EffectData.mark_effect_owner(runtime_effect_data, owner_id)
			EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_EFFECT)
			await game_manager.effect_registry.execute_effect(caster_state, runtime_effect_data, game_manager)


func is_after_spell_cast_hand_effect(effect_data: Dictionary, caster_state: CardState, spell_data: Dictionary) -> bool:
	if EffectData.get_trigger(effect_data) != EffectData.TRIGGER_AFTER_SPELL_CAST:
		return false
	if not EffectData.is_active_in_hand(effect_data):
		return false
	if not is_spell_id_matched(effect_data, spell_data):
		return false
	if not are_spell_tags_matched(effect_data, spell_data):
		return false
	if not is_source_card_matched(effect_data, caster_state):
		return false

	return true


func is_spell_id_matched(effect_data: Dictionary, spell_data: Dictionary) -> bool:
	var spell_ids := EffectData.get_spell_ids(effect_data)
	if spell_ids.is_empty():
		return true

	var spell_id := str(spell_data.get(EffectData.KEY_ID, ""))
	return spell_id != "" and spell_ids.has(spell_id)


func are_spell_tags_matched(effect_data: Dictionary, spell_data: Dictionary) -> bool:
	var required_spell_tags := EffectData.get_required_spell_tags(effect_data)
	if required_spell_tags.is_empty():
		return true

	var spell_tags := EffectData.get_spell_tags(spell_data)
	for required_tag in required_spell_tags:
		if not spell_tags.has(required_tag):
			return false

	return true


func is_source_card_matched(effect_data: Dictionary, caster_state: CardState) -> bool:
	var source_card_ids := EffectData.get_source_card_ids(effect_data)
	if source_card_ids.is_empty():
		return true
	if caster_state == null:
		return false

	for card_id in source_card_ids:
		if caster_state.represents_card_id(card_id):
			return true

	return false
