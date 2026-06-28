extends Resource
class_name HandCardState

const SOURCE_HERO_REVIVE := "hero_revive"

var data: CardData
var owner_id := ""
var cooldown_turns := 0
var source := ""
var tags: Array[String] = []
var permanent_stat_overrides: Dictionary = {}


func setup(
	new_data: CardData,
	new_owner_id: String,
	new_cooldown_turns := 0,
	new_source := "",
	new_tags: Array[String] = [],
	new_permanent_stat_overrides: Dictionary = {}
) -> void:
	data = new_data
	owner_id = new_owner_id
	cooldown_turns = maxi(new_cooldown_turns, 0)
	source = new_source
	tags = new_tags.duplicate()
	permanent_stat_overrides = new_permanent_stat_overrides.duplicate(true)


func has_permanent_stat_overrides() -> bool:
	return not permanent_stat_overrides.is_empty()


func get_permanent_stat_overrides() -> Dictionary:
	return permanent_stat_overrides.duplicate(true)


func is_available() -> bool:
	return cooldown_turns <= 0


func tick_cooldown() -> bool:
	if cooldown_turns <= 0:
		return false

	cooldown_turns -= 1
	return true


static func get_card_data(entry: Variant) -> CardData:
	if entry is CardData:
		return entry as CardData
	if entry is HandCardState:
		var hand_card_state := entry as HandCardState
		return hand_card_state.data

	return null


static func get_cooldown_turns(entry: Variant) -> int:
	if entry is HandCardState:
		var hand_card_state := entry as HandCardState
		return hand_card_state.cooldown_turns

	return 0


static func is_entry_available(entry: Variant) -> bool:
	if entry is HandCardState:
		var hand_card_state := entry as HandCardState
		return hand_card_state.is_available()

	return get_card_data(entry) != null
