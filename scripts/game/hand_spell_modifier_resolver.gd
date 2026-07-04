extends RefCounted
class_name HandSpellModifierResolver

# HandSpellModifierResolver handles hand upgrades that rewrite spell abilities at runtime.
# It is intentionally stateless: the current player hand, spell definition and selected
# target fully determine the resulting runtime target rule, effects and animation.


func resolve_hand_spell(
	player: PlayerState,
	card_data: CardData,
	target_state: CardState
) -> Dictionary:
	var resolved_effects := duplicate_effects(card_data.effects if card_data != null else [])
	var resolved_animation := card_data.animation if card_data != null else ""
	var resolved_target_rule := SpellTargetResolver.get_rule_from_card_data(card_data)

	if player == null or card_data == null:
		return {
			"effects": resolved_effects,
			"animation": resolved_animation,
			"target_rule": resolved_target_rule
		}

	for modifier_data in get_spell_modifiers(player):
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

		var modifier_target_rule := EffectData.get_target_rule(modifier_data)
		if modifier_target_rule != "":
			resolved_target_rule = modifier_target_rule

	return {
		"effects": resolved_effects,
		"animation": resolved_animation,
		"target_rule": resolved_target_rule
	}


func resolve_spell_action(
	player: PlayerState,
	spell_data: Dictionary,
	target_state: CardState = null
) -> Dictionary:
	var resolved_spell := spell_data.duplicate(true)
	if player == null or spell_data.is_empty():
		return resolved_spell

	var spell_id := str(resolved_spell.get("id", ""))
	for modifier_data in get_spell_modifiers(player):
		if not applies_to_spell_id(modifier_data, spell_id):
			continue
		if not matches_target_relation(EffectData.get_target_relation(modifier_data), player, target_state):
			continue

		var replacement_effects := EffectData.get_replace_effects(modifier_data)
		if not replacement_effects.is_empty():
			resolved_spell["effects"] = duplicate_effects(replacement_effects)

		var append_effects := EffectData.get_append_effects(modifier_data)
		if not append_effects.is_empty():
			var resolved_effects := duplicate_effects(resolved_spell.get("effects", []))
			for append_effect in append_effects:
				resolved_effects.append(append_effect.duplicate(true))
			resolved_spell["effects"] = resolved_effects

		var modifier_animation := str(modifier_data.get("animation", ""))
		if modifier_animation != "":
			resolved_spell["animation"] = modifier_animation

		var modifier_target_rule := EffectData.get_target_rule(modifier_data)
		if modifier_target_rule != "":
			resolved_spell["target_rule"] = modifier_target_rule

	return resolved_spell


func get_spell_modifiers(player: PlayerState) -> Array[Dictionary]:
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
			if not is_spell_modifier_effect(effect_data):
				continue
			if not is_active_modifier(effect_data):
				continue

			modifiers.append(effect_data)

	for equipment_data in player.get_equipped_cards():
		if equipment_data == null:
			continue

		for effect_data in equipment_data.effects:
			if not effect_data is Dictionary:
				continue
			if not is_spell_modifier_effect(effect_data):
				continue
			if not is_equipped_modifier(effect_data):
				continue

			modifiers.append(effect_data)

	return modifiers


func is_spell_modifier_effect(effect_data: Dictionary) -> bool:
	var effect_id := EffectData.get_id(effect_data)
	return (
		effect_id == EffectData.EFFECT_MODIFY_HAND_SPELL_EFFECTS
		or effect_id == EffectData.EFFECT_MODIFY_SPELL_ABILITY
	)


func is_active_modifier(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	if trigger == "":
		return EffectData.is_active_in_hand(effect_data)

	return trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE


func is_equipped_modifier(effect_data: Dictionary) -> bool:
	return EffectData.get_trigger(effect_data) == EffectData.TRIGGER_WHILE_EQUIPPED


func applies_to_spell(
	modifier_data: Dictionary,
	card_data: CardData,
	player: PlayerState,
	target_state: CardState
) -> bool:
	if card_data == null:
		return false

	var card_ids := EffectData.get_card_ids(modifier_data)
	var spell_ids := EffectData.get_spell_ids(modifier_data)
	if not card_ids.is_empty():
		if not card_ids.has(card_data.id):
			return false
	elif not spell_ids.is_empty():
		return false

	return matches_target_relation(EffectData.get_target_relation(modifier_data), player, target_state)


func applies_to_spell_id(modifier_data: Dictionary, spell_id: String) -> bool:
	var spell_ids := EffectData.get_spell_ids(modifier_data)
	if not spell_ids.is_empty():
		return spell_id != "" and spell_ids.has(spell_id)

	if not EffectData.get_card_ids(modifier_data).is_empty():
		return false

	return true


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


func duplicate_effects(effects: Variant) -> Array[Dictionary]:
	var duplicated_effects: Array[Dictionary] = []
	if effects is Array:
		for effect_data in effects:
			if effect_data is Dictionary:
				duplicated_effects.append(effect_data.duplicate(true))

	return duplicated_effects
