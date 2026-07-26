extends CardEffect
class_name ClaimDeathSlotEffect

# Reserves the dying unit's slot for a replacement before normal board refill.
func execute(source_state: CardState, effect_data: Dictionary, game_manager: Node) -> void:
	if source_state == null or game_manager == null:
		return
	if not game_manager.has_method("claim_death_slot"):
		return

	var card_id := EffectData.get_card_id(effect_data)
	if card_id == "":
		return

	var claim := {
		EffectData.KEY_CARD_ID: card_id,
		EffectData.KEY_SLOT_OWNER: str(
			effect_data.get(EffectData.KEY_SLOT_OWNER, EffectData.DEATH_SLOT_OWNER_DEFEATED)
		),
		EffectData.KEY_OWNER_ID: get_effect_owner_id(source_state, effect_data),
		EffectData.KEY_VICTIM_LAYER: str(
			effect_data.get(EffectData.KEY_VICTIM_LAYER, EffectData.BOARD_LAYER_GROUND)
		),
		EffectData.KEY_DESTINATION_LAYER: str(
			effect_data.get(EffectData.KEY_DESTINATION_LAYER, EffectData.BOARD_LAYER_GROUND)
		),
		EffectData.KEY_PRIORITY: int(effect_data.get(EffectData.KEY_PRIORITY, 200)),
		EffectData.KEY_ANIMATION: str(effect_data.get(EffectData.KEY_ANIMATION, ""))
	}
	game_manager.claim_death_slot(source_state, claim)


func can_execute(
	source_state: CardState,
	effect_data: Dictionary,
	game_manager: Node
) -> bool:
	return (
		source_state != null
		and game_manager != null
		and game_manager.has_method("claim_death_slot")
		and EffectData.get_card_id(effect_data) != ""
	)
