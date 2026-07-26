extends RefCounted
class_name CardData

const TYPE_MINION := "minion"
const TYPE_SPELL := "spell"
const TYPE_BUILDING := "building"
const TYPE_UPGRADE := "upgrade"
const TYPE_EQUIPMENT := "equipment"
const TYPE_TIME := "time"
const UPGRADE_TYPE_MINION_LIBRARY := "minion_library"
const EQUIPMENT_TYPE_WEAPON := "weapon"
const EQUIPMENT_TYPE_SUIT := "suit"
const ROLE_HERO := "hero"
const KEYWORD_CAVALRY := "cavalry"
const KEYWORD_RANGED := "ranged"
const KEYWORD_MAGIC_IMMUNE := "magic_immune"
const KEYWORD_RANGED_ATTACK_IMMUNE := "ranged_attack_immune"
const KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK := "can_attack_with_zero_attack"
const KEYWORD_MECHANICAL := "mechanical"
const KEYWORD_MOBILE_ASSAULT := "mobile_assault"
const KEYWORD_SPELL_MOVE := "spell_move"
const KEYWORD_SPELL_ATTACK := "spell_attack"
const KEYWORD_FLYING := "flying"
const KEYWORD_TELEPORT := "teleport"
const KEYWORD_STEALTH := "stealth"
const KEYWORD_CRITICAL := "critical"
const KEYWORD_GIANT := "giant"
const KEYWORD_TAUNT := "taunt"
const KEYWORD_LIFESTEAL := "lifesteal"
const KEYWORD_REFLECT := "reflect"
const KEYWORD_KAGUNE_BIKAKU := "bikaku"
const KEYWORD_KAGUNE_RINKAKU := "rinkaku"
const KEYWORD_KAGUNE_KOUKAKU := "koukaku"
const KEYWORD_KAGUNE_UKAKU := "ukaku"
const KEYWORD_TRIGGER := "trigger"
const KEYWORD_REBORN := "reborn"
const KEYWORD_REBORN_PREFIX := "reborn_"
const KEYWORD_SIEGE_PREFIX := "siege_"
const KEYWORD_SPLASH_PREFIX := "splash_"
const KEYWORD_FRONTAL_WIDTH_PREFIX := "frontal_width_"
const KEYWORD_SIEGE_3 := "siege_3"

# CardData 是静态卡牌数据，来自 data/cards.json。
# 它描述“这是什么牌”，不记录“这张牌当前怎么样”。

var faction_id := ""
var faction_name := ""

# 以下字段基本对应 data/cards.json 中每张卡牌的配置。
var id := ""
var display_name := ""
var description := ""
var type := ""
var role := ""
var count := 1
var level := 1
var keywords: Array[String] = []

# 效果定义来自 JSON。这里保存原始 Dictionary，由 EffectSystem 解释执行。
var effects: Array[Dictionary] = []
var spell_actions: Array[Dictionary] = []
var spell_tags: Array[String] = []
var actions: Array[Dictionary] = []
var mounted_attacks: Array[Dictionary] = []
var selection: Dictionary = {}
var target_rule := ""
var animation := ""
var audio := ""
var equipment_type := ""
var upgrade_type := ""
var attack := 0
var health := 0
var armor := 0
var movement := 1
var attack_speed := 1
var chaos_corruption := 0
var reborn_health_values: Array[int] = []
var owner_hero_card_id := ""
var start_in_hand := false
var evolution_line := ""

# JSON 中配置的正面图片路径。
var front_texture_path := ""
var table_texture_path := ""
var back_texture_path := ""

# 卡图按需加载。CardDatabase 初始化时只解析路径，避免一次性解码整套卡面。
var _front_texture: Texture2D
var front_texture: Texture2D:
	get:
		if _front_texture == null:
			_front_texture = load_texture(front_texture_path)
		return _front_texture
	set(value):
		_front_texture = value

var _table_texture: Texture2D
var table_texture: Texture2D:
	get:
		if _table_texture == null:
			_table_texture = load_texture(table_texture_path)
		return _table_texture
	set(value):
		_table_texture = value

var _back_texture: Texture2D
var back_texture: Texture2D:
	get:
		if _back_texture == null:
			_back_texture = load_texture(back_texture_path)
		return _back_texture
	set(value):
		_back_texture = value


func is_minion() -> bool:
	return type == TYPE_MINION


func is_spell() -> bool:
	return type == TYPE_SPELL


func is_building() -> bool:
	return type == TYPE_BUILDING


func is_upgrade() -> bool:
	return type == TYPE_UPGRADE


func is_equipment() -> bool:
	return type == TYPE_EQUIPMENT


func is_time() -> bool:
	return type == TYPE_TIME


func is_hero() -> bool:
	return role == ROLE_HERO


func is_hero_attached_card() -> bool:
	return owner_hero_card_id != ""


func should_enter_hand_when_revealed() -> bool:
	return is_spell() or is_upgrade() or is_equipment()


func is_unit() -> bool:
	return is_minion() or is_building()


func has_keyword(keyword: String) -> bool:
	return keywords.has(keyword)


func get_siege_bonus() -> int:
	return get_numeric_keyword_value(KEYWORD_SIEGE_PREFIX)


func get_splash_damage() -> int:
	return get_numeric_keyword_value(KEYWORD_SPLASH_PREFIX)


func get_frontal_attack_width() -> int:
	var width := get_numeric_keyword_value(KEYWORD_FRONTAL_WIDTH_PREFIX)
	if has_keyword(KEYWORD_GIANT):
		width = maxi(width, 3)
	return width if width > 0 and width % 2 == 1 else 0


func get_numeric_keyword_value(prefix: String) -> int:
	var value := 0
	for keyword in keywords:
		if not keyword.begins_with(prefix):
			continue

		var amount_text := keyword.substr(prefix.length())
		if not amount_text.is_valid_int():
			continue

		value = maxi(value, int(amount_text))

	return maxi(value, 0)

static func from_dictionary(card_dictionary: Dictionary, faction_dictionary: Dictionary) -> CardData:
	# 把 JSON 里的 Dictionary 转成代码里更好用的 CardData 对象。
	var data := CardData.new()

	# 记录这张牌属于哪个种族/阵营包。
	data.faction_id = str(faction_dictionary.get("id", ""))
	data.faction_name = str(faction_dictionary.get("name", ""))

	# get 的第二个参数是默认值，避免 JSON 缺字段时直接报错。
	data.id = str(card_dictionary.get("id", ""))
	data.display_name = str(card_dictionary.get("name", ""))
	data.description = str(card_dictionary.get("description", ""))
	data.type = str(card_dictionary.get("type", ""))
	data.role = str(card_dictionary.get("role", ""))
	data.count = int(card_dictionary.get("count", 1))
	data.level = maxi(int(card_dictionary.get("level", 1)), 1)
	data.target_rule = str(card_dictionary.get("target_rule", ""))
	var raw_selection: Variant = card_dictionary.get("selection", {})
	if raw_selection is Dictionary:
		data.selection = raw_selection.duplicate(true)
	data.animation = str(card_dictionary.get("animation", ""))
	data.audio = str(card_dictionary.get("audio", ""))
	data.equipment_type = str(card_dictionary.get("equipment_type", ""))
	data.upgrade_type = str(card_dictionary.get("upgrade_type", ""))
	data.attack = int(card_dictionary.get("attack", 0))
	data.health = int(card_dictionary.get("health", 0))
	data.armor = maxi(int(card_dictionary.get("armor", 0)), 0)
	data.movement = int(card_dictionary.get("movement", 1))
	data.attack_speed = int(card_dictionary.get("attack_speed", 1))
	data.chaos_corruption = int(card_dictionary.get("chaos_corruption", 0))
	var raw_reborn_health_values: Variant = card_dictionary.get("reborn_health_values", [])
	if raw_reborn_health_values is Array:
		for health_value in raw_reborn_health_values:
			data.reborn_health_values.append(maxi(int(health_value), 0))
	data.start_in_hand = bool(card_dictionary.get("start_in_hand", false))
	data.evolution_line = str(card_dictionary.get("evolution_line", ""))
	data.front_texture_path = str(card_dictionary.get("url", ""))
	data.table_texture_path = get_table_texture_path(data.front_texture_path)
	data.back_texture_path = "res://assets/img/卡背/%d.png" % data.level

	var raw_keywords = card_dictionary.get("keywords", [])
	if raw_keywords is Array:
		for keyword in raw_keywords:
			data.keywords.append(str(keyword))

	var raw_effects = card_dictionary.get("effects", [])
	if raw_effects is Array:
		for effect in raw_effects:
			if effect is Dictionary:
				data.effects.append(effect)

	var raw_spell_actions = card_dictionary.get("spell_actions", [])
	if raw_spell_actions is Array:
		for spell_action in raw_spell_actions:
			if spell_action is Dictionary:
				data.spell_actions.append(spell_action)

	var raw_spell_tags = card_dictionary.get(EffectData.KEY_SPELL_TAGS, [])
	if raw_spell_tags is Array:
		for spell_tag in raw_spell_tags:
			var normalized_spell_tag := str(spell_tag)
			if normalized_spell_tag != "" and not data.spell_tags.has(normalized_spell_tag):
				data.spell_tags.append(normalized_spell_tag)

	var raw_actions = card_dictionary.get(EffectData.KEY_ACTIONS, [])
	if raw_actions is Array:
		for action_data in raw_actions:
			if action_data is Dictionary:
				data.actions.append(action_data)

	var raw_mounted_attacks = card_dictionary.get(EffectData.KEY_MOUNTED_ATTACKS, [])
	if raw_mounted_attacks is Array:
		for mounted_attack in raw_mounted_attacks:
			if mounted_attack is Dictionary:
				data.mounted_attacks.append(mounted_attack)

	return data


static func load_texture(texture_path: String) -> Texture2D:
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		return null
	return ResourceLoader.load(texture_path) as Texture2D


static func get_table_texture_path(front_path: String) -> String:
	if front_path == "":
		return ""

	var extension := front_path.get_extension()
	if extension == "":
		return ""

	var table_path := "%s-table.%s" % [front_path.trim_suffix(".%s" % extension), extension]
	if ResourceLoader.exists(table_path):
		return table_path

	return ""
