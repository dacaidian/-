extends RefCounted
class_name BoardViewToggleController

const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

const ACCENT := Color(0.48, 0.78, 0.90, 1.0)
const OUTER_GAP := 6.0
const SCREEN_MARGIN := 4.0
const TOGGLE_SIZE := Vector2(196.0, 34.0)

var game_manager: Node
var game_root: Control
var card_board: Control
var toggle: CheckButton
var layout_pending := false


func setup(
	new_game_manager: Node,
	new_game_root: Control,
	new_card_board: Control,
	new_toggle: CheckButton
) -> void:
	game_manager = new_game_manager
	game_root = new_game_root
	card_board = new_card_board
	toggle = new_toggle
	if game_root == null or card_board == null or toggle == null:
		return

	configure_toggle_style()
	if not toggle.toggled.is_connected(_on_toggle_toggled):
		toggle.toggled.connect(_on_toggle_toggled)
	if card_board.has_signal("view_mode_changed"):
		var mode_callable := Callable(self, "_on_board_view_mode_changed")
		if not card_board.is_connected("view_mode_changed", mode_callable):
			card_board.connect("view_mode_changed", mode_callable)
	if not card_board.resized.is_connected(schedule_layout):
		card_board.resized.connect(schedule_layout)
	if not game_root.resized.is_connected(schedule_layout):
		game_root.resized.connect(schedule_layout)

	sync_from_board()
	schedule_layout()


func configure_toggle_style() -> void:
	toggle.tooltip_text = "切换中央 5×5 与包含飞行外环的完整 7×7 战场。"
	toggle.custom_minimum_size = TOGGLE_SIZE
	toggle.z_index = 3050
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.add_theme_color_override("font_color", RightSideHudStyleScript.PRIMARY_TEXT)
	toggle.add_theme_color_override("font_hover_color", Color.WHITE)
	toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
	toggle.add_theme_color_override("font_disabled_color", RightSideHudStyleScript.MUTED_TEXT)
	toggle.add_theme_stylebox_override("normal", RightSideHudStyleScript.create_button_style(ACCENT))
	toggle.add_theme_stylebox_override("hover", RightSideHudStyleScript.create_button_style(ACCENT, true))
	toggle.add_theme_stylebox_override("pressed", RightSideHudStyleScript.create_button_style(ACCENT, false, true))
	toggle.add_theme_stylebox_override("hover_pressed", RightSideHudStyleScript.create_button_style(ACCENT, true, true))
	toggle.add_theme_stylebox_override("disabled", RightSideHudStyleScript.create_disabled_button_style())


func sync_from_board() -> void:
	if toggle == null or card_board == null:
		return
	var is_full_view := bool(card_board.get("is_full_board_view"))
	toggle.set_pressed_no_signal(is_full_view)
	toggle.text = "完整战场 7×7" if is_full_view else "中央战场 5×5"


func schedule_layout() -> void:
	if layout_pending or toggle == null:
		return
	layout_pending = true
	toggle.get_tree().process_frame.connect(_position_toggle, CONNECT_ONE_SHOT)


func _position_toggle() -> void:
	layout_pending = false
	if game_root == null or card_board == null or toggle == null:
		return
	if not is_instance_valid(game_root) or not is_instance_valid(card_board) or not is_instance_valid(toggle):
		return

	var board_rect := card_board.get_global_rect()
	var toggle_size := Vector2(
		maxf(toggle.size.x, toggle.custom_minimum_size.x),
		maxf(toggle.size.y, toggle.custom_minimum_size.y)
	)
	var root_rect := game_root.get_global_rect()
	var desired_position := Vector2(
		board_rect.get_center().x - toggle_size.x * 0.5,
		board_rect.position.y - toggle_size.y - OUTER_GAP
	)
	desired_position.x = clampf(
		desired_position.x,
		root_rect.position.x + SCREEN_MARGIN,
		root_rect.end.x - toggle_size.x - SCREEN_MARGIN
	)
	desired_position.y = clampf(
		desired_position.y,
		root_rect.position.y + SCREEN_MARGIN,
		root_rect.end.y - toggle_size.y - SCREEN_MARGIN
	)
	toggle.global_position = desired_position


func _on_toggle_toggled(enabled: bool) -> void:
	if card_board == null or toggle == null:
		return
	if (
		game_manager != null
		and game_manager.has_method("is_game_busy")
		and bool(game_manager.call("is_game_busy"))
	):
		sync_from_board()
		return
	if game_manager != null and game_manager.has_method("prepare_board_view_change"):
		game_manager.call("prepare_board_view_change")
	elif game_manager != null and game_manager.has_method("cancel_interaction"):
		game_manager.call("cancel_interaction")
	card_board.call("set_full_board_view", enabled)


func _on_board_view_mode_changed(_is_full_view: bool) -> void:
	sync_from_board()
	schedule_layout()
