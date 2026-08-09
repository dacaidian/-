extends SceneTree

const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")


class GeometryProbe:
	extends Control

	var paths: Array[PackedVector2Array] = []

	func _draw() -> void:
		for path_index in range(paths.size()):
			Toolkit.draw_ribbon(
				self,
				paths[path_index],
				2.4 + float(path_index % 3),
				Color(0.54, 0.92, 0.24, 0.72),
				Color(0.05, 0.01, 0.08, 0.52),
				Color(0.94, 1.0, 0.62, 0.18),
				8.0,
				true,
				true,
				float(path_index) * 0.37
			)
		var ellipse_cases: Array[Dictionary] = [
			{"center": Vector2(300.0, 300.0), "radii": Vector2.ZERO, "rotation": 0.0},
			{"center": Vector2(330.0, 300.0), "radii": Vector2(0.001, 0.001), "rotation": 0.0},
			{"center": Vector2(370.0, 300.0), "radii": Vector2(0.11, 0.11), "rotation": 0.31},
			{"center": Vector2(430.0, 300.0), "radii": Vector2(52.0, 0.11), "rotation": 0.78},
			{"center": Vector2(520.0, 310.0), "radii": Vector2(58.0, 24.0), "rotation": 1.17},
		]
		for ellipse_case in ellipse_cases:
			Toolkit.draw_soft_ellipse(
				self,
				Vector2(ellipse_case["center"]),
				Vector2(ellipse_case["radii"]),
				Color(0.48, 0.06, 0.12, 0.72),
				Color(0.03, 0.01, 0.04, 0.64),
				6,
				float(ellipse_case["rotation"])
			)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var probe := GeometryProbe.new()
	probe.name = "CanvasGeometryProbe"
	probe.size = Vector2(640.0, 420.0)
	probe.paths = [
		PackedVector2Array([Vector2(30.0, 30.0), Vector2(30.0, 30.0), Vector2(30.0, 30.0)]),
		PackedVector2Array([Vector2(50.0, 50.0), Vector2(50.001, 50.0), Vector2(50.002, 50.001)]),
		PackedVector2Array([Vector2(80.0, 80.0), Vector2(180.0, 80.0)]),
		PackedVector2Array([Vector2(80.0, 130.0), Vector2(190.0, 130.0), Vector2(115.0, 130.0), Vector2(230.0, 130.0)]),
		PackedVector2Array([Vector2(80.0, 190.0), Vector2(190.0, 190.0), Vector2(192.0, 280.0)]),
		PackedVector2Array([Vector2(310.0, 80.0), Vector2(470.0, 80.0), Vector2(470.0, 220.0), Vector2(310.0, 220.0), Vector2(310.0, 80.0)]),
	]
	root.add_child(probe)
	await process_frame
	probe.queue_redraw()
	await process_frame
	probe.queue_free()
	await process_frame
	if root.get_child_count() != 0:
		push_error("Canvas geometry probe leaked nodes")
		quit(1)
		return
	print("VFX_CANVAS_TOOLKIT_TESTS_OK")
	quit()
