extends RefCounted
class_name RightSideHudLayoutController

const DEFAULT_MARGIN := 16.0
const DEFAULT_GAP := 12.0

# RightSideHudLayoutController only arranges already-created HUD panels.
# It does not decide visibility or mutate gameplay state.


func update(root: Control, panels: Array, margin := DEFAULT_MARGIN, gap := DEFAULT_GAP) -> void:
	if root == null:
		return

	var viewport := root.get_viewport()
	if viewport == null:
		return

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var next_y := margin
	for panel in panels:
		next_y = layout_panel(panel as Control, viewport_size, next_y, margin, gap)


func layout_panel(panel: Control, viewport_size: Vector2, y_position: float, margin: float, gap: float) -> float:
	if panel == null or not panel.visible:
		return y_position

	var panel_size := panel.size
	var minimum_size := panel.get_combined_minimum_size()
	if panel_size.x <= 0.0:
		panel_size.x = minimum_size.x
	if panel_size.y <= 0.0:
		panel_size.y = minimum_size.y

	panel.position = Vector2(
		maxf(margin, viewport_size.x - panel_size.x - margin),
		clampf(y_position, margin, maxf(margin, viewport_size.y - panel_size.y - margin))
	)
	return panel.position.y + panel_size.y + gap
