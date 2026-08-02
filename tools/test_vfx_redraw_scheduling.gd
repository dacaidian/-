extends SceneTree

const ThrottledProgressVisualScript := preload("res://scripts/ui/animation/throttled_progress_visual.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var visual := ThrottledProgressVisualScript.new() as Control
	visual.name = "ThrottledProgressProbe"
	visual.size = Vector2(640.0, 360.0)
	var draw_counter := {"count": 0}
	visual.draw.connect(func(): draw_counter["count"] = int(draw_counter["count"]) + 1)
	root.add_child(visual)
	await process_frame

	draw_counter["count"] = 0
	for progress_index in range(1, 100):
		visual.set("progress", float(progress_index) / 100.0)
	await process_frame
	if int(draw_counter["count"]) > 1:
		return _fail("Progress burst was not coalesced into one Canvas redraw")

	var before_final := int(draw_counter["count"])
	visual.set("progress", 1.0)
	await process_frame
	if int(draw_counter["count"]) <= before_final:
		return _fail("Final progress did not force a completion redraw")

	visual.queue_free()
	await process_frame
	if root.get_child_count() != 0:
		return _fail("Throttled progress visual leaked nodes")
	print("VFX_REDRAW_SCHEDULING_TESTS_OK")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
