extends RefCounted
class_name CardAnimationController

# CardAnimationController 只负责卡牌相关的表现动画。
# 它可以移动、缩放、闪烁 Card 节点或创建临时特效节点，但不直接修改 CardState。
# 规则状态变化统一由 GameManager 在 await 动画之后处理。

var move_animation_duration := 0.24
var attack_animation_duration := 0.26
var attack_lunge_distance := 54.0
var attack_target_shake_distance := 8.0
var ranged_attack_animation_duration := 0.34
var ranged_attack_projectile_size := Vector2(30, 10)
var ranged_attack_projectile_color := Color(0.55, 0.88, 1.0, 0.94)
var ranged_attack_projectile_glow_color := Color(0.24, 0.64, 1.0, 0.32)
var spell_animation_duration := 0.32
var heal_spell_effect_color := Color(0.38, 1.0, 0.52, 0.46)
var heal_spell_effect_glow_color := Color(0.52, 1.0, 0.62, 0.58)
var shield_spell_effect_color := Color(0.34, 0.78, 1.0, 0.34)
var shield_spell_effect_glow_color := Color(0.52, 0.92, 1.0, 0.64)
var arcane_spell_effect_color := Color(0.48, 0.42, 1.0, 0.36)
var arcane_spell_effect_glow_color := Color(0.72, 0.64, 1.0, 0.62)
var summon_spell_effect_color := Color(0.20, 0.76, 1.0, 0.34)
var summon_spell_effect_glow_color := Color(0.62, 0.94, 1.0, 0.70)
var fireball_projectile_size := Vector2(34, 22)
var fireball_projectile_color := Color(1.0, 0.34, 0.08, 0.96)
var fireball_projectile_glow_color := Color(1.0, 0.72, 0.18, 0.58)
var fireball_impact_color := Color(1.35, 0.82, 0.42, 1.0)
var dark_arrow_projectile_size := Vector2(58, 18)
var dark_arrow_projectile_color := Color(0.03, 0.025, 0.055, 0.96)
var dark_arrow_projectile_glow_color := Color(0.42, 0.18, 0.72, 0.46)
var dark_arrow_impact_color := Color(0.60, 0.44, 0.92, 1.0)
var gu_projectile_size := Vector2(18, 10)
var gu_projectile_color := Color(0.09, 0.28, 0.08, 0.94)
var gu_projectile_glow_color := Color(0.44, 1.0, 0.20, 0.48)
var gu_impact_color := Color(0.58, 1.22, 0.34, 1.0)


func setup(config: Dictionary) -> void:
	move_animation_duration = float(config.get("move_animation_duration", move_animation_duration))
	attack_animation_duration = float(config.get("attack_animation_duration", attack_animation_duration))
	attack_lunge_distance = float(config.get("attack_lunge_distance", attack_lunge_distance))
	attack_target_shake_distance = float(config.get("attack_target_shake_distance", attack_target_shake_distance))
	ranged_attack_animation_duration = float(config.get("ranged_attack_animation_duration", ranged_attack_animation_duration))
	ranged_attack_projectile_size = config.get("ranged_attack_projectile_size", ranged_attack_projectile_size)
	ranged_attack_projectile_color = config.get("ranged_attack_projectile_color", ranged_attack_projectile_color)
	ranged_attack_projectile_glow_color = config.get("ranged_attack_projectile_glow_color", ranged_attack_projectile_glow_color)
	spell_animation_duration = float(config.get("spell_animation_duration", spell_animation_duration))
	heal_spell_effect_color = config.get("heal_spell_effect_color", heal_spell_effect_color)
	heal_spell_effect_glow_color = config.get("heal_spell_effect_glow_color", heal_spell_effect_glow_color)
	shield_spell_effect_color = config.get("shield_spell_effect_color", shield_spell_effect_color)
	shield_spell_effect_glow_color = config.get("shield_spell_effect_glow_color", shield_spell_effect_glow_color)
	arcane_spell_effect_color = config.get("arcane_spell_effect_color", arcane_spell_effect_color)
	arcane_spell_effect_glow_color = config.get("arcane_spell_effect_glow_color", arcane_spell_effect_glow_color)


func play_card_swap(
	owner: Node,
	first_card: Card,
	second_card: Card,
	first_slot_position: Vector2,
	second_slot_position: Vector2
) -> void:
	if owner == null or first_card == null or second_card == null:
		return

	var first_local_position: Vector2 = first_card.position
	var second_local_position: Vector2 = second_card.position
	var first_z_index: int = first_card.z_index
	var second_z_index: int = second_card.z_index

	first_card.is_animating = true
	second_card.is_animating = true
	first_card.set_as_top_level(true)
	second_card.set_as_top_level(true)
	first_card.z_index = 1000
	second_card.z_index = 1001
	first_card.global_position = second_slot_position
	second_card.global_position = first_slot_position

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(first_card, "global_position", first_slot_position, move_animation_duration)
	tween.tween_property(second_card, "global_position", second_slot_position, move_animation_duration)
	await tween.finished

	first_card.set_as_top_level(false)
	second_card.set_as_top_level(false)
	first_card.position = first_local_position
	second_card.position = second_local_position
	first_card.z_index = first_z_index
	second_card.z_index = second_z_index
	first_card.is_animating = false
	second_card.is_animating = false


func play_card_attack(owner: Node, root: Node, attacker_card: Card, target_card: Card, is_melee_attack := true) -> void:
	if is_melee_attack:
		await play_melee_attack(owner, attacker_card, target_card)
	else:
		await play_ranged_attack(owner, root, attacker_card, target_card)


func play_card_to_empty_slot(owner: Node, from_card: Card, to_card: Card) -> void:
	if owner == null or from_card == null or to_card == null:
		return

	from_card.is_animating = true
	var from_local_position: Vector2 = from_card.position
	var from_global_position: Vector2 = from_card.global_position
	var from_z_index: int = from_card.z_index
	var target_global_position: Vector2 = to_card.global_position

	from_card.set_as_top_level(true)
	from_card.global_position = from_global_position
	from_card.z_index = 1300

	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(from_card, "global_position", target_global_position, move_animation_duration)
	await tween.finished

	from_card.set_as_top_level(false)
	from_card.position = from_local_position
	from_card.z_index = from_z_index
	from_card.is_animating = false


func play_melee_attack(owner: Node, attacker_card: Card, target_card: Card) -> void:
	if owner == null or attacker_card == null or target_card == null:
		return

	var attacker_start_global_position: Vector2 = attacker_card.global_position
	var target_start_position: Vector2 = target_card.position
	var attacker_start_local_position: Vector2 = attacker_card.position
	var attacker_start_scale: Vector2 = attacker_card.scale
	var target_start_scale: Vector2 = target_card.scale
	var attacker_start_z_index: int = attacker_card.z_index
	var target_start_z_index: int = target_card.z_index
	var attack_vector: Vector2 = target_card.global_position - attacker_card.global_position

	if attack_vector.length() <= 0.01:
		return

	attacker_card.is_animating = true
	target_card.is_animating = true
	attacker_card.set_as_top_level(true)
	attacker_card.global_position = attacker_start_global_position
	attacker_card.z_index = 1200
	target_card.z_index = 1190

	var attack_direction: Vector2 = attack_vector.normalized()
	var lunge_distance: float = minf(attack_lunge_distance, attack_vector.length() * 0.42)
	var lunge_position: Vector2 = attacker_start_global_position + attack_direction * lunge_distance
	var target_shake_offset: Vector2 = attack_direction * attack_target_shake_distance
	var windup_duration: float = attack_animation_duration * 0.28
	var lunge_duration: float = attack_animation_duration * 0.32
	var recover_duration: float = attack_animation_duration * 0.40

	var windup_position: Vector2 = attacker_start_global_position - attack_direction * 8.0
	var windup_tween := owner.create_tween()
	windup_tween.set_parallel(true)
	windup_tween.set_trans(Tween.TRANS_SINE)
	windup_tween.set_ease(Tween.EASE_OUT)
	windup_tween.tween_property(attacker_card, "global_position", windup_position, windup_duration)
	windup_tween.tween_property(attacker_card, "scale", attacker_start_scale * 1.03, windup_duration)
	await windup_tween.finished

	var lunge_tween := owner.create_tween()
	lunge_tween.set_parallel(true)
	lunge_tween.set_trans(Tween.TRANS_QUAD)
	lunge_tween.set_ease(Tween.EASE_IN)
	lunge_tween.tween_property(attacker_card, "global_position", lunge_position, lunge_duration)
	lunge_tween.tween_property(attacker_card, "scale", attacker_start_scale * 1.07, lunge_duration)
	lunge_tween.tween_property(target_card, "position", target_start_position + target_shake_offset, lunge_duration)
	lunge_tween.tween_property(target_card, "scale", target_start_scale * 0.97, lunge_duration)
	await lunge_tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(attacker_card, "global_position", attacker_start_global_position, recover_duration)
	recover_tween.tween_property(attacker_card, "scale", attacker_start_scale, recover_duration)
	recover_tween.tween_property(target_card, "position", target_start_position, recover_duration)
	recover_tween.tween_property(target_card, "scale", target_start_scale, recover_duration)
	await recover_tween.finished

	attacker_card.set_as_top_level(false)
	attacker_card.position = attacker_start_local_position
	attacker_card.scale = attacker_start_scale
	target_card.position = target_start_position
	target_card.scale = target_start_scale
	attacker_card.z_index = attacker_start_z_index
	target_card.z_index = target_start_z_index
	attacker_card.is_animating = false
	target_card.is_animating = false


func play_ranged_attack(owner: Node, root: Node, attacker_card: Card, target_card: Card) -> void:
	if owner == null or root == null or attacker_card == null or target_card == null:
		return

	var attacker_start_scale: Vector2 = attacker_card.scale
	var target_start_position: Vector2 = target_card.position
	var target_start_scale: Vector2 = target_card.scale
	var target_start_modulate: Color = target_card.self_modulate
	var attacker_start_z_index: int = attacker_card.z_index
	var target_start_z_index: int = target_card.z_index
	var attacker_center: Vector2 = attacker_card.global_position + attacker_card.size * 0.5
	var target_center: Vector2 = target_card.global_position + target_card.size * 0.5
	var attack_vector: Vector2 = target_center - attacker_center

	if attack_vector.length() <= 0.01:
		return

	attacker_card.is_animating = true
	target_card.is_animating = true
	attacker_card.z_index = 1180
	target_card.z_index = 1190

	var attack_direction: Vector2 = attack_vector.normalized()
	var target_shake_offset: Vector2 = attack_direction * attack_target_shake_distance
	var charge_duration: float = ranged_attack_animation_duration * 0.22
	var flight_duration: float = ranged_attack_animation_duration * 0.56
	var impact_duration: float = ranged_attack_animation_duration * 0.22

	var charge_tween := owner.create_tween()
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(attacker_card, "scale", attacker_start_scale * 1.04, charge_duration)
	await charge_tween.finished

	var projectile := create_ranged_attack_projectile()
	root.add_child(projectile)
	projectile.rotation = attack_direction.angle()
	projectile.global_position = attacker_center - projectile.pivot_offset

	var flight_tween := owner.create_tween()
	flight_tween.set_parallel(true)
	flight_tween.set_trans(Tween.TRANS_CUBIC)
	flight_tween.set_ease(Tween.EASE_OUT)
	flight_tween.tween_property(projectile, "global_position", target_center - projectile.pivot_offset, flight_duration)
	flight_tween.tween_property(projectile, "scale", Vector2(1.25, 1.25), flight_duration)
	flight_tween.tween_property(attacker_card, "scale", attacker_start_scale, flight_duration)
	await flight_tween.finished

	var impact_tween := owner.create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_SINE)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(projectile, "modulate:a", 0.0, impact_duration)
	impact_tween.tween_property(projectile, "scale", Vector2(1.8, 1.8), impact_duration)
	impact_tween.tween_property(target_card, "position", target_start_position + target_shake_offset, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "scale", target_start_scale * 0.97, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "self_modulate", Color(1.25, 1.25, 1.0, 1.0), impact_duration * 0.5)
	await impact_tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "position", target_start_position, impact_duration)
	recover_tween.tween_property(target_card, "scale", target_start_scale, impact_duration)
	recover_tween.tween_property(target_card, "self_modulate", target_start_modulate, impact_duration)
	await recover_tween.finished

	projectile.queue_free()
	attacker_card.scale = attacker_start_scale
	target_card.position = target_start_position
	target_card.scale = target_start_scale
	target_card.self_modulate = target_start_modulate
	attacker_card.z_index = attacker_start_z_index
	target_card.z_index = target_start_z_index
	attacker_card.is_animating = false
	target_card.is_animating = false


func create_ranged_attack_projectile() -> Panel:
	var projectile := Panel.new()
	projectile.name = "RangedAttackProjectile"
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.custom_minimum_size = ranged_attack_projectile_size
	projectile.size = ranged_attack_projectile_size
	projectile.pivot_offset = ranged_attack_projectile_size * 0.5
	projectile.z_index = 1400
	projectile.add_theme_stylebox_override("panel", create_ranged_attack_projectile_style())
	return projectile


func create_ranged_attack_projectile_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ranged_attack_projectile_color
	style.border_color = ranged_attack_projectile_glow_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(ranged_attack_projectile_size.y * 0.5))
	style.shadow_color = ranged_attack_projectile_glow_color
	style.shadow_size = 14
	return style


func play_spell_cast(owner: Node, effect_root: Control, caster_card: Card, target_card: Card, spell_data: Dictionary) -> void:
	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"heal", "healing_spell":
			await play_heal_spell(owner, effect_root, target_card)
		"shield", "frost_shield":
			await play_shield_spell(owner, effect_root, target_card)
		"arcane", "arcane_wisdom":
			await play_arcane_spell(owner, effect_root, target_card)
		"arcane_aura":
			await play_arcane_aura_spell(owner, effect_root, target_card)
		"baptism":
			await play_baptism_spell(owner, effect_root, target_card)
		"fireball":
			await play_fireball_spell(owner, effect_root, caster_card, target_card)
		"pyroblast":
			await play_fireball_spell(owner, effect_root, caster_card, target_card, 1.65)
		"dark_arrow":
			if caster_card == null or target_card == null:
				return
			await play_dark_arrow_spell(owner, effect_root, caster_card.get_global_rect().get_center(), target_card)
		"gu_infusion":
			if caster_card == null or target_card == null:
				return
			await play_gu_infusion_spell(owner, effect_root, caster_card.get_global_rect().get_center(), target_card)
		_:
			await play_default_spell(owner, target_card)


func play_spell_cast_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, spell_data: Dictionary) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"heal", "healing_spell":
			await play_heal_spell_at_rect(owner, effect_root, target_rect)
		"shield", "frost_shield":
			await play_shield_spell_at_rect(owner, effect_root, target_rect)
		"arcane", "arcane_wisdom":
			await play_arcane_spell_at_rect(owner, effect_root, target_rect)
		"summon":
			await play_summon_spell_at_rect(owner, effect_root, target_rect)
		"arcane_aura":
			await play_arcane_aura_spell_at_rect(owner, effect_root, target_rect)
		"baptism":
			await play_baptism_spell_at_rect(owner, effect_root, target_rect)
		"gu_infusion":
			await play_gu_infusion_at_rect(owner, effect_root, target_rect)
		_:
			await play_default_spell_at_rect(owner, effect_root, target_rect)


func play_spell_cast_from_rect_to_card(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	spell_data: Dictionary
) -> void:
	if owner == null or effect_root == null or source_rect.size == Vector2.ZERO or target_card == null:
		return

	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"fireball":
			await play_fireball_from_point(owner, effect_root, source_rect.get_center(), target_card)
		"pyroblast":
			await play_fireball_from_point(owner, effect_root, source_rect.get_center(), target_card, 1.65)
		"dark_arrow":
			await play_dark_arrow_spell(owner, effect_root, source_rect.get_center(), target_card)
		"gu_infusion":
			await play_gu_infusion_spell(owner, effect_root, source_rect.get_center(), target_card)
		"baptism":
			await play_baptism_spell(owner, effect_root, target_card)
		_:
			await play_spell_cast(owner, effect_root, target_card, target_card, spell_data)


func play_default_spell(owner: Node, target_card: Card) -> void:
	if owner == null or target_card == null:
		return

	var start_scale: Vector2 = target_card.scale
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "scale", start_scale * 1.04, spell_animation_duration * 0.5)
	tween.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.5)
	await tween.finished
	target_card.scale = start_scale


func play_default_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var effect := create_rect_spell_effect(target_rect, "DefaultSpellEffect", create_arcane_spell_effect_style(), 1.10)
	effect_root.add_child(effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", Vector2(1.28, 1.28), spell_animation_duration)
	tween.tween_property(effect, "modulate:a", 0.0, spell_animation_duration)
	await tween.finished

	effect.queue_free()


func play_heal_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var heal_effect := create_heal_spell_effect(target_card)
	effect_root.add_child(heal_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "scale", start_scale * 1.07, spell_animation_duration * 0.42)
	tween.tween_property(heal_effect, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.42)
	tween.tween_property(heal_effect, "modulate:a", 0.95, spell_animation_duration * 0.42)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.55)
	recover_tween.tween_property(heal_effect, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.55)
	recover_tween.tween_property(heal_effect, "modulate:a", 0.0, spell_animation_duration * 0.55)
	await recover_tween.finished

	heal_effect.queue_free()
	target_card.scale = start_scale
	target_card.is_animating = false


func play_heal_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var heal_effect := create_heal_spell_effect_for_rect(target_rect)
	effect_root.add_child(heal_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(heal_effect, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.42)
	tween.tween_property(heal_effect, "modulate:a", 0.95, spell_animation_duration * 0.42)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(heal_effect, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.55)
	recover_tween.tween_property(heal_effect, "modulate:a", 0.0, spell_animation_duration * 0.55)
	await recover_tween.finished

	heal_effect.queue_free()


func play_shield_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var shield_effect := create_shield_spell_effect(target_card)
	effect_root.add_child(shield_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "scale", start_scale * 1.05, spell_animation_duration * 0.40)
	tween.tween_property(shield_effect, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.40)
	tween.tween_property(shield_effect, "modulate:a", 0.9, spell_animation_duration * 0.40)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.60)
	recover_tween.tween_property(shield_effect, "scale", Vector2(1.30, 1.30), spell_animation_duration * 0.60)
	recover_tween.tween_property(shield_effect, "modulate:a", 0.0, spell_animation_duration * 0.60)
	await recover_tween.finished

	shield_effect.queue_free()
	target_card.scale = start_scale
	target_card.is_animating = false


func play_shield_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var shield_effect := create_shield_spell_effect_for_rect(target_rect)
	effect_root.add_child(shield_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(shield_effect, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.40)
	tween.tween_property(shield_effect, "modulate:a", 0.9, spell_animation_duration * 0.40)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(shield_effect, "scale", Vector2(1.30, 1.30), spell_animation_duration * 0.60)
	recover_tween.tween_property(shield_effect, "modulate:a", 0.0, spell_animation_duration * 0.60)
	await recover_tween.finished

	shield_effect.queue_free()


func play_arcane_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var arcane_effect := create_arcane_spell_effect(target_card)
	effect_root.add_child(arcane_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "scale", start_scale * 1.06, spell_animation_duration * 0.38)
	tween.tween_property(arcane_effect, "rotation", 0.18, spell_animation_duration)
	tween.tween_property(arcane_effect, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.38)
	tween.tween_property(arcane_effect, "modulate:a", 0.88, spell_animation_duration * 0.38)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.62)
	recover_tween.tween_property(arcane_effect, "rotation", 0.44, spell_animation_duration * 0.62)
	recover_tween.tween_property(arcane_effect, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.62)
	recover_tween.tween_property(arcane_effect, "modulate:a", 0.0, spell_animation_duration * 0.62)
	await recover_tween.finished

	arcane_effect.queue_free()
	target_card.scale = start_scale
	target_card.is_animating = false


func play_arcane_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var arcane_effect := create_arcane_spell_effect_for_rect(target_rect)
	effect_root.add_child(arcane_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(arcane_effect, "rotation", 0.18, spell_animation_duration)
	tween.tween_property(arcane_effect, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.38)
	tween.tween_property(arcane_effect, "modulate:a", 0.88, spell_animation_duration * 0.38)
	await tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(arcane_effect, "rotation", 0.44, spell_animation_duration * 0.62)
	recover_tween.tween_property(arcane_effect, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.62)
	recover_tween.tween_property(arcane_effect, "modulate:a", 0.0, spell_animation_duration * 0.62)
	await recover_tween.finished

	arcane_effect.queue_free()


func play_arcane_aura_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var target_rect := target_card.get_global_rect()
	await play_arcane_aura_spell_at_rect(owner, effect_root, target_rect)
	target_card.scale = start_scale
	target_card.is_animating = false


func play_arcane_aura_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var aura_effect := create_arcane_aura_effect_for_rect(target_rect)
	var pulse_effect := create_rect_spell_effect(target_rect, "ArcaneAuraPulseEffect", create_arcane_spell_effect_style(), 1.06)
	effect_root.add_child(pulse_effect)
	effect_root.add_child(aura_effect)

	var bloom_tween := owner.create_tween()
	bloom_tween.set_parallel(true)
	bloom_tween.set_trans(Tween.TRANS_SINE)
	bloom_tween.set_ease(Tween.EASE_OUT)
	bloom_tween.tween_property(aura_effect, "rotation", 0.32, spell_animation_duration * 0.45)
	bloom_tween.tween_property(aura_effect, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.45)
	bloom_tween.tween_property(aura_effect, "modulate:a", 0.92, spell_animation_duration * 0.45)
	bloom_tween.tween_property(pulse_effect, "scale", Vector2(1.26, 1.26), spell_animation_duration * 0.45)
	bloom_tween.tween_property(pulse_effect, "modulate:a", 0.72, spell_animation_duration * 0.45)
	await bloom_tween.finished

	var settle_tween := owner.create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_CUBIC)
	settle_tween.set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(aura_effect, "rotation", 0.88, spell_animation_duration * 0.72)
	settle_tween.tween_property(aura_effect, "scale", Vector2(1.75, 1.75), spell_animation_duration * 0.72)
	settle_tween.tween_property(aura_effect, "modulate:a", 0.0, spell_animation_duration * 0.72)
	settle_tween.tween_property(pulse_effect, "scale", Vector2(2.10, 2.10), spell_animation_duration * 0.72)
	settle_tween.tween_property(pulse_effect, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await settle_tween.finished

	aura_effect.queue_free()
	pulse_effect.queue_free()


func play_baptism_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var target_rect := target_card.get_global_rect()
	await play_baptism_spell_at_rect(owner, effect_root, target_rect)
	target_card.scale = start_scale
	target_card.is_animating = false


func play_baptism_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var heal_effect := create_heal_spell_effect_for_rect(target_rect)
	var wave_effect := create_baptism_wave_effect_for_rect(target_rect)
	effect_root.add_child(wave_effect)
	effect_root.add_child(heal_effect)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(heal_effect, "scale", Vector2(1.14, 1.14), spell_animation_duration * 0.42)
	tween.tween_property(heal_effect, "modulate:a", 0.95, spell_animation_duration * 0.42)
	tween.tween_property(wave_effect, "scale", Vector2(1.45, 1.45), spell_animation_duration * 0.42)
	tween.tween_property(wave_effect, "modulate:a", 0.78, spell_animation_duration * 0.42)
	await tween.finished

	var spread_tween := owner.create_tween()
	spread_tween.set_parallel(true)
	spread_tween.set_trans(Tween.TRANS_CUBIC)
	spread_tween.set_ease(Tween.EASE_OUT)
	spread_tween.tween_property(heal_effect, "scale", Vector2(1.46, 1.46), spell_animation_duration * 0.66)
	spread_tween.tween_property(heal_effect, "modulate:a", 0.0, spell_animation_duration * 0.66)
	spread_tween.tween_property(wave_effect, "scale", Vector2(2.85, 2.85), spell_animation_duration * 0.66)
	spread_tween.tween_property(wave_effect, "modulate:a", 0.0, spell_animation_duration * 0.66)
	await spread_tween.finished

	heal_effect.queue_free()
	wave_effect.queue_free()


func play_summon_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var portal_effect := create_summon_spell_effect_for_rect(target_rect)
	var wave_effect := create_summon_wave_effect_for_rect(target_rect)
	var droplets: Array[Panel] = create_summon_droplets_for_rect(target_rect)
	effect_root.add_child(wave_effect)
	effect_root.add_child(portal_effect)
	for droplet in droplets:
		effect_root.add_child(droplet)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(portal_effect, "scale", Vector2(1.14, 1.14), spell_animation_duration * 0.42)
	rise_tween.tween_property(portal_effect, "rotation", 0.20, spell_animation_duration * 0.42)
	rise_tween.tween_property(portal_effect, "modulate:a", 0.96, spell_animation_duration * 0.42)
	rise_tween.tween_property(wave_effect, "scale", Vector2(1.36, 1.36), spell_animation_duration * 0.42)
	rise_tween.tween_property(wave_effect, "modulate:a", 0.72, spell_animation_duration * 0.42)
	for droplet in droplets:
		var offset: Vector2 = droplet.get_meta("summon_offset", Vector2.ZERO)
		rise_tween.tween_property(droplet, "position", droplet.position + offset * 0.35, spell_animation_duration * 0.42)
		rise_tween.tween_property(droplet, "modulate:a", 0.92, spell_animation_duration * 0.42)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(portal_effect, "scale", Vector2(1.66, 1.66), spell_animation_duration * 0.72)
	burst_tween.tween_property(portal_effect, "rotation", 0.72, spell_animation_duration * 0.72)
	burst_tween.tween_property(portal_effect, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(wave_effect, "scale", Vector2(2.55, 2.55), spell_animation_duration * 0.72)
	burst_tween.tween_property(wave_effect, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for droplet in droplets:
		var offset: Vector2 = droplet.get_meta("summon_offset", Vector2.ZERO)
		burst_tween.tween_property(droplet, "position", droplet.position + offset, spell_animation_duration * 0.72)
		burst_tween.tween_property(droplet, "scale", Vector2(0.25, 0.25), spell_animation_duration * 0.72)
		burst_tween.tween_property(droplet, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burst_tween.finished

	portal_effect.queue_free()
	wave_effect.queue_free()
	for droplet in droplets:
		droplet.queue_free()


func play_fireball_spell(owner: Node, effect_root: Control, caster_card: Card, target_card: Card, size_scale := 1.0) -> void:
	if owner == null or effect_root == null or caster_card == null or target_card == null:
		return

	var caster_start_scale: Vector2 = caster_card.scale
	var caster_start_z_index: int = caster_card.z_index
	caster_card.is_animating = true
	caster_card.z_index = 1180
	var caster_center: Vector2 = caster_card.get_global_rect().get_center()

	var charge_duration: float = spell_animation_duration * 0.20
	var charge_tween := owner.create_tween()
	charge_tween.set_parallel(true)
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(caster_card, "scale", caster_start_scale * 1.06, charge_duration)
	await charge_tween.finished

	await play_fireball_from_point(owner, effect_root, caster_center, target_card, size_scale)

	caster_card.scale = caster_start_scale
	caster_card.z_index = caster_start_z_index
	caster_card.is_animating = false


func play_fireball_from_point(owner: Node, effect_root: Control, caster_center: Vector2, target_card: Card, size_scale := 1.0) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	var target_start_position: Vector2 = target_card.position
	var target_start_scale: Vector2 = target_card.scale
	var target_start_modulate: Color = target_card.self_modulate
	var target_start_z_index: int = target_card.z_index
	var target_center: Vector2 = target_card.get_global_rect().get_center()
	var cast_vector: Vector2 = target_center - caster_center

	if cast_vector.length() <= 0.01:
		await play_default_spell(owner, target_card)
		return

	target_card.is_animating = true
	target_card.z_index = 1190

	var cast_direction: Vector2 = cast_vector.normalized()
	var target_shake_offset: Vector2 = cast_direction * attack_target_shake_distance
	var flight_duration: float = spell_animation_duration * 0.58
	var impact_duration: float = spell_animation_duration * 0.22

	var fireball := create_fireball_projectile(size_scale)
	effect_root.add_child(fireball)
	fireball.rotation = cast_direction.angle()
	fireball.global_position = caster_center - fireball.pivot_offset

	var flight_tween := owner.create_tween()
	flight_tween.set_parallel(true)
	flight_tween.set_trans(Tween.TRANS_CUBIC)
	flight_tween.set_ease(Tween.EASE_OUT)
	flight_tween.tween_property(fireball, "global_position", target_center - fireball.pivot_offset, flight_duration)
	flight_tween.tween_property(fireball, "scale", Vector2(1.28, 1.28) * size_scale, flight_duration)
	await flight_tween.finished

	var impact_tween := owner.create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_SINE)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(fireball, "modulate:a", 0.0, impact_duration)
	impact_tween.tween_property(fireball, "scale", Vector2(2.1, 2.1) * size_scale, impact_duration)
	impact_tween.tween_property(target_card, "position", target_start_position + target_shake_offset, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "scale", target_start_scale * 0.95, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "self_modulate", fireball_impact_color, impact_duration * 0.5)
	await impact_tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "position", target_start_position, impact_duration)
	recover_tween.tween_property(target_card, "scale", target_start_scale, impact_duration)
	recover_tween.tween_property(target_card, "self_modulate", target_start_modulate, impact_duration)
	await recover_tween.finished

	fireball.queue_free()
	target_card.position = target_start_position
	target_card.scale = target_start_scale
	target_card.self_modulate = target_start_modulate
	target_card.z_index = target_start_z_index
	target_card.is_animating = false


func play_dark_arrow_spell(owner: Node, effect_root: Control, caster_center: Vector2, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	var target_start_position: Vector2 = target_card.position
	var target_start_scale: Vector2 = target_card.scale
	var target_start_modulate: Color = target_card.self_modulate
	var target_start_z_index: int = target_card.z_index
	var target_center: Vector2 = target_card.get_global_rect().get_center()
	var cast_vector: Vector2 = target_center - caster_center

	if cast_vector.length() <= 0.01:
		await play_default_spell(owner, target_card)
		return

	target_card.is_animating = true
	target_card.z_index = 1190

	var cast_direction: Vector2 = cast_vector.normalized()
	var target_shake_offset: Vector2 = cast_direction * attack_target_shake_distance
	var flight_duration: float = spell_animation_duration * 0.64
	var impact_duration: float = spell_animation_duration * 0.24

	var dark_arrow := create_dark_arrow_projectile()
	effect_root.add_child(dark_arrow)
	dark_arrow.rotation = cast_direction.angle()
	dark_arrow.global_position = caster_center - dark_arrow.pivot_offset

	var flight_tween := owner.create_tween()
	flight_tween.set_parallel(true)
	flight_tween.set_trans(Tween.TRANS_CUBIC)
	flight_tween.set_ease(Tween.EASE_IN)
	flight_tween.tween_property(dark_arrow, "global_position", target_center - dark_arrow.pivot_offset, flight_duration)
	flight_tween.tween_property(dark_arrow, "scale", Vector2(1.18, 1.18), flight_duration)
	flight_tween.tween_property(dark_arrow, "modulate:a", 1.0, flight_duration * 0.35)
	await flight_tween.finished

	var impact_tween := owner.create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_SINE)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(dark_arrow, "modulate:a", 0.0, impact_duration)
	impact_tween.tween_property(dark_arrow, "scale", Vector2(1.75, 1.75), impact_duration)
	impact_tween.tween_property(target_card, "position", target_start_position + target_shake_offset, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "scale", target_start_scale * 0.94, impact_duration * 0.5)
	impact_tween.tween_property(target_card, "self_modulate", dark_arrow_impact_color, impact_duration * 0.5)
	await impact_tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "position", target_start_position, impact_duration)
	recover_tween.tween_property(target_card, "scale", target_start_scale, impact_duration)
	recover_tween.tween_property(target_card, "self_modulate", target_start_modulate, impact_duration)
	await recover_tween.finished

	dark_arrow.queue_free()
	target_card.position = target_start_position
	target_card.scale = target_start_scale
	target_card.self_modulate = target_start_modulate
	target_card.z_index = target_start_z_index
	target_card.is_animating = false


func play_gu_infusion_spell(owner: Node, effect_root: Control, caster_center: Vector2, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	var target_start_scale: Vector2 = target_card.scale
	var target_start_modulate: Color = target_card.self_modulate
	var target_start_z_index: int = target_card.z_index
	var target_center: Vector2 = target_card.get_global_rect().get_center()
	var cast_vector: Vector2 = target_center - caster_center

	if cast_vector.length() <= 0.01:
		await play_gu_infusion_at_rect(owner, effect_root, target_card.get_global_rect())
		return

	target_card.is_animating = true
	target_card.z_index = 1190

	var cast_direction: Vector2 = cast_vector.normalized()
	var perpendicular := Vector2(-cast_direction.y, cast_direction.x)
	var flight_duration: float = spell_animation_duration * 0.62
	var impact_duration: float = spell_animation_duration * 0.34
	var worms: Array[Panel] = []

	for index in range(5):
		var worm := create_gu_projectile()
		var lane_offset: float = (float(index) - 2.0) * 8.0
		var start_offset: Vector2 = perpendicular * lane_offset
		var end_offset: Vector2 = perpendicular * lane_offset * 0.22
		worm.global_position = caster_center + start_offset - worm.pivot_offset
		worm.rotation = cast_direction.angle() + sin(float(index)) * 0.28
		effect_root.add_child(worm)
		worms.append(worm)

		var worm_tween := owner.create_tween()
		worm_tween.set_parallel(true)
		worm_tween.set_trans(Tween.TRANS_CUBIC)
		worm_tween.set_ease(Tween.EASE_IN_OUT)
		worm_tween.tween_property(worm, "global_position", target_center + end_offset - worm.pivot_offset, flight_duration)
		worm_tween.tween_property(worm, "rotation", worm.rotation + 0.75 + float(index) * 0.10, flight_duration)
		worm_tween.tween_property(worm, "scale", Vector2(1.35, 1.35), flight_duration)

	await owner.create_tween().tween_interval(flight_duration).finished

	var impact_ring := create_gu_infusion_effect_for_rect(target_card.get_global_rect())
	effect_root.add_child(impact_ring)

	var impact_tween := owner.create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_SINE)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(impact_ring, "scale", Vector2(1.36, 1.36), impact_duration)
	impact_tween.tween_property(impact_ring, "modulate:a", 0.0, impact_duration)
	impact_tween.tween_property(target_card, "scale", target_start_scale * 1.08, impact_duration * 0.48)
	impact_tween.tween_property(target_card, "self_modulate", gu_impact_color, impact_duration * 0.48)
	for worm in worms:
		impact_tween.tween_property(worm, "modulate:a", 0.0, impact_duration)
		impact_tween.tween_property(worm, "scale", Vector2(0.35, 0.35), impact_duration)
	await impact_tween.finished

	var recover_tween := owner.create_tween()
	recover_tween.set_parallel(true)
	recover_tween.set_trans(Tween.TRANS_BACK)
	recover_tween.set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(target_card, "scale", target_start_scale, spell_animation_duration * 0.28)
	recover_tween.tween_property(target_card, "self_modulate", target_start_modulate, spell_animation_duration * 0.28)
	await recover_tween.finished

	for worm in worms:
		worm.queue_free()
	impact_ring.queue_free()
	target_card.scale = target_start_scale
	target_card.self_modulate = target_start_modulate
	target_card.z_index = target_start_z_index
	target_card.is_animating = false


func play_gu_infusion_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var ring := create_gu_infusion_effect_for_rect(target_rect)
	effect_root.add_child(ring)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.34, 1.34), spell_animation_duration)
	tween.tween_property(ring, "modulate:a", 0.0, spell_animation_duration)
	await tween.finished
	ring.queue_free()


func play_area_spell_cast(owner: Node, effect_root: Control, caster_card: Card, center_card: Card, spell_data: Dictionary) -> void:
	if owner == null or effect_root == null or caster_card == null or center_card == null:
		return

	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"blizzard":
			await play_blizzard_area_spell(owner, effect_root, caster_card, center_card, spell_data)
		_:
			await play_default_spell(owner, center_card)


func play_blizzard_area_spell(owner: Node, effect_root: Control, caster_card: Card, center_card: Card, spell_data: Dictionary) -> void:
	var area_rows: int = int(spell_data.get("area_rows", 3))
	var area_cols: int = int(spell_data.get("area_cols", 3))

	caster_card.is_animating = true
	var caster_start_scale: Vector2 = caster_card.scale
	var caster_start_z_index: int = caster_card.z_index
	caster_card.z_index = 1180

	var charge_duration: float = spell_animation_duration * 0.22
	var charge_tween := owner.create_tween()
	charge_tween.set_parallel(true)
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(caster_card, "scale", caster_start_scale * 1.08, charge_duration)
	await charge_tween.finished

	var center_rect: Rect2 = center_card.get_global_rect()
	var center_pos: Vector2 = center_rect.get_center()
	var card_size_ref: Vector2 = center_card.size

	var area_width: float = card_size_ref.x * area_cols
	var area_height: float = card_size_ref.y * area_rows
	var area_rect := Rect2(center_pos - Vector2(area_width, area_height) * 0.5, Vector2(area_width, area_height))

	var blizzard_effect := create_blizzard_area_effect(area_rect)
	effect_root.add_child(blizzard_effect)

	var blizzard_duration: float = spell_animation_duration * 0.70
	var blizzard_tween := owner.create_tween()
	blizzard_tween.set_parallel(true)
	blizzard_tween.set_trans(Tween.TRANS_SINE)
	blizzard_tween.set_ease(Tween.EASE_IN_OUT)
	blizzard_tween.tween_property(blizzard_effect, "modulate:a", 0.88, blizzard_duration * 0.3)
	blizzard_tween.tween_property(blizzard_effect, "scale", Vector2(1.06, 1.06), blizzard_duration * 0.3)
	await owner.create_tween().tween_interval(blizzard_duration * 0.4).finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(blizzard_effect, "modulate:a", 0.0, blizzard_duration * 0.3)
	fade_tween.tween_property(blizzard_effect, "scale", Vector2(1.16, 1.16), blizzard_duration * 0.3)
	fade_tween.tween_property(caster_card, "scale", caster_start_scale, blizzard_duration * 0.3)
	await fade_tween.finished

	blizzard_effect.queue_free()
	caster_card.scale = caster_start_scale
	caster_card.z_index = caster_start_z_index
	caster_card.is_animating = false


func create_blizzard_area_effect(area_rect: Rect2) -> Panel:
	var effect := Panel.new()
	effect.name = "BlizzardAreaEffect"
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = area_rect.size
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = area_rect.get_center() - effect.pivot_offset
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2250

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.72, 1.0, 0.24)
	style.border_color = Color(0.56, 0.92, 1.0, 0.70)
	style.set_border_width_all(6)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.24, 0.68, 1.0, 0.44)
	style.shadow_size = 32
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_fireball_projectile(size_scale := 1.0) -> Panel:
	var projectile := Panel.new()
	projectile.name = "FireballProjectile"
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var projectile_size := fireball_projectile_size * size_scale
	projectile.custom_minimum_size = projectile_size
	projectile.size = projectile_size
	projectile.pivot_offset = projectile_size * 0.5
	projectile.z_index = 2150
	projectile.add_theme_stylebox_override("panel", create_fireball_projectile_style(size_scale))
	return projectile


func create_dark_arrow_projectile() -> Control:
	var arrow := Control.new()
	arrow.name = "DarkArrowProjectile"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.custom_minimum_size = dark_arrow_projectile_size
	arrow.size = dark_arrow_projectile_size
	arrow.pivot_offset = dark_arrow_projectile_size * 0.5
	arrow.modulate = Color(1.0, 1.0, 1.0, 0.88)
	arrow.z_index = 2160

	var shaft := Panel.new()
	shaft.name = "Shaft"
	shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shaft.position = Vector2(0.0, dark_arrow_projectile_size.y * 0.40)
	shaft.size = Vector2(dark_arrow_projectile_size.x * 0.68, dark_arrow_projectile_size.y * 0.20)
	shaft.add_theme_stylebox_override("panel", create_dark_arrow_shaft_style())
	arrow.add_child(shaft)

	var head := Polygon2D.new()
	head.name = "Head"
	head.color = dark_arrow_projectile_color
	head.polygon = PackedVector2Array([
		Vector2(dark_arrow_projectile_size.x * 0.62, 0.0),
		Vector2(dark_arrow_projectile_size.x, dark_arrow_projectile_size.y * 0.5),
		Vector2(dark_arrow_projectile_size.x * 0.62, dark_arrow_projectile_size.y)
	])
	arrow.add_child(head)

	return arrow


func create_gu_projectile() -> Panel:
	var projectile := Panel.new()
	projectile.name = "GuInfusionWorm"
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.size = gu_projectile_size
	projectile.pivot_offset = gu_projectile_size * 0.5
	projectile.modulate = Color(1.0, 1.0, 1.0, 0.96)
	projectile.z_index = 2170
	projectile.add_theme_stylebox_override("panel", create_gu_projectile_style())
	return projectile


func create_fireball_projectile_style(size_scale := 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fireball_projectile_color
	style.border_color = fireball_projectile_glow_color
	style.set_border_width_all(int(6.0 * size_scale))
	style.set_corner_radius_all(int(fireball_projectile_size.y * size_scale * 0.5))
	style.shadow_color = fireball_projectile_glow_color
	style.shadow_size = int(22.0 * size_scale)
	return style


func create_dark_arrow_shaft_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = dark_arrow_projectile_color
	style.border_color = dark_arrow_projectile_glow_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = dark_arrow_projectile_glow_color
	style.shadow_size = 18
	return style


func create_gu_projectile_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = gu_projectile_color
	style.border_color = gu_projectile_glow_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = gu_projectile_glow_color
	style.shadow_size = 12
	return style


func create_heal_spell_effect(target_card: Card) -> Panel:
	var target_rect := target_card.get_global_rect()
	return create_heal_spell_effect_for_rect(target_rect)


func create_shield_spell_effect(target_card: Card) -> Panel:
	var target_rect := target_card.get_global_rect()
	return create_shield_spell_effect_for_rect(target_rect)


func create_arcane_spell_effect(target_card: Card) -> Panel:
	var target_rect := target_card.get_global_rect()
	return create_arcane_spell_effect_for_rect(target_rect)


func create_heal_spell_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "HealSpellEffect", create_heal_spell_effect_style(), 1.28)


func create_shield_spell_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "ShieldSpellEffect", create_shield_spell_effect_style(), 1.34)


func create_arcane_spell_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "ArcaneSpellEffect", create_arcane_spell_effect_style(), 1.22)


func create_arcane_aura_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "ArcaneAuraEffect", create_arcane_aura_effect_style(), 1.30)


func create_gu_infusion_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "GuInfusionImpactEffect", create_gu_infusion_effect_style(), 1.18)


func create_summon_spell_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "SummonSpellEffect", create_summon_spell_effect_style(), 1.18)


func create_summon_wave_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "SummonWaveEffect", create_summon_wave_effect_style(), 1.04)


func create_summon_droplets_for_rect(target_rect: Rect2) -> Array[Panel]:
	var droplets: Array[Panel] = []
	var center: Vector2 = target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.42
	var droplet_size := Vector2(14.0, 14.0)

	for index in range(6):
		var angle: float = TAU * float(index) / 6.0 - PI * 0.5
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.34
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * 0.90
		var droplet := Panel.new()
		droplet.name = "SummonDroplet_%d" % index
		droplet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		droplet.size = droplet_size
		droplet.pivot_offset = droplet_size * 0.5
		droplet.global_position = center + start_offset - droplet.pivot_offset
		droplet.modulate = Color(1.0, 1.0, 1.0, 0.0)
		droplet.z_index = 2320
		droplet.set_meta("summon_offset", burst_offset)
		droplet.add_theme_stylebox_override("panel", create_summon_droplet_style())
		droplets.append(droplet)

	return droplets


func create_baptism_wave_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "BaptismWaveEffect", create_baptism_wave_effect_style(), 1.16)


func create_rect_spell_effect(target_rect: Rect2, effect_name: String, style: StyleBoxFlat, size_multiplier: float) -> Panel:
	var effect := Panel.new()
	effect.name = effect_name
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = target_rect.size * size_multiplier
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = target_rect.get_center() - effect.pivot_offset
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2300
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_heal_spell_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = heal_spell_effect_color
	style.border_color = heal_spell_effect_glow_color
	style.set_border_width_all(8)
	style.set_corner_radius_all(10)
	style.shadow_color = heal_spell_effect_glow_color
	style.shadow_size = 28
	return style


func create_shield_spell_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = shield_spell_effect_color
	style.border_color = shield_spell_effect_glow_color
	style.set_border_width_all(9)
	style.set_corner_radius_all(14)
	style.shadow_color = shield_spell_effect_glow_color
	style.shadow_size = 32
	return style


func create_arcane_spell_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = arcane_spell_effect_color
	style.border_color = arcane_spell_effect_glow_color
	style.set_border_width_all(7)
	style.set_corner_radius_all(18)
	style.shadow_color = arcane_spell_effect_glow_color
	style.shadow_size = 30
	return style


func create_arcane_aura_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.30, 0.24, 1.0, 0.20)
	style.border_color = Color(0.72, 0.92, 1.0, 0.78)
	style.set_border_width_all(9)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.46, 0.72, 1.0, 0.54)
	style.shadow_size = 38
	return style


func create_gu_infusion_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.72, 0.12, 0.24)
	style.border_color = Color(0.64, 1.0, 0.28, 0.82)
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.36, 1.0, 0.18, 0.56)
	style.shadow_size = 34
	return style


func create_summon_spell_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = summon_spell_effect_color
	style.border_color = summon_spell_effect_glow_color
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = summon_spell_effect_glow_color
	style.shadow_size = 34
	return style


func create_summon_wave_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.52, 1.0, 0.16)
	style.border_color = Color(0.72, 0.96, 1.0, 0.74)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.34, 0.78, 1.0, 0.42)
	style.shadow_size = 30
	return style


func create_summon_droplet_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.62, 0.95, 1.0, 0.92)
	style.border_color = Color(0.94, 1.0, 1.0, 0.78)
	style.set_border_width_all(3)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.32, 0.80, 1.0, 0.54)
	style.shadow_size = 14
	return style


func create_baptism_wave_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.88, 0.36, 0.20)
	style.border_color = Color(1.0, 0.95, 0.62, 0.78)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.72, 0.18, 0.50)
	style.shadow_size = 36
	return style
