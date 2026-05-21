extends RefCounted
class_name HandSpellModifierResolver

# HandSpellModifierResolver handles hand upgrades that rewrite spell cards at cast time.
# It is intentionally stateless: the current player hand, spell card and selected target
# fully determine the resulting runtime effects and animation.


func resolve_hand_spell(
	player: PlayerState,
	card_data: CardData,
	target_state: CardState
) -> Dictionary:
	var resolved_effects := duplicate_effects(card_data.effects if card_data != null else [])
	var resolved_animation := card_data.animation if card_data != null else ""

	if player == null or card_data == null:
		return {
			"effects": resolved_effects,
			"animation": resolved_animation
		}

	for modifier_data in get_hand_spell_modifiers(player):
		if not applies_to_spell(modifier_data, card_data, player, target_state):
			continue

		var replacement_effects := EffectData.get_replace_effects(modifier_data)
		if not replacement_effects.is_empty():
			resolved_effects = duplicate_effects(replacement_effects)

		var append_effects := EffectData.get_append_effects(modifier_data)
		for append_effect in append_effects:
			resolved_effects.append(append_effect.duplicate(true))

		var modifier_animation := str(modifier_data.get("animation", ""))
		if modifier_animation != "":
			resolved_animation = modifier_animation

	return {
		"effects": resolved_effects,
		"animation": resolved_animation
	}


func get_hand_spell_modifiers(player: PlayerState) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	if player == null:
		return modifiers

	for hand_entry in player.hand:
		var hand_card_data := HandCardState.get_card_data(hand_entry)
		if hand_card_data == null:
			continue

		for effect_data in hand_card_data.effects:
			if not effect_data is Dictionary:
				continue
			if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_HAND_SPELL_EFFECTS:
				continue
			if not is_active_modifier(effect_data):
				continue

			modifiers.append(effect_data)

	return modifiers


func is_active_modifier(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	if trigger == "":
		return EffectData.is_active_in_hand(effect_data)

	return trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE


func applies_to_spell(
	modifier_data: Dictionary,
	card_data: CardData,
	player: PlayerState,
	target_state: CardState
) -> bool:
	if card_data == null:
		return false

	var card_ids := EffectData.get_card_ids(modifier_data)
	if not card_ids.is_empty() and not card_ids.has(card_data.id):
		return false

	return matches_target_relation(EffectData.get_target_relation(modifier_data), player, target_state)


func matches_target_relation(relation: String, player: PlayerState, target_state: CardState) -> bool:
	match relation:
		EffectData.TARGET_RELATION_ANY:
			return true
		EffectData.TARGET_RELATION_FRIENDLY:
			return player != null and target_state != null and target_state.owner_id == player.id
		EffectData.TARGET_RELATION_ENEMY:
			return (
				player != null
				and target_state != null
				and target_state.owner_id != ""
				and target_state.owner_id != player.id
			)
		_:
			push_warning("暂不支持的手牌法术修正目标关系: %s" % relation)
			return false


func duplicate_effects(effects: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated_effects: Array[Dictionary] = []
	for effect_data in effects:
		if effect_data is Dictionary:
			duplicated_effects.append(effect_data.duplicate(true))

	return duplicated_effects
