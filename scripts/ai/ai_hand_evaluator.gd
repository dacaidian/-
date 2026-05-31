extends RefCounted

const AICommonScript = preload("res://scripts/ai/ai_common.gd")
const AIBoardEvaluatorScript = preload("res://scripts/ai/ai_board_evaluator.gd")

var _board_evaluator: RefCounted


func _init() -> void:
	_board_evaluator = AIBoardEvaluatorScript.new()


func evaluate_and_play_all(gm: GameManager, difficulty: String) -> void:
	if gm == null or gm.is_game_over:
		return

	var player := gm.get_current_player()
	if player == null or player.hand.is_empty():
		return

	var hpr := gm.get_hand_play_resolver()
	var threshold: float = AICommonScript.reserve_threshold(difficulty)
	var max_iterations := player.hand.size() * 2
	var iterations := 0

	while player.hand.size() > 0 and iterations < max_iterations:
		iterations += 1
		if gm.is_game_over:
			return

		var played := false
		for i in range(player.hand.size()):
			if gm.is_game_over:
				return

			if not player.is_hand_card_available_at(i):
				continue

			if not hpr.can_play_hand_card_at(player, i, gm):
				continue

			var card_data := player.get_hand_card_data_at(i)
			if card_data == null:
				continue

			var evaluation: Dictionary = _evaluate_single_card(card_data, i, player, gm, hpr)
			var score: float = AICommonScript.apply_difficulty_noise(evaluation["score"], difficulty)

			if score >= threshold:
				await _execute_card(card_data, i, player, evaluation["target"], gm)
				played = true
				break

		if not played:
			break


func _evaluate_single_card(card_data: CardData, _hand_index: int, player: PlayerState, gm: GameManager, hpr: HandPlayResolver) -> Dictionary:
	if card_data.is_spell():
		return _evaluate_spell(card_data, player, gm, hpr)
	elif card_data.is_minion():
		return _evaluate_minion_placement(card_data, player, gm, hpr)
	elif card_data.is_equipment():
		return _evaluate_equipment(card_data, player)
	return {"target": null, "score": 0.0}


func evaluate_hand_card(card_data: CardData, hand_index: int, player: PlayerState, gm: GameManager, hpr: HandPlayResolver) -> Dictionary:
	return _evaluate_single_card(card_data, hand_index, player, gm, hpr)


func _evaluate_spell(card_data: CardData, player: PlayerState, gm: GameManager, hpr: HandPlayResolver) -> Dictionary:
	var target_rule := hpr.get_target_rule(card_data)
	if not SpellTargetResolver.requires_target(target_rule):
		var no_target_effects := get_resolved_spell_effects(card_data, player, null, hpr)
		return {"target": null, "score": _score_no_target_spell(no_target_effects, player, gm)}

	var valid_targets: Array = hpr.get_valid_targets(card_data, gm)
	var best_target = null
	var best_score := 0.0

	for target in valid_targets:
		if target == null:
			continue
		var target_effects := get_resolved_spell_effects(card_data, player, target, hpr)
		var score: float = _score_spell_on_target(target_effects, target, player, gm)
		if score > best_score:
			best_target = target
			best_score = score

	return {"target": best_target, "score": best_score}


func get_resolved_spell_effects(
	card_data: CardData,
	player: PlayerState,
	target: CardState,
	hpr: HandPlayResolver
) -> Array[Dictionary]:
	if hpr == null:
		var fallback_effects: Array[Dictionary] = []
		if card_data != null:
			fallback_effects = card_data.effects.duplicate(true)
		return fallback_effects

	return hpr.get_resolved_spell_effects(player, card_data, target)


func _score_no_target_spell(effects: Array[Dictionary], _player: PlayerState, _gm: GameManager) -> float:
	var score := 0.0
	for effect_data in effects:
		if not effect_data is Dictionary:
			continue
		var effect_id := str(effect_data.get("id", ""))
		var amount := int(effect_data.get("amount", 1))

		# 资源分是胜利条件，优先级最高
		if effect_id == "gain_resource_score":
			score += amount * 10.0
		elif effect_id == "gain_flips":
			score += amount * 4.0
		elif effect_id == "gain_mana":
			score += amount * 3.0
		elif effect_id == "add_card_to_hand" or effect_id == "choose_card_to_hand":
			score += 4.0
		elif effect_id == "resurrect":
			score += 5.0
		elif effect_id == "gain_attack":
			score += amount * 2.0
		elif effect_id == "increase_max_health":
			score += amount * 1.5
		elif effect_id == "shield":
			score += amount * 1.5
		elif effect_id == "apply_status":
			score += 2.0
		else:
			score += 1.5

	return score


func _score_spell_on_target(effects: Array[Dictionary], target: CardState, player: PlayerState, _gm: GameManager) -> float:
	if target == null:
		return 0.0

	var score := 0.0
	for effect_data in effects:
		if not effect_data is Dictionary:
			continue
		var effect_id := str(effect_data.get("id", ""))
		var amount := int(effect_data.get("amount", 1))

		if effect_id == "damage":
			# 对己方造成伤害是严重错误
			if target.owner_id == player.id:
				score -= 30.0
			else:
				var effective := amount
				if target.has_status("divine_shield"):
					effective = 0
				elif target.shield > 0:
					effective = maxi(amount - target.shield, 0)
				var will_kill := effective >= target.current_health and not target.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION)
				if will_kill:
					score += AICommonScript.calc_threat_score(target) * 1.2 + 10.0
				else:
					score += effective * 2.5

		elif effect_id == "heal":
			# 治疗只对己方有效
			if target.owner_id == player.id:
				var missing := target.max_health - target.current_health
				var effective := mini(amount, missing)
				score += effective * 2.0
				if target.is_hero():
					score += 3.0

		elif effect_id == "shield":
			if target.owner_id == player.id:
				score += amount * 1.5

		elif effect_id == "gain_attack":
			if target.owner_id == player.id:
				score += amount * 2.0 + AICommonScript.calc_threat_score(target) * 0.5

		elif effect_id == "increase_max_health":
			if target.owner_id == player.id:
				score += amount * 1.5

		elif effect_id == "apply_status":
			var status_id := str(effect_data.get("status_id", ""))
			var status_tags := EffectData.get_status_tags(effect_data)
			var status_payload := EffectData.get_status_payload(effect_data)
			var attack_bonus := int(status_payload.get(EffectData.KEY_ATTACK_BONUS, 0))
			var poison_damage := int(status_payload.get(EffectData.KEY_POISON_DAMAGE, 0))
			var poison_turns := int(effect_data.get(EffectData.KEY_STATUS_DURATION_TURNS, 0))
			var is_own := target.owner_id == player.id
			var is_enemy := target.owner_id != "" and target.owner_id != player.id
			var threat: float = AICommonScript.calc_threat_score(target)
			if status_id == "freeze":
				# 冻结敌人 — 好事
				if is_enemy:
					score += threat * 0.6 + 2.0
				elif is_own:
					score -= threat * 0.6 + 2.0
			elif status_id == "divine_shield":
				# 圣盾己方 — 好事；圣盾敌人 — 坏事
				if is_own:
					score += threat * 0.4 + 2.0
				elif is_enemy:
					score -= threat * 0.4 + 2.0
			elif status_id == CardStatus.STATUS_POISON or status_tags.has(CardStatus.TAG_DAMAGE_OVER_TIME):
				var poison_value := float(poison_damage * maxi(poison_turns, 1))
				if is_enemy:
					score += poison_value * 1.8 + threat * 0.35
				elif is_own:
					score -= poison_value * 1.8 + threat * 0.35
			elif status_tags.has(CardStatus.TAG_CONTROL):
				if is_enemy:
					score += threat * 2.0 + 7.0
				elif is_own:
					score -= threat * 2.0 + 7.0
			elif status_tags.has(CardStatus.TAG_DEATH_PREVENTION):
				if is_own:
					var missing_health := target.max_health - target.current_health
					score += threat * 0.55 + float(missing_health) * 0.8 + 3.0
				elif is_enemy:
					score -= threat * 0.45 + 3.0
			elif status_tags.has(CardStatus.TAG_ATTACK_MODIFIER) or attack_bonus != 0:
				if is_own:
					score += float(attack_bonus) * 2.0 + threat * 0.5
				elif is_enemy:
					score -= float(attack_bonus) * 2.0 + threat * 0.5
			elif is_own:
				score += 2.0

		elif effect_id == "resurrect":
			score += 5.0

		else:
			score += 1.5

	return score


func _evaluate_minion_placement(card_data: CardData, player: PlayerState, gm: GameManager, hpr: HandPlayResolver) -> Dictionary:
	var valid_targets: Array = hpr.get_valid_placement_targets(gm)
	if valid_targets.is_empty():
		return {"target": null, "score": 0.0}

	var player_index := gm.players.find(player)
	var best_target = null
	var best_score := 0.0

	for state in valid_targets:
		if state == null:
			continue

		var is_own: bool = _is_slot_in_own_half(state.slot_index, gm.board_columns, player_index)
		var pos_weight: float = AICommonScript.calc_slot_position_weight(state.slot_index, gm.board_columns, is_own)
		var combat_value: float = float(card_data.attack) * 1.5 + float(card_data.health) * 0.5
		var replace_penalty := -2.0 if state.data != null else 0.0

		var score: float = pos_weight * 3.0 + combat_value * 0.8 + replace_penalty
		if score > best_score:
			best_target = state
			best_score = score

	return {"target": best_target, "score": best_score}


func _evaluate_equipment(card_data: CardData, player: PlayerState) -> Dictionary:
	var equipment_type := card_data.equipment_type
	if equipment_type == "":
		equipment_type = card_data.type

	var existing := player.equipped_cards_by_type.get(equipment_type) as CardData
	var score := 2.0

	if card_data.attack > 0:
		score += float(card_data.attack) * 1.5

	for effect_data in card_data.effects:
		if not effect_data is Dictionary:
			continue
		var effect_id := str(effect_data.get("id", ""))
		var amount := int(effect_data.get("amount", 1))
		if effect_id == "modify_spell_power":
			score += float(amount) * 2.0

	if existing != null:
		var old_attack := float(existing.attack)
		var old_sp := 0
		for e in existing.effects:
			if e is Dictionary and str(e.get("id", "")) == "modify_spell_power":
				old_sp = int(e.get("amount", 1))

		var new_attack := float(card_data.attack)
		var new_sp := 0
		for e in card_data.effects:
			if e is Dictionary and str(e.get("id", "")) == "modify_spell_power":
				new_sp = int(e.get("amount", 1))

		var delta: float = (new_attack - old_attack) * 1.5 + float(new_sp - old_sp) * 2.0
		if delta <= 0:
			score = -1.0
		else:
			score = delta

	return {"target": null, "score": score}


func _execute_card(card_data: CardData, hand_index: int, player: PlayerState, target: CardState, gm: GameManager) -> void:
	if gm == null or card_data == null or player == null:
		return

	var hpr := gm.get_hand_play_resolver()
	gm.is_executing_action = true

	if card_data.is_spell():
		await hpr.execute_hand_card(gm, player, card_data, hand_index, target)
	elif card_data.is_minion():
		await hpr.execute_hand_minion_placement(gm, player, card_data, hand_index, target)
	elif card_data.is_equipment():
		await hpr.execute_hand_equipment(gm, player, card_data, hand_index)

	gm.is_executing_action = false
	gm.update_hand_drawer_view()
	gm.update_equipment_display_view()
	gm.refresh_action_available_hints()
	gm.refresh_debug_panel()

	await AICommonScript.await_step_delay(gm)


func _is_slot_in_own_half(slot_index: int, board_columns: int, player_index: int) -> bool:
	var total_rows := 5
	var row: int = slot_index / board_columns
	if player_index == 0:
		return row <= 1
	return row >= total_rows - 2
