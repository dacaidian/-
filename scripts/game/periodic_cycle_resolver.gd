extends RefCounted
class_name PeriodicCycleResolver

# Shared cycle phase helper for periodic effects.
# It only owns phase bookkeeping; concrete effects decide what to do when active.


func get_runtime_key(effect_data: Dictionary, default_prefix: String, fallback_id := "") -> String:
	var runtime_id := str(effect_data.get(EffectData.KEY_RUNTIME_STATE_ID, ""))
	if runtime_id == "":
		runtime_id = fallback_id
	if runtime_id == "":
		runtime_id = EffectData.get_status_id(effect_data)
	if runtime_id == "":
		return ""

	return "%s:%s" % [default_prefix, runtime_id]


func resolve_cycle(player: PlayerState, effect_data: Dictionary, runtime_key: String) -> Dictionary:
	if player == null or runtime_key == "":
		return {
			"phase": 0,
			"is_active": false
		}

	var cycle_length: int = maxi(int(effect_data.get(EffectData.KEY_CYCLE_LENGTH, 2)), 1)
	var phase := get_current_phase(player, runtime_key)
	if bool(effect_data.get(EffectData.KEY_RESET_PHASE, false)):
		phase = 0
	if should_advance_phase(effect_data):
		phase = posmod(phase + 1, cycle_length)

	player.set_effect_runtime_value(runtime_key, phase)
	return {
		"phase": phase,
		"is_active": get_active_phases(effect_data).has(phase)
	}


func get_current_phase(player: PlayerState, runtime_key: String) -> int:
	var raw_value: Variant = player.get_effect_runtime_value(runtime_key, null)
	if raw_value == null:
		return 0

	return maxi(int(raw_value), 0)


func should_advance_phase(effect_data: Dictionary) -> bool:
	if effect_data.has(EffectData.KEY_ADVANCE_PHASE):
		return bool(effect_data.get(EffectData.KEY_ADVANCE_PHASE))

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
