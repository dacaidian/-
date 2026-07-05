extends CardEffect
class_name PeriodicTriggerEffect

const PeriodicCycleResolverScript := preload("res://scripts/game/periodic_cycle_resolver.gd")

var periodic_cycle_resolver := PeriodicCycleResolverScript.new()

# Generic periodic trigger effect.
# It shares phase bookkeeping with PeriodicStatusAuraEffect, then executes child effects when active.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if game_manager == null:
		return
	if not is_trigger_player_matched(source_state, effect_data):
		return

	var player := get_owner_player(source_state, effect_data, game_manager)
	if player == null:
		return

	var runtime_key := periodic_cycle_resolver.get_runtime_key(effect_data, "periodic_trigger", get_fallback_runtime_id(source_state))
	if runtime_key == "":
		return

	var cycle_result := periodic_cycle_resolver.resolve_cycle(player, effect_data, runtime_key)
	if not bool(cycle_result.get("is_active", false)):
		return

	var animation_key := str(effect_data.get("animation", ""))
	if animation_key != "" and source_state != null and game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(source_state, animation_key)

	for child_effect in get_child_effects(effect_data):
		var runtime_effect_data := child_effect.duplicate(true)
		EffectData.mark_effect_owner(runtime_effect_data, player.id)
		await game_manager.effect_registry.execute_effect(source_state, runtime_effect_data, game_manager)


func can_execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> bool:
	if game_manager == null:
		return false
	if not is_trigger_player_matched(source_state, effect_data):
		return false

	return not get_child_effects(effect_data).is_empty()


func get_owner_player(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> PlayerState:
	if game_manager == null or not game_manager.has_method("get_player_by_id"):
		return null

	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id == "":
		owner_id = str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if owner_id == "":
		return null

	return game_manager.get_player_by_id(owner_id) as PlayerState


func is_trigger_player_matched(source_state: CardState, effect_data: Dictionary) -> bool:
	var trigger_player_id := str(effect_data.get(EventContext.TURN_PLAYER_ID, ""))
	if trigger_player_id == "":
		return true

	match EffectData.get_trigger_player(effect_data):
		EffectData.TRIGGER_PLAYER_SOURCE_OWNER:
			return source_state != null and source_state.owner_id == trigger_player_id
		_:
			return true


func get_child_effects(effect_data: Dictionary) -> Array[Dictionary]:
	var child_effects: Array[Dictionary] = []
	var raw_effects: Variant = effect_data.get(EffectData.KEY_EFFECTS, [])
	if raw_effects is Array:
		for child_effect in raw_effects:
			if child_effect is Dictionary:
				child_effects.append(child_effect)

	return child_effects


func get_fallback_runtime_id(source_state: CardState) -> String:
	if source_state == null:
		return ""

	return source_state.card_id
