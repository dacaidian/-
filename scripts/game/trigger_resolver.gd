extends RefCounted
class_name TriggerResolver

# TriggerResolver 统一管理触发队列。
# on_enter_board 是单位新身份在战场生效的统一入口；on_reveal 仅保留给真正翻牌专用效果。

var trigger_queue: Array[Dictionary] = []
var is_resolving := false


func queue_trigger(source_state: CardState, trigger: String, context: Dictionary = {}) -> void:
	if source_state == null or trigger == "":
		return

	trigger_queue.append({
		"source_state": source_state,
		"trigger": trigger,
		"context": context.duplicate(true)
	})


func queue_board_entry(
	source_state: CardState,
	entry_reason: String,
	include_reveal_trigger := false
) -> void:
	if source_state == null:
		return

	var context := {
		EventContext.BOARD_ENTRY_REASON: entry_reason,
	}
	queue_trigger(source_state, EventContext.TRIGGER_ON_ENTER_BOARD, context)
	if include_reveal_trigger:
		queue_trigger(source_state, EventContext.TRIGGER_ON_REVEAL, context)


func resolve_queued(game_manager: GameManager) -> void:
	if game_manager == null or is_resolving:
		return

	is_resolving = true
	while not trigger_queue.is_empty():
		var trigger_entry: Dictionary = trigger_queue.pop_front()
		var source_state := trigger_entry.get("source_state") as CardState
		var trigger := str(trigger_entry.get("trigger", ""))
		var context: Dictionary = {}
		var raw_context: Variant = trigger_entry.get("context", {})
		if raw_context is Dictionary:
			context = raw_context

		await game_manager.effect_registry.execute_trigger(source_state, trigger, game_manager, context)

	is_resolving = false
