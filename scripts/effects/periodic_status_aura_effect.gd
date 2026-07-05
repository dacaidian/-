extends CardEffect
class_name PeriodicStatusAuraEffect

# 通用周期光环效果。
# 用于手牌/装备等持续来源按回合相位给场上单位附加或移除某个状态。


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var player := get_owner_player(source_state, effect_data, game_manager)
	if player == null:
		return

	var runtime_key := get_runtime_key(effect_data)
	if runtime_key == "":
		return

	var cycle_length: int = maxi(int(effect_data.get(EffectData.KEY_CYCLE_LENGTH, 2)), 1)
	var phase := get_current_phase(player, runtime_key)
	if should_advance_phase(effect_data):
		phase = posmod(phase + 1, cycle_length)
	player.set_effect_runtime_value(runtime_key, phase)

	var is_active := get_active_phases(effect_data).has(phase)
	await sync_status(source_state, effect_data, game_manager, player, is_active)


func get_owner_player(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		owner_id = str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if owner_id == "":
		return null

	return game_manager.get_player_by_id(owner_id) as PlayerState


func get_runtime_key(effect_data: Dictionary) -> String:
	var runtime_id := str(effect_data.get(EffectData.KEY_RUNTIME_STATE_ID, ""))
	if runtime_id == "":
		runtime_id = EffectData.get_status_id(effect_data)
	if runtime_id == "":
		return ""

	return "periodic_status_aura:%s" % runtime_id


func get_current_phase(player: PlayerState, runtime_key: String) -> int:
	var raw_value: Variant = player.get_effect_runtime_value(runtime_key, null)
	if raw_value == null:
		return 0

	return maxi(int(raw_value), 0)


func should_advance_phase(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	return trigger != EffectData.TRIGGER_WHILE_IN_HAND and trigger != EffectData.TRIGGER_PASSIVE


func get_active_phases(effect_data: Dictionary) -> Array[int]:
	var phases: Array[int] = []
	var raw_phases: Variant = effect_data.get(EffectData.KEY_ACTIVE_PHASES, [0])
	if raw_phases is Array:
		for raw_phase in raw_phases:
			var phase := maxi(int(raw_phase), 0)
			if not phases.has(phase):
				phases.append(phase)

	if phases.is_empty():
		phases.append(0)

	return phases


func sync_status(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node,
	player: PlayerState,
	is_active: bool
) -> void:
	var status_id := EffectData.get_status_id(effect_data)
	if status_id == "":
		return

	var target_states := get_matching_targets(effect_data, game_manager, player.id)
	for target_state in target_states:
		if target_state == null:
			continue

		var existing_status := target_state.get_status(status_id)
		if not is_active:
			if existing_status != null:
				target_state.remove_status(status_id)
			continue

		if existing_status != null:
			continue

		var runtime_effect_data := effect_data.duplicate(true)
		EffectData.mark_effect_owner(runtime_effect_data, player.id)
		var status := CardStatus.from_effect_data(runtime_effect_data, target_state, source_state)
		target_state.add_status(status)

		var apply_animation := str(runtime_effect_data.get("apply_animation", ""))
		if apply_animation != "" and game_manager != null and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, apply_animation)


func get_matching_targets(effect_data: Dictionary, game_manager: Node, owner_id: String) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null or owner_id == "":
		return targets

	var card_ids := EffectData.get_card_ids(effect_data)
	if card_ids.is_empty():
		return targets

	for value in game_manager.get_all_board_states():
		var state := value as CardState
		if not BoardQuery.is_face_up_minion(state):
			continue
		if state.owner_id != owner_id:
			continue
		if not is_state_in_card_filter(state, card_ids):
			continue

		targets.append(state)

	return targets
