extends RefCounted
class_name CardCollectionCatalog

const CardCatalogEntryScript := preload(
	"res://scripts/application/card_catalog_entry.gd"
)

const SORT_DEFAULT := "default"
const SORT_NAME := "name"
const SORT_LEVEL := "level"
const SORT_TYPE := "type"

const TYPE_ORDER := {
	CardData.ROLE_HERO: 0,
	CardData.TYPE_MINION: 1,
	CardData.TYPE_SPELL: 2,
	CardData.TYPE_BUILDING: 3,
	CardData.TYPE_UPGRADE: 4,
	CardData.TYPE_EQUIPMENT: 5,
	CardData.TYPE_TIME: 6,
}

const CATEGORY_ORDER := {
	CardCatalogEntryScript.CATEGORY_POOL: 0,
	CardCatalogEntryScript.CATEGORY_STARTING_HAND: 1,
	CardCatalogEntryScript.CATEGORY_TOKEN: 2,
	CardCatalogEntryScript.CATEGORY_SYSTEM: 3,
}

var entries: Array[CardCatalogEntryScript] = []
var faction_ids: Array[String] = []
var faction_counts: Dictionary = {}


func rebuild(card_database: CardDatabase) -> void:
	entries.clear()
	faction_ids.clear()
	faction_counts.clear()
	if card_database == null:
		return

	faction_ids = card_database.get_all_faction_ids()
	for faction_index in range(faction_ids.size()):
		var faction_id := faction_ids[faction_index]
		var display_name := card_database.get_faction_display_name(faction_id)
		var faction_entries := 0

		for card_data in card_database.get_faction_cards(faction_id):
			entries.append(_create_entry(
				card_database,
				card_data,
				display_name,
				faction_index,
				CardCatalogEntryScript.SOURCE_REGULAR
			))
			faction_entries += 1

		for token_data in card_database.get_faction_token_cards(faction_id):
			entries.append(_create_entry(
				card_database,
				token_data,
				display_name,
				faction_index,
				CardCatalogEntryScript.SOURCE_TOKEN
			))
			faction_entries += 1

		faction_counts[faction_id] = faction_entries


func query(filters: Dictionary = {}) -> Array[CardCatalogEntryScript]:
	var result: Array[CardCatalogEntryScript] = []
	var faction_id := str(filters.get("faction_id", ""))
	var type_key := str(filters.get("type", ""))
	var category := str(filters.get("category", ""))
	var level := int(filters.get("level", 0))
	var search_terms := _get_search_terms(str(filters.get("search", "")))

	for entry in entries:
		if faction_id != "" and entry.faction_id != faction_id:
			continue
		if type_key != "" and entry.get_type_filter_key() != type_key:
			continue
		if category != "" and entry.category != category:
			continue
		if level > 0 and entry.card_data.level != level:
			continue
		if not _matches_search(entry, search_terms):
			continue
		result.append(entry)

	var sort_mode := str(filters.get("sort", SORT_DEFAULT))
	result.sort_custom(_compare_entries.bind(sort_mode))
	return result


func get_total_count() -> int:
	return entries.size()


func get_faction_count(faction_id: String) -> int:
	return int(faction_counts.get(faction_id, 0))


func _create_entry(
	card_database: CardDatabase,
	card_data: CardData,
	display_name: String,
	faction_index: int,
	source: String
) -> CardCatalogEntryScript:
	var hero_display_name := ""
	if card_data.owner_hero_card_id != "":
		var hero_data := card_database.get_card(card_data.owner_hero_card_id)
		if hero_data != null:
			hero_display_name = hero_data.display_name

	var entry := CardCatalogEntryScript.new()
	entry.setup(
		card_data,
		display_name,
		faction_index,
		source,
		hero_display_name
	)
	return entry


func _get_search_terms(search_text: String) -> Array[String]:
	var terms: Array[String] = []
	for raw_term in search_text.strip_edges().to_lower().split(" ", false):
		var term := str(raw_term).strip_edges()
		if term != "":
			terms.append(term)
	return terms


func _matches_search(entry: CardCatalogEntryScript, search_terms: Array[String]) -> bool:
	for term in search_terms:
		if not entry.search_text.contains(term):
			return false
	return true


func _compare_entries(
	left: CardCatalogEntryScript,
	right: CardCatalogEntryScript,
	sort_mode: String
) -> bool:
	match sort_mode:
		SORT_NAME:
			var name_order := _compare_text(left.card_data.display_name, right.card_data.display_name)
			if name_order != 0:
				return name_order < 0
		SORT_LEVEL:
			if left.card_data.level != right.card_data.level:
				return left.card_data.level < right.card_data.level
		SORT_TYPE:
			var left_type_rank := int(TYPE_ORDER.get(left.get_type_filter_key(), 99))
			var right_type_rank := int(TYPE_ORDER.get(right.get_type_filter_key(), 99))
			if left_type_rank != right_type_rank:
				return left_type_rank < right_type_rank

	if left.faction_order != right.faction_order:
		return left.faction_order < right.faction_order
	if left.card_data.level != right.card_data.level:
		return left.card_data.level < right.card_data.level

	var left_type := int(TYPE_ORDER.get(left.get_type_filter_key(), 99))
	var right_type := int(TYPE_ORDER.get(right.get_type_filter_key(), 99))
	if left_type != right_type:
		return left_type < right_type

	var left_category := int(CATEGORY_ORDER.get(left.category, 99))
	var right_category := int(CATEGORY_ORDER.get(right.category, 99))
	if left_category != right_category:
		return left_category < right_category

	var display_name_order := _compare_text(
		left.card_data.display_name,
		right.card_data.display_name
	)
	if display_name_order != 0:
		return display_name_order < 0
	return _compare_text(left.card_data.id, right.card_data.id) < 0


func _compare_text(left: String, right: String) -> int:
	return left.naturalnocasecmp_to(right)
