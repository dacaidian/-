extends RefCounted
class_name MatchSetup

# MatchSetup 保存进入一局游戏前的玩家配置。
# 入口 UI 只负责展示和修改它；GameManager 只接收最终结果。

var player_names: Array[String] = []
var player_faction_ids: Array[String] = []
var selected_hero_card_ids: Array[String] = []
var player_ai_flags: Array[bool] = []
var player_ai_difficulties: Array[String] = []


func initialize_defaults(
	card_database: CardDatabase,
	available_faction_ids: Array[String],
	default_player_names: Array[String],
	player_count: int
) -> void:
	player_names.clear()
	player_faction_ids.clear()
	selected_hero_card_ids.clear()
	player_ai_flags.clear()
	player_ai_difficulties.clear()

	for index in range(player_count):
		player_names.append(default_player_names[index] if index < default_player_names.size() else "Player %d" % (index + 1))

		var faction_id := ""
		if index < available_faction_ids.size():
			faction_id = available_faction_ids[index]

		player_faction_ids.append(faction_id)
		selected_hero_card_ids.append(get_default_hero(card_database, faction_id))
		player_ai_flags.append(false)
		player_ai_difficulties.append("normal")


func set_faction(
	player_index: int,
	faction_id: String,
	available_faction_ids: Array[String],
	card_database: CardDatabase
) -> void:
	if not is_valid_player_index(player_index) or faction_id == "":
		return

	player_faction_ids[player_index] = faction_id
	selected_hero_card_ids[player_index] = get_default_hero(card_database, faction_id)
	ensure_distinct_factions(player_index, available_faction_ids, card_database)


func set_hero(player_index: int, hero_card_id: String) -> void:
	if not is_valid_player_index(player_index):
		return

	selected_hero_card_ids[player_index] = hero_card_id


func ensure_distinct_factions(
	changed_player_index: int,
	available_faction_ids: Array[String],
	card_database: CardDatabase
) -> void:
	var changed_faction_id := get_faction_id(changed_player_index)
	if changed_faction_id == "":
		return

	for player_index in range(player_faction_ids.size()):
		if player_index == changed_player_index:
			continue
		if player_faction_ids[player_index] != changed_faction_id:
			continue

		for faction_id in available_faction_ids:
			if faction_id == changed_faction_id or player_faction_ids.has(faction_id):
				continue

			player_faction_ids[player_index] = faction_id
			selected_hero_card_ids[player_index] = get_default_hero(card_database, faction_id)
			break


func can_start() -> bool:
	if player_faction_ids.size() < 2 or selected_hero_card_ids.size() < 2:
		return false

	var seen_factions: Array[String] = []
	for index in range(player_faction_ids.size()):
		var faction_id := player_faction_ids[index]
		var hero_id := selected_hero_card_ids[index]
		if faction_id == "" or hero_id == "":
			return false
		if seen_factions.has(faction_id):
			return false

		seen_factions.append(faction_id)

	return true


func get_start_warning(available_faction_ids: Array[String]) -> String:
	if available_faction_ids.size() < 2:
		return "至少需要两个可选种族"
	if has_duplicate_factions():
		return "两名玩家不能选择相同种族"
	return "请选择双方种族与英雄"


func has_duplicate_factions() -> bool:
	var seen_factions: Array[String] = []
	for faction_id in player_faction_ids:
		if faction_id == "":
			continue
		if seen_factions.has(faction_id):
			return true
		seen_factions.append(faction_id)

	return false


func get_faction_id(player_index: int) -> String:
	if player_index < 0 or player_index >= player_faction_ids.size():
		return ""

	return player_faction_ids[player_index]


func get_hero_id(player_index: int) -> String:
	if player_index < 0 or player_index >= selected_hero_card_ids.size():
		return ""

	return selected_hero_card_ids[player_index]


func is_valid_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < player_faction_ids.size()


func get_default_hero(card_database: CardDatabase, faction_id: String) -> String:
	if card_database == null or faction_id == "":
		return ""

	return card_database.get_default_hero_id(faction_id)


func set_ai_control(player_index: int, is_ai: bool) -> void:
	if not is_valid_player_index(player_index):
		return
	player_ai_flags[player_index] = is_ai


func set_ai_difficulty(player_index: int, difficulty: String) -> void:
	if not is_valid_player_index(player_index):
		return
	if difficulty in ["easy", "normal", "hard"]:
		player_ai_difficulties[player_index] = difficulty


func get_ai_flag(player_index: int) -> bool:
	if player_index < 0 or player_index >= player_ai_flags.size():
		return false
	return player_ai_flags[player_index]


func get_ai_difficulty(player_index: int) -> String:
	if player_index < 0 or player_index >= player_ai_difficulties.size():
		return "normal"
	return player_ai_difficulties[player_index]
