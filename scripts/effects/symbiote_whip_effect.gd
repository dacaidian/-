extends CardEffect
class_name SymbioteWhipEffect

const KEY_ENEMY_DAMAGE := "enemy_damage"
const KEY_FRIENDLY_DAMAGE := "friendly_damage"
const KEY_FRIENDLY_ATTACK_BONUS := "friendly_attack_bonus"


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var target_state := EffectData.get_selected_target_state(effect_data)
	if not can_whip_target(source_state, target_state):
		return

	var is_friendly := target_state.owner_id == source_state.owner_id
	var damage := int(effect_data.get(
		KEY_FRIENDLY_DAMAGE if is_friendly else KEY_ENEMY_DAMAGE,
		0
	))
	target_state.take_damage(maxi(damage, 0))
	if game_manager != null and game_manager.has_method("resolve_dead_states"):
		await game_manager.resolve_dead_states(
			[target_state],
			EffectData.get_death_reason(effect_data, EffectData.DEATH_REASON_SPELL),
			source_state,
			get_effect_owner_id(source_state, effect_data)
		)

	if (
		is_friendly
		and BoardQuery.is_face_up_minion(target_state)
		and not target_state.is_pending_death
	):
		target_state.set_current_attack(
			target_state.current_attack + maxi(int(effect_data.get(KEY_FRIENDLY_ATTACK_BONUS, 0)), 0)
		)


func can_execute(source_state: CardState, effect_data: Dictionary, _game_manager: Node) -> bool:
	return can_whip_target(source_state, EffectData.get_selected_target_state(effect_data))


func can_whip_target(source_state: CardState, target_state: CardState) -> bool:
	return (
		source_state != null
		and target_state != null
		and BoardQuery.is_face_up_minion(target_state)
		and not target_state.is_hero()
		and source_state.owner_id != ""
		and target_state.owner_id != ""
	)
