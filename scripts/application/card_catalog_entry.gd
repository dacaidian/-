extends RefCounted
class_name CardCatalogEntry

const SOURCE_REGULAR := "regular"
const SOURCE_TOKEN := "token"

const CATEGORY_POOL := "pool"
const CATEGORY_STARTING_HAND := "starting_hand"
const CATEGORY_TOKEN := "token"
const CATEGORY_SYSTEM := "system"

const KEYWORD_LABELS := {
	CardData.KEYWORD_CAVALRY: "骑兵",
	CardData.KEYWORD_RANGED: "远程",
	CardData.KEYWORD_MAGIC_IMMUNE: "魔法免疫",
	CardData.KEYWORD_RANGED_ATTACK_IMMUNE: "远程攻击免疫",
	CardData.KEYWORD_CAN_ATTACK_WITH_ZERO_ATTACK: "零攻可攻击",
	CardData.KEYWORD_MECHANICAL: "机械",
	CardData.KEYWORD_MOBILE_ASSAULT: "移动攻击",
	CardData.KEYWORD_SPELL_MOVE: "施法移动",
	CardData.KEYWORD_SPELL_ATTACK: "施法攻击",
	CardData.KEYWORD_FLYING: "飞行",
	CardData.KEYWORD_TELEPORT: "瞬移",
	CardData.KEYWORD_STEALTH: "隐身",
	CardData.KEYWORD_CRITICAL: "暴击",
	CardData.KEYWORD_GIANT: "巨兽",
	CardData.KEYWORD_TAUNT: "嘲讽",
	CardData.KEYWORD_LIFESTEAL: "吸血",
	CardData.KEYWORD_REFLECT: "反伤",
	CardData.KEYWORD_KAGUNE_BIKAKU: "尾赫",
	CardData.KEYWORD_KAGUNE_RINKAKU: "鳞赫",
	CardData.KEYWORD_KAGUNE_KOUKAKU: "甲赫",
	CardData.KEYWORD_KAGUNE_UKAKU: "羽赫",
	CardData.KEYWORD_TRIGGER: "触发",
	CardData.KEYWORD_REBORN: "复生",
}

const UNIT_TRAIT_LABELS := {
	CardData.UNIT_TRAIT_HUMANOID: "类人生物",
	CardData.UNIT_TRAIT_HUMAN: "人类",
	CardData.UNIT_TRAIT_ELF: "精灵",
	CardData.UNIT_TRAIT_ORC: "兽人",
	CardData.UNIT_TRAIT_DWARF: "矮人",
	CardData.UNIT_TRAIT_BEASTFOLK: "兽裔",
	CardData.UNIT_TRAIT_GHOUL: "喰种",
	CardData.UNIT_TRAIT_DEMON: "恶魔",
	CardData.UNIT_TRAIT_UNDEAD: "亡灵",
	CardData.UNIT_TRAIT_BEAST: "野兽",
	CardData.UNIT_TRAIT_AVIAN: "鸟类",
	CardData.UNIT_TRAIT_REPTILE: "爬行生物",
	CardData.UNIT_TRAIT_INSECT: "虫类",
	CardData.UNIT_TRAIT_ELEMENTAL: "元素",
	CardData.UNIT_TRAIT_MECHANICAL: "机械",
	CardData.UNIT_TRAIT_CONSTRUCT: "构装体",
	CardData.UNIT_TRAIT_SPIRIT: "灵体",
	CardData.UNIT_TRAIT_YAOGUAI: "妖族",
	CardData.UNIT_TRAIT_ALIEN: "异星生物",
	CardData.UNIT_TRAIT_ABERRATION: "异化体",
	CardData.UNIT_TRAIT_COSMIC: "宇宙实体",
	CardData.UNIT_TRAIT_GU: "蛊物",
	CardData.UNIT_TRAIT_FOX: "狐族",
	CardData.UNIT_TRAIT_MONKEY: "猴族",
	CardData.UNIT_TRAIT_CHAOS: "混沌生物",
	CardData.UNIT_TRAIT_SYMBIOTE: "共生体",
}

var card_data: CardData
var faction_id := ""
var faction_display_name := ""
var faction_order := 0
var structural_source := SOURCE_REGULAR
var category := CATEGORY_POOL
var owner_hero_display_name := ""
var search_text := ""


func setup(
	data: CardData,
	display_faction_name: String,
	load_order: int,
	source: String,
	hero_display_name := ""
) -> void:
	card_data = data
	faction_id = data.faction_id if data != null else ""
	faction_display_name = display_faction_name
	faction_order = load_order
	structural_source = source
	owner_hero_display_name = hero_display_name
	category = _resolve_category()
	search_text = _build_search_text()


func is_token() -> bool:
	return structural_source == SOURCE_TOKEN


func is_hero() -> bool:
	return card_data != null and card_data.is_hero()


func get_type_filter_key() -> String:
	if is_hero():
		return CardData.ROLE_HERO
	return card_data.type if card_data != null else ""


func get_type_label() -> String:
	match get_type_filter_key():
		CardData.ROLE_HERO:
			return "英雄牌"
		CardData.TYPE_MINION:
			return "随从牌"
		CardData.TYPE_SPELL:
			return "法术牌"
		CardData.TYPE_BUILDING:
			return "建筑牌"
		CardData.TYPE_UPGRADE:
			if card_data.upgrade_type == CardData.UPGRADE_TYPE_MINION_LIBRARY:
				return "随从库牌"
			return "升级牌"
		CardData.TYPE_EQUIPMENT:
			return "装备牌"
		CardData.TYPE_TIME:
			return "状态牌"
		_:
			return "其他"


func get_category_label() -> String:
	match category:
		CATEGORY_STARTING_HAND:
			return "默认入手"
		CATEGORY_TOKEN:
			return "衍生牌"
		CATEGORY_SYSTEM:
			return "状态展示"
		_:
			return "常规牌池"


func get_collection_note() -> String:
	if card_data == null:
		return ""

	match category:
		CATEGORY_STARTING_HAND:
			return "游戏开始时自动进入对应玩家手牌，不进入常规牌池。"
		CATEGORY_TOKEN:
			return "由卡牌、技能或形态变化生成，不进入常规牌池。"
		CATEGORY_SYSTEM:
			return "用于展示种族时间、浓度或其他规则状态，不进入常规牌池。"
		_:
			return "常规牌池中共有 %d 张。" % maxi(card_data.count, 0)


func get_keyword_labels() -> Array[String]:
	var labels: Array[String] = []
	if card_data == null:
		return labels

	for keyword in card_data.keywords:
		var label := _get_keyword_label(keyword)
		if label != "" and not labels.has(label):
			labels.append(label)

	return labels


func get_unit_trait_labels() -> Array[String]:
	var labels: Array[String] = []
	if card_data == null:
		return labels

	for unit_trait in card_data.unit_traits:
		var label := str(UNIT_TRAIT_LABELS.get(unit_trait, unit_trait))
		if label != "" and not labels.has(label):
			labels.append(label)

	return labels


func get_stats_text() -> String:
	if card_data == null or not card_data.is_unit():
		return ""

	var parts: Array[String] = [
		"攻击 %d" % card_data.attack,
		"生命 %d" % card_data.health,
	]
	if card_data.armor > 0:
		parts.append("护甲 %d" % card_data.armor)
	if card_data.is_minion():
		parts.append("移动 %d" % card_data.movement)
		parts.append("攻速 %d" % card_data.attack_speed)
	if card_data.chaos_corruption > 0:
		parts.append("腐蚀 %d" % card_data.chaos_corruption)
	return "  ·  ".join(parts)


func _resolve_category() -> String:
	if structural_source == SOURCE_TOKEN:
		return CATEGORY_TOKEN
	if card_data == null:
		return CATEGORY_SYSTEM
	if card_data.start_in_hand:
		return CATEGORY_STARTING_HAND
	if card_data.is_time() or card_data.count <= 0:
		return CATEGORY_SYSTEM
	return CATEGORY_POOL


func _build_search_text() -> String:
	if card_data == null:
		return ""

	var terms: Array[String] = [
		card_data.id,
		card_data.display_name,
		card_data.description,
		faction_id,
		faction_display_name,
		get_type_label(),
		get_category_label(),
		owner_hero_display_name,
	]
	terms.append_array(card_data.keywords)
	terms.append_array(get_keyword_labels())
	terms.append_array(card_data.unit_traits)
	terms.append_array(get_unit_trait_labels())
	if owner_hero_display_name != "":
		terms.append("英雄专属")
	return " ".join(terms).to_lower()


func _get_keyword_label(keyword: String) -> String:
	if KEYWORD_LABELS.has(keyword):
		return str(KEYWORD_LABELS[keyword])
	if keyword.begins_with(CardData.KEYWORD_SIEGE_PREFIX):
		return "攻城 %s" % keyword.trim_prefix(CardData.KEYWORD_SIEGE_PREFIX)
	if keyword.begins_with(CardData.KEYWORD_SPLASH_PREFIX):
		return "溅射 %s" % keyword.trim_prefix(CardData.KEYWORD_SPLASH_PREFIX)
	if keyword.begins_with(CardData.KEYWORD_FRONTAL_WIDTH_PREFIX):
		return "正面攻击 %s 格" % keyword.trim_prefix(CardData.KEYWORD_FRONTAL_WIDTH_PREFIX)
	if keyword.begins_with(CardData.KEYWORD_REBORN_PREFIX):
		return "复生 %s" % keyword.trim_prefix(CardData.KEYWORD_REBORN_PREFIX)
	return keyword
