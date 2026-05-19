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
	tick_hand_cooldowns()
	gain_mana(1)
	state_changed.emit(self)


func end_turn() -> void:
	# 第一版结束回合暂时不清理资源，只广播状态变化。
	# 后续可以在这里处理弃牌、持续效果、回合结束触发等逻辑。
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
