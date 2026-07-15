extends RefCounted
class_name KagunePowerResolver

const FACTION_ID := "tokyo_ghoul"
const HIGH_RC_STATE_ID := "rc_high"
const STATUS_ID := "kagune_release"
const STATUS_NAME := "赫子解放"
const STATUS_TAG := "kagune_power"
const FEATHER_NEEDLE_ACTION_ID := "feather_needle"


func refresh_player(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var is_active := (
		player.faction_id == FACTION_ID
		and game_manager.is_spell_turn_active
		and game_manager.get_current_player() == player
	)
	var is_high_concentration := player.faction_runtime_state_id == HIGH_RC_STATE_ID

	for state in game_manager.get_all_board_states():
		if not BoardQuery.is_face_up_minion(state):
			continue

		var existing_status := state.get_status(STATUS_ID)
		if existing_status != null and existing_status.source_owner_id == player.id:
			state.remove_status(STATUS_ID)
		if state.owner_id != player.id:
			continue
		if not is_active:
			continue

		var kagune_types := get_kagune_types(state)
		if kagune_types.is_empty():
			continue

		state.add_status(create_kagune_status(player, kagune_types, is_high_concentration))


func get_kagune_types(state: CardState) -> Array[String]:
	var types: Array[String] = []
	if state == null:
		return types

	for kagune_type in [
		CardData.KEYWORD_KAGUNE_BIKAKU,
		CardData.KEYWORD_KAGUNE_RINKAKU,
		CardData.KEYWORD_KAGUNE_KOUKAKU,
		CardData.KEYWORD_KAGUNE_UKAKU
	]:
		if state.has_keyword(kagune_type):
			types.append(kagune_type)
	return types


func create_kagune_status(
	player: PlayerState,
	kagune_types: Array[String],
	is_high_concentration: bool
) -> CardStatus:
	var status := CardStatus.new()
	status.status_id = STATUS_ID
	status.display_name = STATUS_NAME
	status.description = "施法回合中，赫子能力已经解放。"
	status.tags = [CardStatus.TAG_UNCLEANSEABLE, STATUS_TAG]
	status.stack_policy = CardStatus.STACK_POLICY_REPLACE
	status.is_permanent = true
	status.source_card_id = "kagune_power_guide"
	status.source_owner_id = player.id
	status.duration_owner_id = player.id
	status.valence = EffectData.STATUS_VALENCE_POSITIVE
	status.payload = create_kagune_payload(kagune_types, is_high_concentration)
	if int(status.payload.get(EffectData.KEY_ATTACK_BONUS, 0)) != 0:
		status.tags.append(CardStatus.TAG_ATTACK_MODIFIER)
	return status


func create_kagune_payload(kagune_types: Array[String], is_high_concentration: bool) -> Dictionary:
	var payload := {"kagune_types": kagune_types.duplicate()}
	var keywords: Array[String] = []
	var actions: Array[Dictionary] = []
	var attack_bonus := 0
	var armor_bonus := 0
	var movement_bonus := 0

	for kagune_type in kagune_types:
		match kagune_type:
			CardData.KEYWORD_KAGUNE_BIKAKU:
				append_unique_keyword(keywords, CardData.KEYWORD_MOBILE_ASSAULT)
				if is_high_concentration:
					movement_bonus += 2
			CardData.KEYWORD_KAGUNE_RINKAKU:
				attack_bonus += 2 if is_high_concentration else 1
				if is_high_concentration:
					append_unique_keyword(keywords, CardData.KEYWORD_LIFESTEAL)
			CardData.KEYWORD_KAGUNE_KOUKAKU:
				armor_bonus += 2 if is_high_concentration else 1
				if is_high_concentration:
					append_unique_keyword(keywords, CardData.KEYWORD_REFLECT)
			CardData.KEYWORD_KAGUNE_UKAKU:
				actions.append(create_feather_needle_action(3 if is_high_concentration else 1))

	if not keywords.is_empty():
		payload[EffectData.KEY_KEYWORDS] = keywords
	if not actions.is_empty():
		payload[EffectData.KEY_ACTIONS] = actions
	if attack_bonus != 0:
		payload[EffectData.KEY_ATTACK_BONUS] = attack_bonus
	if armor_bonus != 0:
		payload[EffectData.KEY_ARMOR_BONUS] = armor_bonus
	if movement_bonus != 0:
		payload[EffectData.KEY_MOVEMENT_BONUS] = movement_bonus
	return payload


func create_feather_needle_action(damage: int) -> Dictionary:
	return {
		EffectData.KEY_ACTION_ID: FEATHER_NEEDLE_ACTION_ID,
		"name": "羽针",
		EffectData.KEY_TARGET_RULE: SpellTargetResolver.TARGET_RULE_ALL_MINIONS,
		"animation": FEATHER_NEEDLE_ACTION_ID,
		"main_action_cost": 0,
		"action_group": CardState.ACTION_GROUP_SPECIAL,
		"can_reuse_action_group": true,
		"once_per_turn": true,
		"effects": [
			{
				EffectData.KEY_ID: EffectData.EFFECT_DAMAGE,
				EffectData.KEY_AMOUNT: damage
			}
		]
	}


func append_unique_keyword(keywords: Array[String], keyword: String) -> void:
	if keyword != "" and not keywords.has(keyword):
		keywords.append(keyword)
