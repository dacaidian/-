extends Control
class_name StartMenu

const PLAYER_COUNT := 2

@export var cards_json_path := "res://data/cards.json"
@export var battle_scene_path := "res://main.tscn"
@export var player_names: Array[String] = ["Player 1", "Player 2"]

var card_database := CardDatabase.new()
var match_setup := MatchSetup.new()
var faction_ids: Array[String] = []
var player_panels: Array = []

@onready var start_button: Button = $"RootMargin/VBoxContainer/Footer/StartButton"
@onready var warning_label: Label = $"RootMargin/VBoxContainer/Footer/WarningLabel"
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if not card_database.load_from_json(cards_json_path):
		push_error("入口页无法加载卡牌数据")
		return

	faction_ids = card_database.get_playable_faction_ids()
	match_setup.initialize_defaults(card_database, faction_ids, player_names, PLAYER_COUNT)

	var selection_area := get_node("RootMargin/VBoxContainer/SelectionArea")
	player_panels = [
		selection_area.get_node("PlayerPanel0"),
		selection_area.get_node("PlayerPanel1"),
	]

	var panel_tints := [
		Color(0.15, 0.20, 0.24, 0.86),
		Color(0.24, 0.16, 0.20, 0.86),
	]

	for index in range(PLAYER_COUNT):
		var panel = player_panels[index]
		panel.panel_tint = panel_tints[index]
		panel.setup(index, card_database, match_setup, faction_ids)
		panel.faction_selected.connect(_on_panel_faction_selected)
		panel.hero_selected.connect(_on_panel_hero_selected)
		panel.control_type_selected.connect(_on_panel_control_type_selected)
		panel.ai_difficulty_selected.connect(_on_panel_ai_difficulty_selected)

	start_button.pressed.connect(_on_start_pressed)
	refresh_start_button()
	_add_ambient_lighting()
	_setup_animations()


func _add_ambient_lighting() -> void:
	_add_ambient_particle_layer(
		"AmbientDust",
		Color(0.95, 0.72, 0.42, 0.20),
		Color(0.95, 0.72, 0.42, 0.0),
		10,
		14.0,
		Vector2(900, 620),
		Vector2(0, -1),
		Vector2(0, -0.8),
		Vector2(4.0, 10.0),
		Vector2(0.20, 0.46)
	)
	_add_ambient_particle_layer(
		"AmbientAsh",
		Color(0.62, 0.45, 0.30, 0.12),
		Color(0.62, 0.45, 0.30, 0.0),
		18,
		18.0,
		Vector2(960, 700),
		Vector2(0.16, -1),
		Vector2(0, 0.25),
		Vector2(2.0, 6.0),
		Vector2(0.10, 0.28)
	)


func _add_ambient_particle_layer(
	layer_name: String,
	center_color: Color,
	edge_color: Color,
	amount: int,
	lifetime: float,
	emission_extents: Vector2,
	direction: Vector2,
	gravity: Vector2,
	velocity_range: Vector2,
	scale_range: Vector2
) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, center_color)
	gradient.set_color(1, edge_color)

	var particle_texture := GradientTexture2D.new()
	particle_texture.gradient = gradient
	particle_texture.width = 18
	particle_texture.height = 18
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(0.72, 0.5)

	var particles := CPUParticles2D.new()
	particles.name = layer_name
	particles.z_index = 1
	particles.position = Vector2(960, 720)
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = false
	particles.preprocess = lifetime * 0.88
	particles.explosiveness = 0.0
	particles.randomness = 0.72
	particles.speed_scale = 0.18
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = emission_extents
	particles.direction = direction.normalized()
	particles.spread = 24.0
	particles.gravity = gravity
	particles.initial_velocity_min = velocity_range.x
	particles.initial_velocity_max = velocity_range.y
	particles.scale_amount_min = scale_range.x
	particles.scale_amount_max = scale_range.y
	particles.angular_velocity_min = -6.0
	particles.angular_velocity_max = 6.0
	particles.color = Color(1.0, 1.0, 1.0, 1.0)
	particles.texture = particle_texture
	add_child(particles)
	move_child(particles, 3)


func _setup_animations() -> void:
	if animation_player == null:
		return
	var lib := AnimationLibrary.new()

	var entrance := Animation.new()
	entrance.length = 0.6
	entrance.add_track(Animation.TYPE_VALUE)
	entrance.track_set_path(0, ".:modulate")
	entrance.track_insert_key(0, 0.0, Color(1, 1, 1, 0))
	entrance.track_insert_key(0, 0.6, Color(1, 1, 1, 1))
	lib.add_animation("entrance", entrance)

	var breathe := Animation.new()
	breathe.length = 3.0
	breathe.loop_mode = Animation.LOOP_LINEAR
	breathe.add_track(Animation.TYPE_VALUE)
	breathe.track_set_path(0, "RootMargin/VBoxContainer/Header/TextureRect/TitleLabel:scale")
	breathe.track_insert_key(0, 0.0, Vector2(1, 1))
	breathe.track_insert_key(0, 1.5, Vector2(1.03, 1.03))
	breathe.track_insert_key(0, 3.0, Vector2(1, 1))
	lib.add_animation("title_breathe", breathe)

	animation_player.add_animation_library("", lib)
	animation_player.play("entrance")
	animation_player.queue("title_breathe")


func refresh_all_panels() -> void:
	for panel in player_panels:
		panel.refresh_all()


func refresh_start_button() -> void:
	var can_start := match_setup.can_start()
	start_button.disabled = not can_start
	warning_label.text = "" if can_start else match_setup.get_start_warning(faction_ids)


func _on_panel_faction_selected(player_index: int, faction_id: String) -> void:
	match_setup.set_faction(player_index, faction_id, faction_ids, card_database)
	refresh_all_panels()
	refresh_start_button()


func _on_panel_hero_selected(player_index: int, hero_id: String) -> void:
	match_setup.set_hero(player_index, hero_id)
	player_panels[player_index].refresh_preview()
	refresh_start_button()


func _on_panel_control_type_selected(player_index: int, is_ai: bool) -> void:
	match_setup.set_ai_control(player_index, is_ai)
	player_panels[player_index].refresh_control_type_select()
	refresh_start_button()


func _on_panel_ai_difficulty_selected(player_index: int, difficulty: String) -> void:
	match_setup.set_ai_difficulty(player_index, difficulty)


func _on_start_pressed() -> void:
	if not match_setup.can_start():
		return

	var battle_scene := load(battle_scene_path) as PackedScene
	if battle_scene == null:
		push_error("找不到战斗场景: %s" % battle_scene_path)
		return

	var battle_root := battle_scene.instantiate()
	var game_manager := battle_root.get_node_or_null("GameManager") as GameManager
	if game_manager == null:
		push_error("战斗场景缺少 GameManager")
		battle_root.queue_free()
		return

	game_manager.player_faction_ids = match_setup.player_faction_ids.duplicate()
	game_manager.selected_hero_card_ids = match_setup.selected_hero_card_ids.duplicate()
	game_manager.player_names = match_setup.player_names.duplicate()
	game_manager.player_ai_flags = match_setup.player_ai_flags.duplicate()
	game_manager.player_ai_difficulties = match_setup.player_ai_difficulties.duplicate()

	get_tree().root.add_child(battle_root)
	get_tree().current_scene = battle_root
	queue_free()
