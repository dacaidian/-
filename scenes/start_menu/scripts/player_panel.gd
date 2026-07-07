extends PanelContainer
class_name PlayerPanel

signal faction_selected(player_index: int, faction_id: String)
signal hero_selected(player_index: int, hero_id: String)
signal control_type_selected(player_index: int, is_ai: bool)
signal ai_difficulty_selected(player_index: int, difficulty: String)

var player_index := 0
var is_refreshing := false

var _card_database: CardDatabase
var _match_setup: MatchSetup
var _faction_ids: Array[String] = []

@export var panel_tint := Color(0.15, 0.20, 0.24, 0.86)

@onready var logo_texture: TextureRect = $MarginContainer/VBoxContainer/LogoFrame/LogoTexture
@onready var hero_texture: TextureRect = $MarginContainer/VBoxContainer/HeroTexture
@onready var player_label: Label = $MarginContainer/VBoxContainer/PlayerLabel
@onready var faction_label: Label = $MarginContainer/VBoxContainer/FactionLabel
@onready var hero_label: Label = $MarginContainer/VBoxContainer/HeroLabel
@onready var attached_label: Label = $MarginContainer/VBoxContainer/AttachedLabel
@onready var faction_select: OptionButton = $MarginContainer/VBoxContainer/FactionSelect
@onready var hero_select: OptionButton = $MarginContainer/VBoxContainer/HeroSelect
@onready var control_type_select: OptionButton = $MarginContainer/VBoxContainer/ControlTypeSelect
@onready var ai_difficulty_select: OptionButton = $MarginContainer/VBoxContainer/AIDifficultySelect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_init_control_type_select()
	_init_ai_difficulty_select()
	_connect_signals()


func _init_control_type_select() -> void:
	control_type_select.add_item("玩家操作")
	control_type_select.set_item_metadata(0, false)
	control_type_select.add_item("AI 控制")
	control_type_select.set_item_metadata(1, true)


func _init_ai_difficulty_select() -> void:
	ai_difficulty_select.add_item("AI 难度：简单")
	ai_difficulty_select.set_item_metadata(0, "easy")
	ai_difficulty_select.add_item("AI 难度：普通")
	ai_difficulty_select.set_item_metadata(1, "normal")
	ai_difficulty_select.add_item("AI 难度：困难")
	ai_difficulty_select.set_item_metadata(2, "hard")
	ai_difficulty_select.select(1)


func _connect_signals() -> void:
	faction_select.item_selected.connect(_on_faction_select_item_selected)
	hero_select.item_selected.connect(_on_hero_select_item_selected)
	control_type_select.item_selected.connect(_on_control_type_select_item_selected)
	ai_difficulty_select.item_selected.connect(_on_ai_difficulty_select_item_selected)
	logo_texture.mouse_entered.connect(_on_logo_texture_mouse_entered)


func setup(p_index: int, card_database: CardDatabase, match_setup: MatchSetup, faction_ids: Array[String]) -> void:
	player_index = p_index
	_card_database = card_database
	_match_setup = match_setup
	_faction_ids = faction_ids
	apply_panel_tint()
	refresh_all()


func apply_panel_tint() -> void:
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style == null:
		return
	style.bg_color = panel_tint
	add_theme_stylebox_override("panel", style)


func refresh_all() -> void:
	is_refreshing = true
	refresh_player_label()
	refresh_faction_select()
	refresh_hero_select()
	refresh_preview()
	refresh_control_type_select()
	is_refreshing = false


func refresh_player_label() -> void:
	var names: Array = _match_setup.player_names
	player_label.text = names[player_index] if player_index < names.size() else "Player %d" % (player_index + 1)


func refresh_faction_select() -> void:
	faction_select.clear()
	var opponent_index := 1 - player_index
	var opponent_faction_id := _match_setup.get_faction_id(opponent_index)
	var selected_index := 0

	for index in range(_faction_ids.size()):
		var faction_id := _faction_ids[index]
		faction_select.add_item(_card_database.get_faction_display_name(faction_id))
		faction_select.set_item_metadata(index, faction_id)
		if faction_id == opponent_faction_id:
			faction_select.set_item_disabled(index, true)
		if faction_id == _match_setup.get_faction_id(player_index):
			selected_index = index

	faction_select.select(selected_index)


func refresh_hero_select() -> void:
	hero_select.clear()
	var heroes := _card_database.get_faction_heroes(_match_setup.get_faction_id(player_index))
	var selected_hero_id := _match_setup.get_hero_id(player_index)
	if selected_hero_id == "" and not heroes.is_empty():
		selected_hero_id = heroes[0].id
		_match_setup.set_hero(player_index, selected_hero_id)

	var selected_index := 0
	for index in range(heroes.size()):
		var hero := heroes[index]
		hero_select.add_item(hero.display_name)
		hero_select.set_item_metadata(index, hero.id)
		if hero.id == selected_hero_id:
			selected_index = index

	hero_select.disabled = heroes.is_empty()
	if not heroes.is_empty():
		hero_select.select(selected_index)


func refresh_preview() -> void:
	var faction_id := _match_setup.get_faction_id(player_index)
	var hero_id := _match_setup.get_hero_id(player_index)
	faction_label.text = _card_database.get_faction_display_name(faction_id)
	logo_texture.texture = load_faction_logo(faction_id)

	var hero := _card_database.get_card(hero_id)
	if hero != null:
		play_hero_switch_animation()
		hero_texture.texture = get_hero_preview_texture(hero)
		hero_label.text = hero.description if hero.description != "" else hero.display_name
	else:
		hero_texture.texture = null
		hero_label.text = "该种族暂未配置英雄"

	var attached_count := _card_database.get_attached_card_ids(faction_id, hero_id).size()
	attached_label.text = "英雄附属牌：%d" % attached_count


func refresh_control_type_select() -> void:
	var is_ai := _match_setup.get_ai_flag(player_index)
	control_type_select.select(0 if not is_ai else 1)
	ai_difficulty_select.visible = is_ai

	if is_ai:
		var difficulty := _match_setup.get_ai_difficulty(player_index)
		match difficulty:
			"easy":   ai_difficulty_select.select(0)
			"normal": ai_difficulty_select.select(1)
			"hard":   ai_difficulty_select.select(2)
			_:        ai_difficulty_select.select(1)


func load_faction_logo(faction_id: String) -> Texture2D:
	var folder_name := _card_database.get_faction_display_name(faction_id)
	var logo_path := "res://assets/img/%s/logo.png" % folder_name
	if ResourceLoader.exists(logo_path):
		return load(logo_path) as Texture2D
	return null


func get_hero_preview_texture(hero: CardData) -> Texture2D:
	if hero == null:
		return null
	if hero.table_texture != null:
		return hero.table_texture
	return hero.front_texture


func play_hero_switch_animation() -> void:
	if animation_player != null and animation_player.has_animation("hero_switch"):
		animation_player.play("hero_switch")


func play_logo_pulse() -> void:
	if animation_player != null and animation_player.has_animation("logo_pulse"):
		animation_player.play("logo_pulse")


func _on_faction_select_item_selected(item_index: int) -> void:
	if is_refreshing:
		return
	var faction_id := str(faction_select.get_item_metadata(item_index))
	if faction_id == "":
		return
	faction_selected.emit(player_index, faction_id)


func _on_hero_select_item_selected(item_index: int) -> void:
	if is_refreshing:
		return
	var hero_id := str(hero_select.get_item_metadata(item_index))
	hero_selected.emit(player_index, hero_id)


func _on_control_type_select_item_selected(item_index: int) -> void:
	if is_refreshing:
		return
	var is_ai := bool(control_type_select.get_item_metadata(item_index))
	control_type_selected.emit(player_index, is_ai)


func _on_ai_difficulty_select_item_selected(item_index: int) -> void:
	if is_refreshing:
		return
	var difficulty := str(ai_difficulty_select.get_item_metadata(item_index))
	ai_difficulty_selected.emit(player_index, difficulty)


func _on_logo_texture_mouse_entered() -> void:
	play_logo_pulse()
