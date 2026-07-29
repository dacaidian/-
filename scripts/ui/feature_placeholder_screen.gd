extends Control
class_name FeaturePlaceholderScreen

signal back_requested

@onready var content_panel: PanelContainer = %ContentPanel
@onready var page_title: Label = %PageTitle
@onready var empty_title: Label = %EmptyTitle
@onready var empty_message: Label = %EmptyMessage
@onready var back_button: Button = %BackButton

var _title_text := ""
var _empty_title_text := ""
var _empty_message_text := ""


func _ready() -> void:
	content_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_panel_style(ApplicationUiStyle.BLUE)
	)
	ApplicationUiStyle.style_compact_button(back_button, ApplicationUiStyle.GOLD)
	back_button.pressed.connect(func(): back_requested.emit())
	_apply_content()
	back_button.grab_focus.call_deferred()


func configure(title_text: String, empty_title_text: String, empty_message_text: String) -> void:
	_title_text = title_text
	_empty_title_text = empty_title_text
	_empty_message_text = empty_message_text
	if is_node_ready():
		_apply_content()


func _apply_content() -> void:
	page_title.text = _title_text
	empty_title.text = _empty_title_text
	empty_message.text = _empty_message_text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
