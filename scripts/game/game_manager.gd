extends Node
class_name GameManager

const CardPoolViewControllerScript := preload("res://scripts/ui/card_pool_view_controller.gd")
const TurnStatusControllerScript := preload("res://scripts/ui/turn_status_controller.gd")
const HandDrawerControllerScript := preload("res://scripts/ui/hand_drawer_controller.gd")
const EquipmentDisplayControllerScript := preload("res://scripts/ui/equipment_display_controller.gd")
const AttackOccupyChoiceControllerScript := preload("res://scripts/ui/attack_occupy_choice_controller.gd")
const CardAnimationControllerScript := preload("res://scripts/ui/card_animation_controller.gd")
const BoardSlotResolverScript := preload("res://scripts/game/board_slot_resolver.gd")
const ActionHintResolverScript := preload("res://scripts/game/action_hint_resolver.gd")
const RevealResolverScript := preload("res://scripts/game/reveal_resolver.gd")
const HandInteractionControllerScript := preload("res://scripts/game/hand_interaction_controller.gd")
const DeathResolverScript := preload("res://scripts/game/death_resolver.gd")
const HandPassiveResolverScript := preload("res://scripts/game/hand_passive_resolver.gd")
const VictoryResolverScript := preload("res://scripts/game/victory_resolver.gd")
const TriggerResolverScript := preload("res://scripts/game/trigger_resolver.gd")
const TurnTriggerResolverScript := preload("res://scripts/game/turn_trigger_resolver.gd")
const StatusResolverScript := preload("res://scripts/game/status_resolver.gd")
const EquipmentTriggerResolverScript := preload("res://scripts/game/equipment_trigger_resolver.gd")
const VictoryScreenControllerScript := preload("res://scripts/ui/victory_screen_controller.gd")

# GameManager 是战局编排入口。
# 它持有玩家、棋盘、牌池和交互状态，负责串起回合、行动、死亡、补位等规则流程。
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

# 第一版固定参战种族：玩家 1 白银之手，玩家 2 达拉然议会。
@export var player_faction_ids: Array[String] = ["silver_hand", "dalaran_council"]

# 入口选择页传入的英雄。为空时使用对应种族的第一个英雄。
@export var selected_hero_card_ids: Array[String] = []

# 中立牌库不属于任一玩家种族，但会与双方种族牌一起洗入公共牌池。
@export var neutral_faction_ids: Array[String] = ["neutral"]

# 所有卡牌默认使用的背面图片。
@export var default_back_texture_path := "res://assets/img/卡背/1.png"

# 第一版两名玩家名称。启动时会转成 PlayerState。
@export var player_names: Array[String] = ["Player 1", "Player 2"]
@export var player_max_flips_per_turn := 4
@export var spell_turn_mana_cost := 1
@export var victory_resource_score := 80

# 棋盘列数。当前 5*5 棋盘用于判断上下左右相邻。
@export var board_columns := 5

# 卡牌移动动画时长。移动规则仍然由 CardState 交换决定，这里只负责表现。
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

# 棋盘上的 25 个状态，索引和 CardSlot 顺序一致。
var board_states: Array[CardState] = []

# 与 board_states 一一对应的卡牌节点。
var board_cards: Array[Card] = []

# 两名玩家的运行时状态。
var players: Array[PlayerState] = []

# 静态卡牌数据库，启动时从 JSON 初始化。
var card_database := CardDatabase.new()

# 卡牌效果注册表，负责把 JSON 中的效果 id 映射到代码逻辑。
var effect_registry := EffectRegistry.new()

# 卡牌行动注册表。第一版所有随从都拥有移动行动。
var action_registry := ActionRegistry.new()

# 玩家交互状态机，负责记录当前焦点牌和正在选择的操作目标。
var interaction_manager := InteractionManager.new()

# 持久化卡牌池，游戏加载时构建，之后可被多处调用。
var card_pool: CardPool

# 加载后的默认卡背资源。
var default_back_texture: Texture2D
var debug_panel: Node
var end_turn_button: Button
var action_menu_controller := ActionMenuController.new()
var card_pool_view_controller := CardPoolViewControllerScript.new()
var turn_status_controller := TurnStatusControllerScript.new()
var hand_drawer_controller := HandDrawerControllerScript.new()
var equipment_display_controller := EquipmentDisplayControllerScript.new()
var attack_occupy_choice_controller := AttackOccupyChoiceControllerScript.new()
var card_animation_controller := CardAnimationControllerScript.new()
var board_slot_resolver := BoardSlotResolverScript.new()
var action_hint_resolver := ActionHintResolverScript.new()
var reveal_resolver := RevealResolverScript.new()
var hand_interaction_controller := HandInteractionControllerScript.new()
var death_resolver := DeathResolverScript.new()
var hand_passive_resolver := HandPassiveResolverScript.new()
var victory_resolver := VictoryResolverScript.new()
var trigger_resolver := TriggerResolverScript.new()
var turn_trigger_resolver := TurnTriggerResolverScript.new()
var status_resolver := StatusResolverScript.new()
var equipment_trigger_resolver := EquipmentTriggerResolverScript.new()
var victory_screen_controller: VictoryScreenController

# 当前操作人索引，只由 GameManager 修改。
var current_player_index := 0
var turn_number := 1
var is_spell_turn_active := false
var is_game_over := false
var winner_player_id := ""

# 翻牌结算期间暂时锁住新的卡牌操作，避免动画中连续点击导致状态交错。
var is_resolving_card_action := false

# 行动执行期间由行动流程统一收尾，避免死亡结算和外层点击流程重复取消交互。
var is_executing_action := false

func _ready() -> void:
	connect_end_turn_button()
	connect_interaction_manager()
	connect_viewport_resize()
	setup_action_menu.call_deferred()

	if not load_static_card_data():
		return

	initialize_players()
	setup_card_animation_controller()
	setup_turn_status_view()
	setup_hand_drawer_view()
	setup_equipment_display_view()
	update_turn_status_view()
	update_hand_drawer_view()
	update_equipment_display_view()
	card_pool = create_initial_card_pool()
	initialize_board()
	setup_card_pool_view()
	update_card_pool_view()


func _input(event: InputEvent) -> void:
	if is_game_over:
		return

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


func connect_viewport_resize() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	if not viewport.size_changed.is_connected(update_card_pool_view):
		viewport.size_changed.connect(update_card_pool_view)
	if not viewport.size_changed.is_connected(update_equipment_display_view):
		viewport.size_changed.connect(update_equipment_display_view)


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
		player.set_base_flips_per_turn(player_max_flips_per_turn)
		player.remaining_flips = player.max_flips_per_turn
		player.max_mana = PlayerState.MANA_CAPACITY
		player.mana = 0
		player.state_changed.connect(_on_player_state_changed)
		players.append(player)

	if not players.is_empty():
		players[current_player_index].start_turn()


func load_static_card_data() -> bool:
	# CardDatabase 负责解析 JSON 并缓存 CardData。
	if not card_database.load_from_json(cards_json_path):
		return false

	card_database.load_test_config("res://data/test_config.json")
	_apply_test_game_params()

	# 卡背暂时作为统一运行时资源，由 GameManager 注入到每个 CardState。
	default_back_texture = load(default_back_texture_path) as Texture2D
	return true


func _apply_test_game_params() -> void:
	if not card_database.is_test_mode:
		return
	spell_turn_mana_cost = card_database.get_test_game_param("spell_turn_mana_cost", spell_turn_mana_cost)
	victory_resource_score = card_database.get_test_game_param("victory_resource_score", victory_resource_score)


func create_initial_card_pool() -> CardPool:
	# 公共牌池由双方选中种族、选中英雄和中立牌库一起组成。
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


func initialize_board() -> void:
	board_cards = find_board_cards()
	board_states.clear()

	if card_pool == null:
		push_error("GameManager 初始化失败：牌池未创建")
		return

	for index in range(board_cards.size()):
		var card: Card = board_cards[index]
		var card_data: CardData = null

		if not card_pool.is_empty():
			card_data = card_pool.draw_random()

		var state := create_initial_card_state(card_data, index)

		board_states.append(state)
		state.state_changed.connect(_on_card_state_changed)
		card.bind_state(state)

		# 点击事件统一进入 GameManager，Card 自己不改状态。
		if not card.clicked.is_connected(_on_card_clicked):
			card.clicked.connect(_on_card_clicked)
		if not card.mouse_entered_card.is_connected(_on_card_hovered):
			card.mouse_entered_card.connect(_on_card_hovered)
		if not card.mouse_exited_card.is_connected(_on_card_unhovered):
			card.mouse_exited_card.connect(_on_card_unhovered)

	debug_panel = get_node_or_null(debug_panel_path)
	refresh_action_available_hints()
	refresh_debug_panel()


func create_initial_card_state(card_data: CardData, slot_index: int) -> CardState:
	# 创建棋盘上某一个格子的运行时状态。
	var state := CardState.new()
	state.slot_index = slot_index
	state.owner_id = ""
	state.is_interactable = true
	state.is_selected = false
	state.back_texture = default_back_texture

	# 静态数据决定这张牌是什么，运行时状态复制当前攻击/生命等可变值。
	state.set_card_data(card_data)

	# 初始全部背面朝上；之后只能通过 CardState 方法修改。
	state.set_face_up(false)

	return state


func setup_card_pool_view() -> void:
	card_pool_view_controller.setup(
		self,
		card_pool_view_path,
		card_pool_animation_root_path,
		default_back_texture,
		card_pool_view_size,
		card_pool_view_margin,
		refill_animation_duration
	)


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


func setup_turn_status_view() -> void:
	turn_status_controller.setup(self, turn_status_panel_path)
	if not turn_status_controller.spell_turn_requested.is_connected(activate_spell_turn):
		turn_status_controller.spell_turn_requested.connect(activate_spell_turn)


func update_turn_status_view() -> void:
	var current_player := get_current_player()
	var can_activate := (
		current_player != null
		and not is_spell_turn_active
		and current_player.mana >= spell_turn_mana_cost
	)
	turn_status_controller.update(
		current_player,
		turn_number,
		is_spell_turn_active,
		spell_turn_mana_cost,
		can_activate,
		victory_resource_score,
		is_game_over,
		get_winner_player()
	)


func setup_hand_drawer_view() -> void:
	hand_interaction_controller.setup(self)


func update_hand_drawer_view() -> void:
	hand_interaction_controller.update_hand_drawer_view(self)
	update_equipment_display_view()


func setup_equipment_display_view() -> void:
	equipment_display_controller.setup(get_parent() as Control)


func update_equipment_display_view() -> void:
	equipment_display_controller.update(get_current_player())


func update_card_pool_view() -> void:
	var remaining: int = 0
	var next_back_texture: Texture2D = default_back_texture
	if card_pool != null:
		remaining = card_pool.remaining()
		next_back_texture = get_card_pool_next_back_texture()

	card_pool_view_controller.update(remaining, get_parent(), next_back_texture)


func get_card_pool_next_back_texture() -> Texture2D:
	if card_pool == null:
		return default_back_texture

	var next_level := card_pool.get_lowest_available_level()
	if next_level <= 0:
		return default_back_texture

	return get_card_back_texture_for_level(next_level)


func get_card_back_texture_for_level(level: int) -> Texture2D:
	var card_back_path := "res://assets/img/卡背/%d.png" % maxi(level, 1)
	if ResourceLoader.exists(card_back_path):
		return load(card_back_path) as Texture2D

	return default_back_texture


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


func _on_card_hovered(card: Card) -> void:
	if interaction_manager.is_area_target_mode:
		interaction_manager.update_area_preview(card.state, board_states, self)


func _on_card_unhovered(_card: Card) -> void:
	if interaction_manager.is_area_target_mode:
		interaction_manager.clear_area_preview(board_states)


func _on_card_clicked(card: Card) -> void:
	if is_game_busy():
		return

	if card.state == null:
		return

	if not card.state.is_interactable:
		return

	if interaction_manager.mode == InteractionManager.Mode.SELECTING_ACTION_TARGET:
		handle_action_target_clicked(card.state)
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

	# 单向数据流：点击只进入 GameManager，GameManager 只修改 CardState。
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
		# 翻到对方种族时，本次翻牌失败，卡牌自动扣回背面且不产生归属。
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
	# 回合结束后切换当前操作人。
	if is_game_busy():
		return

	if players.is_empty():
		return

	is_resolving_card_action = true
	hide_action_menu()
	interaction_manager.cancel(board_states)

	var current_player := get_current_player()
	if current_player != null:
		current_player.end_turn()
		await resolve_turn_timing_triggers(EventContext.TRIGGER_AFTER_TURN_END, current_player.id)

	is_spell_turn_active = false
	current_player_index = (current_player_index + 1) % players.size()
	turn_number += 1

	current_player = get_current_player()
	if current_player != null:
		await resolve_turn_timing_triggers(EventContext.TRIGGER_BEFORE_TURN_START, current_player.id)
		refresh_hand_passives_for_player(current_player, false)
		current_player.start_turn()
		restore_minion_actions_for_player(current_player.id)

	is_resolving_card_action = false
	refresh_action_available_hints()
	update_turn_status_view()
	update_hand_drawer_view()
	refresh_debug_panel()


func resolve_turn_timing_triggers(trigger: String, turn_player_id: String) -> void:
	await turn_trigger_resolver.queue_turn_timing_triggers(self, trigger, turn_player_id)
	status_resolver.resolve_turn_timing(self, trigger, turn_player_id)


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
	refresh_action_available_hints()
	update_action_menu()
	update_turn_status_view()
	refresh_debug_panel()


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


func find_face_up_board_state(owner_id: String, card_id: String) -> CardState:
	if owner_id == "" or card_id == "":
		return null

	for state in board_states:
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
	update_turn_status_view()
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
	interaction_manager.cancel(board_states)
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
		push_error("找不到主菜单场景: res://scenes/start_menu/start_menu.tscn")
		return

	var start_menu := start_menu_scene.instantiate()
	get_tree().root.add_child(start_menu)
	get_tree().current_scene = start_menu

	var main_root := get_parent()
	if main_root != null:
		main_root.queue_free()


func check_and_destroy_if_dead(state: CardState, reason: String = "damage", source_state: CardState = null) -> bool:
	return death_resolver.check_and_destroy_if_dead(self, state, reason, source_state)


func resolve_dead_units(reason: String = "damage", source_state: CardState = null) -> bool:
	return death_resolver.resolve_dead_units(self, reason, source_state)


func resolve_dead_states(states_to_check: Array, reason: String = "damage", source_state: CardState = null) -> bool:
	return death_resolver.resolve_dead_states(self, states_to_check, reason, source_state)


func destroy_card(state: CardState, reason: String = "destroy", source_state: CardState = null) -> void:
	death_resolver.destroy_card(self, state, reason, source_state)


func destroy_card_with_refill(
	state: CardState,
	reason: String = "destroy",
	source_state: CardState = null,
	should_refill_slot := true
) -> void:
	death_resolver.destroy_card_with_refill(self, state, reason, source_state, should_refill_slot)


func resolve_attack_kill(attacker_state: CardState, defeated_state: CardState, can_occupy := true) -> void:
	await death_resolver.resolve_attack_kill(self, attacker_state, defeated_state, can_occupy)


func resolve_after_attack_triggers(attacker_state: CardState, attacked_state: CardState) -> void:
	await equipment_trigger_resolver.resolve_after_attack(self, attacker_state, attacked_state)


func can_offer_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> bool:
	return death_resolver.can_offer_attack_occupy(attacker_state, defeated_state)


func resolve_attack_occupy(attacker_state: CardState, defeated_state: CardState) -> void:
	await death_resolver.resolve_attack_occupy(self, attacker_state, defeated_state)


func create_death_metadata(state: CardState, reason: String = "destroy", source_state: CardState = null) -> Dictionary:
	return death_resolver.create_death_metadata(self, state, reason, source_state)


func restore_minion_actions_for_player(player_id: String) -> void:
	if player_id == "":
		return

	for state in board_states:
		if state == null or state.is_empty():
			continue

		if not state.is_minion():
			continue

		if state.is_owned_by(player_id):
			state.restore_movement()
			state.restore_attacks()
			state.restore_main_actions()


func refresh_action_available_hints() -> void:
	action_hint_resolver.refresh(
		board_states,
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
	# 玩家点击己方正面随从时，进入或切换焦点状态；不再把牌扣回去。
	if not can_select_card(state, current_player):
		refresh_debug_panel()
		return

	interaction_manager.toggle_card_selection(state, board_states)
	update_action_menu()


func can_select_card(state: CardState, current_player: PlayerState) -> bool:
	if state == null or current_player == null:
		return false

	if state.is_empty() or not state.is_face_up:
		return false

	if not state.is_minion():
		return false

	return state.is_owned_by(current_player.id)


func handle_action_target_clicked(target_state: CardState) -> void:
	# 行动目标阶段只响应合法目标；点其他格子不会误触发翻牌。
	if target_state == null:
		refresh_debug_panel()
		return

	if not interaction_manager.is_valid_target_slot(target_state.slot_index):
		refresh_debug_panel()
		return

	if interaction_manager.selected_action != null:
		await execute_selected_action(target_state)
	elif interaction_manager.selected_hand_card_data != null:
		await execute_selected_hand_card(target_state)

	refresh_action_available_hints()
	refresh_debug_panel()
	cancel_interaction()


func execute_selected_action(target_state: CardState) -> void:
	if interaction_manager.selected_action == null:
		return

	is_executing_action = true
	await interaction_manager.selected_action.execute(interaction_manager.focused_state, target_state, self)
	is_executing_action = false


func execute_selected_hand_card(target_state: CardState) -> void:
	await hand_interaction_controller.execute_selected_hand_card(self, target_state)


func swap_board_slot_contents(first_state: CardState, second_state: CardState) -> void:
	# 交换两个固定格子的卡牌内容，但保留格子本身的 slot_index 和 UI 绑定关系。
	if first_state == null or second_state == null:
		return

	var first_card: Card = get_card_by_slot(first_state.slot_index)
	var second_card: Card = get_card_by_slot(second_state.slot_index)

	if first_card == null or second_card == null:
		first_state.swap_card_content_with(second_state)
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
		second_global_position
	)

	is_resolving_card_action = false
	refresh_action_available_hints()
	refresh_debug_panel()


func play_card_swap_animation(
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2
) -> void:
	await card_animation_controller.play_card_swap(
		self,
		first_card,
		second_card,
		first_slot_position,
		second_slot_position
	)


func play_card_attack_animation(attacker_state: CardState, target_state: CardState, is_melee_attack := true) -> void:
	if attacker_state == null or target_state == null:
		return

	var attacker_card: Card = get_card_by_slot(attacker_state.slot_index)
	var target_card: Card = get_card_by_slot(target_state.slot_index)
	if attacker_card == null or target_card == null:
		return

	is_resolving_card_action = true
	await card_animation_controller.play_card_attack(
		self,
		get_parent(),
		attacker_card,
		target_card,
		is_melee_attack
	)
	is_resolving_card_action = false


func play_spell_cast_animation(caster_state: CardState, target_state: CardState, spell_data: Dictionary) -> void:
	if caster_state == null or target_state == null:
		return

	var caster_card: Card = get_card_by_slot(caster_state.slot_index)
	var target_card: Card = get_card_by_slot(target_state.slot_index)
	if caster_card == null or target_card == null:
		return

	is_resolving_card_action = true
	await card_animation_controller.play_spell_cast(
		self,
		get_overlay_animation_root(),
		caster_card,
		target_card,
		spell_data
	)
	is_resolving_card_action = false


func play_area_spell_animation(caster_state: CardState, center_state: CardState, spell_data: Dictionary) -> void:
	if caster_state == null or center_state == null:
		return

	var caster_card: Card = get_card_by_slot(caster_state.slot_index)
	var center_card: Card = get_card_by_slot(center_state.slot_index)
	if caster_card == null or center_card == null:
		return

	is_resolving_card_action = true
	await card_animation_controller.play_area_spell_cast(
		self,
		get_overlay_animation_root(),
		caster_card,
		center_card,
		spell_data
	)
	is_resolving_card_action = false


func play_effect_heal_animation(target_state: CardState) -> void:
	if target_state == null:
		return

	var target_card: Card = get_card_by_slot(target_state.slot_index)
	if target_card == null:
		return

	await card_animation_controller.play_spell_cast(
		self,
		get_overlay_animation_root(),
		target_card,
		target_card,
		{"animation": "heal"}
	)


func play_status_apply_animation(target_state: CardState, animation_key: String) -> void:
	if target_state == null or animation_key == "":
		return

	var target_card: Card = get_card_by_slot(target_state.slot_index)
	if target_card == null:
		return

	await card_animation_controller.play_spell_cast(
		self,
		get_overlay_animation_root(),
		target_card,
		target_card,
		{"animation": animation_key}
	)


func play_card_to_hand_animation(source_card: Card, card_data: CardData) -> void:
	if source_card == null or card_data == null:
		return

	await hand_drawer_controller.play_card_to_hand_animation(
		self,
		get_overlay_animation_root(),
		source_card,
		card_data
	)


func play_hand_spell_card_animation(card_data: CardData, target_state: CardState = null) -> void:
	if card_data == null:
		return

	var spell_data := {
		"animation": card_data.animation if card_data.animation != "" else "heal"
	}

	is_resolving_card_action = true

	if target_state != null:
		var target_card: Card = get_card_by_slot(target_state.slot_index)
		if target_card != null:
			var hand_card_rect: Rect2 = hand_interaction_controller.get_selected_hand_card_rect()
			if hand_card_rect.size != Vector2.ZERO:
				await card_animation_controller.play_spell_cast_from_rect_to_card(
					self,
					get_overlay_animation_root(),
					hand_card_rect,
					target_card,
					spell_data
				)
			else:
				await card_animation_controller.play_spell_cast(
					self,
					get_overlay_animation_root(),
					target_card,
					target_card,
					spell_data
				)
	else:
		var hand_card_rect: Rect2 = hand_interaction_controller.get_selected_hand_card_rect()
		if hand_card_rect.size != Vector2.ZERO:
			await card_animation_controller.play_spell_cast_at_rect(
				self,
				get_overlay_animation_root(),
				hand_card_rect,
				spell_data
			)

	is_resolving_card_action = false


func get_overlay_animation_root() -> Control:
	if card_pool_view_controller.animation_root != null:
		return card_pool_view_controller.animation_root

	return get_parent() as Control

func move_card_content_to_empty_slot(from_state: CardState, to_state: CardState) -> void:
	if from_state == null or to_state == null:
		return

	if from_state.is_empty() or not to_state.is_empty():
		return

	var from_card: Card = get_card_by_slot(from_state.slot_index)
	var to_card: Card = get_card_by_slot(to_state.slot_index)
	var moving_snapshot := from_state.create_card_snapshot()
	if from_card == null or to_card == null:
		to_state.apply_card_snapshot(moving_snapshot)
		from_state.clear_card()
		refresh_action_available_hints()
		refresh_debug_panel()
		return

	is_resolving_card_action = true
	await card_animation_controller.play_card_to_empty_slot(self, from_card, to_card)
	to_state.apply_card_snapshot(moving_snapshot)
	from_state.clear_card()
	is_resolving_card_action = false
	refresh_action_available_hints()
	refresh_debug_panel()


func animate_refill_board_slot(slot_index: int, card_data: CardData) -> void:
	var state: CardState = get_board_state(slot_index)
	var target_card: Card = get_card_by_slot(slot_index)
	if state == null or target_card == null or card_data == null:
		return

	if card_pool_view_controller.view == null or card_pool_view_controller.animation_root == null:
		state.set_card_data(card_data)
		state.set_face_up(false)
		refresh_action_available_hints()
		refresh_debug_panel()
		return

	is_resolving_card_action = true
	target_card.is_animating = true

	var card_back_texture: Texture2D = card_data.back_texture
	if card_back_texture == null:
		card_back_texture = get_card_back_texture_for_level(card_data.level)

	await card_pool_view_controller.play_refill_animation(self, target_card, card_back_texture)

	if state.is_empty():
		state.set_card_data(card_data)
		state.set_face_up(false)

	target_card.is_animating = false
	is_resolving_card_action = false
	refresh_action_available_hints()
	refresh_debug_panel()


func cancel_interaction() -> void:
	# 预留给后续“取消”按钮或右键取消调用。
	hide_action_menu()
	hand_interaction_controller.clear_anchor()
	interaction_manager.cancel(board_states)


func return_to_action_menu() -> void:
	# 目标选择阶段通过通用取消输入退回焦点菜单，不占用任何卡牌目标点击。
	if interaction_manager.focused_state == null and interaction_manager.selected_hand_card_data == null:
		cancel_interaction()
		return

	interaction_manager.return_to_card_selection(board_states)
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

	interaction_manager.start_action_selection(action, board_states, self)


func get_card_by_slot(slot_index: int) -> Card:
	if slot_index < 0 or slot_index >= board_cards.size():
		return null

	return board_cards[slot_index]


func execute_action_without_target(action: CardAction) -> void:
	if action == null or interaction_manager.focused_state == null:
		return

	is_executing_action = true
	await action.execute(interaction_manager.focused_state, null, self)
	is_executing_action = false


func _on_card_state_changed(state: CardState) -> void:
	refresh_debug_panel()


func _on_player_state_changed(state: PlayerState) -> void:
	check_victory()
	update_turn_status_view()
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


func find_board_cards() -> Array[Card]:
	# 从指定的 CardBoard 节点开始递归查找所有卡牌实例。
	var cards: Array[Card] = []
	var card_board := get_node_or_null(card_board_path)

	if card_board == null:
		return cards

	collect_cards(card_board, cards)
	return cards


func collect_cards(node: Node, cards: Array[Card]) -> void:
	# 深度优先遍历 CardBoard 下的所有节点。
	if node is Card:
		cards.append(node)

	for child in node.get_children():
		collect_cards(child, cards)
