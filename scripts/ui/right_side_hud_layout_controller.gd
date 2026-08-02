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
	var panel_width := RightSideHudStyleScript.get_panel_width(viewport_size.x)
	var visible_panels: Array[Control] = []
	for panel_entry in panels:
		var panel := panel_entry as Control
		if panel == null or not panel.visible:
			continue
		normalize_panel(panel, panel_width)
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
	stretch_panels_to_available_height(visible_panels, available_height, effective_gap)

	var x_position := maxf(
		effective_margin,
		viewport_size.x - panel_width - effective_margin
	)
	var next_y := effective_margin
	for panel in visible_panels:
		panel.position = Vector2(x_position, next_y)
		next_y += panel.size.y + effective_gap


func normalize_panel(panel: Control, panel_width: float) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.custom_minimum_size.x = panel_width

	var minimum_size := panel.get_combined_minimum_size()
	panel.size = Vector2(
		panel_width,
		maxf(panel.custom_minimum_size.y, minimum_size.y)
	)


func stretch_panels_to_available_height(
	panels: Array[Control],
	available_height: float,
	gap: float
) -> void:
	if panels.is_empty():
		return

	var gap_height := gap * float(maxi(panels.size() - 1, 0))
	var free_height := available_height - gap_height - get_total_panel_height(panels)
	if free_height <= 0.0:
		return

	# Three or more panels form the full HUD rail and share all remaining height.
	# Sparse factions keep a bounded amount of breathing room instead of creating
	# two oversized empty panels.
	var stretch_budget := free_height
	if panels.size() < 3:
		stretch_budget = minf(stretch_budget, 96.0 * float(panels.size()))

	var total_weight := 0.0
	for panel in panels:
		total_weight += get_panel_stretch_weight(panel)
	if total_weight <= 0.0:
		return

	var pixel_budget := maxi(floori(stretch_budget), 0)
	var allocated_pixels := 0
	for panel_index in range(panels.size()):
		var panel := panels[panel_index]
		var extra_pixels := pixel_budget - allocated_pixels
		if panel_index < panels.size() - 1:
			extra_pixels = floori(
				float(pixel_budget) * get_panel_stretch_weight(panel) / total_weight
			)
		panel.size.y += float(extra_pixels)
		allocated_pixels += extra_pixels


func get_panel_stretch_weight(panel: Control) -> float:
	match panel.name:
		"TurnStatusPanel":
			return 1.10
		"FactionSkillPanel":
			return 1.15
		"EquipmentDisplayPanel":
			return 1.05
		_:
			return 1.0


func get_total_panel_height(panels: Array[Control]) -> float:
	var total := 0.0
	for panel in panels:
		total += panel.size.y
	return total
