extends CardEffect
class_name CarnageKillProgressEffect

const COUNTER_KEY := "carnage_enemy_minion_kills"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if not can_execute(source_state, effect_data, game_manager):
		return

	var threshold := maxi(int(effect_data.get(EffectData.KEY_THRESHOLD, 2)), 1)
	var kill_count := source_state.increment_runtime_counter(COUNTER_KEY)
	var escalation_count := 0
	while kill_count >= threshold:
		kill_count -= threshold
		source_state.add_permanent_attack_speed(1)
		escalation_count += 1
	source_state.set_runtime_counter(COUNTER_KEY, kill_count)
	if (
		escalation_count > 0
		and game_manager != null
		and game_manager.has_method("play_status_apply_animation")
	):
		await game_manager.play_status_apply_animation(
			source_state,
			"symbiote_carnage_escalation"
		)


func can_execute(source_state: CardState, effect_data: Dictionary, _game_manager: Node) -> bool:
	if source_state == null or source_state.is_empty() or source_state.is_pending_death:
		return false
	var defeated_state := effect_data.get(EventContext.DEAD_STATE) as CardState
	return (
		defeated_state != null
		and defeated_state.is_minion()
		and not defeated_state.is_hero()
		and source_state.owner_id != ""
		and defeated_state.owner_id != ""
		and source_state.owner_id != defeated_state.owner_id
	)
