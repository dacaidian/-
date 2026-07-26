extends Control
class_name BoardPersistentVisualController

const ExtremeColdStormAreaVisualScript := preload(
	"res://scripts/ui/persistent_visuals/extreme_cold_storm_area_visual.gd"
)

# Owns long-lived visuals that cover board areas and follow a runtime source.
# CardStatus payloads declare visuals; registered renderer scripts decide how
# they look. Rules never create or move visual nodes directly.

var game_manager: Node
var visual_factories: Dictionary = {}
var active_visuals: Dictionary = {}


func _init() -> void:
	register_visual(ExtremeColdStormAreaVisualScript.VISUAL_KEY, ExtremeColdStormAreaVisualScript)


func setup(new_game_manager: Node, visual_root: Control) -> void:
	game_manager = new_game_manager
	name = "BoardPersistentVisualController"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 20

	if visual_root != null and get_parent() != visual_root:
		if get_parent() != null:
			reparent(visual_root)
		else:
			visual_root.add_child(self)

	refresh_sources()


func register_visual(visual_key: String, visual_script: Script) -> void:
	if visual_key == "" or visual_script == null:
		return
	visual_factories[visual_key] = visual_script


func has_registered_visual(visual_key: String) -> bool:
	return visual_factories.has(visual_key)


func get_active_visual_count() -> int:
	return active_visuals.size()


func refresh_sources() -> void:
	if game_manager == null or not game_manager.has_method("get_all_board_states"):
		clear_visuals()
		return

	var desired_keys: Dictionary = {}
	for source_state_value in game_manager.call("get_all_board_states"):
		var source_state := source_state_value as CardState
		if source_state == null or source_state.is_empty() or not source_state.is_face_up:
			continue

		for status in source_state.statuses:
			if status == null:
				continue
			var descriptors := EffectData.get_status_persistent_visuals(status)
			for descriptor_index in range(descriptors.size()):
				var descriptor := descriptors[descriptor_index]
				var visual_key := str(descriptor.get(EffectData.KEY_VISUAL_KEY, ""))
				if not visual_factories.has(visual_key):
					continue

				var instance_key := "%d:%d:%d" % [
					source_state.get_instance_id(),
					status.get_instance_id(),
					descriptor_index
				]
				desired_keys[instance_key] = true
				var visual := active_visuals.get(instance_key) as PersistentBoardAreaVisual
				if visual == null:
					visual = create_visual(visual_key)
					if visual == null:
						continue
					active_visuals[instance_key] = visual
					add_child(visual)
				visual.configure(game_manager, source_state, status, descriptor)

	for instance_key in active_visuals.keys():
		if desired_keys.has(instance_key):
			continue
		var stale_visual := active_visuals.get(instance_key) as PersistentBoardAreaVisual
		active_visuals.erase(instance_key)
		if stale_visual != null and is_instance_valid(stale_visual):
			stale_visual.queue_free()


func create_visual(visual_key: String) -> PersistentBoardAreaVisual:
	var visual_script := visual_factories.get(visual_key) as Script
	if visual_script == null:
		return null
	return visual_script.new() as PersistentBoardAreaVisual


func clear_visuals() -> void:
	for visual_value in active_visuals.values():
		var visual := visual_value as PersistentBoardAreaVisual
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
	active_visuals.clear()
