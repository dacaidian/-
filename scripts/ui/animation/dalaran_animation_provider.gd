extends RefCounted
class_name DalaranAnimationProvider

const TARGETED_KEYS: Array[String] = [
	"cone_of_cold",
	"extreme_cold_storm",
	"extreme_cold_storm_pulse",
	"extreme_cold_storm_summon"
]
const RECT_KEYS: Array[String] = ["extreme_cold_storm_cast"]

const ICE_BODY_COLOR := Color(0.26, 0.76, 1.0, 0.96)
const ICE_CORE_COLOR := Color(0.82, 0.98, 1.0, 1.0)
const ICE_EDGE_COLOR := Color(0.66, 0.94, 1.0, 0.92)
const FROST_TRAIL_COLOR := Color(0.48, 0.84, 1.0, 0.58)

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router != null:
		router.register_targeted(TARGETED_KEYS, play_targeted)
		router.register_at_rect(RECT_KEYS, play_at_rect)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if animation_key == "cone_of_cold":
		await play_cone_of_cold(owner, effect_root, caster_card, target_card)
	elif target_card != null:
		await play_extreme_cold_storm_at_rect(
			owner,
			effect_root,
			target_card.get_global_rect(),
			animation_key
		)


func play_at_rect(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	await play_extreme_cold_storm_at_rect(owner, effect_root, target_rect, animation_key)


func play_extreme_cold_storm_at_rect(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	if animation_key == "extreme_cold_storm_summon":
		await play_frozen_summon(owner, effect_root, target_rect)
		return
	if animation_key == "extreme_cold_storm_pulse":
		await play_extreme_cold_storm_crash(owner, effect_root, target_rect)
		return

	var scale_factor := 1.45
	var storm_rect := Rect2(
		target_rect.get_center() - target_rect.size * scale_factor * 0.5,
		target_rect.size * scale_factor
	)
	var veil := create_storm_disc(storm_rect, false)
	var outer_ring := create_storm_ring(storm_rect, 1.0, 5.0)
	var inner_ring := create_storm_ring(storm_rect, 0.68, 4.0)
	var snow_shards := create_storm_shards(storm_rect, 10)

	effect_root.add_child(veil)
	effect_root.add_child(outer_ring)
	effect_root.add_child(inner_ring)
	for shard in snow_shards:
		effect_root.add_child(shard)

	var gather := owner.create_tween()
	gather.set_parallel(true)
	gather.set_trans(Tween.TRANS_QUART)
	gather.set_ease(Tween.EASE_OUT)
	gather.tween_property(veil, "modulate:a", 0.48, spell_animation_duration * 0.62)
	gather.tween_property(outer_ring, "scale", Vector2.ONE, spell_animation_duration * 0.72)
	gather.tween_property(outer_ring, "modulate:a", 0.96, spell_animation_duration * 0.52)
	gather.tween_property(inner_ring, "scale", Vector2.ONE, spell_animation_duration * 0.58)
	gather.tween_property(inner_ring, "modulate:a", 0.88, spell_animation_duration * 0.48)
	for shard in snow_shards:
		gather.tween_property(shard, "modulate:a", 0.92, spell_animation_duration * 0.56)
	await gather.finished

	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_SINE)
	release.set_ease(Tween.EASE_IN_OUT)
	release.tween_property(veil, "scale", Vector2(1.12, 1.12), spell_animation_duration * 1.15)
	release.tween_property(veil, "modulate:a", 0.0, spell_animation_duration * 1.15)
	release.tween_property(outer_ring, "rotation", 0.72, spell_animation_duration * 1.15)
	release.tween_property(outer_ring, "scale", Vector2(1.24, 1.24), spell_animation_duration * 1.15)
	release.tween_property(outer_ring, "modulate:a", 0.0, spell_animation_duration * 1.15)
	release.tween_property(inner_ring, "rotation", -0.96, spell_animation_duration)
	release.tween_property(inner_ring, "scale", Vector2(1.38, 1.38), spell_animation_duration)
	release.tween_property(inner_ring, "modulate:a", 0.0, spell_animation_duration)
	for shard in snow_shards:
		var drift: Vector2 = shard.get_meta("storm_drift", Vector2.ZERO)
		release.tween_property(shard, "position", shard.position + drift, spell_animation_duration)
		release.tween_property(shard, "rotation", shard.rotation + 1.3, spell_animation_duration)
		release.tween_property(shard, "modulate:a", 0.0, spell_animation_duration)
	await release.finished

	veil.queue_free()
	outer_ring.queue_free()
	inner_ring.queue_free()
	for shard in snow_shards:
		shard.queue_free()


func play_extreme_cold_storm_crash(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> void:
	var scale_factor := 3.30
	var storm_rect := Rect2(
		target_rect.get_center() - target_rect.size * scale_factor * 0.5,
		target_rect.size * scale_factor
	)
	var cloud := create_storm_cloud(storm_rect)
	var veil := create_storm_disc(storm_rect, true)
	var impact_ring := create_storm_ring(storm_rect, 0.92, 7.0)
	var falling_ice := create_falling_ice(storm_rect, 26)

	veil.scale = Vector2(0.62, 0.62)
	impact_ring.scale = Vector2(0.32, 0.32)
	effect_root.add_child(cloud)
	effect_root.add_child(veil)
	effect_root.add_child(impact_ring)
	for ice_streak in falling_ice:
		effect_root.add_child(ice_streak)

	var fall_duration := maxf(spell_animation_duration * 1.55, 0.52)
	var descend := owner.create_tween()
	descend.set_parallel(true)
	descend.set_trans(Tween.TRANS_QUART)
	descend.set_ease(Tween.EASE_IN)
	descend.tween_property(cloud, "modulate:a", 0.88, fall_duration * 0.42)
	descend.tween_property(cloud, "scale", Vector2(1.02, 1.08), fall_duration)
	descend.tween_property(veil, "modulate:a", 0.34, fall_duration * 0.72)
	descend.tween_property(veil, "scale", Vector2.ONE, fall_duration)
	for index in range(falling_ice.size()):
		var ice_streak := falling_ice[index]
		var target_position: Vector2 = ice_streak.get_meta("impact_position", ice_streak.position)
		var delay := float(index % 6) * fall_duration * 0.035
		descend.tween_property(
			ice_streak,
			"position",
			target_position,
			fall_duration * (0.66 + float(index % 4) * 0.055)
		).set_delay(delay)
		descend.tween_property(
			ice_streak,
			"modulate:a",
			0.96,
			fall_duration * 0.34
		).set_delay(delay)
	await descend.finished

	var impact_duration := maxf(spell_animation_duration * 0.78, 0.28)
	var impact := owner.create_tween()
	impact.set_parallel(true)
	impact.set_trans(Tween.TRANS_BACK)
	impact.set_ease(Tween.EASE_OUT)
	impact.tween_property(impact_ring, "scale", Vector2.ONE, impact_duration)
	impact.tween_property(impact_ring, "modulate:a", 0.98, impact_duration * 0.46)
	impact.tween_property(veil, "modulate:a", 0.72, impact_duration * 0.38)
	impact.tween_property(cloud, "position:y", cloud.position.y + storm_rect.size.y * 0.10, impact_duration)
	for ice_streak in falling_ice:
		impact.tween_property(ice_streak, "scale", Vector2(0.42, 1.32), impact_duration * 0.48)
	await impact.finished

	var fade_duration := maxf(spell_animation_duration * 1.10, 0.38)
	var fade := owner.create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)
	fade.tween_property(cloud, "modulate:a", 0.0, fade_duration)
	fade.tween_property(veil, "scale", Vector2(1.10, 1.10), fade_duration)
	fade.tween_property(veil, "modulate:a", 0.0, fade_duration)
	fade.tween_property(impact_ring, "scale", Vector2(1.22, 1.22), fade_duration)
	fade.tween_property(impact_ring, "modulate:a", 0.0, fade_duration)
	for index in range(falling_ice.size()):
		var ice_streak := falling_ice[index]
		var shatter_offset := Vector2(
			-10.0 + float(index % 5) * 5.0,
			8.0 + float(index % 3) * 5.0
		)
		fade.tween_property(ice_streak, "position", ice_streak.position + shatter_offset, fade_duration)
		fade.tween_property(ice_streak, "scale", Vector2(0.18, 0.18), fade_duration)
		fade.tween_property(ice_streak, "modulate:a", 0.0, fade_duration)
	await fade.finished

	cloud.queue_free()
	veil.queue_free()
	impact_ring.queue_free()
	for ice_streak in falling_ice:
		ice_streak.queue_free()


func create_storm_cloud(storm_rect: Rect2) -> Panel:
	var cloud := Panel.new()
	cloud.name = "ExtremeColdStormCloud"
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud.position = Vector2(
		storm_rect.position.x,
		storm_rect.position.y - storm_rect.size.y * 0.16
	)
	cloud.size = Vector2(storm_rect.size.x, storm_rect.size.y * 0.34)
	cloud.pivot_offset = cloud.size * 0.5
	cloud.scale = Vector2(1.12, 0.72)
	cloud.modulate.a = 0.0
	cloud.z_index = 2248
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.18, 0.42, 0.58)
	style.border_color = Color(0.40, 0.82, 1.0, 0.62)
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(cloud.size.y * 0.48))
	style.shadow_color = Color(0.18, 0.62, 1.0, 0.66)
	style.shadow_size = 22
	cloud.add_theme_stylebox_override("panel", style)
	return cloud


func create_falling_ice(storm_rect: Rect2, count: int) -> Array[Panel]:
	var falling_ice: Array[Panel] = []
	for index in range(count):
		var horizontal_ratio := fmod(float(index) * 0.6180339 + 0.11, 1.0)
		var depth_ratio := fmod(float(index) * 0.381966 + 0.18, 1.0)
		var streak := Panel.new()
		streak.name = "ExtremeColdFallingIce_%d" % index
		streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
		streak.size = Vector2(
			3.0 + float(index % 3),
			20.0 + float(index % 5) * 4.0
		)
		streak.pivot_offset = streak.size * 0.5
		streak.position = Vector2(
			storm_rect.position.x + storm_rect.size.x * horizontal_ratio,
			storm_rect.position.y - storm_rect.size.y * (0.24 + float(index % 4) * 0.05)
		)
		streak.rotation = -0.18 + float(index % 3) * 0.08
		streak.modulate.a = 0.0
		streak.z_index = 2265
		streak.set_meta(
			"impact_position",
			Vector2(
				storm_rect.position.x + storm_rect.size.x * horizontal_ratio,
				storm_rect.position.y + storm_rect.size.y * (0.12 + depth_ratio * 0.78)
			)
		)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.90, 0.99, 1.0, 0.98)
		style.border_color = Color(0.54, 0.88, 1.0, 0.96)
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		style.shadow_color = Color(0.22, 0.70, 1.0, 0.82)
		style.shadow_size = 7
		streak.add_theme_stylebox_override("panel", style)
		falling_ice.append(streak)
	return falling_ice


func create_storm_disc(target_rect: Rect2, is_pulse: bool) -> Panel:
	var disc := Panel.new()
	disc.name = "ExtremeColdStormDisc"
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.position = target_rect.position
	disc.size = target_rect.size
	disc.pivot_offset = disc.size * 0.5
	disc.modulate.a = 0.0
	disc.z_index = 2240
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.32, 0.62, 0.30 if is_pulse else 0.20)
	style.border_color = Color(0.58, 0.92, 1.0, 0.72)
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(minf(disc.size.x, disc.size.y) * 0.5))
	style.shadow_color = Color(0.12, 0.55, 1.0, 0.45)
	style.shadow_size = 18 if is_pulse else 10
	disc.add_theme_stylebox_override("panel", style)
	return disc


func create_storm_ring(target_rect: Rect2, size_ratio: float, width: float) -> Panel:
	var ring_size := target_rect.size * size_ratio
	var ring := Panel.new()
	ring.name = "ExtremeColdStormRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = ring_size
	ring.position = target_rect.get_center() - ring_size * 0.5
	ring.pivot_offset = ring_size * 0.5
	ring.scale = Vector2(0.28, 0.28)
	ring.modulate.a = 0.0
	ring.z_index = 2250
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.78, 0.97, 1.0, 0.92)
	style.set_border_width_all(int(width))
	style.set_corner_radius_all(int(minf(ring_size.x, ring_size.y) * 0.5))
	style.shadow_color = Color(0.28, 0.76, 1.0, 0.62)
	style.shadow_size = int(width * 1.8)
	ring.add_theme_stylebox_override("panel", style)
	return ring


func create_storm_shards(target_rect: Rect2, count: int) -> Array[Panel]:
	var shards: Array[Panel] = []
	var center := target_rect.get_center()
	var radius := minf(target_rect.size.x, target_rect.size.y) * 0.45
	for index in range(count):
		var angle := TAU * float(index) / float(count) + float(index % 3) * 0.17
		var shard := Panel.new()
		shard.name = "ExtremeColdShard_%d" % index
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.size = Vector2(4.0, 13.0 if index % 2 == 0 else 8.0)
		shard.pivot_offset = shard.size * 0.5
		shard.position = center + Vector2(cos(angle), sin(angle)) * radius - shard.pivot_offset
		shard.rotation = angle + PI * 0.5
		shard.modulate.a = 0.0
		shard.z_index = 2260
		shard.set_meta(
			"storm_drift",
			Vector2(cos(angle + 0.72), sin(angle + 0.72)) * radius * 0.72
		)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.88, 0.99, 1.0, 0.96)
		style.shadow_color = Color(0.28, 0.78, 1.0, 0.72)
		style.shadow_size = 6
		style.set_corner_radius_all(2)
		shard.add_theme_stylebox_override("panel", style)
		shards.append(shard)
	return shards


func play_frozen_summon(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var pillar_rect := Rect2(
		target_rect.position + Vector2(target_rect.size.x * 0.28, target_rect.size.y * 0.10),
		Vector2(target_rect.size.x * 0.44, target_rect.size.y * 0.84)
	)
	var pillar := Panel.new()
	pillar.name = "ExtremeColdSummonPillar"
	pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pillar.position = pillar_rect.position
	pillar.size = pillar_rect.size
	pillar.pivot_offset = Vector2(pillar.size.x * 0.5, pillar.size.y)
	pillar.scale = Vector2(0.25, 0.08)
	pillar.modulate.a = 0.0
	pillar.z_index = 2270
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.56, 0.90, 1.0, 0.78)
	style.border_color = Color(0.92, 1.0, 1.0, 0.96)
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(pillar.size.x * 0.42))
	style.shadow_color = Color(0.18, 0.64, 1.0, 0.72)
	style.shadow_size = 14
	pillar.add_theme_stylebox_override("panel", style)
	effect_root.add_child(pillar)

	var rise := owner.create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_BACK)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(pillar, "scale", Vector2.ONE, spell_animation_duration * 0.78)
	rise.tween_property(pillar, "modulate:a", 0.96, spell_animation_duration * 0.50)
	await rise.finished

	var fade := owner.create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN)
	fade.tween_property(pillar, "scale", Vector2(1.18, 1.08), spell_animation_duration * 0.72)
	fade.tween_property(pillar, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await fade.finished
	pillar.queue_free()


func play_cone_of_cold(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card
) -> void:
	if owner == null or effect_root == null or caster_card == null or target_card == null:
		return

	var source_rect := caster_card.get_global_rect()
	var target_rect := target_card.get_global_rect()
	var source_center := source_rect.get_center()
	var target_center := target_rect.get_center()
	var cast_vector := target_center - source_center
	if cast_vector.length_squared() <= 0.001:
		return

	var direction := cast_vector.normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var source_radius := minf(source_rect.size.x, source_rect.size.y) * 0.22
	var target_radius := minf(target_rect.size.x, target_rect.size.y) * 0.16
	var launch_position := source_center + direction * source_radius
	var impact_position := target_center - direction * target_radius
	var projectile_length := clampf(minf(source_rect.size.x, source_rect.size.y) * 0.55, 34.0, 74.0)
	var projectile_width := projectile_length * 0.44
	var is_magic_immune := (
		target_card.state != null
		and target_card.state.has_keyword(CardData.KEYWORD_MAGIC_IMMUNE)
	)

	var charge_ring := create_charge_ring(source_rect)
	var projectile := create_ice_cone(projectile_length, projectile_width, false)
	var projectile_core := create_ice_cone(projectile_length * 0.72, projectile_width * 0.42, true)
	var frost_trail := create_frost_trail(launch_position, direction, projectile_length)
	var trail_crystals := create_trail_crystals(
		launch_position,
		impact_position,
		perpendicular,
		projectile_width
	)

	projectile.position = launch_position
	projectile.rotation = direction.angle()
	projectile_core.position = launch_position
	projectile_core.rotation = direction.angle()

	effect_root.add_child(charge_ring)
	effect_root.add_child(frost_trail)
	for crystal in trail_crystals:
		effect_root.add_child(crystal)
	effect_root.add_child(projectile)
	effect_root.add_child(projectile_core)

	caster_card.is_animating = true
	target_card.is_animating = true
	var caster_scale := caster_card.scale
	var target_position := target_card.position
	var target_scale := target_card.scale
	var target_modulate := target_card.self_modulate

	await play_cone_charge(
		owner,
		caster_card,
		caster_scale,
		charge_ring,
		projectile,
		projectile_core
	)
	await play_cone_flight(
		owner,
		projectile,
		projectile_core,
		frost_trail,
		trail_crystals,
		impact_position,
		cast_vector.length()
	)

	projectile.modulate.a = 0.0
	projectile_core.modulate.a = 0.0
	var impact_ring := create_impact_ring(target_rect, is_magic_immune)
	var impact_flash := create_impact_flash(target_rect, is_magic_immune)
	var shards := create_impact_shards(target_center, direction, perpendicular, target_rect.size)
	var freeze_shell: Panel = null
	if not is_magic_immune:
		freeze_shell = create_freeze_shell(target_rect)

	effect_root.add_child(impact_ring)
	effect_root.add_child(impact_flash)
	if freeze_shell != null:
		effect_root.add_child(freeze_shell)
	for shard in shards:
		effect_root.add_child(shard)

	await play_cone_impact(
		owner,
		target_card,
		target_position,
		target_scale,
		target_modulate,
		impact_ring,
		impact_flash,
		freeze_shell,
		shards,
		is_magic_immune
	)

	charge_ring.queue_free()
	frost_trail.queue_free()
	projectile.queue_free()
	projectile_core.queue_free()
	impact_ring.queue_free()
	impact_flash.queue_free()
	if freeze_shell != null:
		freeze_shell.queue_free()
	for crystal in trail_crystals:
		crystal.queue_free()
	for shard in shards:
		shard.queue_free()

	caster_card.scale = caster_scale
	target_card.position = target_position
	target_card.scale = target_scale
	target_card.self_modulate = target_modulate
	caster_card.is_animating = false
	target_card.is_animating = false


func play_cone_charge(
	owner: Node,
	caster_card: Card,
	caster_scale: Vector2,
	charge_ring: Panel,
	projectile: Polygon2D,
	projectile_core: Polygon2D
) -> void:
	var charge_duration := maxf(spell_animation_duration * 0.48, 0.15)
	var charge := owner.create_tween()
	charge.set_parallel(true)
	charge.set_trans(Tween.TRANS_BACK)
	charge.set_ease(Tween.EASE_OUT)
	charge.tween_property(caster_card, "scale", caster_scale * 1.055, charge_duration)
	charge.tween_property(charge_ring, "scale", Vector2.ONE, charge_duration)
	charge.tween_property(charge_ring, "modulate:a", 0.88, charge_duration * 0.72)
	charge.tween_property(projectile, "scale", Vector2.ONE, charge_duration)
	charge.tween_property(projectile, "modulate:a", 0.98, charge_duration * 0.72)
	charge.tween_property(projectile_core, "scale", Vector2.ONE, charge_duration)
	charge.tween_property(projectile_core, "modulate:a", 1.0, charge_duration * 0.72)
	await charge.finished


func play_cone_flight(
	owner: Node,
	projectile: Polygon2D,
	projectile_core: Polygon2D,
	frost_trail: Line2D,
	trail_crystals: Array[Polygon2D],
	impact_position: Vector2,
	distance: float
) -> void:
	var travel_duration := clampf(distance / 1050.0, 0.28, 0.52)
	var flight := owner.create_tween()
	flight.set_parallel(true)
	flight.set_trans(Tween.TRANS_QUAD)
	flight.set_ease(Tween.EASE_IN)
	flight.tween_property(projectile, "position", impact_position, travel_duration)
	flight.tween_property(projectile_core, "position", impact_position, travel_duration)
	flight.tween_property(frost_trail, "position", impact_position, travel_duration)
	flight.tween_property(frost_trail, "modulate:a", 0.72, travel_duration * 0.20)
	flight.tween_property(
		frost_trail,
		"modulate:a",
		0.0,
		travel_duration * 0.42
	).set_delay(travel_duration * 0.48)
	for index in range(trail_crystals.size()):
		var crystal := trail_crystals[index]
		var appear_delay := travel_duration * (0.10 + float(index) * 0.065)
		flight.tween_property(crystal, "modulate:a", 0.78, travel_duration * 0.18).set_delay(appear_delay)
		flight.tween_property(crystal, "scale", Vector2.ONE, travel_duration * 0.22).set_delay(appear_delay)
	await flight.finished


func play_cone_impact(
	owner: Node,
	target_card: Card,
	target_position: Vector2,
	target_scale: Vector2,
	target_modulate: Color,
	impact_ring: Panel,
	impact_flash: Panel,
	freeze_shell: Panel,
	shards: Array[Polygon2D],
	is_magic_immune: bool
) -> void:
	var impact_duration := maxf(spell_animation_duration * 0.62, 0.20)
	var burst := owner.create_tween()
	burst.set_parallel(true)
	burst.set_trans(Tween.TRANS_BACK)
	burst.set_ease(Tween.EASE_OUT)
	burst.tween_property(impact_ring, "scale", Vector2.ONE, impact_duration)
	burst.tween_property(impact_ring, "modulate:a", 0.94, impact_duration * 0.54)
	burst.tween_property(impact_flash, "scale", Vector2(1.16, 1.16), impact_duration)
	burst.tween_property(impact_flash, "modulate:a", 0.78, impact_duration * 0.42)
	if not is_magic_immune:
		burst.tween_property(
			target_card,
			"position",
			target_position + Vector2(-5.0, 2.0),
			impact_duration * 0.30
		)
		burst.tween_property(target_card, "scale", target_scale * 1.035, impact_duration * 0.42)
		burst.tween_property(
			target_card,
			"self_modulate",
			Color(0.62, 0.88, 1.12, target_modulate.a),
			impact_duration * 0.48
		)
		if freeze_shell != null:
			burst.tween_property(freeze_shell, "scale", Vector2.ONE, impact_duration)
			burst.tween_property(freeze_shell, "modulate:a", 0.82, impact_duration * 0.64)
	for shard in shards:
		var burst_offset: Vector2 = shard.get_meta("burst_offset", Vector2.ZERO)
		burst.tween_property(shard, "position", shard.position + burst_offset, impact_duration)
		burst.tween_property(shard, "scale", Vector2.ONE, impact_duration * 0.72)
		burst.tween_property(shard, "modulate:a", 0.96, impact_duration * 0.46)
	await burst.finished

	var settle_duration := maxf(spell_animation_duration * 0.62, 0.20)
	var settle := owner.create_tween()
	settle.set_parallel(true)
	settle.set_trans(Tween.TRANS_SINE)
	settle.set_ease(Tween.EASE_IN_OUT)
	settle.tween_property(target_card, "position", target_position, settle_duration)
	settle.tween_property(target_card, "scale", target_scale, settle_duration)
	settle.tween_property(target_card, "self_modulate", target_modulate, settle_duration)
	settle.tween_property(impact_ring, "scale", Vector2(1.46, 1.46), settle_duration)
	settle.tween_property(impact_ring, "modulate:a", 0.0, settle_duration)
	settle.tween_property(impact_flash, "scale", Vector2(1.38, 1.38), settle_duration)
	settle.tween_property(impact_flash, "modulate:a", 0.0, settle_duration)
	if freeze_shell != null:
		settle.tween_property(freeze_shell, "modulate:a", 0.30, settle_duration)
	for shard in shards:
		var drift: Vector2 = shard.get_meta("settle_offset", Vector2.ZERO)
		settle.tween_property(shard, "position", shard.position + drift, settle_duration)
		settle.tween_property(shard, "scale", Vector2(0.28, 0.28), settle_duration)
		settle.tween_property(shard, "modulate:a", 0.0, settle_duration)
	await settle.finished


func create_ice_cone(length: float, width: float, is_core: bool) -> Polygon2D:
	var cone := Polygon2D.new()
	cone.name = "ConeOfColdCore" if is_core else "ConeOfColdProjectile"
	cone.polygon = PackedVector2Array([
		Vector2(length * 0.58, 0.0),
		Vector2(-length * 0.24, -width * 0.50),
		Vector2(-length * 0.52, 0.0),
		Vector2(-length * 0.24, width * 0.50)
	])
	cone.color = ICE_CORE_COLOR if is_core else ICE_BODY_COLOR
	cone.scale = Vector2(0.18, 0.18)
	cone.modulate.a = 0.0
	cone.z_index = 2250 if is_core else 2248
	return cone


func create_charge_ring(source_rect: Rect2) -> Panel:
	var ring := create_panel_effect(
		source_rect,
		"ConeOfColdCharge",
		Color(0.08, 0.42, 0.68, 0.12),
		ICE_EDGE_COLOR,
		1.02,
		4
	)
	ring.scale = Vector2(0.34, 0.34)
	ring.modulate.a = 0.0
	ring.z_index = 2244
	return ring


func create_frost_trail(start: Vector2, direction: Vector2, length: float) -> Line2D:
	var trail := Line2D.new()
	trail.name = "ConeOfColdTrail"
	trail.points = PackedVector2Array([
		Vector2(-length * 1.18, 0.0),
		Vector2.ZERO
	])
	trail.position = start
	trail.rotation = direction.angle()
	trail.width = 5.0
	trail.default_color = FROST_TRAIL_COLOR
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.modulate.a = 0.0
	trail.z_index = 2238
	return trail


func create_trail_crystals(
	start: Vector2,
	finish: Vector2,
	perpendicular: Vector2,
	width: float
) -> Array[Polygon2D]:
	var crystals: Array[Polygon2D] = []
	for index in range(8):
		var progress := 0.14 + float(index) * 0.10
		var side := -1.0 if index % 2 == 0 else 1.0
		var crystal := create_ice_shard(
			start.lerp(finish, progress) + perpendicular * width * 0.16 * side,
			7.0 + float(index % 3) * 2.0,
			ICE_EDGE_COLOR
		)
		crystal.name = "ConeOfColdTrailCrystal_%d" % index
		crystal.rotation = float(index) * 0.58 * side
		crystal.scale = Vector2(0.12, 0.12)
		crystal.modulate.a = 0.0
		crystal.z_index = 2242
		crystals.append(crystal)
	return crystals


func create_impact_shards(
	center: Vector2,
	direction: Vector2,
	perpendicular: Vector2,
	target_size: Vector2
) -> Array[Polygon2D]:
	var shards: Array[Polygon2D] = []
	var radius := minf(target_size.x, target_size.y) * 0.34
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var radial := direction.rotated(angle)
		var shard := create_ice_shard(
			center + radial * radius * 0.18,
			10.0 + float(index % 4) * 2.4,
			ICE_CORE_COLOR if index % 3 == 0 else ICE_EDGE_COLOR
		)
		shard.name = "ConeOfColdImpactShard_%d" % index
		shard.rotation = radial.angle() + PI * 0.5
		shard.scale = Vector2(0.16, 0.16)
		shard.modulate.a = 0.0
		shard.z_index = 2260
		var side_bias := perpendicular * (4.0 if index % 2 == 0 else -4.0)
		shard.set_meta("burst_offset", radial * radius * (0.72 + float(index % 3) * 0.16) + side_bias)
		shard.set_meta("settle_offset", radial * radius * 0.22 + Vector2(0.0, 7.0))
		shards.append(shard)
	return shards


func create_ice_shard(position_value: Vector2, length: float, color: Color) -> Polygon2D:
	var shard := Polygon2D.new()
	shard.polygon = PackedVector2Array([
		Vector2(0.0, -length),
		Vector2(length * 0.34, 0.0),
		Vector2(0.0, length * 0.72),
		Vector2(-length * 0.34, 0.0)
	])
	shard.position = position_value
	shard.color = color
	return shard


func create_impact_ring(target_rect: Rect2, is_magic_immune: bool) -> Panel:
	var edge_color := Color(0.62, 0.72, 0.82, 0.76) if is_magic_immune else ICE_EDGE_COLOR
	var ring := create_panel_effect(
		target_rect,
		"ConeOfColdImpact",
		Color(0.16, 0.52, 0.78, 0.10),
		edge_color,
		1.30,
		5
	)
	ring.scale = Vector2(0.24, 0.24)
	ring.modulate.a = 0.0
	ring.z_index = 2254
	return ring


func create_impact_flash(target_rect: Rect2, is_magic_immune: bool) -> Panel:
	var flash_color := (
		Color(0.54, 0.64, 0.72, 0.16)
		if is_magic_immune
		else Color(0.72, 0.96, 1.0, 0.24)
	)
	var flash := create_panel_effect(
		target_rect,
		"ConeOfColdFlash",
		flash_color,
		Color(0.0, 0.0, 0.0, 0.0),
		0.72,
		0
	)
	flash.scale = Vector2(0.36, 0.36)
	flash.modulate.a = 0.0
	flash.z_index = 2252
	return flash


func create_freeze_shell(target_rect: Rect2) -> Panel:
	var shell := create_panel_effect(
		target_rect,
		"ConeOfColdFreezeShell",
		Color(0.30, 0.72, 0.96, 0.18),
		Color(0.76, 0.97, 1.0, 0.88),
		0.92,
		3
	)
	shell.scale = Vector2(0.58, 0.58)
	shell.modulate.a = 0.0
	shell.z_index = 2256
	return shell


func create_panel_effect(
	target_rect: Rect2,
	effect_name: String,
	background_color: Color,
	border_color: Color,
	scale_factor: float,
	border_width: int
) -> Panel:
	var panel := Panel.new()
	panel.name = effect_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = target_rect.size * scale_factor
	panel.pivot_offset = panel.size * 0.5
	panel.global_position = target_rect.get_center() - panel.pivot_offset

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(border_color.r, border_color.g, border_color.b, border_color.a * 0.62)
	style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel
