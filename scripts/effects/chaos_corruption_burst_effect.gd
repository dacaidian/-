extends CardEffect
class_name ChaosCorruptionBurstEffect

# 野兽人混沌腐蚀结算：
# 己方回合结束时统计场上己方随从的混沌腐蚀总数，每 threshold 点转化为一次群体伤害。

const DEFAULT_THRESHOLD := 10
const DEFAULT_DAMAGE_PER_THRESHOLD := 1


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null or not game_manager.has_method("get_all_board_states"):
		return

	var owner_id := str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if owner_id == "":
		owner_id = get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		return

	var threshold := maxi(int(effect_data.get(EffectData.KEY_THRESHOLD, DEFAULT_THRESHOLD)), 1)
	var damage_per_threshold := maxi(int(effect_data.get(EffectData.KEY_DAMAGE_PER_THRESHOLD, DEFAULT_DAMAGE_PER_THRESHOLD)), 0)
	if damage_per_threshold <= 0:
		return

	var total_corruption := get_total_friendly_corruption(game_manager, owner_id)
	var damage := int(total_corruption / threshold) * damage_per_threshold
	if damage <= 0:
		return

	var damaged_targets: Array[CardState] = []
	for target_state in get_enemy_minions(game_manager, owner_id):
		target_state.take_damage(damage)
		damaged_targets.append(target_state)

	if damaged_targets.is_empty():
		return

	if game_manager.has_method("resolve_dead_states"):
		var death_reason := EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_EFFECT)
		game_manager.resolve_dead_states(damaged_targets, death_reason, source_state)


func get_total_friendly_corruption(game_manager: Node, owner_id: String) -> int:
	var total := 0
	for value in game_manager.get_all_board_states():
		var state := value as CardState
		if not is_counted_friendly_minion(state, owner_id):
			continue

		total += maxi(state.chaos_corruption, 0)

	return total


func get_enemy_minions(game_manager: Node, owner_id: String) -> Array[CardState]:
	var targets: Array[CardState] = []
	for value in game_manager.get_all_board_states():
		var state := value as CardState
		if state == null or state.is_empty() or not state.is_face_up:
			continue
		if state.owner_id == "" or state.owner_id == owner_id:
			continue
		if not state.is_minion():
			continue

		targets.append(state)

	return targets


func is_counted_friendly_minion(state: CardState, owner_id: String) -> bool:
	return (
		state != null
		and not state.is_empty()
		and state.is_face_up
		and state.owner_id == owner_id
		and state.is_minion()
	)
