extends PanelContainer
class_name DebugPanel

# DebugPanel 鍙礋璐ｆ妸杩愯鏃剁姸鎬佸睍绀哄嚭鏉ワ紝涓嶅弬涓庝换浣曟父鎴忚鍒欍€?
@onready var state_label: RichTextLabel = $MarginContainer/StateLabel
@onready var margin_container: MarginContainer = $MarginContainer

var toggle_button: Button
var is_expanded := true
var expanded_anchor_bottom := 1.0
var expanded_offset_left := 0.0
var expanded_offset_top := 0.0
var expanded_offset_right := 0.0
var expanded_offset_bottom := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2000
	store_expanded_layout()
	setup_toggle_button()
	if margin_container != null:
		margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin_container.add_theme_constant_override("margin_top", 12)
	if state_label != null:
		state_label.mouse_filter = Control.MOUSE_FILTER_STOP


func store_expanded_layout() -> void:
	expanded_anchor_bottom = anchor_bottom
	expanded_offset_left = offset_left
	expanded_offset_top = offset_top
	expanded_offset_right = offset_right
	expanded_offset_bottom = offset_bottom


func setup_toggle_button() -> void:
	toggle_button = Button.new()
	toggle_button.name = "DebugToggleButton"
	toggle_button.text = "Debug"
	toggle_button.custom_minimum_size = Vector2(104, 32)
	toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_button.z_index = 4000
	toggle_button.pressed.connect(toggle_debug_panel)
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	parent_control.add_child.call_deferred(toggle_button)
	position_toggle_button.call_deferred()


func toggle_debug_panel() -> void:
	set_expanded(not is_expanded)


func set_expanded(value: bool) -> void:
	is_expanded = value
	if margin_container != null:
		margin_container.visible = is_expanded

	if toggle_button != null:
		toggle_button.text = "Hide" if is_expanded else "Debug"
		position_toggle_button()

	if is_expanded:
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_bottom = expanded_anchor_bottom
		offset_left = expanded_offset_left
		offset_top = expanded_offset_top
		offset_right = expanded_offset_right
		offset_bottom = expanded_offset_bottom
	else:
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_bottom = 0.0
		offset_left = -520.0
		offset_top = 24.0
		offset_right = -400.0
		offset_bottom = 68.0


func position_toggle_button() -> void:
	if toggle_button == null:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	toggle_button.position = Vector2(
		maxf(viewport_size.x - 520.0, 20.0),
		24.0
	)

func update_states(
	states: Array[CardState],
	players: Array[PlayerState],
	current_player_index: int,
	turn_number: int,
	card_pool_remaining: int = -1,
	interaction_manager: InteractionManager = null
) -> void:
	# 重新拼接整块调试文本。
	var lines: Array[String] = []
	lines.append("[b]Card State Debug[/b]")
	lines.append("turn: %d" % turn_number)
	if card_pool_remaining >= 0:
		lines.append("card_pool_remaining: %d" % card_pool_remaining)
	if interaction_manager != null:
		lines.append("interaction: %s" % interaction_manager.get_mode_name())
		lines.append("focused_slot: %s" % format_slot_number(interaction_manager.get_focused_slot()))
		if interaction_manager.get_selected_action_id() != "":
			lines.append("selected_action: %s" % interaction_manager.get_selected_action_id())
		if not interaction_manager.valid_target_slots.is_empty():
			lines.append("valid_targets: %s" % format_slot_numbers(interaction_manager.valid_target_slots))
	lines.append("")
	lines.append("[b]Players[/b]")

	for index in range(players.size()):
		lines.append(format_player(players[index], index == current_player_index))

	lines.append("")
	lines.append("[b]Board Cards[/b]")
	lines.append("count: %d" % states.size())
	lines.append("")

	for state in states:
		lines.append(format_state(state))

	state_label.text = "\n".join(PackedStringArray(lines))


func format_player(player: PlayerState, is_current: bool) -> String:
	# 当前操作玩家前面用 > 标记。
	var marker := ">" if is_current else " "

	return "%s %s  faction=%s  resource=%d  flips=%d/%d  mana=%d/%d  hand=%d deck=%d discard=%d graveyard=%d" % [
		marker,
		player.display_name,
		player.faction_id,
		player.resource_score,
		player.remaining_flips,
		player.max_flips_per_turn,
		player.mana,
		player.max_mana,
		player.hand.size(),
		player.deck.size(),
		player.discard_pile.size(),
		player.graveyard.size()
	]


func format_state(state: CardState) -> String:
	# 把单张卡牌的关键运行时状态压缩成一行。
	if state.is_empty():
		return "#%02d  empty" % [state.slot_index + 1]

	var face := "front" if state.is_face_up else "back"
	var keywords := ""
	var role := ""

	if state.data != null:
		keywords = ",".join(PackedStringArray(state.data.keywords))
		role = state.data.role

	var owner := state.owner_id if state.owner_id != "" else "none"
	var marks: Array[String] = []
	if state.is_selected:
		marks.append("selected")
	if state.is_valid_target:
		marks.append("target")

	return "#%02d  %s  id=%s  role=%s  faction=%s  owner=%s  face=%s  atk=%d  hp=%d/%d  dmg=%d shield=%d  main=%d/%d groups=[%s]  move=%d/%d  attacks=%d/%d  marks=[%s]  keywords=[%s]  statuses=[%s]" % [
		state.slot_index + 1,
		state.display_name,
		state.card_id,
		role,
		state.data.faction_id,
		owner,
		face,
		state.current_attack,
		state.current_health,
		state.max_health,
		state.damage_taken,
		state.shield,
		state.current_main_actions,
		state.max_main_actions,
		",".join(PackedStringArray(state.used_action_groups)),
		state.current_movement,
		state.max_movement,
		state.current_attacks,
		state.max_attack_speed,
		",".join(PackedStringArray(marks)),
		keywords,
		format_statuses(state)
	]


func format_statuses(state: CardState) -> String:
	var status_texts: Array[String] = []

	for status in state.statuses:
		if status == null:
			continue

		var duration := "permanent" if status.is_permanent else "%d" % status.remaining_turns
		var stack_text := "x%d" % status.stacks if status.stacks > 1 else ""
		status_texts.append("%s%s:%s" % [status.status_id, stack_text, duration])

	return ",".join(PackedStringArray(status_texts))


func format_slot_number(slot_index: int) -> String:
	if slot_index < 0:
		return "none"

	return "#%02d" % [slot_index + 1]


func format_slot_numbers(slot_indexes: Array[int]) -> String:
	var numbers: Array[String] = []

	for slot_index in slot_indexes:
		numbers.append(format_slot_number(slot_index))

	return ",".join(PackedStringArray(numbers))
