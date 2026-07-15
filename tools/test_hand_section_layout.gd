extends SceneTree

const HandSectionLayoutPolicyScript := preload("res://scripts/ui/hand_section_layout_policy.gd")
const TYPES: Array[String] = ["spell", "minion", "upgrade", "equipment"]


func _init() -> void:
	test_empty_sections_collapse()
	test_crowded_section_receives_more_space()
	test_constrained_layout_stays_within_budget()
	print("HAND_SECTION_LAYOUT_TESTS_OK")
	quit()


func test_empty_sections_collapse() -> void:
	var policy := HandSectionLayoutPolicyScript.new()
	var result := policy.allocate(TYPES, {}, 900.0, 10.0, 3)
	for card_type in TYPES:
		assert(is_equal_approx(float(result[card_type]), policy.EMPTY_SECTION_HEIGHT))


func test_crowded_section_receives_more_space() -> void:
	var policy := HandSectionLayoutPolicyScript.new()
	var result := policy.allocate(
		TYPES,
		{"spell": 3, "minion": 0, "upgrade": 9, "equipment": 0},
		900.0,
		10.0,
		3
	)
	assert(float(result["spell"]) > policy.ACTIVE_SECTION_MIN_HEIGHT)
	assert(float(result["upgrade"]) > float(result["spell"]))
	assert(is_equal_approx(float(result["minion"]), policy.EMPTY_SECTION_HEIGHT))
	assert(is_equal_approx(float(result["equipment"]), policy.EMPTY_SECTION_HEIGHT))


func test_constrained_layout_stays_within_budget() -> void:
	var policy := HandSectionLayoutPolicyScript.new()
	var available_height := 390.0
	var separation := 10.0
	var result := policy.allocate(
		TYPES,
		{"spell": 5, "minion": 2, "upgrade": 7, "equipment": 1},
		available_height,
		separation,
		3
	)
	var used_height := separation * float(TYPES.size() - 1)
	for card_type in TYPES:
		assert(float(result[card_type]) >= 0.0)
		used_height += float(result[card_type])
	assert(used_height <= available_height + 0.01)
