extends SceneTree

const CardAnimationControllerScript := preload("res://scripts/ui/card_animation_controller.gd")

var failed := false


func _initialize() -> void:
	var controller := CardAnimationControllerScript.new()
	controller.setup({})
	var router: SpellAnimationRouter = controller.spell_animation_router

	_assert_routes(router, "targeted", [
		"fiery_eyes_golden_gaze", "beastmen_evolution", "gu_infusion",
		"sacrifice", "fel_infusion", "feather_needle"
	])
	_assert_routes(router, "rect", [
		"somersault_cloud", "wild_call", "gu_summon", "charm",
		"dark_portal", "centipede_form"
	])
	_assert_routes(router, "source_rect", [
		"body_beyond_body", "wanmo_ritual", "medical_practice",
		"soul_hook", "life_drain"
	])
	_assert_routes(router, "board", ["chaos_corruption_burst", "kagune_release"])
	_assert_routes(router, "path", ["beast_path"])
	_assert_routes(router, "area", ["foxfire"])

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
			"board":
				registered = router.has_board_route(animation_key)
			"path":
				registered = router.has_path_route(animation_key)
			"area":
				registered = router.has_area_route(animation_key)
		if not registered:
			push_error("%s route missing for %s" % [context, animation_key])
			failed = true
