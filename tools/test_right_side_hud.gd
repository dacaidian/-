extends SceneTree

const EquipmentDisplayControllerScript := preload("res://scripts/ui/equipment_display_controller.gd")
const FactionSkillPanelControllerScript := preload("res://scripts/ui/faction_skill_panel_controller.gd")
const FactionTimePanelControllerScript := preload("res://scripts/ui/faction_time_panel_controller.gd")
const RightSideHudLayoutControllerScript := preload("res://scripts/ui/right_side_hud_layout_controller.gd")
const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")
const TailResourceMeterScript := preload("res://scripts/ui/tail_resource_meter.gd")
const TurnStatusControllerScript := preload("res://scripts/ui/turn_status_controller.gd")


func _init() -> void:
	run.call_deferred()
	var watchdog := create_timer(10.0)
	watchdog.timeout.connect(_on_watchdog_timeout)


func _on_watchdog_timeout() -> void:
	push_error("Right-side HUD test did not finish before the watchdog timeout.")
	quit(1)


func run() -> void:
	var scene := Control.new()
	scene.name = "RightHudTestRoot"
	scene.size = Vector2(1280.0, 720.0)
	root.add_child(scene)

	var turn_panel := PanelContainer.new()
	turn_panel.name = "TurnPanel"
	scene.add_child(turn_panel)

	var player := create_player()
	var turn_controller := TurnStatusControllerScript.new()
	turn_controller.setup(scene, NodePath("TurnPanel"))
	turn_controller.update(player, 7, false, 3, true, 80)

	var time_controller := FactionTimePanelControllerScript.new()
	time_controller.setup(scene)
	var skill_controller := FactionSkillPanelControllerScript.new()
	skill_controller.setup(scene)
	var equipment_controller := EquipmentDisplayControllerScript.new()
	equipment_controller.setup(scene)
	await process_frame

	time_controller.update(player, CardDatabase.new(), scene)
	skill_controller.update(player, scene, ["sacrifice"])
	equipment_controller.update(player)
	await process_frame
	await process_frame

	var panels: Array = [
		turn_controller.panel,
		time_controller.panel,
		skill_controller.panel,
		equipment_controller.panel,
	]
	var layout_controller := RightSideHudLayoutControllerScript.new()
	layout_controller.layout_for_viewport(panels, Vector2(1280.0, 720.0))

	assert(turn_controller.mana_label.text == "3/5")
	assert(turn_controller.flip_label.text == "2/4")
	assert(turn_controller.resource_label.text == "34/80")
	assert(turn_controller.panel.find_child("MetricRow", true, false) != null)

	var tail_meter := skill_controller.panel.find_child("TailResourceMeter", true, false) as TailResourceMeter
	assert(tail_meter != null)
	assert(tail_meter.current_value == 5)
	assert(tail_meter.maximum_value == 9)
	assert(skill_controller.panel.find_child("TailStageLabel", true, false).text == "三尾 · 远程")

	player.gain_faction_resource("tail", 1)
	skill_controller.update(player, scene, ["sacrifice"])
	await process_frame
	tail_meter = skill_controller.panel.find_child("TailResourceMeter", true, false) as TailResourceMeter
	assert(tail_meter != null)
	assert(tail_meter.previous_value == 5)
	assert(tail_meter.current_value == 6)
	assert(skill_controller.panel.find_child("TailStageLabel", true, false).text == "六尾 · 免疫")

	var previous_bottom := 0.0
	var expected_x := -1.0
	for panel_entry in panels:
		var panel := panel_entry as Control
		assert(panel != null and panel.visible)
		assert(is_equal_approx(panel.size.x, RightSideHudStyleScript.PANEL_WIDTH))
		if expected_x < 0.0:
			expected_x = panel.position.x
		else:
			assert(is_equal_approx(panel.position.x, expected_x))
		assert(panel.position.y >= previous_bottom - 0.01)
		previous_bottom = panel.position.y + panel.size.y

	assert(
		previous_bottom <= 720.0 - RightSideHudStyleScript.PANEL_MARGIN + 0.01,
		"right-side HUD bottom %.2f exceeds the 720p safe area" % previous_bottom
	)
	assert(equipment_controller.panel.size.y < 166.0)

	print("RIGHT_SIDE_HUD_TESTS_OK")
	scene.queue_free()
	await process_frame
	quit()


func create_player() -> PlayerState:
	var player := PlayerState.new()
	player.setup("hud_player", "玩家一")
	player.set_faction("fox_spirit", "狐妖仙")
	player.mana = 3
	player.max_mana = 5
	player.remaining_flips = 2
	player.max_flips_per_turn = 4
	player.resource_score = 34
	player.setup_faction_resources([
		{
			"id": "tail",
			"name": "尾",
			"initial": 5,
			"max": 9,
		},
	])
	player.setup_faction_skills([
		{
			"id": "sacrifice",
			"name": "献祭",
			"description": "献祭一个友方非英雄随从。",
			"once_per_turn": true,
		},
	])
	player.set_unlocked_faction_skills(["sacrifice"])
	player.setup_faction_runtime_state({
		"id": "time",
		"name": "时间",
		"default_state_id": "full_moon",
		"panel_hint": "回合结束后推进",
		"cycle": [
			{
				"id": "full_moon",
				"name": "满月",
				"card_id": "",
			},
		],
	})

	var equipment := CardData.new()
	equipment.id = "hud_test_weapon"
	equipment.display_name = "测试武器"
	equipment.type = CardData.TYPE_EQUIPMENT
	equipment.equipment_type = "weapon"
	player.equip_card(equipment)
	return player
