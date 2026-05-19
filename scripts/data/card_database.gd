extends RefCounted
class_name CardDatabase

# CardDatabase 负责读取并缓存所有 JSON 静态卡牌数据。
# GameManager 不直接解析 JSON，而是通过这个类查询卡牌池。

var factions_by_id: Dictionary = {}
var cards_by_id: Dictionary = {}
var cards_by_faction_id: Dictionary = {}
var faction_ids_in_load_order: Array[String] = []

# 测试模式：白名单过滤 + count 覆盖，不修改 cards.json
var is_test_mode := false
var test_config: Dictionary = {}


func load_test_config(path: String) -> void:
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	var parsed_data = JSON.parse_string(json_text)

	if parsed_data == null or not parsed_data is Dictionary:
		return

	test_config = parsed_data
	is_test_mode = test_config.get("enabled", false)


func is_card_allowed_in_test_mode(card_id: String, faction_id: String) -> bool:
	var faction_cards: Array = test_config.get("cards", {}).get(faction_id, [])
	return faction_cards.has(card_id)


func get_test_count_override(_card_id: String) -> int:
	var overrides: Dictionary = test_config.get("override_counts", {})
	var default_count: int = overrides.get("_default", -1)
	return overrides.get(_card_id, default_count)


func _should_include_neutral_pool() -> bool:
	return test_config.get("include_neutral_pool", true)


func get_test_game_param(param_name: String, default_value):
	return test_config.get("game_params", {}).get(param_name, default_value)


func load_from_json(path: String) -> bool:
	# 入口方法：读取 JSON 文件，并把内容缓存到几个 Dictionary 中。
	if not FileAccess.file_exists(path):
		push_error("CardDatabase 找不到卡牌配置文件: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	var parsed_data = JSON.parse_string(json_text)

	# JSON.parse_string 失败时会返回 null。
	if parsed_data == null:
		push_error("CardDatabase 解析 JSON 失败: %s" % path)
		return false

	# 当前 cards.json 的根节点设计为数组，每个元素是一组种族/阵营数据。
	if not parsed_data is Array:
		push_error("CardDatabase 期望 JSON 根节点是数组: %s" % path)
		return false

	# 重新加载前清空旧缓存，避免重复初始化时残留旧数据。
	clear()

	for faction_dictionary in parsed_data:
		if not faction_dictionary is Dictionary:
			continue

		load_faction(faction_dictionary)

	return true


func clear() -> void:
	# 清理所有索引表。
	factions_by_id.clear()
	cards_by_id.clear()
	cards_by_faction_id.clear()
	faction_ids_in_load_order.clear()


func load_faction(faction_dictionary: Dictionary) -> void:
	# 读取一个种族/阵营包，例如 silver_hand。
	var faction_id := str(faction_dictionary.get("id", ""))
	if faction_id == "":
		return

	# factions_by_id 保存原始 faction Dictionary，方便以后读取阵营名称、描述等信息。
	factions_by_id[faction_id] = faction_dictionary
	faction_ids_in_load_order.append(faction_id)

	# cards_by_faction_id 保存这个阵营下的 CardData 列表。
	cards_by_faction_id[faction_id] = []

	var raw_cards = faction_dictionary.get("cards", [])
	if not raw_cards is Array:
		return

	for card_dictionary in raw_cards:
		if not card_dictionary is Dictionary:
			continue

		var card_data := CardData.from_dictionary(card_dictionary, faction_dictionary)
		if card_data.id == "":
			continue

		# 全局按 id 查询。
		cards_by_id[card_data.id] = card_data

		# 按阵营查询。
		cards_by_faction_id[faction_id].append(card_data)

	var raw_tokens = faction_dictionary.get("tokens", [])
	if raw_tokens is Array:
		for token_dictionary in raw_tokens:
			if not token_dictionary is Dictionary:
				continue

			var token_data := CardData.from_dictionary(token_dictionary, faction_dictionary)
			if token_data.id == "":
				continue

			cards_by_id[token_data.id] = token_data

	apply_hero_attachment_metadata(faction_dictionary)


func get_card(card_id: String) -> CardData:
	# 按唯一 id 获取一张静态卡牌数据。
	return cards_by_id.get(card_id) as CardData


func get_faction_cards(faction_id: String) -> Array[CardData]:
	# 返回指定阵营的所有静态卡牌数据。
	var cards: Array[CardData] = []

	for card_data in cards_by_faction_id.get(faction_id, []):
		cards.append(card_data)

	return cards


func get_playable_faction_ids() -> Array[String]:
	var faction_ids: Array[String] = []

	for faction_id in faction_ids_in_load_order:
		if is_neutral_faction(faction_id):
			continue

		faction_ids.append(str(faction_id))

	return faction_ids


func is_neutral_faction(faction_id: String) -> bool:
	var faction = factions_by_id.get(faction_id, {})
	if not faction is Dictionary:
		return false

	return str(faction.get("kind", "")) == "neutral_pool"


func get_faction_display_name(faction_id: String) -> String:
	var faction = factions_by_id.get(faction_id, {})
	if faction is Dictionary:
		return str(faction.get("displayName", faction.get("name", faction_id)))

	return faction_id


func get_faction_description(faction_id: String) -> String:
	var faction = factions_by_id.get(faction_id, {})
	if faction is Dictionary:
		return str(faction.get("description", ""))

	return ""


func get_faction_heroes(faction_id: String) -> Array[CardData]:
	var heroes: Array[CardData] = []
	var faction = factions_by_id.get(faction_id, {})

	if faction is Dictionary:
		var raw_heroes: Variant = faction.get("heroes", [])
		if raw_heroes is Array:
			for hero_entry in raw_heroes:
				var hero_card_id := get_hero_entry_card_id(hero_entry)
				var hero_card := get_card(hero_card_id)
				if hero_card != null and hero_card.is_hero():
					heroes.append(hero_card)

	if not heroes.is_empty():
		return heroes

	for card_data in get_faction_cards(faction_id):
		if card_data != null and card_data.is_hero():
			heroes.append(card_data)

	return heroes


func get_default_hero_id(faction_id: String) -> String:
	var heroes := get_faction_heroes(faction_id)
	if heroes.is_empty():
		return ""

	return heroes[0].id


func get_attached_card_ids(faction_id: String, hero_card_id: String) -> Array[String]:
	var attached_card_ids: Array[String] = []
	var hero_entry := get_hero_entry(faction_id, hero_card_id)
	if hero_entry.is_empty():
		return attached_card_ids

	var raw_attached_cards: Variant = hero_entry.get("attached_cards", [])
	if not raw_attached_cards is Array:
		return attached_card_ids

	for attached_entry in raw_attached_cards:
		var attached_card_id := get_attached_entry_card_id(attached_entry)
		if attached_card_id != "" and not attached_card_ids.has(attached_card_id):
			attached_card_ids.append(attached_card_id)

	return attached_card_ids


func get_all_attached_card_ids(faction_id: String) -> Array[String]:
	var attached_card_ids: Array[String] = []
	var faction = factions_by_id.get(faction_id, {})
	if not faction is Dictionary:
		return attached_card_ids

	var raw_heroes: Variant = faction.get("heroes", [])
	if not raw_heroes is Array:
		return attached_card_ids

	for hero_entry in raw_heroes:
		if not hero_entry is Dictionary:
			continue

		var raw_attached_cards: Variant = hero_entry.get("attached_cards", [])
		if not raw_attached_cards is Array:
			continue

		for attached_entry in raw_attached_cards:
			var attached_card_id := get_attached_entry_card_id(attached_entry)
			if attached_card_id != "" and not attached_card_ids.has(attached_card_id):
				attached_card_ids.append(attached_card_id)

	return attached_card_ids


func get_hero_entry(faction_id: String, hero_card_id: String) -> Dictionary:
	var faction = factions_by_id.get(faction_id, {})
	if not faction is Dictionary:
		return {}

	var raw_heroes: Variant = faction.get("heroes", [])
	if not raw_heroes is Array:
		return {}

	for hero_entry in raw_heroes:
		if not hero_entry is Dictionary:
			continue
		if get_hero_entry_card_id(hero_entry) == hero_card_id:
			return hero_entry

	return {}


func get_hero_entry_card_id(hero_entry: Variant) -> String:
	if hero_entry is Dictionary:
		return str(hero_entry.get("card_id", hero_entry.get("id", "")))

	return str(hero_entry)


func get_attached_entry_card_id(attached_entry: Variant) -> String:
	if attached_entry is Dictionary:
		return str(attached_entry.get("card_id", attached_entry.get("id", "")))

	return str(attached_entry)


func apply_hero_attachment_metadata(faction_dictionary: Dictionary) -> void:
	var faction_id := str(faction_dictionary.get("id", ""))
	if faction_id == "":
		return

	var raw_heroes: Variant = faction_dictionary.get("heroes", [])
	if not raw_heroes is Array:
		return

	for hero_entry in raw_heroes:
		if not hero_entry is Dictionary:
			continue

		var hero_card_id := get_hero_entry_card_id(hero_entry)
		if hero_card_id == "":
			continue

		var raw_attached_cards: Variant = hero_entry.get("attached_cards", [])
		if not raw_attached_cards is Array:
			continue

		for attached_entry in raw_attached_cards:
			var attached_card_id := get_attached_entry_card_id(attached_entry)
			var attached_card := get_card(attached_card_id)
			if attached_card != null and attached_card.faction_id == faction_id:
				attached_card.owner_hero_card_id = hero_card_id


func build_weighted_pool(faction_id: String) -> Array[CardData]:
	var pool: Array[CardData] = []

	if is_test_mode and not _should_include_neutral_pool() and is_neutral_faction(faction_id):
		return pool

	for card_data in get_faction_cards(faction_id):
		if is_test_mode and not is_card_allowed_in_test_mode(card_data.id, faction_id):
			continue
		append_card_copies_to_pool(pool, card_data)

	return pool


func build_weighted_pool_for_selection(faction_id: String, selected_hero_card_id := "") -> Array[CardData]:
	var pool: Array[CardData] = []
	var selected_hero_id := selected_hero_card_id
	if selected_hero_id == "":
		selected_hero_id = get_default_hero_id(faction_id)

	var selected_attached_card_ids := get_attached_card_ids(faction_id, selected_hero_id)
	var all_attached_card_ids := get_all_attached_card_ids(faction_id)

	for card_data in get_faction_cards(faction_id):
		if card_data == null:
			continue

		if is_test_mode and not is_card_allowed_in_test_mode(card_data.id, faction_id):
			continue

		if card_data.is_hero() and card_data.id != selected_hero_id:
			continue

		if all_attached_card_ids.has(card_data.id) and not selected_attached_card_ids.has(card_data.id):
			continue

		append_card_copies_to_pool(pool, card_data)

	return pool


func append_card_copies_to_pool(pool: Array[CardData], card_data: CardData) -> void:
	if card_data == null:
		return

	var copy_count := maxi(card_data.count, 0)
	if is_test_mode:
		var override := get_test_count_override(card_data.id)
		if override >= 0:
			copy_count = override
	for copy_index in range(copy_count):
		pool.append(card_data)
