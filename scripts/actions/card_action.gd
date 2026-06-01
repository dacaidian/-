extends RefCounted
class_name CardAction

# CardAction 是所有卡牌行动的基类。
# 每个具体行动只负责三件事：能否开始、哪些目标合法、如何执行。

var id := ""
var display_name := ""
var main_action_cost := 1
var action_group := ""
var can_reuse_action_group := true
var once_per_turn := false


func can_start(_user: CardState, _game_manager: GameManager) -> bool:
	return false


func get_valid_targets(_user: CardState, _game_manager: GameManager) -> Array[CardState]:
	var targets: Array[CardState] = []
	return targets


func execute(_user: CardState, _target: CardState, _game_manager: GameManager) -> void:
	pass


func requires_target() -> bool:
	return true


func get_area_info() -> Dictionary:
	return {}


func can_pay_action_cost(user: CardState) -> bool:
	if user == null:
		return false

	if main_action_cost > 0 and not user.can_take_action_group(action_group, can_reuse_action_group):
		return false

	if once_per_turn and user.has_used_action_id(id):
		return false

	return true


func pay_action_cost(user: CardState) -> bool:
	if user == null:
		return false

	if main_action_cost > 0 and not user.register_action_group(action_group):
		return false

	if once_per_turn and not user.register_action_id(id):
		return false

	return true


func is_controlled_face_up_minion(user: CardState, game_manager: GameManager) -> bool:
	if user == null or game_manager == null:
		return false

	if user.is_empty() or not user.is_face_up:
		return false

	if not user.is_minion():
		return false

	var current_player: PlayerState = game_manager.get_current_player()
	if current_player == null:
		return false

	return user.is_owned_by(current_player.id)


func is_neighbor(from_slot: int, to_slot: int, board_columns: int) -> bool:
	return BoardQuery.is_neighbor(from_slot, to_slot, board_columns)
