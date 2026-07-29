extends SceneTree

const CardAnimationControllerScript := preload("res://scripts/ui/card_animation_controller.gd")

var failed := false


func _initialize() -> void:
	var controller := CardAnimationControllerScript.new()
	controller.setup({})
	var router: SpellAnimationRouter = controller.spell_animation_router

	_assert_routes(router, "targeted", [
		"fiery_eyes_golden_gaze", "beastmen_evolution", "gu_infusion",
		"sacrifice", "fel_infusion", "feather_needle", "cone_of_cold",
		"extreme_cold_storm", "extreme_cold_storm_pulse",
		"extreme_cold_storm_summon", "divine_shield", "baptism",
		"holy_heal", "power_word_shield", "inner_fire", "fireball",
		"pyroblast", "frost_shield", "arcane_wisdom", "arcane_space",
		"arcane_aura", "arcane_aura_pulse", "healing_to_resolve",
		"gu_herb_poison", "gu_scorpion_breeding", "gu_life_link_death",
		"thin_burial_release", "thin_burial_break", "gu_snake_venom_apply",
		"gu_devour", "gu_venom_inject", "gu_venom_burst",
		"gu_scorpion_venom_apply", "gu_king_venom_apply",
		"gu_poison_tick_scorpion", "gu_poison_tick_snake",
		"gu_poison_tick_king", "gu_poison_burst",
		"moonblade", "tranquil_spring", "precision_shot", "full_moon_cover",
		"meteor_aura", "meteor_strike", "claw_strike", "elune_grace"
	])
	_assert_routes(router, "rect", [
		"somersault_cloud", "wild_call", "gu_summon", "charm",
		"dark_portal", "centipede_form", "extreme_cold_storm_cast",
		"divine_shield", "baptism", "holy_heal", "power_word_shield",
		"inner_fire", "healing_to_resolve", "faith_light", "resurrection", "water_summon",
		"giant_water_summon", "academy_summon", "arcane_aura_prepare",
		"arcane_aura", "arcane_aura_pulse", "frost_shield",
		"arcane_wisdom", "arcane_space", "gu_herb_poison",
		"gu_scorpion_breeding", "gu_life_link_death",
		"thin_burial_release", "thin_burial_break", "gu_snake_venom_apply",
		"gu_devour", "gu_venom_inject", "gu_venom_burst",
		"gu_scorpion_venom_apply", "gu_king_venom_apply",
		"gu_poison_tick_scorpion", "gu_poison_tick_snake",
		"gu_poison_tick_king", "gu_poison_burst",
		"moonblade", "tranquil_spring", "precision_shot", "full_moon_cover",
		"meteor_aura", "meteor_strike", "claw_strike", "elune_grace"
	])
	_assert_routes(router, "source_rect", [
		"body_beyond_body", "wanmo_ritual", "medical_practice",
		"soul_hook", "life_drain", "divine_shield", "baptism",
		"holy_heal", "power_word_shield", "inner_fire", "healing_to_resolve", "fireball",
		"pyroblast", "frost_shield", "gu_herb_poison",
		"gu_scorpion_breeding", "gu_life_link_death",
		"thin_burial_release", "thin_burial_break", "gu_snake_venom_apply",
		"gu_devour", "gu_venom_inject", "gu_venom_burst",
		"gu_scorpion_venom_apply", "gu_king_venom_apply",
		"gu_poison_tick_scorpion", "gu_poison_tick_snake",
		"gu_poison_tick_king", "gu_poison_burst",
		"moonblade", "tranquil_spring", "precision_shot", "full_moon_cover",
		"meteor_aura", "meteor_strike", "claw_strike"
	])
	_assert_routes(router, "multi_rect", [
		"faith_light", "gu_venom_burst", "gu_poison_tick_scorpion",
		"gu_poison_tick_snake", "gu_poison_tick_king", "gu_poison_burst",
		"thin_burial_release", "thin_burial_break", "meteor_strike"
	])
	_assert_routes(router, "board", [
		"chaos_corruption_burst",
		"kagune_release",
		"night_elf_time_transition",
		"night_elf_time_transition_sunrise",
		"night_elf_time_transition_noon",
		"night_elf_time_transition_dusk",
		"night_elf_time_transition_moonrise",
		"night_elf_time_transition_full_moon",
		"night_elf_time_transition_moonset"
	])
	_assert_routes(router, "path", ["beast_path"])
	_assert_routes(router, "area", ["foxfire", "blizzard"])

	if router.has_targeted_route("missing_animation_key"):
		push_error("unknown animation key unexpectedly has a route")
		failed = true
	if failed:
		quit(1)
		return
	print("OK: animation provider routes are registered")
	quit()


func _assert_routes(router: SpellAnimationRouter, context: String, animation_keys: Array[String]) -> void:
	for animation_key in animation_keys:
		var registered := false
		match context:
			"targeted":
				registered = router.has_targeted_route(animation_key)
			"rect":
				registered = router.has_rect_route(animation_key)
			"source_rect":
				registered = router.has_source_rect_route(animation_key)
			"multi_rect":
				registered = router.has_multi_rect_route(animation_key)
			"board":
				registered = router.has_board_route(animation_key)
			"path":
				registered = router.has_path_route(animation_key)
			"area":
				registered = router.has_area_route(animation_key)
		if not registered:
			push_error("%s route missing for %s" % [context, animation_key])
			failed = true
