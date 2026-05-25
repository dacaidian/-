extends RefCounted
class_name CardData

const TYPE_MINION := "minion"
const TYPE_SPELL := "spell"
const TYPE_BUILDING := "building"
const TYPE_UPGRADE := "upgrade"
const TYPE_EQUIPMENT := "equipment"
const TYPE_TIME := "time"
const EQUIPMENT_TYPE_WEAPON := "weapon"
const ROLE_HERO := "hero"
const KEYWORD_CAVALRY := "cavalry"
const KEYWORD_RANGED := "ranged"
const KEYWORD_MAGIC_IMMUNE := "magic_immune"
const KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK := "can_attack_with_zero_attack"
const KEYWORD_MECHANICAL := "mechanical"
const KEYWORD_MOBILE_ASSAULT := "mobile_assault"
const KEYWORD_SIEGE_PREFIX := "siege_"
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
var target_rule := ""
var animation := ""
var equipment_type := ""
var attack := 0
var health := 0
var attack_speed := 1
var owner_hero_card_id := ""

# JSON 中配置的正面图片路径。
var front_texture_path := ""
var back_texture_path := ""

# 运行时根据 front_texture_path 加载出的图片资源。
var front_texture: Texture2D
var back_texture: Texture2D


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
	for keyword in keywords:
		if not keyword.begins_with(KEYWORD_SIEGE_PREFIX):
			continue

		var amount_text := keyword.substr(KEYWORD_SIEGE_PREFIX.length())
		if not amount_text.is_valid_int():
			continue

		return maxi(int(amount_text), 0)

	return 0

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
	data.animation = str(card_dictionary.get("animation", ""))
	data.equipment_type = str(card_dictionary.get("equipment_type", ""))
	data.attack = int(card_dictionary.get("attack", 0))
	data.health = int(card_dictionary.get("health", 0))
	data.attack_speed = int(card_dictionary.get("attack_speed", 1))
	data.front_texture_path = str(card_dictionary.get("url", ""))
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

	# JSON 只保存资源路径；真正的 Texture2D 在这里加载。
	if data.front_texture_path != "":
		data.front_texture = load(data.front_texture_path) as Texture2D
	if ResourceLoader.exists(data.back_texture_path):
		data.back_texture = load(data.back_texture_path) as Texture2D

	return data
