extends RefCounted
class_name NightElfVfxFactory

const CrescentShader := preload(
	"res://scripts/ui/animation/shaders/night_elf_crescent.gdshader"
)
const MoonDiscShader := preload(
	"res://scripts/ui/animation/shaders/night_elf_moon_disc.gdshader"
)
const MoonbeamShader := preload(
	"res://scripts/ui/animation/shaders/night_elf_moonbeam.gdshader"
)

const MOON_CORE := Color(0.93, 0.985, 1.0, 1.0)
const MOON_WHITE := Color(0.78, 0.91, 0.98, 0.94)
const MOON_SILVER := Color(0.58, 0.77, 0.90, 0.86)
const MOON_BLUE := Color(0.25, 0.50, 0.76, 0.78)
const MOON_VIOLET := Color(0.40, 0.34, 0.62, 0.62)
const NIGHT_INDIGO := Color(0.035, 0.065, 0.16, 0.72)
const FOREST_TEAL := Color(0.12, 0.34, 0.32, 0.66)
const FOREST_MIST := Color(0.34, 0.54, 0.52, 0.42)
const WATER_CORE := Color(0.78, 0.96, 1.0, 0.96)
const WATER_BLUE := Color(0.22, 0.66, 0.82, 0.78)

var _soft_texture: GradientTexture2D
var _mote_texture: GradientTexture2D
var _leaf_texture: GradientTexture2D
var _water_texture: GradientTexture2D


func create_root(
	effect_root: Control,
	root_name: String,
	z_index: int
) -> Control:
	var root := Control.new()
	root.name = root_name
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = effect_root.size
	if root.size == Vector2.ZERO:
		root.size = effect_root.get_viewport_rect().size
	root.z_index = z_index
	effect_root.add_child(root)
	root.global_position = Vector2.ZERO
	return root


func create_glow(
	center: Vector2,
	glow_size: Vector2,
	color: Color,
	z_index: int
) -> TextureRect:
	var glow := TextureRect.new()
	glow.name = "MoonlightGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = _get_soft_texture()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = glow_size
	glow.pivot_offset = glow_size * 0.5
	glow.position = center - glow.pivot_offset
	glow.modulate = color
	glow.z_index = z_index
	_add_additive_material(glow)
	return glow


func create_crescent(
	center: Vector2,
	diameter: float,
	rotation_angle: float,
	core_color: Color,
	edge_color: Color,
	z_index: int,
	cut_offset := 0.16
) -> ColorRect:
	var crescent := ColorRect.new()
	crescent.name = "SilverCrescent"
	crescent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crescent.color = Color.WHITE
	crescent.size = Vector2.ONE * diameter
	crescent.pivot_offset = crescent.size * 0.5
	crescent.position = center - crescent.pivot_offset
	crescent.rotation = rotation_angle
	crescent.z_index = z_index
	var material := ShaderMaterial.new()
	material.shader = CrescentShader
	material.set_shader_parameter("core_color", core_color)
	material.set_shader_parameter("edge_color", edge_color)
	material.set_shader_parameter("cut_offset", cut_offset)
	crescent.material = material
	return crescent


func create_moon_disc(
	center: Vector2,
	diameter: float,
	phase: float,
	core_color: Color,
	edge_color: Color,
	z_index: int
) -> ColorRect:
	var moon := ColorRect.new()
	moon.name = "MoonPhase"
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon.color = Color.WHITE
	moon.size = Vector2.ONE * diameter
	moon.pivot_offset = moon.size * 0.5
	moon.position = center - moon.pivot_offset
	moon.z_index = z_index
	var material := ShaderMaterial.new()
	material.shader = MoonDiscShader
	material.set_shader_parameter("core_color", core_color)
	material.set_shader_parameter("edge_color", edge_color)
	material.set_shader_parameter("phase", clampf(phase, -1.0, 1.0))
	moon.material = material
	return moon


func create_moonbeam(
	center: Vector2,
	beam_size: Vector2,
	core_color: Color,
	edge_color: Color,
	z_index: int,
	intensity := 1.0,
	taper := 0.28
) -> ColorRect:
	var beam := ColorRect.new()
	beam.name = "Moonbeam"
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.color = Color.WHITE
	beam.size = beam_size
	beam.pivot_offset = Vector2(beam_size.x * 0.5, beam_size.y)
	beam.position = center - beam.pivot_offset
	beam.z_index = z_index
	var material := ShaderMaterial.new()
	material.shader = MoonbeamShader
	material.set_shader_parameter("core_color", core_color)
	material.set_shader_parameter("edge_color", edge_color)
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("taper", taper)
	beam.material = material
	return beam


func create_ring(
	center: Vector2,
	radius: Vector2,
	color: Color,
	width: float,
	z_index: int,
	segments := 72,
	start_angle := 0.0,
	arc_length := TAU
) -> Line2D:
	var ring := Line2D.new()
	ring.name = "LunarRing"
	ring.width = width
	ring.default_color = color
	ring.antialiased = true
	ring.z_index = z_index
	ring.position = center
	var points := PackedVector2Array()
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		var angle := start_angle + arc_length * ratio
		points.append(
			Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		)
	ring.points = points
	_add_additive_material(ring)
	return ring


func create_trail(
	trail_name: String,
	width: float,
	head_color: Color,
	middle_color: Color,
	z_index: int
) -> Line2D:
	var trail := Line2D.new()
	trail.name = trail_name
	trail.width = width
	trail.antialiased = true
	trail.z_index = z_index
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	gradient.colors = PackedColorArray([
		Color(middle_color.r, middle_color.g, middle_color.b, 0.0),
		middle_color,
		head_color
	])
	trail.gradient = gradient
	_add_additive_material(trail)
	return trail


func create_particles(
	particle_name: String,
	center: Vector2,
	kind: String,
	color: Color,
	amount: int,
	lifetime: float,
	direction: Vector2,
	spread: float,
	velocity_range: Vector2,
	emission_extents: Vector2,
	gravity: Vector2,
	scale_range: Vector2,
	z_index: int,
	explosiveness := 0.82
) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = particle_name
	particles.position = center
	particles.z_index = z_index
	particles.amount = maxi(amount, 1)
	particles.lifetime = maxf(lifetime, 0.08)
	particles.one_shot = true
	particles.explosiveness = clampf(explosiveness, 0.0, 1.0)
	particles.randomness = 0.46
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = emission_extents
	particles.direction = (
		direction.normalized()
		if direction.length() > 0.001
		else Vector2.UP
	)
	particles.spread = spread
	particles.gravity = gravity
	particles.initial_velocity_min = velocity_range.x
	particles.initial_velocity_max = velocity_range.y
	particles.scale_amount_min = scale_range.x
	particles.scale_amount_max = scale_range.y
	particles.angular_velocity_min = -58.0
	particles.angular_velocity_max = 58.0
	particles.color = color
	particles.color_ramp = _create_particle_ramp(color)
	particles.texture = _get_particle_texture(kind)
	particles.emitting = true
	if kind != "leaf":
		_add_additive_material(particles)
	return particles


func create_star(
	center: Vector2,
	radius: float,
	color: Color,
	z_index: int
) -> Node2D:
	var star := Node2D.new()
	star.name = "EluneStar"
	star.position = center
	star.z_index = z_index

	var horizontal := Line2D.new()
	horizontal.width = maxf(radius * 0.16, 1.0)
	horizontal.default_color = color
	horizontal.antialiased = true
	horizontal.points = PackedVector2Array([
		Vector2(-radius, 0.0),
		Vector2(radius, 0.0)
	])
	_add_additive_material(horizontal)
	star.add_child(horizontal)

	var vertical := Line2D.new()
	vertical.width = maxf(radius * 0.13, 1.0)
	vertical.default_color = color
	vertical.antialiased = true
	vertical.points = PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(0.0, radius)
	])
	_add_additive_material(vertical)
	star.add_child(vertical)

	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(radius * 0.28, 0.0),
		Vector2(0.0, radius * 0.28),
		Vector2(-radius * 0.28, 0.0),
		Vector2(0.0, -radius * 0.28)
	])
	core.color = Color(
		minf(color.r + 0.12, 1.0),
		minf(color.g + 0.12, 1.0),
		minf(color.b + 0.12, 1.0),
		color.a
	)
	_add_additive_material(core)
	star.add_child(core)
	return star


func create_arrow(
	center: Vector2,
	direction: Vector2,
	length: float,
	color: Color,
	z_index: int
) -> Node2D:
	var arrow := Node2D.new()
	arrow.name = "MoonlightArrow"
	arrow.position = center
	arrow.z_index = z_index
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side := forward.orthogonal()

	var shaft := Line2D.new()
	shaft.width = maxf(length * 0.018, 1.2)
	shaft.default_color = color
	shaft.antialiased = true
	shaft.points = PackedVector2Array([
		-forward * length * 0.44,
		forward * length * 0.40
	])
	_add_additive_material(shaft)
	arrow.add_child(shaft)

	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		forward * length * 0.50,
		forward * length * 0.31 + side * length * 0.09,
		forward * length * 0.35,
		forward * length * 0.31 - side * length * 0.09
	])
	head.color = color
	_add_additive_material(head)
	arrow.add_child(head)
	return arrow


func create_claw_mark(
	path: PackedVector2Array,
	max_width: float,
	z_index: int
) -> Node2D:
	var mark := Node2D.new()
	mark.name = "PhysicalClawMark"
	mark.z_index = z_index
	if path.size() < 2:
		return mark

	var left_edge := PackedVector2Array()
	var right_edge := PackedVector2Array()
	for point_index in range(path.size()):
		var previous_index := maxi(point_index - 1, 0)
		var next_index := mini(point_index + 1, path.size() - 1)
		var tangent := (path[next_index] - path[previous_index]).normalized()
		if tangent == Vector2.ZERO:
			tangent = Vector2(0.7, 1.0).normalized()
		var normal := tangent.orthogonal()
		var ratio := float(point_index) / float(maxi(path.size() - 1, 1))
		var half_width := max_width * (0.06 + sin(ratio * PI) * 0.94)
		left_edge.append(path[point_index] + normal * half_width)
		right_edge.append(path[point_index] - normal * half_width)

	var polygon_points := PackedVector2Array()
	for point in left_edge:
		polygon_points.append(point)
	for point_index in range(right_edge.size() - 1, -1, -1):
		polygon_points.append(right_edge[point_index])

	var cut := Polygon2D.new()
	cut.polygon = polygon_points
	cut.color = Color(0.005, 0.018, 0.028, 0.90)
	mark.add_child(cut)

	var edge := Line2D.new()
	edge.points = left_edge
	edge.width = maxf(max_width * 0.16, 1.0)
	edge.default_color = Color(0.72, 0.90, 0.98, 0.92)
	edge.antialiased = true
	_add_additive_material(edge)
	mark.add_child(edge)

	var inner := Line2D.new()
	inner.points = path
	inner.width = maxf(max_width * 0.24, 1.0)
	inner.default_color = Color(0.01, 0.06, 0.09, 0.94)
	inner.antialiased = true
	mark.add_child(inner)
	return mark


func phase_presentation(state_id: String) -> Dictionary:
	match state_id:
		"sunrise":
			return {
				"phase": 0.18,
				"core": Color(1.0, 0.84, 0.70, 0.90),
				"edge": Color(0.92, 0.52, 0.34, 0.74),
				"veil": Color(0.56, 0.28, 0.22, 0.15)
			}
		"noon":
			return {
				"phase": 0.98,
				"core": Color(0.96, 1.0, 0.90, 0.82),
				"edge": Color(0.42, 0.68, 0.52, 0.62),
				"veil": Color(0.48, 0.58, 0.40, 0.10)
			}
		"dusk":
			return {
				"phase": 0.24,
				"core": Color(0.80, 0.74, 0.94, 0.90),
				"edge": Color(0.86, 0.48, 0.32, 0.72),
				"veil": Color(0.26, 0.10, 0.34, 0.19)
			}
		"moonrise":
			return {
				"phase": -0.34,
				"core": MOON_WHITE,
				"edge": MOON_BLUE,
				"veil": Color(0.03, 0.10, 0.28, 0.19)
			}
		"moonset":
			return {
				"phase": 0.34,
				"core": Color(0.76, 0.80, 0.94, 0.88),
				"edge": Color(0.54, 0.42, 0.76, 0.70),
				"veil": Color(0.12, 0.07, 0.24, 0.17)
			}
		_:
			return {
				"phase": 1.0,
				"core": MOON_CORE,
				"edge": MOON_SILVER,
				"veil": Color(0.06, 0.14, 0.34, 0.22)
			}


func _get_particle_texture(kind: String) -> Texture2D:
	match kind:
		"leaf":
			if _leaf_texture == null:
				_leaf_texture = _create_radial_texture(
					Vector2i(30, 11),
					Vector2(0.86, 0.5)
				)
			return _leaf_texture
		"water":
			if _water_texture == null:
				_water_texture = _create_radial_texture(
					Vector2i(13, 25),
					Vector2(0.64, 0.5)
				)
			return _water_texture
		"mote", "star":
			if _mote_texture == null:
				_mote_texture = _create_radial_texture(
					Vector2i(22, 22),
					Vector2(0.70, 0.5)
				)
			return _mote_texture
		_:
			return _get_soft_texture()


func _get_soft_texture() -> GradientTexture2D:
	if _soft_texture == null:
		_soft_texture = _create_radial_texture(
			Vector2i(128, 128),
			Vector2(0.72, 0.5)
		)
	return _soft_texture


func _create_radial_texture(
	texture_size: Vector2i,
	fill_to: Vector2
) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.74),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size.x
	texture.height = texture_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = fill_to
	return texture


func _create_particle_ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.18, 0.72, 1.0])
	ramp.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.0),
		Color(color.r, color.g, color.b, color.a),
		Color(color.r, color.g, color.b, color.a * 0.70),
		Color(color.r, color.g, color.b, 0.0)
	])
	return ramp


func _add_additive_material(item: CanvasItem) -> void:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	item.material = material
