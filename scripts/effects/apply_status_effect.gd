extends CardEffect
class_name ApplyStatusEffect

# 给目标单位附加运行时状态。状态只负责记录和生命周期；
# 中毒、圣盾等具体规则可以后续通过状态 id/tag 接入对应 resolver。
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	var status_id := EffectData.get_status_id(effect_data)
	if status_id == "":
		push_warning("apply_status 缺少 status_id")
		return

	for target_state in get_target_states(source_state, effect_data, game_manager):
		if target_state == null or not target_state.is_unit():
			continue

		var status := CardStatus.from_effect_data(effect_data, target_state, source_state)
		target_state.add_status(status)
		var apply_animation := str(effect_data.get("apply_animation", ""))
		if apply_animation != "" and game_manager != null and game_manager.has_method("play_status_apply_animation"):
			await game_manager.play_status_apply_animation(target_state, apply_animation)
