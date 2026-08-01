extends CardEffect
class_name ApplyStatusEffect

const StatusModifierResolverScript := preload("res://scripts/game/status_modifier_resolver.gd")

var status_modifier_resolver := StatusModifierResolverScript.new()

# 给目标单位附加运行时状态。状态只负责记录和生命周期；
# 中毒、圣盾等具体规则可以后续通过状态 id/tag 接入对应 resolver。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var runtime_effect_data := status_modifier_resolver.resolve_status_effect_data(source_state, effect_data, game_manager)
	var status_id := EffectData.get_status_id(runtime_effect_data)
	if status_id == "":
		push_warning("apply_status 缺少 status_id")
		return

	var applied_targets: Array[CardState] = []
	for target_state in get_target_states(source_state, runtime_effect_data, game_manager):
		if target_state == null or not target_state.is_unit():
			continue

		var previous_owner_id := target_state.owner_id
		var status := CardStatus.from_effect_data(runtime_effect_data, target_state, source_state)
		target_state.add_status(status)
		refresh_owner_dependent_passives_if_needed(previous_owner_id, target_state.owner_id, game_manager)
		applied_targets.append(target_state)

	await play_apply_animation(applied_targets, runtime_effect_data, game_manager)


func play_apply_animation(
	targets: Array[CardState],
	effect_data: Dictionary,
	game_manager: Node
) -> void:
	var apply_animation := str(effect_data.get("apply_animation", ""))
	if apply_animation == "" or targets.is_empty() or game_manager == null:
		return

	var played_multi := false
	if (
		EffectData.get_presentation_scope(effect_data) == EffectData.PRESENTATION_SCOPE_MULTI
		and game_manager.has_method("play_multi_target_effect_animation")
	):
		played_multi = bool(
			await game_manager.play_multi_target_effect_animation(targets, apply_animation)
		)
	if played_multi or not game_manager.has_method("play_status_apply_animation"):
		return

	for target_state in targets:
		await game_manager.play_status_apply_animation(target_state, apply_animation)


func refresh_owner_dependent_passives_if_needed(previous_owner_id: String, next_owner_id: String, game_manager: Node) -> void:
	if previous_owner_id == next_owner_id or game_manager == null:
		return
	if next_owner_id == "" or not game_manager.has_method("get_player_by_id"):
		return

	var next_owner := game_manager.get_player_by_id(next_owner_id) as PlayerState
	if next_owner != null and game_manager.has_method("refresh_hand_passives_for_player"):
		game_manager.refresh_hand_passives_for_player(next_owner, false)
