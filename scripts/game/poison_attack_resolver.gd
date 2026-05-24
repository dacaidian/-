extends RefCounted
class_name PoisonAttackResolver

# Resolves whether a unit currently has a poison-on-attack package.
# The source can be printed card effects, upgrade-granted after_attack effects,
# or status payload trigger effects such as devour inheritance.

const POISON_DAMAGE_PER_TURN := "damage_per_turn"
const POISON_DURATION_TURNS := "duration_turns"
const POISON_TOTAL_DAMAGE := "total_damage"
const POISON_LEVEL := "level"

var granted_unit_trigger_resolver := GrantedUnitTriggerResolver.new()


func get_poison_attack_package(source_state: CardState, game_manager: GameManager) -> Dictionary:
	if source_state == null or source_state.data == null or game_manager == null:
		return {}

	var best_package: Dictionary = {}
	merge_best_package(best_package, get_best_package_from_effects(source_state.data.effects))

	var owner := game_manager.get_player_by_id(source_state.owner_id) as PlayerState
	for grant_data in granted_unit_trigger_resolver.get_grants_for_source(
		owner,
		source_state,
		EventContext.TRIGGER_AFTER_ATTACK
	):
		merge_best_package(best_package, get_best_package_from_effects(EffectData.get_granted_effects(grant_data)))

	for status in source_state.statuses:
		if status == null:
			continue
		merge_best_package(
			best_package,
			get_best_package_from_effects(EffectData.get_status_trigger_effects(status, EventContext.TRIGGER_AFTER_ATTACK))
		)

	return best_package


func get_best_package_from_effects(effects: Array) -> Dictionary:
	var best_package: Dictionary = {}
	for effect_data in effects:
		if not effect_data is Dictionary:
			continue

		if EffectData.get_id(effect_data) != EffectData.EFFECT_APPLY_STATUS:
			continue
		if EffectData.get_status_id(effect_data) != CardStatus.STATUS_POISON:
			continue

		var package := create_package_from_poison_effect(effect_data)
		merge_best_package(best_package, package)

	return best_package


func create_package_from_poison_effect(effect_data: Dictionary) -> Dictionary:
	var payload := EffectData.get_status_payload(effect_data)
	var damage_per_turn := int(payload.get(EffectData.KEY_POISON_DAMAGE, 0))
	var duration_turns := maxi(EffectData.get_status_duration_turns(effect_data), 0)
	var total_damage := damage_per_turn * duration_turns
	if total_damage <= 0:
		return {}

	return {
		POISON_DAMAGE_PER_TURN: damage_per_turn,
		POISON_DURATION_TURNS: duration_turns,
		POISON_TOTAL_DAMAGE: total_damage,
		POISON_LEVEL: int(payload.get(EffectData.KEY_POISON_ATTACK_LEVEL, damage_per_turn))
	}


func merge_best_package(best_package: Dictionary, candidate: Dictionary) -> void:
	if candidate.is_empty():
		return

	var candidate_total := int(candidate.get(POISON_TOTAL_DAMAGE, 0))
	var best_total := int(best_package.get(POISON_TOTAL_DAMAGE, 0))
	if candidate_total <= best_total:
		return

	best_package.clear()
	for key in candidate:
		best_package[key] = candidate[key]
