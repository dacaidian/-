extends Control
class_name MainMenuScreen

signal start_game_requested
signal match_history_requested
signal card_collection_requested
signal exit_game_requested

@onready var menu_panel: PanelContainer = %MenuPanel
@onready var start_button: Button = %StartGameButton
@onready var history_button: Button = %MatchHistoryButton
@onready var collection_button: Button = %CardCollectionButton
@onready var exit_button: Button = %ExitGameButton
@onready var exit_confirmation: ConfirmationDialog = %ExitConfirmation


func _ready() -> void:
	menu_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_panel_style(ApplicationUiStyle.GOLD)
	)
	ApplicationUiStyle.style_menu_button(start_button, ApplicationUiStyle.GOLD, true)
	ApplicationUiStyle.style_menu_button(history_button, ApplicationUiStyle.BLUE)
	ApplicationUiStyle.style_menu_button(collection_button, ApplicationUiStyle.BLUE)
	ApplicationUiStyle.style_menu_button(exit_button, ApplicationUiStyle.DANGER)

	start_button.pressed.connect(func(): start_game_requested.emit())
	history_button.pressed.connect(func(): match_history_requested.emit())
	collection_button.pressed.connect(func(): card_collection_requested.emit())
	exit_button.pressed.connect(_show_exit_confirmation)
	exit_confirmation.confirmed.connect(func(): exit_game_requested.emit())
	start_button.grab_focus.call_deferred()


func _show_exit_confirmation() -> void:
	exit_confirmation.title = "退出游戏"
	exit_confirmation.dialog_text = "确定要退出 War Card 吗？"
	exit_confirmation.ok_button_text = "退出"
	exit_confirmation.cancel_button_text = "取消"
	exit_confirmation.popup_centered(Vector2i(420, 180))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_exit_confirmation()
		get_viewport().set_input_as_handled()
