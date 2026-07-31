extends RefCounted
class_name CardReserveResolver

# 缺口驱动的有限随从库存。配置定义库存，玩家运行时只保存剩余牌和冷却。
const RUNTIME_KEY_PREFIX := "card_reserve:"
const INACTIVE_COOLDOWN := -1

var random := RandomNumberGenerator.new()


func _init() -> void:
	random.randomize()


func refresh_player(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	var configs := collect_active_reserve_configs(player)
	for raw_reserve_id in configs.keys():
		var reserve_id := str(raw_reserve_id)
		var config: Dictionary = configs.get(reserve_id, {})
		reconcile_reserve(player, game_manager, reserve_id, config)


func advance_owner_turn(player: PlayerState, game_manager: GameManager) -> void:
	if player == null or game_manager == null:
		return

	refresh_player(player, game_manager)
	var configs := collect_active_reserve_configs(player)
	for raw_reserve_id in configs.keys():
		var reserve_id := str(raw_reserve_id)
		var config: Dictionary = configs.get(reserve_id, {})
		var runtime := get_runtime(player, reserve_id)
		if runtime.is_empty():
			continue

		var capacity := calculate_effective_capacity(player, reserve_id, config)
		var active_count := count_active_reserve_cards(player, game_manager, config)
		var remaining_pool: Array = runtime.get("remaining_pool", [])
		if capacity <= 0 or active_count >= capacity or remaining_pool.is_empty():
			runtime["cooldown_remaining"] = INACTIVE_COOLDOWN
			save_runtime(player, reserve_id, runtime)
			continue

		var cooldown_remaining := int(runtime.get("cooldown_remaining", INACTIVE_COOLDOWN))
		if cooldown_remaining < 0:
			cooldown_remaining = EffectData.get_reserve_cooldown_turns(config)
		if cooldown_remaining > 0:
			cooldown_remaining -= 1

		if cooldown_remaining <= 0:
			var deficit := maxi(capacity - active_count, 0)
			draw_from_reserve(player, game_manager, runtime, deficit, config)
			active_count = count_active_reserve_cards(player, game_manager, config)
			remaining_pool = runtime.get("remaining_pool", [])
			cooldown_remaining = (
				EffectData.get_reserve_cooldown_turns(config)
				if active_count < capacity and not remaining_pool.is_empty()
				else INACTIVE_COOLDOWN
			)

		runtime["cooldown_remaining"] = cooldown_remaining
		save_runtime(player, reserve_id, runtime)


func get_hand_view_data(player: PlayerState, game_manager: GameManager) -> Dictionary:
	var views: Dictionary = {}
	if player == null or game_manager == null:
		return views

	for hand_index in range(player.hand.size()):
		var card_data := HandCardState.get_card_data(player.hand[hand_index])
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not is_reserve_source_effect(effect_data):
				continue

			var reserve_id := EffectData.get_reserve_id(effect_data)
			if reserve_id == "":
				continue

			var runtime := get_runtime(player, reserve_id)
			var capacity := calculate_effective_capacity(player, reserve_id, effect_data)
			var active_count := count_active_reserve_cards(player, game_manager, effect_data)
			var remaining_pool: Array = runtime.get("remaining_pool", [])
			var cooldown_remaining := int(runtime.get("cooldown_remaining", INACTIVE_COOLDOWN))
			views[hand_index] = {
				"reserve_id": reserve_id,
				"capacity": capacity,
				"active_count": active_count,
				"remaining_stock": remaining_pool.size(),
				"cooldown_remaining": cooldown_remaining,
				"is_exhausted": remaining_pool.is_empty() and active_count < capacity,
			}
			break

	return views


func reconcile_reserve(
	player: PlayerState,
	game_manager: GameManager,
	reserve_id: String,
	config: Dictionary
) -> void:
	var runtime_key := get_runtime_key(reserve_id)
	var is_new_runtime := not player.effect_runtime_values.has(runtime_key)
	var runtime := get_runtime(player, reserve_id)
	if is_new_runtime:
		runtime = create_runtime(config)

	var capacity := calculate_effective_capacity(player, reserve_id, config)
	var previous_capacity := int(runtime.get("last_capacity", capacity))
	var active_count := count_active_reserve_cards(player, game_manager, config)
	if is_new_runtime:
		draw_from_reserve(player, game_manager, runtime, maxi(capacity - active_count, 0), config)
	elif capacity > previous_capacity:
		var capacity_gain := capacity - previous_capacity
		var deficit := maxi(capacity - active_count, 0)
		draw_from_reserve(player, game_manager, runtime, mini(capacity_gain, deficit), config)

	runtime["last_capacity"] = capacity
	active_count = count_active_reserve_cards(player, game_manager, config)
	var remaining_pool: Array = runtime.get("remaining_pool", [])
	if capacity <= 0 or active_count >= capacity or remaining_pool.is_empty():
		runtime["cooldown_remaining"] = INACTIVE_COOLDOWN
	elif int(runtime.get("cooldown_remaining", INACTIVE_COOLDOWN)) < 0:
		runtime["cooldown_remaining"] = EffectData.get_reserve_cooldown_turns(config)

	save_runtime(player, reserve_id, runtime)


func collect_active_reserve_configs(player: PlayerState) -> Dictionary:
	var configs: Dictionary = {}
	if player == null:
		return configs

	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null:
			continue

		for effect_data in card_data.effects:
			if not is_reserve_source_effect(effect_data):
				continue

			var reserve_id := EffectData.get_reserve_id(effect_data)
			if reserve_id == "":
				continue

			if not configs.has(reserve_id):
				configs[reserve_id] = effect_data
				continue

			var current_config: Dictionary = configs.get(reserve_id, {})
			if EffectData.get_reserve_capacity(effect_data) > EffectData.get_reserve_capacity(current_config):
				configs[reserve_id] = effect_data

	return configs


func calculate_effective_capacity(player: PlayerState, reserve_id: String, config: Dictionary) -> int:
	var capacity := EffectData.get_reserve_capacity(config)
	if player == null or reserve_id == "":
		return capacity

	for card_entry in player.hand:
		var card_data := HandCardState.get_card_data(card_entry)
		if card_data == null:
			continue
		for effect_data in card_data.effects:
			if EffectData.get_id(effect_data) != EffectData.EFFECT_MODIFY_CARD_RESERVE_CAPACITY:
				continue
			if not is_active_hand_effect(effect_data):
				continue
			if EffectData.get_reserve_id(effect_data) != reserve_id:
				continue
			capacity += EffectData.get_amount(effect_data)

	return maxi(capacity, 0)


func count_active_reserve_cards(
	player: PlayerState,
	game_manager: GameManager,
	config: Dictionary
) -> int:
	var pool_ids := get_pool_card_ids(config)
	var zones := EffectData.get_reserve_count_zones(config)
	var count := 0
	if zones.has(EffectData.COUNT_ZONE_HAND):
		for card_entry in player.hand:
			var card_data := HandCardState.get_card_data(card_entry)
			if card_data != null and pool_ids.has(card_data.id):
				count += 1

	if zones.has(EffectData.COUNT_ZONE_BOARD):
		for state in game_manager.get_all_board_states():
			if state == null or state.is_empty() or not state.is_face_up or not state.is_minion():
				continue
			if state.owner_id != player.id:
				continue
			for card_id in pool_ids:
				if state.represents_card_id(card_id):
					count += 1
					break

	return count


func draw_from_reserve(
	player: PlayerState,
	game_manager: GameManager,
	runtime: Dictionary,
	amount: int,
	config: Dictionary = {}
) -> int:
	var remaining_pool: Array = runtime.get("remaining_pool", [])
	var granted := 0
	while granted < amount and not remaining_pool.is_empty():
		var selected_index := random.randi_range(0, remaining_pool.size() - 1)
		var card_id := str(remaining_pool.pop_at(selected_index))
		var card_data := game_manager.get_card_data_by_id(card_id)
		if card_data == null or not card_data.is_minion():
			push_warning("随从库忽略无效随从卡: %s" % card_id)
			continue

		player.add_to_hand(card_data)
		granted += 1

	runtime["remaining_pool"] = remaining_pool
	var animation_key := str(config.get(EffectData.KEY_ANIMATION, ""))
	if granted > 0 and animation_key != "" and game_manager.has_method("play_board_effect_animation"):
		game_manager.call_deferred("play_board_effect_animation", animation_key)
	return granted


func create_runtime(config: Dictionary) -> Dictionary:
	var remaining_pool: Array[String] = []
	for pool_entry in EffectData.get_reserve_pool(config):
		var card_id := EffectData.get_card_id(pool_entry)
		var count := maxi(int(pool_entry.get("count", 1)), 0)
		for _copy_index in range(count):
			remaining_pool.append(card_id)

	return {
		"remaining_pool": remaining_pool,
		"cooldown_remaining": INACTIVE_COOLDOWN,
		"last_capacity": EffectData.get_reserve_capacity(config),
		"initialized": true,
	}


func get_pool_card_ids(config: Dictionary) -> Array[String]:
	var card_ids: Array[String] = []
	for pool_entry in EffectData.get_reserve_pool(config):
		var card_id := EffectData.get_card_id(pool_entry)
		if card_id != "" and not card_ids.has(card_id):
			card_ids.append(card_id)

	return card_ids


func is_reserve_source_effect(effect_data: Dictionary) -> bool:
	return (
		EffectData.get_id(effect_data) == EffectData.EFFECT_MAINTAIN_CARD_RESERVE
		and is_active_hand_effect(effect_data)
	)


func is_active_hand_effect(effect_data: Dictionary) -> bool:
	var trigger := EffectData.get_trigger(effect_data)
	var active_zone := EffectData.get_active_zone(effect_data)
	return (
		(trigger == EffectData.TRIGGER_WHILE_IN_HAND or trigger == EffectData.TRIGGER_PASSIVE)
		and (active_zone == "" or active_zone == EffectData.ACTIVE_ZONE_HAND)
	)


func get_runtime(player: PlayerState, reserve_id: String) -> Dictionary:
	var stored: Variant = player.get_effect_runtime_value(get_runtime_key(reserve_id), {})
	if stored is Dictionary:
		return (stored as Dictionary).duplicate(true)
	return {}


func save_runtime(player: PlayerState, reserve_id: String, runtime: Dictionary) -> void:
	var runtime_key := get_runtime_key(reserve_id)
	var stored: Variant = player.get_effect_runtime_value(runtime_key, null)
	if stored is Dictionary and stored == runtime:
		return
	player.set_effect_runtime_value(runtime_key, runtime.duplicate(true))


func get_runtime_key(reserve_id: String) -> String:
	return "%s%s" % [RUNTIME_KEY_PREFIX, reserve_id]
