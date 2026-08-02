extends Control
class_name ThrottledProgressVisual

# Complex procedural VFX still follow the tween every frame, but rebuilding all
# Canvas draw commands at display refresh rate is unnecessary for card-scale
# presentation. This base batches progress changes into a bounded redraw rate.

const DEFAULT_REDRAW_FPS := 24.0

var progress := 0.0:
	set(value):
		var next_progress := clampf(value, 0.0, 1.0)
		if is_equal_approx(progress, next_progress):
			return
		progress = next_progress
		request_visual_redraw(progress <= 0.001 or progress >= 0.999)

var visual_redraw_fps := DEFAULT_REDRAW_FPS
var _visual_redraw_pending := false
var _last_visual_redraw_usec := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	request_visual_redraw(true)


func _process(_delta: float) -> void:
	if not _visual_redraw_pending:
		set_process(false)
		return
	_flush_visual_redraw_if_due(false)


func set_visual_redraw_fps(frames_per_second: float) -> void:
	visual_redraw_fps = maxf(frames_per_second, 1.0)


func request_visual_redraw(immediate := false) -> void:
	_visual_redraw_pending = true
	if not is_inside_tree():
		return
	if not _flush_visual_redraw_if_due(immediate):
		set_process(true)


func _flush_visual_redraw_if_due(immediate: bool) -> bool:
	var now_usec := Time.get_ticks_usec()
	var interval_usec := maxi(int(round(1000000.0 / visual_redraw_fps)), 1)
	if (
		not immediate
		and _last_visual_redraw_usec > 0
		and now_usec - _last_visual_redraw_usec < interval_usec
	):
		return false
	_last_visual_redraw_usec = now_usec
	_visual_redraw_pending = false
	queue_redraw()
	set_process(false)
	return true
