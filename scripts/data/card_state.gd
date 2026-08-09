extends Resource
class_name CardState

const ActionResourceResolverScript := preload("res://scripts/game/action_resource_resolver.gd")

signal state_changed(state: CardState)
signal damage_prevented(state: CardState, prevention_id: String, prevented_amount: int)

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

# 永久属性覆盖层。它的优先级高于 origin，但不污染 origin。
# 例如卡扎克杀戮成长会写入这里；死亡清状态后重新入场仍保留，净化/驱散不会移除。
var permanent_stat_overrides: Dictionary = {}

# Per-instance rule counters that must follow snapshots but are not visible or
# cleanseable statuses, such as Carnage's two-kill progress.
var runtime_counters: Dictionary = {}

# 当前是否允许玩家操作这张牌。
var is_interactable := true

# 当前是否被选中。后续做选牌、拖拽、释放效果时会用到。
var is_selected := false

# 当前是否是某个操作的合法目标，只用于 UI 高亮和调试显示。
var is_valid_target := false

# 当前是否是普通攻击目标选择里的敌方嘲讽目标，只用于 UI 强提示。
var is_taunt_target_hint := false

# 当前是否应该显示“可行动”提示。只用于表现层提示，具体可用动作由 ActionRegistry 决定。
var is_action_available_hint := false

var is_area_preview := false
# Cell-level visual mirror. The authoritative data lives on BoardCell and must
# survive card content changes such as refill, movement, or clearing.
var has_beast_path := false

# 当前是否已经进入死亡结算队列。用于批量死亡时避免同一张牌重复入队。
var is_pending_death := false

# 当前是否正面朝上。翻开状态唯一存储在这里。
var is_face_up := false

# 当前实例使用的正反面图片。
var front_texture: Texture2D
var table_texture: Texture2D
var back_texture: Texture2D

# 当前攻击、生命上限、已受伤害和护盾。当前生命由 max_health - damage_taken 计算得出。
var current_attack := 0
var passive_attack_bonus := 0
var passive_keywords: Array[String] = []
var status_attack_bonus := 0
var status_attack_floor_debt := 0
var status_attack_override := -1
var attack_before_status_override_raw := 0
var status_max_health_bonus := 0
var passive_armor_bonus := 0
var status_armor_bonus := 0
var passive_max_movement := 0
var status_movement_bonus := 0
var status_control_base_owner_id := ""
var max_health := 0
var damage_taken := 0
var shield := 0
var armor := 0
var chaos_corruption := 0
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
var passive_max_attack_speed := 0
var status_attack_speed_bonus := 0
var mounted_attack_max_uses: Dictionary = {}
var mounted_attack_uses: Dictionary = {}

# 当前可开启的行动类别数量。普通随从每回合只能移动、攻击、施法三选一；后续敏捷等能力可扩展。
var max_main_actions := 0
var current_main_actions := 0
var used_action_groups: Array[String] = []
var used_action_ids: Array[String] = []
var consumed_action_ids: Array[String] = []
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
		table_texture = null
		back_texture = null
		origin.clear()
		permanent_stat_overrides.clear()
		runtime_counters.clear()
		current_attack = 0
		passive_attack_bonus = 0
		passive_keywords.clear()
		status_attack_bonus = 0
		status_attack_floor_debt = 0
		status_attack_override = -1
		attack_before_status_override_raw = 0
		status_max_health_bonus = 0
		passive_armor_bonus = 0
		status_armor_bonus = 0
		passive_max_movement = 0
		status_movement_bonus = 0
		status_control_base_owner_id = ""
		max_health = 0
		damage_taken = 0
		shield = 0
		armor = 0
		chaos_corruption = 0
		reborn_health_values.clear()
		max_movement = 0
		current_movement = 0
		max_attack_speed = 0
		current_attacks = 0
		passive_max_attack_speed = 0
		status_attack_speed_bonus = 0
		mounted_attack_max_uses.clear()
		mounted_attack_uses.clear()
		max_main_actions = 0
		current_main_actions = 0
		used_action_groups.clear()
		used_action_ids.clear()
		consumed_action_ids.clear()
		allowed_action_group_pairs.clear()
		statuses.clear()
		is_face_up = false
		is_selected = false
		is_valid_target = false
		is_taunt_target_hint = false
		is_action_available_hint = false
		is_pending_death = false
	else:
		card_id = data.id
		display_name = data.display_name
		front_texture = data.front_texture
		table_texture = data.table_texture
		back_texture = data.back_texture
		current_attack = data.attack
		passive_attack_bonus = 0
		passive_keywords.clear()
		status_attack_bonus = 0
		status_attack_floor_debt = 0
		status_attack_override = -1
		attack_before_status_override_raw = 0
		status_max_health_bonus = 0
		passive_armor_bonus = data.armor
		status_armor_bonus = 0
		passive_max_movement = 0
		status_movement_bonus = 0
		status_control_base_owner_id = ""
		max_health = data.health
		damage_taken = 0
		shield = 0
		armor = passive_armor_bonus
		chaos_corruption = data.chaos_corruption
		reborn_health_values = create_initial_reborn_health_values()
		is_action_available_hint = false
		is_pending_death = false
		if data.is_minion():
			max_movement = maxi(data.movement, 0)
			passive_max_movement = max_movement
			current_movement = max_movement
			passive_max_attack_speed = maxi(data.attack_speed, 0)
			status_attack_speed_bonus = 0
			max_attack_speed = passive_max_attack_speed
			current_attacks = max_attack_speed
			mounted_attack_max_uses = create_initial_mounted_attack_uses()
			mounted_attack_uses = mounted_attack_max_uses.duplicate(true)
			max_main_actions = 1
			current_main_actions = max_main_actions
			used_action_groups.clear()
			used_action_ids.clear()
			consumed_action_ids.clear()
			allowed_action_group_pairs.clear()
			apply_keyword_passives()
			passive_max_movement = max_movement
		elif data.is_building():
			max_movement = 0
			current_movement = 0
			max_attack_speed = 0
			current_attacks = 0
			passive_max_attack_speed = 0
			status_attack_speed_bonus = 0
			mounted_attack_max_uses.clear()
			mounted_attack_uses.clear()
			max_main_actions = 1
			current_main_actions = max_main_actions
			used_action_groups.clear()
			used_action_ids.clear()
			consumed_action_ids.clear()
			allowed_action_group_pairs.clear()
		else:
			max_movement = 0
			current_movement = 0
			max_attack_speed = 0
			current_attacks = 0
			passive_max_attack_speed = 0
			status_attack_speed_bonus = 0
			mounted_attack_max_uses.clear()
			mounted_attack_uses.clear()
			max_main_actions = 0
			current_main_actions = 0
			used_action_groups.clear()
			used_action_ids.clear()
			consumed_action_ids.clear()
			allowed_action_group_pairs.clear()
		statuses.clear()
		origin = create_origin_snapshot()
		permanent_stat_overrides.clear()
		runtime_counters.clear()

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
	return (data != null and data.is_hero()) or is_transformed_from_hero()


func is_transformed_from_hero() -> bool:
	var hero_card_id := get_effective_hero_card_id()
	return hero_card_id != "" and (data == null or card_id != hero_card_id)


func get_effective_hero_card_id() -> String:
	if data != null and data.is_hero():
		return card_id

	var transform_status := get_transform_status()
	if transform_status == null or not transform_preserves_original_identity(transform_status):
		return ""

	var original_snapshot: Dictionary = transform_status.payload.get("original_snapshot", {})
	var original_data := original_snapshot.get("data") as CardData
	if original_data != null and original_data.is_hero():
		return original_data.id

	if str(original_snapshot.get("role", "")) == CardData.ROLE_HERO:
		return str(original_snapshot.get("card_id", ""))

	return ""


func get_effective_hero_card_data() -> CardData:
	if data != null and data.is_hero():
		return data

	var transform_status := get_transform_status()
	if transform_status == null or not transform_preserves_original_identity(transform_status):
		return null

	var original_snapshot: Dictionary = transform_status.payload.get("original_snapshot", {})
	var original_data := original_snapshot.get("data") as CardData
	if original_data != null and original_data.is_hero():
		return original_data

	return null


func represents_card_id(target_card_id: String) -> bool:
	if target_card_id == "":
		return false
	if card_id == target_card_id:
		return true

	var transform_status := get_transform_status()
	if transform_status == null or not transform_preserves_original_identity(transform_status):
		return false

	var original_snapshot: Dictionary = transform_status.payload.get("original_snapshot", {})
	return str(original_snapshot.get("card_id", "")) == target_card_id


func get_represented_card_ids() -> Array[String]:
	var card_ids: Array[String] = []
	if card_id != "":
		card_ids.append(card_id)

	var transform_status := get_transform_status()
	if transform_status != null and transform_preserves_original_identity(transform_status):
		var original_snapshot: Dictionary = transform_status.payload.get("original_snapshot", {})
		var original_card_id := str(original_snapshot.get("card_id", ""))
		if original_card_id != "" and not card_ids.has(original_card_id):
			card_ids.append(original_card_id)

	return card_ids


func is_flying() -> bool:
	return has_keyword(CardData.KEYWORD_FLYING)


func uses_minion_action_resources() -> bool:
	return is_minion()


func has_keyword(keyword: String) -> bool:
	return (data != null and data.has_keyword(keyword)) or passive_keywords.has(keyword) or has_status_keyword(keyword)


func has_status_keyword(keyword: String) -> bool:
	if keyword == "":
		return false

	for status in statuses:
		if status == null:
			continue
		var status_keywords := EffectData.get_keywords(status.payload)
		if status_keywords.has(keyword):
			return true

	return false


func get_siege_bonus() -> int:
	return get_numeric_keyword_value(CardData.KEYWORD_SIEGE_PREFIX)


func get_splash_damage() -> int:
	return get_numeric_keyword_value(CardData.KEYWORD_SPLASH_PREFIX)


func get_frontal_attack_width() -> int:
	var width := get_numeric_keyword_value(CardData.KEYWORD_FRONTAL_WIDTH_PREFIX)
	if has_keyword(CardData.KEYWORD_GIANT):
		width = maxi(width, 3)
	return width if width > 0 and width % 2 == 1 else 0


func get_numeric_keyword_value(prefix: String) -> int:
	var value := data.get_numeric_keyword_value(prefix) if data != null else 0
	for keyword in passive_keywords:
		if not keyword.begins_with(prefix):
			continue

		var amount_text := keyword.substr(prefix.length())
		if not amount_text.is_valid_int():
			continue

		value = maxi(value, int(amount_text))

	for status in statuses:
		if status == null:
			continue
		for keyword in EffectData.get_keywords(status.payload):
			if not keyword.begins_with(prefix):
				continue

			var amount_text := keyword.substr(prefix.length())
			if amount_text.is_valid_int():
				value = maxi(value, int(amount_text))

	return maxi(value, 0)


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


func refresh_action_keyword_passives() -> void:
	ActionResourceResolverScript.refresh_action_keyword_passives(self)


func create_initial_reborn_health_values() -> Array[int]:
	var values: Array[int] = []
	if data == null:
		return values

	if not data.reborn_health_values.is_empty():
		return data.reborn_health_values.duplicate()

	# Legacy keyword support. New cards should use CardData.reborn_health_values.
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
		"permanent_stat_overrides": permanent_stat_overrides.duplicate(true),
		"runtime_counters": runtime_counters.duplicate(true),
		"is_face_up": is_face_up,
		"front_texture": front_texture,
		"table_texture": table_texture,
		"back_texture": back_texture,
		"current_attack": current_attack,
		"passive_attack_bonus": passive_attack_bonus,
		"passive_keywords": passive_keywords.duplicate(),
		"status_attack_bonus": status_attack_bonus,
		"status_attack_floor_debt": status_attack_floor_debt,
		"status_attack_override": status_attack_override,
		"attack_before_status_override_raw": attack_before_status_override_raw,
		"status_max_health_bonus": status_max_health_bonus,
		"passive_armor_bonus": passive_armor_bonus,
		"status_armor_bonus": status_armor_bonus,
		"passive_max_movement": passive_max_movement,
		"status_movement_bonus": status_movement_bonus,
		"status_control_base_owner_id": status_control_base_owner_id,
		"max_health": max_health,
		"damage_taken": damage_taken,
		"shield": shield,
		"armor": armor,
		"chaos_corruption": chaos_corruption,
		"reborn_health_values": reborn_health_values.duplicate(),
		"max_movement": max_movement,
		"current_movement": current_movement,
		"max_attack_speed": max_attack_speed,
		"current_attacks": current_attacks,
		"passive_max_attack_speed": passive_max_attack_speed,
		"status_attack_speed_bonus": status_attack_speed_bonus,
		"mounted_attack_max_uses": mounted_attack_max_uses.duplicate(true),
		"mounted_attack_uses": mounted_attack_uses.duplicate(true),
		"max_main_actions": max_main_actions,
		"current_main_actions": current_main_actions,
		"used_action_groups": used_action_groups.duplicate(),
		"used_action_ids": used_action_ids.duplicate(),
		"consumed_action_ids": consumed_action_ids.duplicate(),
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
	var snapshot_permanent_stat_overrides = snapshot.get("permanent_stat_overrides", {})
	if snapshot_permanent_stat_overrides is Dictionary:
		permanent_stat_overrides = snapshot_permanent_stat_overrides.duplicate(true)
	else:
		permanent_stat_overrides = {}
	var snapshot_runtime_counters = snapshot.get("runtime_counters", {})
	if snapshot_runtime_counters is Dictionary:
		runtime_counters = snapshot_runtime_counters.duplicate(true)
	else:
		runtime_counters = {}
	is_face_up = bool(snapshot.get("is_face_up", false))
	front_texture = snapshot.get("front_texture") as Texture2D
	table_texture = snapshot.get("table_texture") as Texture2D
	back_texture = snapshot.get("back_texture") as Texture2D
	current_attack = int(snapshot.get("current_attack", 0))
	passive_attack_bonus = int(snapshot.get("passive_attack_bonus", 0))
	passive_keywords = normalize_string_array(snapshot.get("passive_keywords", []))
	status_attack_bonus = int(snapshot.get("status_attack_bonus", 0))
	status_attack_floor_debt = int(snapshot.get("status_attack_floor_debt", 0))
	status_attack_override = int(snapshot.get("status_attack_override", -1))
	attack_before_status_override_raw = int(snapshot.get("attack_before_status_override_raw", 0))
	status_max_health_bonus = int(snapshot.get("status_max_health_bonus", 0))
	passive_armor_bonus = int(snapshot.get("passive_armor_bonus", snapshot.get("armor", 0)))
	status_armor_bonus = int(snapshot.get("status_armor_bonus", 0))
	passive_max_movement = int(snapshot.get("passive_max_movement", snapshot.get("max_movement", 0)))
	status_movement_bonus = int(snapshot.get("status_movement_bonus", 0))
	status_control_base_owner_id = str(snapshot.get("status_control_base_owner_id", ""))
	max_health = int(snapshot.get("max_health", snapshot.get("current_health", 0)))
	damage_taken = int(snapshot.get("damage_taken", 0))
	shield = int(snapshot.get("shield", 0))
	armor = int(snapshot.get("armor", 0))
	chaos_corruption = int(snapshot.get("chaos_corruption", 0))
	reborn_health_values = normalize_int_array(snapshot.get("reborn_health_values", []))
	max_movement = int(snapshot.get("max_movement", 0))
	current_movement = int(snapshot.get("current_movement", 0))
	max_attack_speed = int(snapshot.get("max_attack_speed", 0))
	current_attacks = int(snapshot.get("current_attacks", 0))
	status_attack_speed_bonus = int(snapshot.get("status_attack_speed_bonus", 0))
	passive_max_attack_speed = int(
		snapshot.get("passive_max_attack_speed", maxi(max_attack_speed - status_attack_speed_bonus, 0))
	)
	mounted_attack_max_uses = normalize_int_dictionary(snapshot.get("mounted_attack_max_uses", {}))
	mounted_attack_uses = normalize_int_dictionary(snapshot.get("mounted_attack_uses", {}))
	max_main_actions = int(snapshot.get("max_main_actions", 0))
	current_main_actions = int(snapshot.get("current_main_actions", 0))
	used_action_groups = normalize_string_array(snapshot.get("used_action_groups", []))
	used_action_ids = normalize_string_array(snapshot.get("used_action_ids", []))
	consumed_action_ids = normalize_string_array(snapshot.get("consumed_action_ids", []))
	allowed_action_group_pairs = normalize_string_array(snapshot.get("allowed_action_group_pairs", []))
	apply_status_snapshots(snapshot.get("statuses", []))
	if not snapshot.has("status_attack_bonus"):
		status_attack_bonus = calculate_status_attack_bonus()
	if not snapshot.has("status_attack_floor_debt"):
		status_attack_floor_debt = 0
	if not snapshot.has("status_attack_override"):
		status_attack_override = calculate_status_attack_override()
	if not snapshot.has("attack_before_status_override_raw"):
		attack_before_status_override_raw = (
			current_attack - status_attack_bonus + status_attack_floor_debt
		)
	if not snapshot.has("status_max_health_bonus"):
		status_max_health_bonus = calculate_status_max_health_bonus()
	if not snapshot.has("status_armor_bonus"):
		status_armor_bonus = calculate_status_armor_bonus()
		passive_armor_bonus = maxi(armor - status_armor_bonus, 0)
	if not snapshot.has("status_movement_bonus"):
		status_movement_bonus = calculate_status_movement_bonus()
		passive_max_movement = maxi(max_movement - status_movement_bonus, 0)
	if not snapshot.has("status_attack_speed_bonus"):
		status_attack_speed_bonus = calculate_status_attack_speed_bonus()
		passive_max_attack_speed = maxi(max_attack_speed - status_attack_speed_bonus, 0)
	if not snapshot.has("status_control_base_owner_id"):
		status_control_base_owner_id = ""
	is_action_available_hint = bool(snapshot.get("is_action_available_hint", false))
	is_pending_death = false
	is_selected = false
	is_valid_target = false
	is_taunt_target_hint = false
	state_changed.emit(self)


func apply_permanent_stat_overrides_as_fresh_state(overrides: Dictionary) -> void:
	if data == null:
		return

	permanent_stat_overrides = overrides.duplicate(true)
	current_attack = int(permanent_stat_overrides.get("attack", origin.get("attack", current_attack)))
	passive_attack_bonus = 0
	status_attack_bonus = 0
	status_attack_floor_debt = 0
	status_attack_override = -1
	attack_before_status_override_raw = 0
	status_max_health_bonus = 0
	passive_armor_bonus = maxi(int(permanent_stat_overrides.get("armor", origin.get("armor", data.armor))), 0)
	status_armor_bonus = 0
	status_movement_bonus = 0
	status_control_base_owner_id = ""
	max_health = int(permanent_stat_overrides.get("health", origin.get("health", max_health)))
	damage_taken = 0
	shield = 0
	armor = passive_armor_bonus
	chaos_corruption = int(permanent_stat_overrides.get("chaos_corruption", origin.get("chaos_corruption", chaos_corruption)))
	reborn_health_values = normalize_int_array(origin.get("reborn_health_values", []))
	max_movement = int(origin.get("movement", max_movement))
	passive_max_movement = max_movement
	current_movement = max_movement
	passive_max_attack_speed = int(
		permanent_stat_overrides.get("attack_speed", origin.get("attack_speed", max_attack_speed))
	)
	status_attack_speed_bonus = 0
	max_attack_speed = passive_max_attack_speed
	current_attacks = max_attack_speed
	mounted_attack_max_uses = normalize_int_dictionary(origin.get("mounted_attack_max_uses", {}))
	mounted_attack_uses.clear()
	max_main_actions = int(origin.get("main_actions", max_main_actions))
	current_main_actions = max_main_actions
	used_action_groups.clear()
	used_action_ids.clear()
	consumed_action_ids.clear()
	allowed_action_group_pairs = normalize_string_array(origin.get("allowed_action_group_pairs", []))
	statuses.clear()
	is_pending_death = false
	refresh_action_keyword_passives()
	state_changed.emit(self)


func get_transform_status() -> CardStatus:
	return get_status(CardStatus.STATUS_TRANSFORM)


func transform_preserves_original_identity(status: CardStatus = null) -> bool:
	var transform_status := status if status != null else get_transform_status()
	if transform_status == null:
		return false

	return bool(transform_status.payload.get(EffectData.KEY_PRESERVE_ORIGINAL_IDENTITY, true))


func is_cover_transformed() -> bool:
	var status := get_transform_status()
	if status == null:
		return false

	return str(status.payload.get(EffectData.KEY_TRANSFORM_MODE, "cover")) == "cover"


func restore_from_transform_status(status: CardStatus) -> bool:
	if status == null:
		return false

	var original_snapshot: Dictionary = status.payload.get("original_snapshot", {})
	if original_snapshot.is_empty():
		return false

	var action_economy_snapshot := create_action_economy_snapshot()
	apply_card_snapshot(original_snapshot)
	apply_action_economy_after_form_change(action_economy_snapshot)
	return true


func transform_to_card_data(target_data: CardData) -> void:
	if target_data == null:
		return

	var action_economy_snapshot := create_action_economy_snapshot()
	set_card_data(target_data)
	apply_action_economy_after_form_change(action_economy_snapshot)


func create_action_economy_snapshot() -> Dictionary:
	var spent_mounted_uses := {}
	for action_id in mounted_attack_max_uses:
		var max_uses := int(mounted_attack_max_uses.get(action_id, 0))
		var current_uses := int(mounted_attack_uses.get(action_id, max_uses))
		spent_mounted_uses[str(action_id)] = maxi(max_uses - current_uses, 0)

	return {
		"spent_movement": maxi(max_movement - current_movement, 0),
		"spent_attacks": maxi(max_attack_speed - current_attacks, 0),
		"spent_mounted_attack_uses": spent_mounted_uses,
		"used_action_groups": used_action_groups.duplicate(),
		"used_action_ids": used_action_ids.duplicate(),
		"consumed_action_ids": consumed_action_ids.duplicate()
	}


func apply_action_economy_after_form_change(action_economy_snapshot: Dictionary) -> void:
	var spent_movement := int(action_economy_snapshot.get("spent_movement", 0))
	current_movement = maxi(max_movement - spent_movement, 0)

	var spent_attacks := int(action_economy_snapshot.get("spent_attacks", 0))
	current_attacks = maxi(max_attack_speed - spent_attacks, 0)

	var spent_mounted_uses = action_economy_snapshot.get("spent_mounted_attack_uses", {})
	if spent_mounted_uses is Dictionary:
		for action_id in mounted_attack_max_uses.keys():
			var max_uses := int(mounted_attack_max_uses.get(action_id, 0))
			var spent_uses := int(spent_mounted_uses.get(action_id, 0))
			mounted_attack_uses[action_id] = maxi(max_uses - spent_uses, 0)

	used_action_groups = normalize_string_array(action_economy_snapshot.get("used_action_groups", []))
	used_action_ids = normalize_string_array(action_economy_snapshot.get("used_action_ids", []))
	consumed_action_ids = normalize_string_array(action_economy_snapshot.get("consumed_action_ids", []))
	refresh_current_main_actions()
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
		"armor": data.armor,
		"chaos_corruption": data.chaos_corruption,
		"reborn_health_values": reborn_health_values.duplicate(),
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
		"status_attack_override": status_attack_override,
		"attack_before_status_override_raw": attack_before_status_override_raw,
		"status_max_health_bonus": status_max_health_bonus,
		"status_control_base_owner_id": status_control_base_owner_id,
		"max_health": max_health,
		"damage_taken": damage_taken,
		"shield": shield,
		"armor": armor,
		"reborn_health_values": reborn_health_values.duplicate(),
		"current_health": current_health,
		"max_movement": max_movement,
		"current_movement": current_movement,
		"max_attack_speed": max_attack_speed,
		"current_attacks": current_attacks,
		"runtime_counters": runtime_counters.duplicate(true),
		"mounted_attack_max_uses": mounted_attack_max_uses.duplicate(true),
		"mounted_attack_uses": mounted_attack_uses.duplicate(true),
		"max_main_actions": max_main_actions,
		"current_main_actions": current_main_actions,
		"used_action_groups": used_action_groups.duplicate(),
		"used_action_ids": used_action_ids.duplicate(),
		"consumed_action_ids": consumed_action_ids.duplicate(),
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

	current_attack = int(permanent_stat_overrides.get("attack", origin.get("attack", data.attack)))
	passive_attack_bonus = 0
	passive_keywords.clear()
	status_attack_bonus = 0
	status_attack_floor_debt = 0
	status_attack_override = -1
	attack_before_status_override_raw = 0
	status_max_health_bonus = 0
	passive_armor_bonus = maxi(int(permanent_stat_overrides.get("armor", origin.get("armor", data.armor))), 0)
	status_armor_bonus = 0
	status_movement_bonus = 0
	status_control_base_owner_id = ""
	max_health = int(permanent_stat_overrides.get("health", origin.get("health", data.health)))
	damage_taken = 0
	if health_value > 0:
		damage_taken = maxi(max_health - mini(health_value, max_health), 0)
	shield = 0
	armor = passive_armor_bonus
	chaos_corruption = int(permanent_stat_overrides.get("chaos_corruption", origin.get("chaos_corruption", data.chaos_corruption)))
	reborn_health_values = remaining_reborn_values
	max_movement = int(origin.get("movement", 1 if data.is_minion() else 0))
	passive_max_movement = max_movement
	current_movement = max_movement
	passive_max_attack_speed = int(
		permanent_stat_overrides.get(
			"attack_speed",
			origin.get("attack_speed", data.attack_speed if data.is_minion() else 0)
		)
	)
	status_attack_speed_bonus = 0
	max_attack_speed = passive_max_attack_speed
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
	is_taunt_target_hint = false
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


func set_taunt_target_hint(value: bool) -> void:
	if is_taunt_target_hint == value:
		return

	is_taunt_target_hint = value
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


func set_beast_path(value: bool) -> void:
	if has_beast_path == value:
		return
	has_beast_path = value
	state_changed.emit(self)


func can_move() -> bool:
	return current_movement > 0 and not has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION)


func can_attack() -> bool:
	return current_attacks > 0 and not has_status_with_tag(CardStatus.TAG_ACTION_PREVENTION)


func can_take_action_group(action_group: String, can_reuse_used_group := true) -> bool:
	return ActionResourceResolverScript.can_take_action_group(self, action_group, can_reuse_used_group)


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


func has_consumed_action_id(action_id: String) -> bool:
	return action_id != "" and consumed_action_ids.has(action_id)


func consume_action_id(action_id: String) -> bool:
	if action_id == "":
		return true
	if has_consumed_action_id(action_id):
		return false

	consumed_action_ids.append(action_id)
	state_changed.emit(self)
	return true


func can_combine_action_groups(first_group: String, second_group: String) -> bool:
	return ActionResourceResolverScript.can_combine_action_groups(self, first_group, second_group)


func get_effective_max_main_actions() -> int:
	return ActionResourceResolverScript.get_effective_max_main_actions(self)


func can_combine_action_groups_from_current_keywords(first_group: String, second_group: String) -> bool:
	return ActionResourceResolverScript.can_combine_action_groups_from_current_keywords(self, first_group, second_group)


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
	return ActionResourceResolverScript.create_action_group_pair_key(first_group, second_group)


func refresh_current_main_actions() -> void:
	current_main_actions = maxi(get_effective_max_main_actions() - used_action_groups.size(), 0)


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
	if status.status_id == CardStatus.STATUS_FIRE:
		add_unique_fire_status(status)
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


func add_unique_fire_status(status: CardStatus) -> void:
	var existing_status := get_status(CardStatus.STATUS_FIRE)
	if existing_status != null:
		if not status.is_stronger_fire_than(existing_status):
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


func cleanse_statuses(cleanse_mode := EffectData.CLEANSE_MODE_ALL) -> Array[CardStatus]:
	var removed_statuses: Array[CardStatus] = []
	for index in range(statuses.size() - 1, -1, -1):
		var status := statuses[index]
		if status == null:
			statuses.remove_at(index)
			continue
		if status.tags.has(CardStatus.TAG_UNCLEANSEABLE):
			continue
		if not should_cleanse_status(status, cleanse_mode):
			continue

		removed_statuses.append(status)
		statuses.remove_at(index)

	if removed_statuses.is_empty():
		return removed_statuses

	var transform_status := find_transform_status_in_list(removed_statuses)
	if transform_status != null:
		restore_from_transform_status(transform_status)
		removed_statuses.reverse()
		return removed_statuses

	recalculate_status_modifiers(false)
	state_changed.emit(self)
	removed_statuses.reverse()
	return removed_statuses


func should_cleanse_status(status: CardStatus, cleanse_mode: String) -> bool:
	if status == null:
		return false

	match cleanse_mode:
		EffectData.CLEANSE_MODE_ALL:
			return true
		EffectData.CLEANSE_MODE_POSITIVE, EffectData.CLEANSE_MODE_NEGATIVE:
			return status.get_cleanse_valence() == cleanse_mode
		_:
			return true


func has_status(status_id: String) -> bool:
	return get_status(status_id) != null


func find_transform_status_in_list(status_list: Array[CardStatus]) -> CardStatus:
	for status in status_list:
		if status != null and status.status_id == CardStatus.STATUS_TRANSFORM:
			return status

	return null


func has_status_with_tag(tag: String) -> bool:
	for status in statuses:
		if status != null and status.tags.has(tag):
			return true
	return false


func is_stealthed_from_player(player_id: String) -> bool:
	return (
		player_id != ""
		and owner_id != ""
		and owner_id != player_id
		and has_keyword(CardData.KEYWORD_STEALTH)
	)


func remove_statuses_with_tag(tag: String) -> Array[CardStatus]:
	var removed_statuses: Array[CardStatus] = []
	if tag == "":
		return removed_statuses

	for index in range(statuses.size() - 1, -1, -1):
		var status := statuses[index]
		if status == null:
			statuses.remove_at(index)
			continue
		if not status.tags.has(tag):
			continue

		removed_statuses.append(status)
		statuses.remove_at(index)

	if removed_statuses.is_empty():
		return removed_statuses

	recalculate_status_modifiers(false)
	state_changed.emit(self)
	removed_statuses.reverse()
	return removed_statuses


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
	if passive_max_movement == normalized_value:
		return

	var spent_movement: int = maxi(max_movement - current_movement, 0)
	passive_max_movement = normalized_value
	max_movement = maxi(passive_max_movement + status_movement_bonus, 0)
	if should_preserve_spent_movement:
		current_movement = maxi(max_movement - spent_movement, 0)
	else:
		current_movement = max_movement
	state_changed.emit(self)


func set_max_attack_speed(value: int, should_preserve_spent_attacks := true) -> void:
	var normalized_value: int = maxi(value, 0)
	if passive_max_attack_speed == normalized_value:
		return

	var spent_attacks: int = maxi(max_attack_speed - current_attacks, 0)
	passive_max_attack_speed = normalized_value
	max_attack_speed = maxi(passive_max_attack_speed + status_attack_speed_bonus, 0)
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
	if damage_taken <= 0:
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


func gain_temporary_health(amount: int) -> int:
	# 生命吸取等特殊效果可以临时让当前生命超过 max_health。
	# 普通治疗仍然只会把 damage_taken 恢复到 0，因此无法重新治疗到临时超上限值。
	if amount <= 0:
		return 0

	damage_taken -= amount
	state_changed.emit(self)
	return amount


func take_damage(amount: int) -> void:
	# 伤害优先消耗护盾，剩余伤害才增加已受伤害；死亡由 GameManager 统一检查。
	if amount <= 0:
		return

	var effective_amount := amount + get_damage_amplify_bonus()
	if effective_amount <= 0:
		return

	if consume_divine_shield():
		damage_prevented.emit(self, CardStatus.STATUS_DIVINE_SHIELD, effective_amount)
		return

	var remaining_damage := effective_amount
	var did_receive_damage := false
	if shield > 0:
		var absorbed_damage: int = mini(shield, remaining_damage)
		shield -= absorbed_damage
		remaining_damage -= absorbed_damage
		did_receive_damage = absorbed_damage > 0

	if remaining_damage > 0:
		damage_taken = mini(damage_taken + remaining_damage, max_health)
		did_receive_damage = true

	if did_receive_damage:
		remove_status(CardStatus.STATUS_ROOTED)

	state_changed.emit(self)


func get_damage_amplify_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status == null:
			continue

		bonus += calculate_status_numeric_modifier(status, EffectData.KEY_DAMAGE_AMPLIFY)

	return maxi(bonus, 0)


func consume_divine_shield() -> bool:
	var status := get_status(CardStatus.STATUS_DIVINE_SHIELD)
	if status == null:
		return false

	if status.stacks > 1:
		status.stacks -= 1
		state_changed.emit(self)
		return true

	return remove_status(CardStatus.STATUS_DIVINE_SHIELD)


func consume_bronze_head_iron_arms() -> bool:
	var status := get_status(CardStatus.STATUS_BRONZE_HEAD_IRON_ARMS)
	if status == null:
		return false

	if status.stacks > 1:
		status.stacks -= 1
		state_changed.emit(self)
		return true

	return remove_status(CardStatus.STATUS_BRONZE_HEAD_IRON_ARMS)


func trigger_attack_reflection() -> bool:
	if has_keyword(CardData.KEYWORD_REFLECT):
		return true
	return consume_bronze_head_iron_arms()


func gain_shield(amount: int) -> void:
	if amount <= 0:
		return

	shield += amount
	state_changed.emit(self)


func set_armor(value: int) -> void:
	var normalized_value := maxi(value, 0)
	if passive_armor_bonus == normalized_value:
		return

	passive_armor_bonus = normalized_value
	armor = maxi(passive_armor_bonus + status_armor_bonus, 0)
	state_changed.emit(self)


func set_current_attack(value: int) -> void:
	var normalized_value := maxi(value, 0)
	if status_attack_override >= 0:
		attack_before_status_override_raw += normalized_value - current_attack
		current_attack = status_attack_override
	else:
		current_attack = normalized_value
	state_changed.emit(self)


func add_permanent_attack(amount: int) -> void:
	if data == null or amount == 0:
		return

	var origin_attack := int(origin.get("attack", data.attack))
	var previous_attack := int(permanent_stat_overrides.get("attack", origin_attack))
	var next_attack := maxi(previous_attack + amount, 0)
	var applied_delta := next_attack - previous_attack
	if applied_delta == 0:
		return

	permanent_stat_overrides["attack"] = next_attack
	if status_attack_override >= 0:
		attack_before_status_override_raw += applied_delta
		current_attack = status_attack_override
	else:
		var raw_attack := current_attack + status_attack_floor_debt + applied_delta
		current_attack = maxi(raw_attack, 0)
		status_attack_floor_debt = mini(raw_attack - current_attack, 0)
	state_changed.emit(self)


func add_permanent_max_health(amount: int) -> void:
	if data == null or amount <= 0:
		return
	var origin_health := int(origin.get("health", data.health))
	var previous_health := int(permanent_stat_overrides.get("health", origin_health))
	var next_health := previous_health + amount
	permanent_stat_overrides["health"] = next_health
	max_health += next_health - previous_health
	state_changed.emit(self)


func add_permanent_attack_speed(amount: int) -> void:
	if data == null or amount == 0:
		return
	var origin_attack_speed := int(origin.get("attack_speed", data.attack_speed))
	var previous_attack_speed := int(
		permanent_stat_overrides.get("attack_speed", origin_attack_speed)
	)
	var next_attack_speed := maxi(previous_attack_speed + amount, 0)
	if next_attack_speed == previous_attack_speed:
		return
	permanent_stat_overrides["attack_speed"] = next_attack_speed
	set_max_attack_speed(next_attack_speed, true)


func get_runtime_counter(key: String, default_value := 0) -> int:
	if key == "":
		return default_value
	return int(runtime_counters.get(key, default_value))


func set_runtime_counter(key: String, value: int) -> void:
	if key == "":
		return
	if int(runtime_counters.get(key, 0)) == value:
		return
	runtime_counters[key] = value
	state_changed.emit(self)


func increment_runtime_counter(key: String, amount := 1) -> int:
	var next_value := get_runtime_counter(key) + amount
	set_runtime_counter(key, next_value)
	return next_value


func set_passive_attack_bonus(value: int) -> void:
	var normalized_value := maxi(value, 0)
	if passive_attack_bonus == normalized_value:
		return

	var passive_delta := normalized_value - passive_attack_bonus
	if status_attack_override >= 0:
		attack_before_status_override_raw += passive_delta
	else:
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
	refresh_action_keyword_passives()
	state_changed.emit(self)


func calculate_status_attack_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status == null or not status.tags.has(CardStatus.TAG_ATTACK_MODIFIER):
			continue

		bonus += calculate_status_numeric_modifier(status, EffectData.KEY_ATTACK_BONUS)

	return bonus


func calculate_status_attack_override() -> int:
	var attack_override := -1
	for status in statuses:
		if status == null or not status.payload.has(EffectData.KEY_ATTACK_OVERRIDE):
			continue

		# Multiple fixed-attack statuses resolve by application order; the newest wins.
		attack_override = maxi(int(status.payload.get(EffectData.KEY_ATTACK_OVERRIDE, -1)), 0)

	return attack_override


func calculate_status_max_health_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status == null or not status.tags.has(CardStatus.TAG_HEALTH_MODIFIER):
			continue

		bonus += calculate_status_numeric_modifier(status, EffectData.KEY_MAX_HEALTH_BONUS)

	return bonus


func calculate_status_armor_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status != null:
			bonus += calculate_status_numeric_modifier(status, EffectData.KEY_ARMOR_BONUS)
	return bonus


func calculate_status_movement_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status != null:
			bonus += calculate_status_numeric_modifier(status, EffectData.KEY_MOVEMENT_BONUS)
	return bonus


func calculate_status_attack_speed_bonus() -> int:
	var bonus := 0
	for status in statuses:
		if status != null:
			bonus += calculate_status_numeric_modifier(status, EffectData.KEY_ATTACK_SPEED_BONUS)
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
	var next_status_attack_override := calculate_status_attack_override()
	var next_status_max_health_bonus := calculate_status_max_health_bonus()
	var next_status_armor_bonus := calculate_status_armor_bonus()
	var next_status_movement_bonus := calculate_status_movement_bonus()
	var next_status_attack_speed_bonus := calculate_status_attack_speed_bonus()
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
		and status_attack_override == next_status_attack_override
		and status_max_health_bonus == next_status_max_health_bonus
		and status_armor_bonus == next_status_armor_bonus
		and status_movement_bonus == next_status_movement_bonus
		and status_attack_speed_bonus == next_status_attack_speed_bonus
		and owner_id == next_owner_id
	):
		return

	var raw_attack := attack_before_status_override_raw if status_attack_override >= 0 else (
		current_attack + status_attack_floor_debt
	)
	raw_attack += next_status_attack_bonus - status_attack_bonus
	attack_before_status_override_raw = raw_attack
	if next_status_attack_override >= 0:
		current_attack = next_status_attack_override
	else:
		current_attack = maxi(raw_attack, 0)
	status_attack_floor_debt = mini(raw_attack - maxi(raw_attack, 0), 0)
	status_attack_bonus = next_status_attack_bonus
	status_attack_override = next_status_attack_override
	owner_id = next_owner_id
	status_armor_bonus = next_status_armor_bonus
	armor = maxi(passive_armor_bonus + status_armor_bonus, 0)

	var spent_movement := maxi(max_movement - current_movement, 0)
	status_movement_bonus = next_status_movement_bonus
	max_movement = maxi(passive_max_movement + status_movement_bonus, 0)
	current_movement = maxi(max_movement - spent_movement, 0)

	var spent_attacks := maxi(max_attack_speed - current_attacks, 0)
	status_attack_speed_bonus = next_status_attack_speed_bonus
	max_attack_speed = maxi(passive_max_attack_speed + status_attack_speed_bonus, 0)
	current_attacks = maxi(max_attack_speed - spent_attacks, 0)

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
