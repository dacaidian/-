extends Resource
class_name PlayerState

signal state_changed(state: PlayerState)

const MANA_CAPACITY := 5
const DEFAULT_RESOURCE_SCORE := 0

# PlayerState 保存某个玩家自己的运行时状态。
# 未来手牌、牌库、弃牌堆、资源、英雄状态都可以继续放在这里。

var id := ""
var display_name := ""
var faction_id := ""
var faction_name := ""
var selected_hero_card_id := ""
var is_ai := false
var ai_difficulty := "normal"
var faction_runtime_state_config: Dictionary = {}
var faction_runtime_state_id := ""
var faction_runtime_state_name := ""
var faction_runtime_state_card_id := ""
var faction_runtime_state_cycle_index := -1
var faction_runtime_state_cycle_override_ids: Array[String] = []
var faction_resource_configs: Dictionary = {}
var faction_resource_values: Dictionary = {}
var faction_skill_configs: Dictionary = {}
var unlocked_faction_skill_ids: Array[String] = []
var used_faction_skill_ids: Array[String] = []
var has_global_board_vision := false
var visible_board_slots: Array[int] = []

# 资源分是玩家的长期胜利资源。达到战局目标值的玩家会赢得游戏。
var resource_score := DEFAULT_RESOURCE_SCORE

# 当前回合还可以翻开的卡牌数量。
var remaining_flips := 1
var base_flips_per_turn := 1
var max_flips_per_turn := 1
var flip_capacity_bonus := 0

# 法力。每个自己的回合开始时积攒 1 点，使用后消耗，最多保留 5 点。
var mana := 0
var max_mana := MANA_CAPACITY

# 预留区域：以后可以保存 CardState 或 card_id。
var hand: Array = []
var deck: Array = []
var discard_pile: Array = []
var equipped_cards_by_type: Dictionary = {}
var spell_history_sequence := 0
var last_spell_records_by_source_card_id: Dictionary = {}

# 玩家独立坟场，保存离场卡牌的 origin + last_state + death 元数据快照。
var graveyard: Array[Dictionary] = []

func setup(new_id: String, new_display_name: String) -> void:
	# 初始化玩家基础身份信息。
	id = new_id
	display_name = new_display_name
	state_changed.emit(self)


func set_faction(new_faction_id: String, new_faction_name := "") -> void:
	# 记录玩家所属种族；翻牌时会用它判断这张牌是否属于当前玩家。
	faction_id = new_faction_id
	faction_name = new_faction_name
	state_changed.emit(self)


func set_selected_hero(card_id: String) -> void:
	selected_hero_card_id = card_id
	state_changed.emit(self)


func setup_faction_runtime_state(config: Dictionary) -> void:
	faction_runtime_state_config = config.duplicate(true)
	faction_runtime_state_id = ""
	faction_runtime_state_name = ""
	faction_runtime_state_card_id = ""
	faction_runtime_state_cycle_index = -1
	faction_runtime_state_cycle_override_ids.clear()

	var cycle := get_faction_runtime_state_cycle()
	if cycle.is_empty():
		state_changed.emit(self)
		return

	var default_state_id := str(faction_runtime_state_config.get("default_state_id", ""))
	var default_index := find_faction_runtime_state_index(default_state_id)
	if default_index < 0:
		default_index = 0

	set_faction_runtime_state_by_index(default_index)
	state_changed.emit(self)


func setup_faction_resources(configs: Array[Dictionary]) -> void:
	faction_resource_configs.clear()
	faction_resource_values.clear()

	for config in configs:
		var resource_id := str(config.get("id", ""))
		if resource_id == "":
			continue

		var normalized_config := config.duplicate(true)
		var initial_value := int(normalized_config.get("initial", 0))
		var max_value := int(normalized_config.get("max", initial_value))
		faction_resource_configs[resource_id] = normalized_config
		faction_resource_values[resource_id] = clampi(initial_value, 0, max_value)

	state_changed.emit(self)


func setup_faction_skills(configs: Array[Dictionary]) -> void:
	faction_skill_configs.clear()
	unlocked_faction_skill_ids.clear()
	used_faction_skill_ids.clear()

	for config in configs:
		var skill_id := str(config.get("id", ""))
		if skill_id == "":
			continue

		faction_skill_configs[skill_id] = config.duplicate(true)

	state_changed.emit(self)


func get_faction_resource_config(resource_id: String) -> Dictionary:
	var config: Dictionary = faction_resource_configs.get(resource_id, {})
	return config.duplicate(true)


func get_faction_resource_value(resource_id: String) -> int:
	return int(faction_resource_values.get(resource_id, 0))


func gain_faction_resource(resource_id: String, amount: int) -> void:
	if resource_id == "" or amount == 0:
		return

	var config := get_faction_resource_config(resource_id)
	var max_value := int(config.get("max", 999999))
	var current_value := get_faction_resource_value(resource_id)
	faction_resource_values[resource_id] = clampi(current_value + amount, 0, max_value)
	state_changed.emit(self)


func set_unlocked_faction_skills(skill_ids: Array[String]) -> void:
	var normalized_skill_ids: Array[String] = []
	for skill_id in skill_ids:
		if skill_id == "" or not faction_skill_configs.has(skill_id):
			continue
		if normalized_skill_ids.has(skill_id):
			continue
		normalized_skill_ids.append(skill_id)

	unlocked_faction_skill_ids = normalized_skill_ids
	for index in range(used_faction_skill_ids.size() - 1, -1, -1):
		if not unlocked_faction_skill_ids.has(used_faction_skill_ids[index]):
			used_faction_skill_ids.remove_at(index)

	state_changed.emit(self)


func get_unlocked_faction_skill_configs() -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	for skill_id in unlocked_faction_skill_ids:
		var config: Dictionary = faction_skill_configs.get(skill_id, {})
		if config.is_empty():
			continue
		configs.append(config.duplicate(true))
	return configs


func can_use_faction_skill(skill_id: String) -> bool:
	return unlocked_faction_skill_ids.has(skill_id) and not used_faction_skill_ids.has(skill_id)


func register_faction_skill_use(skill_id: String) -> bool:
	if not can_use_faction_skill(skill_id):
		return false

	used_faction_skill_ids.append(skill_id)
	state_changed.emit(self)
	return true


func has_faction_runtime_state() -> bool:
	return not get_effective_faction_runtime_state_cycle().is_empty()


func get_faction_runtime_state_title() -> String:
	return str(faction_runtime_state_config.get("name", ""))


func should_advance_faction_runtime_state_on(trigger: String) -> bool:
	if not has_faction_runtime_state():
		return false

	return str(faction_runtime_state_config.get("advance_trigger", "after_turn_end")) == trigger


func get_faction_runtime_state_cycle() -> Array:
	var raw_cycle: Variant = faction_runtime_state_config.get("cycle", [])
	if raw_cycle is Array:
		return raw_cycle

	return []


func get_effective_faction_runtime_state_cycle() -> Array:
	var cycle := get_faction_runtime_state_cycle()
	if faction_runtime_state_cycle_override_ids.is_empty():
		return cycle

	var filtered_cycle: Array = []
	for entry in cycle:
		if not entry is Dictionary:
			continue
		var state_id := str(entry.get("id", ""))
		if faction_runtime_state_cycle_override_ids.has(state_id):
			filtered_cycle.append(entry)

	return filtered_cycle


func find_faction_runtime_state_index(state_id: String) -> int:
	if state_id == "":
		return -1

	var cycle := get_effective_faction_runtime_state_cycle()
	for index in range(cycle.size()):
		var entry: Variant = cycle[index]
		if not entry is Dictionary:
			continue
		if str(entry.get("id", "")) == state_id:
			return index

	return -1


func set_faction_runtime_state_by_id(state_id: String) -> bool:
	var index := find_faction_runtime_state_index(state_id)
	if index < 0:
		return false

	set_faction_runtime_state_by_index(index)
	state_changed.emit(self)
	return true


func set_faction_runtime_state_by_index(index: int) -> void:
	var cycle := get_effective_faction_runtime_state_cycle()
	if cycle.is_empty():
		return

	var normalized_index := posmod(index, cycle.size())
	var entry: Variant = cycle[normalized_index]
	if not entry is Dictionary:
		return

	faction_runtime_state_cycle_index = normalized_index
	faction_runtime_state_id = str(entry.get("id", ""))
	faction_runtime_state_name = str(entry.get("name", faction_runtime_state_id))
	faction_runtime_state_card_id = str(entry.get("card_id", ""))


func advance_faction_runtime_state() -> bool:
	if not has_faction_runtime_state():
		return false

	set_faction_runtime_state_by_index(faction_runtime_state_cycle_index + 1)
	state_changed.emit(self)
	return true


func set_faction_runtime_state_cycle_override(state_ids: Array[String], fallback_state_id := "") -> bool:
	var normalized_state_ids: Array[String] = []
	for state_id in state_ids:
		if state_id != "" and not normalized_state_ids.has(state_id):
			normalized_state_ids.append(state_id)

	var did_change := normalized_state_ids != faction_runtime_state_cycle_override_ids
	faction_runtime_state_cycle_override_ids = normalized_state_ids

	if not has_faction_runtime_state():
		if did_change:
			state_changed.emit(self)
		return did_change

	var current_index := find_faction_runtime_state_index(faction_runtime_state_id)
	if current_index >= 0:
		set_faction_runtime_state_by_index(current_index)
	else:
		var fallback_index := find_faction_runtime_state_index(fallback_state_id)
		if fallback_state_id != "" and fallback_index >= 0:
			set_faction_runtime_state_by_index(fallback_index)
			did_change = true
		elif not get_effective_faction_runtime_state_cycle().is_empty():
			set_faction_runtime_state_by_index(0)
			did_change = true

	if did_change:
		state_changed.emit(self)

	return did_change


func gain_resource_score(amount: int) -> void:
	if amount <= 0:
		return

	resource_score += amount
	state_changed.emit(self)


func set_resource_score(value: int) -> void:
	resource_score = maxi(value, 0)
	state_changed.emit(self)


func start_turn() -> void:
	# 进入玩家回合时，获得 1 点法力，不会自动回满。
	remaining_flips = max_flips_per_turn
	used_faction_skill_ids.clear()
	tick_hand_cooldowns()
	gain_mana(1)
	state_changed.emit(self)


func end_turn() -> void:
	# 第一版结束回合暂时不清理资源，只广播状态变化。
	# 后续可以在这里处理弃牌、持续效果、回合结束触发等逻辑。
	clear_turn_board_vision(false)
	state_changed.emit(self)



func grant_global_board_vision_until_turn_end() -> void:
	if has_global_board_vision:
		return

	has_global_board_vision = true
	state_changed.emit(self)


func grant_board_slot_vision_until_turn_end(slot_index: int) -> void:
	if slot_index < 0 or visible_board_slots.has(slot_index):
		return

	visible_board_slots.append(slot_index)
	state_changed.emit(self)


func can_preview_board_slot(slot_index: int) -> bool:
	if has_global_board_vision:
		return true

	return visible_board_slots.has(slot_index)


func clear_turn_board_vision(should_emit_changed := true) -> void:
	if not has_global_board_vision and visible_board_slots.is_empty():
		return

	has_global_board_vision = false
	visible_board_slots.clear()
	if should_emit_changed:
		state_changed.emit(self)


func can_flip_card() -> bool:
	# GameManager 点击卡牌前会用这个方法判断是否还能翻牌。
	return remaining_flips > 0


func spend_flip() -> bool:
	# 消耗一次翻牌机会。成功消耗返回 true。
	if not can_flip_card():
		return false

	remaining_flips -= 1
	state_changed.emit(self)
	return true


func gain_flips(amount: int) -> void:
	# 增加当前回合剩余翻牌次数，不改变每回合基础上限。
	if amount <= 0:
		return

	remaining_flips += amount
	state_changed.emit(self)


func set_base_flips_per_turn(value: int) -> void:
	base_flips_per_turn = maxi(value, 0)
	recalculate_flip_capacity()
	state_changed.emit(self)


func set_flip_capacity_bonus(value: int) -> void:
	flip_capacity_bonus = maxi(value, 0)
	recalculate_flip_capacity()
	state_changed.emit(self)


func recalculate_flip_capacity() -> void:
	max_flips_per_turn = base_flips_per_turn + flip_capacity_bonus
	remaining_flips = mini(remaining_flips, max_flips_per_turn)


func gain_mana(amount: int) -> void:
	if amount <= 0:
		return

	mana = mini(mana + amount, max_mana)
	state_changed.emit(self)


func spend_mana(amount: int) -> bool:
	if amount <= 0:
		return true

	if mana < amount:
		return false

	mana -= amount
	state_changed.emit(self)
	return true


func set_mana_capacity(value: int) -> void:
	# 设置法力保留上限，并保证当前法力不会超过上限。
	max_mana = maxi(value, 0)
	mana = mini(mana, max_mana)
	state_changed.emit(self)


func add_to_hand(card_data: CardData) -> void:
	# 这里只负责玩家区域数据变化；是否允许进入手牌由翻牌/区域路由规则先判断。
	if card_data == null:
		return

	hand.append(card_data)
	state_changed.emit(self)


func add_hand_card_state(hand_card_state: HandCardState) -> void:
	if hand_card_state == null or hand_card_state.data == null:
		return

	hand.append(hand_card_state)
	state_changed.emit(self)


func add_to_hand_with_cooldown(
	card_data: CardData,
	cooldown_turns: int,
	source := "",
	tags: Array[String] = []
) -> void:
	if card_data == null:
		return

	var hand_card_state := HandCardState.new()
	hand_card_state.setup(card_data, id, cooldown_turns, source, tags)
	add_hand_card_state(hand_card_state)


func remove_from_hand(card_data: CardData) -> bool:
	if card_data == null:
		return false

	var index := find_hand_card_index(card_data)
	if index < 0:
		return false

	hand.remove_at(index)
	state_changed.emit(self)
	return true


func remove_from_hand_at(hand_index: int, expected_card_data: CardData = null) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false

	if expected_card_data != null and get_hand_card_data_at(hand_index) != expected_card_data:
		return false

	hand.remove_at(hand_index)
	state_changed.emit(self)
	return true


func get_hand_card_data_at(hand_index: int) -> CardData:
	if hand_index < 0 or hand_index >= hand.size():
		return null

	return HandCardState.get_card_data(hand[hand_index])


func get_hand_card_state_at(hand_index: int) -> HandCardState:
	if hand_index < 0 or hand_index >= hand.size():
		return null

	return hand[hand_index] as HandCardState


func is_hand_card_available_at(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= hand.size():
		return false

	return HandCardState.is_entry_available(hand[hand_index])


func find_hand_card_index(card_data: CardData) -> int:
	for index in range(hand.size()):
		if get_hand_card_data_at(index) == card_data:
			return index

	return -1


func tick_hand_cooldowns() -> void:
	var did_change := false
	for entry in hand:
		var hand_card_state := entry as HandCardState
		if hand_card_state == null:
			continue

		if hand_card_state.tick_cooldown():
			did_change = true

	if did_change:
		state_changed.emit(self)


func equip_card(card_data: CardData) -> void:
	if card_data == null or not card_data.is_equipment():
		return

	var equipment_type := card_data.equipment_type
	if equipment_type == "":
		equipment_type = card_data.type

	var replaced_card := equipped_cards_by_type.get(equipment_type) as CardData
	equipped_cards_by_type[equipment_type] = card_data
	if replaced_card != null:
		hand.append(replaced_card)

	state_changed.emit(self)


func record_spell_action(source_card_id: String, spell_data: Dictionary) -> void:
	if source_card_id == "" or spell_data.is_empty():
		return

	spell_history_sequence += 1
	last_spell_records_by_source_card_id[source_card_id] = {
		"source_card_id": source_card_id,
		"spell_data": spell_data.duplicate(true),
		"sequence": spell_history_sequence,
	}
	state_changed.emit(self)


func get_latest_spell_action_for_sources(source_card_ids: Array[String]) -> Dictionary:
	var latest_sequence := -1
	var latest_spell_data: Dictionary = {}

	for source_card_id in source_card_ids:
		var record: Dictionary = last_spell_records_by_source_card_id.get(source_card_id, {})
		if not record is Dictionary:
			continue

		var sequence := int(record.get("sequence", -1))
		if sequence <= latest_sequence:
			continue

		var spell_data: Dictionary = record.get("spell_data", {})
		if not spell_data is Dictionary or spell_data.is_empty():
			continue

		latest_sequence = sequence
		latest_spell_data = spell_data

	return latest_spell_data.duplicate(true)


func get_spell_power_bonus() -> int:
	var bonus := 0
	for card_data in get_equipped_cards():
		for effect_data in card_data.effects:
			if EffectData.get_id(effect_data) == EffectData.EFFECT_MODIFY_SPELL_POWER:
				bonus += EffectData.get_amount(effect_data)

	return bonus


func get_hero_revive_cooldown_modifier(hero_card_id: String = "") -> int:
	var modifier := 0
	for card_data in get_equipped_cards():
		if hero_card_id != "" and card_data.owner_hero_card_id != "" and card_data.owner_hero_card_id != hero_card_id:
			continue

		for effect_data in card_data.effects:
			if EffectData.get_id(effect_data) == EffectData.EFFECT_MODIFY_HERO_REVIVE_COOLDOWN:
				modifier += EffectData.get_amount(effect_data)

	return modifier


func get_equipped_cards() -> Array[CardData]:
	var equipped_cards: Array[CardData] = []
	for card_data in equipped_cards_by_type.values():
		if card_data is CardData:
			equipped_cards.append(card_data)

	return equipped_cards


func add_to_graveyard(card_snapshot: Dictionary) -> void:
	graveyard.append(card_snapshot)
	state_changed.emit(self)


func remove_from_graveyard_at(index: int) -> Dictionary:
	if index < 0 or index >= graveyard.size():
		return {}
	var snapshot: Dictionary = graveyard[index]
	graveyard.remove_at(index)
	state_changed.emit(self)
	return snapshot
