extends RefCounted
class_name RightSideHudLayoutController

const RightSideHudStyleScript := preload("res://scripts/ui/right_side_hud_style.gd")

# RightSideHudLayoutController only arranges already-created HUD panels.
# It does not decide visibility or mutate gameplay state.


func update(
	root: Control,
	panels: Array,
	margin := RightSideHudStyleScript.PANEL_MARGIN,
	gap := RightSideHudStyleScript.PANEL_GAP
) -> void:
	if root == null:
		return

	var viewport := root.get_viewport()
	if viewport == null:
		return

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	layout_for_viewport(panels, viewport_size, margin, gap)


func layout_for_viewport(
	panels: Array,
	viewport_size: Vector2,
	margin := RightSideHudStyleScript.PANEL_MARGIN,
	gap := RightSideHudStyleScript.PANEL_GAP
) -> void:
	var visible_panels: Array[Control] = []
	for panel_entry in panels:
		var panel := panel_entry as Control
		if panel == null or not panel.visible:
			continue
		normalize_panel(panel)
		visible_panels.append(panel)

	if visible_panels.is_empty():
		return

	var effective_margin := minf(margin, maxf(4.0, viewport_size.y * 0.025))
	var effective_gap := gap
	var total_panel_height := get_total_panel_height(visible_panels)
	var available_height := maxf(0.0, viewport_size.y - effective_margin * 2.0)
	if visible_panels.size() > 1 and total_panel_height + effective_gap * float(visible_panels.size() - 1) > available_height:
		effective_gap = maxf(
			4.0,
			(available_height - total_panel_height) / float(visible_panels.size() - 1)
		)

	var x_position := maxf(
		effective_margin,
		viewport_size.x - RightSideHudStyleScript.PANEL_WIDTH - effective_margin
	)
	var next_y := effective_margin
	for panel in visible_panels:
		panel.position = Vector2(x_position, next_y)
		next_y += panel.size.y + effective_gap


func normalize_panel(panel: Control) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.custom_minimum_size.x = RightSideHudStyleScript.PANEL_WIDTH

	var minimum_size := panel.get_combined_minimum_size()
	panel.size = Vector2(
		RightSideHudStyleScript.PANEL_WIDTH,
		maxf(panel.custom_minimum_size.y, minimum_size.y)
	)


func get_total_panel_height(panels: Array[Control]) -> float:
	var total := 0.0
	for panel in panels:
		total += panel.size.y
	return total
