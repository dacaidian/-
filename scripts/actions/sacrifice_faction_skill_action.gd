extends CardAction
class_name SacrificeFactionSkillAction

const ACTION_ID := "faction_skill:sacrifice"
const RESOURCE_TAIL := "tail"

var skill_data: Dictionary = {}


func setup(value: Dictionary) -> SacrificeFactionSkillAction:
	skill_data = value.duplicate(true)
	id = ACTION_ID
	display_name = str(skill_data.get("name", "献祭"))
	action_group = ""
	main_action_cost = 0
	return self


func can_start(user: CardState, game_manager: GameManager) -> bool:
	var player := get_current_player(game_manager)
	if player == null:
		return false

	return player.can_use_faction_skill(get_skill_id())


func get_valid_targets(user: CardState, game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	if not can_start(user, game_manager):
		return targets

	for state in game_manager.get_all_board_states():
		if can_target(user, state, game_manager):
			targets.append(state)

	return targets


func can_target(_user: CardState, target: CardState, game_manager: GameManager) -> bool:
	var player := get_current_player(game_manager)
	if player == null or target == null:
		return false

	return (
		BoardQuery.is_face_up_minion(target)
		and target.is_owned_by(player.id)
		and not target.is_hero()
	)


func execute(user: CardState, target: CardState, game_manager: GameManager) -> void:
	var player := get_current_player(game_manager)
	if player == null or target == null:
		return
	if not can_start(user, game_manager) or not can_target(user, target, game_manager):
		return
	if not player.register_faction_skill_use(get_skill_id()):
		return

	if game_manager.has_method("play_status_apply_animation"):
		await game_manager.play_status_apply_animation(target, "sacrifice")

	game_manager.destroy_card_with_refill(target, "faction_skill_sacrifice", user, true)
	player.gain_faction_resource(str(skill_data.get("resource_id", RESOURCE_TAIL)), int(skill_data.get("amount", 1)))
	if game_manager.has_method("refresh_hand_passives_for_player"):
		game_manager.refresh_hand_passives_for_player(player, player == game_manager.get_current_player())


func get_skill_id() -> String:
	return str(skill_data.get("id", "sacrifice"))


func get_current_player(game_manager: GameManager) -> PlayerState:
	if game_manager == null:
		return null
	return game_manager.get_current_player()
