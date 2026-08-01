extends SceneTree

const TokyoGhoulAnimationProviderScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_animation_provider.gd"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var effect_root := Control.new()
	effect_root.name = "TokyoGhoulAnimationTestRoot"
	effect_root.size = Vector2(1280.0, 720.0)
	root.add_child(effect_root)

	var provider := TokyoGhoulAnimationProviderScript.new()
	provider.setup(0.01)
	var target_rect := Rect2(Vector2(540.0, 260.0), Vector2(120.0, 168.0))

	for animation_key in [
		"centipede_form",
		"dragon_form",
		"saint_sword_form",
		"bikaku_volley"
	]:
		await provider.play_at_rect(effect_root, effect_root, target_rect, animation_key)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			return

	for animation_key in [
		"kagune_release",
		"rc_rise_medium",
		"rc_rise_high",
		"rc_fall_medium",
		"rc_fall_low",
		"s_rank_intelligence",
		"sss_rank_intelligence",
	]:
		await provider.play_board(effect_root, effect_root, animation_key)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			return

	var caster := Card.new()
	caster.size = Vector2(96.0, 132.0)
	caster.global_position = Vector2(180.0, 300.0)
	var target := Card.new()
	target.size = Vector2(96.0, 132.0)
	target.global_position = Vector2(880.0, 260.0)
	await provider.play_targeted(effect_root, effect_root, caster, target, "feather_needle")
	await process_frame
	if not _assert_no_children(effect_root, "feather_needle"):
		caster.free()
		target.free()
		return


	for animation_key in [
		"centipede_form",
		"dragon_form",
		"saint_sword_form",
		"rc_forced_feeding",
		"bikaku_volley",
		"free_meal",
		"kakuja_form",
		"restore_form",
		"special_blend",
		"sugar_cube_coffee",
		"kagune_lifesteal",
		"koukaku_reflect",
	]:
		await provider.play_targeted(effect_root, effect_root, caster, target, animation_key)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			caster.free()
			target.free()
			return

	for animation_key in ["centipede_form", "dragon_form", "saint_sword_form"]:
		await provider.play_from_rect(
			effect_root,
			effect_root,
			caster.get_global_rect(),
			target,
			animation_key
		)
		await process_frame
		if not _assert_no_children(effect_root, "%s_from_hand" % animation_key):
			caster.free()
			target.free()
			return

	for animation_key in [
		"tokyo_bikaku_attack",
		"tokyo_rinkaku_attack",
		"tokyo_koukaku_attack",
		"tokyo_ukaku_attack",
		"tokyo_chimera_attack",
		"tokyo_centipede_attack",
		"tokyo_dragon_attack",
		"tokyo_saint_sword_attack",
		"tokyo_owl_attack",
		"tokyo_furuta_attack",
	]:
		if not provider.is_replacement_attack_key(animation_key):
			push_error("Tokyo Ghoul attack key is not marked as a replacement: %s" % animation_key)
			quit(1)
			return
		await provider.play_from_rect(
			effect_root,
			effect_root,
			caster.get_global_rect(),
			target,
			animation_key
		)
		await process_frame
		if not _assert_no_children(effect_root, animation_key):
			caster.free()
			target.free()
			return

	await provider.play_attack_from_rect(
		effect_root,
		effect_root,
		caster.get_global_rect(),
		target,
		"tokyo_bikaku_attack",
		true
	)
	await process_frame
	if not _assert_no_children(effect_root, "tokyo_bikaku_melee_impact"):
		caster.free()
		target.free()
		return

	caster.free()
	target.free()
	await process_frame
	if not _assert_no_children(effect_root, "targeted_cleanup"):
		return

	var state := CardState.new()
	var card_data := CardData.new()
	card_data.id = "tokyo_ghoul_overlay_test"
	card_data.type = CardData.TYPE_MINION
	card_data.health = 8
	state.set_card_data(card_data)
	state.set_face_up(true)

	var status := CardStatus.new()
	status.status_id = KagunePowerResolver.STATUS_ID
	status.tags = [KagunePowerResolver.STATUS_TAG]
	status.payload = {
		KagunePowerResolver.PAYLOAD_KAGUNE_TYPES: [
			CardData.KEYWORD_KAGUNE_BIKAKU,
			CardData.KEYWORD_KAGUNE_RINKAKU,
			CardData.KEYWORD_KAGUNE_KOUKAKU,
			CardData.KEYWORD_KAGUNE_UKAKU
		],
		KagunePowerResolver.PAYLOAD_IS_HIGH_CONCENTRATION: true
	}
	state.add_status(status)

	var overlay := CardStatusOverlay.new()
	overlay.size = Vector2(120.0, 168.0)
	effect_root.add_child(overlay)
	overlay.set_state(state)
	if not overlay.visible or not overlay.is_processing():
		push_error("Tokyo Ghoul kagune overlay did not enable animated refresh")
		quit(1)
		return

	state.remove_status(status.status_id)
	overlay.refresh()
	if overlay.visible or overlay.is_processing():
		push_error("Tokyo Ghoul kagune overlay stayed active after status removal")
		quit(1)
		return
	for form_id in [
		"kaneki_centipede_form",
		"kaneki_dragon_form",
		"kaneki_saint_sword_form",
		"non_killing_owl",
		"one_eyed_owl",
	]:
		card_data.id = form_id
		state.card_id = form_id
		overlay.refresh()
		if not overlay.visible or not overlay.is_processing():
			push_error("Tokyo Ghoul transformed form did not enable its persistent visual: %s" % form_id)
			quit(1)
			return
	card_data.id = "tokyo_ghoul_overlay_test"
	state.card_id = card_data.id
	overlay.refresh()
	if overlay.visible or overlay.is_processing():
		push_error("Tokyo Ghoul transformed form visual did not clear")
		quit(1)
		return

	if not _test_attack_profile_resolution():
		return
	if not _test_implicit_transform_animation_target():
		return
	if not _test_animation_config_contract():
		return

	overlay.queue_free()
	effect_root.queue_free()
	await process_frame
	print("TOKYO_GHOUL_ANIMATION_TESTS_OK")
	call_deferred("_finish_success")


func _finish_success() -> void:
	await process_frame
	quit()


func _test_attack_profile_resolution() -> bool:
	var resolver := GameAnimationResolver.new()
	var cases := {
		CardData.KEYWORD_KAGUNE_BIKAKU: "tokyo_bikaku_attack",
		CardData.KEYWORD_KAGUNE_RINKAKU: "tokyo_rinkaku_attack",
		CardData.KEYWORD_KAGUNE_KOUKAKU: "tokyo_koukaku_attack",
		CardData.KEYWORD_KAGUNE_UKAKU: "tokyo_ukaku_attack",
	}
	for keyword in cases.keys():
		var state := _create_attack_state("profile_%s" % keyword, [str(keyword)])
		if resolver.resolve_attack_animation_key(state) != str(cases[keyword]):
			push_error("Tokyo Ghoul attack profile mismatch for %s" % keyword)
			quit(1)
			return false

	var chimera := _create_attack_state(
		"shikorae",
		[CardData.KEYWORD_KAGUNE_BIKAKU, CardData.KEYWORD_KAGUNE_UKAKU]
	)
	if resolver.resolve_attack_animation_key(chimera) != "tokyo_chimera_attack":
		push_error("Tokyo Ghoul multi-kagune attack did not resolve to chimera")
		quit(1)
		return false

	for card_id in [
		"kaneki_centipede_form",
		"kaneki_dragon_form",
		"kaneki_saint_sword_form",
		"kuzen_yoshimura",
		"eto_yoshimura",
		"non_killing_owl",
		"nimura_furuta",
	]:
		var state := _create_attack_state(card_id, [])
		if resolver.resolve_attack_animation_key(state) == "":
			push_error("Tokyo Ghoul form attack has no presentation profile: %s" % card_id)
			quit(1)
			return false
	return true


func _create_attack_state(card_id: String, keywords: Array[String]) -> CardState:
	var data := CardData.new()
	data.id = card_id
	data.type = CardData.TYPE_MINION
	data.faction_id = "tokyo_ghoul"
	data.attack = 1
	data.health = 1
	data.keywords = keywords
	var state := CardState.new()
	state.set_card_data(data)
	state.set_face_up(true)
	return state


func _test_implicit_transform_animation_target() -> bool:
	var game_manager := GameManager.new()
	var player := PlayerState.new()
	player.id = "tokyo_player"
	var kaneki := _create_attack_state("kaneki_ken", [CardData.KEYWORD_KAGUNE_BIKAKU])
	kaneki.owner_id = player.id
	kaneki.slot_index = 0
	game_manager.board_states = [kaneki]

	var resolved_spell := {
		"effects": [{
			"id": EffectData.EFFECT_TRANSFORM_UNIT,
			"target": EffectData.TARGET_OWNER_CARD_BY_ID,
			"target_card_id": "kaneki_ken",
			"presentation_target": EffectData.PRESENTATION_TARGET_EFFECT_TARGET,
		}]
	}
	var animation_target := HandPlayResolver.new().resolve_implicit_animation_target(
		resolved_spell,
		player,
		game_manager
	)
	if animation_target != kaneki:
		push_error("owner-card transform did not resolve Kaneki as its animation target")
		game_manager.audio_manager.free()
		game_manager.free()
		quit(1)
		return false
	var unmarked_spell := resolved_spell.duplicate(true)
	var unmarked_effect := (unmarked_spell["effects"] as Array)[0] as Dictionary
	unmarked_effect.erase("presentation_target")
	if HandPlayResolver.new().resolve_implicit_animation_target(unmarked_spell, player, game_manager) != null:
		push_error("unmarked owner-card spell unexpectedly changed its animation target")
		game_manager.audio_manager.free()
		game_manager.free()
		quit(1)
		return false

	game_manager.audio_manager.free()
	game_manager.free()
	return true


func _test_animation_config_contract() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if not parsed is Array:
		push_error("cards.json did not parse for Tokyo Ghoul animation coverage")
		quit(1)
		return false
	for faction_entry in parsed:
		if not faction_entry is Dictionary or str(faction_entry.get("id", "")) != "tokyo_ghoul":
			continue
		var cards_by_id: Dictionary = {}
		for collection_key in ["cards", "tokens"]:
			for card_entry in faction_entry.get(collection_key, []):
				if card_entry is Dictionary:
					cards_by_id[str(card_entry.get("id", ""))] = card_entry
		var cafe: Dictionary = cards_by_id.get("thirteenth_district_cafe", {})
		var cafe_actions: Array = cafe.get("actions", [])
		if cafe_actions.is_empty() or str((cafe_actions[0] as Dictionary).get("animation", "")) != "special_blend":
			push_error("13th District Cafe is missing the special_blend animation")
			quit(1)
			return false
		var coffee: Dictionary = cards_by_id.get("sugar_cube_coffee", {})
		if str(coffee.get("animation", "")) != "sugar_cube_coffee":
			push_error("Sugar cube coffee is missing its Tokyo Ghoul animation")
			quit(1)
			return false
		for spell_id in ["bikaku_volley", "centipede_form", "dragon_form", "saint_sword_form"]:
			var spell: Dictionary = cards_by_id.get(spell_id, {})
			var effects: Array = spell.get("effects", [])
			if effects.is_empty() or str((effects[0] as Dictionary).get("presentation_target", "")) != EffectData.PRESENTATION_TARGET_EFFECT_TARGET:
				push_error("Tokyo Ghoul self spell is missing its explicit presentation target: %s" % spell_id)
				quit(1)
				return false
		for reserve_id in ["s_rank_ghoul_intelligence", "sss_rank_ghoul_intelligence"]:
			var reserve_card: Dictionary = cards_by_id.get(reserve_id, {})
			var reserve_effects: Array = reserve_card.get("effects", [])
			if reserve_effects.is_empty() or str((reserve_effects[0] as Dictionary).get("animation", "")) == "":
				push_error("Tokyo Ghoul reserve is missing its restock animation: %s" % reserve_id)
				quit(1)
				return false
		return true
	push_error("Tokyo Ghoul faction is missing from cards.json")
	quit(1)
	return false


func _assert_no_children(effect_root: Control, animation_key: String) -> bool:
	if effect_root.get_child_count() == 0:
		return true
	push_error(
		"Tokyo Ghoul animation leaked nodes after %s: %d"
		% [animation_key, effect_root.get_child_count()]
	)
	quit(1)
	return false
