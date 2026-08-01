extends SceneTree

const CardAnimationControllerScript := preload("res://scripts/ui/card_animation_controller.gd")

const SHADOWMOON_TARGET_KEYS: Array[String] = [
	"fel_sacrifice", "fel_sacrifice_heavy", "fel_infusion", "fel_infusion_transfer",
	"fel_infusion_settle", "fel_overload", "fel_overload_transfer", "fel_overload_settle",
	"fel_overload_detonate", "fel_burst", "fel_burst_impact", "mana_burn", "fel_bite",
	"life_drain", "life_drain_receive", "curse", "curse_cast", "curse_mark",
	"curse_impact", "fel_madness", "fel_madness_chaos_orc",
	"fel_madness_hellhound", "fel_madness_succubus", "fel_madness_wolf_rider",
	"fel_madness_doomguard", "fel_madness_warlock", "kiljaeden_whisper",
	"kiljaeden_whisper_mark", "immolation_mark", "immolation_tick", "fire",
	"demon_summon", "dark_portal", "immolation", "immolation_cast",
]
const SHADOWMOON_MULTI_KEYS: Array[String] = [
	"fel_madness", "fel_madness_chaos_orc", "fel_madness_hellhound",
	"fel_madness_succubus", "fel_madness_wolf_rider", "fel_madness_doomguard",
	"fel_madness_warlock", "kiljaeden_whisper", "kiljaeden_whisper_mark",
	"immolation_mark", "fel_burst_impact",
]

class RouteProbe:
	extends RefCounted

	var calls: Array[String] = []

	func play_first(_owner: Node, _effect_root: Control, _key: String) -> void:
		calls.append("first")

	func play_second(_owner: Node, _effect_root: Control, _key: String) -> void:
		calls.append("second")


var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller := CardAnimationControllerScript.new()
	controller.setup({})
	var router: SpellAnimationRouter = controller.spell_animation_router

	_assert_routes(router, "targeted", [
		"fiery_eyes_golden_gaze", "immortal_peach", "drive_spirit",
		"drive_spirit_battlefield", "bronze_head_iron_arms_reflect",
		"dragon_palace_treasure", "hair_clone_enter", "monkey_hair_clone_assist",
		"beastmen_evolution", "beastmen_slaughter", "wanmo_charge",
		"savage_roar", "savage_roar_buff", "wild_call", "beast_path", "wanmo_ritual",
		"gu_infusion",
		"sacrifice", "nine_tail_sacrifice", "fox_reborn", "soul_hook", "charm", "fox_mind_art",
		"nine_tail_tail_enter", "fel_infusion", "feather_needle", "cone_of_cold",
		"centipede_form", "dragon_form", "saint_sword_form",
		"rc_forced_feeding", "bikaku_volley", "free_meal", "kakuja_form",
		"restore_form", "special_blend", "sugar_cube_coffee",
		"kagune_lifesteal", "koukaku_reflect",
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
		"somersault_cloud", "body_beyond_body", "bronze_head_iron_arms",
		"immobilize", "gather_scatter_qi", "heavenly_form",
		"dragon_palace_treasure", "beastmen_evolution", "beastmen_slaughter",
		"wanmo_charge", "savage_roar", "savage_roar_buff", "wild_call",
		"beast_path", "wanmo_ritual", "gu_summon", "charm",
		"sacrifice", "nine_tail_sacrifice", "fox_reborn", "soul_hook", "fox_mind_art",
		"nine_tail_tail_enter", "ruin_country",
		"dark_portal", "centipede_form", "dragon_form", "saint_sword_form",
		"bikaku_volley", "extreme_cold_storm_cast",
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
		"body_beyond_body", "monkey_somersault_move", "monkey_westward_move",
		"monkey_hair_clone_assist", "bronze_head_iron_arms_reflect",
		"beastmen_evolution", "beastmen_slaughter", "wanmo_charge",
		"savage_roar", "savage_roar_buff", "wild_call", "beast_path",
		"wanmo_ritual", "medical_practice",
		"sacrifice", "nine_tail_sacrifice", "fox_reborn", "soul_hook", "charm", "fox_mind_art",
		"nine_tail_tail_enter", "life_drain", "divine_shield", "baptism",
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
		"thin_burial_release", "thin_burial_break", "meteor_strike",
		"celestial_fox_evolve", "ruin_country_targets"
	])
	_assert_routes(router, "source_rect", [
		"centipede_form", "dragon_form", "saint_sword_form",
		"tokyo_bikaku_attack", "tokyo_rinkaku_attack", "tokyo_koukaku_attack",
		"tokyo_ukaku_attack", "tokyo_chimera_attack", "tokyo_centipede_attack",
		"tokyo_dragon_attack", "tokyo_saint_sword_attack", "tokyo_owl_attack",
		"tokyo_furuta_attack", "kagune_lifesteal", "koukaku_reflect"
	])
	_assert_routes(router, "board", [
		"fiery_eyes_golden_gaze", "drive_spirit_battlefield",
		"chaos_corruption_burst",
		"kagune_release",
		"rc_rise_medium", "rc_rise_high", "rc_fall_medium", "rc_fall_low",
		"s_rank_intelligence", "sss_rank_intelligence",
		"night_elf_time_transition",
		"night_elf_time_transition_sunrise",
		"night_elf_time_transition_noon",
		"night_elf_time_transition_dusk",
		"night_elf_time_transition_moonrise",
		"night_elf_time_transition_full_moon",
		"night_elf_time_transition_moonset", "nine_tail_army"
	])
	_assert_routes(router, "path", ["beast_path"])
	_assert_routes(router, "area", ["foxfire", "blizzard"])
	_assert_routes(router, "targeted", SHADOWMOON_TARGET_KEYS)
	_assert_routes(router, "rect", SHADOWMOON_TARGET_KEYS)
	_assert_routes(router, "source_rect", SHADOWMOON_TARGET_KEYS)
	_assert_routes(router, "multi_rect", SHADOWMOON_MULTI_KEYS)
	_assert_routes(router, "board", ["fel_madness_broadcast"])

	var collision_router := SpellAnimationRouter.new()
	var route_probe := RouteProbe.new()
	collision_router.register_board(
		["collision_test"],
		Callable(route_probe, "play_first")
	)
	collision_router.register_board(
		["collision_test"],
		Callable(route_probe, "play_second")
	)
	var route_context := Control.new()
	root.add_child(route_context)
	var collision_played := await collision_router.try_play_board(
		"collision_test",
		route_context,
		route_context
	)
	route_context.queue_free()
	if not collision_played or route_probe.calls != ["first"]:
		push_error(
			"duplicate animation route replaced its original handler: %s"
			% [route_probe.calls]
		)
		failed = true

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
