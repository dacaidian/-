extends Node
class_name GameManager

const CardPoolViewControllerScript := preload("res://scripts/ui/card_pool_view_controller.gd")
const TurnStatusControllerScript := preload("res://scripts/ui/turn_status_controller.gd")
const FactionTimePanelControllerScript := preload("res://scripts/ui/faction_time_panel_controller.gd")
const FactionSkillPanelControllerScript := preload("res://scripts/ui/faction_skill_panel_controller.gd")
const HandDrawerControllerScript := preload("res://scripts/ui/hand_drawer_controller.gd")
const EquipmentDisplayControllerScript := preload("res://scripts/ui/equipment_display_controller.gd")
const RightSideHudLayoutControllerScript := preload("res://scripts/ui/right_side_hud_layout_controller.gd")
const AttackOccupyChoiceControllerScript := preload("res://scripts/ui/attack_occupy_choice_controller.gd")
const CardAnimationControllerScript := preload("res://scripts/ui/card_animation_controller.gd")
const GameAnimationResolverScript := preload("res://scripts/game/game_animation_resolver.gd")
const BoardPersistentVisualControllerScript := preload(
	"res://scripts/ui/board_persistent_visual_controller.gd"
)
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const BoardSlotResolverScript := preload("res://scripts/game/board_slot_resolver.gd")
const ActionHintResolverScript := preload("res://scripts/game/action_hint_resolver.gd")
const RevealResolverScript := preload("res://scripts/game/reveal_resolver.gd")
const HandInteractionControllerScript := preload("res://scripts/game/hand_interaction_controller.gd")
const DeathResolverScript := preload("res://scripts/game/death_resolver.gd")
const HandPassiveResolverScript := preload("res://scripts/game/hand_passive_resolver.gd")
const CardReserveResolverScript := preload("res://scripts/game/card_reserve_resolver.gd")
const VictoryResolverScript := preload("res://scripts/game/victory_resolver.gd")
const TriggerResolverScript := preload("res://scripts/game/trigger_resolver.gd")
const TurnTriggerResolverScript := preload("res://scripts/game/turn_trigger_resolver.gd")
const SpellCastTriggerResolverScript := preload("res://scripts/game/spell_cast_trigger_resolver.gd")
const StatusResolverScript := preload("res://scripts/game/status_resolver.gd")
const EquipmentTriggerResolverScript := preload("res://scripts/game/equipment_trigger_resolver.gd")
const BoardSlotEffectResolverScript := preload("res://scripts/game/board_slot_effect_resolver.gd")
const TargetStateResolverScript := preload("res://scripts/game/target_state_resolver.gd")
const BoardLayerResolverScript := preload("res://scripts/game/board_layer_resolver.gd")
const BoardMovementResolverScript := preload("res://scripts/game/board_movement_resolver.gd")
const FactionSkillResolverScript := preload("res://scripts/game/faction_skill_resolver.gd")
const TurnEventLedgerScript := preload("res://scripts/game/turn_event_ledger.gd")
const FactionRuntimeStateResolverScript := preload("res://scripts/game/faction_runtime_state_resolver.gd")
const KagunePowerResolverScript := preload("res://scripts/game/kagune_power_resolver.gd")
const GameHudCoordinatorScript := preload("res://scripts/game/game_hud_coordinator.gd")
const VictoryScreenControllerScript := preload("res://scripts/ui/victory_screen_controller.gd")
const AICommonScript := preload("res://scripts/ai/ai_common.gd")
const AIBoardEvaluatorScript := preload("res://scripts/ai/ai_board_evaluator.gd")
const AIHandEvaluatorScript := preload("res://scripts/ai/ai_hand_evaluator.gd")
const AIControllerScript := preload("res://scripts/ai/ai_controller.gd")

# GameManager 是战局编排入口。
# 它持有玩家、棋盘、牌池和交互状态，并串起回合、行动、死亡、补位等规则流程。
# 具体 UI 和动画表现委托给独立 Controller，避免规则主类继续膨胀。
@export var card_board_path: NodePath
@export var debug_panel_path: NodePath
@export var end_turn_button_path: NodePath
@export var card_pool_view_path: NodePath
@export var card_pool_animation_root_path: NodePath
@export var turn_status_panel_path: NodePath
@export var hand_drawer_panel_path: NodePath

# 静态卡牌配置文件路径。
@export var cards_json_path := "res://data/cards.json"

# 音频配置文件路径。背景音乐和音效 key 到资源路径的映射都在这里维护。
@export var audio_config_path := "res://data/audio.json"
@export var default_battle_bgm_key := "battle_default"

# 默认参战种族；入口选择页会覆盖这些值。
@export var player_faction_ids: Array[String] = ["silver_hand", "dalaran_council"]

# 入口选择页传入的英雄。为空时使用对应种族的第一个英雄。
@export var selected_hero_card_ids: Array[String] = []

# 中立牌库不属于任一玩家种族，但会与双方种族牌一起洗入公共牌池。
@export var neutral_faction_ids: Array[String] = ["neutral"]

# 所有卡牌默认使用的背面图片。
@export var default_back_texture_path := "res://assets/img/卡背/1.png"

# 两名玩家名称。启动时会转成 PlayerState。
@export var player_names: Array[String] = ["Player 1", "Player 2"]
@export var player_ai_flags: Array[bool] = []
@export var player_ai_difficulties: Array[String] = []
@export var player_max_flips_per_turn := 4
@export var spell_turn_mana_cost := 3
@export var ai_turn_watchdog_seconds := 18.0
@export var victory_resource_score := 80

# 棋盘尺寸。当前物理棋盘为 7x7；外圈是战场边缘，中间 5x5 是普通地面牌池区域。
@export var board_columns := 7
@export var board_rows := 7

# 卡牌移动动画时长。移动规则由 CardState / CardAction 决定，这里只负责表现。
@export var move_animation_duration := 0.24

# 卡牌攻击动画参数。攻击规则由 AttackAction 决定，这里只负责表现。
@export var attack_animation_duration := 0.26
@export var attack_lunge_distance := 54.0
@export var attack_target_shake_distance := 8.0
@export var ranged_attack_animation_duration := 0.34
@export var ranged_attack_projectile_size := Vector2(30, 10)
@export var ranged_attack_projectile_color := Color(0.55, 0.88, 1.0, 0.94)
@export var ranged_attack_projectile_glow_color := Color(0.24, 0.64, 1.0, 0.32)
@export var spell_animation_duration := 0.32
@export var heal_spell_effect_color := Color(0.38, 1.0, 0.52, 0.46)
@export var heal_spell_effect_glow_color := Color(0.52, 1.0, 0.62, 0.58)

# 公共牌池视觉和补位动画参数。
@export var card_pool_view_size := Vector2(150, 210)
@export var card_pool_view_margin := 28.0
@export var refill_animation_duration := 0.36

# 攻击击杀后的占领选择面板。
@export var occupy_choice_panel_size := Vector2(320, 132)

# 物理棋盘单元格。每个 BoardCell 拥有 ground_state 和 aerial_states。
var board_cells: Array[BoardCell] = []

# 棋盘地面层状态，索引与 BoardCell / CardSlot 顺序一致；保留给现有规则兼容。
var board_states: Array[CardState] = []
var aerial_board_states: Array[CardState] = []

# 与 board_states / aerial_board_states 一一对应的卡牌节点。
var board_cards: Array[Card] = []
var aerial_board_cards: Array[Card] = []

# 两名玩家的运行时状态。
var players: Array[PlayerState] = []

# 静态卡牌数据库，启动时从 JSON 初始化。
var card_database := CardDatabase.new()

# 卡牌效果注册表，负责把 JSON 中的效果 id 映射到代码逻辑。
var effect_registry := EffectRegistry.new()

# 卡牌行动注册表。
var action_registry := ActionRegistry.new()

# 玩家交互状态机。
var interaction_manager := InteractionManager.new()

# 持久化卡牌池。
var card_pool: CardPool

# 加载后的默认卡背资源。
var default_back_texture: Texture2D
var debug_panel: Node
var end_turn_button: Button
var action_menu_controller := ActionMenuController.new()
var card_pool_view_controller := CardPoolViewControllerScript.new()
var turn_status_controller := TurnStatusControllerScript.new()
var faction_time_panel_controller := FactionTimePanelControllerScript.new()
var faction_skill_panel_controller := FactionSkillPanelControllerScript.new()
var hand_drawer_controller := HandDrawerControllerScript.new()
var equipment_display_controller := EquipmentDisplayControllerScript.new()
var right_side_hud_layout_controller := RightSideHudLayoutControllerScript.new()
var attack_occupy_choice_controller := AttackOccupyChoiceControllerScript.new()
var card_animation_controller := CardAnimationControllerScript.new()
var game_animation_resolver := GameAnimationResolverScript.new()
var board_persistent_visual_controller: BoardPersistentVisualController
var audio_manager := AudioManagerScript.new()
var board_slot_resolver := BoardSlotResolverScript.new()
var action_hint_resolver := ActionHintResolverScript.new()
var reveal_resolver := RevealResolverScript.new()
var hand_interaction_controller := HandInteractionControllerScript.new()
var death_resolver := DeathResolverScript.new()
var hand_passive_resolver := HandPassiveResolverScript.new()
var card_reserve_resolver := CardReserveResolverScript.new()
var victory_resolver := VictoryResolverScript.new()
var trigger_resolver := TriggerResolverScript.new()
var turn_trigger_resolver := TurnTriggerResolverScript.new()
var spell_cast_trigger_resolver := SpellCastTriggerResolverScript.new()
var status_resolver := StatusResolverScript.new()
var equipment_trigger_resolver := EquipmentTriggerResolverScript.new()
var board_slot_effect_resolver := BoardSlotEffectResolverScript.new()
var target_state_resolver := TargetStateResolverScript.new()
var board_layer_resolver := BoardLayerResolverScript.new()
var board_movement_resolver := BoardMovementResolverScript.new()
var faction_skill_resolver := FactionSkillResolverScript.new()
var turn_event_ledger := TurnEventLedgerScript.new()
var faction_runtime_state_resolver := FactionRuntimeStateResolverScript.new()
var kagune_power_resolver := KagunePowerResolverScript.new()
var game_hud_coordinator := GameHudCoordinatorScript.new()
var victory_screen_controller: VictoryScreenController
var ai_controller := AIControllerScript.new()

var current_player_index := 0
var turn_number := 1
var is_spell_turn_active := false
var is_game_over := false
var winner_player_id := ""
var is_resolving_card_action := false
var is_executing_action := false
var is_ai_turn_scheduled := false
var ai_turn_watchdog_token := 0

func _ready() -> void:
	connect_end_turn_button()
	connect_interaction_manager()
	connect_viewport_resize()
	setup_action_menu.call_deferred()

	if not load_static_card_data():
		return

	initialize_players()
	setup_card_animation_controller()
	setup_audio_manager()
	game_hud_coordinator.setup(self)
	game_hud_coordinator.refresh_all(self)
	card_pool = create_initial_card_pool()
	initialize_board()
	setup_card_pool_view()
	setup_board_persistent_visuals()
	update_card_pool_view()
	start_battle_music()
	schedule_ai_turn_if_needed()


func _input(event: InputEvent) -> void:
	if is_game_over:
		return

	if _is_ai_controlling():
		return

	# 鍥炲悎缁撴潫鍚庡垏鎹㈠綋鍓嶆搷浣滀汉銆?	# Switch the active player after ending the turn.
	# Switch the active player after ending the turn.
	if is_game_busy():
		return

	if interaction_manager.mode == InteractionManager.Mode.SELECTING_ACTION_TARGET and should_return_to_action_menu(event):
		return_to_action_menu()
		get_viewport().set_input_as_handled()
		return

	if interaction_manager.mode == InteractionManager.Mode.CARD_SELECTED and should_cancel_card_selection(event):
		cancel_interaction()
		get_viewport().set_input_as_handled()
		return


func should_return_to_action_menu(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true

	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == KEY_ESCAPE

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_RIGHT

	return false


func should_cancel_card_selection(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_RIGHT

	return false


func is_game_busy() -> bool:
	return is_game_over or is_resolving_card_action or is_executing_action


func _is_ai_controlling() -> bool:
	var player := get_current_player()
	return player != null and player.is_ai


func connect_viewport_resize() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	if not viewport.size_changed.is_connected(update_card_pool_view):
		viewport.size_changed.connect(update_card_pool_view)
	if not viewport.size_changed.is_connected(update_equipment_display_view):
		viewport.size_changed.connect(update_equipment_display_view)
	if not viewport.size_changed.is_connected(update_faction_time_panel_view):
		viewport.size_changed.connect(update_faction_time_panel_view)
	if not viewport.size_changed.is_connected(update_faction_skill_panel_view):
		viewport.size_changed.connect(update_faction_skill_panel_view)
	if not viewport.size_changed.is_connected(update_right_side_hud_layout):
		viewport.size_changed.connect(update_right_side_hud_layout)


func connect_end_turn_button() -> void:
	end_turn_button = get_node_or_null(end_turn_button_path) as Button
	if end_turn_button == null:
		return

	if not end_turn_button.pressed.is_connected(end_turn):
		end_turn_button.pressed.connect(end_turn)


func setup_action_menu() -> void:
	action_menu_controller.setup(get_parent())
	if not action_menu_controller.action_requested.is_connected(_on_action_menu_action_requested):
		action_menu_controller.action_requested.connect(_on_action_menu_action_requested)
	if not action_menu_controller.cancel_requested.is_connected(cancel_interaction):
		action_menu_controller.cancel_requested.connect(cancel_interaction)
	update_action_menu()


func initialize_players() -> void:
	players.clear()

	for index in range(player_names.size()):
		var player := PlayerState.new()
		player.setup("player_%d" % (index + 1), player_names[index])
		if index < player_faction_ids.size():
			player.set_faction(player_faction_ids[index], get_faction_display_name(player_faction_ids[index]))
			player.set_selected_hero(get_selected_hero_for_player(index))
			player.setup_faction_runtime_state(card_database.get_faction_runtime_state_config(player_faction_ids[index]))
			player.setup_faction_resources(card_database.get_faction_resource_configs(player_faction_ids[index]))
			player.setup_faction_skills(card_database.get_faction_skill_configs(player_faction_ids[index]))
		player.is_ai = get_player_ai_flag(index)
		player.ai_difficulty = get_player_ai_difficulty(index)
		player.set_base_flips_per_turn(player_max_flips_per_turn)
		player.remaining_flips = player.max_flips_per_turn
		player.max_mana = PlayerState.MANA_CAPACITY
		player.mana = 0
		player.state_changed.connect(_on_player_state_changed)
		players.append(player)

	for index in range(players.size()):
		add_starting_hand_cards_for_player(players[index], index)
		refresh_hand_passives_for_player(players[index], false)

	if not players.is_empty():
		turn_event_ledger.begin_turn(players[current_player_index].id)
		players[current_player_index].start_turn()
		card_reserve_resolver.advance_owner_turn(players[current_player_index], self)


func add_starting_hand_cards_for_player(player: PlayerState, player_index: int) -> void:
	if player == null or player_index < 0 or player_index >= player_faction_ids.size():
		return

	var faction_id := player_faction_ids[player_index]
	var hero_id := get_selected_hero_for_player(player_index)
	for card_data in card_database.get_starting_hand_cards(faction_id, hero_id):
		player.add_to_hand(card_data)


func load_static_card_data() -> bool:
	# CardDatabase parses JSON and caches CardData.
	if not card_database.load_from_json(cards_json_path):
		return false

	card_database.load_test_config("res://data/test_config.json")
	_apply_test_game_params()

	# Runtime card back resource injected into each CardState.
	default_back_texture = load(default_back_texture_path) as Texture2D
	return true


func _apply_test_game_params() -> void:
	if not card_database.is_test_mode:
		return
	spell_turn_mana_cost = card_database.get_test_game_param("spell_turn_mana_cost", spell_turn_mana_cost)
	victory_resource_score = card_database.get_test_game_param("victory_resource_score", victory_resource_score)


func create_initial_card_pool() -> CardPool:
	# Build the shared pool from selected factions, heroes, and neutral pools.
	return CardPool.from_match_selection(
		player_faction_ids,
		selected_hero_card_ids,
		neutral_faction_ids,
		card_database
	)


func get_faction_display_name(faction_id: String) -> String:
	return card_database.get_faction_display_name(faction_id)


func get_selected_hero_for_player(player_index: int) -> String:
	if player_index >= 0 and player_index < selected_hero_card_ids.size():
		var selected_hero_id := selected_hero_card_ids[player_index]
		if selected_hero_id != "":
			return selected_hero_id

	if player_index >= 0 and player_index < player_faction_ids.size():
		return card_database.get_default_hero_id(player_faction_ids[player_index])

	return ""


func get_player_ai_flag(player_index: int) -> bool:
	if player_index >= 0 and player_index < player_ai_flags.size():
		return player_ai_flags[player_index]
	return false


func get_player_ai_difficulty(player_index: int) -> String:
	if player_index >= 0 and player_index < player_ai_difficulties.size():
		var difficulty := player_ai_difficulties[player_index]
		if difficulty in ["easy", "normal", "hard"]:
			return difficulty
	return "normal"


func initialize_board() -> void:
	prepare_card_board_view()
	board_cards = find_board_cards()
	aerial_board_cards = find_board_cards("AerialCard")
	board_states.clear()
	aerial_board_states.clear()
	board_cells.clear()

	if card_pool == null:
		push_error("GameManager initialization failed: card pool was not created.")
		return

	for index in range(board_cards.size()):
		var card: Card = board_cards[index]
		var card_data: CardData = null

		if is_land_slot(index) and not card_pool.is_empty():
			card_data = card_pool.draw_random()

		var state := create_initial_card_state(card_data, index)
		state.is_interactable = is_land_slot(index)
		var aerial_state := create_initial_card_state(null, index)
		aerial_state.is_interactable = true
		var cell := create_board_cell(index, state)
		cell.aerial_states.append(aerial_state)

		board_cells.append(cell)
		board_states.append(state)
		aerial_board_states.append(aerial_state)
		state.state_changed.connect(_on_card_state_changed)
		aerial_state.state_changed.connect(_on_card_state_changed)
		card.bind_state(state)
		var aerial_card: Card = aerial_board_cards[index] if index < aerial_board_cards.size() else null
		if aerial_card != null:
			aerial_card.bind_state(aerial_state)

		# Click events are routed through GameManager; Card does not mutate state directly.
		if not card.clicked.is_connected(_on_card_clicked):
			card.clicked.connect(_on_card_clicked)
		if not card.mouse_entered_card.is_connected(_on_card_hovered):
			card.mouse_entered_card.connect(_on_card_hovered)
		if not card.mouse_exited_card.is_connected(_on_card_unhovered):
			card.mouse_exited_card.connect(_on_card_unhovered)
		if aerial_card != null:
			if not aerial_card.clicked.is_connected(_on_card_clicked):
				aerial_card.clicked.connect(_on_card_clicked)
			if not aerial_card.mouse_entered_card.is_connected(_on_card_hovered):
				aerial_card.mouse_entered_card.connect(_on_card_hovered)
			if not aerial_card.mouse_exited_card.is_connected(_on_card_unhovered):
				aerial_card.mouse_exited_card.connect(_on_card_unhovered)

		sync_slot_card_layout(index)

	sync_card_board_slot_styles()

	debug_panel = get_node_or_null(debug_panel_path)
	refresh_action_available_hints()
	refresh_debug_panel()


func prepare_card_board_view() -> void:
	var card_board := get_node_or_null(card_board_path)
	if card_board == null:
		return

	card_board.set("board_columns", board_columns)
	card_board.set("board_rows", board_rows)
	if card_board.has_method("ensure_board_slots"):
		card_board.ensure_board_slots()
	if card_board.has_method("resize_to_viewport"):
		card_board.resize_to_viewport()


func create_board_cell(slot_index: int, ground_state: CardState) -> BoardCell:
	var cell := BoardCell.new()
	cell.setup(slot_index, board_columns, is_land_slot(slot_index))
	cell.ground_state = ground_state
	return cell


func is_land_slot(slot_index: int) -> bool:
	return board_layer_resolver.is_land_slot(self, slot_index)


func get_board_cell(slot_index: int) -> BoardCell:
	return board_layer_resolver.get_board_cell(self, slot_index)


func get_aerial_state(slot_index: int) -> CardState:
	return board_layer_resolver.get_aerial_state(self, slot_index)


func get_all_board_states() -> Array[CardState]:
	return board_layer_resolver.get_all_board_states(self)


func get_board_states_at_slot(slot_index: int, include_empty := false) -> Array[CardState]:
	return board_layer_resolver.get_board_states_at_slot(self, slot_index, include_empty)


func can_refill_ground_slot(slot_index: int) -> bool:
	return board_layer_resolver.can_refill_ground_slot(self, slot_index)


func can_place_ground_card_on_slot(slot_index: int) -> bool:
	return board_layer_resolver.can_place_ground_card_on_slot(self, slot_index)


func can_place_aerial_card_on_slot(slot_index: int) -> bool:
	return board_layer_resolver.can_place_aerial_card_on_slot(self, slot_index)


func sync_board_cell_state_flags(slot_index: int) -> void:
	board_layer_resolver.sync_board_cell_state_flags(self, slot_index)


func add_beast_path_to_slots(slot_indices: Array[int], path_id: String) -> void:
	board_layer_resolver.add_beast_path_to_slots(self, slot_indices, path_id)


func is_beast_path_slot(slot_index: int) -> bool:
	return board_layer_resolver.is_beast_path_slot(self, slot_index)


func are_slots_connected_by_beast_path(from_slot: int, to_slot: int) -> bool:
	return board_layer_resolver.are_slots_connected_by_beast_path(self, from_slot, to_slot)


func sync_slot_card_layout(slot_index: int) -> void:
	var ground_card := get_card_by_slot(slot_index)
	var aerial_card := get_aerial_card_by_slot(slot_index)
	var ground_state := get_board_state(slot_index)
	var aerial_state := get_aerial_state(slot_index)
	if ground_card == null or aerial_card == null:
		return

	var slot_size := ground_card.card_size
	ground_card.position = Vector2.ZERO
	if not ground_card.is_animating:
		ground_card.scale = Vector2.ONE
	ground_card.z_index = 0

	if aerial_state == null or aerial_state.is_empty():
		aerial_card.position = Vector2.ZERO
		if not aerial_card.is_animating:
			aerial_card.scale = Vector2.ONE
		aerial_card.z_index = 20
		return

	if ground_state == null or ground_state.is_empty():
		aerial_card.position = Vector2.ZERO
		if not aerial_card.is_animating:
			aerial_card.scale = Vector2.ONE
	else:
		if not aerial_card.is_animating:
			aerial_card.scale = Vector2(0.62, 0.62)
		aerial_card.position = Vector2(slot_size.x * 0.36, slot_size.y * 0.02)
	aerial_card.z_index = 30


func sync_card_board_slot_styles() -> void:
	var card_board := get_node_or_null(card_board_path)
	if card_board == null or not card_board.has_method("set_land_slot_states"):
		return

	card_board.set_land_slot_states(board_layer_resolver.get_land_slot_states(self))


func create_initial_card_state(card_data: CardData, slot_index: int) -> CardState:
	# Create runtime state for one board slot.
	var state := CardState.new()
	state.slot_index = slot_index
	state.owner_id = ""
	state.is_interactable = true
	state.is_selected = false
	state.back_texture = default_back_texture

	# Static card data defines identity; runtime state copies mutable values.
	state.set_card_data(card_data)

	# Cards start face down and are changed through CardState methods.
	state.set_face_up(false)

	return state


func setup_card_pool_view() -> void:
	game_hud_coordinator.setup_card_pool(self)


func setup_card_animation_controller() -> void:
	card_animation_controller.setup({
		"move_animation_duration": move_animation_duration,
		"attack_animation_duration": attack_animation_duration,
		"attack_lunge_distance": attack_lunge_distance,
		"attack_target_shake_distance": attack_target_shake_distance,
		"ranged_attack_animation_duration": ranged_attack_animation_duration,
		"ranged_attack_projectile_size": ranged_attack_projectile_size,
		"ranged_attack_projectile_color": ranged_attack_projectile_color,
		"ranged_attack_projectile_glow_color": ranged_attack_projectile_glow_color,
		"spell_animation_duration": spell_animation_duration,
		"heal_spell_effect_color": heal_spell_effect_color,
		"heal_spell_effect_glow_color": heal_spell_effect_glow_color
	})


func setup_board_persistent_visuals() -> void:
	if board_persistent_visual_controller == null:
		board_persistent_visual_controller = BoardPersistentVisualControllerScript.new()
	board_persistent_visual_controller.setup(self, get_overlay_animation_root())


func setup_audio_manager() -> void:
	if audio_manager.get_parent() == null:
		add_child(audio_manager)
	audio_manager.setup(audio_config_path)


func start_battle_music() -> void:
	if default_battle_bgm_key == "":
		return
	audio_manager.play_bgm(default_battle_bgm_key)


func play_sfx(audio_key: String) -> void:
	audio_manager.play_sfx(audio_key)


func play_spell_sfx(spell_data: Dictionary) -> void:
	audio_manager.play_spell_sfx(spell_data)


func update_turn_status_view() -> void:
	game_hud_coordinator.update_turn_status(self)


func update_faction_time_panel_view() -> void:
	game_hud_coordinator.update_faction_time(self)


func update_faction_skill_panel_view() -> void:
	game_hud_coordinator.update_faction_skill(self)


func update_hand_drawer_view() -> void:
	game_hud_coordinator.update_hand_drawer(self)


func update_equipment_display_view() -> void:
	game_hud_coordinator.update_equipment(self)


func update_right_side_hud_layout() -> void:
	game_hud_coordinator.update_right_side_layout(self)


func update_card_pool_view() -> void:
	game_hud_coordinator.update_card_pool(self)


func get_card_pool_next_back_texture() -> Texture2D:
	return board_slot_resolver.get_card_pool_next_back_texture(self)


func get_card_back_texture_for_level(level: int) -> Texture2D:
	return board_slot_resolver.get_card_back_texture_for_level(self, level)


func draw_card_to_slot(slot_index: int) -> bool:
	return board_slot_resolver.draw_card_to_slot(self, slot_index)


func refill_board_slot_from_pool(slot_index: int) -> bool:
	return board_slot_resolver.refill_board_slot_from_pool(self, slot_index)


func clear_board_slot(slot_index: int) -> void:
	board_slot_resolver.clear_board_slot(self, slot_index)


func refill_empty_board_slots(max_count: int = -1) -> int:
	return board_slot_resolver.refill_empty_board_slots(self, max_count)


func get_board_state(slot_index: int) -> CardState:
	if slot_index < 0 or slot_index >= board_states.size():
		return null

	return board_states[slot_index]


func can_preview_card_front(state: CardState) -> bool:
	if state == null or state.is_empty():
		return false
	if state.is_face_up:
		return true

	var current_player := get_current_player()
	if current_player == null:
		return false

	return current_player.can_preview_board_slot(state.slot_index)


func _on_card_hovered(card: Card) -> void:
	if interaction_manager.is_area_target_mode:
		interaction_manager.update_area_preview(card.state, board_states, self)


func _on_card_unhovered(_card: Card) -> void:
	if interaction_manager.is_area_target_mode:
		interaction_manager.clear_area_preview(get_all_board_states())


func _on_card_clicked(card: Card) -> void:
	if is_game_busy():
		return

	if _is_ai_controlling():
		return

	if card.state == null:
		return

	if interaction_manager.mode == InteractionManager.Mode.SELECTING_ACTION_TARGET:
		handle_action_target_clicked(card.state)
		return

	if not card.state.is_interactable:
		return

	if card.state.is_empty():
		if interaction_manager.mode != InteractionManager.Mode.IDLE:
			cancel_interaction()
			return

		refresh_debug_panel()
		return

	var current_player := get_current_player()
	if current_player == null:
		return

	if card.state.has_owner() and not card.state.is_owned_by(current_player.id):
		refresh_debug_panel()
		return

	# Clicks enter GameManager; GameManager mutates CardState.
	var was_face_up := card.state.is_face_up
	if was_face_up:
		handle_face_up_card_clicked(card.state, current_player)
		return

	if not was_face_up and not current_player.can_flip_card():
		refresh_debug_panel()
		return

	is_resolving_card_action = true
	current_player.spend_flip()

	await card.play_flip_animation(Callable(card.state, "set_face_up").bind(true))

	if not reveal_resolver.can_player_claim_card(self, current_player, card.state):
		# If this belongs to the opponent faction, flip it back without taking ownership.
		await card.play_flip_animation(Callable(card.state, "set_face_up").bind(false))
		is_resolving_card_action = false
		refresh_debug_panel()
		return

	if reveal_resolver.should_assign_owner_on_reveal(self, card.state):
		card.state.set_owner(current_player.id)
	await reveal_resolver.resolve_revealed_card(self, card.state, current_player)

	is_resolving_card_action = false
	refresh_debug_panel()


func end_turn() -> void:
	# Switch the active player after ending the turn.
	if is_game_busy():
		return

	if players.is_empty():
		return

	is_resolving_card_action = true
	# Close transient interaction UI before switching turns.
	hide_action_menu()
	interaction_manager.cancel(get_all_board_states())

	var current_player := get_current_player()
	if current_player != null:
		current_player.end_turn()
		get_tree().call_group("card_hover_previews", "hide_preview")
		get_tree().call_group("hud_card_texture_previews", "hide")
		await resolve_turn_timing_triggers(EventContext.TRIGGER_AFTER_TURN_END, current_player.id)
		await advance_faction_runtime_state_for_player(current_player)

	is_spell_turn_active = false
	if current_player != null:
		refresh_hand_passives_for_player(current_player, false)
	current_player_index = (current_player_index + 1) % players.size()
	turn_number += 1

	current_player = get_current_player()
	if current_player != null:
		turn_event_ledger.begin_turn(current_player.id)
		await resolve_turn_timing_triggers(EventContext.TRIGGER_BEFORE_TURN_START, current_player.id)
		refresh_hand_passives_for_player(current_player, false)
		current_player.start_turn()
		card_reserve_resolver.advance_owner_turn(current_player, self)
		restore_unit_actions_for_all_players()

	is_resolving_card_action = false
	refresh_action_available_hints()
	update_turn_status_view()
	update_faction_time_panel_view()
	update_faction_skill_panel_view()
	update_hand_drawer_view()
	refresh_debug_panel()
	schedule_ai_turn_if_needed()


func advance_faction_runtime_state_for_player(player: PlayerState) -> void:
	if player == null:
		return

	if await faction_runtime_state_resolver.resolve_after_turn_end(self, player, turn_event_ledger):
		refresh_hand_passives_for_player(player, false)
		update_faction_time_panel_view()


func record_turn_death_event(death_event: Dictionary) -> void:
	var current_player := get_current_player()
	var state := death_event.get("state") as CardState
	if current_player == null or state == null:
		return

	var death_metadata: Dictionary = death_event.get("death_metadata", {})
	var death_record := turn_event_ledger.record_death(
		state,
		str(death_metadata.get("source_owner_id", "")),
		str(death_event.get("reason", ""))
	)
	if faction_runtime_state_resolver.resolve_after_death_event(
		current_player,
		turn_event_ledger,
		death_record
	):
		refresh_hand_passives_for_player(current_player, false)
		update_faction_time_panel_view()


func schedule_ai_turn_if_needed() -> void:
	if is_game_over or is_ai_turn_scheduled:
		return

	var player := get_current_player()
	if player == null or not player.is_ai:
		_set_end_turn_button_enabled(true)
		return

	_set_end_turn_button_enabled(false)
	is_ai_turn_scheduled = true
	_run_ai_turn.call_deferred()


func _run_ai_turn() -> void:
	await get_tree().process_frame
	is_ai_turn_scheduled = false
	if is_game_over or not _is_ai_controlling() or is_game_busy():
		schedule_ai_turn_if_needed()
		return

	var watchdog_token := start_ai_turn_watchdog()
	await ai_controller.run_turn(self)
	stop_ai_turn_watchdog(watchdog_token)


func start_ai_turn_watchdog() -> int:
	ai_turn_watchdog_token += 1
	var token := ai_turn_watchdog_token
	Callable(self, "resolve_ai_turn_watchdog").call_deferred(token)
	return token


func stop_ai_turn_watchdog(token: int) -> void:
	if token == ai_turn_watchdog_token:
		ai_turn_watchdog_token += 1


func resolve_ai_turn_watchdog(token: int) -> void:
	var tree := get_tree()
	if tree == null:
		return

	await tree.create_timer(ai_turn_watchdog_seconds).timeout
	if token != ai_turn_watchdog_token:
		return
	if is_game_over or not _is_ai_controlling():
		return

	var player := get_current_player()
	var player_name: String = player.display_name if player != null else "AI"
	push_warning("AI turn watchdog forced end turn for %s after %.1f seconds." % [player_name, ai_turn_watchdog_seconds])

	is_executing_action = false
	is_resolving_card_action = false
	is_ai_turn_scheduled = false
	hide_action_menu()
	interaction_manager.cancel(get_all_board_states())
	refresh_action_available_hints()
	update_turn_status_view()
	update_hand_drawer_view()
	refresh_debug_panel()

	await end_turn()


func _set_end_turn_button_enabled(enabled: bool) -> void:
	if end_turn_button != null:
		end_turn_button.disabled = not enabled


func resolve_turn_timing_triggers(trigger: String, turn_player_id: String) -> void:
	await status_resolver.resolve_pre_trigger_status_effects(self, trigger, turn_player_id)
	await turn_trigger_resolver.queue_turn_timing_triggers(self, trigger, turn_player_id)
	await status_resolver.resolve_turn_timing(self, trigger, turn_player_id)


func resolve_after_spell_cast(owner_id: String, caster_state: CardState, spell_data: Dictionary) -> void:
	await spell_cast_trigger_resolver.resolve_after_spell_cast(self, owner_id, caster_state, spell_data)


func activate_spell_turn() -> void:
	if is_game_busy():
		return

	if is_spell_turn_active:
		return

	var current_player := get_current_player()
	if current_player == null:
		return

	if not current_player.spend_mana(spell_turn_mana_cost):
		update_turn_status_view()
		return

	is_spell_turn_active = true
	refresh_hand_passives_for_player(current_player, false)
	update_turn_status_view()
	refresh_debug_panel()

	is_resolving_card_action = true
	var activation_animation_key := (
		KagunePowerResolver.RELEASE_ANIMATION_KEY
		if kagune_power_resolver.handles(current_player)
		else GameAnimationResolver.SPELL_TURN_ACTIVATION_ANIMATION_KEY
	)
	await play_board_effect_animation(activation_animation_key)
	is_resolving_card_action = false

	refresh_action_available_hints()
	update_action_menu()


func get_current_player_name() -> String:
	var current_player := get_current_player()
	if current_player == null:
		return "None"

	return current_player.display_name


func get_current_player() -> PlayerState:
	if players.is_empty():
		return null

	return players[current_player_index]


func get_player_by_id(player_id: String) -> PlayerState:
	if player_id == "":
		return null

	for player in players:
		if player.id == player_id:
			return player

	return null


func get_card_data_by_id(card_id: String) -> CardData:
	return card_database.get_card(card_id)


func get_hand_play_resolver() -> HandPlayResolver:
	return hand_interaction_controller.hand_play_resolver


func choose_card_indices_for_ai(candidates: Array[Dictionary], max_select: int) -> Array[int]:
	var selected: Array[int] = []
	if candidates.is_empty() or max_select <= 0:
		return selected

	var scored: Array[Dictionary] = []
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		scored.append({
			"index": index,
			"score": _score_ai_card_choice(candidate)
		})

	scored.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["score"]) > float(b["score"]))
	for item in scored:
		if selected.size() >= max_select:
			break
		selected.append(int(item["index"]))

	return selected


func _score_ai_card_choice(candidate: Dictionary) -> float:
	var attack := float(candidate.get("attack", 0))
	var health := float(candidate.get("health", 0))
	var level := float(candidate.get("level", 1))
	return attack * 2.0 + health + level * 0.75


func find_face_up_board_state(owner_id: String, card_id: String) -> CardState:
	if owner_id == "" or card_id == "":
		return null

	for state in get_all_board_states():
		if state == null or state.is_empty() or not state.is_face_up:
			continue
		if state.owner_id == owner_id and state.card_id == card_id:
			return state

	return null


func queue_card_trigger(source_state: CardState, trigger: String, context: Dictionary = {}) -> void:
	trigger_resolver.queue_trigger(source_state, trigger, context)


func resolve_queued_triggers() -> void:
	await trigger_resolver.resolve_queued(self)


func refresh_hand_passives_for_player(player: PlayerState, should_adjust_remaining_flips := false) -> void:
	hand_passive_resolver.refresh_player_passives(player, should_adjust_remaining_flips, self)
	card_reserve_resolver.refresh_player(player, self)
	kagune_power_resolver.refresh_player(player, self)
	update_turn_status_view()
	update_faction_skill_panel_view()
	refresh_action_available_hints()
	refresh_debug_panel()


func award_resource_score(player_id: String, amount: int) -> void:
	if player_id == "" or amount <= 0 or is_game_over:
		return

	var player := get_player_by_id(player_id)
	if player == null:
		return

	player.gain_resource_score(amount)
	check_victory()


func check_victory() -> void:
	if is_game_over:
		return

	var winner := victory_resolver.get_winner(players, victory_resource_score)
	if winner == null:
		return

	is_game_over = true
	winner_player_id = winner.id
	hide_action_menu()
	interaction_manager.cancel(get_all_board_states())
	update_turn_status_view()
	update_hand_drawer_view()
	refresh_debug_panel()

	await _show_victory_screen(winner)
	_transition_to_start_menu()


func get_winner_player() -> PlayerState:
	return get_player_by_id(winner_player_id)


func _show_victory_screen(winner: PlayerState) -> void:
	victory_screen_controller = VictoryScreenControllerScript.new()
	await victory_screen_controller.show(
		get_parent(), winner, players, turn_number, victory_resource_score
	)


func _transition_to_start_menu() -> void:
	var start_menu_scene := load("res://scenes/start_menu/start_menu.tscn") as PackedScene
	if start_menu_scene == null:
		push_error("閹靛彞绗夐崚棰佸瘜閼挎粌宕熼崷鐑樻珯: res://scenes/start_menu/start_menu.tscn")
		return

	var start_menu := start_menu_scene.instantiate()
	get_tree().root.add_child(start_menu)
	get_tree().current_scene = start_menu

	var main_root := get_parent()
	if main_root != null:
		main_root.queue_free()


func check_and_destroy_if_dead(state: CardState, reason: String = "damage", source_state: CardState = null) -> bool:
	return await death_resolver.check_and_destroy_if_dead(self, state, reason, source_state)


func resolve_dead_units(reason: String = "damage", source_state: CardState = null) -> bool:
	return await death_resolver.resolve_dead_units(self, reason, source_state)


func resolve_dead_states(
	states_to_check: Array,
	reason: String = "damage",
	source_state: CardState = null,
	source_owner_id := "",
	death_slot_claim: Dictionary = {}
) -> bool:
	return await death_resolver.resolve_dead_states(
		self,
		states_to_check,
		reason,
		source_state,
		true,
		false,
		source_owner_id,
		death_slot_claim
	)


func claim_death_slot(dead_state: CardState, claim: Dictionary) -> bool:
	return death_resolver.claim_death_slot(self, dead_state, claim)


func destroy_card(state: CardState, reason: String = "destroy", source_state: CardState = null) -> void:
	await death_resolver.destroy_card(self, state, reason, source_state)


func destroy_card_with_refill(
	state: CardState,
	reason: String = "destroy",
	source_state: CardState = null,
	should_refill_slot := true,
	source_owner_id := ""
) -> void:
	await death_resolver.destroy_card_with_refill(
		self,
		state,
		reason,
		source_state,
		should_refill_slot,
		source_owner_id
	)


func resolve_attack_kill(attacker_state: CardState, defeated_state: CardState, can_occupy := true) -> void:
	await death_resolver.resolve_attack_kill(self, attacker_state, defeated_state, can_occupy)


func resolve_after_attack_triggers(attacker_state: CardState, attacked_state: CardState) -> void:
	var context := {
		EventContext.ATTACK_TARGET_STATE: attacked_state,
		EventContext.SOURCE_STATE: attacker_state,
		EventContext.SOURCE_CARD_ID: attacker_state.card_id if attacker_state != null else ""
	}
	trigger_resolver.queue_trigger(attacker_state, EventContext.TRIGGER_AFTER_ATTACK, context)
	await trigger_resolver.resolve_queued(self)
	await resolve_after_friendly_attack_triggers(attacker_state, attacked_state, context)
	await equipment_trigger_resolver.resolve_after_attack(self, attacker_state, attacked_state)


func resolve_after_friendly_attack_triggers(attacker_state: CardState, attacked_state: CardState, context: Dictionary) -> void:
	if attacker_state == null or attacker_state.owner_id == "":
		return

	for value in get_all_board_states():
		var source_state := value as CardState
		if not BoardQuery.is_face_up_unit(source_state):
			continue
		if source_state == attacker_state:
			continue
		if source_state.owner_id != attacker_state.owner_id:
			continue

		trigger_resolver.queue_trigger(source_state, EventContext.TRIGGER_AFTER_FRIENDLY_ATTACK, context)

	await trigger_resolver.resolve_queued(self)


func set_board_slot_effect(slot_index: int, slot_effect: Variant) -> void:
	if slot_effect == null:
		return

	slot_effect.slot_index = slot_index
	board_slot_effect_resolver.add_slot_effect(slot_effect)
	refresh_debug_panel()


func resolve_slot_unit_entered(state: CardState) -> void:
	await board_slot_effect_resolver.resolve_unit_entered(self, state)


func can_offer_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> bool:
	return death_resolver.can_offer_attack_occupy(attacker_state, defeated_state)


func resolve_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> void:
	await death_resolver.resolve_attack_occupy(self, attacker_state, defeated_state)


func create_death_metadata(state: CardState, reason: String = "destroy", source_state: CardState = null) -> Dictionary:
	return death_resolver.create_death_metadata(self, state, reason, source_state)


func restore_minion_actions_for_player(player_id: String) -> void:
	if player_id == "":
		return

	for state in get_all_board_states():
		if state == null or state.is_empty():
			continue

		if not state.is_unit():
			continue

		if state.is_owned_by(player_id):
			state.restore_movement()
			state.restore_attacks()
			state.restore_mounted_attack_uses()
			state.restore_main_actions()


func restore_unit_actions_for_all_players() -> void:
	for state in get_all_board_states():
		if state == null or state.is_empty():
			continue

		if not state.is_unit():
			continue

		state.restore_movement()
		state.restore_attacks()
		state.restore_mounted_attack_uses()
		state.restore_main_actions()


func refresh_action_available_hints() -> void:
	action_hint_resolver.refresh(
		get_all_board_states(),
		get_current_player(),
		interaction_manager,
		action_registry,
		self
	)


func connect_interaction_manager() -> void:
	if not interaction_manager.interaction_changed.is_connected(_on_interaction_changed):
		interaction_manager.interaction_changed.connect(_on_interaction_changed)


func _on_interaction_changed() -> void:
	refresh_action_available_hints()
	hand_interaction_controller.update_hand_drawer_selection_state(self)
	refresh_debug_panel()


func handle_face_up_card_clicked(state: CardState, current_player: PlayerState) -> void:
	# Clicking an owned face-up unit enters or switches focus state.
	if not can_select_card(state, current_player):
		refresh_debug_panel()
		return

	interaction_manager.toggle_card_selection(state, get_all_board_states())
	update_action_menu()


func can_select_card(state: CardState, current_player: PlayerState) -> bool:
	if state == null or current_player == null:
		return false

	if state.is_empty() or not state.is_face_up:
		return false

	if not state.is_unit():
		return false

	return state.is_owned_by(current_player.id) and not action_registry.get_available_actions(state, self).is_empty()


func handle_action_target_clicked(target_state: CardState) -> void:
	# 行动目标阶段只响应合法目标；点同格飞行层时会解析到真正可用的地面层目标。
	if target_state == null:
		refresh_debug_panel()
		return

	if not interaction_manager.is_valid_target_slot(target_state.slot_index):
		refresh_debug_panel()
		return

	target_state = target_state_resolver.resolve_clicked_target_state(target_state, self)
	if target_state == null:
		refresh_debug_panel()
		return

	if interaction_manager.selected_action != null:
		if not interaction_manager.selected_action.can_target(interaction_manager.selected_action_user_state, target_state, self):
			refresh_debug_panel()
			return
		await execute_selected_action(target_state)
	elif interaction_manager.selected_hand_card_data != null:
		var selected_hand_owner := get_player_by_id(interaction_manager.selected_hand_owner_id)
		if (
			interaction_manager.selected_hand_action_id == HandPlayResolver.HAND_CAST_ACTION_ID
			and not get_hand_play_resolver().can_target(
				interaction_manager.selected_hand_card_data,
				target_state,
				self,
				selected_hand_owner
			)
		):
			refresh_debug_panel()
			return
		await execute_selected_hand_card(target_state)

	refresh_action_available_hints()
	refresh_debug_panel()
	cancel_interaction()


func execute_selected_action(target_state: CardState) -> void:
	if interaction_manager.selected_action == null:
		return

	is_executing_action = true
	await interaction_manager.selected_action.execute(interaction_manager.selected_action_user_state, target_state, self)
	is_executing_action = false

func execute_selected_hand_card(target_state: CardState) -> void:
	await hand_interaction_controller.execute_selected_hand_card(self, target_state)


func swap_board_cells(
	first_state: CardState,
	second_state: CardState,
	animation_key := ""
) -> void:
	# Swap two board cells; cell properties move with the cell.
	if first_state == null or second_state == null:
		return

	var first_cell := get_board_cell(first_state.slot_index)
	var second_cell := get_board_cell(second_state.slot_index)
	if first_cell != null and second_cell != null:
		first_cell.swap_cell_properties_with(second_cell)
		sync_board_cell_state_flags(first_state.slot_index)
		sync_board_cell_state_flags(second_state.slot_index)
		sync_card_board_slot_styles()

	await swap_board_slot_contents(first_state, second_state, animation_key)
	sync_board_cell_state_flags(first_state.slot_index)
	sync_board_cell_state_flags(second_state.slot_index)
	sync_card_board_slot_styles()


func swap_board_slot_contents(
	first_state: CardState,
	second_state: CardState,
	animation_key := ""
) -> void:
	# Swap fixed-slot card contents while preserving slot indices and UI bindings.
	if first_state == null or second_state == null:
		return

	var first_card: Card = get_card_by_slot(first_state.slot_index)
	var second_card: Card = get_card_by_slot(second_state.slot_index)

	if first_card == null or second_card == null:
		first_state.swap_card_content_with(second_state)
		await resolve_slot_unit_entered(first_state)
		await resolve_slot_unit_entered(second_state)
		refresh_action_available_hints()
		refresh_debug_panel()
		return

	is_resolving_card_action = true
	var first_global_position: Vector2 = first_card.global_position
	var second_global_position: Vector2 = second_card.global_position

	first_state.swap_card_content_with(second_state)
	await play_card_swap_animation(
		first_card,
		second_card,
		first_global_position,
		second_global_position,
		animation_key
	)
	await resolve_slot_unit_entered(first_state)
	await resolve_slot_unit_entered(second_state)

	is_resolving_card_action = false
	refresh_action_available_hints()
	refresh_debug_panel()


func play_card_swap_animation(
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2,
	animation_key := ""
) -> void:
	await game_animation_resolver.play_card_swap_animation(
		self,
		first_card,
		second_card,
		first_slot_position,
		second_slot_position,
		animation_key
	)


func play_card_attack_animation(attacker_state: CardState, target_state: CardState, is_melee_attack := true) -> void:
	await game_animation_resolver.play_card_attack_animation(self, attacker_state, target_state, is_melee_attack)


func play_secondary_attack_impact_animation(target_states: Array[CardState]) -> void:
	await game_animation_resolver.play_secondary_attack_impact_animation(self, target_states)


func play_spell_cast_animation(caster_state: CardState, target_state: CardState, spell_data: Dictionary) -> void:
	await game_animation_resolver.play_spell_cast_animation(self, caster_state, target_state, spell_data)


func play_area_spell_animation(caster_state: CardState, center_state: CardState, spell_data: Dictionary) -> void:
	await game_animation_resolver.play_area_spell_animation(self, caster_state, center_state, spell_data)


func play_link_units_animation(first_state: CardState, second_state: CardState, animation_key := "gu_life_link") -> void:
	await game_animation_resolver.play_link_units_animation(self, first_state, second_state, animation_key)


func play_moonblade_animation(caster_state: CardState, first_state: CardState, second_state: CardState) -> void:
	await game_animation_resolver.play_moonblade_animation(self, caster_state, first_state, second_state)


func play_effect_heal_animation(target_state: CardState) -> void:
	await game_animation_resolver.play_effect_heal_animation(self, target_state)


func play_multi_target_effect_animation(
	target_states: Array[CardState],
	animation_key: String
) -> bool:
	return await game_animation_resolver.play_multi_target_effect_animation(
		self,
		target_states,
		animation_key
	)


func play_status_apply_animation(target_state: CardState, animation_key: String) -> void:
	await game_animation_resolver.play_status_apply_animation(self, target_state, animation_key)


func play_slot_effect_animation(target_state: CardState, animation_key: String) -> void:
	await game_animation_resolver.play_slot_effect_animation(self, target_state, animation_key)


func play_board_effect_animation(animation_key: String) -> void:
	await game_animation_resolver.play_board_effect_animation(self, animation_key)


func play_path_effect_animation(slot_indices: Array[int], animation_key: String) -> void:
	await game_animation_resolver.play_path_effect_animation(self, slot_indices, animation_key)


func play_card_to_hand_animation(source_card: Card, card_data: CardData) -> void:
	await game_animation_resolver.play_card_to_hand_animation(self, source_card, card_data)


func play_hand_spell_card_animation(card_data: CardData, target_state: CardState = null, animation_override := "") -> void:
	await game_animation_resolver.play_hand_spell_card_animation(self, card_data, target_state, animation_override)


func get_overlay_animation_root() -> Control:
	return game_animation_resolver.get_overlay_animation_root(self)

func move_card_content_to_empty_slot(from_state: CardState, to_state: CardState) -> void:
	await board_movement_resolver.move_card_content_to_empty_slot(self, from_state, to_state)


func move_flying_card_to_slot(from_state: CardState, to_slot_index: int) -> void:
	await board_movement_resolver.move_flying_card_to_slot(self, from_state, to_slot_index)


func promote_ground_flying_to_aerial(source_state: CardState) -> CardState:
	return await board_movement_resolver.promote_ground_flying_to_aerial(self, source_state)


func animate_refill_board_slot(slot_index: int, card_data: CardData) -> void:
	await game_animation_resolver.animate_refill_board_slot(self, slot_index, card_data)


func cancel_interaction() -> void:
	# Shared cancellation path for buttons and right click.
	hide_action_menu()
	hand_interaction_controller.clear_anchor()
	interaction_manager.cancel(get_all_board_states())


func return_to_action_menu() -> void:
	# Return from target selection to the focus menu.
	if interaction_manager.focused_state == null and interaction_manager.selected_hand_card_data == null:
		cancel_interaction()
		return

	interaction_manager.return_to_card_selection(get_all_board_states())
	update_action_menu_after_layout()


func update_action_menu() -> void:
	if interaction_manager.mode != InteractionManager.Mode.CARD_SELECTED:
		hide_action_menu()
		return

	if hand_interaction_controller.show_action_menu_if_selected(self):
		return

	if interaction_manager.focused_state == null:
		hide_action_menu()
		return

	var available_actions: Array[CardAction] = action_registry.get_available_actions(interaction_manager.focused_state, self)
	var focused_card: Card = get_card_by_slot(interaction_manager.focused_state.slot_index)
	if focused_card == null:
		hide_action_menu()
		return

	action_menu_controller.show_for_card(focused_card, available_actions)


func hide_action_menu() -> void:
	action_menu_controller.hide()


func _on_action_menu_action_requested(action_id: String) -> void:
	if hand_interaction_controller.handle_action_menu_request(self, action_id):
		return

	start_action_selection(action_id)


func update_action_menu_after_layout() -> void:
	await get_tree().process_frame
	update_action_menu()


func start_action_selection(action_id: String) -> void:
	var action: CardAction = action_registry.get_action(action_id)
	hide_action_menu()
	if action == null:
		update_action_menu()
		refresh_debug_panel()
		return

	if not action.requires_target():
		await execute_action_without_target(action)
		refresh_action_available_hints()
		refresh_debug_panel()
		cancel_interaction()
		return

	interaction_manager.start_action_selection(action, get_all_board_states(), self)


func get_card_by_slot(slot_index: int) -> Card:
	if slot_index < 0 or slot_index >= board_cards.size():
		return null

	return board_cards[slot_index]


func get_aerial_card_by_slot(slot_index: int) -> Card:
	if slot_index < 0 or slot_index >= aerial_board_cards.size():
		return null

	return aerial_board_cards[slot_index]


func get_card_for_state(state: CardState) -> Card:
	if state == null:
		return null

	var aerial_state := get_aerial_state(state.slot_index)
	if aerial_state == state:
		return get_aerial_card_by_slot(state.slot_index)

	return get_card_by_slot(state.slot_index)


func execute_action_without_target(action: CardAction) -> void:
	if action == null or interaction_manager.focused_state == null:
		return

	is_executing_action = true
	await action.execute(interaction_manager.focused_state, null, self)
	is_executing_action = false


func _on_faction_skill_requested(skill_id: String) -> void:
	if is_game_busy() or skill_id == "":
		return
	if _is_ai_controlling():
		return

	var player := get_current_player()
	if not faction_skill_resolver.start_skill_selection(self, player, skill_id):
		update_faction_skill_panel_view()
		refresh_debug_panel()
		return

	update_hand_drawer_view()
	refresh_debug_panel()


func _on_card_state_changed(state: CardState) -> void:
	if state != null:
		sync_slot_card_layout(state.slot_index)
	if board_persistent_visual_controller != null:
		board_persistent_visual_controller.refresh_sources()
	refresh_debug_panel()


func _on_player_state_changed(state: PlayerState) -> void:
	check_victory()
	update_turn_status_view()
	update_faction_time_panel_view()
	update_faction_skill_panel_view()
	if state == get_current_player():
		update_hand_drawer_view()
	refresh_debug_panel()


func refresh_debug_panel() -> void:
	if debug_panel == null:
		return

	var card_pool_remaining := -1
	if card_pool != null:
		card_pool_remaining = card_pool.remaining()

	if not debug_panel.has_method("update_states"):
		return

	debug_panel.update_states(
		board_states,
		players,
		current_player_index,
		turn_number,
		card_pool_remaining,
		interaction_manager
	)


func find_board_cards(card_node_name := "Card") -> Array[Card]:
	# Recursively collect card instances under CardBoard.
	var cards: Array[Card] = []
	var card_board := get_node_or_null(card_board_path)

	if card_board == null:
		return cards

	collect_cards(card_board, cards, card_node_name)
	return cards


func collect_cards(node: Node, cards: Array[Card], card_node_name := "Card") -> void:
	# Depth-first traversal under CardBoard.
	if node is Card:
		if node.name == card_node_name:
			cards.append(node)

	for child in node.get_children():
		collect_cards(child, cards, card_node_name)
