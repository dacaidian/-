extends CardAction
class_name AttackAction

# 普通攻击：默认攻击相邻正面单位，不区分敌我。
# ranged 关键词会扩展目标范围，但只有近战攻击击杀时才触发占领；近战击杀随从或摧毁建筑都可以占领。
const PROFILE_CAN_ATTACK := "can_attack"
const PROFILE_IS_MELEE := "is_melee"
const PROFILE_CAN_OCCUPY := "can_occupy"

func _init() -> void:
	id = "attack"
	display_name = "攻击"
	action_group = CardState.ACTION_GROUP_ATTACK


func can_start(user: CardState, game_manager: GameManager) -> bool:
	if not is_controlled_face_up_minion(user, game_manager):
		return false

	if user.current_attack <= 0 and not user.has_keyword(CardData.KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK):
		return false

	return user.can_attack() and can_pay_action_cost(user)


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.get_all_board_states():
		if get_attack_profile(user, state, game_manager)[PROFILE_CAN_ATTACK]:
			targets.append(state)

	return targets


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	if user == null or target == null or game_manager == null:
		return

	if not can_start(user, game_manager):
		return

	var attack_profile := get_attack_profile(user, target, game_manager)
	if not attack_profile[PROFILE_CAN_ATTACK]:
		return

	if not pay_action_cost(user):
		return

	if not user.spend_attack():
		return

	await perform_attack(
		user,
		target,
		game_manager,
		bool(attack_profile[PROFILE_CAN_OCCUPY])
	)


func perform_attack(
	user: CardState,
	target: CardState,
	game_manager: GameManager,
	can_occupy: bool
) -> bool:
	# Shared normal-attack resolution. Triggered attacks may call this without
	# paying action resources, while still receiving armor, reflection, splash,
	# lifesteal, death attribution and after-attack triggers.
	if (
		user == null
		or target == null
		or game_manager == null
		or not BoardQuery.is_face_up_minion(user)
		or user.is_pending_death
	):
		return false

	var attack_profile := get_attack_profile(user, target, game_manager)
	if not bool(attack_profile[PROFILE_CAN_ATTACK]):
		return false

	var attacker_owner_id := user.owner_id
	var attacker_card_id := user.card_id
	var is_melee_attack := bool(attack_profile[PROFILE_IS_MELEE])
	var next_attack_statuses := get_next_attack_modifier_statuses(user)
	var next_attack_bonus_damage := 0
	var next_attack_heal_amount := 0
	var next_attack_animation := ""
	var next_attack_heal_animation := ""
	for modifier_status in next_attack_statuses:
		var excludes_buildings := bool(modifier_status.payload.get(
			EffectData.KEY_NEXT_ATTACK_EXCLUDES_BUILDINGS,
			false
		))
		if excludes_buildings and target.is_building():
			continue
		next_attack_bonus_damage += int(modifier_status.payload.get(
			EffectData.KEY_NEXT_ATTACK_BONUS_DAMAGE,
			0
		))
		next_attack_heal_amount += int(modifier_status.payload.get(
			EffectData.KEY_NEXT_ATTACK_HEAL,
			0
		))
		if next_attack_animation == "":
			next_attack_animation = str(modifier_status.payload.get(
				EffectData.KEY_TRIGGER_ANIMATION,
				""
			))
		if next_attack_heal_animation == "":
			next_attack_heal_animation = str(modifier_status.payload.get(
				EffectData.KEY_LIFESTEAL_ANIMATION,
				""
			))
	await game_manager.play_card_attack_animation(user, target, is_melee_attack)
	for modifier_status in next_attack_statuses:
		user.remove_status_instance(modifier_status)
	if next_attack_animation != "":
		await game_manager.play_spell_cast_animation(
			user,
			target,
			{EffectData.KEY_ANIMATION: next_attack_animation}
		)
	var attack_damage := calculate_attack_damage(user, target) + next_attack_bonus_damage
	if is_ranged_attack_immune(target, is_melee_attack):
		attack_damage = 0
	var was_reflected := await resolve_attack_reflection(user, target, attack_damage, game_manager)
	var secondary_damage_targets: Array[CardState] = []
	var actual_life_damage := 0
	if not was_reflected:
		actual_life_damage = deal_attack_damage_to_target(target, apply_armor_to_attack_damage(target, attack_damage))
		await resolve_lifesteal(user, target, actual_life_damage, game_manager)
		secondary_damage_targets = apply_secondary_attack_damage(user, target, game_manager, is_melee_attack)
	if next_attack_heal_amount > 0:
		await resolve_fixed_attack_heal(
			user,
			next_attack_heal_amount,
			game_manager,
			next_attack_heal_animation
		)
	if not secondary_damage_targets.is_empty():
		# Play the shared area-impact presentation while source and primary target
		# still have stable board nodes. Death resolution remains authoritative and
		# runs only after the purely visual context has been consumed.
		await game_manager.play_secondary_attack_impact_animation(
			user,
			target,
			secondary_damage_targets
		)
	if target.current_health <= 0:
		await game_manager.resolve_attack_kill(user, target, can_occupy)
	var resolved_attacker := user
	if resolved_attacker.is_empty() or resolved_attacker.card_id != attacker_card_id:
		resolved_attacker = game_manager.find_face_up_board_state(attacker_owner_id, attacker_card_id)
	if not secondary_damage_targets.is_empty():
		await game_manager.resolve_dead_states(
			secondary_damage_targets,
			EffectData.DEATH_REASON_ATTACK,
			resolved_attacker,
			attacker_owner_id
		)

	break_attack_or_spell_stealth(resolved_attacker)
	var trigger_source := resolved_attacker
	if trigger_source != null:
		await game_manager.resolve_after_attack_triggers(trigger_source, target)
	return true


func resolve_fixed_attack_heal(
	user: CardState,
	heal_amount: int,
	game_manager: GameManager,
	animation_key := ""
) -> void:
	if (
		user == null
		or game_manager == null
		or heal_amount <= 0
		or not BoardQuery.is_face_up_minion(user)
		or user.is_pending_death
	):
		return

	var healed_amount := user.heal(heal_amount)
	if healed_amount <= 0:
		return
	if animation_key != "":
		await game_manager.play_status_apply_animation(user, animation_key)
	game_manager.queue_card_trigger(user, EventContext.TRIGGER_ON_EFFECTIVE_HEAL, {
		EventContext.EFFECTIVE_HEAL_AMOUNT: healed_amount,
		EventContext.SOURCE_STATE: user
	})
	await game_manager.resolve_queued_triggers()


func get_next_attack_modifier_statuses(user: CardState) -> Array[CardStatus]:
	var modifier_statuses: Array[CardStatus] = []
	if user == null:
		return modifier_statuses
	for status in user.statuses:
		if status != null and status.tags.has(CardStatus.TAG_NEXT_ATTACK_MODIFIER):
			modifier_statuses.append(status)
	return modifier_statuses


func resolve_attack_reflection(
	attacker: CardState,
	defender: CardState,
	damage: int,
	game_manager: GameManager
) -> bool:
	if attacker == null or defender == null or game_manager == null:
		return false
	if damage <= 0:
		return false
	var reflect_animation := get_status_animation(
		defender,
		EffectData.KEY_REFLECT_ANIMATION,
		"bronze_head_iron_arms_reflect"
	)
	if not defender.trigger_attack_reflection():
		return false

	if game_manager.has_method("play_status_apply_animation"):
		if reflect_animation in ["koukaku_reflect", "bronze_head_iron_arms_reflect"]:
			await game_manager.play_spell_cast_animation(
				defender,
				attacker,
				{EffectData.KEY_ANIMATION: reflect_animation}
			)
		else:
			await game_manager.play_status_apply_animation(defender, reflect_animation)
	attacker.take_damage(damage)
	await game_manager.resolve_dead_states([attacker], EffectData.DEATH_REASON_EFFECT, defender)
	return true


func resolve_bronze_head_iron_arms(
	attacker: CardState,
	defender: CardState,
	damage: int,
	game_manager: GameManager
) -> bool:
	return await resolve_attack_reflection(attacker, defender, damage, game_manager)


func can_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	return bool(get_attack_profile(user, target, game_manager)[PROFILE_CAN_ATTACK])


func calculate_attack_damage(user: CardState, target: CardState) -> int:
	if user == null:
		return 0

	var damage := user.current_attack
	if user.has_keyword(CardData.KEYWORD_CRITICAL):
		damage *= 2
	if target != null and target.is_building():
		damage += user.get_siege_bonus()

	return maxi(damage, 0)


func apply_secondary_attack_damage(
	user: CardState,
	target: CardState,
	game_manager: GameManager,
	is_melee_attack := true
) -> Array[CardState]:
	var damaged_targets: Array[CardState] = []
	append_unique_states(damaged_targets, apply_frontal_attack_damage(user, target, game_manager, is_melee_attack))
	append_unique_states(damaged_targets, apply_fixed_splash_damage(user, target, game_manager, is_melee_attack))
	return damaged_targets


func append_unique_states(targets: Array[CardState], additions: Array[CardState]) -> void:
	for state in additions:
		if state != null and not targets.has(state):
			targets.append(state)


func apply_giant_splash_damage(user: CardState, target: CardState, game_manager: GameManager) -> Array[CardState]:
	if user == null or not user.has_keyword(CardData.KEYWORD_GIANT):
		var empty_targets: Array[CardState] = []
		return empty_targets
	return apply_frontal_attack_damage(user, target, game_manager, true, 3)


func apply_frontal_attack_damage(
	user: CardState,
	target: CardState,
	game_manager: GameManager,
	is_melee_attack := true,
	width_override := 0
) -> Array[CardState]:
	var damaged_targets: Array[CardState] = []
	if user == null or target == null or game_manager == null:
		return damaged_targets
	var width := width_override if width_override > 0 else user.get_frontal_attack_width()
	if width <= 0:
		return damaged_targets

	for slot_index in get_frontal_attack_slots(
		user.slot_index,
		target.slot_index,
		width,
		game_manager.board_columns,
		game_manager.board_states.size()
	):
		for splash_target in game_manager.get_board_states_at_slot(slot_index):
			if splash_target == target:
				continue
			if not can_secondary_attack_damage_target(user, splash_target):
				continue
			if is_ranged_attack_immune(splash_target, is_melee_attack):
				continue

			var splash_damage := apply_armor_to_attack_damage(splash_target, calculate_attack_damage(user, splash_target))
			splash_target.take_damage(splash_damage)
			damaged_targets.append(splash_target)

	return damaged_targets


func apply_fixed_splash_damage(
	user: CardState,
	target: CardState,
	game_manager: GameManager,
	is_melee_attack := true
) -> Array[CardState]:
	var damaged_targets: Array[CardState] = []
	if user == null or target == null or game_manager == null:
		return damaged_targets

	var splash_damage := user.get_splash_damage()
	if splash_damage <= 0:
		return damaged_targets

	var adjacent_slots := BoardQuery.get_adjacent_slots(
		target.slot_index,
		game_manager.board_columns,
		game_manager.board_states.size()
	)
	for slot_index in adjacent_slots:
		# 格子邻接与单位层无关：每个相邻格的地面层和飞行层都会被检查。
		for splash_target in game_manager.get_board_states_at_slot(slot_index):
			if not can_secondary_attack_damage_target(user, splash_target):
				continue
			if is_ranged_attack_immune(splash_target, is_melee_attack):
				continue

			splash_target.take_damage(apply_armor_to_attack_damage(splash_target, splash_damage))
			damaged_targets.append(splash_target)

	return damaged_targets


func deal_attack_damage_to_target(target: CardState, damage: int) -> int:
	if target == null or damage <= 0:
		return 0

	var previous_health := target.current_health
	target.take_damage(damage)
	return maxi(previous_health - target.current_health, 0)


func resolve_lifesteal(
	user: CardState,
	target: CardState,
	actual_life_damage: int,
	game_manager: GameManager
) -> void:
	if user == null or game_manager == null:
		return
	if actual_life_damage <= 0:
		return
	if not user.has_keyword(CardData.KEYWORD_LIFESTEAL):
		return

	var healed_amount := user.heal(actual_life_damage)
	if healed_amount <= 0:
		return

	var lifesteal_animation := get_status_animation(
		user,
		EffectData.KEY_LIFESTEAL_ANIMATION,
		""
	)
	if lifesteal_animation != "" and target != null:
		await game_manager.play_spell_cast_animation(
			target,
			user,
			{EffectData.KEY_ANIMATION: lifesteal_animation}
		)
	elif game_manager.has_method("play_effect_heal_animation"):
		await game_manager.play_effect_heal_animation(user)

	if game_manager.has_method("queue_card_trigger"):
		game_manager.queue_card_trigger(user, EventContext.TRIGGER_ON_EFFECTIVE_HEAL, {
			EventContext.EFFECTIVE_HEAL_AMOUNT: healed_amount,
			EventContext.SOURCE_STATE: user
		})
	if game_manager.has_method("resolve_queued_triggers"):
		await game_manager.resolve_queued_triggers()


func get_status_animation(state: CardState, payload_key: String, fallback: String) -> String:
	if state == null or payload_key == "":
		return fallback
	for status in state.statuses:
		if status == null:
			continue
		var animation_key := str(status.payload.get(payload_key, ""))
		if animation_key != "":
			return animation_key
	return fallback


func get_giant_splash_slots(attacker_slot: int, target_slot: int, board_columns: int, board_size: int) -> Array[int]:
	return get_frontal_attack_slots(attacker_slot, target_slot, 3, board_columns, board_size)


func get_frontal_attack_slots(
	attacker_slot: int,
	target_slot: int,
	width: int,
	board_columns: int,
	board_size: int
) -> Array[int]:
	var slots: Array[int] = []
	if attacker_slot == target_slot or board_columns <= 0 or board_size <= 0 or width <= 0:
		return slots
	var normalized_width := width if width % 2 == 1 else width - 1
	if normalized_width <= 0:
		return slots

	var attacker_row: int = floori(float(attacker_slot) / float(board_columns))
	var attacker_col: int = attacker_slot % board_columns
	var target_row: int = floori(float(target_slot) / float(board_columns))
	var target_col: int = target_slot % board_columns
	var row_delta: int = clampi(target_row - attacker_row, -1, 1)
	var col_delta: int = clampi(target_col - attacker_col, -1, 1)
	if row_delta == 0 and col_delta == 0:
		return slots

	var offsets: Array[Vector2i] = [Vector2i(row_delta, col_delta)]
	var radius := floori(float(normalized_width) / 2.0)
	if row_delta != 0 and col_delta != 0:
		for step in range(1, radius + 1):
			offsets.append(Vector2i(row_delta * step, 0))
			offsets.append(Vector2i(0, col_delta * step))
	elif row_delta != 0:
		for step in range(1, radius + 1):
			offsets.append(Vector2i(row_delta, -step))
			offsets.append(Vector2i(row_delta, step))
	elif col_delta != 0:
		for step in range(1, radius + 1):
			offsets.append(Vector2i(-step, col_delta))
			offsets.append(Vector2i(step, col_delta))

	for offset in offsets:
		var slot := get_slot_by_offset(attacker_row, attacker_col, offset, board_columns, board_size)
		if slot >= 0 and not slots.has(slot):
			slots.append(slot)

	return slots


func get_slot_by_offset(row: int, col: int, offset: Vector2i, board_columns: int, board_size: int) -> int:
	var board_rows: int = int(ceil(float(board_size) / float(board_columns)))
	var target_row := row + offset.x
	var target_col := col + offset.y
	if target_row < 0 or target_row >= board_rows:
		return -1
	if target_col < 0 or target_col >= board_columns:
		return -1

	var slot := target_row * board_columns + target_col
	return slot if slot >= 0 and slot < board_size else -1


func can_secondary_attack_damage_target(user: CardState, target: CardState) -> bool:
	if user == null or target == null or target == user:
		return false
	if not BoardQuery.is_face_up_unit(target):
		return false
	if target.owner_id == user.owner_id and target.owner_id != "":
		return false

	return true


func is_ranged_attack_immune(target: CardState, is_melee_attack: bool) -> bool:
	return (
		target != null
		and not is_melee_attack
		and target.has_keyword(CardData.KEYWORD_RANGED_ATTACK_IMMUNE)
	)


func apply_armor_to_attack_damage(target: CardState, damage: int) -> int:
	if target == null or damage <= 0:
		return maxi(damage, 0)

	return maxi(damage - target.armor, 0)


func get_attack_profile(user: CardState, target: CardState, game_manager: GameManager) -> Dictionary:
	var profile := {
		PROFILE_CAN_ATTACK: false,
		PROFILE_IS_MELEE: false,
		PROFILE_CAN_OCCUPY: false
	}

	if game_manager == null:
		return profile

	if not is_attackable_unit_target(user, target):
		return profile

	if is_blocked_by_enemy_taunt(user, target, game_manager):
		return profile

	if is_melee_attack_target(user, target, game_manager.board_columns):
		profile[PROFILE_CAN_ATTACK] = true
		profile[PROFILE_IS_MELEE] = true
		profile[PROFILE_CAN_OCCUPY] = target.is_unit() and not user.is_flying()
		return profile

	if target.has_keyword(CardData.KEYWORD_RANGED_ATTACK_IMMUNE):
		return profile

	if is_ranged_attack_target(user, target, game_manager):
		profile[PROFILE_CAN_ATTACK] = true

	return profile


func is_attackable_unit_target(user: CardState, target: CardState) -> bool:
	if user == null or target == null:
		return false

	if user == target:
		return false

	if not BoardQuery.is_face_up_unit(target):
		return false

	if target.is_stealthed_from_player(user.owner_id):
		return false

	return true


func is_blocked_by_enemy_taunt(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false
	if user.owner_id == "":
		return false
	if target.owner_id == "":
		return false
	if target.owner_id == user.owner_id:
		return false
	if target.has_keyword(CardData.KEYWORD_TAUNT):
		return false

	return has_visible_enemy_taunt_minion(user, game_manager)


func has_visible_enemy_taunt_minion(user: CardState, game_manager: GameManager) -> bool:
	if user == null or game_manager == null or user.owner_id == "":
		return false

	for state in game_manager.get_all_board_states():
		if state == null or state == user:
			continue
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id == "" or state.owner_id == user.owner_id:
			continue
		if state.is_stealthed_from_player(user.owner_id):
			continue
		if state.has_keyword(CardData.KEYWORD_TAUNT):
			return true

	return false


func is_melee_attack_target(user: CardState, target: CardState, board_columns: int) -> bool:
	if user == null or target == null or board_columns <= 0:
		return false

	if user.slot_index == target.slot_index:
		return user != target

	return is_neighbor(user.slot_index, target.slot_index, board_columns)


func is_ranged_attack_target(user: CardState, target: CardState, game_manager: GameManager) -> bool:
	if user == null or target == null or game_manager == null:
		return false

	if not user.has_keyword(CardData.KEYWORD_RANGED):
		return false

	for anchor_state in game_manager.get_all_board_states():
		if not is_ranged_anchor(user, anchor_state):
			continue

		if target == anchor_state:
			return true

		if is_neighbor(anchor_state.slot_index, target.slot_index, game_manager.board_columns):
			return true

	return false


func is_ranged_anchor(user: CardState, anchor_state: CardState) -> bool:
	if user == null or anchor_state == null:
		return false

	if not BoardQuery.is_face_up_minion(anchor_state):
		return false

	return anchor_state.owner_id != "" and anchor_state.owner_id == user.owner_id


func break_attack_or_spell_stealth(user: CardState) -> void:
	if user == null:
		return

	user.remove_statuses_with_tag(CardStatus.TAG_BREAKS_ON_ATTACK_OR_SPELL)
