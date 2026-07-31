extends RefCounted
class_name GameAnimationResolver

const SPELL_TURN_ACTIVATION_ANIMATION_KEY := "spell_turn_activation"

# GameAnimationResolver owns animation orchestration that needs both runtime
# board state and UI nodes. GameManager keeps stable facade methods, while this
# resolver keeps the animation bridge out of the main rules coordinator.


func play_card_swap_animation(
	game_manager: GameManager,
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2,
	animation_key := ""
) -> void:
	if game_manager == null:
		return

	await game_manager.card_animation_controller.play_card_swap(
		game_manager,
		first_card,
		second_card,
		first_slot_position,
		second_slot_position,
		get_overlay_animation_root(game_manager),
		animation_key
	)


func play_card_attack_animation(
	game_manager: GameManager,
	attacker_state: CardState,
	target_state: CardState,
	is_melee_attack := true,
	attack_animation_key := ""
) -> void:
	if game_manager == null or attacker_state == null or target_state == null:
		return
	if attack_animation_key == "":
		attack_animation_key = resolve_attack_animation_key(attacker_state)

	var attacker_card: Card = game_manager.get_card_for_state(attacker_state)
	var target_card: Card = game_manager.get_card_for_state(target_state)
	if attacker_card == null or target_card == null:
		return

	game_manager.is_resolving_card_action = true
	game_manager.play_sfx("attack_melee" if is_melee_attack else "attack_ranged")
	await game_manager.card_animation_controller.play_card_attack(
		game_manager,
		get_overlay_animation_root(game_manager),
		attacker_card,
		target_card,
		is_melee_attack,
		attack_animation_key
	)
	game_manager.is_resolving_card_action = false


func resolve_attack_animation_key(attacker_state: CardState) -> String:
	if attacker_state == null or attacker_state.data == null:
		return ""
	if attacker_state.data.faction_id != "tokyo_ghoul":
		return ""

	match attacker_state.card_id:
		"kaneki_centipede_form":
			return "tokyo_centipede_attack"
		"kaneki_dragon_form":
			return "tokyo_dragon_attack"
		"kaneki_saint_sword_form":
			return "tokyo_saint_sword_attack"
		"kuzen_yoshimura", "eto_yoshimura", "non_killing_owl", "one_eyed_owl":
			return "tokyo_owl_attack"
		"nimura_furuta":
			return "tokyo_furuta_attack"

	var kagune_types: Array[String] = []
	for kagune_type in [
		CardData.KEYWORD_KAGUNE_BIKAKU,
		CardData.KEYWORD_KAGUNE_RINKAKU,
		CardData.KEYWORD_KAGUNE_KOUKAKU,
		CardData.KEYWORD_KAGUNE_UKAKU,
	]:
		if attacker_state.has_keyword(kagune_type):
			kagune_types.append(kagune_type)
	if kagune_types.size() > 1:
		return "tokyo_chimera_attack"
	if kagune_types.is_empty():
		return ""

	match kagune_types[0]:
		CardData.KEYWORD_KAGUNE_UKAKU:
			return "tokyo_ukaku_attack"
		CardData.KEYWORD_KAGUNE_KOUKAKU:
			return "tokyo_koukaku_attack"
		CardData.KEYWORD_KAGUNE_RINKAKU:
			return "tokyo_rinkaku_attack"
		CardData.KEYWORD_KAGUNE_BIKAKU:
			return "tokyo_bikaku_attack"
	return ""


func play_secondary_attack_impact_animation(
	game_manager: GameManager,
	target_states: Array[CardState]
) -> void:
	if game_manager == null or target_states.is_empty():
		return

	var target_cards: Array[Card] = []
	for target_state in target_states:
		if target_state == null:
			continue
		var target_card: Card = game_manager.get_card_for_state(target_state)
		if target_card != null and not target_cards.has(target_card):
			target_cards.append(target_card)
	if target_cards.is_empty():
		return

	game_manager.is_resolving_card_action = true
	await game_manager.card_animation_controller.play_secondary_attack_impacts(
		game_manager,
		target_cards
	)
	game_manager.is_resolving_card_action = false


func play_spell_cast_animation(
	game_manager: GameManager,
	caster_state: CardState,
	target_state: CardState,
	spell_data: Dictionary
) -> void:
	if game_manager == null or caster_state == null or target_state == null:
		return

	var caster_card: Card = game_manager.get_card_for_state(caster_state)
	var target_card: Card = game_manager.get_card_for_state(target_state)
	if caster_card == null or target_card == null:
		return

	game_manager.is_resolving_card_action = true
	game_manager.play_spell_sfx(spell_data)
	await game_manager.card_animation_controller.play_spell_cast(
		game_manager,
		get_overlay_animation_root(game_manager),
		caster_card,
		target_card,
		spell_data
	)
	game_manager.is_resolving_card_action = false


func play_area_spell_animation(
	game_manager: GameManager,
	caster_state: CardState,
	center_state: CardState,
	spell_data: Dictionary
) -> void:
	if game_manager == null or caster_state == null or center_state == null:
		return

	var caster_card: Card = game_manager.get_card_for_state(caster_state)
	var center_card: Card = game_manager.get_card_for_state(center_state)
	if caster_card == null or center_card == null:
		return

	game_manager.is_resolving_card_action = true
	game_manager.play_spell_sfx(spell_data)
	await game_manager.card_animation_controller.play_area_spell_cast(
		game_manager,
		get_overlay_animation_root(game_manager),
		caster_card,
		center_card,
		spell_data
	)
	game_manager.is_resolving_card_action = false


func play_link_units_animation(
	game_manager: GameManager,
	first_state: CardState,
	second_state: CardState,
	animation_key := "gu_life_link"
) -> void:
	if game_manager == null or first_state == null or second_state == null:
		return

	var first_card: Card = game_manager.get_card_for_state(first_state)
	var second_card: Card = game_manager.get_card_for_state(second_state)
	if first_card == null or second_card == null:
		return

	game_manager.is_resolving_card_action = true
	await game_manager.card_animation_controller.play_life_link_spell(
		game_manager,
		get_overlay_animation_root(game_manager),
		first_card,
		second_card,
		{"animation": animation_key}
	)
	game_manager.is_resolving_card_action = false


func play_moonblade_animation(
	game_manager: GameManager,
	caster_state: CardState,
	first_state: CardState,
	second_state: CardState
) -> void:
	if game_manager == null or caster_state == null or first_state == null or second_state == null:
		return

	var caster_card: Card = game_manager.get_card_for_state(caster_state)
	var first_card: Card = game_manager.get_card_for_state(first_state)
	var second_card: Card = game_manager.get_card_for_state(second_state)
	if caster_card == null or first_card == null or second_card == null:
		return

	game_manager.is_resolving_card_action = true
	await game_manager.card_animation_controller.play_moonblade_spell(
		game_manager,
		get_overlay_animation_root(game_manager),
		caster_card,
		first_card,
		second_card
	)
	game_manager.is_resolving_card_action = false


func play_effect_heal_animation(game_manager: GameManager, target_state: CardState) -> void:
	if game_manager == null or target_state == null:
		return

	var target_card: Card = game_manager.get_card_for_state(target_state)
	if target_card == null:
		return

	await game_manager.card_animation_controller.play_spell_cast(
		game_manager,
		get_overlay_animation_root(game_manager),
		target_card,
		target_card,
		{"animation": "heal"}
	)


func play_multi_target_effect_animation(
	game_manager: GameManager,
	target_states: Array[CardState],
	animation_key: String
) -> bool:
	if game_manager == null or target_states.is_empty() or animation_key == "":
		return false

	var target_rects: Array[Rect2] = []
	for target_state in target_states:
		var target_card: Card = game_manager.get_card_for_state(target_state)
		if target_card != null and is_instance_valid(target_card):
			target_rects.append(target_card.get_global_rect())
	if target_rects.is_empty():
		return false

	return await game_manager.card_animation_controller.play_multi_rect_effect(
		game_manager,
		get_overlay_animation_root(game_manager),
		target_rects,
		animation_key
	)


func play_status_apply_animation(
	game_manager: GameManager,
	target_state: CardState,
	animation_key: String
) -> void:
	if game_manager == null or target_state == null or animation_key == "":
		return

	var target_card: Card = game_manager.get_card_for_state(target_state)
	if target_card == null:
		return

	await game_manager.card_animation_controller.play_spell_cast(
		game_manager,
		get_overlay_animation_root(game_manager),
		target_card,
		target_card,
		{"animation": animation_key}
	)


func play_slot_effect_animation(
	game_manager: GameManager,
	target_state: CardState,
	animation_key: String
) -> void:
	if game_manager == null or target_state == null or animation_key == "":
		return

	var target_card: Card = game_manager.get_card_for_state(target_state)
	if target_card == null:
		return

	await game_manager.card_animation_controller.play_spell_cast_at_rect(
		game_manager,
		get_overlay_animation_root(game_manager),
		target_card.get_global_rect(),
		{"animation": animation_key}
	)


func play_board_effect_animation(game_manager: GameManager, animation_key: String) -> void:
	if game_manager == null or animation_key == "":
		return

	await game_manager.card_animation_controller.play_board_effect(
		game_manager,
		get_overlay_animation_root(game_manager),
		animation_key
	)


func play_path_effect_animation(game_manager: GameManager, slot_indices: Array[int], animation_key: String) -> void:
	if game_manager == null or animation_key == "" or slot_indices.is_empty():
		return

	var rects: Array[Rect2] = []
	for slot_index in slot_indices:
		var card := game_manager.get_card_by_slot(slot_index)
		if card == null:
			continue
		rects.append(card.get_global_rect())

	if rects.is_empty():
		return

	await game_manager.card_animation_controller.play_path_effect(
		game_manager,
		get_overlay_animation_root(game_manager),
		rects,
		animation_key
	)


func play_card_to_hand_animation(
	game_manager: GameManager,
	source_card: Card,
	card_data: CardData
) -> void:
	if game_manager == null or source_card == null or card_data == null:
		return

	await game_manager.hand_drawer_controller.play_card_to_hand_animation(
		game_manager,
		get_overlay_animation_root(game_manager),
		source_card,
		card_data
	)


func play_hand_spell_card_animation(
	game_manager: GameManager,
	card_data: CardData,
	target_state: CardState = null,
	animation_override := ""
) -> void:
	if game_manager == null or card_data == null:
		return

	var spell_data := {
		"animation": animation_override if animation_override != "" else (card_data.animation if card_data.animation != "" else "heal")
	}
	if card_data.audio != "":
		spell_data["audio"] = card_data.audio

	game_manager.is_resolving_card_action = true
	game_manager.play_spell_sfx(spell_data)

	if target_state != null:
		var target_card: Card = game_manager.get_card_for_state(target_state)
		if target_card != null:
			var hand_card_rect: Rect2 = game_manager.hand_interaction_controller.get_selected_hand_card_rect()
			if hand_card_rect.size != Vector2.ZERO:
				await game_manager.card_animation_controller.play_spell_cast_from_rect_to_card(
					game_manager,
					get_overlay_animation_root(game_manager),
					hand_card_rect,
					target_card,
					spell_data
				)
			else:
				await game_manager.card_animation_controller.play_spell_cast(
					game_manager,
					get_overlay_animation_root(game_manager),
					target_card,
					target_card,
					spell_data
				)
	else:
		var hand_card_rect: Rect2 = game_manager.hand_interaction_controller.get_selected_hand_card_rect()
		if hand_card_rect.size != Vector2.ZERO:
			await game_manager.card_animation_controller.play_spell_cast_at_rect(
				game_manager,
				get_overlay_animation_root(game_manager),
				hand_card_rect,
				spell_data
			)

	game_manager.is_resolving_card_action = false


func get_overlay_animation_root(game_manager: GameManager) -> Control:
	if game_manager == null:
		return null
	if game_manager.card_pool_view_controller.animation_root != null:
		return game_manager.card_pool_view_controller.animation_root

	return game_manager.get_parent() as Control


func animate_refill_board_slot(game_manager: GameManager, slot_index: int, card_data: CardData) -> void:
	if game_manager == null:
		return

	var state: CardState = game_manager.get_board_state(slot_index)
	var target_card: Card = game_manager.get_card_by_slot(slot_index)
	if state == null or target_card == null or card_data == null:
		return

	if not game_manager.can_refill_ground_slot(slot_index):
		game_manager.card_pool.add_card(card_data, true)
		game_manager.update_card_pool_view()
		game_manager.refresh_debug_panel()
		return

	if game_manager.card_pool_view_controller.view == null or game_manager.card_pool_view_controller.animation_root == null:
		state.set_card_data(card_data)
		state.set_face_up(false)
		game_manager.refresh_action_available_hints()
		game_manager.refresh_debug_panel()
		return

	game_manager.is_resolving_card_action = true
	target_card.is_animating = true

	var card_back_texture: Texture2D = card_data.back_texture
	if card_back_texture == null:
		card_back_texture = game_manager.get_card_back_texture_for_level(card_data.level)

	await game_manager.card_pool_view_controller.play_refill_animation(game_manager, target_card, card_back_texture)

	if state.is_empty() and game_manager.can_refill_ground_slot(slot_index):
		state.set_card_data(card_data)
		state.set_face_up(false)
	else:
		game_manager.card_pool.add_card(card_data, true)
		game_manager.update_card_pool_view()

	target_card.is_animating = false
	game_manager.is_resolving_card_action = false
	game_manager.refresh_action_available_hints()
	game_manager.refresh_debug_panel()
