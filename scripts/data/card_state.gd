extends Resource
class_name CardState

signal state_changed(state: CardState)

const ACTION_GROUP_MOVE := "move"
const ACTION_GROUP_ATTACK := "attack"
const ACTION_GROUP_SPELL := "spell"
const ACTION_GROUP_SPECIAL := "special"

# CardState 是运行时状态。
# 它引用 CardData，同时保存“这张具体卡牌的初始快照”和当前变化。

# 这张牌在棋盘中的位置，当前是 0 到 24。
var slot_index := -1

# 卡牌所属玩家 id。空字符串表示暂时无人拥有。
var owner_id := ""

# 预留给卡牌数据表或资源 id。
var card_id := ""

# 预留给 UI 展示、日志和调试。
var display_name := ""

# 静态卡牌数据，来自 CardDatabase。
var data: CardData

# 这张具体卡牌进入游戏时的初始属性快照。
# 它和 CardData 的区别是：origin 描述“这一个实例出生时是什么样”，
# 后续坟场、复活、复制可以直接使用它，不需要重新回 JSON 查询。
var origin: Dictionary = {}

# 当前是否允许玩家操作这张牌。
var is_interactable := true

# 当前是否被选中。后续做选牌、拖拽、释放效果时会用到。
var is_selected := false

# 当前是否是某个操作的合法目标，只用于 UI 高亮和调试显示。
var is_valid_target := false

# 当前是否应该显示“可行动”提示。只用于表现层提示，具体可用动作由 ActionRegistry 决定。
var is_action_available_hint := false

var is_area_preview := false

# 当前是否已经进入死亡结算队列。用于批量死亡时避免同一张牌重复入队。
var is_pending_death := false

# 当前是否正面朝上。翻开状态唯一存储在这里。
var is_face_up := false

# 当前实例使用的正反面图片。
var front_texture: Texture2D
var back_texture: Texture2D

# 当前攻击、生命上限、已受伤害和护盾。当前生命由 max_health - damage_taken 计算得出。
var current_attack := 0
var passive_attack_bonus := 0
var passive_keywords: Array[String] = []
var status_attack_bonus := 0
var status_attack_floor_debt := 0
var status_max_health_bonus := 0
var status_control_base_owner_id := ""
var max_health := 0
var damage_taken := 0
var shield := 0
var reborn_health_values: Array[int] = []
var current_health: int:
	get:
		return maxi(max_health - damage_taken, 0)

# 当前移动力。第一版所有随从默认 1 点移动力，之后可以扩展为从 JSON 读取。
var max_movement := 0
var current_movement := 0

# 当前攻击次数。攻速决定每回合最多可以攻击几次，第一版随从默认 1。
var max_attack_speed := 0
var current_attacks := 0
var mounted_attack_max_uses: Dictionary = {}
var mounted_attack_uses: Dictionary = {}

# 当前可开启的行动类别数量。普通随从每回合只能移动、攻击、施法三选一；后续敏捷等能力可扩展。
var max_main_actions := 0
var current_main_actions := 0
var used_action_groups: Array[String] = []
var used_action_ids: Array[String] = []
var allowed_action_group_pairs: Array[String] = []

# 当前附着在这张棋盘牌上的状态，例如中毒、圣盾、冻结、临时增益等。
var statuses: Array[CardStatus] = []


func set_card_data(value: CardData) -> void:
	# 绑定静态数据，并从静态数据初始化运行时数值。
	data = value

	if data == null:
		card_id = ""
		display_name = "空格子"
		owner_id = ""
		front_texture = null
		back_texture = null
		origin.clear()
		current_attack = 0
		passive_attack_bonus = 0
		passive_keywords.clear()
		status_attack_bonus = 0
		status_attack_floor_debt = 0
		status_max_health_bonus = 0
		status_control_base_owner_id = ""
		max_health = 0
		damage_taken = 0
		shield = 0
		reborn_health_values.clear()
		max_movement = 0
		current_movement = 0
		max_attack_speed = 0
		current_attacks = 0
		mounted_attack_max_uses.clear()
		mounted_attack_uses.clear()
		max_main_actions = 0
		current_main_actions = 0
		used_action_groups.clear()
		used_action_ids.clear()
		allowed_action_group_pairs.clear()
		statuses.clear()
		is_face_up = false
		is_selected = false
		is_valid_target = false
		is_action_available_hint = false
		is_pending_death = false
	else:
		card_id = data.id
		display_name = data.display_name
		front_texture = data.front_texture
		back_texture = data.back_texture
		current_attack = data.attack
		passive_attack_bonus = 0
		passive_keywords.clear()
		status_attack_bonus = 0
		status_attack_floor_debt = 0
		status_max_health_bonus = 0
		status_control_base_owner_id = ""
		max_health = data.health
		damage_taken = 0
		shield = 0
		reborn_health_values = create_initial_reborn_health_values()
		is_action_available_hint = false
		is_pending_death = false
		if data.is_minion():
			max_movement = 1
			current_movement = max_movement
			max_attack_speed = maxi(data.attack_speed, 0)
			current_attacks = max_attack_speed
			mounted_attack_max_uses = create_initial_mounted_attack_uses()
			mounted_attack_uses = mounted_attack_max_uses.duplicate(true)
			max_main_actions = 1
			current_main_actions = max_main_actions
			used_action_groups.clear()
			used_action_ids.clear()
			allowed_action_group_pairs.clear()
			apply_keyword_passives()
		elif data.is_building():
			max_movement = 0
			current_movement = 0
			max_attack_speed = 0
			current_attacks = 0
			mounted_attack_max_uses.clear()
			mounted_attack_uses.clear()
			max_main_actions = 1
			current_main_actions = max_main_actions
			used_action_groups.clear()
			used_action_ids.clear()
			allowed_action_group_pairs.clear()
		else:
			max_movement = 0
			current_movement = 0
			max_attack_speed = 0
			current_attacks = 0
			mounted_attack_max_uses.clear()
			mounted_attack_uses.clear()
			max_main_actions = 0
			current_main_actions = 0
			used_action_groups.clear()
			used_action_ids.clear()
			allowed_action_group_pairs.clear()
		statuses.clear()
		origin = create_origin_snapshot()

	state_changed.emit(self)


func set_face_up(value: bool) -> void:
	# 翻面状态只能通过这里修改，确保所有监听者都会收到 state_changed。
	if is_face_up == value:
		return

	is_face_up = value
	state_changed.emit(self)


func toggle_face_up() -> void:
	# 便捷方法：在正面和背面之间切换。
	if is_empty():
		return

	set_face_up(not is_face_up)


func is_empty() -> bool:
	# 没有绑定 CardData 时，这个状态代表棋盘上的一个空格子。
	return data == null


func is_minion() -> bool:
	return data != null and data.is_minion()


func is_building() -> bool:
	return data != null and data.is_building()


func is_unit() -> bool:
	return data != null and data.is_unit()


func is_hero() -> bool:
	return data != null and data.is_hero()


func is_flying() -> bool:
	return has_keyword(CardData.KEYWORD_FLYING)


func uses_minion_action_resources() -> bool:
	return is_minion()


func has_keyword(keyword: String) -> bool:
	return (data != null and data.has_keyword(keyword)) or passive_keywords.has(keyword)


func get_siege_bonus() -> int:
	var bonus := data.get_siege_bonus() if data != null else 0
	for keyword in passive_keywords:
		if not keyword.begins_with(CardData.KEYWORD_SIEGE_PREFIX):
			continue

		var amount_text := keyword.substr(CardData.KEYWORD_SIEGE_PREFIX.length())
		if not amount_text.is_valid_int():
			continue

		bonus = maxi(bonus, int(amount_text))

	return bonus


func apply_keyword_passives() -> void:
	if has_keyword(CardData.KEYWORD_CAVALRY):
		apply_cavalry_passive()
	if has_keyword(CardData.KEYWORD_MOBILE_ASSAULT):
		apply_mobile_assault_passive()
	if has_keyword(CardData.KEYWORD_SPELL_MOVE):
		apply_spell_move_passive()
	if has_keyword(CardData.KEYWORD_SPELL_ATTACK):
		apply_spell_attack_passive()


func apply_cavalry_passive() -> void:
	max_movement = 3
	current_movement = max_movement
	max_main_actions = maxi(max_main_actions, 2)
	current_main_actions = max_main_actions
	allow_action_group_pair(ACTION_GROUP_MOVE, ACTION_GROUP_ATTACK, false)


func apply_mobile_assault_passive() -> void:
	max_main_actions = maxi(max_main_actions, 2)
	current_main_actions = max_main_actions
	allow_action_group_pair(ACTION_GROUP_MOVE, ACTION_GROUP_ATTACK, false)


func apply_spell_move_passive() -> void:
	max_main_actions = maxi(max_main_actions, 2)
	current_main_actions = max_main_actions
	allow_action_group_pair(ACTION_GROUP_MOVE, ACTION_GROUP_SPELL, false)


func apply_spell_attack_passive() -> void:
	max_main_actions = maxi(max_main_actions, 2)
	current_main_actions = max_main_actions
	allow_action_group_pair(ACTION_GROUP_ATTACK, ACTION_GROUP_SPELL, false)


func create_initial_reborn_health_values() -> Array[int]:
	var values: Array[int] = []
	if data == null:
		return values

	for keyword in data.keywords:
		var value := get_reborn_health_value_from_keyword(keyword)
		if value >= 0:
			values.append(value)

	return values


func get_reborn_health_value_from_keyword(keyword: String) -> int:
	if keyword == CardData.KEYWORD_REBORN:
		return 0
	if keyword.begins_with(CardData.KEYWORD_REBORN_PREFIX):
		var amount_text := keyword.substr(CardData.KEYWORD_REBORN_PREFIX.length())
		if amount_text.is_valid_int():
			return maxi(int(amount_text), 0)

	return -1


func clear_card() -> void:
	# 牌离开棋盘后，格子仍然保留，但卡牌数据被清空。
	set_card_data(null)


func swap_card_content_with(other_state: CardState) -> void:
	# 交换两个格子里的“卡牌内容”，但保留各自的 slot_index 和 UI 绑定关系。
	if other_state == null:
		return

	var self_snapshot: Dictionary = create_card_snapshot()
	var other_snapshot: Dictionary = other_state.create_card_snapshot()
	apply_card_snapshot(other_snapshot)
	other_state.apply_card_snapshot(self_snapshot)


func create_card_snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"card_id": card_id,
		"display_name": display_name,
		"data": data,
		"origin": origin.duplicate(true),
		"is_face_up": is_face_up,
		"front_texture": front_texture,
		"back_texture": back_texture,
		"current_attack": current_attack,
		"passive_attack_bonus": passive_attack_bonus,
		"passive_keywords": passive_keywords.duplicate(),
		"status_attack_bonus": status_attack_bonus,
		"status_attack_floor_debt": status_attack_floor_debt,
		"status_max_health_bonus": status_max_health_bonus,
		"status_control_base_owner_id": status_control_base_owner_id,
		"max_health": max_health,
		"damage_taken": damage_taken,
		"shield": shield,
		"reborn_health_values": reborn_health_values.duplicate(),
		"max_movement": max_movement,
		"current_movement": current_movement,
		"max_attack_speed": max_attack_speed,
		"current_attacks": current_attacks,
		"mounted_attack_max_uses": mounted_attack_max_uses.duplicate(true),
		"mounted_attack_uses": mounted_attack_uses.duplicate(true),
		"max_main_actions": max_main_actions,
		"current_main_actions": current_main_actions,
		"used_action_groups": used_action_groups.duplicate(),
		"used_action_ids": used_action_ids.duplicate(),
		"allowed_action_group_pairs": allowed_action_group_pairs.duplicate(),
		"statuses": create_status_snapshots(),
		"is_action_available_hint": is_action_available_hint
	}


func apply_card_snapshot(snapshot: Dictionary) -> void:
	owner_id = str(snapshot.get("owner_id", ""))
	card_id = str(snapshot.get("card_id", ""))
	display_name = str(snapshot.get("display_name", ""))
	data = snapshot.get("data") as CardData
	var snapshot_origin = snapshot.get("origin", {})
	if snapshot_origin is Dictionary:
		origin = snapshot_origin.duplicate(true)
	else:
		origin = {}
	is_face_up = bool(snapshot.get("is_face_up", false))
	front_texture = snapshot.get("front_texture") as Texture2D
	back_texture = snapshot.get("back_texture") as Texture2D
	current_attack = int(snapshot.get("current_attack", 0))
	passive_attack_bonus = int(snapshot.get("passive_attack_bonus", 0))
	passive_keywords = normalize_string_array(snapshot.get("passive_keywords", []))
	status_attack_bonus = int(snapshot.get("status_attack_bonus", 0))
	status_attack_floor_debt = int(snapshot.get("status_attack_floor_debt", 0))
	status_max_health_bonus = int(snapshot.get("status_max_health_bonus", 0))
	status_control_base_owner_id = str(snapshot.get("status_control_base_owner_id", ""))
	max_health = int(snapshot.get("max_health", snapshot.get("current_health", 0)))
	damage_taken = int(snapshot.get("damage_taken", 0))
	shield = int(snapshot.get("shield", 0))
	reborn_health_values = normalize_int_array(snapshot.get("reborn_health_values", []))
	max_movement = int(snapshot.get("max_movement", 0))
	current_movement = int(snapshot.get("current_movement", 0))
	max_attack_speed = int(snapshot.get("max_attack_speed", 0))
	current_attacks = int(snapshot.get("current_attacks", 0))
	mounted_attack_max_uses = normalize_int_dictionary(snapshot.get("mounted_attack_max_uses", {}))
	mounted_attack_uses = normalize_int_dictionary(snapshot.get("mounted_attack_uses", {}))
	max_main_actions = int(snapshot.get("max_main_actions", 0))
	current_main_actions = int(snapshot.get("current_main_actions", 0))
	used_action_groups = normalize_string_array(snapshot.get("used_action_groups", []))
	used_action_ids = normalize_string_array(snapshot.get("used_action_ids", []))
	allowed_action_group_pairs = normalize_string_array(snapshot.get("allowed_action_group_pairs", []))
	apply_status_snapshots(snapshot.get("statuses", []))
	if not snapshot.has("status_attack_bonus"):
		status_attack_bonus = calculate_status_attack_bonus()
	if not snapshot.has("status_attack_floor_debt"):
		status_attack_floor_debt = 0
	if not snapshot.has("status_max_health_bonus"):
		status_max_health_bonus = calculate_status_max_health_bonus()
	if not snapshot.has("status_control_base_owner_id"):
		status_control_base_owner_id = ""
	is_action_available_hint = bool(snapshot.get("is_action_available_hint", false))
	is_pending_death = false
	is_selected = false
	is_valid_target = false
	state_changed.emit(self)


func create_origin_snapshot() -> Dictionary:
	if data == null:
		return {}

	return {
		"card_id": data.id,
		"display_name": data.display_name,
		"description": data.description,
		"type": data.type,
		"equipment_type": data.equipment_type,
		"role": data.role,
		"faction_id": data.faction_id,
		"faction_name": data.faction_name,
		"keywords": data.keywords.duplicate(true),
		"effects": data.effects.duplicate(true),
		"spell_actions": data.spell_actions.duplicate(true),
		"attack": data.attack,
		"health": data.health,
		"movement": max_movement,
		"attack_speed": max_attack_speed,
		"mounted_attack_max_uses": mounted_attack_max_uses.duplicate(true),
		"mounted_attack_uses": mounted_attack_uses.duplicate(true),
		"main_actions": max_main_actions,
		"allowed_action_group_pairs": allowed_action_group_pairs.duplicate(),
		"front_texture_path": data.front_texture_path,
		"data": data
	}


func create_last_state_snapshot() -> Dictionary:
	return {
		"slot_index": slot_index,
		"owner_id": owner_id,
		"card_id": card_id,
		"display_name": display_name,
		"is_face_up": is_face_up,
		"current_attack": current_attack,
		"passive_attack_bonus": passive_attack_bonus,
		"passive_keywords": passive_keywords.duplicate(),
		"status_attack_bonus": status_attack_bonus,
		"status_attack_floor_debt": status_attack_floor_debt,
		"status_max_health_bonus": status_max_health_bonus,
		"status_control_base_owner_id": status_control_base_owner_id,
		"max_health": max_health,
		"damage_taken": damage_taken,
		"shield": shield,
		"reborn_health_values": reborn_health_values.duplicate(),
		"current_health": current_health,
		"max_movement": max_movement,
		"current_movement": current_movement,
		"max_attack_speed": max_attack_speed,
		"current_attacks": current_attacks,
		"mounted_attack_max_uses": mounted_attack_max_uses.duplicate(true),
		"mounted_attack_uses": mounted_attack_uses.duplicate(true),
		"max_main_actions": max_main_actions,
		"current_main_actions": current_main_actions,
		"used_action_groups": used_action_groups.duplicate(),
		"used_action_ids": used_action_ids.duplicate(),
		"allowed_action_group_pairs": allowed_action_group_pairs.duplicate(),
		"statuses": create_status_snapshots()
	}


func create_graveyard_snapshot(death_metadata: Dictionary = {}) -> Dictionary:
	return {
		"origin": origin.duplicate(true),
		"last_state": create_last_state_snapshot(),
		"death": death_metadata.duplicate(true)
	}


func has_reborn() -> bool:
	return not reborn_health_values.is_empty()


func get_reborn_count() -> int:
	return reborn_health_values.size()


func get_next_reborn_health_value() -> int:
	if reborn_health_values.is_empty():
		return -1

	return maxi(int(reborn_health_values[0]), 0)


func add_reborn_health_value(health_value: int = 0) -> void:
	reborn_health_values.append(maxi(health_value, 0))
	state_changed.emit(self)


func consume_next_reborn_health_value() -> int:
	if reborn_health_values.is_empty():
		return -1

	var health_value := maxi(int(reborn_health_values[0]), 0)
	reborn_health_values.remove_at(0)
	return health_value


func revive_from_reborn(health_value: int) -> void:
	if data == null:
		return

	var remaining_reborn_values := reborn_health_values.duplicate()
	var revived_owner_id := owner_id
	if status_control_base_owner_id != "":
		revived_owner_id = status_control_base_owner_id

	current_attack = int(origin.get("attack", data.attack))
	passive_attack_bonus = 0
	passive_keywords.clear()
	status_attack_bonus = 0
	status_attack_floor_debt = 0
	status_max_health_bonus = 0
	status_control_base_owner_id = ""
	max_health = int(origin.get("health", data.health))
	damage_taken = 0
	if health_value > 0:
		damage_taken = maxi(max_health - mini(health_value, max_health), 0)
	shield = 0
	reborn_health_values = remaining_reborn_values
	max_movement = int(origin.get("movement", 1 if data.is_minion() else 0))
	current_movement = max_movement
	max_attack_speed = int(origin.get("attack_speed", data.attack_speed if data.is_minion() else 0))
	current_attacks = max_attack_speed
	mounted_attack_max_uses = normalize_int_dictionary(origin.get("mounted_attack_max_uses", {}))
	mounted_attack_uses = mounted_attack_max_uses.duplicate(true)
	max_main_actions = int(origin.get("main_actions", 1 if data.is_unit() else 0))
	current_main_actions = max_main_actions
	used_action_groups.clear()
	used_action_ids.clear()
	allowed_action_group_pairs = normalize_string_array(origin.get("allowed_action_group_pairs", []))
	statuses.clear()
	owner_id = revived_owner_id
	is_face_up = true
	is_pending_death = false
	is_selected = false
	is_valid_target = false
	is_action_available_hint = false
	apply_keyword_passives()
	state_changed.emit(self)


func set_owner(new_owner_id: String) -> void:
	# 卡牌归属只通过状态对象记录，方便后续交互统一判断权限。
	if owner_id == new_owner_id:
		return

	owner_id = new_owner_id
	state_changed.emit(self)


func has_owner() -> bool:
	return owner_id != ""


func is_owned_by(player_id: String) -> bool:
	return owner_id == player_id


func set_selected(value: bool) -> void:
	# 未来做选中、释放技能、拖拽时可以复用这个状态。
	if is_selected == value:
		return

	is_selected = value
	state_changed.emit(self)


func set_valid_target(value: bool) -> void:
	# 由交互管理器维护，表示当前操作流程里这个格子是否可被点击为目标。
	if is_valid_target == value:
		return

	is_valid_target = value
	state_changed.emit(self)


func set_action_available_hint(value: bool) -> void:
	if is_action_available_hint == value:
		return

	is_action_available_hint = value
	state_changed.emit(self)


func set_area_preview(value: bool) -> void:
	if is_area_preview == value:
		return
	is_area_preview = value
	state_changed.emit(self)


func can_move() -> bool:
	return current_movement > 0 and not has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION)


func can_attack() -> bool:
	return current_attacks > 0 and not has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION)


func can_take_action_group(action_group: String, can_reuse_used_group := true) -> bool:
	if has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION):
		return false
	if action_group == "":
		return true

	if used_action_groups.has(action_group):
		return can_reuse_used_group

	if max_main_actions <= 0:
		return false

	if used_action_groups.size() >= max_main_actions:
		return false

	for used_group in used_action_groups:
		if not can_combine_action_groups(used_group, action_group):
			return false

	return true


func register_action_group(action_group: String) -> bool:
	if action_group == "":
		return true

	if not can_take_action_group(action_group):
		return false

	if used_action_groups.has(action_group):
		return true

	used_action_groups.append(action_group)
	refresh_current_main_actions()
	state_changed.emit(self)
	return true


func has_used_action_id(action_id: String) -> bool:
	return action_id != "" and used_action_ids.has(action_id)


func register_action_id(action_id: String) -> bool:
	if action_id == "":
		return true

	if has_used_action_id(action_id):
		return false

	used_action_ids.append(action_id)
	state_changed.emit(self)
	return true


func can_combine_action_groups(first_group: String, second_group: String) -> bool:
	if first_group == second_group:
		return true

	return allowed_action_group_pairs.has(create_action_group_pair_key(first_group, second_group))


func allow_action_group_pair(first_group: String, second_group: String, should_emit_changed := true) -> void:
	if first_group == "" or second_group == "" or first_group == second_group:
		return

	var pair_key := create_action_group_pair_key(first_group, second_group)
	if allowed_action_group_pairs.has(pair_key):
		return

	allowed_action_group_pairs.append(pair_key)
	if should_emit_changed:
		state_changed.emit(self)


func create_action_group_pair_key(first_group: String, second_group: String) -> String:
	var groups := [first_group, second_group]
	groups.sort()
	return "%s|%s" % [groups[0], groups[1]]


func refresh_current_main_actions() -> void:
	current_main_actions = maxi(max_main_actions - used_action_groups.size(), 0)


func normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))

	return result


func normalize_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(maxi(int(item), 0))

	return result


func normalize_int_dictionary(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key in value:
			result[str(key)] = int(value[key])

	return result


func create_initial_mounted_attack_uses() -> Dictionary:
	var result := {}
	if data == null:
		return result

	for mounted_attack in data.mounted_attacks:
		var action_id := EffectData.get_action_id(mounted_attack)
		if action_id == "":
			continue

		result[action_id] = maxi(EffectData.get_attack_speed(mounted_attack), 0)

	return result


func create_status_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for status in statuses:
		if status == null:
			continue

		snapshots.append(status.to_snapshot())

	return snapshots


func apply_status_snapshots(value: Variant) -> void:
	statuses.clear()
	if not value is Array:
		recalculate_status_modifiers(false)
		return

	for item in value:
		if not item is Dictionary:
			continue

		var status := CardStatus.new()
		status.apply_snapshot(item)
		if status.status_id != "":
			statuses.append(status)

	recalculate_status_modifiers(false)


func add_status(status: CardStatus) -> void:
	if status == null or status.status_id == "":
		return
	if status.status_id == CardStatus.STATUS_POISON:
		if has_keyword(CardData.KEYWORD_MECHANICAL):
			return
		add_unique_poison_status(status)
		return
	if status.status_id == CardStatus.STATUS_STORED_VENOM:
		add_stored_venom_status(status)
		return

	for existing_status in statuses:
		if existing_status != null and existing_status.is_same_stack_key(status):
			existing_status.merge_from(status)
			recalculate_status_modifiers(false)
			state_changed.emit(self)
			return

	statuses.append(status)
	recalculate_status_modifiers(false)
	state_changed.emit(self)


func add_unique_poison_status(status: CardStatus) -> void:
	var existing_status := get_status(CardStatus.STATUS_POISON)
	if existing_status != null:
		if not status.is_stronger_poison_than(existing_status):
			return

		statuses.erase(existing_status)

	statuses.append(status)
	state_changed.emit(self)


func add_stored_venom_status(status: CardStatus) -> void:
	var existing_status := get_status(CardStatus.STATUS_STORED_VENOM)
	if existing_status != null:
		var current_damage := existing_status.get_stored_venom_damage()
		var added_damage := status.get_stored_venom_damage()
		existing_status.payload[EffectData.KEY_STORED_VENOM_DAMAGE] = current_damage + added_damage
		state_changed.emit(self)
		return

	statuses.append(status)
	state_changed.emit(self)


func remove_status(status_id: String) -> bool:
	for index in range(statuses.size() - 1, -1, -1):
		var status := statuses[index]
		if status != null and status.status_id == status_id:
			statuses.remove_at(index)
			recalculate_status_modifiers(false)
			state_changed.emit(self)
			return true

	return false


func remove_status_instance(status: CardStatus) -> bool:
	if status == null:
		return false

	var index := statuses.find(status)
	if index < 0:
		return false

	statuses.remove_at(index)
	recalculate_status_modifiers(false)
	state_changed.emit(self)
	return true


func cleanse_statuses() -> Array[CardStatus]:
	var removed_statuses: Array[CardStatus] = []
	for index in range(statuses.size() - 1, -1, -1):
		var status := statuses[index]
		if status == null:
			statuses.remove_at(index)
			continue

		removed_statuses.append(status)
		statuses.remove_at(index)

	if removed_statuses.is_empty():
		return removed_statuses

	recalculate_status_modifiers(false)
	state_changed.emit(self)
	removed_statuses.reverse()
	return removed_statuses


func has_status(status_id: String) -> bool:
	return get_status(status_id) != null


func has_status_with_tag(tag: String) -> bool:
	for status in statuses:
		if status != null and status.tags.has(tag):
			return true
	return false


func get_status(status_id: String) -> CardStatus:
	for status in statuses:
		if status != null and status.status_id == status_id:
			return status

	return null


func expire_statuses_for_turn_timing(trigger: String, turn_player_id: String) -> Array[CardStatus]:
	var expired_statuses: Array[CardStatus] = []
	var did_change := false

	for index in range(statuses.size() - 1, -1, -1):
		var status := statuses[index]
		if status == null:
			statuses.remove_at(index)
			did_change = true
			continue

		if not status.should_tick(trigger, turn_player_id):
			continue

		if status.tick_turn():
			expired_statuses.append(status)
			statuses.remove_at(index)
		did_change = true

	if did_change:
		recalculate_status_modifiers(false)
		state_changed.emit(self)

	expired_statuses.reverse()
	return expired_statuses


func spend_movement(amount: int = 1) -> bool:
	if amount <= 0:
		return true

	if current_movement < amount:
		return false

	current_movement -= amount
	state_changed.emit(self)
	return true


func restore_movement() -> void:
	if current_movement == max_movement:
		return

	current_movement = max_movement
	state_changed.emit(self)


func set_max_movement(value: int, should_preserve_spent_movement := true) -> void:
	var normalized_value: int = maxi(value, 0)
	if max_movement == normalized_value:
		return

	var spent_movement: int = maxi(max_movement - current_movement, 0)
	max_movement = normalized_value
	if should_preserve_spent_movement:
		current_movement = maxi(max_movement - spent_movement, 0)
	else:
		current_movement = max_movement
	state_changed.emit(self)


func set_max_attack_speed(value: int, should_preserve_spent_attacks := true) -> void:
	var normalized_value: int = maxi(value, 0)
	if max_attack_speed == normalized_value:
		return

	var spent_attacks: int = maxi(max_attack_speed - current_attacks, 0)
	max_attack_speed = normalized_value
	if should_preserve_spent_attacks:
		current_attacks = maxi(max_attack_speed - spent_attacks, 0)
	else:
		current_attacks = max_attack_speed
	state_changed.emit(self)


func spend_attack(amount: int = 1) -> bool:
	if amount <= 0:
		return true

	if current_attacks < amount:
		return false

	current_attacks -= amount
	state_changed.emit(self)
	return true


func restore_attacks() -> void:
	if current_attacks == max_attack_speed:
		return

	current_attacks = max_attack_speed
	state_changed.emit(self)


func restore_mounted_attack_uses() -> void:
	var next_uses := mounted_attack_max_uses.duplicate(true)
	if mounted_attack_uses == next_uses:
		return

	mounted_attack_uses = next_uses
	state_changed.emit(self)


func get_mounted_attack_uses(action_id: String) -> int:
	return int(mounted_attack_uses.get(action_id, 0))


func spend_mounted_attack_use(action_id: String) -> bool:
	if action_id == "":
		return false

	var remaining := get_mounted_attack_uses(action_id)
	if remaining <= 0:
		return false

	mounted_attack_uses[action_id] = remaining - 1
	state_changed.emit(self)
	return true


func set_mounted_attack_max_uses(action_id: String, value: int, should_preserve_spent_uses := true) -> void:
	if action_id == "":
		return

	var normalized_value := maxi(value, 0)
	var previous_max := int(mounted_attack_max_uses.get(action_id, 0))
	var previous_current := int(mounted_attack_uses.get(action_id, previous_max))
	if previous_max == normalized_value:
		return

	var spent_uses := maxi(previous_max - previous_current, 0)
	mounted_attack_max_uses[action_id] = normalized_value
	if should_preserve_spent_uses:
		mounted_attack_uses[action_id] = maxi(normalized_value - spent_uses, 0)
	else:
		mounted_attack_uses[action_id] = normalized_value

	state_changed.emit(self)


func restore_main_actions() -> void:
	if current_main_actions == max_main_actions and used_action_groups.is_empty() and used_action_ids.is_empty():
		return

	used_action_groups.clear()
	used_action_ids.clear()
	current_main_actions = max_main_actions
	state_changed.emit(self)


func heal(amount: int) -> int:
	# 治疗减少已受伤害，当前生命不会超过 max_health。
	if amount <= 0:
		return 0
	if has_keyword(CardData.KEYWORD_MECHANICAL):
		return 0

	var previous_damage_taken := damage_taken
	damage_taken = maxi(damage_taken - amount, 0)
	var healed_amount := previous_damage_taken - damage_taken
	if healed_amount <= 0:
		return 0

	state_changed.emit(self)
	return healed_amount


func take_damage(amount: int) -> void:
	# 伤害优先消耗护盾，剩余伤害才增加已受伤害；死亡由 GameManager 统一检查。
	if amount <= 0:
		return

	if consume_divine_shield():
		return

	var remaining_damage := amount
	if shield > 0:
		var absorbed_damage: int = mini(shield, remaining_damage)
		shield -= absorbed_damage
		remaining_damage -= absorbed_damage

	if remaining_damage > 0:
		damage_taken = mini(damage_taken + remaining_damage, max_health)

	state_changed.emit(self)


func consume_divine_shield() -> bool:
	var status := get_status(CardStatus.STATUS_DIVINE_SHIELD)
	if status == null:
		return false

	if status.stacks > 1:
		status.stacks -= 1
		state_changed.emit(self)
		return true

	return remove_status(CardStatus.STATUS_DIVINE_SHIELD)


func gain_shield(amount: int) -> void:
	if amount <= 0:
		return

	shield += amount
	state_changed.emit(self)


func set_current_attack(value: int) -> void:
	current_attack = maxi(value, 0)
	state_changed.emit(self)


func set_passive_attack_bonus(value: int) -> void:
	var normalized_value := maxi(value, 0)
	if passive_attack_bonus == normalized_value:
		return

	var base_attack := current_attack - passive_attack_bonus - status_attack_bonus + status_attack_floor_debt
	var raw_attack := base_attack + normalized_value + status_attack_bonus
	current_attack = maxi(raw_attack, 0)
	status_attack_floor_debt = mini(raw_attack - current_attack, 0)
	passive_attack_bonus = normalized_value
	state_changed.emit(self)


func set_passive_keywords(keywords: Array[String]) -> void:
	var normalized_keywords: Array[String] = []
	for keyword in keywords:
		if keyword != "" and not normalized_keywords.has(keyword):
			normalized_keywords.append(keyword)

	normalized_keywords.sort()
	var current_keywords := passive_keywords.duplicate()
	current_keywords.sort()
	if current_keywords == normalized_keywords:
		return

	passive_keywords = normalized_keywords
	state_changed.emit(self)


func calculate_status_attack_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status == null or not status.tags.has(CardStatus.TAG_ATTACK_MODIFIER):
			continue

		bonus += calculate_status_numeric_modifier(status, EffectData.KEY_ATTACK_BONUS)

	return bonus


func calculate_status_max_health_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status == null or not status.tags.has(CardStatus.TAG_HEALTH_MODIFIER):
			continue

		bonus += calculate_status_numeric_modifier(status, EffectData.KEY_MAX_HEALTH_BONUS)

	return bonus


func get_status_control_owner_id() -> String:
	var control_owner_id := ""
	for status in statuses:
		if status == null or not status.tags.has(CardStatus.TAG_CONTROL):
			continue
		if status.source_owner_id == "":
			continue

		control_owner_id = status.source_owner_id

	return control_owner_id


func calculate_status_numeric_modifier(status: CardStatus, payload_key: String) -> int:
	if status == null:
		return 0

	var amount := int(status.payload.get(payload_key, 0))
	if amount == 0:
		return 0

	if bool(status.payload.get(EffectData.KEY_CUMULATIVE_STATUS_MODIFIER, false)):
		return amount

	return amount * maxi(status.stacks, 1)


func recalculate_status_modifiers(should_emit_changed := true) -> void:
	var next_status_attack_bonus := calculate_status_attack_bonus()
	var next_status_max_health_bonus := calculate_status_max_health_bonus()
	var next_control_owner_id := get_status_control_owner_id()
	var next_owner_id := owner_id
	if next_control_owner_id != "":
		if status_control_base_owner_id == "":
			status_control_base_owner_id = owner_id
		next_owner_id = next_control_owner_id
	elif status_control_base_owner_id != "":
		next_owner_id = status_control_base_owner_id
		status_control_base_owner_id = ""

	if (
		status_attack_bonus == next_status_attack_bonus
		and status_max_health_bonus == next_status_max_health_bonus
		and owner_id == next_owner_id
	):
		return

	var base_attack := current_attack - status_attack_bonus + status_attack_floor_debt
	var raw_attack := base_attack + next_status_attack_bonus
	current_attack = maxi(raw_attack, 0)
	status_attack_floor_debt = mini(raw_attack - current_attack, 0)
	status_attack_bonus = next_status_attack_bonus
	owner_id = next_owner_id

	var health_bonus_delta := next_status_max_health_bonus - status_max_health_bonus
	if health_bonus_delta != 0:
		max_health = maxi(max_health + health_bonus_delta, 0)
		if health_bonus_delta > 0:
			damage_taken = maxi(damage_taken - health_bonus_delta, 0)
		else:
			damage_taken = mini(damage_taken, max_health)
		status_max_health_bonus = next_status_max_health_bonus

	if should_emit_changed:
		state_changed.emit(self)


func increase_max_health(amount: int, should_heal_added_health: bool = true) -> void:
	if amount <= 0:
		return

	max_health += amount
	if should_heal_added_health:
		damage_taken = maxi(damage_taken - amount, 0)

	state_changed.emit(self)


func decrease_max_health(amount: int) -> void:
	if amount <= 0:
		return

	max_health = maxi(max_health - amount, 0)
	damage_taken = mini(damage_taken, max_health)
	state_changed.emit(self)
