extends RefCounted
class_name FactionRuntimeStateResolver

const RcConcentrationResolverScript := preload("res://scripts/game/rc_concentration_resolver.gd")

var rc_concentration_resolver := RcConcentrationResolverScript.new()


func resolve_after_turn_end(
	game_manager: GameManager,
	player: PlayerState,
	ledger: TurnEventLedger
) -> bool:
	if game_manager == null or player == null:
		return false

	if rc_concentration_resolver.handles(player):
		return await rc_concentration_resolver.resolve_after_turn_end(game_manager, player, ledger)

	if not player.should_advance_faction_runtime_state_on(EventContext.TRIGGER_AFTER_TURN_END):
		return false

	return player.advance_faction_runtime_state()
