extends Control
class_name CardStatusOverlay

# CardStatusOverlay draws persistent visual markers for statuses attached to a board card.
# It is purely presentational: CardState remains the single source of truth.

var state: CardState
var beast_path_color := Color(0.30, 0.16, 0.04, 0.28)
var beast_path_edge_color := Color(0.86, 0.58, 0.20, 0.88)
var beast_path_glow_color := Color(0.28, 0.70, 0.16, 0.42)
var divine_shield_color := Color(1.0, 0.84, 0.24, 0.26)
var divine_shield_edge_color := Color(1.0, 0.92, 0.48, 0.82)
var divine_shield_glow_color := Color(1.0, 0.78, 0.18, 0.34)
var arcane_aura_color := Color(0.45, 0.35, 1.0, 0.18)
var arcane_aura_edge_color := Color(0.72, 0.66, 1.0, 0.72)
var arcane_aura_glow_color := Color(0.40, 0.72, 1.0, 0.28)
var freeze_ice_color := Color(0.30, 0.68, 0.96, 0.22)
var freeze_ice_edge_color := Color(0.44, 0.82, 1.0, 0.72)
var freeze_ice_glow_color := Color(0.24, 0.60, 0.96, 0.20)
var encourage_gu_color := Color(0.42, 1.0, 0.36, 0.16)
var encourage_gu_edge_color := Color(0.72, 1.0, 0.48, 0.72)
var encourage_gu_venom_color := Color(0.20, 0.95, 0.38, 0.58)
var encourage_gu_insect_color := Color(0.96, 1.0, 0.42, 0.82)
var snake_venom_color := Color(0.26, 0.10, 0.36, 0.22)
var snake_venom_edge_color := Color(0.72, 0.38, 1.0, 0.70)
var snake_venom_fang_color := Color(0.82, 1.0, 0.34, 0.80)
var life_link_larva_color := Color(0.36, 0.22, 0.04, 0.20)
var life_link_larva_edge_color := Color(0.88, 0.82, 0.24, 0.74)
var life_link_larva_core_color := Color(0.70, 1.0, 0.26, 0.80)
var life_link_color := Color(0.10, 0.36, 0.08, 0.18)
var life_link_edge_color := Color(0.62, 1.0, 0.32, 0.76)
var life_link_thread_color := Color(0.46, 1.0, 0.24, 0.78)
var death_immunity_color := Color(0.05, 0.12, 0.07, 0.26)
var death_immunity_edge_color := Color(0.74, 1.0, 0.42, 0.74)
var death_immunity_thread_color := Color(0.40, 0.92, 0.24, 0.62)
var precision_shot_color := Color(0.30, 0.78, 1.0, 0.16)
var precision_shot_edge_color := Color(0.64, 0.94, 1.0, 0.86)
var precision_shot_mark_color := Color(1.0, 0.96, 0.58, 0.90)
var meteor_aura_color := Color(0.42, 0.16, 0.72, 0.18)
var meteor_aura_edge_color := Color(0.92, 0.78, 1.0, 0.80)
var meteor_aura_star_color := Color(1.0, 0.86, 0.42, 0.88)
var soul_hook_color := Color(0.45, 0.04, 0.18, 0.20)
var soul_hook_edge_color := Color(1.0, 0.24, 0.56, 0.74)
var soul_hook_chain_color := Color(0.86, 0.44, 1.0, 0.76)
var charm_color := Color(0.82, 0.18, 0.70, 0.18)
var charm_edge_color := Color(1.0, 0.42, 0.86, 0.78)
var charm_rune_color := Color(1.0, 0.78, 0.96, 0.86)
var reborn_color := Color(0.18, 0.78, 0.44, 0.16)
var reborn_edge_color := Color(0.76, 1.0, 0.58, 0.82)
var reborn_core_color := Color(1.0, 0.92, 0.48, 0.88)
var bronze_iron_color := Color(0.74, 0.58, 0.34, 0.16)
var bronze_iron_edge_color := Color(1.0, 0.78, 0.38, 0.84)
var bronze_iron_plate_color := Color(0.92, 0.72, 0.42, 0.36)
var bronze_iron_rivet_color := Color(1.0, 0.92, 0.66, 0.86)
var immortal_peach_color := Color(1.0, 0.42, 0.58, 0.16)
var immortal_peach_edge_color := Color(1.0, 0.78, 0.48, 0.78)
var immortal_peach_leaf_color := Color(0.58, 1.0, 0.42, 0.72)
var immortal_peach_core_color := Color(1.0, 0.88, 0.62, 0.88)
var rooted_color := Color(1.0, 0.66, 0.10, 0.24)
var rooted_edge_color := Color(1.0, 0.86, 0.30, 0.88)
var rooted_seal_color := Color(1.0, 0.92, 0.42, 0.92)
var rooted_seal_shadow_color := Color(0.32, 0.16, 0.02, 0.72)
var stealth_color := Color(0.52, 0.72, 0.92, 0.12)
var stealth_edge_color := Color(0.76, 0.92, 1.0, 0.62)
var stealth_mist_color := Color(0.86, 0.96, 1.0, 0.34)
var wanmo_charge_color := Color(0.46, 0.02, 0.02, 0.24)
var wanmo_charge_edge_color := Color(1.0, 0.24, 0.08, 0.78)
var wanmo_charge_core_color := Color(1.0, 0.46, 0.12, 0.92)
var wanmo_charge_text_color := Color(1.0, 0.90, 0.58, 0.98)
var wanmo_charge_shadow_color := Color(0.12, 0.0, 0.0, 0.96)
var chaos_corruption_color := Color(0.22, 0.02, 0.30, 0.20)
var chaos_corruption_edge_color := Color(0.86, 0.18, 1.0, 0.78)
var chaos_corruption_core_color := Color(0.92, 0.20, 0.34, 0.88)
var chaos_corruption_text_color := Color(1.0, 0.78, 0.98, 0.98)
var chaos_corruption_shadow_color := Color(0.08, 0.0, 0.10, 0.96)
var fel_infusion_color := Color(0.10, 0.82, 0.28, 0.18)
var fel_infusion_edge_color := Color(0.44, 1.0, 0.26, 0.82)
var fel_infusion_flame_color := Color(0.12, 1.0, 0.42, 0.74)
var fel_overload_color := Color(0.06, 0.48, 0.12, 0.24)
var fel_overload_edge_color := Color(0.68, 1.0, 0.20, 0.90)
var fel_overload_crack_color := Color(0.10, 1.0, 0.34, 0.82)
var fel_madness_color := Color(0.18, 0.04, 0.22, 0.22)
var fel_madness_edge_color := Color(0.64, 0.96, 0.16, 0.64)
var fel_madness_rune_color := Color(0.72, 0.06, 0.10, 0.72)
var damage_amplify_color := Color(0.34, 0.02, 0.42, 0.22)
var damage_amplify_edge_color := Color(0.96, 0.20, 1.0, 0.78)
var damage_amplify_crack_color := Color(0.20, 1.0, 0.34, 0.72)
var damage_amplify_text_color := Color(1.0, 0.80, 1.0, 0.96)
var damage_amplify_shadow_color := Color(0.08, 0.0, 0.12, 0.96)
var taunt_color := Color(0.42, 0.22, 0.08, 0.08)
var taunt_edge_color := Color(0.95, 0.60, 0.18, 0.50)
var taunt_plate_color := Color(0.34, 0.16, 0.06, 0.26)
var taunt_rivet_color := Color(0.98, 0.72, 0.28, 0.56)
var kagune_release_color := Color(0.34, 0.015, 0.08, 0.11)
var kagune_release_edge_color := Color(0.88, 0.12, 0.30, 0.62)
var kagune_release_core_color := Color(1.0, 0.34, 0.48, 0.76)
var animation_time := 0.0
var redraw_accumulator := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _process(delta: float) -> void:
	animation_time = fmod(animation_time + delta, 1000.0)
	redraw_accumulator += delta
	if redraw_accumulator >= 1.0 / 30.0:
		redraw_accumulator = 0.0
		queue_redraw()


func set_state(new_state: CardState) -> void:
	state = new_state
	refresh()


func refresh() -> void:
	visible = has_visible_status()
	set_process(visible and (should_show_divine_shield() or should_show_arcane_aura()))
	if visible:
		queue_redraw()


func has_visible_status() -> bool:
	return should_show_beast_path() or should_show_taunt() or should_show_kagune_release() or should_show_divine_shield() or should_show_bronze_head_iron_arms() or should_show_immortal_peach() or should_show_rooted() or should_show_stealth() or should_show_arcane_aura() or should_show_meteor_aura() or should_show_freeze() or should_show_encourage_gu() or should_show_snake_venom() or should_show_life_link_larva() or should_show_life_link() or should_show_death_immunity() or should_show_precision_shot() or should_show_soul_hook() or should_show_charm() or should_show_reborn() or should_show_wanmo_charge() or should_show_chaos_corruption() or should_show_fel_infusion() or should_show_fel_overload() or should_show_fel_madness() or should_show_damage_amplify()


func should_show_beast_path() -> bool:
	return state != null and state.has_beast_path


func should_show_taunt() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_minion() and state.has_keyword(CardData.KEYWORD_TAUNT)


func should_show_kagune_release() -> bool:
	return state != null and state.is_face_up and state.has_status_with_tag(KagunePowerResolver.STATUS_TAG)


func should_show_divine_shield() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_DIVINE_SHIELD)


func should_show_bronze_head_iron_arms() -> bool:
	if state == null or state.data == null:
		return false

	return (
		state.is_face_up
		and state.is_unit()
		and (
			state.has_status(CardStatus.STATUS_BRONZE_HEAD_IRON_ARMS)
			or state.has_keyword(CardData.KEYWORD_REFLECT)
		)
	)


func should_show_immortal_peach() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_IMMORTAL_PEACH)


func should_show_rooted() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ROOTED)


func should_show_stealth() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status_with_tag(CardStatus.TAG_STEALTH)


func should_show_arcane_aura() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ARCANE_AURA)


func should_show_meteor_aura() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_METEOR_AURA)


func should_show_freeze() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_FREEZE)


func should_show_encourage_gu() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_ENCOURAGE_GU)


func should_show_snake_venom() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_SNAKE_VENOM)


func should_show_life_link() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_LIFE_LINK)


func should_show_life_link_larva() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_LIFE_LINK_LARVA)


func should_show_death_immunity() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status_with_tag(CardStatus.TAG_DEATH_PREVENTION)


func should_show_precision_shot() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_PRECISION_SHOT)


func should_show_soul_hook() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_SOUL_HOOK)


func should_show_charm() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_minion() and state.has_status(CardStatus.STATUS_CHARM)


func should_show_reborn() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_minion() and state.get_reborn_count() > 0


func should_show_wanmo_charge() -> bool:
	if state == null or state.data == null:
		return false

	var status := state.get_status(CardStatus.STATUS_WANMO_CHARGE)
	return state.is_face_up and state.is_building() and status != null and status.get_wanmo_charge() > 0


func should_show_chaos_corruption() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_minion() and state.chaos_corruption > 0


func should_show_fel_infusion() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_FEL_INFUSION)


func should_show_fel_overload() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.has_status(CardStatus.STATUS_FEL_OVERLOAD)


func should_show_fel_madness() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_minion() and get_fel_madness_status() != null


func should_show_damage_amplify() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.get_damage_amplify_bonus() > 0


func _draw() -> void:
	if should_show_beast_path():
		draw_beast_path_overlay()
	if should_show_taunt():
		draw_taunt_overlay()
	if should_show_kagune_release():
		draw_kagune_release_overlay()
	if should_show_arcane_aura():
		draw_arcane_aura()
	if should_show_meteor_aura():
		draw_meteor_aura()
	if should_show_precision_shot():
		draw_precision_shot_overlay()
	if should_show_soul_hook():
		draw_soul_hook_overlay()
	if should_show_charm():
		draw_charm_overlay()
	if should_show_reborn():
		draw_reborn_overlay()
	if should_show_wanmo_charge():
		draw_wanmo_charge_overlay()
	if should_show_chaos_corruption():
		draw_chaos_corruption_overlay()
	if should_show_fel_infusion():
		draw_fel_infusion_overlay()
	if should_show_fel_overload():
		draw_fel_overload_overlay()
	if should_show_fel_madness():
		draw_fel_madness_overlay()
	if should_show_damage_amplify():
		draw_damage_amplify_overlay()
	if should_show_encourage_gu():
		draw_encourage_gu_overlay()
	if should_show_snake_venom():
		draw_snake_venom_overlay()
	if should_show_life_link_larva():
		draw_life_link_larva_overlay()
	if should_show_life_link():
		draw_life_link_overlay()
	if should_show_death_immunity():
		draw_death_immunity_overlay()
	if should_show_bronze_head_iron_arms():
		draw_bronze_head_iron_arms()
	if should_show_immortal_peach():
		draw_immortal_peach_overlay()
	if should_show_rooted():
		draw_rooted_overlay()
	if should_show_stealth():
		draw_stealth_overlay()
	if should_show_divine_shield():
		draw_divine_shield()
	if should_show_freeze():
		draw_freeze_overlay()


func draw_beast_path_overlay() -> void:
	var card_rect := Rect2(Vector2.ZERO, size)
	var inset := maxf(minf(size.x, size.y) * 0.035, 2.0)
	var path_rect := card_rect.grow(-inset)
	var center := card_rect.get_center()
	var tunnel_width := maxf(minf(size.x, size.y) * 0.22, 12.0)

	draw_rect(path_rect, beast_path_color, true)
	draw_rect(path_rect, beast_path_edge_color, false, 6)

	draw_line(
		Vector2(inset, center.y),
		Vector2(size.x - inset, center.y),
		beast_path_glow_color,
		tunnel_width
	)
	draw_line(
		Vector2(center.x, inset),
		Vector2(center.x, size.y - inset),
		Color(beast_path_glow_color.r, beast_path_glow_color.g, beast_path_glow_color.b, beast_path_glow_color.a * 0.78),
		tunnel_width * 0.72
	)


func draw_taunt_overlay() -> void:
	var guard_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.045)
	var center := guard_rect.get_center()
	var edge_width := maxf(size.x * 0.014, 1.5)

	draw_rect(guard_rect, taunt_color, true)
	draw_rect(guard_rect, taunt_edge_color, false, edge_width, true)

	var shield_height := guard_rect.size.y * 0.38
	var shield_width := guard_rect.size.x * 0.34
	var top_y := guard_rect.position.y + guard_rect.size.y * 0.16
	var shield_points := PackedVector2Array([
		center + Vector2(-shield_width * 0.50, -shield_height * 0.42),
		center + Vector2(shield_width * 0.50, -shield_height * 0.42),
		center + Vector2(shield_width * 0.42, shield_height * 0.12),
		center + Vector2(0.0, shield_height * 0.58),
		center + Vector2(-shield_width * 0.42, shield_height * 0.12)
	])
	for index in range(shield_points.size()):
		shield_points[index].y = shield_points[index].y - center.y + top_y + shield_height * 0.50

	draw_colored_polygon(shield_points, taunt_plate_color)
	draw_polyline(shield_points, Color(taunt_edge_color.r, taunt_edge_color.g, taunt_edge_color.b, 0.62), maxf(size.x * 0.014, 1.5), true)

	for index in range(4):
		var t := float(index) / 3.0
		var x := lerpf(guard_rect.position.x + guard_rect.size.x * 0.18, guard_rect.position.x + guard_rect.size.x * 0.82, t)
		draw_line(
			Vector2(x, guard_rect.position.y + guard_rect.size.y * 0.10),
			Vector2(x, guard_rect.position.y + guard_rect.size.y * 0.90),
			Color(taunt_edge_color.r, taunt_edge_color.g, taunt_edge_color.b, 0.12),
			maxf(size.x * 0.008, 1.0)
		)

	for point in shield_points:
		draw_circle(point, maxf(size.x * 0.010, 1.6), taunt_rivet_color)

	var crack_color := Color(0.92, 0.54, 0.18, 0.26)
	draw_line(Vector2(size.x * 0.16, size.y * 0.24), Vector2(size.x * 0.38, size.y * 0.42), crack_color, 2.0)
	draw_line(Vector2(size.x * 0.38, size.y * 0.42), Vector2(size.x * 0.27, size.y * 0.58), crack_color, 1.4)
	draw_line(Vector2(size.x * 0.78, size.y * 0.26), Vector2(size.x * 0.55, size.y * 0.48), crack_color, 2.0)
	draw_line(Vector2(size.x * 0.55, size.y * 0.48), Vector2(size.x * 0.70, size.y * 0.70), crack_color, 1.4)

	for index in range(5):
		var angle := TAU * float(index) / 5.0 + 0.32
		var point := center + Vector2(cos(angle), sin(angle)) * minf(size.x, size.y) * 0.28
		draw_circle(point, 2.6, Color(0.76, 0.42, 0.12, 0.38))


func draw_kagune_release_overlay() -> void:
	var card_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.035)
	var center := card_rect.get_center()
	draw_rect(card_rect, kagune_release_color, true)
	draw_rect(card_rect, kagune_release_edge_color, false, maxf(size.x * 0.018, 2.0))

	for index in range(4):
		var side := -1.0 if index < 2 else 1.0
		var vertical := float(index % 2)
		var start := center + Vector2(side * card_rect.size.x * 0.12, card_rect.size.y * (-0.18 + vertical * 0.36))
		var middle := center + Vector2(side * card_rect.size.x * 0.30, card_rect.size.y * (-0.28 + vertical * 0.56))
		var tip := center + Vector2(side * card_rect.size.x * 0.46, card_rect.size.y * (-0.40 + vertical * 0.80))
		draw_polyline(
			PackedVector2Array([start, middle, tip]),
			kagune_release_edge_color,
			maxf(size.x * 0.026, 2.5),
			true
		)
		draw_circle(tip, maxf(size.x * 0.014, 1.8), kagune_release_core_color)


func draw_arcane_aura() -> void:
	var aura_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.04)
	var center := aura_rect.get_center()
	var radius := minf(aura_rect.size.x, aura_rect.size.y) * 0.44
	var status := state.get_status(CardStatus.STATUS_ARCANE_AURA) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)
	var pulse := 0.5 + 0.5 * sin(animation_time * 2.3)
	var rotation := animation_time * 0.42

	draw_circle(
		center,
		radius * (0.72 + pulse * 0.025),
		Color(arcane_aura_color.r, arcane_aura_color.g, arcane_aura_color.b, arcane_aura_color.a * (0.72 + pulse * 0.22))
	)

	for index in range(ring_count):
		var ring_radius := radius + float(index) * 4.2
		var direction := 1.0 if index % 2 == 0 else -1.0
		var ring_rotation := rotation * direction + float(index) * 0.34
		var alpha := arcane_aura_edge_color.a * (1.0 - float(index) * 0.12)
		var ring_color := Color(
			arcane_aura_edge_color.r,
			arcane_aura_edge_color.g,
			arcane_aura_edge_color.b,
			alpha * (0.82 + pulse * 0.18)
		)
		draw_arc(center, ring_radius, ring_rotation, ring_rotation + TAU * 0.34, 36, ring_color, 2.4, true)
		draw_arc(center, ring_radius, ring_rotation + TAU * 0.50, ring_rotation + TAU * 0.84, 36, ring_color, 2.4, true)

		for rune_index in range(6):
			var angle := ring_rotation + TAU * float(rune_index) / 6.0
			var radial := Vector2.from_angle(angle)
			var tangent := radial.orthogonal()
			var rune_center := center + radial * ring_radius
			var rune_size := 2.8 + float(index) * 0.45
			draw_line(rune_center - tangent * rune_size, rune_center + tangent * rune_size, ring_color, 1.4, true)
			draw_line(rune_center, rune_center + radial * rune_size * 1.5, ring_color, 1.2, true)

	for stream_index in range(7):
		var phase := fmod(animation_time * (0.24 + float(stream_index) * 0.015) + float(stream_index) * 0.137, 1.0)
		var angle := TAU * float(stream_index) / 7.0 - rotation * 0.35
		var radial := Vector2.from_angle(angle)
		var stream_radius := radius * (0.30 + phase * 0.66)
		var stream_point := center + radial * stream_radius + Vector2(0.0, -8.0 * sin(phase * PI))
		var stream_alpha := sin(phase * PI) * (0.28 + pulse * 0.22)
		draw_circle(
			stream_point,
			1.8 + pulse * 0.8,
			Color(arcane_aura_glow_color.r, arcane_aura_glow_color.g, arcane_aura_glow_color.b, stream_alpha)
		)

	for orbit_index in range(3):
		var orbit_angle := -rotation * 1.8 + TAU * float(orbit_index) / 3.0
		var orbit_point := center + Vector2.from_angle(orbit_angle) * radius * 0.84
		draw_circle(orbit_point, 2.5 + pulse, Color(0.76, 0.90, 1.0, 0.70))
		draw_circle(orbit_point, 1.1 + pulse * 0.35, Color(0.94, 0.98, 1.0, 0.96))


func draw_meteor_aura() -> void:
	var aura_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.05)
	var center := aura_rect.get_center()
	var radius := minf(aura_rect.size.x, aura_rect.size.y) * 0.42
	var status := state.get_status(CardStatus.STATUS_METEOR_AURA) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 5)

	draw_circle(center, radius * 0.82, meteor_aura_color)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 4.5
		var alpha := meteor_aura_edge_color.a * (1.0 - float(index) * 0.12)
		draw_arc(center, ring_radius, -PI * 0.18, TAU - PI * 0.18, 80, Color(meteor_aura_edge_color.r, meteor_aura_edge_color.g, meteor_aura_edge_color.b, alpha), 2.2, true)

	for index in range(6):
		var angle := TAU * float(index) / 6.0 + 0.28
		var pos := center + Vector2(cos(angle), sin(angle)) * radius * 0.78
		draw_line(pos + Vector2(-4.0, 0.0), pos + Vector2(4.0, 0.0), meteor_aura_star_color, 1.8)
		draw_line(pos + Vector2(0.0, -4.0), pos + Vector2(0.0, 4.0), meteor_aura_star_color, 1.8)


func draw_wanmo_charge_overlay() -> void:
	var status := state.get_status(CardStatus.STATUS_WANMO_CHARGE) if state != null else null
	if status == null:
		return

	var charge_count := status.get_wanmo_charge()
	var charge_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.08)
	var center := charge_rect.get_center()
	var radius := minf(charge_rect.size.x, charge_rect.size.y) * 0.34

	draw_circle(center, radius * 1.08, wanmo_charge_color)
	for index in range(mini(maxi(charge_count, 1), 6)):
		var ring_radius := radius + float(index) * 4.0
		var alpha := wanmo_charge_edge_color.a * (1.0 - float(index) * 0.12)
		draw_arc(center, ring_radius, -PI * 0.22, TAU - PI * 0.22, 80, Color(wanmo_charge_edge_color.r, wanmo_charge_edge_color.g, wanmo_charge_edge_color.b, alpha), 2.4, true)

	for index in range(6):
		var angle := TAU * float(index) / 6.0 + 0.16
		var inner_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.45
		var outer_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.88
		draw_line(inner_point, outer_point, wanmo_charge_core_color, 2.0)

	var font := get_theme_default_font()
	var font_size := maxi(int(size.x * 0.22), 22)
	var text := str(charge_count)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var text_position := center - text_size * 0.5 + Vector2(0.0, text_size.y * 0.78)
	draw_string(font, text_position + Vector2(2.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, wanmo_charge_shadow_color)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, wanmo_charge_text_color)


func draw_chaos_corruption_overlay() -> void:
	var corruption_value: int = maxi(state.chaos_corruption if state != null else 0, 0)
	if corruption_value <= 0:
		return

	var corruption_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.055)
	var center := corruption_rect.get_center()
	var radius := minf(corruption_rect.size.x, corruption_rect.size.y) * 0.35
	var ring_count: int = mini(corruption_value, 9)

	draw_circle(center, radius * 0.96, chaos_corruption_color)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 3.2
		var alpha := chaos_corruption_edge_color.a * (1.0 - float(index) * 0.075)
		var start_angle := -PI * 0.35 + float(index) * 0.19
		draw_arc(
			center,
			ring_radius,
			start_angle,
			start_angle + TAU * 0.82,
			78,
			Color(chaos_corruption_edge_color.r, chaos_corruption_edge_color.g, chaos_corruption_edge_color.b, alpha),
			2.1,
			true
		)

	for index in range(6):
		var angle := TAU * float(index) / 6.0 + PI * 0.10
		var inner_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.30
		var outer_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.86
		draw_line(
			inner_point,
			outer_point,
			Color(chaos_corruption_core_color.r, chaos_corruption_core_color.g, chaos_corruption_core_color.b, 0.40),
			1.8
		)

	for index in range(mini(corruption_value, 12)):
		var angle := TAU * float(index) / float(mini(corruption_value, 12)) - PI * 0.5
		var point := center + Vector2(cos(angle), sin(angle)) * radius * 0.72
		draw_circle(point, maxf(size.x * 0.010, 1.8), Color(chaos_corruption_core_color.r, chaos_corruption_core_color.g, chaos_corruption_core_color.b, 0.58))

	var font := get_theme_default_font()
	var font_size := maxi(int(size.x * 0.20), 20)
	var text := str(corruption_value)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var text_position := center - text_size * 0.5 + Vector2(0.0, text_size.y * 0.78)
	draw_string(font, text_position + Vector2(2.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, chaos_corruption_shadow_color)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, chaos_corruption_text_color)


func draw_fel_infusion_overlay() -> void:
	var fel_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.045)
	var center := fel_rect.get_center()
	var radius := minf(fel_rect.size.x, fel_rect.size.y) * 0.42
	var status := state.get_status(CardStatus.STATUS_FEL_INFUSION) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)

	draw_rect(fel_rect, fel_infusion_color, true)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 4.2
		var alpha := fel_infusion_edge_color.a * (1.0 - float(index) * 0.13)
		draw_arc(center, ring_radius, -PI * 0.12, TAU - PI * 0.12, 84, Color(fel_infusion_edge_color.r, fel_infusion_edge_color.g, fel_infusion_edge_color.b, alpha), 2.5, true)

	for index in range(7):
		var angle := -PI * 0.85 + float(index) * PI * 1.70 / 6.0
		var from_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.20
		var bend_point := center + Vector2(cos(angle), sin(angle)) * radius * 0.66 + Vector2(-sin(angle), cos(angle)) * sin(float(index) * 1.9) * 7.0
		var to_point := center + Vector2(cos(angle), sin(angle)) * radius * 1.02
		draw_line(from_point, bend_point, fel_infusion_flame_color, 2.4)
		draw_line(bend_point, to_point, Color(fel_infusion_flame_color.r, fel_infusion_flame_color.g, fel_infusion_flame_color.b, 0.48), 1.8)


func draw_fel_overload_overlay() -> void:
	var overload_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.035)
	var center := overload_rect.get_center()
	var radius := minf(overload_rect.size.x, overload_rect.size.y) * 0.42

	draw_rect(overload_rect, fel_overload_color, true)
	for index in range(4):
		var alpha := fel_overload_edge_color.a * (1.0 - float(index) * 0.16)
		draw_arc(center, radius + float(index) * 3.8, PI * 0.08, TAU + PI * 0.08, 90, Color(fel_overload_edge_color.r, fel_overload_edge_color.g, fel_overload_edge_color.b, alpha), 2.4, true)

	var crack_points := [
		[Vector2(0.50, 0.12), Vector2(0.44, 0.34), Vector2(0.55, 0.50), Vector2(0.48, 0.78)],
		[Vector2(0.24, 0.24), Vector2(0.38, 0.38), Vector2(0.28, 0.58)],
		[Vector2(0.76, 0.22), Vector2(0.62, 0.42), Vector2(0.72, 0.64)],
	]
	for crack in crack_points:
		for point_index in range(crack.size() - 1):
			var from_point: Vector2 = overload_rect.position + Vector2(overload_rect.size.x * crack[point_index].x, overload_rect.size.y * crack[point_index].y)
			var to_point: Vector2 = overload_rect.position + Vector2(overload_rect.size.x * crack[point_index + 1].x, overload_rect.size.y * crack[point_index + 1].y)
			draw_line(from_point, to_point, fel_overload_crack_color, 2.6)
			draw_line(from_point, to_point, Color(0.0, 0.10, 0.0, 0.52), 1.0)

	draw_circle(center, radius * 0.18, Color(fel_overload_crack_color.r, fel_overload_crack_color.g, fel_overload_crack_color.b, 0.44))


func draw_fel_madness_overlay() -> void:
	var madness_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := madness_rect.get_center()
	var radius := minf(madness_rect.size.x, madness_rect.size.y) * 0.34
	var status := get_fel_madness_status()
	var stack_count := status.stacks if status != null else 1
	var claw_count: int = mini(maxi(stack_count + 2, 3), 6)

	draw_rect(madness_rect, fel_madness_color, true)
	draw_circle(center, radius * 0.98, Color(0.03, 0.0, 0.04, 0.20))
	for index in range(3):
		var grow := float(index) * 4.0
		var alpha := fel_madness_edge_color.a * (1.0 - float(index) * 0.18)
		draw_rect(madness_rect.grow(grow), Color(fel_madness_edge_color.r, fel_madness_edge_color.g, fel_madness_edge_color.b, alpha), false, maxf(size.x * 0.020, 2.0), true)

	for index in range(claw_count):
		var x := madness_rect.position.x + madness_rect.size.x * (0.22 + float(index) * 0.56 / float(maxi(claw_count - 1, 1)))
		var top := center.y - radius * (0.56 + 0.10 * float(index % 2))
		var bottom := center.y + radius * 0.58
		var claw_from := Vector2(x - radius * 0.10, top)
		var claw_to := Vector2(x + radius * 0.08, bottom)
		draw_line(claw_from, claw_to, Color(0.04, 0.0, 0.02, 0.70), 4.0)
		draw_line(claw_from, claw_to, fel_madness_rune_color, 2.2)
		draw_line(Vector2(x - radius * 0.02, top + radius * 0.18), Vector2(x + radius * 0.16, bottom - radius * 0.10), Color(fel_madness_edge_color.r, fel_madness_edge_color.g, fel_madness_edge_color.b, 0.40), 1.4)

	for index in range(5):
		var angle := TAU * float(index) / 5.0 - PI * 0.38
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.28
		var outer := center + Vector2(cos(angle), sin(angle)) * radius * 0.68
		draw_line(inner, outer, Color(0.42, 0.88, 0.12, 0.30), 1.5)

	draw_circle(center, radius * 0.18, Color(0.58, 0.92, 0.12, 0.30))
	draw_circle(center, radius * 0.08, Color(0.08, 0.0, 0.06, 0.58))


func draw_damage_amplify_overlay() -> void:
	var status := get_damage_amplify_status()
	if state == null:
		return

	var amplify_value: int = maxi(state.get_damage_amplify_bonus() if state != null else 0, 0)
	if amplify_value <= 0:
		return

	var curse_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.045)
	var center := curse_rect.get_center()
	var radius := minf(curse_rect.size.x, curse_rect.size.y) * 0.38
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 5)

	draw_rect(curse_rect, damage_amplify_color, true)
	for index in range(ring_count):
		var grow := float(index) * 4.0
		var alpha := damage_amplify_edge_color.a * (1.0 - float(index) * 0.14)
		draw_rect(
			curse_rect.grow(grow),
			Color(damage_amplify_edge_color.r, damage_amplify_edge_color.g, damage_amplify_edge_color.b, alpha),
			false,
			maxf(size.x * 0.020, 2.0),
			true
		)

	var crack_paths := [
		[Vector2(0.22, 0.18), Vector2(0.42, 0.38), Vector2(0.34, 0.62), Vector2(0.50, 0.82)],
		[Vector2(0.78, 0.16), Vector2(0.58, 0.36), Vector2(0.70, 0.58), Vector2(0.52, 0.76)],
		[Vector2(0.32, 0.30), Vector2(0.52, 0.48), Vector2(0.42, 0.66)]
	]
	for crack in crack_paths:
		for point_index in range(crack.size() - 1):
			var from_point: Vector2 = curse_rect.position + Vector2(curse_rect.size.x * crack[point_index].x, curse_rect.size.y * crack[point_index].y)
			var to_point: Vector2 = curse_rect.position + Vector2(curse_rect.size.x * crack[point_index + 1].x, curse_rect.size.y * crack[point_index + 1].y)
			draw_line(from_point, to_point, damage_amplify_crack_color, maxf(size.x * 0.018, 1.8))
			draw_line(from_point, to_point, Color(0.04, 0.0, 0.06, 0.58), maxf(size.x * 0.008, 1.0))

	draw_arc(center, radius, -PI * 0.20, TAU - PI * 0.20, 72, damage_amplify_edge_color, maxf(size.x * 0.020, 2.0), true)
	draw_arc(center, radius * 0.68, PI * 0.18, TAU + PI * 0.18, 64, Color(damage_amplify_crack_color.r, damage_amplify_crack_color.g, damage_amplify_crack_color.b, 0.48), maxf(size.x * 0.014, 1.4), true)

	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := maxi(int(size.x * 0.18), 18)
	var text := "+%d" % amplify_value
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var text_position := center - text_size * 0.5 + Vector2(0.0, text_size.y * 0.78)
	draw_string(font, text_position + Vector2(2.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, damage_amplify_shadow_color)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, damage_amplify_text_color)


func get_damage_amplify_status() -> CardStatus:
	if state == null:
		return null

	for status in state.statuses:
		if status == null:
			continue
		if int(status.payload.get(EffectData.KEY_DAMAGE_AMPLIFY, 0)) > 0:
			return status

	return null


func get_fel_madness_status() -> CardStatus:
	if state == null:
		return null

	var chaos_orc_status := state.get_status(CardStatus.STATUS_FEL_MADNESS_CHAOS_ORC)
	if chaos_orc_status != null:
		return chaos_orc_status

	var hellhound_status := state.get_status(CardStatus.STATUS_FEL_MADNESS_HELLHOUND)
	if hellhound_status != null:
		return hellhound_status

	var succubus_status := state.get_status(CardStatus.STATUS_FEL_MADNESS_SUCCUBUS)
	if succubus_status != null:
		return succubus_status

	var wolf_rider_status := state.get_status(CardStatus.STATUS_FEL_MADNESS_CHAOS_WOLF_RIDER)
	if wolf_rider_status != null:
		return wolf_rider_status

	var warlock_status := state.get_status(CardStatus.STATUS_FEL_MADNESS_WARLOCK)
	if warlock_status != null:
		return warlock_status

	return state.get_status(CardStatus.STATUS_FEL_MADNESS_DOOMGUARD)


func draw_divine_shield() -> void:
	var shield_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.07)
	var pulse := 0.5 + 0.5 * sin(animation_time * 2.8)
	var edge_alpha := 0.72 + pulse * 0.18
	var points := PackedVector2Array([
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.50, shield_rect.position.y + shield_rect.size.y * 0.04),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.88, shield_rect.position.y + shield_rect.size.y * 0.17),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.82, shield_rect.position.y + shield_rect.size.y * 0.66),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.50, shield_rect.position.y + shield_rect.size.y * 0.94),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.18, shield_rect.position.y + shield_rect.size.y * 0.66),
		Vector2(shield_rect.position.x + shield_rect.size.x * 0.12, shield_rect.position.y + shield_rect.size.y * 0.17)
	])

	draw_shield_glow(
		points,
		6,
		7.0 + pulse * 2.0,
		Color(
			divine_shield_glow_color.r,
			divine_shield_glow_color.g,
			divine_shield_glow_color.b,
			divine_shield_glow_color.a + pulse * 0.10
		)
	)
	draw_colored_polygon(points, divine_shield_color)
	draw_polyline(
		points,
		Color(
			divine_shield_edge_color.r,
			divine_shield_edge_color.g,
			divine_shield_edge_color.b,
			edge_alpha
		),
		4.0,
		true
	)
	draw_polyline(PackedVector2Array([points[5], points[0], points[1]]), Color(1.0, 0.98, 0.70, 0.95), 6.0, true)

	var center := shield_rect.get_center()
	var ray_color := Color(1.0, 0.95, 0.56, 0.22)
	draw_line(Vector2(center.x, shield_rect.position.y + shield_rect.size.y * 0.18), Vector2(center.x, shield_rect.position.y + shield_rect.size.y * 0.78), ray_color, 2.0)
	draw_line(Vector2(shield_rect.position.x + shield_rect.size.x * 0.28, center.y), Vector2(shield_rect.position.x + shield_rect.size.x * 0.72, center.y), ray_color, 2.0)

	for strand_index in range(3):
		var strand := PackedVector2Array()
		for step in range(11):
			var t := float(step) / 10.0
			var y := shield_rect.position.y + shield_rect.size.y * (0.22 + t * 0.56)
			var width_at_y := shield_rect.size.x * (0.24 - absf(t - 0.5) * 0.18)
			var x := (
				center.x
				+ sin(t * TAU * 1.25 + animation_time * 2.1 + float(strand_index) * 2.0)
				* width_at_y
			)
			strand.append(Vector2(x, y))
		draw_polyline(strand, Color(1.0, 0.92, 0.32, 0.20), 1.8, true)

	for mote_index in range(8):
		var angle := animation_time * 1.6 + TAU * float(mote_index) / 8.0
		var orbit := Vector2(cos(angle), sin(angle)) * shield_rect.size * Vector2(0.38, 0.43)
		var mote_position := center + orbit
		draw_circle(mote_position, 3.8, Color(1.0, 0.82, 0.18, 0.12))
		draw_circle(mote_position, 1.6, Color(1.0, 0.96, 0.58, 0.84))


func draw_bronze_head_iron_arms() -> void:
	var armor_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.055)
	var center := armor_rect.get_center()
	var status := state.get_status(CardStatus.STATUS_BRONZE_HEAD_IRON_ARMS) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 5)
	var edge_width := maxf(size.x * 0.023, 2.0)

	draw_rect(armor_rect, bronze_iron_color, true)
	for index in range(ring_count):
		var grow := float(index) * 3.8
		var alpha := bronze_iron_edge_color.a * (1.0 - float(index) * 0.12)
		draw_rect(
			armor_rect.grow(grow),
			Color(bronze_iron_edge_color.r, bronze_iron_edge_color.g, bronze_iron_edge_color.b, alpha),
			false,
			edge_width,
			true
		)

	var plate_height := armor_rect.size.y * 0.18
	for index in range(3):
		var y := armor_rect.position.y + armor_rect.size.y * (0.28 + float(index) * 0.16)
		var left := armor_rect.position.x + armor_rect.size.x * 0.22
		var right := armor_rect.position.x + armor_rect.size.x * 0.78
		draw_line(Vector2(left, y), Vector2(right, y + plate_height * 0.18), bronze_iron_plate_color, maxf(size.x * 0.035, 3.0))

	var rivet_count := mini(maxi(stack_count + 1, 2), 6)
	for index in range(rivet_count):
		var angle := TAU * float(index) / float(rivet_count) - PI * 0.5
		var point := center + Vector2(cos(angle), sin(angle)) * minf(armor_rect.size.x, armor_rect.size.y) * 0.34
		draw_circle(point, maxf(size.x * 0.014, 2.2), bronze_iron_rivet_color)

	draw_arc(center, minf(armor_rect.size.x, armor_rect.size.y) * 0.40, -PI * 0.18, TAU - PI * 0.18, 72, bronze_iron_edge_color, 2.2, true)


func draw_immortal_peach_overlay() -> void:
	var peach_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := peach_rect.get_center()
	var status := state.get_status(CardStatus.STATUS_IMMORTAL_PEACH) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 5)
	var radius := minf(peach_rect.size.x, peach_rect.size.y) * 0.34

	draw_circle(center, radius * 1.02, immortal_peach_color)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 4.4
		var alpha := immortal_peach_edge_color.a * (1.0 - float(index) * 0.13)
		draw_arc(center, ring_radius, -PI * 0.35, TAU - PI * 0.35, 80, Color(immortal_peach_edge_color.r, immortal_peach_edge_color.g, immortal_peach_edge_color.b, alpha), 2.2, true)

	var fruit_count := mini(maxi(stack_count, 1), 6)
	for index in range(fruit_count):
		var angle := TAU * float(index) / float(fruit_count) - PI * 0.5
		var fruit_center := center + Vector2(cos(angle), sin(angle)) * radius * 0.82
		var fruit_radius := maxf(size.x * 0.018, 2.4)
		draw_circle(fruit_center, fruit_radius, immortal_peach_core_color)
		draw_circle(fruit_center + Vector2(fruit_radius * 0.42, -fruit_radius * 0.25), fruit_radius * 0.46, Color(1.0, 0.50, 0.64, 0.74))
		draw_line(fruit_center + Vector2(0.0, -fruit_radius * 0.92), fruit_center + Vector2(fruit_radius * 0.78, -fruit_radius * 1.55), immortal_peach_leaf_color, 1.5)

	var leaf_left := center + Vector2(-radius * 0.28, -radius * 0.82)
	var leaf_right := center + Vector2(radius * 0.28, -radius * 0.82)
	draw_line(center + Vector2(0.0, -radius * 0.50), leaf_left, immortal_peach_leaf_color, 2.4)
	draw_line(center + Vector2(0.0, -radius * 0.50), leaf_right, immortal_peach_leaf_color, 2.4)


func draw_rooted_overlay() -> void:
	var root_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := root_rect.get_center()
	var edge_width := maxf(size.x * 0.023, 2.0)

	draw_rect(root_rect, rooted_color, true)
	draw_rect(root_rect, rooted_edge_color, false, edge_width, true)

	var glow_radius := minf(root_rect.size.x, root_rect.size.y) * 0.44
	for index in range(3):
		var alpha := 0.15 - float(index) * 0.035
		draw_circle(center, glow_radius * (1.0 + float(index) * 0.18), Color(rooted_edge_color.r, rooted_edge_color.g, rooted_edge_color.b, alpha))

	var seal_rect := Rect2(Vector2.ZERO, Vector2(root_rect.size.x * 0.52, root_rect.size.x * 0.52))
	seal_rect.position = center - seal_rect.size * 0.5
	draw_rect(seal_rect, Color(0.48, 0.22, 0.02, 0.30), true)
	draw_rect(seal_rect, rooted_seal_color, false, maxf(size.x * 0.018, 1.8), true)

	draw_rooted_seal_text(center)


func draw_rooted_seal_text(center: Vector2) -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	var text := "定"
	var font_size := maxi(int(size.x * 0.34), 18)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var text_position := center - text_size * 0.5
	text_position.y += text_size.y * 0.82

	draw_string(font, text_position + Vector2(maxf(size.x * 0.012, 1.3), maxf(size.x * 0.012, 1.3)), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, rooted_seal_shadow_color)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, rooted_seal_color)


func draw_stealth_overlay() -> void:
	var stealth_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.045)
	var center := stealth_rect.get_center()
	var edge_width := maxf(size.x * 0.018, 1.8)

	draw_rect(stealth_rect, stealth_color, true)
	draw_rect(stealth_rect, stealth_edge_color, false, edge_width, true)

	for index in range(7):
		var t := float(index) / 6.0
		var x := lerpf(stealth_rect.position.x + stealth_rect.size.x * 0.12, stealth_rect.position.x + stealth_rect.size.x * 0.88, t)
		var mist_top := Vector2(x - stealth_rect.size.x * 0.10, stealth_rect.position.y + stealth_rect.size.y * 0.18)
		var mist_bottom := Vector2(x + stealth_rect.size.x * 0.10, stealth_rect.position.y + stealth_rect.size.y * 0.82)
		var alpha := stealth_mist_color.a * (0.42 + 0.38 * sin(t * PI))
		draw_line(mist_top, mist_bottom, Color(stealth_mist_color.r, stealth_mist_color.g, stealth_mist_color.b, alpha), maxf(size.x * 0.016, 1.5))

	for index in range(3):
		var radius := minf(stealth_rect.size.x, stealth_rect.size.y) * (0.24 + float(index) * 0.09)
		var alpha := stealth_edge_color.a * (0.42 - float(index) * 0.08)
		draw_arc(center, radius, -PI * 0.18, TAU - PI * 0.18, 72, Color(stealth_edge_color.r, stealth_edge_color.g, stealth_edge_color.b, alpha), 1.8, true)


func draw_shield_glow(points: PackedVector2Array, steps: int, spacing: float, color: Color) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())

	for step in range(steps, 0, -1):
		var grown := PackedVector2Array()
		var grow_amount := float(step) * spacing
		for point in points:
			grown.append(point + (point - center).normalized() * grow_amount)
		var alpha := color.a * pow(1.0 - float(step) / float(steps + 1), 1.3)
		draw_polyline(grown, Color(color.r, color.g, color.b, alpha), 5.0, true)


func draw_freeze_overlay() -> void:
	var freeze_rect := Rect2(Vector2.ZERO, size)
	var border_width := size.x * 0.06

	# Ice-blue border overlay
	var border_color := Color(freeze_ice_edge_color.r, freeze_ice_edge_color.g, freeze_ice_edge_color.b, freeze_ice_edge_color.a)
	var inner_border_width := border_width * 0.6
	draw_rect(freeze_rect, freeze_ice_color, true)
	draw_rect(freeze_rect, border_color, false, border_width)
	draw_rect(freeze_rect.grow(-border_width), Color(border_color.r, border_color.g, border_color.b, border_color.a * 0.45), false, inner_border_width)

	# Ice crystal pattern in the center
	var center := freeze_rect.get_center()
	var crystal_size := minf(freeze_rect.size.x, freeze_rect.size.y) * 0.19
	var crystal_color := Color(border_color.r, border_color.g, border_color.b, border_color.a * 0.62)
	var crystal_glow := Color(freeze_ice_glow_color.r, freeze_ice_glow_color.g, freeze_ice_glow_color.b, freeze_ice_glow_color.a * 0.40)

	# Draw a snowflake-like symbol
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var dir := Vector2(cos(angle), sin(angle))
		var outer_point := center + dir * crystal_size
		var branch_angle := angle + PI * 0.32
		var branch_dir := Vector2(cos(branch_angle), sin(branch_angle))
		var branch_mid := center + dir * crystal_size * 0.55
		draw_line(center, outer_point, crystal_color, 3.0)
		draw_line(branch_mid, branch_mid + branch_dir * crystal_size * 0.32, crystal_color, 2.2)
		var opposite_branch_dir := Vector2(cos(branch_angle - PI * 0.64), sin(branch_angle - PI * 0.64))
		draw_line(branch_mid, branch_mid + opposite_branch_dir * crystal_size * 0.32, crystal_color, 2.2)

	draw_circle(center, crystal_size * 0.12, crystal_glow)


func draw_precision_shot_overlay() -> void:
	var aim_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.08)
	var center := aim_rect.get_center()
	var radius := minf(aim_rect.size.x, aim_rect.size.y) * 0.28
	var status := state.get_status(CardStatus.STATUS_PRECISION_SHOT) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)

	draw_rect(aim_rect, precision_shot_color, true)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 5.0
		var alpha := precision_shot_edge_color.a * (1.0 - float(index) * 0.14)
		draw_arc(center, ring_radius, 0.0, TAU, 72, Color(precision_shot_edge_color.r, precision_shot_edge_color.g, precision_shot_edge_color.b, alpha), 2.5, true)

	var line_length := radius * 1.55
	var gap := radius * 0.34
	draw_line(center + Vector2(-line_length, 0), center + Vector2(-gap, 0), precision_shot_mark_color, 2.4)
	draw_line(center + Vector2(gap, 0), center + Vector2(line_length, 0), precision_shot_mark_color, 2.4)
	draw_line(center + Vector2(0, -line_length), center + Vector2(0, -gap), precision_shot_mark_color, 2.4)
	draw_line(center + Vector2(0, gap), center + Vector2(0, line_length), precision_shot_mark_color, 2.4)
	draw_circle(center, radius * 0.13, precision_shot_mark_color)


func draw_soul_hook_overlay() -> void:
	var hook_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := hook_rect.get_center()
	var edge_width := maxf(size.x * 0.024, 2.0)
	var status := state.get_status(CardStatus.STATUS_SOUL_HOOK) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 3)

	draw_rect(hook_rect, soul_hook_color, true)
	for index in range(ring_count):
		var grow := float(index) * 4.0
		var alpha := soul_hook_edge_color.a * (1.0 - float(index) * 0.14)
		draw_rect(hook_rect.grow(grow), Color(soul_hook_edge_color.r, soul_hook_edge_color.g, soul_hook_edge_color.b, alpha), false, edge_width, true)

	var left_anchor := center + Vector2(-hook_rect.size.x * 0.28, -hook_rect.size.y * 0.16)
	var right_anchor := center + Vector2(hook_rect.size.x * 0.28, hook_rect.size.y * 0.16)
	var chain_points := PackedVector2Array()
	for index in range(9):
		var t := float(index) / 8.0
		var x := lerpf(left_anchor.x, right_anchor.x, t)
		var y := lerpf(left_anchor.y, right_anchor.y, t) + sin(t * TAU * 1.4) * hook_rect.size.y * 0.055
		chain_points.append(Vector2(x, y))

	draw_polyline(chain_points, soul_hook_chain_color, 2.8, false)
	for point in chain_points:
		draw_circle(point, 2.1, Color(soul_hook_edge_color.r, soul_hook_edge_color.g, soul_hook_edge_color.b, 0.52))

	var hook_tip := center + Vector2(hook_rect.size.x * 0.18, -hook_rect.size.y * 0.24)
	draw_arc(hook_tip, hook_rect.size.x * 0.08, PI * 0.20, PI * 1.62, 18, soul_hook_edge_color, 2.8, true)
	draw_line(hook_tip + Vector2(-hook_rect.size.x * 0.04, hook_rect.size.y * 0.055), hook_tip + Vector2(-hook_rect.size.x * 0.12, hook_rect.size.y * 0.13), soul_hook_edge_color, 2.4)


func draw_charm_overlay() -> void:
	var charm_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.045)
	var center := charm_rect.get_center()
	var radius := minf(charm_rect.size.x, charm_rect.size.y) * 0.38

	draw_rect(charm_rect, charm_color, true)
	for index in range(3):
		var grow := float(index) * 3.5
		var alpha := charm_edge_color.a * (1.0 - float(index) * 0.18)
		draw_rect(charm_rect.grow(grow), Color(charm_edge_color.r, charm_edge_color.g, charm_edge_color.b, alpha), false, maxf(size.x * 0.018, 2.0), true)

	for index in range(6):
		var angle := TAU * float(index) / 6.0 + PI * 0.18
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(point, maxf(size.x * 0.012, 2.0), charm_rune_color)
		draw_line(center.lerp(point, 0.74), point, Color(charm_edge_color.r, charm_edge_color.g, charm_edge_color.b, 0.42), 1.4)

	var heart_top := center + Vector2(0, -radius * 0.18)
	draw_circle(heart_top + Vector2(-radius * 0.13, 0), radius * 0.12, charm_rune_color)
	draw_circle(heart_top + Vector2(radius * 0.13, 0), radius * 0.12, charm_rune_color)
	var points := PackedVector2Array([
		heart_top + Vector2(-radius * 0.25, radius * 0.03),
		heart_top + Vector2(radius * 0.25, radius * 0.03),
		heart_top + Vector2(0, radius * 0.34)
	])
	draw_polygon(points, PackedColorArray([charm_rune_color, charm_rune_color, charm_rune_color]))


func draw_reborn_overlay() -> void:
	var reborn_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.07)
	var center := reborn_rect.get_center()
	var radius := minf(reborn_rect.size.x, reborn_rect.size.y) * 0.34
	var reborn_count: int = state.get_reborn_count() if state != null else 0
	var ring_count: int = mini(maxi(reborn_count, 1), 5)

	draw_circle(center, radius * 0.84, reborn_color)
	for index in range(ring_count):
		var ring_radius := radius + float(index) * 4.2
		var alpha := reborn_edge_color.a * (1.0 - float(index) * 0.12)
		draw_arc(center, ring_radius, -PI * 0.5, TAU - PI * 0.5, 88, Color(reborn_edge_color.r, reborn_edge_color.g, reborn_edge_color.b, alpha), 2.4, true)

	for index in range(ring_count):
		var angle := TAU * float(index) / float(ring_count) - PI * 0.5
		var point := center + Vector2(cos(angle), sin(angle)) * radius * 0.90
		draw_circle(point, maxf(size.x * 0.018, 2.5), reborn_core_color)

	var wing_span := radius * 0.46
	var wing_top := center + Vector2(0.0, -radius * 0.10)
	draw_line(wing_top, wing_top + Vector2(-wing_span, -radius * 0.18), reborn_core_color, 2.4)
	draw_line(wing_top, wing_top + Vector2(wing_span, -radius * 0.18), reborn_core_color, 2.4)
	draw_line(wing_top + Vector2(-wing_span, -radius * 0.18), center + Vector2(-wing_span * 0.36, radius * 0.22), Color(reborn_core_color.r, reborn_core_color.g, reborn_core_color.b, 0.62), 1.8)
	draw_line(wing_top + Vector2(wing_span, -radius * 0.18), center + Vector2(wing_span * 0.36, radius * 0.22), Color(reborn_core_color.r, reborn_core_color.g, reborn_core_color.b, 0.62), 1.8)


func draw_encourage_gu_overlay() -> void:
	var gu_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.05)
	var center := gu_rect.get_center()
	var status := state.get_status(CardStatus.STATUS_ENCOURAGE_GU) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var pulse_count: int = mini(maxi(stack_count, 1), 5)
	var edge_width := maxf(size.x * 0.025, 2.0)

	for index in range(pulse_count):
		var grow := float(index) * 4.0
		var pulse_alpha := encourage_gu_edge_color.a * (1.0 - float(index) * 0.12)
		draw_rect(gu_rect.grow(grow), Color(encourage_gu_edge_color.r, encourage_gu_edge_color.g, encourage_gu_edge_color.b, pulse_alpha), false, edge_width, true)

	draw_rect(gu_rect, encourage_gu_color, true)
	draw_gu_veins(center, gu_rect)
	draw_gu_insects(center, gu_rect, pulse_count)


func draw_gu_veins(center: Vector2, gu_rect: Rect2) -> void:
	var vein_count := 7
	var vein_length := minf(gu_rect.size.x, gu_rect.size.y) * 0.35
	for index in range(vein_count):
		var angle := -PI * 0.78 + float(index) * PI * 1.56 / float(vein_count - 1)
		var dir := Vector2(cos(angle), sin(angle))
		var start := center + dir * vein_length * 0.18
		var mid := center + dir * vein_length * 0.55 + Vector2(-dir.y, dir.x) * sin(float(index) * 1.7) * 7.0
		var end := center + dir * vein_length
		draw_line(start, mid, encourage_gu_venom_color, 2.2)
		draw_line(mid, end, Color(encourage_gu_venom_color.r, encourage_gu_venom_color.g, encourage_gu_venom_color.b, encourage_gu_venom_color.a * 0.72), 1.7)


func draw_gu_insects(center: Vector2, gu_rect: Rect2, count: int) -> void:
	var orbit_radius := minf(gu_rect.size.x, gu_rect.size.y) * 0.39
	var insect_count := mini(count + 2, 7)
	for index in range(insect_count):
		var angle := TAU * float(index) / float(insect_count) + 0.34
		var pos := center + Vector2(cos(angle), sin(angle)) * orbit_radius
		var wing_dir := Vector2(-sin(angle), cos(angle))
		draw_circle(pos, 2.4, encourage_gu_insect_color)
		draw_line(pos - wing_dir * 3.0, pos + wing_dir * 3.0, Color(encourage_gu_insect_color.r, encourage_gu_insect_color.g, encourage_gu_insect_color.b, 0.42), 1.4)


func draw_snake_venom_overlay() -> void:
	var venom_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := venom_rect.get_center()
	var edge_width := maxf(size.x * 0.026, 2.0)
	var status := state.get_status(CardStatus.STATUS_SNAKE_VENOM) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)

	draw_rect(venom_rect, snake_venom_color, true)
	for index in range(ring_count):
		var grow := float(index) * 5.0
		var alpha := snake_venom_edge_color.a * (1.0 - float(index) * 0.15)
		draw_rect(venom_rect.grow(grow), Color(snake_venom_edge_color.r, snake_venom_edge_color.g, snake_venom_edge_color.b, alpha), false, edge_width, true)

	var fang_height := venom_rect.size.y * 0.28
	var fang_width := venom_rect.size.x * 0.10
	var left_fang_x := center.x - venom_rect.size.x * 0.15
	var right_fang_x := center.x + venom_rect.size.x * 0.15
	var fang_top := venom_rect.position.y + venom_rect.size.y * 0.22
	draw_fang(Vector2(left_fang_x, fang_top), fang_width, fang_height)
	draw_fang(Vector2(right_fang_x, fang_top), fang_width, fang_height)

	for index in range(5):
		var t := float(index) / 4.0
		var drop_x := venom_rect.position.x + venom_rect.size.x * (0.28 + t * 0.44)
		var drop_y := venom_rect.position.y + venom_rect.size.y * (0.60 + sin(t * TAU) * 0.06)
		draw_circle(Vector2(drop_x, drop_y), 2.2 + float(index % 2), Color(snake_venom_fang_color.r, snake_venom_fang_color.g, snake_venom_fang_color.b, 0.56))


func draw_life_link_larva_overlay() -> void:
	var larva_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.08)
	var center := larva_rect.get_center()
	var edge_width := maxf(size.x * 0.020, 2.0)
	var status := state.get_status(CardStatus.STATUS_LIFE_LINK_LARVA) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 3)

	draw_rect(larva_rect, life_link_larva_color, true)
	for index in range(ring_count):
		var grow := float(index) * 3.5
		var alpha := life_link_larva_edge_color.a * (1.0 - float(index) * 0.18)
		draw_rect(larva_rect.grow(grow), Color(life_link_larva_edge_color.r, life_link_larva_edge_color.g, life_link_larva_edge_color.b, alpha), false, edge_width, true)

	var cocoon_radius := minf(larva_rect.size.x, larva_rect.size.y) * 0.18
	var cocoon_center := center + Vector2(0.0, -larva_rect.size.y * 0.02)
	draw_circle(cocoon_center, cocoon_radius * 1.12, Color(life_link_larva_core_color.r, life_link_larva_core_color.g, life_link_larva_core_color.b, 0.18))
	draw_arc(cocoon_center, cocoon_radius, -PI * 0.15, TAU - PI * 0.15, 36, life_link_larva_core_color, maxf(size.x * 0.018, 1.8), true)
	draw_line(cocoon_center + Vector2(-cocoon_radius * 0.82, -cocoon_radius * 0.28), cocoon_center + Vector2(cocoon_radius * 0.78, cocoon_radius * 0.30), Color(life_link_larva_core_color.r, life_link_larva_core_color.g, life_link_larva_core_color.b, 0.58), 2.0)
	draw_line(cocoon_center + Vector2(-cocoon_radius * 0.62, cocoon_radius * 0.36), cocoon_center + Vector2(cocoon_radius * 0.66, -cocoon_radius * 0.34), Color(life_link_larva_core_color.r, life_link_larva_core_color.g, life_link_larva_core_color.b, 0.46), 1.6)

	for index in range(6):
		var angle := TAU * float(index) / 6.0 + 0.34
		var point := center + Vector2(cos(angle), sin(angle)) * minf(larva_rect.size.x, larva_rect.size.y) * 0.30
		draw_circle(point, maxf(size.x * 0.012, 2.0), Color(life_link_larva_core_color.r, life_link_larva_core_color.g, life_link_larva_core_color.b, 0.54))


func draw_life_link_overlay() -> void:
	var link_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.07)
	var center := link_rect.get_center()
	var edge_width := maxf(size.x * 0.022, 2.0)
	var status := state.get_status(CardStatus.STATUS_LIFE_LINK) if state != null else null
	var stack_count := status.stacks if status != null else 1
	var ring_count: int = mini(maxi(stack_count, 1), 4)

	draw_rect(link_rect, life_link_color, true)
	for index in range(ring_count):
		var grow := float(index) * 4.0
		var alpha := life_link_edge_color.a * (1.0 - float(index) * 0.14)
		draw_rect(link_rect.grow(grow), Color(life_link_edge_color.r, life_link_edge_color.g, life_link_edge_color.b, alpha), false, edge_width, true)

	var left_anchor := center + Vector2(-link_rect.size.x * 0.20, -link_rect.size.y * 0.02)
	var right_anchor := center + Vector2(link_rect.size.x * 0.20, -link_rect.size.y * 0.02)
	draw_circle(left_anchor, size.x * 0.045, life_link_thread_color)
	draw_circle(right_anchor, size.x * 0.045, life_link_thread_color)

	var thread_points := PackedVector2Array()
	for index in range(9):
		var t := float(index) / 8.0
		var x := lerpf(left_anchor.x, right_anchor.x, t)
		var y := lerpf(left_anchor.y, right_anchor.y, t) + sin(t * TAU * 1.5) * size.y * 0.035
		thread_points.append(Vector2(x, y))
	draw_polyline(thread_points, life_link_thread_color, 2.4, false)

	var lower_points := PackedVector2Array()
	for index in range(9):
		var t := float(index) / 8.0
		var x := lerpf(left_anchor.x, right_anchor.x, t)
		var y := lerpf(left_anchor.y, right_anchor.y, t) - sin(t * TAU * 1.5) * size.y * 0.035 + size.y * 0.07
		lower_points.append(Vector2(x, y))
	draw_polyline(lower_points, Color(life_link_thread_color.r, life_link_thread_color.g, life_link_thread_color.b, life_link_thread_color.a * 0.70), 1.8, false)


func draw_death_immunity_overlay() -> void:
	var burial_rect := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
	var center := burial_rect.get_center()
	var edge_width := maxf(size.x * 0.026, 2.0)
	var status := state.get_status(CardStatus.STATUS_DEATH_IMMUNITY) if state != null else null
	var remaining_turns := status.remaining_turns if status != null else 0
	var ring_count: int = mini(maxi(remaining_turns, 1), 4)

	draw_rect(burial_rect, death_immunity_color, true)
	for index in range(ring_count):
		var grow := float(index) * 4.0
		var alpha := death_immunity_edge_color.a * (1.0 - float(index) * 0.14)
		draw_rect(burial_rect.grow(grow), Color(death_immunity_edge_color.r, death_immunity_edge_color.g, death_immunity_edge_color.b, alpha), false, edge_width, true)

	var shroud_top := burial_rect.position.y + burial_rect.size.y * 0.18
	var shroud_bottom := burial_rect.position.y + burial_rect.size.y * 0.82
	var shroud_width := burial_rect.size.x * 0.34
	var shroud_points := PackedVector2Array([
		Vector2(center.x, shroud_top),
		Vector2(center.x + shroud_width * 0.45, shroud_top + burial_rect.size.y * 0.18),
		Vector2(center.x + shroud_width * 0.32, shroud_bottom),
		Vector2(center.x - shroud_width * 0.32, shroud_bottom),
		Vector2(center.x - shroud_width * 0.45, shroud_top + burial_rect.size.y * 0.18)
	])
	draw_colored_polygon(shroud_points, Color(0.08, 0.18, 0.07, 0.34))
	draw_polyline(shroud_points, death_immunity_edge_color, 2.6, true)

	for index in range(5):
		var t := float(index) / 4.0
		var x := lerpf(burial_rect.position.x + burial_rect.size.x * 0.24, burial_rect.position.x + burial_rect.size.x * 0.76, t)
		var y := center.y + sin(t * TAU) * burial_rect.size.y * 0.10
		draw_line(Vector2(x, y - burial_rect.size.y * 0.18), Vector2(x, y + burial_rect.size.y * 0.18), Color(death_immunity_thread_color.r, death_immunity_thread_color.g, death_immunity_thread_color.b, death_immunity_thread_color.a * (0.55 + t * 0.25)), 1.6)


func draw_fang(top_center: Vector2, fang_width: float, fang_height: float) -> void:
	var points := PackedVector2Array([
		top_center + Vector2(-fang_width, 0.0),
		top_center + Vector2(fang_width, 0.0),
		top_center + Vector2(0.0, fang_height)
	])
	draw_colored_polygon(points, Color(snake_venom_fang_color.r, snake_venom_fang_color.g, snake_venom_fang_color.b, 0.34))
	draw_polyline(PackedVector2Array([points[0], points[2], points[1]]), snake_venom_fang_color, 2.0, true)
