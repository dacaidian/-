extends CardEffect
class_name LinkUnitsEffect

const BoardUnitPairSelectionControllerScript := preload("res://scripts/game/board_unit_pair_selection_controller.gd")

# Injects two face-up minions with child/mother gu larvae. The larvae mature at
# the caster's next turn start; only the mature life_link status destroys the
# linked partner. Each cast creates a unique link id, so independent pairs do not
# affect one another.


func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var gm := game_manager as GameManager
	if gm == null:
		return

	var candidates := get_linkable_minions(gm)
	if candidates.size() < 2:
		return

	var owner_id := get_link_owner_id(source_state, effect_data, gm)
	var pair: Array[CardState] = []
	var owner := gm.get_player_by_id(owner_id) as PlayerState
	if owner != null and owner.is_ai:
		pair = choose_ai_pair(candidates, owner.id)
	else:
		var controller := BoardUnitPairSelectionControllerScript.new() as BoardUnitPairSelectionController
		pair = await controller.select_unit_pair(
			gm,
			candidates,
			EffectData.get_selection_title(effect_data, "选择两个随从注入子母蛊")
		)

	if pair.size() < 2:
		return

	var first_state := pair[0]
	var second_state := pair[1]
	if first_state == null or second_state == null or first_state == second_state:
		return
	if not is_linkable_state(first_state) or not is_linkable_state(second_state):
		return

	if gm.has_method("play_link_units_animation"):
		await gm.play_link_units_animation(
			first_state,
			second_state,
			str(effect_data.get("larva_animation", effect_data.get("animation", "gu_life_link_larva")))
		)

	var link_id := create_link_id(owner_id, first_state, second_state)
	apply_life_link_larva_status(first_state, second_state, link_id, owner_id, effect_data)
	apply_life_link_larva_status(second_state, first_state, link_id, owner_id, effect_data)


func can_execute(_source_state: CardState, _effect_data: Dictionary, game_manager: Node) -> bool:
	var gm := game_manager as GameManager
	return gm != null and get_linkable_minions(gm).size() >= 2


func get_linkable_minions(gm: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	for state in gm.get_all_board_states():
		if is_linkable_state(state):
			targets.append(state)

	return targets


func is_linkable_state(state: CardState) -> bool:
	return (
		state != null
		and not state.is_pending_death
		and BoardQuery.is_face_up_minion(state)
		and SpellTargetResolver.can_spell_affect(state)
	)


func get_link_owner_id(source_state: CardState, effect_data: Dictionary, gm: GameManager) -> String:
	var owner_id := get_effect_owner_id(source_state, effect_data)
	if owner_id != "":
		return owner_id

	var current_player := gm.get_current_player() as PlayerState
	return current_player.id if current_player != null else ""


func choose_ai_pair(candidates: Array[CardState], owner_id: String) -> Array[CardState]:
	var enemies: Array[CardState] = []
	var fallback: Array[CardState] = []
	for state in candidates:
		if state == null:
			continue
		if state.owner_id != "" and state.owner_id != owner_id:
			enemies.append(state)
		fallback.append(state)

	var pool := enemies if enemies.size() >= 2 else fallback
	pool.sort_custom(func(first: CardState, second: CardState) -> bool:
		return get_unit_value(first) > get_unit_value(second)
	)

	var result: Array[CardState] = []
	if pool.size() >= 2:
		result.append(pool[0])
		result.append(pool[1])
	return result


func get_unit_value(state: CardState) -> float:
	if state == null:
		return 0.0

	return float(state.current_attack) * 2.0 + float(state.max_health) + (4.0 if state.is_hero() else 0.0)


func create_link_id(owner_id: String, first_state: CardState, second_state: CardState) -> String:
	return "%s:%d:%d:%d" % [owner_id, Time.get_ticks_usec(), first_state.slot_index, second_state.slot_index]


func apply_life_link_larva_status(
	target_state: CardState,
	linked_state: CardState,
	link_id: String,
	owner_id: String,
	effect_data: Dictionary
) -> void:
	var status := CardStatus.new()
	status.status_id = CardStatus.STATUS_LIFE_LINK_LARVA
	status.display_name = "子母蛊幼虫"
	status.description = "蛊虫正在成长，施术者下个回合开始时成熟为同命蛊。"
	status.stacks = 1
	status.stack_policy = CardStatus.STACK_POLICY_STACK
	status.is_permanent = true
	status.remaining_turns = -1
	status.source_card_id = "life_link_larva:%s" % link_id
	status.source_owner_id = owner_id
	status.duration_scope = CardStatus.DURATION_SCOPE_SOURCE_OWNER
	status.duration_owner_id = owner_id
	status.valence = EffectData.STATUS_VALENCE_NEGATIVE
	status.payload = {
		EffectData.KEY_LINK_ID: link_id,
		"linked_card_id": linked_state.card_id,
		"linked_display_name": linked_state.display_name,
		"mature_on_owner_id": owner_id,
		"mature_animation": str(effect_data.get("mature_animation", "gu_life_link")),
		"death_animation": str(effect_data.get("death_animation", "gu_life_link_death"))
	}
	target_state.add_status(status)


func apply_life_link_status(target_state: CardState, linked_state: CardState, link_id: String, owner_id: String) -> void:
	var status := CardStatus.new()
	status.status_id = CardStatus.STATUS_LIFE_LINK
	status.display_name = "同命蛊"
	status.description = "与另一个随从相连，其中一个死亡时另一个也会死亡。"
	status.tags = [CardStatus.TAG_DEATH_LINK]
	status.stacks = 1
	status.stack_policy = CardStatus.STACK_POLICY_STACK
	status.is_permanent = true
	status.remaining_turns = -1
	status.source_card_id = "life_link:%s" % link_id
	status.source_owner_id = owner_id
	status.duration_owner_id = target_state.owner_id
	status.payload = {
		EffectData.KEY_LINK_ID: link_id,
		"linked_card_id": linked_state.card_id,
		"linked_display_name": linked_state.display_name,
		EffectData.KEY_STATUS_TRIGGER_EFFECTS: [
			{
				EffectData.KEY_ID: EffectData.EFFECT_DESTROY_LINKED_UNITS,
				EffectData.KEY_TRIGGER: EventContext.TRIGGER_ON_DESTROYED,
				EffectData.KEY_ANIMATION: "gu_life_link_death"
			}
		]
	}
	target_state.add_status(status)
