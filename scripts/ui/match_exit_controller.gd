extends RefCounted
class_name MatchExitController

signal surrender_requested

var game_manager: GameManager
var layer: CanvasLayer
var surrender_button: Button
var confirmation_dialog: ConfirmationDialog


func setup(_root: Control, manager: GameManager) -> void:
	if manager == null:
		return

	game_manager = manager
	layer = CanvasLayer.new()
	layer.name = "MatchExitLayer"
	layer.layer = 3100
	game_manager.add_child(layer)

	surrender_button = Button.new()
	surrender_button.name = "SurrenderButton"
	surrender_button.text = "投降"
	surrender_button.tooltip_text = "结束本局并判定对方获胜"
	surrender_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	surrender_button.position = Vector2(28.0, 24.0)
	ApplicationUiStyle.style_compact_button(surrender_button, ApplicationUiStyle.DANGER)
	surrender_button.pressed.connect(_show_confirmation)
	layer.add_child(surrender_button)

	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.name = "SurrenderConfirmation"
	confirmation_dialog.title = "确认投降"
	confirmation_dialog.ok_button_text = "确认投降"
	confirmation_dialog.cancel_button_text = "继续对局"
	confirmation_dialog.confirmed.connect(_confirm_surrender)
	layer.add_child(confirmation_dialog)


func update(can_surrender: bool) -> void:
	if surrender_button == null:
		return
	surrender_button.disabled = not can_surrender
	surrender_button.visible = game_manager != null and not game_manager.is_game_over


func _show_confirmation() -> void:
	if game_manager == null or not game_manager.can_surrender():
		return

	var surrendering_player := game_manager.get_surrendering_player()
	var player_name := (
		surrendering_player.display_name
		if surrendering_player != null
		else "当前玩家"
	)
	confirmation_dialog.dialog_text = "%s 将投降，本局立即判定对方获胜。" % player_name
	confirmation_dialog.popup_centered(Vector2i(470, 190))


func _confirm_surrender() -> void:
	if game_manager == null or not game_manager.can_surrender():
		return
	surrender_requested.emit()
