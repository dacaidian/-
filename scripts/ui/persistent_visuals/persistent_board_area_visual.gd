extends Control
class_name PersistentBoardAreaVisual

# Base view for a persistent board-area visual attached to a CardStatus.
# Rules own the status and its area descriptor; this node only follows the
# source card, resolves the matching board rectangle, and drives animation.

var game_manager: Node
var source_state: CardState
var source_status: CardStatus
var descriptor: Dictionary = {}
var animation_time := 0.0
var area_rows := 1
var area_cols := 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	sync_layout()
	queue_redraw()


func configure(
	new_game_manager: Node,
	new_source_state: CardState,
	new_source_status: CardStatus,
	new_descriptor: Dictionary
) -> void:
	game_manager = new_game_manager
	source_state = new_source_state
	source_status = new_source_status
	descriptor = new_descriptor.duplicate(true)
	area_rows = maxi(int(descriptor.get(EffectData.KEY_AREA_ROWS, 1)), 1)
	area_cols = maxi(int(descriptor.get(EffectData.KEY_AREA_COLS, 1)), 1)
	z_index = int(descriptor.get(EffectData.KEY_VISUAL_Z_INDEX, 40))

	if is_inside_tree():
		visible = sync_layout()
		queue_redraw()


func _process(delta: float) -> void:
	if not is_source_active():
		visible = false
		return

	animation_time = fmod(animation_time + delta, 120.0)
	visible = sync_layout()
	if visible:
		queue_redraw()


func is_source_active() -> bool:
	if game_manager == null or not is_instance_valid(game_manager):
		return false
	if source_state == null or source_status == null:
		return false
	if source_state.is_empty() or not source_state.is_face_up:
		return false

	return source_state.statuses.has(source_status)


func sync_layout() -> bool:
	var area_global_rect := get_area_global_rect()
	if area_global_rect.size == Vector2.ZERO:
		return false

	var parent_control := get_parent() as Control
	if parent_control == null:
		return false

	var inverse_transform := parent_control.get_global_transform().affine_inverse()
	var local_start := inverse_transform * area_global_rect.position
	var local_end := inverse_transform * area_global_rect.end
	position = local_start
	size = local_end - local_start
	return size.x > 0.0 and size.y > 0.0


func get_area_global_rect() -> Rect2:
	if game_manager == null or source_state == null:
		return Rect2()
	if not game_manager.has_method("get_card_by_slot"):
		return Rect2()

	var board_columns: int = int(game_manager.get("board_columns"))
	var board_states_value: Variant = game_manager.get("board_states")
	if not board_states_value is Array:
		return Rect2()

	var board_size := (board_states_value as Array).size()
	var area_slots := BoardQuery.get_area_slots(
		source_state.slot_index,
		area_rows,
		area_cols,
		board_columns,
		board_size
	)
	var result := Rect2()
	var has_rect := false
	for slot_index in area_slots:
		var slot_card := game_manager.call("get_card_by_slot", slot_index) as Control
		if slot_card == null or not slot_card.is_visible_in_tree():
			continue

		var slot_control := slot_card.get_parent() as Control
		var slot_rect := (
			slot_control.get_global_rect()
			if slot_control != null
			else slot_card.get_global_rect()
		)
		if slot_rect.size == Vector2.ZERO:
			continue
		result = result.merge(slot_rect) if has_rect else slot_rect
		has_rect = true

	return result if has_rect else Rect2()
