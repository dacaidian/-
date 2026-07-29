extends RefCounted

# Board-wide day/night transition presentation; it does not mutate faction time state.
const NightElfVfxFactoryScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_factory.gd"
)
const NightElfVfxRuntimeScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_runtime.gd"
)
const TIME_TRANSITION_PREFIX := "night_elf_time_transition_"

var _vfx: NightElfVfxFactoryScript
var _runtime: NightElfVfxRuntimeScript


func setup(
	vfx_factory: NightElfVfxFactoryScript,
	runtime: NightElfVfxRuntimeScript
) -> void:
	_vfx = vfx_factory
	_runtime = runtime


func play_transition(
	owner: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	var state_id := _state_from_animation_key(animation_key)
	var root := _vfx.create_root(
		effect_root,
		"NightElfTimeTransition_%s" % state_id,
		NightElfVfxRuntimeScript.TIME_VFX_Z_INDEX
	)
	var viewport_size := root.size
	if viewport_size == Vector2.ZERO:
		root.queue_free()
		return
	var presentation := _vfx.phase_presentation(state_id)
	var veil_color: Color = presentation.get("veil", Color.TRANSPARENT)
	var veil := ColorRect.new()
	veil.name = "NightElfTimeEnvironment"
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.size = viewport_size
	veil.color = Color(veil_color.r, veil_color.g, veil_color.b, 0.0)
	veil.z_index = 0
	root.add_child(veil)

	var symbol_center := Vector2(viewport_size.x * 0.50, viewport_size.y * 0.18)
	var symbol_size := clampf(
		minf(viewport_size.x, viewport_size.y) * 0.22,
		108.0,
		192.0
	)
	var symbol_nodes := _create_time_symbol(
		root,
		state_id,
		symbol_center,
		symbol_size,
		presentation
	)
	for symbol_node in symbol_nodes:
		symbol_node.modulate.a = 0.0
		symbol_node.scale = Vector2.ONE * 0.54
		symbol_node.position.y -= symbol_size * 0.12

	var is_night := state_id in ["moonrise", "full_moon", "moonset"]
	var particle_kind := "star" if is_night else "leaf"
	var particle_color := (
		Color(0.76, 0.90, 1.0, 0.54)
		if is_night
		else Color(0.28, 0.44, 0.38, 0.46)
	)
	if state_id == "dusk":
		particle_color = Color(0.58, 0.50, 0.62, 0.48)
	var total_duration := _runtime.scaled_duration(3.80, 1.35)
	var ambient_particles := _vfx.create_particles(
		"NightElfTimeAmbient",
		Vector2(viewport_size.x * 0.50, viewport_size.y * 0.32),
		particle_kind,
		particle_color,
		18 if is_night else 11,
		total_duration * 0.88,
		Vector2.DOWN if is_night else Vector2.RIGHT,
		34.0,
		Vector2(12.0, 38.0),
		Vector2(viewport_size.x * 0.30, viewport_size.y * 0.12),
		Vector2(0.0, 8.0),
		Vector2(0.10, 0.26),
		30,
		0.20
	)
	root.add_child(ambient_particles)

	var rise_duration := total_duration * 0.30
	var hold_duration := total_duration * 0.42
	var fade_duration := total_duration * 0.28
	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_QUART)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(veil, "color:a", veil_color.a, rise_duration)
	for symbol_node in symbol_nodes:
		rise.tween_property(
			symbol_node,
			"modulate:a",
			1.0,
			rise_duration * 0.86
		)
		rise.tween_property(
			symbol_node,
			"scale",
			Vector2.ONE,
			rise_duration
		)
		rise.tween_property(
			symbol_node,
			"position:y",
			symbol_node.position.y + symbol_size * 0.12,
			rise_duration
		)
	await rise.finished
	var hold := owner.create_tween()
	hold.tween_interval(hold_duration)
	await hold.finished
	await _runtime.finish_root(owner, root, fade_duration)


func _create_time_symbol(
	root: Control,
	state_id: String,
	center: Vector2,
	diameter: float,
	presentation: Dictionary
) -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	var core: Color = presentation.get(
		"core",
		NightElfVfxFactoryScript.MOON_CORE
	)
	var edge: Color = presentation.get(
		"edge",
		NightElfVfxFactoryScript.MOON_SILVER
	)
	var phase := float(presentation.get("phase", 1.0))
	var glow := _vfx.create_glow(
		center,
		Vector2.ONE * diameter * 1.72,
		Color(edge.r, edge.g, edge.b, edge.a * 0.30),
		8
	)
	root.add_child(glow)
	nodes.append(glow)

	var disc := _vfx.create_moon_disc(
		center,
		diameter,
		phase,
		core,
		edge,
		10
	)
	root.add_child(disc)
	nodes.append(disc)

	match state_id:
		"sunrise":
			var dawn_arc := _vfx.create_ring(
				center + Vector2(0.0, diameter * 0.20),
				Vector2(diameter * 0.62, diameter * 0.30),
				Color(0.78, 0.56, 0.40, 0.54),
				maxf(diameter * 0.018, 1.4),
				12,
				52,
				-PI * 0.92,
				PI * 0.84
			)
			root.add_child(dawn_arc)
			nodes.append(dawn_arc)
		"dusk":
			var first_moon := _vfx.create_crescent(
				center + Vector2(diameter * 0.22, -diameter * 0.10),
				diameter * 0.54,
				-0.55,
				Color(0.78, 0.84, 0.94, 0.78),
				Color(0.46, 0.38, 0.66, 0.54),
				13,
				0.18
			)
			root.add_child(first_moon)
			nodes.append(first_moon)
		"moonrise":
			disc.modulate.a = 0.0
			nodes.erase(disc)
			var rising_crescent := _vfx.create_crescent(
				center,
				diameter,
				-0.56,
				core,
				edge,
				11,
				0.17
			)
			root.add_child(rising_crescent)
			nodes.append(rising_crescent)
		"moonset":
			disc.modulate.a = 0.0
			nodes.erase(disc)
			var setting_crescent := _vfx.create_crescent(
				center,
				diameter,
				PI + 0.56,
				core,
				edge,
				11,
				0.17
			)
			root.add_child(setting_crescent)
			nodes.append(setting_crescent)
	return nodes


func _state_from_animation_key(animation_key: String) -> String:
	if animation_key.begins_with(TIME_TRANSITION_PREFIX):
		var state_id := animation_key.trim_prefix(TIME_TRANSITION_PREFIX)
		if state_id != "":
			return state_id
	return "full_moon"
