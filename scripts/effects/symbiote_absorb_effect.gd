extends CardEffect
class_name SymbioteAbsorbEffect

const STATUS_ID := "symbiote_absorption"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var target_state := EffectData.get_selected_target_state(effect_data)
	if not can_absorb_target(source_state, target_state):
		return

	apply_absorption(source_state, target_state)
	if game_manager != null and game_manager.has_method("destroy_card_with_refill"):
		await game_manager.destroy_card_with_refill(
			target_state,
			EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_SPELL),
			source_state,
			true,
			get_effect_owner_id(source_state, effect_data)
		)


func can_execute(source_state: CardState, effect_data: Dictionary, _game_manager: Node) -> bool:
	return can_absorb_target(source_state, EffectData.get_selected_target_state(effect_data))


func can_absorb_target(source_state: CardState, target_state: CardState) -> bool:
	return (
		source_state != null
		and target_state != null
		and source_state != target_state
		and BoardQuery.is_face_up_minion(target_state)
		and not target_state.is_hero()
		and source_state.owner_id != ""
		and target_state.owner_id != ""
		and source_state.owner_id != target_state.owner_id
		and not target_state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION)
	)


func apply_absorption(source_state: CardState, target_state: CardState) -> void:
	var status := source_state.get_status(STATUS_ID)
	if status == null:
		status = create_absorption_status(source_state)
		source_state.statuses.append(status)
	else:
		status.stacks += 1

	status.payload[EffectData.KEY_ATTACK_BONUS] = (
		int(status.payload.get(EffectData.KEY_ATTACK_BONUS, 0)) + target_state.current_attack
	)
	status.payload[EffectData.KEY_MAX_HEALTH_BONUS] = (
		int(status.payload.get(EffectData.KEY_MAX_HEALTH_BONUS, 0)) + target_state.max_health
	)
	append_unique_strings(
		status.payload[EffectData.KEY_KEYWORDS],
		target_state.data.keywords if target_state.data != null else []
	)
	append_unique_dictionaries(
		status.payload[EffectData.KEY_SPELL_ACTIONS],
		target_state.data.spell_actions if target_state.data != null else [],
		"id"
	)
	append_unique_dictionaries(
		status.payload[EffectData.KEY_ACTIONS],
		target_state.data.actions if target_state.data != null else [],
		"id"
	)
	append_unique_dictionaries(
		status.payload[EffectData.KEY_STATUS_TRIGGER_EFFECTS],
		target_state.data.effects if target_state.data != null else [],
		""
	)
	source_state.recalculate_status_modifiers(false)
	source_state.state_changed.emit(source_state)


func create_absorption_status(source_state: CardState) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = STATUS_ID
	status.display_name = "共生吞噬"
	status.description = "获得被吞噬随从当时的攻击、生命上限和固有技能。"
	status.tags = [CardStatus.TAG_ATTACK_MODIFIER, CardStatus.TAG_HEALTH_MODIFIER]
	status.stacks = 1
	status.stack_policy = CardStatus.STACK_POLICY_STACK
	status.is_permanent = true
	status.source_card_id = source_state.card_id
	status.source_owner_id = source_state.owner_id
	status.duration_owner_id = source_state.owner_id
	status.valence = EffectData.STATUS_VALENCE_POSITIVE
	status.payload = {
		EffectData.KEY_ATTACK_BONUS: 0,
		EffectData.KEY_MAX_HEALTH_BONUS: 0,
		EffectData.KEY_CUMULATIVE_STATUS_MODIFIER: true,
		EffectData.KEY_KEYWORDS: [],
		EffectData.KEY_SPELL_ACTIONS: [],
		EffectData.KEY_ACTIONS: [],
		EffectData.KEY_STATUS_TRIGGER_EFFECTS: [],
	}
	return status


func append_unique_strings(target_values: Variant, source_values: Array) -> void:
	if not target_values is Array:
		return
	for raw_value in source_values:
		var value := str(raw_value)
		if value != "" and not target_values.has(value):
			target_values.append(value)


func append_unique_dictionaries(
	target_values: Variant,
	source_values: Array,
	id_key: String
) -> void:
	if not target_values is Array:
		return
	for raw_value in source_values:
		if not raw_value is Dictionary:
			continue
		var value := (raw_value as Dictionary).duplicate(true)
		var is_duplicate := false
		for existing_value in target_values:
			if not existing_value is Dictionary:
				continue
			if id_key != "":
				if str(existing_value.get(id_key, "")) == str(value.get(id_key, "")):
					is_duplicate = true
					break
			elif existing_value == value:
				is_duplicate = true
				break
		if not is_duplicate:
			target_values.append(value)
