extends RefCounted
class_name InteractionManager

signal interaction_changed

# 玩家当前交互状态。后续移动、攻击、技能选目标都从这里扩展。
enum Mode {
	IDLE,
	CARD_SELECTED,
	SELECTING_ACTION_TARGET
}

var mode := Mode.IDLE
var focused_state: CardState
var selected_action: CardAction
var selected_hand_card_data: CardData
var selected_hand_owner_id := ""
var selected_hand_index := -1
var selected_hand_action_id := ""
var valid_target_slots: Array[int] = []
var area_preview_slots: Array[int] = []
var is_area_target_mode := false
var _area_rows := 0
var _area_cols := 0


func select_card(state: CardState, board_states: Array[CardState]) -> void:
	# 选中一张己方正面牌，让它成为当前焦点。
	clear_focus_and_targets(board_states)

	mode = Mode.CARD_SELECTED
	focused_state = state
	selected_action = null
	selected_hand_card_data = null
	selected_hand_owner_id = ""
	selected_hand_index = -1
	selected_hand_action_id = ""
	valid_target_slots.clear()
	focused_state.set_selected(true)
	interaction_changed.emit()


func toggle_card_selection(state: CardState, board_states: Array[CardState]) -> void:
	# 再次点击当前焦点牌时取消选择，点击其他可选牌时切换焦点。
	if focused_state == state:
		cancel(board_states)
	else:
		select_card(state, board_states)


func select_hand_card(card_data: CardData, owner_id: String, hand_index: int, board_states: Array[CardState]) -> void:
	clear_focus_and_targets(board_states)

	mode = Mode.CARD_SELECTED
	focused_state = null
	selected_action = null
	selected_hand_card_data = card_data
	selected_hand_owner_id = owner_id
	selected_hand_index = hand_index
	selected_hand_action_id = ""
	valid_target_slots.clear()
	interaction_changed.emit()


func toggle_hand_card_selection(card_data: CardData, owner_id: String, hand_index: int, board_states: Array[CardState]) -> void:
	if selected_hand_index == hand_index and selected_hand_card_data == card_data and selected_hand_owner_id == owner_id:
		cancel(board_states)
	else:
		select_hand_card(card_data, owner_id, hand_index, board_states)


func start_action_selection(action: CardAction, board_states: Array[CardState], game_manager: GameManager) -> void:
	# 进入某个行动的目标选择。目标合法性由具体 CardAction 决定。
	if focused_state == null or action == null:
		return

	clear_targets(board_states)
	clear_area_preview(board_states)
	mode = Mode.SELECTING_ACTION_TARGET
	selected_action = action
	selected_hand_card_data = null
	selected_hand_owner_id = ""
	selected_hand_index = -1
	selected_hand_action_id = ""
	valid_target_slots.clear()
	area_preview_slots.clear()

	var area_info := action.get_area_info()
	is_area_target_mode = not area_info.is_empty()
	_area_rows = area_info.get("rows", 0)
	_area_cols = area_info.get("cols", 0)

	for state in action.get_valid_targets(focused_state, game_manager):
		state.set_valid_target(true)
		valid_target_slots.append(state.slot_index)

	interaction_changed.emit()


func start_hand_card_target_selection(
	card_data: CardData,
	owner_id: String,
	hand_index: int,
	hand_action_id: String,
	targets: Array[CardState],
	board_states: Array[CardState]
) -> void:
	# 手牌法术也复用同一个目标选择模式，但没有棋盘焦点牌。
	clear_targets(board_states)
	clear_area_preview(board_states)
	mode = Mode.SELECTING_ACTION_TARGET
	focused_state = null
	selected_action = null
	selected_hand_card_data = card_data
	selected_hand_owner_id = owner_id
	selected_hand_index = hand_index
	selected_hand_action_id = hand_action_id
	valid_target_slots.clear()
	area_preview_slots.clear()

	var target_rule := SpellTargetResolver.get_rule_from_card_data(card_data)
	var area_info := SpellTargetResolver.get_area_dimensions(target_rule)
	is_area_target_mode = not area_info.is_empty()
	_area_rows = area_info.get("rows", 0)
	_area_cols = area_info.get("cols", 0)

	for state in targets:
		if state == null:
			continue
		state.set_valid_target(true)
		valid_target_slots.append(state.slot_index)

	interaction_changed.emit()


func is_valid_target_slot(slot_index: int) -> bool:
	return valid_target_slots.has(slot_index)


func update_area_preview(hovered_state: CardState, board_states: Array[CardState], game_manager: GameManager) -> void:
	if not is_area_target_mode:
		return
	clear_area_preview(board_states)
	if hovered_state == null or not is_valid_target_slot(hovered_state.slot_index):
		return

	area_preview_slots = BoardQuery.get_area_slots(
		hovered_state.slot_index, _area_rows, _area_cols,
		game_manager.board_columns, game_manager.board_states.size()
	)
	for slot_index in area_preview_slots:
		var state := game_manager.get_board_state(slot_index) as CardState
		if state != null:
			state.set_area_preview(true)


func clear_area_preview(board_states: Array[CardState]) -> void:
	for slot_index in area_preview_slots:
		var state := board_states[slot_index] as CardState
		if state != null:
			state.set_area_preview(false)
	area_preview_slots.clear()


func cancel(board_states: Array[CardState]) -> void:
	# 取消当前交互，回到空闲状态。
	clear_area_preview(board_states)
	is_area_target_mode = false
	_area_rows = 0
	_area_cols = 0
	clear_focus_and_targets(board_states)
	mode = Mode.IDLE
	focused_state = null
	selected_action = null
	selected_hand_card_data = null
	selected_hand_owner_id = ""
	selected_hand_index = -1
	selected_hand_action_id = ""
	valid_target_slots.clear()
	interaction_changed.emit()


func return_to_card_selection(board_states: Array[CardState]) -> void:
	# 从目标选择退回焦点状态。这个流程不依赖具体行动，也不占用任何目标点击。
	if focused_state == null and selected_hand_card_data == null:
		cancel(board_states)
		return

	clear_targets(board_states)
	mode = Mode.CARD_SELECTED
	selected_action = null
	if focused_state != null:
		selected_hand_card_data = null
		selected_hand_owner_id = ""
		selected_hand_index = -1
		selected_hand_action_id = ""
	valid_target_slots.clear()
	interaction_changed.emit()


func clear_focus_and_targets(board_states: Array[CardState]) -> void:
	if focused_state != null:
		focused_state.set_selected(false)

	clear_targets(board_states)


func clear_targets(board_states: Array[CardState]) -> void:
	for state in board_states:
		state.set_valid_target(false)


func get_mode_name() -> String:
	match mode:
		Mode.IDLE:
			return "idle"
		Mode.CARD_SELECTED:
			return "card_selected"
		Mode.SELECTING_ACTION_TARGET:
			return "selecting_action_target"
		_:
			return "unknown"


func get_focused_slot() -> int:
	if focused_state == null:
		return -1

	return focused_state.slot_index


func get_selected_action_id() -> String:
	if selected_action == null:
		if selected_hand_card_data != null:
			if selected_hand_action_id != "":
				return selected_hand_action_id
			return "hand:%s" % selected_hand_card_data.id
		return ""

	return selected_action.id
