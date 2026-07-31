extends RefCounted
class_name MatchResult

enum EndReason {
	RESOURCE_VICTORY,
	SURRENDER,
}

var end_reason: EndReason = EndReason.RESOURCE_VICTORY
var winner_player_id := ""
var loser_player_id := ""
var surrendered_player_id := ""
var turn_number := 0
var victory_target := 0
var finished_at_unix_time := 0
var player_summaries: Array[Dictionary] = []


static func create(
	reason: EndReason,
	winner: PlayerState,
	all_players: Array[PlayerState],
	current_turn_number: int,
	resource_victory_target: int,
	surrendered_player: PlayerState = null
) -> MatchResult:
	var result := MatchResult.new()
	result.end_reason = reason
	result.turn_number = current_turn_number
	result.victory_target = resource_victory_target
	result.finished_at_unix_time = int(Time.get_unix_time_from_system())
	result.winner_player_id = winner.id if winner != null else ""
	result.surrendered_player_id = (
		surrendered_player.id
		if surrendered_player != null
		else ""
	)

	for player in all_players:
		if player == null:
			continue
		result.player_summaries.append({
			"player_id": player.id,
			"display_name": player.display_name,
			"faction_id": player.faction_id,
			"faction_name": player.faction_name,
			"resource_score": player.resource_score,
			"hand_count": player.hand.size(),
			"graveyard_count": player.graveyard.size(),
			"equipment_count": player.equipped_cards_by_type.size(),
		})
		if player.id != result.winner_player_id:
			result.loser_player_id = player.id

	return result


func is_surrender() -> bool:
	return end_reason == EndReason.SURRENDER


func get_player_summary(player_id: String) -> Dictionary:
	for summary in player_summaries:
		if str(summary.get("player_id", "")) == player_id:
			return summary
	return {}


func get_end_reason_text() -> String:
	return "投降" if is_surrender() else "达到资源分目标"


func to_dictionary() -> Dictionary:
	return {
		"end_reason": end_reason,
		"winner_player_id": winner_player_id,
		"loser_player_id": loser_player_id,
		"surrendered_player_id": surrendered_player_id,
		"turn_number": turn_number,
		"victory_target": victory_target,
		"finished_at_unix_time": finished_at_unix_time,
		"player_summaries": player_summaries.duplicate(true),
	}
