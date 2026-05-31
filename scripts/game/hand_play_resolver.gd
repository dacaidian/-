extends RefCounted
class_name HandPlayResolver

# HandPlayResolver 负责手牌使用规则。
# 当前只实现手牌法术；它复用 InteractionManager 的目标选择模式和 EffectRegistry。

const HandSpellModifierResolverScript := preload("res://scripts/game/hand_spell_modifier_resolver.gd")

const HAND_CAST_ACTION_ID := "hand:cast"
const HAND_PLACE_ACTION_ID := "hand:place"
const HAND_EQUIP_ACTION_ID := "hand:equip"

var hand_spell_modifier_resolver := HandSpellModifierResolverScript.new()


func can_play_hand_card(player: PlayerState, card_data: CardData, game_manager: GameManager = null) -> bool:
	if player == null or card_data == null:
		return false

	if player.find_hand_card_index(card_data) < 0:
		return false

	if not is_required_hero_on_board(player, card_data, game_manager):
		return false

	if card_data.is_spell():
		return not card_data.effects.is_empty() and has_playable_effects(player, card_data, game_manager)

	if card_data.is_minion():
		return not get_valid_placement_targets(game_manager, card_data).is_empty()

	if card_data.is_equipment():
		return true

	return false


func can_play_hand_card_at(player: PlayerState, hand_index: int, game_manager: GameManager = null) -> bool:
	if player == null or hand_index < 0 or hand_index >= player.hand.size():
		return false

	if not player.is_hand_card_available_at(hand_index):
		return false

	return can_play_hand_card(player, player.get_hand_card_data_at(hand_index), game_manager)


func get_available_actions(player: PlayerState, card_data: CardData, hand_index: int, game_manager: GameManager = null) -> Array[CardAction]:
	var actions: Array[CardAction] = []
	if not can_play_hand_card_at(player, hand_index, game_manager):
		return actions

	if card_data.is_spell():
		var action := CardAction.new()
		action.id = HAND_CAST_ACTION_ID
		action.display_name = "施放"
		action.main_action_cost = 0
		actions.append(action)
	elif card_data.is_minion():
		var action := CardAction.new()
		action.id = HAND_PLACE_ACTION_ID
		action.display_name = "放置"
		action.main_action_cost = 0
		actions.append(action)
	elif card_data.is_equipment():
		var action := CardAction.new()
		action.id = HAND_EQUIP_ACTION_ID
		action.display_name = "装备"
		action.main_action_cost = 0
		actions.append(action)
	return actions


func start_cast_target_selection(game_manager: GameManager, player: PlayerState, card_data: CardData, hand_index: int) -> bool:
	if game_manager == null or not can_play_hand_card_at(player, hand_index, game_manager):
		return false

	if not requires_target(card_data, player):
		await execute_hand_card(game_manager, player, card_data, hand_index, null)
		return true

	var targets := get_valid_targets(card_data, game_manager, player)
	if targets.is_empty():
		return false

	game_manager.interaction_manager.start_hand_card_target_selection(
		card_data,
		player.id,
		hand_index,
		HAND_CAST_ACTION_ID,
		targets,
		game_manager.get_all_board_states()
	)
	return true


func start_place_target_selection(game_manager: GameManager, player: PlayerState, card_data: CardData, hand_index: int) -> bool:
	if game_manager == null or player == null or card_data == null:
		return false

	if not can_play_hand_card_at(player, hand_index, game_manager):
		return false

	if not card_data.is_minion():
		return false

	var targets := get_valid_placement_targets(game_manager, card_data)
	if targets.is_empty():
		return false

	game_manager.interaction_manager.start_hand_card_target_selection(
		card_data,
		player.id,
		hand_index,
		HAND_PLACE_ACTION_ID,
		targets,
		game_manager.get_all_board_states()
	)
	return true


func execute_selected_hand_card(game_manager: GameManager, target_state: CardState) -> void:
	if game_manager == null:
		return

	var card_data := game_manager.interaction_manager.selected_hand_card_data
	var player := game_manager.get_player_by_id(game_manager.interaction_manager.selected_hand_owner_id)
	var hand_index := game_manager.interaction_manager.selected_hand_index
	var action_id := game_manager.interaction_manager.selected_hand_action_id
	match action_id:
		HAND_PLACE_ACTION_ID:
			await execute_hand_minion_placement(game_manager, player, card_data, hand_index, target_state)
		HAND_EQUIP_ACTION_ID:
			await execute_hand_equipment(game_manager, player, card_data, hand_index)
		_:
			await execute_hand_card(game_manager, player, card_data, hand_index, target_state)


func execute_hand_card(
	game_manager: GameManager,
	player: PlayerState,
	card_data: CardData,
	hand_index: int,
	target_state: CardState
) -> void:
	if game_manager == null or not can_play_hand_card_at(player, hand_index, game_manager):
		return

	var resolved_spell := resolve_hand_spell(player, card_data, target_state)
	var resolved_target_rule := str(resolved_spell.get("target_rule", get_target_rule(card_data, player)))
	if SpellTargetResolver.requires_target(resolved_target_rule) and not can_target(card_data, target_state, game_manager, player):
		return

	var resolved_animation := str(resolved_spell.get("animation", card_data.animation))
	await game_manager.play_hand_spell_card_animation(card_data, target_state, resolved_animation)

	for effect_data in get_resolved_effects(resolved_spell):
		var runtime_effect_data := effect_data.duplicate(true)
		EffectData.mark_effect_owner(runtime_effect_data, player.id)
		if SpellTargetResolver.requires_target(resolved_target_rule):
			EffectData.mark_selected_target(runtime_effect_data, target_state)
		EffectData.mark_spell_power_enabled(runtime_effect_data)
		EffectData.ensure_death_reason(runtime_effect_data, EffectData.DEATH_REASON_HAND_SPELL)
		await game_manager.effect_registry.execute_effect(null, runtime_effect_data, game_manager)

	player.remove_from_hand_at(hand_index, card_data)
	game_manager.update_hand_drawer_view()
	game_manager.refresh_debug_panel()


func get_resolved_effects(resolved_spell: Dictionary) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var raw_effects: Variant = resolved_spell.get("effects", [])
	if raw_effects is Array:
		for effect_data in raw_effects:
			if effect_data is Dictionary:
				effects.append(effect_data)

	return effects


func resolve_hand_spell(player: PlayerState, card_data: CardData, target_state: CardState) -> Dictionary:
	return hand_spell_modifier_resolver.resolve_hand_spell(player, card_data, target_state)


func get_resolved_spell_effects(player: PlayerState, card_data: CardData, target_state: CardState) -> Array[Dictionary]:
	return get_resolved_effects(resolve_hand_spell(player, card_data, target_state))


func get_valid_targets(card_data: CardData, game_manager: GameManager, player: PlayerState = null) -> Array[CardState]:
	if card_data == null or game_manager == null:
		return []

	return SpellTargetResolver.get_valid_targets(get_target_rule(card_data, player), game_manager)


func get_valid_placement_targets(game_manager: GameManager, card_data: CardData = null) -> Array[CardState]:
	var targets: Array[CardState] = []
	if game_manager == null:
		return targets

	for state in game_manager.board_states:
		if can_place_minion_on_target(state, game_manager, card_data):
			targets.append(state)

	return targets


func can_place_minion_on_target(target_state: CardState, game_manager: GameManager = null, card_data: CardData = null) -> bool:
	if target_state == null:
		return false
	if card_data != null and card_data.has_keyword(CardData.KEYWORD_FLYING):
		return game_manager != null and game_manager.can_place_aerial_card_on_slot(target_state.slot_index)

	if game_manager != null and game_manager.has_method("can_place_ground_card_on_slot"):
		if not game_manager.can_place_ground_card_on_slot(target_state.slot_index):
			return false

	if target_state.is_empty():
		return true

	return not target_state.is_face_up


func execute_hand_minion_placement(
	game_manager: GameManager,
	player: PlayerState,
	card_data: CardData,
	hand_index: int,
	target_state: CardState
) -> void:
	if game_manager == null or player == null or card_data == null:
		return

	if not card_data.is_minion():
		return

	if not can_play_hand_card_at(player, hand_index, game_manager):
		return

	if not can_place_minion_on_target(target_state, game_manager, card_data):
		return

	if not player.remove_from_hand_at(hand_index, card_data):
		return

	if card_data.has_keyword(CardData.KEYWORD_FLYING):
		var aerial_state := game_manager.get_aerial_state(target_state.slot_index)
		if aerial_state == null or not aerial_state.is_empty():
			return
		aerial_state.set_card_data(card_data)
		aerial_state.set_owner(player.id)
		aerial_state.set_face_up(true)
		await game_manager.resolve_slot_unit_entered(aerial_state)
		game_manager.refresh_hand_passives_for_player(player, player == game_manager.get_current_player())
		game_manager.refresh_action_available_hints()
		game_manager.update_hand_drawer_view()
		game_manager.refresh_debug_panel()
		return

	if target_state.data != null and not target_state.is_face_up and game_manager.card_pool != null:
		game_manager.card_pool.add_card(target_state.data, true)
		game_manager.update_card_pool_view()
		refill_one_empty_slot_after_replacing_hidden_card(game_manager, target_state.slot_index)

	target_state.set_card_data(card_data)
	target_state.set_owner(player.id)
	target_state.set_face_up(true)
	await game_manager.resolve_slot_unit_entered(target_state)
	game_manager.refresh_hand_passives_for_player(player, player == game_manager.get_current_player())
	game_manager.refresh_action_available_hints()
	game_manager.update_hand_drawer_view()
	game_manager.refresh_debug_panel()


func execute_hand_equipment(
	game_manager: GameManager,
	player: PlayerState,
	card_data: CardData,
	hand_index: int
) -> void:
	if game_manager == null or player == null or card_data == null:
		return

	if not card_data.is_equipment():
		return

	if not can_play_hand_card_at(player, hand_index, game_manager):
		return

	if not player.remove_from_hand_at(hand_index, card_data):
		return

	player.equip_card(card_data)
	game_manager.interaction_manager.cancel(game_manager.get_all_board_states())
	game_manager.update_hand_drawer_view()
	game_manager.refresh_debug_panel()


func refill_one_empty_slot_after_replacing_hidden_card(game_manager: GameManager, excluded_slot_index: int) -> void:
	if game_manager == null or game_manager.card_pool == null or game_manager.card_pool.is_empty():
		return

	for state in game_manager.board_states:
		if state == null:
			continue
		if state.slot_index == excluded_slot_index:
			continue
		if not state.is_empty():
			continue

		game_manager.refill_board_slot_from_pool(state.slot_index)
		return


func requires_target(card_data: CardData, player: PlayerState = null) -> bool:
	return SpellTargetResolver.requires_target(get_target_rule(card_data, player))


func can_target(card_data: CardData, target: CardState, game_manager: GameManager, player: PlayerState = null) -> bool:
	if card_data == null:
		return false

	return SpellTargetResolver.can_target(get_target_rule(card_data, player), target)


func get_target_rule(card_data: CardData, player: PlayerState = null) -> String:
	if player != null and card_data != null and card_data.is_spell():
		var resolved_spell := resolve_hand_spell(player, card_data, null)
		return str(resolved_spell.get("target_rule", SpellTargetResolver.get_rule_from_card_data(card_data)))

	return SpellTargetResolver.get_rule_from_card_data(card_data)


func is_required_hero_on_board(player: PlayerState, card_data: CardData, game_manager: GameManager) -> bool:
	if card_data == null or not card_data.is_hero_attached_card():
		return true
	if player == null or game_manager == null:
		return false

	return BoardQuery.has_face_up_hero(game_manager.get_all_board_states(), player.id, card_data.owner_hero_card_id)


func has_playable_effects(player: PlayerState, card_data: CardData, game_manager: GameManager) -> bool:
	if card_data == null:
		return false

	for effect_data in card_data.effects:
		if not is_effect_playable(player, effect_data, game_manager):
			return false

	return true


func is_effect_playable(player: PlayerState, effect_data: Dictionary, game_manager: GameManager) -> bool:
	if player == null or game_manager == null:
		return false

	var runtime_effect_data := effect_data.duplicate(true)
	EffectData.mark_effect_owner(runtime_effect_data, player.id)
	return game_manager.effect_registry.can_execute_effect(null, runtime_effect_data, game_manager)
