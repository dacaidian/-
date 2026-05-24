extends RefCounted
class_name CardPool

# CardPool 是持久化卡牌池，在游戏加载时构建。
# 提供无放回抽取，抽取后卡牌从池中移除。

var _pool: Array[CardData] = []

func _init(faction_id: String, card_database: CardDatabase) -> void:
	if faction_id != "" and card_database != null:
		add_cards(card_database.build_weighted_pool(faction_id), false)
	shuffle()


static func from_factions(faction_ids: Array[String], card_database: CardDatabase) -> CardPool:
	# 把多个种族的卡牌按 count 展开后合并成一个公共牌池。
	var card_pool := CardPool.new("", card_database)

	for faction_id in faction_ids:
		if faction_id == "":
			continue

		card_pool.add_cards(card_database.build_weighted_pool(faction_id), false)

	card_pool.shuffle()
	return card_pool


static func from_match_selection(
	player_faction_ids: Array[String],
	selected_hero_card_ids: Array[String],
	neutral_faction_ids: Array[String],
	card_database: CardDatabase
) -> CardPool:
	var card_pool := CardPool.new("", card_database)
	var excluded_neutral_card_ids := card_database.get_excluded_neutral_card_ids_for_factions(player_faction_ids)

	for index in range(player_faction_ids.size()):
		var faction_id := player_faction_ids[index]
		if faction_id == "":
			continue

		var hero_card_id := ""
		if index < selected_hero_card_ids.size():
			hero_card_id = selected_hero_card_ids[index]

		card_pool.add_cards(card_database.build_weighted_pool_for_selection(faction_id, hero_card_id), false)

	for faction_id in neutral_faction_ids:
		if faction_id == "":
			continue

		card_pool.add_cards(filter_cards_by_excluded_ids(
			card_database.build_weighted_pool(faction_id),
			excluded_neutral_card_ids
		), false)

	card_pool.shuffle()
	return card_pool


func draw_random() -> CardData:
	if _pool.is_empty():
		return null

	var active_level := get_lowest_available_level()
	var available_indices := get_indices_for_level(active_level)
	if available_indices.is_empty():
		return null

	var random_index: int = available_indices[randi_range(0, available_indices.size() - 1)]
	return draw_at(random_index)


func draw_at(index: int) -> CardData:
	if index < 0 or index >= _pool.size():
		return null
	var card := _pool[index]
	_pool.remove_at(index)
	return card


func get_pool() -> Array[CardData]:
	return _pool.duplicate()


func add_card(card_data: CardData, should_shuffle := true) -> void:
	if card_data == null:
		return

	_pool.append(card_data)

	if should_shuffle:
		shuffle()


func add_cards(cards: Array[CardData], should_shuffle := true) -> void:
	for card_data in cards:
		if card_data != null:
			_pool.append(card_data)

	if should_shuffle:
		shuffle()


static func filter_cards_by_excluded_ids(cards: Array[CardData], excluded_card_ids: Array[String]) -> Array[CardData]:
	if excluded_card_ids.is_empty():
		return cards

	var filtered_cards: Array[CardData] = []
	for card_data in cards:
		if card_data == null:
			continue
		if excluded_card_ids.has(card_data.id):
			continue

		filtered_cards.append(card_data)

	return filtered_cards


func is_empty() -> bool:
	return _pool.is_empty()


func remaining() -> int:
	return _pool.size()


func get_lowest_available_level() -> int:
	if _pool.is_empty():
		return 0

	var lowest_level := 999999
	for index in range(_pool.size()):
		var card_data: CardData = _pool[index]
		if card_data == null:
			continue

		lowest_level = mini(lowest_level, card_data.level)

	if lowest_level == 999999:
		return 0

	return lowest_level


func get_indices_for_level(level: int) -> Array[int]:
	var indices: Array[int] = []
	if level <= 0:
		return indices

	for index in range(_pool.size()):
		var card_data: CardData = _pool[index]
		if card_data != null and card_data.level == level:
			indices.append(index)

	return indices


func shuffle() -> void:
	_pool.shuffle()
