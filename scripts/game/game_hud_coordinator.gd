extends RefCounted
class_name GameHudCoordinator

# 统一编排对局 HUD 的创建、刷新和布局。
# 各 Controller 仍只负责自己的视图；这里不修改规则状态，也不判断卡牌是否合法。


func setup(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.turn_status_controller.setup(game_manager, game_manager.turn_status_panel_path)
	if not game_manager.turn_status_controller.spell_turn_requested.is_connected(game_manager.activate_spell_turn):
		game_manager.turn_status_controller.spell_turn_requested.connect(game_manager.activate_spell_turn)

	var root := game_manager.get_parent() as Control
	game_manager.faction_time_panel_controller.setup(root)
	game_manager.faction_skill_panel_controller.setup(root)
	if not game_manager.faction_skill_panel_controller.skill_requested.is_connected(game_manager._on_faction_skill_requested):
		game_manager.faction_skill_panel_controller.skill_requested.connect(game_manager._on_faction_skill_requested)

	game_manager.hand_interaction_controller.setup(game_manager)
	game_manager.equipment_display_controller.setup(root)
	game_manager.match_exit_controller.setup(root, game_manager)
	if not game_manager.match_exit_controller.surrender_requested.is_connected(game_manager.surrender_match):
		game_manager.match_exit_controller.surrender_requested.connect(game_manager.surrender_match)


func setup_card_pool(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.card_pool_view_controller.setup(
		game_manager,
		game_manager.card_pool_view_path,
		game_manager.card_pool_animation_root_path,
		game_manager.default_back_texture,
		game_manager.card_pool_view_size,
		game_manager.card_pool_view_margin,
		game_manager.refill_animation_duration
	)


func refresh_all(game_manager: GameManager) -> void:
	update_turn_status(game_manager)
	update_faction_time(game_manager)
	update_faction_skill(game_manager)
	update_hand_drawer(game_manager)
	update_match_exit(game_manager)


func update_turn_status(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	var current_player := game_manager.get_current_player()
	var can_activate := (
		current_player != null
		and not game_manager.is_spell_turn_active
		and current_player.mana >= game_manager.spell_turn_mana_cost
	)
	game_manager.turn_status_controller.update(
		current_player,
		game_manager.turn_number,
		game_manager.is_spell_turn_active,
		game_manager.spell_turn_mana_cost,
		can_activate,
		game_manager.victory_resource_score,
		game_manager.is_game_over,
		game_manager.get_winner_player()
	)
	request_right_side_layout(game_manager)


func update_faction_time(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.faction_time_panel_controller.update(
		game_manager.get_current_player(),
		game_manager.card_database,
		game_manager.get_parent() as Control
	)
	request_right_side_layout(game_manager)


func update_faction_skill(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	var current_player := game_manager.get_current_player()
	game_manager.faction_skill_panel_controller.update(
		current_player,
		game_manager.get_parent() as Control,
		game_manager.faction_skill_resolver.get_usable_skill_ids(game_manager, current_player)
	)
	request_right_side_layout(game_manager)


func update_hand_drawer(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.hand_interaction_controller.update_hand_drawer_view(game_manager)
	update_equipment(game_manager)


func update_equipment(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.equipment_display_controller.update(game_manager.get_current_player())
	request_right_side_layout(game_manager)


func update_right_side_layout(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	game_manager.right_side_hud_layout_controller.update(game_manager.get_parent() as Control, [
		game_manager.turn_status_controller.panel,
		game_manager.faction_time_panel_controller.panel,
		game_manager.faction_skill_panel_controller.panel,
		game_manager.equipment_display_controller.panel
	])


func update_card_pool(game_manager: GameManager) -> void:
	if game_manager == null:
		return

	var remaining := 0
	var next_back_texture: Texture2D = game_manager.default_back_texture
	if game_manager.card_pool != null:
		remaining = game_manager.card_pool.remaining()
		next_back_texture = game_manager.get_card_pool_next_back_texture()

	game_manager.card_pool_view_controller.update(
		remaining,
		game_manager.get_parent(),
		next_back_texture
	)


func update_match_exit(game_manager: GameManager) -> void:
	if game_manager == null:
		return
	game_manager.match_exit_controller.update(game_manager.can_surrender())


func request_right_side_layout(game_manager: GameManager) -> void:
	if game_manager == null:
		return
	game_manager.call_deferred("update_right_side_hud_layout")
