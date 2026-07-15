extends RefCounted
class_name TurnEventLedger

# Records attributed events for the currently active turn. Faction mechanics
# query this ledger instead of teaching the death pipeline about faction rules.

var turn_player_id := ""
var death_records: Array[Dictionary] = []


func begin_turn(player_id: String) -> void:
	turn_player_id = player_id
	death_records.clear()


func record_death(victim: CardState, source_owner_id: String, reason: String) -> void:
	if victim == null or victim.is_empty():
		return

	death_records.append({
		"source_owner_id": source_owner_id,
		"victim_owner_id": victim.owner_id,
		"victim_card_id": victim.card_id,
		"is_minion": victim.is_minion(),
		"is_hero": victim.is_hero(),
		"reason": reason
	})


func get_qualified_minion_kill_count(player_id: String) -> int:
	var count := 0
	for record in death_records:
		if is_qualified_minion_kill(record, player_id):
			count += 1
	return count


func has_enemy_minion_kill(player_id: String) -> bool:
	for record in death_records:
		if not is_qualified_minion_kill(record, player_id):
			continue
		if str(record.get("victim_owner_id", "")) != player_id:
			return true
	return false


func is_qualified_minion_kill(record: Dictionary, player_id: String) -> bool:
	if player_id == "" or turn_player_id != player_id:
		return false
	if str(record.get("source_owner_id", "")) != player_id:
		return false
	if not bool(record.get("is_minion", false)) or bool(record.get("is_hero", false)):
		return false

	# Neutral units and buildings are not food for the RC concentration rule.
	return str(record.get("victim_owner_id", "")) != ""
