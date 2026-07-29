extends Control
class_name GameShell

signal screen_changed(screen_id: String)

const SCREEN_MAIN_MENU := "main_menu"
const SCREEN_FACTION_SELECTION := "faction_selection"
const SCREEN_MATCH_HISTORY := "match_history"
const SCREEN_CARD_COLLECTION := "card_collection"
const SCREEN_MATCH := "match"

@export_file("*.tscn") var main_menu_scene_path := "res://scenes/main_menu/main_menu.tscn"
@export_file("*.tscn") var faction_selection_scene_path := "res://scenes/start_menu/start_menu.tscn"
@export_file("*.tscn") var feature_placeholder_scene_path := "res://scenes/ui/feature_placeholder_screen.tscn"
@export_file("*.tscn") var card_collection_scene_path := "res://scenes/ui/card_collection_screen.tscn"
@export_file("*.tscn") var battle_scene_path := "res://main.tscn"

@onready var screen_host: Control = %ScreenHost

var current_screen: Node
var current_screen_id := ""
var last_match_result: MatchResult


func _ready() -> void:
	show_main_menu()


func show_main_menu(_result: MatchResult = null) -> void:
	if _result != null:
		last_match_result = _result

	var screen := _instantiate_scene(main_menu_scene_path)
	if screen == null:
		return

	screen.start_game_requested.connect(show_faction_selection)
	screen.match_history_requested.connect(show_match_history)
	screen.card_collection_requested.connect(show_card_collection)
	screen.exit_game_requested.connect(_exit_game)
	_mount_screen(screen, SCREEN_MAIN_MENU)


func show_faction_selection() -> void:
	var screen := _instantiate_scene(faction_selection_scene_path)
	if screen == null:
		return

	screen.match_start_requested.connect(_start_match)
	screen.back_requested.connect(show_main_menu)
	_mount_screen(screen, SCREEN_FACTION_SELECTION)


func show_match_history() -> void:
	_show_placeholder(
		SCREEN_MATCH_HISTORY,
		"牌局历史",
		"暂无牌局记录",
		"后续牌局记录将在这里按时间排列。"
	)


func show_card_collection() -> void:
	var screen := _instantiate_scene(card_collection_scene_path)
	if screen == null:
		return

	screen.back_requested.connect(show_main_menu)
	_mount_screen(screen, SCREEN_CARD_COLLECTION)


func _show_placeholder(
	screen_id: String,
	title_text: String,
	empty_title_text: String,
	empty_message_text: String
) -> void:
	var screen := _instantiate_scene(feature_placeholder_scene_path)
	if screen == null:
		return

	screen.configure(title_text, empty_title_text, empty_message_text)
	screen.back_requested.connect(show_main_menu)
	_mount_screen(screen, screen_id)


func _start_match(match_setup: MatchSetup) -> void:
	if match_setup == null or not match_setup.can_start():
		return

	var battle_root := _instantiate_scene(battle_scene_path)
	if battle_root == null:
		return

	var game_manager := battle_root.get_node_or_null("GameManager") as GameManager
	if game_manager == null:
		push_error("战斗场景缺少 GameManager")
		battle_root.queue_free()
		return

	game_manager.configure_match(match_setup)
	game_manager.match_finished.connect(show_main_menu)
	_mount_screen(battle_root, SCREEN_MATCH)


func _mount_screen(screen: Node, screen_id: String) -> void:
	if screen == null or screen_host == null:
		return

	if current_screen != null and is_instance_valid(current_screen):
		screen_host.remove_child(current_screen)
		current_screen.queue_free()

	current_screen = screen
	current_screen_id = screen_id
	screen_host.add_child(screen)

	var control := screen as Control
	if control != null:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(control, "modulate:a", 1.0, 0.18)

	screen_changed.emit(screen_id)


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("无法加载应用页面: %s" % scene_path)
		return null
	return packed_scene.instantiate()


func _exit_game() -> void:
	get_tree().quit()
