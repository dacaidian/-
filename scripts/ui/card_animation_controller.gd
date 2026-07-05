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
var gu_lure_color := Color(0.10, 0.42, 0.07, 0.22)
var gu_lure_glow_color := Color(0.50, 1.0, 0.22, 0.62)
var gu_trap_trigger_color := Color(0.30, 0.04, 0.10, 0.32)
var gu_trap_trigger_glow_color := Color(0.92, 0.18, 0.36, 0.76)
var gu_summon_color := Color(0.08, 0.30, 0.06, 0.30)
var gu_summon_glow_color := Color(0.66, 1.0, 0.20, 0.70)


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
		"immortal_peach":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"medical_practice":
			await play_medical_practice_spell(owner, effect_root, target_card)
		"tranquil_spring":
			await play_tranquil_spring_at_rect(owner, effect_root, target_card.get_global_rect())
		"drive_spirit":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"shield", "frost_shield":
			await play_shield_spell(owner, effect_root, target_card)
		"power_word_shield":
			await play_power_word_shield_at_rect(owner, effect_root, target_card.get_global_rect())
		"fiery_eyes_golden_gaze":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"arcane", "arcane_wisdom":
			await play_arcane_spell(owner, effect_root, target_card)
		"arcane_aura":
			await play_arcane_aura_spell(owner, effect_root, target_card)
		"meteor_aura":
			await play_meteor_aura_at_rect(owner, effect_root, target_card.get_global_rect())
		"meteor_strike":
			await play_meteor_strike_at_rect(owner, effect_root, target_card.get_global_rect())
		"full_moon_cover":
			await play_full_moon_cover_at_rect(owner, effect_root, target_card.get_global_rect())
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
		"somersault_cloud", "body_beyond_body", "gather_scatter_qi", "heavenly_form":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"bronze_head_iron_arms":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"moonblade":
			if caster_card == null or target_card == null:
				return
			await play_moonblade_spell(owner, effect_root, caster_card, target_card, target_card)
		"gu_infusion":
			if caster_card == null or target_card == null:
				return
			await play_gu_infusion_spell(owner, effect_root, caster_card.get_global_rect().get_center(), target_card)
		"fel_infusion", "fel_overload", "fel_burst", "fel_madness", "demon_summon":
			await play_fel_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"mana_burn", "fel_bite":
			if caster_card == null or target_card == null:
				return
			await play_mana_burn_spell(owner, effect_root, caster_card, target_card)
		"gu_life_link_larva":
			await play_gu_life_link_larva_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_life_link":
			await play_gu_life_link_at_rect(owner, effect_root, target_card.get_global_rect())
		"thin_burial":
			await play_thin_burial_at_rect(owner, effect_root, target_card.get_global_rect())
		"sacrifice":
			await play_sacrifice_at_rect(owner, effect_root, target_card.get_global_rect())
		"reborn":
			await play_reborn_at_rect(owner, effect_root, target_card.get_global_rect())
		"beastmen_evolution", "beastmen_slaughter", "wanmo_charge":
			await play_beastmen_survival_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"savage_roar":
			await play_savage_roar_at_rect(owner, effect_root, target_card.get_global_rect())
		"wild_call":
			await play_wild_call_at_rect(owner, effect_root, target_card.get_global_rect())
		"beast_path":
			await play_wild_call_at_rect(owner, effect_root, target_card.get_global_rect())
		"wanmo_ritual":
			await play_wanmo_ritual_at_rect(owner, effect_root, target_card.get_global_rect())
		"soul_hook":
			await play_soul_hook_at_rect(owner, effect_root, target_card.get_global_rect())
		"immobilize":
			await play_monkey_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"charm":
			await play_charm_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_lure":
			if target_card == null:
				return
			await play_gu_lure_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_trap_trigger":
			if target_card == null:
				return
			await play_gu_trap_trigger_at_rect(owner, effect_root, target_card.get_global_rect())
		_:
			await play_default_spell(owner, target_card)


func play_spell_cast_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, spell_data: Dictionary) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"heal", "healing_spell":
			await play_heal_spell_at_rect(owner, effect_root, target_rect)
		"immortal_peach":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"medical_practice":
			await play_medical_practice_at_rect(owner, effect_root, target_rect)
		"tranquil_spring":
			await play_tranquil_spring_at_rect(owner, effect_root, target_rect)
		"drive_spirit":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"shield", "frost_shield":
			await play_shield_spell_at_rect(owner, effect_root, target_rect)
		"power_word_shield":
			await play_power_word_shield_at_rect(owner, effect_root, target_rect)
		"fiery_eyes_golden_gaze":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"arcane", "arcane_wisdom":
			await play_arcane_spell_at_rect(owner, effect_root, target_rect)
		"summon":
			await play_summon_spell_at_rect(owner, effect_root, target_rect)
		"somersault_cloud", "body_beyond_body", "gather_scatter_qi", "heavenly_form":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"bronze_head_iron_arms":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"arcane_aura":
			await play_arcane_aura_spell_at_rect(owner, effect_root, target_rect)
		"meteor_aura":
			await play_meteor_aura_at_rect(owner, effect_root, target_rect)
		"meteor_strike":
			await play_meteor_strike_at_rect(owner, effect_root, target_rect)
		"full_moon_cover":
			await play_full_moon_cover_at_rect(owner, effect_root, target_rect)
		"baptism":
			await play_baptism_spell_at_rect(owner, effect_root, target_rect)
		"gu_infusion":
			await play_gu_infusion_at_rect(owner, effect_root, target_rect)
		"fel_infusion", "fel_overload", "fel_burst", "fel_madness", "demon_summon":
			await play_fel_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"gu_life_link_larva":
			await play_gu_life_link_larva_at_rect(owner, effect_root, target_rect)
		"gu_life_link":
			await play_gu_life_link_at_rect(owner, effect_root, target_rect)
		"thin_burial":
			await play_thin_burial_at_rect(owner, effect_root, target_rect)
		"sacrifice":
			await play_sacrifice_at_rect(owner, effect_root, target_rect)
		"reborn":
			await play_reborn_at_rect(owner, effect_root, target_rect)
		"beastmen_evolution", "beastmen_slaughter", "wanmo_charge":
			await play_beastmen_survival_at_rect(owner, effect_root, target_rect, animation_key)
		"savage_roar":
			await play_savage_roar_at_rect(owner, effect_root, target_rect)
		"wild_call":
			await play_wild_call_at_rect(owner, effect_root, target_rect)
		"beast_path":
			await play_wild_call_at_rect(owner, effect_root, target_rect)
		"wanmo_ritual":
			await play_wanmo_ritual_at_rect(owner, effect_root, target_rect)
		"soul_hook":
			await play_soul_hook_at_rect(owner, effect_root, target_rect)
		"immobilize":
			await play_monkey_spell_at_rect(owner, effect_root, target_rect, animation_key)
		"charm":
			await play_charm_at_rect(owner, effect_root, target_rect)
		"gu_lure":
			await play_gu_lure_at_rect(owner, effect_root, target_rect)
		"gu_summon":
			await play_gu_summon_at_rect(owner, effect_root, target_rect)
		"gu_trap_trigger":
			await play_gu_trap_trigger_at_rect(owner, effect_root, target_rect)
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
		"medical_practice":
			await play_medical_practice_spell(owner, effect_root, target_card)
		"tranquil_spring":
			await play_tranquil_spring_at_rect(owner, effect_root, target_card.get_global_rect())
		"power_word_shield":
			await play_power_word_shield_at_rect(owner, effect_root, target_card.get_global_rect())
		"meteor_strike":
			await play_meteor_strike_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_infusion":
			await play_gu_infusion_spell(owner, effect_root, source_rect.get_center(), target_card)
		"fel_infusion", "fel_overload", "fel_burst", "fel_madness", "demon_summon":
			await play_fel_spell_at_rect(owner, effect_root, target_card.get_global_rect(), animation_key)
		"gu_life_link_larva":
			await play_gu_life_link_larva_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_life_link":
			await play_gu_life_link_at_rect(owner, effect_root, target_card.get_global_rect())
		"thin_burial":
			await play_thin_burial_at_rect(owner, effect_root, target_card.get_global_rect())
		"sacrifice":
			await play_sacrifice_at_rect(owner, effect_root, target_card.get_global_rect())
		"reborn":
			await play_reborn_at_rect(owner, effect_root, target_card.get_global_rect())
		"soul_hook":
			await play_soul_hook_at_rect(owner, effect_root, target_card.get_global_rect())
		"charm":
			await play_charm_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_lure":
			await play_gu_lure_at_rect(owner, effect_root, target_card.get_global_rect())
		"gu_trap_trigger":
			await play_gu_trap_trigger_at_rect(owner, effect_root, target_card.get_global_rect())
		"baptism":
			await play_baptism_spell(owner, effect_root, target_card)
		"full_moon_cover":
			await play_full_moon_cover_at_rect(owner, effect_root, target_card.get_global_rect())
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


func play_medical_practice_spell(owner: Node, effect_root: Control, target_card: Card) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	target_card.is_animating = true
	var start_scale: Vector2 = target_card.scale
	var pulse_tween := owner.create_tween()
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(target_card, "scale", start_scale * 1.05, spell_animation_duration * 0.40)
	pulse_tween.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.55)

	await play_medical_practice_at_rect(owner, effect_root, target_card.get_global_rect())
	if pulse_tween.is_running():
		await pulse_tween.finished

	target_card.scale = start_scale
	target_card.is_animating = false


func play_medical_practice_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var mist := create_rect_spell_effect(target_rect, "MedicalPracticeMistEffect", create_medical_practice_mist_style(), 1.18)
	var herb_ring := create_rect_spell_effect(target_rect, "MedicalPracticeHerbRingEffect", create_medical_practice_ring_style(), 0.86)
	var herb_motes: Array[Panel] = create_medical_practice_motes_for_rect(target_rect)
	effect_root.add_child(mist)
	effect_root.add_child(herb_ring)
	for mote in herb_motes:
		effect_root.add_child(mote)

	var bloom_tween := owner.create_tween()
	bloom_tween.set_parallel(true)
	bloom_tween.set_trans(Tween.TRANS_SINE)
	bloom_tween.set_ease(Tween.EASE_OUT)
	bloom_tween.tween_property(mist, "scale", Vector2(1.26, 1.26), spell_animation_duration * 0.42)
	bloom_tween.tween_property(mist, "modulate:a", 0.72, spell_animation_duration * 0.42)
	bloom_tween.tween_property(herb_ring, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.42)
	bloom_tween.tween_property(herb_ring, "rotation", -0.28, spell_animation_duration * 0.42)
	bloom_tween.tween_property(herb_ring, "modulate:a", 0.95, spell_animation_duration * 0.42)
	for mote in herb_motes:
		var gather_offset: Vector2 = mote.get_meta("medical_practice_offset", Vector2.ZERO)
		bloom_tween.tween_property(mote, "position", mote.position + gather_offset * 0.24, spell_animation_duration * 0.42)
		bloom_tween.tween_property(mote, "modulate:a", 0.92, spell_animation_duration * 0.42)
	await bloom_tween.finished

	var release_tween := owner.create_tween()
	release_tween.set_parallel(true)
	release_tween.set_trans(Tween.TRANS_CUBIC)
	release_tween.set_ease(Tween.EASE_OUT)
	release_tween.tween_property(mist, "scale", Vector2(1.74, 1.74), spell_animation_duration * 0.68)
	release_tween.tween_property(mist, "modulate:a", 0.0, spell_animation_duration * 0.68)
	release_tween.tween_property(herb_ring, "scale", Vector2(1.52, 1.52), spell_animation_duration * 0.68)
	release_tween.tween_property(herb_ring, "rotation", -0.92, spell_animation_duration * 0.68)
	release_tween.tween_property(herb_ring, "modulate:a", 0.0, spell_animation_duration * 0.68)
	for mote in herb_motes:
		var release_offset: Vector2 = mote.get_meta("medical_practice_offset", Vector2.ZERO)
		release_tween.tween_property(mote, "position", mote.position + release_offset, spell_animation_duration * 0.68)
		release_tween.tween_property(mote, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.68)
		release_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.68)
	await release_tween.finished

	mist.queue_free()
	herb_ring.queue_free()
	for mote in herb_motes:
		mote.queue_free()


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


func play_power_word_shield_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var ward := create_rect_spell_effect(target_rect, "PowerWordShieldWard", create_power_word_shield_ward_style(), 1.32)
	var sigil := create_rect_spell_effect(target_rect, "PowerWordShieldSigil", create_power_word_shield_sigil_style(), 0.86)
	effect_root.add_child(ward)
	effect_root.add_child(sigil)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(ward, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.38)
	rise_tween.tween_property(ward, "modulate:a", 0.92, spell_animation_duration * 0.38)
	rise_tween.tween_property(sigil, "scale", Vector2(1.02, 1.02), spell_animation_duration * 0.38)
	rise_tween.tween_property(sigil, "modulate:a", 0.90, spell_animation_duration * 0.38)
	await rise_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(ward, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.68)
	fade_tween.tween_property(ward, "modulate:a", 0.0, spell_animation_duration * 0.68)
	fade_tween.tween_property(sigil, "scale", Vector2(1.36, 1.36), spell_animation_duration * 0.68)
	fade_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.68)
	await fade_tween.finished

	ward.queue_free()
	sigil.queue_free()


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


func play_meteor_aura_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var aura_effect := create_rect_spell_effect(target_rect, "MeteorAuraEffect", create_meteor_aura_effect_style(), 1.34)
	var star_effect := create_rect_spell_effect(target_rect, "MeteorAuraStarEffect", create_meteor_star_effect_style(), 0.44)
	effect_root.add_child(aura_effect)
	effect_root.add_child(star_effect)

	var gather_tween := owner.create_tween()
	gather_tween.set_parallel(true)
	gather_tween.set_trans(Tween.TRANS_SINE)
	gather_tween.set_ease(Tween.EASE_OUT)
	gather_tween.tween_property(aura_effect, "rotation", 0.52, spell_animation_duration * 0.48)
	gather_tween.tween_property(aura_effect, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.48)
	gather_tween.tween_property(aura_effect, "modulate:a", 0.92, spell_animation_duration * 0.48)
	gather_tween.tween_property(star_effect, "scale", Vector2(1.36, 1.36), spell_animation_duration * 0.48)
	gather_tween.tween_property(star_effect, "modulate:a", 0.94, spell_animation_duration * 0.48)
	await gather_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(aura_effect, "rotation", 1.12, spell_animation_duration * 0.68)
	fade_tween.tween_property(aura_effect, "scale", Vector2(1.82, 1.82), spell_animation_duration * 0.68)
	fade_tween.tween_property(aura_effect, "modulate:a", 0.0, spell_animation_duration * 0.68)
	fade_tween.tween_property(star_effect, "scale", Vector2(0.82, 0.82), spell_animation_duration * 0.68)
	fade_tween.tween_property(star_effect, "modulate:a", 0.0, spell_animation_duration * 0.68)
	await fade_tween.finished

	aura_effect.queue_free()
	star_effect.queue_free()


func play_meteor_strike_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var meteor := create_rect_spell_effect(target_rect, "MeteorStrikeMeteor", create_meteor_star_effect_style(), 0.34)
	var impact := create_rect_spell_effect(target_rect, "MeteorStrikeImpact", create_meteor_impact_effect_style(), 0.92)
	var target_center := target_rect.get_center()
	meteor.global_position = target_center + Vector2(-target_rect.size.x * 0.82, -target_rect.size.y * 1.25) - meteor.pivot_offset
	meteor.modulate.a = 0.98
	effect_root.add_child(meteor)
	effect_root.add_child(impact)

	var fall_tween := owner.create_tween()
	fall_tween.set_parallel(true)
	fall_tween.set_trans(Tween.TRANS_CUBIC)
	fall_tween.set_ease(Tween.EASE_IN)
	fall_tween.tween_property(meteor, "global_position", target_center - meteor.pivot_offset, spell_animation_duration * 0.42)
	fall_tween.tween_property(meteor, "scale", Vector2(1.28, 1.28), spell_animation_duration * 0.42)
	await fall_tween.finished

	var impact_tween := owner.create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_SINE)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(meteor, "modulate:a", 0.0, spell_animation_duration * 0.38)
	impact_tween.tween_property(impact, "modulate:a", 0.88, spell_animation_duration * 0.16)
	impact_tween.tween_property(impact, "scale", Vector2(1.55, 1.55), spell_animation_duration * 0.38)
	impact_tween.tween_property(impact, "modulate:a", 0.0, spell_animation_duration * 0.38)
	await impact_tween.finished

	meteor.queue_free()
	impact.queue_free()


func play_full_moon_cover_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var moon_disc := create_rect_spell_effect(target_rect, "FullMoonCoverDisc", create_full_moon_disc_style(), 0.78)
	var moon_halo := create_rect_spell_effect(target_rect, "FullMoonCoverHalo", create_full_moon_halo_style(), 1.10)
	var eclipse_ring := create_rect_spell_effect(target_rect, "FullMoonCoverRing", create_full_moon_ring_style(), 1.28)
	var motes: Array[Panel] = create_full_moon_motes_for_rect(target_rect)
	effect_root.add_child(moon_halo)
	effect_root.add_child(eclipse_ring)
	effect_root.add_child(moon_disc)
	for mote in motes:
		effect_root.add_child(mote)

	var gather_tween := owner.create_tween()
	gather_tween.set_parallel(true)
	gather_tween.set_trans(Tween.TRANS_SINE)
	gather_tween.set_ease(Tween.EASE_OUT)
	gather_tween.tween_property(moon_disc, "scale", Vector2(1.04, 1.04), spell_animation_duration * 0.38)
	gather_tween.tween_property(moon_disc, "modulate:a", 0.96, spell_animation_duration * 0.38)
	gather_tween.tween_property(moon_halo, "scale", Vector2(1.22, 1.22), spell_animation_duration * 0.38)
	gather_tween.tween_property(moon_halo, "modulate:a", 0.78, spell_animation_duration * 0.38)
	gather_tween.tween_property(eclipse_ring, "rotation", 0.28, spell_animation_duration * 0.38)
	gather_tween.tween_property(eclipse_ring, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.38)
	gather_tween.tween_property(eclipse_ring, "modulate:a", 0.86, spell_animation_duration * 0.38)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("full_moon_offset", Vector2.ZERO)
		gather_tween.tween_property(mote, "position", mote.position + offset * 0.30, spell_animation_duration * 0.38)
		gather_tween.tween_property(mote, "modulate:a", 0.90, spell_animation_duration * 0.38)
	await gather_tween.finished

	var cover_tween := owner.create_tween()
	cover_tween.set_parallel(true)
	cover_tween.set_trans(Tween.TRANS_CUBIC)
	cover_tween.set_ease(Tween.EASE_OUT)
	cover_tween.tween_property(moon_disc, "scale", Vector2(1.46, 1.46), spell_animation_duration * 0.78)
	cover_tween.tween_property(moon_disc, "modulate:a", 0.0, spell_animation_duration * 0.78)
	cover_tween.tween_property(moon_halo, "scale", Vector2(2.10, 2.10), spell_animation_duration * 0.78)
	cover_tween.tween_property(moon_halo, "modulate:a", 0.0, spell_animation_duration * 0.78)
	cover_tween.tween_property(eclipse_ring, "rotation", 1.18, spell_animation_duration * 0.78)
	cover_tween.tween_property(eclipse_ring, "scale", Vector2(1.72, 1.72), spell_animation_duration * 0.78)
	cover_tween.tween_property(eclipse_ring, "modulate:a", 0.0, spell_animation_duration * 0.78)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("full_moon_offset", Vector2.ZERO)
		cover_tween.tween_property(mote, "position", mote.position + offset, spell_animation_duration * 0.78)
		cover_tween.tween_property(mote, "scale", Vector2(0.28, 0.28), spell_animation_duration * 0.78)
		cover_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.78)
	await cover_tween.finished

	moon_disc.queue_free()
	moon_halo.queue_free()
	eclipse_ring.queue_free()
	for mote in motes:
		mote.queue_free()


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


func play_tranquil_spring_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var spring_effect := create_rect_spell_effect(target_rect, "TranquilSpringEffect", create_tranquil_spring_effect_style(), 1.34)
	var cleanse_ring := create_rect_spell_effect(target_rect, "TranquilSpringCleanseRing", create_tranquil_spring_ring_style(), 1.08)
	effect_root.add_child(spring_effect)
	effect_root.add_child(cleanse_ring)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(spring_effect, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.42)
	rise_tween.tween_property(spring_effect, "modulate:a", 0.92, spell_animation_duration * 0.42)
	rise_tween.tween_property(cleanse_ring, "scale", Vector2(1.52, 1.52), spell_animation_duration * 0.42)
	rise_tween.tween_property(cleanse_ring, "modulate:a", 0.82, spell_animation_duration * 0.42)
	await rise_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(spring_effect, "scale", Vector2(1.62, 1.62), spell_animation_duration * 0.64)
	fade_tween.tween_property(spring_effect, "modulate:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(cleanse_ring, "scale", Vector2(2.35, 2.35), spell_animation_duration * 0.64)
	fade_tween.tween_property(cleanse_ring, "modulate:a", 0.0, spell_animation_duration * 0.64)
	await fade_tween.finished

	spring_effect.queue_free()
	cleanse_ring.queue_free()


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


func play_monkey_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var aura := create_rect_spell_effect(target_rect, "MonkeySpellAura", create_monkey_spell_aura_style(animation_key), 1.22)
	var core := create_rect_spell_effect(target_rect, "MonkeySpellCore", create_monkey_spell_core_style(animation_key), get_monkey_spell_core_size(animation_key))
	var symbol := create_monkey_spell_symbol(target_rect, animation_key)
	var accents := create_monkey_spell_accents(target_rect, animation_key)
	effect_root.add_child(aura)
	effect_root.add_child(core)
	effect_root.add_child(symbol)
	for accent in accents:
		effect_root.add_child(accent)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.tween_property(aura, "scale", Vector2(1.16, 1.16), spell_animation_duration * 0.38)
	rise_tween.tween_property(aura, "modulate:a", 0.86, spell_animation_duration * 0.38)
	rise_tween.tween_property(aura, "rotation", get_monkey_spell_rotation(animation_key) * 0.35, spell_animation_duration * 0.38)
	rise_tween.tween_property(core, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.38)
	rise_tween.tween_property(core, "modulate:a", 0.94, spell_animation_duration * 0.38)
	rise_tween.tween_property(symbol, "scale", Vector2(1.14, 1.14), spell_animation_duration * 0.38)
	rise_tween.tween_property(symbol, "modulate:a", 0.98, spell_animation_duration * 0.38)
	for index in range(accents.size()):
		var accent := accents[index]
		rise_tween.tween_property(accent, "modulate:a", get_monkey_accent_alpha(animation_key, index), spell_animation_duration * 0.38)
		rise_tween.tween_property(accent, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.38)
	await rise_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(aura, "scale", Vector2(1.78, 1.78), spell_animation_duration * 0.72)
	fade_tween.tween_property(aura, "rotation", get_monkey_spell_rotation(animation_key), spell_animation_duration * 0.72)
	fade_tween.tween_property(aura, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade_tween.tween_property(core, "scale", get_monkey_spell_core_fade_scale(animation_key), spell_animation_duration * 0.72)
	fade_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade_tween.tween_property(symbol, "position", symbol.position + get_monkey_symbol_drift(target_rect, animation_key), spell_animation_duration * 0.72)
	fade_tween.tween_property(symbol, "scale", get_monkey_symbol_fade_scale(animation_key), spell_animation_duration * 0.72)
	fade_tween.tween_property(symbol, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for index in range(accents.size()):
		var accent := accents[index]
		fade_tween.tween_property(accent, "position", accent.position + get_monkey_accent_drift(target_rect, animation_key, index), spell_animation_duration * 0.72)
		fade_tween.tween_property(accent, "scale", get_monkey_accent_fade_scale(animation_key, index), spell_animation_duration * 0.72)
		fade_tween.tween_property(accent, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await fade_tween.finished

	aura.queue_free()
	core.queue_free()
	symbol.queue_free()
	for accent in accents:
		accent.queue_free()


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


func play_moonblade_spell(owner: Node, effect_root: Control, caster_card: Card, first_card: Card, second_card: Card) -> void:
	if owner == null or effect_root == null or caster_card == null or first_card == null or second_card == null:
		return

	var caster_start_scale: Vector2 = caster_card.scale
	var caster_start_z_index: int = caster_card.z_index
	caster_card.is_animating = true
	caster_card.z_index = 1180

	var charge_tween := owner.create_tween()
	charge_tween.set_parallel(true)
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(caster_card, "scale", caster_start_scale * 1.05, spell_animation_duration * 0.18)
	await charge_tween.finished

	await play_moonblade_projectile_chain(
		owner,
		effect_root,
		caster_card.get_global_rect().get_center(),
		first_card,
		second_card
	)

	caster_card.scale = caster_start_scale
	caster_card.z_index = caster_start_z_index
	caster_card.is_animating = false


func play_moonblade_projectile_chain(
	owner: Node,
	effect_root: Control,
	start_point: Vector2,
	first_card: Card,
	second_card: Card
) -> void:
	if owner == null or effect_root == null or first_card == null or second_card == null:
		return

	var first_center: Vector2 = first_card.get_global_rect().get_center()
	var second_center: Vector2 = second_card.get_global_rect().get_center()
	var blade := create_moonblade_projectile()
	effect_root.add_child(blade)
	blade.global_position = start_point - blade.pivot_offset

	var first_hit_direction := (first_center - start_point).normalized()
	await fly_moonblade_segment(owner, blade, first_center, first_hit_direction, spell_animation_duration * 0.32)
	await play_moonblade_impact(owner, first_card, first_hit_direction)

	var second_hit_direction := (second_center - first_center).normalized()
	await fly_moonblade_segment(owner, blade, second_center, second_hit_direction, spell_animation_duration * 0.28)
	await play_moonblade_impact(owner, second_card, second_hit_direction)

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(blade, "modulate:a", 0.0, spell_animation_duration * 0.18)
	fade_tween.tween_property(blade, "scale", Vector2(0.40, 0.40), spell_animation_duration * 0.18)
	await fade_tween.finished
	blade.queue_free()


func fly_moonblade_segment(owner: Node, blade: Panel, target_center: Vector2, direction: Vector2, duration: float) -> void:
	if owner == null or blade == null:
		return

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(blade, "global_position", target_center - blade.pivot_offset, duration)
	tween.tween_property(blade, "rotation", blade.rotation + TAU * 2.4, duration)
	tween.tween_property(blade, "scale", Vector2(1.20, 1.20), duration)
	if direction.length() > 0.01:
		tween.tween_property(blade, "self_modulate", Color(0.80, 0.94, 1.0, 1.0), duration * 0.5)
	await tween.finished


func play_moonblade_impact(owner: Node, target_card: Card, direction: Vector2) -> void:
	if owner == null or target_card == null:
		return

	var start_position: Vector2 = target_card.position
	var start_scale: Vector2 = target_card.scale
	var start_modulate: Color = target_card.self_modulate
	var start_z_index: int = target_card.z_index
	var shake_offset := direction * attack_target_shake_distance
	if shake_offset.length() <= 0.01:
		shake_offset = Vector2(0, -attack_target_shake_distance)

	target_card.is_animating = true
	target_card.z_index = 1190

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target_card, "position", start_position + shake_offset, spell_animation_duration * 0.08)
	tween.tween_property(target_card, "scale", start_scale * 0.96, spell_animation_duration * 0.08)
	tween.tween_property(target_card, "self_modulate", Color(0.72, 0.90, 1.0, 1.0), spell_animation_duration * 0.08)
	await tween.finished

	var recover := owner.create_tween()
	recover.set_parallel(true)
	recover.set_trans(Tween.TRANS_BACK)
	recover.set_ease(Tween.EASE_OUT)
	recover.tween_property(target_card, "position", start_position, spell_animation_duration * 0.14)
	recover.tween_property(target_card, "scale", start_scale, spell_animation_duration * 0.14)
	recover.tween_property(target_card, "self_modulate", start_modulate, spell_animation_duration * 0.14)
	await recover.finished

	target_card.position = start_position
	target_card.scale = start_scale
	target_card.self_modulate = start_modulate
	target_card.z_index = start_z_index
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


func play_fel_spell_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var is_madness := animation_key == "fel_madness"
	var rift := create_rect_spell_effect(target_rect, "FelRift", create_fel_rift_style(is_madness), 1.24)
	var core := create_rect_spell_effect(target_rect, "FelCore", create_fel_core_style(is_madness), 0.54)
	var sigil := create_fel_sigil(target_rect, is_madness)
	var embers := create_fel_embers_for_rect(target_rect, is_madness)

	effect_root.add_child(rift)
	effect_root.add_child(core)
	effect_root.add_child(sigil)
	for ember in embers:
		effect_root.add_child(ember)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(rift, "modulate:a", 0.92, spell_animation_duration * 0.34)
	rise_tween.tween_property(rift, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.34)
	rise_tween.tween_property(rift, "rotation", -0.24, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "modulate:a", 0.88, spell_animation_duration * 0.34)
	rise_tween.tween_property(core, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "modulate:a", 0.96, spell_animation_duration * 0.34)
	rise_tween.tween_property(sigil, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.34)
	for ember in embers:
		var offset: Vector2 = ember.get_meta("fel_ember_offset", Vector2.ZERO)
		rise_tween.tween_property(ember, "global_position", ember.global_position + offset * 0.22, spell_animation_duration * 0.34)
		rise_tween.tween_property(ember, "modulate:a", 0.86, spell_animation_duration * 0.34)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(rift, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.72)
	burst_tween.tween_property(rift, "rotation", 0.58, spell_animation_duration * 0.72)
	burst_tween.tween_property(rift, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "scale", Vector2(0.38, 0.38) if is_madness else Vector2(1.56, 1.56), spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.18), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "scale", Vector2(1.46, 1.46), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for ember in embers:
		var offset: Vector2 = ember.get_meta("fel_ember_offset", Vector2.ZERO)
		burst_tween.tween_property(ember, "global_position", ember.global_position + offset, spell_animation_duration * 0.72)
		burst_tween.tween_property(ember, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.72)
		burst_tween.tween_property(ember, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burst_tween.finished

	rift.queue_free()
	core.queue_free()
	sigil.queue_free()
	for ember in embers:
		ember.queue_free()


func play_mana_burn_spell(owner: Node, effect_root: Control, caster_card: Card, target_card: Card) -> void:
	if owner == null or effect_root == null or caster_card == null or target_card == null:
		return

	var caster_rect := caster_card.get_global_rect()
	var target_rect := target_card.get_global_rect()
	var source_point := target_rect.get_center()
	var destination_point := caster_rect.get_center()
	var burn_vector := destination_point - source_point
	if burn_vector.length() <= 0.01:
		return

	var pillar := create_rect_spell_effect(target_rect, "ManaBurnPillar", create_mana_burn_pillar_style(), 0.76)
	var core := create_rect_spell_effect(caster_rect, "ManaBurnCore", create_mana_burn_core_style(), 0.46)
	var beam := create_mana_burn_beam(source_point, destination_point)
	effect_root.add_child(pillar)
	effect_root.add_child(beam)
	effect_root.add_child(core)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(pillar, "scale", Vector2(1.12, 1.26), spell_animation_duration * 0.32)
	rise_tween.tween_property(pillar, "modulate:a", 0.92, spell_animation_duration * 0.32)
	rise_tween.tween_property(beam, "scale:x", 1.0, spell_animation_duration * 0.42)
	rise_tween.tween_property(beam, "modulate:a", 0.88, spell_animation_duration * 0.42)
	rise_tween.tween_property(core, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.42)
	rise_tween.tween_property(core, "modulate:a", 0.82, spell_animation_duration * 0.42)
	await rise_tween.finished

	var drain_tween := owner.create_tween()
	drain_tween.set_parallel(true)
	drain_tween.set_trans(Tween.TRANS_CUBIC)
	drain_tween.set_ease(Tween.EASE_OUT)
	drain_tween.tween_property(pillar, "scale", Vector2(0.58, 1.82), spell_animation_duration * 0.70)
	drain_tween.tween_property(pillar, "modulate:a", 0.0, spell_animation_duration * 0.70)
	drain_tween.tween_property(beam, "scale:y", 1.80, spell_animation_duration * 0.46)
	drain_tween.tween_property(beam, "modulate:a", 0.0, spell_animation_duration * 0.70)
	drain_tween.tween_property(core, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.70)
	drain_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.70)
	await drain_tween.finished

	pillar.queue_free()
	beam.queue_free()
	core.queue_free()


func play_gu_lure_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var snare := create_gu_lure_effect_for_rect(target_rect)
	var pulse := create_rect_spell_effect(target_rect, "GuLurePulseEffect", create_gu_lure_pulse_style(), 1.04)
	effect_root.add_child(pulse)
	effect_root.add_child(snare)

	var bloom_tween := owner.create_tween()
	bloom_tween.set_parallel(true)
	bloom_tween.set_trans(Tween.TRANS_SINE)
	bloom_tween.set_ease(Tween.EASE_OUT)
	bloom_tween.tween_property(snare, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.42)
	bloom_tween.tween_property(snare, "rotation", 0.14, spell_animation_duration * 0.42)
	bloom_tween.tween_property(snare, "modulate:a", 0.88, spell_animation_duration * 0.42)
	bloom_tween.tween_property(pulse, "scale", Vector2(1.22, 1.22), spell_animation_duration * 0.42)
	bloom_tween.tween_property(pulse, "modulate:a", 0.55, spell_animation_duration * 0.42)
	await bloom_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(snare, "scale", Vector2(1.55, 1.55), spell_animation_duration * 0.70)
	fade_tween.tween_property(snare, "rotation", 0.72, spell_animation_duration * 0.70)
	fade_tween.tween_property(snare, "modulate:a", 0.0, spell_animation_duration * 0.70)
	fade_tween.tween_property(pulse, "scale", Vector2(1.90, 1.90), spell_animation_duration * 0.70)
	fade_tween.tween_property(pulse, "modulate:a", 0.0, spell_animation_duration * 0.70)
	await fade_tween.finished

	snare.queue_free()
	pulse.queue_free()


func play_gu_life_link_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var ring := create_life_link_effect_for_rect(target_rect)
	effect_root.add_child(ring)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.78)
	tween.tween_property(ring, "rotation", -0.42, spell_animation_duration * 0.78)
	tween.tween_property(ring, "modulate:a", 0.0, spell_animation_duration * 0.78)
	await tween.finished

	ring.queue_free()


func play_gu_life_link_larva_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var cocoon := create_life_link_larva_effect_for_rect(target_rect)
	var pulse := create_rect_spell_effect(target_rect, "GuLifeLinkLarvaPulse", create_life_link_larva_pulse_style(), 0.62)
	effect_root.add_child(cocoon)
	effect_root.add_child(pulse)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_SINE)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(cocoon, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.42)
	bind_tween.tween_property(cocoon, "modulate:a", 0.92, spell_animation_duration * 0.42)
	bind_tween.tween_property(pulse, "scale", Vector2(0.84, 0.84), spell_animation_duration * 0.42)
	bind_tween.tween_property(pulse, "modulate:a", 0.78, spell_animation_duration * 0.42)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(cocoon, "scale", Vector2(1.44, 1.44), spell_animation_duration * 0.66)
	fade_tween.tween_property(cocoon, "rotation", 0.22, spell_animation_duration * 0.66)
	fade_tween.tween_property(cocoon, "modulate:a", 0.0, spell_animation_duration * 0.66)
	fade_tween.tween_property(pulse, "scale", Vector2(0.28, 0.28), spell_animation_duration * 0.66)
	fade_tween.tween_property(pulse, "modulate:a", 0.0, spell_animation_duration * 0.66)
	await fade_tween.finished

	cocoon.queue_free()
	pulse.queue_free()


func play_thin_burial_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var shroud := create_thin_burial_effect_for_rect(target_rect)
	var seal := create_rect_spell_effect(target_rect, "ThinBurialSealEffect", create_thin_burial_seal_style(), 0.92)
	effect_root.add_child(shroud)
	effect_root.add_child(seal)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_SINE)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(shroud, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.46)
	bind_tween.tween_property(shroud, "modulate:a", 0.86, spell_animation_duration * 0.46)
	bind_tween.tween_property(seal, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.46)
	bind_tween.tween_property(seal, "rotation", -0.18, spell_animation_duration * 0.46)
	bind_tween.tween_property(seal, "modulate:a", 0.72, spell_animation_duration * 0.46)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(shroud, "scale", Vector2(1.38, 1.38), spell_animation_duration * 0.62)
	fade_tween.tween_property(shroud, "modulate:a", 0.0, spell_animation_duration * 0.62)
	fade_tween.tween_property(seal, "scale", Vector2(1.62, 1.62), spell_animation_duration * 0.62)
	fade_tween.tween_property(seal, "rotation", -0.52, spell_animation_duration * 0.62)
	fade_tween.tween_property(seal, "modulate:a", 0.0, spell_animation_duration * 0.62)
	await fade_tween.finished

	shroud.queue_free()
	seal.queue_free()


func play_sacrifice_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var sigil := create_rect_spell_effect(target_rect, "SacrificeSigilEffect", create_sacrifice_sigil_style(), 1.22)
	var drain := create_rect_spell_effect(target_rect, "SacrificeDrainEffect", create_sacrifice_drain_style(), 0.74)
	var motes: Array[Panel] = create_sacrifice_motes_for_rect(target_rect)
	effect_root.add_child(sigil)
	effect_root.add_child(drain)
	for mote in motes:
		effect_root.add_child(mote)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_CUBIC)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(sigil, "modulate:a", 0.96, spell_animation_duration * 0.28)
	bind_tween.tween_property(sigil, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.28)
	bind_tween.tween_property(drain, "modulate:a", 0.82, spell_animation_duration * 0.28)
	bind_tween.tween_property(drain, "scale", Vector2(0.78, 0.78), spell_animation_duration * 0.28)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(sigil, "scale", Vector2(1.44, 1.44), spell_animation_duration * 0.72)
	fade_tween.tween_property(sigil, "rotation", 0.44, spell_animation_duration * 0.72)
	fade_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade_tween.tween_property(drain, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.72)
	fade_tween.tween_property(drain, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("sacrifice_offset", Vector2.ZERO)
		fade_tween.tween_property(mote, "global_position", mote.global_position + offset, spell_animation_duration * 0.72)
		fade_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await fade_tween.finished

	sigil.queue_free()
	drain.queue_free()
	for mote in motes:
		mote.queue_free()


func play_reborn_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var halo := create_rect_spell_effect(target_rect, "RebornHaloEffect", create_reborn_halo_style(), 1.30)
	var core := create_rect_spell_effect(target_rect, "RebornCoreEffect", create_reborn_core_style(), 0.58)
	effect_root.add_child(halo)
	effect_root.add_child(core)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(halo, "modulate:a", 0.90, spell_animation_duration * 0.36)
	rise_tween.tween_property(halo, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.36)
	rise_tween.tween_property(halo, "rotation", -0.16, spell_animation_duration * 0.36)
	rise_tween.tween_property(core, "modulate:a", 0.96, spell_animation_duration * 0.36)
	rise_tween.tween_property(core, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	await rise_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(halo, "scale", Vector2(1.56, 1.56), spell_animation_duration * 0.72)
	fade_tween.tween_property(halo, "rotation", 0.36, spell_animation_duration * 0.72)
	fade_tween.tween_property(halo, "modulate:a", 0.0, spell_animation_duration * 0.72)
	fade_tween.tween_property(core, "global_position", core.global_position + Vector2(0.0, -target_rect.size.y * 0.22), spell_animation_duration * 0.72)
	fade_tween.tween_property(core, "scale", Vector2(0.42, 0.42), spell_animation_duration * 0.72)
	fade_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await fade_tween.finished

	halo.queue_free()
	core.queue_free()


func play_beastmen_survival_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var is_slaughter := animation_key == "beastmen_slaughter"
	var is_roar := animation_key == "savage_roar"
	var is_wanmo_charge := animation_key == "wanmo_charge"
	var is_wanmo_ritual := animation_key == "wanmo_ritual"
	var ring := create_rect_spell_effect(target_rect, "BeastmenSurvivalRing", create_beastmen_survival_ring_style(is_slaughter), 1.32)
	var core := create_rect_spell_effect(target_rect, "BeastmenSurvivalCore", create_beastmen_survival_core_style(is_slaughter), 0.66 if is_slaughter else 0.58)
	var sigil := create_beastmen_survival_sigil(target_rect, is_slaughter, is_roar, is_wanmo_charge, is_wanmo_ritual)
	var shards := create_beastmen_survival_shards_for_rect(target_rect, is_slaughter)

	effect_root.add_child(ring)
	effect_root.add_child(core)
	effect_root.add_child(sigil)
	for shard in shards:
		effect_root.add_child(shard)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(ring, "modulate:a", 0.94, spell_animation_duration * 0.36)
	rise_tween.tween_property(ring, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.36)
	rise_tween.tween_property(ring, "rotation", -0.28 if is_slaughter else 0.20, spell_animation_duration * 0.36)
	rise_tween.tween_property(core, "modulate:a", 0.90, spell_animation_duration * 0.36)
	rise_tween.tween_property(core, "scale", Vector2(1.24, 1.24), spell_animation_duration * 0.36)
	rise_tween.tween_property(sigil, "modulate:a", 0.96, spell_animation_duration * 0.36)
	rise_tween.tween_property(sigil, "scale", Vector2(1.12, 1.12), spell_animation_duration * 0.36)
	for shard in shards:
		var offset: Vector2 = shard.get_meta("beastmen_survival_offset", Vector2.ZERO)
		rise_tween.tween_property(shard, "global_position", shard.global_position + offset * 0.22, spell_animation_duration * 0.36)
		rise_tween.tween_property(shard, "modulate:a", 0.88, spell_animation_duration * 0.36)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(ring, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.72)
	burst_tween.tween_property(ring, "rotation", 0.62 if is_slaughter else -0.48, spell_animation_duration * 0.72)
	burst_tween.tween_property(ring, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "scale", Vector2(0.36, 0.36) if is_slaughter else Vector2(1.82, 1.82), spell_animation_duration * 0.72)
	burst_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.20), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "scale", Vector2(1.42, 1.42) if is_slaughter else Vector2(1.70, 1.70), spell_animation_duration * 0.72)
	burst_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for shard in shards:
		var offset: Vector2 = shard.get_meta("beastmen_survival_offset", Vector2.ZERO)
		burst_tween.tween_property(shard, "global_position", shard.global_position + offset, spell_animation_duration * 0.72)
		burst_tween.tween_property(shard, "scale", Vector2(0.30, 0.30), spell_animation_duration * 0.72)
		burst_tween.tween_property(shard, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burst_tween.finished

	ring.queue_free()
	core.queue_free()
	sigil.queue_free()
	for shard in shards:
		shard.queue_free()


func play_savage_roar_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var shockwave := create_rect_spell_effect(target_rect, "SavageRoarShockwave", create_beastmen_roar_shockwave_style(), 1.42)
	var throat_glow := create_rect_spell_effect(target_rect, "SavageRoarThroatGlow", create_beastmen_roar_core_style(), 0.52)
	var sigil := create_beastmen_spell_sigil(target_rect, "吼", Color(1.0, 0.54, 0.10, 0.98), 0.46)
	var streaks := create_beastmen_radial_streaks_for_rect(target_rect, "SavageRoarStreak", 10, Color(1.0, 0.28, 0.04, 0.90), Color(1.0, 0.78, 0.22, 0.78))

	effect_root.add_child(shockwave)
	effect_root.add_child(throat_glow)
	effect_root.add_child(sigil)
	for streak in streaks:
		effect_root.add_child(streak)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_BACK)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(shockwave, "modulate:a", 0.92, spell_animation_duration * 0.30)
	rise_tween.tween_property(shockwave, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.30)
	rise_tween.tween_property(throat_glow, "modulate:a", 0.96, spell_animation_duration * 0.30)
	rise_tween.tween_property(throat_glow, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.30)
	rise_tween.tween_property(sigil, "modulate:a", 1.0, spell_animation_duration * 0.30)
	rise_tween.tween_property(sigil, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.30)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(shockwave, "scale", Vector2(1.96, 1.96), spell_animation_duration * 0.76)
	burst_tween.tween_property(shockwave, "modulate:a", 0.0, spell_animation_duration * 0.76)
	burst_tween.tween_property(throat_glow, "scale", Vector2(0.34, 0.34), spell_animation_duration * 0.76)
	burst_tween.tween_property(throat_glow, "modulate:a", 0.0, spell_animation_duration * 0.76)
	burst_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.22), spell_animation_duration * 0.76)
	burst_tween.tween_property(sigil, "scale", Vector2(1.62, 1.62), spell_animation_duration * 0.76)
	burst_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.76)
	for streak in streaks:
		var offset: Vector2 = streak.get_meta("beastmen_spell_offset", Vector2.ZERO)
		burst_tween.tween_property(streak, "global_position", streak.global_position + offset, spell_animation_duration * 0.76)
		burst_tween.tween_property(streak, "scale", Vector2(0.28, 0.28), spell_animation_duration * 0.76)
		burst_tween.tween_property(streak, "modulate:a", 0.0, spell_animation_duration * 0.76)
	await burst_tween.finished

	shockwave.queue_free()
	throat_glow.queue_free()
	sigil.queue_free()
	for streak in streaks:
		streak.queue_free()


func play_wild_call_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var ring := create_rect_spell_effect(target_rect, "WildCallRitualRing", create_wild_call_ring_style(), 1.28)
	var smoke := create_rect_spell_effect(target_rect, "WildCallSmoke", create_wild_call_smoke_style(), 0.84)
	var sigil := create_beastmen_spell_sigil(target_rect, "兽", Color(0.92, 0.96, 0.42, 0.98), 0.42)
	var call_marks := create_beastmen_radial_streaks_for_rect(target_rect, "WildCallTotemSpark", 8, Color(0.42, 0.72, 0.14, 0.90), Color(1.0, 0.82, 0.28, 0.72))

	effect_root.add_child(ring)
	effect_root.add_child(smoke)
	effect_root.add_child(sigil)
	for call_mark in call_marks:
		effect_root.add_child(call_mark)

	var gather_tween := owner.create_tween()
	gather_tween.set_parallel(true)
	gather_tween.set_trans(Tween.TRANS_BACK)
	gather_tween.set_ease(Tween.EASE_OUT)
	gather_tween.tween_property(ring, "modulate:a", 0.90, spell_animation_duration * 0.36)
	gather_tween.tween_property(ring, "rotation", -0.18, spell_animation_duration * 0.36)
	gather_tween.tween_property(smoke, "modulate:a", 0.78, spell_animation_duration * 0.36)
	gather_tween.tween_property(smoke, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	gather_tween.tween_property(sigil, "modulate:a", 0.95, spell_animation_duration * 0.36)
	await gather_tween.finished

	var release_tween := owner.create_tween()
	release_tween.set_parallel(true)
	release_tween.set_trans(Tween.TRANS_SINE)
	release_tween.set_ease(Tween.EASE_OUT)
	release_tween.tween_property(ring, "scale", Vector2(1.58, 1.58), spell_animation_duration * 0.74)
	release_tween.tween_property(ring, "rotation", 0.54, spell_animation_duration * 0.74)
	release_tween.tween_property(ring, "modulate:a", 0.0, spell_animation_duration * 0.74)
	release_tween.tween_property(smoke, "scale", Vector2(1.62, 1.62), spell_animation_duration * 0.74)
	release_tween.tween_property(smoke, "modulate:a", 0.0, spell_animation_duration * 0.74)
	release_tween.tween_property(sigil, "scale", Vector2(1.48, 1.48), spell_animation_duration * 0.74)
	release_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.74)
	for call_mark in call_marks:
		var offset: Vector2 = call_mark.get_meta("beastmen_spell_offset", Vector2.ZERO)
		release_tween.tween_property(call_mark, "global_position", call_mark.global_position + offset * 0.82, spell_animation_duration * 0.74)
		release_tween.tween_property(call_mark, "modulate:a", 0.0, spell_animation_duration * 0.74)
	await release_tween.finished

	ring.queue_free()
	smoke.queue_free()
	sigil.queue_free()
	for call_mark in call_marks:
		call_mark.queue_free()


func play_wanmo_ritual_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var ritual_ring := create_rect_spell_effect(target_rect, "WanmoRitualRing", create_wanmo_ritual_ring_style(), 1.46)
	var rift := create_rect_spell_effect(target_rect, "WanmoRitualRift", create_wanmo_ritual_rift_style(), 0.70)
	var sigil := create_beastmen_spell_sigil(target_rect, "仪", Color(1.0, 0.16, 0.08, 0.98), 0.48)
	var fragments := create_beastmen_radial_streaks_for_rect(target_rect, "WanmoRitualFragment", 12, Color(0.55, 0.02, 0.00, 0.95), Color(1.0, 0.22, 0.08, 0.82))

	effect_root.add_child(ritual_ring)
	effect_root.add_child(rift)
	effect_root.add_child(sigil)
	for fragment in fragments:
		effect_root.add_child(fragment)

	var open_tween := owner.create_tween()
	open_tween.set_parallel(true)
	open_tween.set_trans(Tween.TRANS_BACK)
	open_tween.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(ritual_ring, "modulate:a", 0.94, spell_animation_duration * 0.38)
	open_tween.tween_property(ritual_ring, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.38)
	open_tween.tween_property(ritual_ring, "rotation", -0.42, spell_animation_duration * 0.38)
	open_tween.tween_property(rift, "modulate:a", 0.90, spell_animation_duration * 0.38)
	open_tween.tween_property(rift, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.38)
	open_tween.tween_property(sigil, "modulate:a", 1.0, spell_animation_duration * 0.38)
	open_tween.tween_property(sigil, "scale", Vector2(1.15, 1.15), spell_animation_duration * 0.38)
	await open_tween.finished

	var collapse_tween := owner.create_tween()
	collapse_tween.set_parallel(true)
	collapse_tween.set_trans(Tween.TRANS_EXPO)
	collapse_tween.set_ease(Tween.EASE_OUT)
	collapse_tween.tween_property(ritual_ring, "scale", Vector2(1.82, 1.82), spell_animation_duration * 0.86)
	collapse_tween.tween_property(ritual_ring, "rotation", 0.76, spell_animation_duration * 0.86)
	collapse_tween.tween_property(ritual_ring, "modulate:a", 0.0, spell_animation_duration * 0.86)
	collapse_tween.tween_property(rift, "scale", Vector2(0.28, 0.28), spell_animation_duration * 0.86)
	collapse_tween.tween_property(rift, "modulate:a", 0.0, spell_animation_duration * 0.86)
	collapse_tween.tween_property(sigil, "global_position", sigil.global_position + Vector2(0.0, -target_rect.size.y * 0.18), spell_animation_duration * 0.86)
	collapse_tween.tween_property(sigil, "scale", Vector2(1.72, 1.72), spell_animation_duration * 0.86)
	collapse_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.86)
	for fragment in fragments:
		var offset: Vector2 = fragment.get_meta("beastmen_spell_offset", Vector2.ZERO)
		collapse_tween.tween_property(fragment, "global_position", fragment.global_position + offset * 1.08, spell_animation_duration * 0.86)
		collapse_tween.tween_property(fragment, "rotation", fragment.rotation + 1.10, spell_animation_duration * 0.86)
		collapse_tween.tween_property(fragment, "modulate:a", 0.0, spell_animation_duration * 0.86)
	await collapse_tween.finished

	ritual_ring.queue_free()
	rift.queue_free()
	sigil.queue_free()
	for fragment in fragments:
		fragment.queue_free()


func play_board_effect(owner: Node, effect_root: Control, animation_key: String) -> void:
	if owner == null or effect_root == null or animation_key == "":
		return

	match animation_key:
		"chaos_corruption_burst":
			await play_chaos_corruption_board_burst(owner, effect_root)
		_:
			return


func play_path_effect(owner: Node, effect_root: Control, target_rects: Array[Rect2], animation_key: String) -> void:
	if owner == null or effect_root == null or target_rects.is_empty():
		return

	match animation_key:
		"beast_path":
			await play_beast_path_line_effect(owner, effect_root, target_rects)
		_:
			return


func play_beast_path_line_effect(owner: Node, effect_root: Control, target_rects: Array[Rect2]) -> void:
	var segments: Array[Panel] = []
	var sigils: Array[Label] = []
	for index in range(target_rects.size()):
		var rect := target_rects[index]
		if rect.size == Vector2.ZERO:
			continue
		var segment := create_rect_spell_effect(rect, "BeastPathSegment_%d" % index, create_beast_path_segment_style(index), 1.04)
		var sigil := create_beastmen_spell_sigil(rect, "径", Color(0.86, 0.62, 0.26, 0.96), 0.32)
		segment.z_index = 2260
		sigil.z_index = 2268
		effect_root.add_child(segment)
		effect_root.add_child(sigil)
		segments.append(segment)
		sigils.append(sigil)

	var dig_tween := owner.create_tween()
	dig_tween.set_parallel(true)
	dig_tween.set_trans(Tween.TRANS_BACK)
	dig_tween.set_ease(Tween.EASE_OUT)
	for index in range(segments.size()):
		var delay := spell_animation_duration * 0.08 * float(index)
		dig_tween.tween_property(segments[index], "modulate:a", 0.92, spell_animation_duration * 0.28).set_delay(delay)
		dig_tween.tween_property(segments[index], "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.28).set_delay(delay)
		dig_tween.tween_property(sigils[index], "modulate:a", 0.90, spell_animation_duration * 0.28).set_delay(delay)
		dig_tween.tween_property(sigils[index], "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.28).set_delay(delay)
	await dig_tween.finished

	var settle_tween := owner.create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_SINE)
	settle_tween.set_ease(Tween.EASE_IN_OUT)
	for index in range(segments.size()):
		settle_tween.tween_property(segments[index], "scale", Vector2(1.24, 1.24), spell_animation_duration * 0.62)
		settle_tween.tween_property(segments[index], "modulate:a", 0.0, spell_animation_duration * 0.62)
		settle_tween.tween_property(sigils[index], "global_position", sigils[index].global_position + Vector2(0.0, -target_rects[index].size.y * 0.12), spell_animation_duration * 0.62)
		settle_tween.tween_property(sigils[index], "modulate:a", 0.0, spell_animation_duration * 0.62)
	await settle_tween.finished

	for segment in segments:
		segment.queue_free()
	for sigil in sigils:
		sigil.queue_free()


func play_chaos_corruption_board_burst(owner: Node, effect_root: Control) -> void:
	var viewport_size := effect_root.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var veil := ColorRect.new()
	veil.name = "ChaosCorruptionVeil"
	veil.color = Color(0.18, 0.02, 0.00, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 2280

	var pulse := Panel.new()
	pulse.name = "ChaosCorruptionBoardPulse"
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.size = viewport_size * 0.72
	pulse.pivot_offset = pulse.size * 0.5
	pulse.position = (viewport_size - pulse.size) * 0.5
	pulse.modulate = Color(1.0, 1.0, 1.0, 0.0)
	pulse.z_index = 2290
	pulse.add_theme_stylebox_override("panel", create_chaos_corruption_board_pulse_style())

	var sigil := Label.new()
	sigil.name = "ChaosCorruptionBoardSigil"
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil.text = "蚀"
	sigil.size = Vector2(220.0, 220.0)
	sigil.pivot_offset = sigil.size * 0.5
	sigil.position = viewport_size * 0.5 - sigil.pivot_offset
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.modulate = Color(1.0, 1.0, 1.0, 0.0)
	sigil.z_index = 2298
	sigil.add_theme_font_size_override("font_size", 132)
	sigil.add_theme_color_override("font_color", Color(0.86, 0.08, 0.02, 0.96))
	sigil.add_theme_color_override("font_shadow_color", Color(0.02, 0.0, 0.0, 0.96))
	sigil.add_theme_constant_override("shadow_offset_x", 5)
	sigil.add_theme_constant_override("shadow_offset_y", 5)

	var motes := create_chaos_corruption_board_motes(viewport_size)

	effect_root.add_child(veil)
	effect_root.add_child(pulse)
	effect_root.add_child(sigil)
	for mote in motes:
		effect_root.add_child(mote)

	var surge_tween := owner.create_tween()
	surge_tween.set_parallel(true)
	surge_tween.set_trans(Tween.TRANS_CUBIC)
	surge_tween.set_ease(Tween.EASE_OUT)
	surge_tween.tween_property(veil, "color:a", 0.34, spell_animation_duration * 0.42)
	surge_tween.tween_property(pulse, "modulate:a", 0.86, spell_animation_duration * 0.42)
	surge_tween.tween_property(pulse, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.42)
	surge_tween.tween_property(sigil, "modulate:a", 0.94, spell_animation_duration * 0.42)
	surge_tween.tween_property(sigil, "scale", Vector2(1.10, 1.10), spell_animation_duration * 0.42)
	for mote in motes:
		surge_tween.tween_property(mote, "modulate:a", 0.82, spell_animation_duration * 0.42)
	await surge_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(veil, "color:a", 0.0, spell_animation_duration * 0.92)
	fade_tween.tween_property(pulse, "scale", Vector2(1.58, 1.58), spell_animation_duration * 0.92)
	fade_tween.tween_property(pulse, "modulate:a", 0.0, spell_animation_duration * 0.92)
	fade_tween.tween_property(sigil, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.92)
	fade_tween.tween_property(sigil, "modulate:a", 0.0, spell_animation_duration * 0.92)
	for mote in motes:
		var drift: Vector2 = mote.get_meta("chaos_corruption_drift", Vector2.ZERO)
		fade_tween.tween_property(mote, "position", mote.position + drift, spell_animation_duration * 0.92)
		fade_tween.tween_property(mote, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.92)
		fade_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.92)
	await fade_tween.finished

	veil.queue_free()
	pulse.queue_free()
	sigil.queue_free()
	for mote in motes:
		mote.queue_free()


func play_soul_hook_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var snare := create_rect_spell_effect(target_rect, "SoulHookSnareEffect", create_soul_hook_snare_style(), 1.16)
	var core := create_rect_spell_effect(target_rect, "SoulHookCoreEffect", create_soul_hook_core_style(), 0.54)
	var motes: Array[Panel] = create_soul_hook_motes_for_rect(target_rect)
	effect_root.add_child(snare)
	effect_root.add_child(core)
	for mote in motes:
		effect_root.add_child(mote)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_CUBIC)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(snare, "modulate:a", 0.92, spell_animation_duration * 0.36)
	bind_tween.tween_property(snare, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.36)
	bind_tween.tween_property(core, "modulate:a", 0.80, spell_animation_duration * 0.36)
	bind_tween.tween_property(core, "scale", Vector2(0.92, 0.92), spell_animation_duration * 0.36)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(snare, "scale", Vector2(1.38, 1.38), spell_animation_duration * 0.64)
	fade_tween.tween_property(snare, "rotation", -0.28, spell_animation_duration * 0.64)
	fade_tween.tween_property(snare, "modulate:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(core, "scale", Vector2(0.26, 0.26), spell_animation_duration * 0.64)
	fade_tween.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.64)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("soul_hook_offset", Vector2.ZERO)
		fade_tween.tween_property(mote, "global_position", mote.global_position + offset, spell_animation_duration * 0.64)
		fade_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.64)
	await fade_tween.finished

	snare.queue_free()
	core.queue_free()
	for mote in motes:
		mote.queue_free()


func play_charm_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var halo := create_rect_spell_effect(target_rect, "CharmHaloEffect", create_charm_halo_style(), 1.24)
	var heart := create_rect_spell_effect(target_rect, "CharmHeartEffect", create_charm_heart_style(), 0.34)
	var motes: Array[Panel] = create_charm_motes_for_rect(target_rect)
	effect_root.add_child(halo)
	effect_root.add_child(heart)
	for mote in motes:
		effect_root.add_child(mote)

	var bloom_tween := owner.create_tween()
	bloom_tween.set_parallel(true)
	bloom_tween.set_trans(Tween.TRANS_BACK)
	bloom_tween.set_ease(Tween.EASE_OUT)
	bloom_tween.tween_property(halo, "modulate:a", 0.90, spell_animation_duration * 0.35)
	bloom_tween.tween_property(halo, "scale", Vector2(1.08, 1.08), spell_animation_duration * 0.35)
	bloom_tween.tween_property(heart, "modulate:a", 0.92, spell_animation_duration * 0.35)
	bloom_tween.tween_property(heart, "scale", Vector2(1.20, 1.20), spell_animation_duration * 0.35)
	await bloom_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(halo, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.65)
	fade_tween.tween_property(halo, "modulate:a", 0.0, spell_animation_duration * 0.65)
	fade_tween.tween_property(heart, "global_position", heart.global_position + Vector2(0, -target_rect.size.y * 0.28), spell_animation_duration * 0.65)
	fade_tween.tween_property(heart, "scale", Vector2(0.62, 0.62), spell_animation_duration * 0.65)
	fade_tween.tween_property(heart, "modulate:a", 0.0, spell_animation_duration * 0.65)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("charm_offset", Vector2.ZERO)
		fade_tween.tween_property(mote, "global_position", mote.global_position + offset, spell_animation_duration * 0.65)
		fade_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.65)
	await fade_tween.finished

	halo.queue_free()
	heart.queue_free()
	for mote in motes:
		mote.queue_free()


func play_life_link_spell(
	owner: Node,
	effect_root: Control,
	first_card: Card,
	second_card: Card,
	spell_data: Dictionary
) -> void:
	if owner == null or effect_root == null or first_card == null or second_card == null:
		return

	var animation_key := str(spell_data.get("animation", "gu_life_link"))
	var is_larva := animation_key == "gu_life_link_larva"
	var first_rect := first_card.get_global_rect()
	var second_rect := second_card.get_global_rect()
	var first_ring := create_life_link_larva_effect_for_rect(first_rect) if is_larva else create_life_link_effect_for_rect(first_rect)
	var second_ring := create_life_link_larva_effect_for_rect(second_rect) if is_larva else create_life_link_effect_for_rect(second_rect)
	var tether := Line2D.new()
	tether.name = "GuLifeLinkLarvaTether" if is_larva else "GuLifeLinkTether"
	tether.width = 4.5 if is_larva else 7.0
	tether.default_color = Color(0.90, 0.84, 0.20, 0.0) if is_larva else Color(0.56, 1.0, 0.28, 0.0)
	tether.z_index = 2310
	tether.points = PackedVector2Array([first_rect.get_center(), second_rect.get_center()])
	tether.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tether.end_cap_mode = Line2D.LINE_CAP_ROUND

	effect_root.add_child(tether)
	effect_root.add_child(first_ring)
	effect_root.add_child(second_ring)

	var bind_tween := owner.create_tween()
	bind_tween.set_parallel(true)
	bind_tween.set_trans(Tween.TRANS_SINE)
	bind_tween.set_ease(Tween.EASE_OUT)
	bind_tween.tween_property(tether, "default_color:a", 0.86, spell_animation_duration * 0.36)
	bind_tween.tween_property(first_ring, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	bind_tween.tween_property(first_ring, "modulate:a", 0.92, spell_animation_duration * 0.36)
	bind_tween.tween_property(second_ring, "scale", Vector2(1.18, 1.18), spell_animation_duration * 0.36)
	bind_tween.tween_property(second_ring, "modulate:a", 0.92, spell_animation_duration * 0.36)
	await bind_tween.finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(tether, "width", 2.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(tether, "default_color:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(first_ring, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.64)
	fade_tween.tween_property(first_ring, "modulate:a", 0.0, spell_animation_duration * 0.64)
	fade_tween.tween_property(second_ring, "scale", Vector2(1.64, 1.64), spell_animation_duration * 0.64)
	fade_tween.tween_property(second_ring, "modulate:a", 0.0, spell_animation_duration * 0.64)
	await fade_tween.finished

	tether.queue_free()
	first_ring.queue_free()
	second_ring.queue_free()


func play_gu_summon_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var circle := create_rect_spell_effect(target_rect, "GuSummonCircleEffect", create_gu_summon_circle_style(), 1.22)
	var coil := create_rect_spell_effect(target_rect, "GuSummonCoilEffect", create_gu_summon_coil_style(), 0.92)
	var motes: Array[Panel] = create_gu_summon_motes_for_rect(target_rect)
	effect_root.add_child(circle)
	effect_root.add_child(coil)
	for mote in motes:
		effect_root.add_child(mote)

	var rise_tween := owner.create_tween()
	rise_tween.set_parallel(true)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(circle, "scale", Vector2(1.22, 1.22), spell_animation_duration * 0.46)
	rise_tween.tween_property(circle, "rotation", -0.34, spell_animation_duration * 0.46)
	rise_tween.tween_property(circle, "modulate:a", 0.96, spell_animation_duration * 0.46)
	rise_tween.tween_property(coil, "scale", Vector2(1.44, 1.44), spell_animation_duration * 0.46)
	rise_tween.tween_property(coil, "rotation", 0.62, spell_animation_duration * 0.46)
	rise_tween.tween_property(coil, "modulate:a", 0.82, spell_animation_duration * 0.46)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("gu_summon_offset", Vector2.ZERO)
		rise_tween.tween_property(mote, "position", mote.position + offset * 0.30, spell_animation_duration * 0.46)
		rise_tween.tween_property(mote, "modulate:a", 0.92, spell_animation_duration * 0.46)
	await rise_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(circle, "scale", Vector2(1.74, 1.74), spell_animation_duration * 0.72)
	burst_tween.tween_property(circle, "rotation", -1.05, spell_animation_duration * 0.72)
	burst_tween.tween_property(circle, "modulate:a", 0.0, spell_animation_duration * 0.72)
	burst_tween.tween_property(coil, "scale", Vector2(2.10, 2.10), spell_animation_duration * 0.72)
	burst_tween.tween_property(coil, "rotation", 1.64, spell_animation_duration * 0.72)
	burst_tween.tween_property(coil, "modulate:a", 0.0, spell_animation_duration * 0.72)
	for mote in motes:
		var offset: Vector2 = mote.get_meta("gu_summon_offset", Vector2.ZERO)
		burst_tween.tween_property(mote, "position", mote.position + offset, spell_animation_duration * 0.72)
		burst_tween.tween_property(mote, "scale", Vector2(0.20, 0.20), spell_animation_duration * 0.72)
		burst_tween.tween_property(mote, "modulate:a", 0.0, spell_animation_duration * 0.72)
	await burst_tween.finished

	circle.queue_free()
	coil.queue_free()
	for mote in motes:
		mote.queue_free()


func play_gu_trap_trigger_at_rect(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return

	var bite := create_gu_trap_trigger_effect_for_rect(target_rect)
	var spores: Array[Panel] = create_gu_trap_spores_for_rect(target_rect)
	effect_root.add_child(bite)
	for spore in spores:
		effect_root.add_child(spore)

	var snap_tween := owner.create_tween()
	snap_tween.set_parallel(true)
	snap_tween.set_trans(Tween.TRANS_BACK)
	snap_tween.set_ease(Tween.EASE_OUT)
	snap_tween.tween_property(bite, "scale", Vector2(1.28, 1.28), spell_animation_duration * 0.34)
	snap_tween.tween_property(bite, "modulate:a", 0.96, spell_animation_duration * 0.34)
	for spore in spores:
		var offset: Vector2 = spore.get_meta("trap_offset", Vector2.ZERO)
		snap_tween.tween_property(spore, "position", spore.position + offset * 0.38, spell_animation_duration * 0.34)
		snap_tween.tween_property(spore, "modulate:a", 0.90, spell_animation_duration * 0.34)
	await snap_tween.finished

	var burst_tween := owner.create_tween()
	burst_tween.set_parallel(true)
	burst_tween.set_trans(Tween.TRANS_CUBIC)
	burst_tween.set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(bite, "scale", Vector2(1.72, 1.72), spell_animation_duration * 0.58)
	burst_tween.tween_property(bite, "modulate:a", 0.0, spell_animation_duration * 0.58)
	for spore in spores:
		var offset: Vector2 = spore.get_meta("trap_offset", Vector2.ZERO)
		burst_tween.tween_property(spore, "position", spore.position + offset, spell_animation_duration * 0.58)
		burst_tween.tween_property(spore, "scale", Vector2(0.28, 0.28), spell_animation_duration * 0.58)
		burst_tween.tween_property(spore, "modulate:a", 0.0, spell_animation_duration * 0.58)
	await burst_tween.finished

	bite.queue_free()
	for spore in spores:
		spore.queue_free()


func play_area_spell_cast(owner: Node, effect_root: Control, caster_card: Card, center_card: Card, spell_data: Dictionary) -> void:
	if owner == null or effect_root == null or caster_card == null or center_card == null:
		return

	var animation_key := str(spell_data.get("animation", spell_data.get("id", "")))
	match animation_key:
		"blizzard":
			await play_blizzard_area_spell(owner, effect_root, caster_card, center_card, spell_data)
		"foxfire":
			await play_foxfire_area_spell(owner, effect_root, caster_card, center_card, spell_data)
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

	var area_rect := get_area_spell_rect(center_card, area_rows, area_cols)

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


func play_foxfire_area_spell(owner: Node, effect_root: Control, caster_card: Card, center_card: Card, spell_data: Dictionary) -> void:
	var area_rows: int = int(spell_data.get("area_rows", 2))
	var area_cols: int = int(spell_data.get("area_cols", 2))

	caster_card.is_animating = true
	var caster_start_scale: Vector2 = caster_card.scale
	var caster_start_z_index: int = caster_card.z_index
	caster_card.z_index = 1180

	var charge_duration: float = spell_animation_duration * 0.20
	var charge_tween := owner.create_tween()
	charge_tween.set_parallel(true)
	charge_tween.set_trans(Tween.TRANS_SINE)
	charge_tween.set_ease(Tween.EASE_OUT)
	charge_tween.tween_property(caster_card, "scale", caster_start_scale * 1.06, charge_duration)
	await charge_tween.finished

	var area_rect := get_area_spell_rect(center_card, area_rows, area_cols)
	var foxfire_effect := create_foxfire_area_effect(area_rect)
	effect_root.add_child(foxfire_effect)

	var flame_count := 8
	for i in range(flame_count):
		var flame := create_foxfire_flame()
		foxfire_effect.add_child(flame)
		var x := randf_range(8.0, maxf(8.0, area_rect.size.x - 8.0))
		var y := randf_range(8.0, maxf(8.0, area_rect.size.y - 8.0))
		flame.position = Vector2(x, y) - flame.pivot_offset

	var duration: float = spell_animation_duration * 0.74
	var pulse_tween := owner.create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(foxfire_effect, "modulate:a", 0.92, duration * 0.22)
	pulse_tween.tween_property(foxfire_effect, "scale", Vector2(1.05, 1.05), duration * 0.30)
	await owner.create_tween().tween_interval(duration * 0.46).finished

	var fade_tween := owner.create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(foxfire_effect, "modulate:a", 0.0, duration * 0.32)
	fade_tween.tween_property(foxfire_effect, "scale", Vector2(1.14, 1.14), duration * 0.32)
	fade_tween.tween_property(caster_card, "scale", caster_start_scale, duration * 0.32)
	await fade_tween.finished

	foxfire_effect.queue_free()
	caster_card.scale = caster_start_scale
	caster_card.z_index = caster_start_z_index
	caster_card.is_animating = false


func get_area_spell_rect(anchor_card: Card, area_rows: int, area_cols: int) -> Rect2:
	var anchor_rect: Rect2 = anchor_card.get_global_rect()
	var card_size_ref: Vector2 = anchor_card.size
	var area_size := Vector2(card_size_ref.x * area_cols, card_size_ref.y * area_rows)
	if area_rows % 2 == 0 or area_cols % 2 == 0:
		return Rect2(anchor_rect.position, area_size)

	return Rect2(anchor_rect.get_center() - area_size * 0.5, area_size)


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


func create_foxfire_area_effect(area_rect: Rect2) -> Panel:
	var effect := Panel.new()
	effect.name = "FoxfireAreaEffect"
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = area_rect.size
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = area_rect.get_center() - effect.pivot_offset
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2260

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.22, 0.92, 0.18)
	style.border_color = Color(1.0, 0.48, 0.96, 0.74)
	style.set_border_width_all(5)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.9, 0.18, 1.0, 0.50)
	style.shadow_size = 34
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_foxfire_flame() -> Panel:
	var flame := Panel.new()
	flame.name = "FoxfireFlame"
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flame_size := Vector2(18, 18)
	flame.size = flame_size
	flame.custom_minimum_size = flame_size
	flame.pivot_offset = flame_size * 0.5
	flame.z_index = 2262

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.42, 0.96, 0.74)
	style.border_color = Color(1.0, 0.82, 1.0, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.8, 0.08, 1.0, 0.62)
	style.shadow_size = 14
	flame.add_theme_stylebox_override("panel", style)
	return flame


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


func create_moonblade_projectile() -> Panel:
	var projectile := Panel.new()
	projectile.name = "MoonbladeProjectile"
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.size = Vector2(34, 34)
	projectile.pivot_offset = projectile.size * 0.5
	projectile.modulate = Color(1.0, 1.0, 1.0, 0.96)
	projectile.z_index = 2180
	projectile.add_theme_stylebox_override("panel", create_moonblade_projectile_style())
	return projectile


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


func create_moonblade_projectile_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.88, 1.0, 0.86)
	style.border_color = Color(1.0, 0.98, 0.72, 0.92)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.48, 0.78, 1.0, 0.68)
	style.shadow_size = 20
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


func create_gu_lure_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "GuLureSnareEffect", create_gu_lure_effect_style(), 1.18)


func create_gu_trap_trigger_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "GuTrapTriggerEffect", create_gu_trap_trigger_effect_style(), 1.24)


func create_life_link_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "GuLifeLinkEffect", create_life_link_effect_style(), 1.20)


func create_life_link_larva_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "GuLifeLinkLarvaEffect", create_life_link_larva_effect_style(), 1.04)


func create_thin_burial_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "ThinBurialShroudEffect", create_thin_burial_effect_style(), 1.18)


func create_gu_summon_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center: Vector2 = target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.38
	var mote_size := Vector2(9.0, 9.0)

	for index in range(8):
		var angle: float = TAU * float(index) / 8.0 + PI * 0.08
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.24
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * 0.92
		var mote := Panel.new()
		mote.name = "GuSummonMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center + start_offset - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2330
		mote.set_meta("gu_summon_offset", burst_offset)
		mote.add_theme_stylebox_override("panel", create_gu_summon_mote_style())
		motes.append(mote)

	return motes


func create_medical_practice_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center: Vector2 = target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.36
	var mote_size := Vector2(11.0, 8.0)

	for index in range(7):
		var angle: float = TAU * float(index) / 7.0 - PI * 0.18
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.20
		var release_offset := Vector2(cos(angle), sin(angle)) * radius * 0.82
		var mote := Panel.new()
		mote.name = "MedicalPracticeMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center + start_offset - mote.pivot_offset
		mote.rotation = angle + PI * 0.18
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2330
		mote.set_meta("medical_practice_offset", release_offset)
		mote.add_theme_stylebox_override("panel", create_medical_practice_mote_style())
		motes.append(mote)

	return motes


func create_sacrifice_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center := target_rect.get_center()
	var offsets := [
		Vector2(-target_rect.size.x * 0.28, -target_rect.size.y * 0.46),
		Vector2(target_rect.size.x * 0.24, -target_rect.size.y * 0.52),
		Vector2(-target_rect.size.x * 0.10, -target_rect.size.y * 0.66),
		Vector2(target_rect.size.x * 0.08, -target_rect.size.y * 0.42),
		Vector2(target_rect.size.x * 0.34, -target_rect.size.y * 0.32)
	]

	for index in range(offsets.size()):
		var mote := Panel.new()
		mote.name = "SacrificeSoulMote_%d" % index
		var mote_size := Vector2(11, 11) if index % 2 == 0 else Vector2(8, 8)
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.84)
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.z_index = 2310
		mote.set_meta("sacrifice_offset", offsets[index])
		mote.add_theme_stylebox_override("panel", create_sacrifice_mote_style())
		motes.append(mote)

	return motes


func create_soul_hook_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center := target_rect.get_center()
	var offsets := [
		Vector2(-target_rect.size.x * 0.24, -target_rect.size.y * 0.28),
		Vector2(target_rect.size.x * 0.26, -target_rect.size.y * 0.22),
		Vector2(-target_rect.size.x * 0.12, target_rect.size.y * 0.28),
		Vector2(target_rect.size.x * 0.16, target_rect.size.y * 0.24)
	]

	for index in range(offsets.size()):
		var mote := Panel.new()
		mote.name = "SoulHookMote_%d" % index
		var mote_size := Vector2(9, 9) if index % 2 == 0 else Vector2(7, 7)
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.82)
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.z_index = 2310
		mote.set_meta("soul_hook_offset", offsets[index])
		mote.add_theme_stylebox_override("panel", create_soul_hook_mote_style())
		motes.append(mote)

	return motes


func create_charm_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center := target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.34

	for index in range(8):
		var angle := TAU * float(index) / 8.0 + PI * 0.10
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.28
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * 0.92 + Vector2(0, -target_rect.size.y * 0.12)
		var mote := Panel.new()
		mote.name = "CharmMote_%d" % index
		var mote_size := Vector2(8, 8) if index % 2 == 0 else Vector2(6, 6)
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center + start_offset - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.78)
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.z_index = 2315
		mote.set_meta("charm_offset", burst_offset)
		mote.add_theme_stylebox_override("panel", create_charm_mote_style())
		motes.append(mote)

	return motes


func create_beastmen_survival_sigil(
	target_rect: Rect2,
	is_slaughter: bool,
	is_roar := false,
	is_wanmo_charge := false,
	is_wanmo_ritual := false
) -> Label:
	var label := Label.new()
	label.name = "BeastmenSurvivalSigil"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = get_beastmen_survival_sigil_text(is_slaughter, is_roar, is_wanmo_charge, is_wanmo_ritual)
	label.size = target_rect.size * (Vector2(0.58, 0.58) if is_slaughter else Vector2(0.54, 0.54))
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2355
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * (0.44 if is_slaughter else 0.40)), 22))
	var sigil_color := Color(1.0, 0.42, 0.18, 0.98) if is_slaughter else Color(1.0, 0.68, 0.24, 0.96)
	if is_roar:
		sigil_color = Color(1.0, 0.55, 0.12, 0.98)
	if is_wanmo_charge:
		sigil_color = Color(1.0, 0.30, 0.10, 0.98)
	if is_wanmo_ritual:
		sigil_color = Color(1.0, 0.18, 0.08, 0.98)
	label.add_theme_color_override("font_color", sigil_color)
	label.add_theme_color_override("font_shadow_color", Color(0.16, 0.01, 0.01, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func get_beastmen_survival_sigil_text(
	is_slaughter: bool,
	is_roar: bool,
	is_wanmo_charge: bool,
	is_wanmo_ritual: bool
) -> String:
	if is_wanmo_ritual:
		return "仪"
	if is_wanmo_charge:
		return "岩"
	if is_roar:
		return "吼"
	return "噬" if is_slaughter else "爪"


func create_beastmen_survival_shards_for_rect(target_rect: Rect2, is_slaughter: bool) -> Array[Panel]:
	var shards: Array[Panel] = []
	var center := target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * (0.38 if is_slaughter else 0.34)
	var shard_count := 9 if is_slaughter else 7

	for index in range(shard_count):
		var angle := TAU * float(index) / float(shard_count) + (PI * 0.08 if is_slaughter else -PI * 0.12)
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.22
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * (1.05 if is_slaughter else 0.88)
		var shard := Panel.new()
		shard.name = "BeastmenSurvivalShard_%d" % index
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shard_size := Vector2(10.0, 22.0) if index % 2 == 0 else Vector2(8.0, 16.0)
		shard.size = shard_size
		shard.pivot_offset = shard_size * 0.5
		shard.global_position = center + start_offset - shard.pivot_offset
		shard.rotation = angle + PI * 0.5
		shard.modulate = Color(1.0, 1.0, 1.0, 0.0)
		shard.z_index = 2340
		shard.set_meta("beastmen_survival_offset", burst_offset)
		shard.add_theme_stylebox_override("panel", create_beastmen_survival_shard_style(is_slaughter))
		shards.append(shard)

	return shards


func create_beastmen_spell_sigil(target_rect: Rect2, text: String, font_color: Color, size_multiplier := 0.44) -> Label:
	var label := Label.new()
	label.name = "BeastmenSpellSigil"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size = target_rect.size * Vector2(0.62, 0.62)
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2360
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * size_multiplier), 24))
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func create_beastmen_radial_streaks_for_rect(
	target_rect: Rect2,
	name_prefix: String,
	count: int,
	fill_color: Color,
	border_color: Color
) -> Array[Panel]:
	var streaks: Array[Panel] = []
	var center := target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.40

	for index in range(count):
		var angle := TAU * float(index) / float(count) + PI * 0.07
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.18
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * (1.02 if index % 2 == 0 else 0.82)
		var streak := Panel.new()
		streak.name = "%s_%d" % [name_prefix, index]
		streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var streak_size := Vector2(9.0, 30.0) if index % 2 == 0 else Vector2(7.0, 20.0)
		streak.size = streak_size
		streak.pivot_offset = streak_size * 0.5
		streak.global_position = center + start_offset - streak.pivot_offset
		streak.rotation = angle + PI * 0.5
		streak.modulate = Color(1.0, 1.0, 1.0, 0.0)
		streak.z_index = 2350
		streak.set_meta("beastmen_spell_offset", burst_offset)
		streak.add_theme_stylebox_override("panel", create_beastmen_spell_streak_style(fill_color, border_color))
		streaks.append(streak)

	return streaks


func create_chaos_corruption_board_motes(viewport_size: Vector2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center := viewport_size * 0.5
	var radius := minf(viewport_size.x, viewport_size.y) * 0.42

	for index in range(18):
		var angle := TAU * float(index) / 18.0 + PI * 0.11
		var inward := Vector2(cos(angle), sin(angle)) * radius * (0.35 + 0.035 * float(index % 5))
		var drift := Vector2(cos(angle), sin(angle)) * radius * (0.42 + 0.018 * float(index % 4))
		var mote := Panel.new()
		mote.name = "ChaosCorruptionBoardMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mote_size := Vector2(14.0, 14.0) if index % 3 == 0 else Vector2(9.0, 9.0)
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.position = center + inward - mote.pivot_offset
		mote.scale = Vector2(0.72, 0.72)
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2296
		mote.set_meta("chaos_corruption_drift", drift)
		mote.add_theme_stylebox_override("panel", create_chaos_corruption_mote_style(index))
		motes.append(mote)

	return motes


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


func create_full_moon_motes_for_rect(target_rect: Rect2) -> Array[Panel]:
	var motes: Array[Panel] = []
	var center: Vector2 = target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.44
	var mote_size := Vector2(9.0, 9.0)

	for index in range(10):
		var angle: float = TAU * float(index) / 10.0 - PI * 0.35
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.18
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * 0.96
		var mote := Panel.new()
		mote.name = "FullMoonMote_%d" % index
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mote.size = mote_size
		mote.pivot_offset = mote_size * 0.5
		mote.global_position = center + start_offset - mote.pivot_offset
		mote.modulate = Color(1.0, 1.0, 1.0, 0.0)
		mote.z_index = 2335
		mote.set_meta("full_moon_offset", burst_offset)
		mote.add_theme_stylebox_override("panel", create_full_moon_mote_style())
		motes.append(mote)

	return motes


func create_gu_trap_spores_for_rect(target_rect: Rect2) -> Array[Panel]:
	var spores: Array[Panel] = []
	var center: Vector2 = target_rect.get_center()
	var radius: float = minf(target_rect.size.x, target_rect.size.y) * 0.34
	var spore_size := Vector2(12.0, 12.0)

	for index in range(7):
		var angle: float = TAU * float(index) / 7.0 + PI * 0.12
		var start_offset := Vector2(cos(angle), sin(angle)) * radius * 0.16
		var burst_offset := Vector2(cos(angle), sin(angle)) * radius * 0.86
		var spore := Panel.new()
		spore.name = "GuTrapSpore_%d" % index
		spore.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spore.size = spore_size
		spore.pivot_offset = spore_size * 0.5
		spore.global_position = center + start_offset - spore.pivot_offset
		spore.modulate = Color(1.0, 1.0, 1.0, 0.0)
		spore.z_index = 2330
		spore.set_meta("trap_offset", burst_offset)
		spore.add_theme_stylebox_override("panel", create_gu_trap_spore_style())
		spores.append(spore)

	return spores


func create_baptism_wave_effect_for_rect(target_rect: Rect2) -> Panel:
	return create_rect_spell_effect(target_rect, "BaptismWaveEffect", create_baptism_wave_effect_style(), 1.16)


func create_monkey_spell_symbol(target_rect: Rect2, animation_key: String) -> Label:
	var label := Label.new()
	label.name = "MonkeySpellSymbol"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = get_monkey_spell_symbol(animation_key)
	label.size = target_rect.size * get_monkey_symbol_size_multiplier(animation_key)
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2350
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * get_monkey_symbol_font_scale(animation_key)), 20))
	label.add_theme_color_override("font_color", get_monkey_symbol_color(animation_key))
	label.add_theme_color_override("font_shadow_color", get_monkey_symbol_shadow_color(animation_key))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func create_monkey_spell_accents(target_rect: Rect2, animation_key: String) -> Array[Control]:
	var accents: Array[Control] = []
	match animation_key:
		"fiery_eyes_golden_gaze":
			for index in range(2):
				var x_offset := (-0.18 if index == 0 else 0.18) * target_rect.size.x
				accents.append(create_monkey_accent_panel(
					target_rect,
					"GoldenEyeSlit_%d" % index,
					create_monkey_accent_style(Color(1.0, 0.78, 0.08, 0.82), Color(1.0, 0.96, 0.42, 0.96), 3, 999, Color(1.0, 0.42, 0.05, 0.66), 20),
					Vector2(0.24, 0.055),
					Vector2(x_offset, -target_rect.size.y * 0.13)
				))
			for index in range(3):
				accents.append(create_monkey_accent_panel(
					target_rect,
					"GoldenGazeRay_%d" % index,
					create_monkey_accent_style(Color(1.0, 0.60, 0.02, 0.42), Color(1.0, 0.92, 0.30, 0.66), 2, 3, Color(1.0, 0.46, 0.02, 0.45), 12),
					Vector2(0.58, 0.020),
					Vector2(0.0, target_rect.size.y * (-0.02 + float(index) * 0.10))
				))
		"somersault_cloud":
			for index in range(5):
				var angle := -PI * 0.85 + float(index) * PI * 0.24
				accents.append(create_monkey_accent_panel(
					target_rect,
					"CloudPuff_%d" % index,
					create_monkey_accent_style(Color(0.90, 0.96, 1.0, 0.78), Color(1.0, 0.98, 0.78, 0.70), 2, 999, Color(0.80, 0.94, 1.0, 0.40), 18),
					Vector2(0.18, 0.12),
					Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.25
				))
			accents.append(create_monkey_accent_panel(
				target_rect,
				"CloudGoldTrail",
				create_monkey_accent_style(Color(1.0, 0.70, 0.10, 0.36), Color(1.0, 0.94, 0.44, 0.72), 3, 999, Color(1.0, 0.62, 0.10, 0.45), 18),
				Vector2(0.72, 0.030),
				Vector2(0.0, target_rect.size.y * 0.20)
			))
		"body_beyond_body":
			for index in range(7):
				var angle := TAU * float(index) / 7.0 - PI * 0.5
				var hair := create_monkey_accent_panel(
					target_rect,
					"HairCloneStrand_%d" % index,
					create_monkey_accent_style(Color(0.96, 0.86, 0.62, 0.72), Color(1.0, 0.96, 0.78, 0.80), 2, 999, Color(1.0, 0.78, 0.36, 0.36), 10),
					Vector2(0.035, 0.18),
					Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.30
				)
				hair.rotation = angle + PI * 0.5
				accents.append(hair)
		"bronze_head_iron_arms":
			for index in range(4):
				var y_offset := target_rect.size.y * (-0.22 + float(index) * 0.15)
				accents.append(create_monkey_accent_panel(
					target_rect,
					"BronzePlate_%d" % index,
					create_monkey_accent_style(Color(0.66, 0.42, 0.18, 0.46), Color(1.0, 0.76, 0.36, 0.88), 3, 7, Color(1.0, 0.58, 0.20, 0.35), 16),
					Vector2(0.68, 0.055),
					Vector2(0.0, y_offset)
				))
			for index in range(6):
				var angle := TAU * float(index) / 6.0
				accents.append(create_monkey_accent_panel(
					target_rect,
					"BronzeRivet_%d" % index,
					create_monkey_accent_style(Color(1.0, 0.82, 0.38, 0.88), Color(1.0, 0.98, 0.70, 0.80), 2, 999, Color(1.0, 0.62, 0.20, 0.46), 10),
					Vector2(0.055, 0.055),
					Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.32
				))
		"immortal_peach":
			accents.append(create_monkey_accent_panel(
				target_rect,
				"PeachFruit",
				create_monkey_accent_style(Color(1.0, 0.46, 0.62, 0.82), Color(1.0, 0.88, 0.60, 0.90), 4, 999, Color(1.0, 0.36, 0.58, 0.56), 20),
				Vector2(0.30, 0.24),
				Vector2(0.0, target_rect.size.y * 0.06)
			))
			for index in range(2):
				var leaf := create_monkey_accent_panel(
					target_rect,
					"PeachLeaf_%d" % index,
					create_monkey_accent_style(Color(0.42, 1.0, 0.34, 0.70), Color(0.86, 1.0, 0.58, 0.82), 2, 999, Color(0.40, 1.0, 0.24, 0.36), 12),
					Vector2(0.20, 0.055),
					Vector2(target_rect.size.x * (-0.08 if index == 0 else 0.08), -target_rect.size.y * 0.16)
				)
				leaf.rotation = -0.52 if index == 0 else 0.52
				accents.append(leaf)
		"drive_spirit":
			for index in range(3):
				var talisman := create_monkey_accent_label(target_rect, "敕", "DriveSpiritTalisman_%d" % index, Color(1.0, 0.90, 0.46, 0.94), Color(0.18, 0.08, 0.02, 0.75), 0.22)
				talisman.position += Vector2(target_rect.size.x * (-0.24 + float(index) * 0.24), target_rect.size.y * (-0.10 + float(index % 2) * 0.18))
				talisman.rotation = -0.18 + float(index) * 0.18
				accents.append(talisman)
			accents.append(create_monkey_accent_panel(
				target_rect,
				"DriveSpiritSweep",
				create_monkey_accent_style(Color(0.82, 1.0, 0.90, 0.30), Color(1.0, 0.96, 0.62, 0.82), 4, 999, Color(0.70, 1.0, 0.86, 0.44), 22),
				Vector2(0.82, 0.035),
				Vector2(0.0, target_rect.size.y * 0.22)
			))
		"immobilize":
			for index in range(4):
				var bar := create_monkey_accent_panel(
					target_rect,
					"ImmobilizeSealBar_%d" % index,
					create_monkey_accent_style(Color(1.0, 0.72, 0.08, 0.40), Color(1.0, 0.95, 0.42, 0.86), 3, 5, Color(1.0, 0.64, 0.04, 0.42), 16),
					Vector2(0.72, 0.035),
					Vector2(0.0, target_rect.size.y * (-0.28 + float(index) * 0.19))
				)
				bar.rotation = -0.08 if index % 2 == 0 else 0.08
				accents.append(bar)
		"gather_scatter_qi":
			for index in range(6):
				var mist := create_monkey_accent_panel(
					target_rect,
					"QiMist_%d" % index,
					create_monkey_accent_style(Color(0.82, 0.94, 1.0, 0.34), Color(0.96, 1.0, 1.0, 0.50), 2, 999, Color(0.70, 0.92, 1.0, 0.28), 12),
					Vector2(0.10 + float(index % 3) * 0.05, 0.028),
					Vector2(target_rect.size.x * (-0.30 + float(index % 3) * 0.30), target_rect.size.y * (-0.20 + floorf(float(index) / 3.0) * 0.38))
				)
				mist.rotation = -0.45 + float(index) * 0.18
				accents.append(mist)
		"heavenly_form":
			for index in range(2):
				var pillar := create_monkey_accent_panel(
					target_rect,
					"HeavenlyPillar_%d" % index,
					create_monkey_accent_style(Color(1.0, 0.70, 0.18, 0.28), Color(1.0, 0.92, 0.44, 0.78), 5, 8, Color(1.0, 0.54, 0.12, 0.46), 24),
					Vector2(0.055, 0.82),
					Vector2(target_rect.size.x * (-0.42 if index == 0 else 0.42), 0.0)
				)
				pillar.rotation = -0.06 if index == 0 else 0.06
				accents.append(pillar)
		_:
			accents.append(create_monkey_accent_panel(
				target_rect,
				"MonkeyDefaultAccent",
				create_monkey_accent_style(Color(1.0, 0.72, 0.16, 0.32), Color(1.0, 0.92, 0.46, 0.78), 4, 999, Color(1.0, 0.54, 0.10, 0.42), 20),
				Vector2(0.72, 0.035),
				Vector2.ZERO
			))
	return accents


func create_monkey_accent_panel(
	target_rect: Rect2,
	panel_name: String,
	style: StyleBoxFlat,
	size_multiplier: Vector2,
	center_offset: Vector2
) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = Vector2(target_rect.size.x * size_multiplier.x, target_rect.size.y * size_multiplier.y)
	panel.pivot_offset = panel.size * 0.5
	panel.global_position = target_rect.get_center() + center_offset - panel.pivot_offset
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.z_index = 2340
	panel.add_theme_stylebox_override("panel", style)
	return panel


func create_monkey_accent_label(
	target_rect: Rect2,
	text: String,
	label_name: String,
	font_color: Color,
	shadow_color: Color,
	size_multiplier: float
) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.size = Vector2(target_rect.size.x * size_multiplier, target_rect.size.x * size_multiplier)
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2345
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * size_multiplier * 0.76), 15))
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


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


func create_mana_burn_beam(source_point: Vector2, destination_point: Vector2) -> Panel:
	var beam_vector := destination_point - source_point
	var beam_length := beam_vector.length()
	var beam_size := Vector2(beam_length, 14.0)
	var beam := Panel.new()
	beam.name = "ManaBurnBeam"
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.size = beam_size
	beam.pivot_offset = Vector2(0.0, beam_size.y * 0.5)
	beam.global_position = source_point - beam.pivot_offset
	beam.rotation = beam_vector.angle()
	beam.scale = Vector2(0.0, 1.0)
	beam.modulate = Color(1.0, 1.0, 1.0, 0.0)
	beam.z_index = 2310
	beam.add_theme_stylebox_override("panel", create_mana_burn_beam_style())
	return beam


func create_fel_sigil(target_rect: Rect2, is_madness: bool) -> Label:
	var label := Label.new()
	label.name = "FelSigil"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "FEL" if not is_madness else "RAGE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = target_rect.size * (Vector2(0.78, 0.36) if is_madness else Vector2(0.66, 0.34))
	label.pivot_offset = label.size * 0.5
	label.global_position = target_rect.get_center() - label.pivot_offset
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.z_index = 2303
	label.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * (0.17 if is_madness else 0.19)), 18))
	label.add_theme_color_override("font_color", Color(0.56, 1.0, 0.18, 0.96) if not is_madness else Color(0.72, 1.0, 0.10, 0.98))
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.0, 0.0, 0.96))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func create_fel_embers_for_rect(target_rect: Rect2, is_madness: bool) -> Array[Panel]:
	var embers: Array[Panel] = []
	var ember_count := 9 if is_madness else 7
	var ember_color := Color(0.42, 1.0, 0.08, 0.90) if is_madness else Color(0.18, 1.0, 0.42, 0.86)
	var smoke_color := Color(0.02, 0.02, 0.02, 0.64)
	var radius := minf(target_rect.size.x, target_rect.size.y) * 0.48
	for index in range(ember_count):
		var angle := TAU * float(index) / float(ember_count) + (0.24 if is_madness else -0.18)
		var base_position := target_rect.get_center() + Vector2(cos(angle), sin(angle)) * radius * 0.42
		var ember := Panel.new()
		ember.name = "FelEmber"
		ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ember.size = target_rect.size * Vector2(0.055, 0.055)
		ember.pivot_offset = ember.size * 0.5
		ember.global_position = base_position - ember.pivot_offset
		ember.modulate = Color(1.0, 1.0, 1.0, 0.0)
		ember.z_index = 2302
		ember.add_theme_stylebox_override("panel", create_fel_ember_style(ember_color if index % 3 != 0 else smoke_color))
		ember.set_meta("fel_ember_offset", Vector2(cos(angle), sin(angle)) * radius * (0.92 if is_madness else 0.74))
		embers.append(ember)

	return embers


func create_monkey_spell_aura_style(animation_key: String) -> StyleBoxFlat:
	match animation_key:
		"somersault_cloud":
			return create_monkey_accent_style(Color(0.62, 0.86, 1.0, 0.18), Color(1.0, 0.96, 0.70, 0.76), 6, 999, Color(0.76, 0.92, 1.0, 0.42), 34)
		"body_beyond_body":
			return create_monkey_accent_style(Color(0.86, 0.76, 0.50, 0.15), Color(1.0, 0.88, 0.44, 0.78), 6, 999, Color(1.0, 0.70, 0.22, 0.38), 30)
		"bronze_head_iron_arms":
			return create_monkey_accent_style(Color(0.50, 0.28, 0.12, 0.20), Color(1.0, 0.72, 0.30, 0.86), 8, 22, Color(1.0, 0.48, 0.12, 0.48), 36)
		"immortal_peach":
			return create_monkey_accent_style(Color(1.0, 0.36, 0.54, 0.16), Color(1.0, 0.84, 0.54, 0.84), 7, 999, Color(1.0, 0.42, 0.62, 0.42), 34)
		"drive_spirit":
			return create_monkey_accent_style(Color(0.34, 0.74, 0.68, 0.14), Color(1.0, 0.92, 0.42, 0.82), 7, 18, Color(0.74, 1.0, 0.86, 0.42), 32)
		"immobilize":
			return create_monkey_accent_style(Color(0.76, 0.34, 0.02, 0.20), Color(1.0, 0.84, 0.22, 0.92), 8, 10, Color(1.0, 0.58, 0.04, 0.54), 38)
		"gather_scatter_qi":
			return create_monkey_accent_style(Color(0.72, 0.88, 1.0, 0.12), Color(0.94, 1.0, 1.0, 0.58), 5, 999, Color(0.74, 0.94, 1.0, 0.34), 28)
		"heavenly_form":
			return create_monkey_accent_style(Color(1.0, 0.58, 0.08, 0.16), Color(1.0, 0.90, 0.34, 0.92), 9, 16, Color(1.0, 0.42, 0.04, 0.56), 42)
		_:
			return create_monkey_accent_style(Color(1.0, 0.62, 0.10, 0.18), Color(1.0, 0.88, 0.38, 0.82), 7, 999, Color(1.0, 0.48, 0.08, 0.44), 32)


func create_monkey_spell_core_style(animation_key: String) -> StyleBoxFlat:
	match animation_key:
		"fiery_eyes_golden_gaze":
			return create_monkey_accent_style(Color(1.0, 0.54, 0.04, 0.72), Color(1.0, 0.98, 0.48, 0.94), 4, 999, Color(1.0, 0.32, 0.02, 0.68), 28)
		"somersault_cloud":
			return create_monkey_accent_style(Color(0.92, 0.98, 1.0, 0.70), Color(1.0, 0.96, 0.70, 0.88), 3, 999, Color(0.84, 0.96, 1.0, 0.56), 24)
		"bronze_head_iron_arms":
			return create_monkey_accent_style(Color(0.78, 0.48, 0.20, 0.48), Color(1.0, 0.82, 0.44, 0.92), 5, 10, Color(1.0, 0.56, 0.12, 0.54), 26)
		"immortal_peach":
			return create_monkey_accent_style(Color(1.0, 0.50, 0.66, 0.70), Color(1.0, 0.92, 0.62, 0.92), 4, 999, Color(1.0, 0.38, 0.62, 0.58), 26)
		"drive_spirit":
			return create_monkey_accent_style(Color(0.98, 0.86, 0.34, 0.42), Color(1.0, 0.98, 0.70, 0.92), 4, 7, Color(1.0, 0.78, 0.22, 0.42), 22)
		"immobilize":
			return create_monkey_accent_style(Color(1.0, 0.64, 0.06, 0.46), Color(1.0, 0.96, 0.34, 0.96), 5, 6, Color(1.0, 0.48, 0.02, 0.58), 28)
		"gather_scatter_qi":
			return create_monkey_accent_style(Color(0.86, 0.96, 1.0, 0.30), Color(1.0, 1.0, 1.0, 0.72), 3, 999, Color(0.78, 0.96, 1.0, 0.38), 22)
		"heavenly_form":
			return create_monkey_accent_style(Color(1.0, 0.72, 0.16, 0.36), Color(1.0, 0.96, 0.48, 0.96), 6, 12, Color(1.0, 0.42, 0.04, 0.62), 34)
		_:
			return create_monkey_accent_style(Color(1.0, 0.68, 0.14, 0.42), Color(1.0, 0.94, 0.48, 0.88), 4, 999, Color(1.0, 0.48, 0.10, 0.48), 24)


func create_monkey_accent_style(
	bg_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_color: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	return style


func get_monkey_spell_symbol(animation_key: String) -> String:
	match animation_key:
		"fiery_eyes_golden_gaze":
			return "眼"
		"somersault_cloud":
			return "云"
		"body_beyond_body":
			return "毫"
		"bronze_head_iron_arms":
			return "铁"
		"immortal_peach":
			return "桃"
		"drive_spirit":
			return "敕"
		"immobilize":
			return "定"
		"gather_scatter_qi":
			return "气"
		"heavenly_form":
			return "法"
		_:
			return "猿"


func get_monkey_symbol_color(animation_key: String) -> Color:
	match animation_key:
		"somersault_cloud", "gather_scatter_qi":
			return Color(0.92, 0.98, 1.0, 0.96)
		"immortal_peach":
			return Color(1.0, 0.84, 0.58, 0.98)
		"drive_spirit":
			return Color(1.0, 0.94, 0.52, 0.98)
		"bronze_head_iron_arms":
			return Color(1.0, 0.76, 0.34, 0.98)
		_:
			return Color(1.0, 0.88, 0.30, 0.98)


func get_monkey_symbol_shadow_color(animation_key: String) -> Color:
	match animation_key:
		"somersault_cloud", "gather_scatter_qi":
			return Color(0.05, 0.18, 0.28, 0.86)
		"drive_spirit":
			return Color(0.14, 0.06, 0.02, 0.88)
		_:
			return Color(0.24, 0.08, 0.02, 0.88)


func get_monkey_symbol_size_multiplier(animation_key: String) -> Vector2:
	match animation_key:
		"heavenly_form":
			return Vector2(0.92, 0.92)
		"immobilize":
			return Vector2(0.66, 0.66)
		_:
			return Vector2(0.58, 0.58)


func get_monkey_symbol_font_scale(animation_key: String) -> float:
	match animation_key:
		"heavenly_form":
			return 0.56
		"immobilize":
			return 0.42
		_:
			return 0.36


func get_monkey_spell_core_size(animation_key: String) -> float:
	match animation_key:
		"heavenly_form":
			return 0.82
		"bronze_head_iron_arms", "immobilize":
			return 0.66
		"somersault_cloud":
			return 0.74
		_:
			return 0.54


func get_monkey_spell_core_fade_scale(animation_key: String) -> Vector2:
	match animation_key:
		"gather_scatter_qi":
			return Vector2(0.34, 0.34)
		"heavenly_form":
			return Vector2(1.46, 1.46)
		_:
			return Vector2(1.36, 1.36)


func get_monkey_symbol_fade_scale(animation_key: String) -> Vector2:
	match animation_key:
		"gather_scatter_qi", "body_beyond_body":
			return Vector2(0.45, 0.45)
		"heavenly_form":
			return Vector2(1.34, 1.34)
		_:
			return Vector2(0.74, 0.74)


func get_monkey_symbol_drift(target_rect: Rect2, animation_key: String) -> Vector2:
	match animation_key:
		"somersault_cloud":
			return Vector2(target_rect.size.x * 0.24, -target_rect.size.y * 0.16)
		"gather_scatter_qi":
			return Vector2(0.0, -target_rect.size.y * 0.24)
		"heavenly_form":
			return Vector2(0.0, -target_rect.size.y * 0.08)
		_:
			return Vector2.ZERO


func get_monkey_spell_rotation(animation_key: String) -> float:
	match animation_key:
		"somersault_cloud":
			return 0.58
		"body_beyond_body":
			return -0.82
		"gather_scatter_qi":
			return 0.72
		"heavenly_form":
			return 0.12
		_:
			return 0.36


func get_monkey_accent_alpha(animation_key: String, index: int) -> float:
	match animation_key:
		"gather_scatter_qi":
			return 0.58 + float(index % 3) * 0.08
		"body_beyond_body":
			return 0.82
		"heavenly_form":
			return 0.78
		_:
			return 0.90


func get_monkey_accent_drift(target_rect: Rect2, animation_key: String, index: int) -> Vector2:
	match animation_key:
		"fiery_eyes_golden_gaze":
			return Vector2(target_rect.size.x * (0.30 + float(index % 2) * 0.10), target_rect.size.y * 0.03)
		"somersault_cloud":
			return Vector2(target_rect.size.x * 0.22, -target_rect.size.y * 0.14)
		"body_beyond_body":
			var angle := TAU * float(index) / 7.0 - PI * 0.5
			return Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.24
		"gather_scatter_qi":
			return Vector2(target_rect.size.x * (-0.08 + float(index % 3) * 0.08), -target_rect.size.y * 0.28)
		"heavenly_form":
			return Vector2(0.0, -target_rect.size.y * 0.12)
		_:
			var angle := TAU * float(index) / 6.0
			return Vector2(cos(angle), sin(angle)) * target_rect.size.x * 0.10


func get_monkey_accent_fade_scale(animation_key: String, index: int) -> Vector2:
	match animation_key:
		"gather_scatter_qi", "body_beyond_body":
			return Vector2(0.28, 0.28)
		"heavenly_form":
			return Vector2(1.24 + float(index) * 0.08, 1.24 + float(index) * 0.08)
		"immobilize":
			return Vector2(1.36, 1.08)
		_:
			return Vector2(1.42, 1.42)


func create_fel_rift_style(is_madness: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.13, 0.04, 0.34) if not is_madness else Color(0.12, 0.18, 0.02, 0.36)
	style.border_color = Color(0.36, 1.0, 0.08, 0.88) if not is_madness else Color(0.70, 1.0, 0.06, 0.90)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.10, 1.0, 0.22, 0.44) if not is_madness else Color(0.40, 1.0, 0.02, 0.48)
	style.shadow_size = 34
	return style


func create_fel_core_style(is_madness: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.0, 0.0, 0.74)
	style.border_color = Color(0.48, 1.0, 0.16, 0.92) if not is_madness else Color(0.82, 1.0, 0.08, 0.94)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.18, 1.0, 0.18, 0.58)
	style.shadow_size = 22
	return style


func create_fel_ember_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(color.r, color.g, color.b, minf(color.a + 0.14, 1.0))
	style.set_border_width_all(1)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(color.r, color.g, color.b, 0.42)
	style.shadow_size = 10
	return style


func create_mana_burn_pillar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.48, 0.10, 0.32)
	style.border_color = Color(0.54, 1.0, 0.16, 0.92)
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.18, 1.0, 0.10, 0.62)
	style.shadow_size = 22
	return style


func create_mana_burn_core_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 1.0, 0.24, 0.30)
	style.border_color = Color(0.78, 1.0, 0.20, 0.96)
	style.set_border_width_all(3)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.20, 1.0, 0.04, 0.66)
	style.shadow_size = 18
	return style


func create_mana_burn_beam_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 1.0, 0.08, 0.72)
	style.border_color = Color(0.76, 1.0, 0.26, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.12, 1.0, 0.02, 0.70)
	style.shadow_size = 18
	return style


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


func create_power_word_shield_ward_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.78, 0.28, 0.22)
	style.border_color = Color(1.0, 0.95, 0.62, 0.92)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.78, 0.28, 0.58)
	style.shadow_size = 36
	return style


func create_power_word_shield_sigil_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.96, 0.70, 0.30)
	style.border_color = Color(1.0, 1.0, 0.88, 0.96)
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(1.0, 0.88, 0.46, 0.52)
	style.shadow_size = 22
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


func create_tranquil_spring_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.38, 0.96, 0.88, 0.24)
	style.border_color = Color(0.78, 1.0, 0.94, 0.88)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.42, 0.92, 1.0, 0.58)
	style.shadow_size = 38
	return style


func create_tranquil_spring_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.74, 1.0, 0.88, 0.10)
	style.border_color = Color(0.92, 1.0, 0.88, 0.82)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.68, 1.0, 0.82, 0.48)
	style.shadow_size = 26
	return style


func create_meteor_aura_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.36, 0.14, 0.68, 0.22)
	style.border_color = Color(0.92, 0.80, 1.0, 0.84)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.68, 0.42, 1.0, 0.58)
	style.shadow_size = 40
	return style


func create_meteor_star_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.78, 0.22, 0.78)
	style.border_color = Color(1.0, 0.96, 0.64, 0.96)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.52, 0.12, 0.74)
	style.shadow_size = 30
	return style


func create_meteor_impact_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.36, 0.16, 0.34)
	style.border_color = Color(1.0, 0.82, 0.34, 0.90)
	style.set_border_width_all(8)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(1.0, 0.30, 0.08, 0.62)
	style.shadow_size = 34
	return style


func create_full_moon_disc_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.86, 0.94, 1.0, 0.78)
	style.border_color = Color(1.0, 0.98, 0.78, 0.92)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.70, 0.88, 1.0, 0.70)
	style.shadow_size = 34
	return style


func create_full_moon_halo_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.44, 0.86, 0.16)
	style.border_color = Color(0.68, 0.90, 1.0, 0.78)
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.42, 0.70, 1.0, 0.56)
	style.shadow_size = 40
	return style


func create_full_moon_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.18, 0.06)
	style.border_color = Color(0.92, 0.96, 1.0, 0.84)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.66, 0.82, 1.0, 0.52)
	style.shadow_size = 28
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


func create_gu_lure_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = gu_lure_color
	style.border_color = gu_lure_glow_color
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.shadow_color = gu_lure_glow_color
	style.shadow_size = 34
	return style


func create_gu_lure_pulse_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.24, 0.04, 0.16)
	style.border_color = Color(0.42, 0.92, 0.18, 0.58)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.32, 0.82, 0.12, 0.36)
	style.shadow_size = 26
	return style


func create_gu_trap_trigger_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = gu_trap_trigger_color
	style.border_color = gu_trap_trigger_glow_color
	style.set_border_width_all(9)
	style.set_corner_radius_all(999)
	style.shadow_color = gu_trap_trigger_glow_color
	style.shadow_size = 38
	return style


func create_life_link_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.32, 0.08, 0.18)
	style.border_color = Color(0.58, 1.0, 0.28, 0.82)
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.36, 1.0, 0.18, 0.56)
	style.shadow_size = 34
	return style


func create_life_link_larva_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.34, 0.24, 0.05, 0.22)
	style.border_color = Color(0.90, 0.84, 0.20, 0.82)
	style.set_border_width_all(6)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.54, 1.0, 0.18, 0.42)
	style.shadow_size = 28
	return style


func create_life_link_larva_pulse_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.54, 1.0, 0.20, 0.34)
	style.border_color = Color(1.0, 0.92, 0.32, 0.78)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.72, 1.0, 0.22, 0.58)
	style.shadow_size = 24
	return style


func create_thin_burial_effect_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.05, 0.30)
	style.border_color = Color(0.72, 1.0, 0.34, 0.78)
	style.set_border_width_all(8)
	style.set_corner_radius_all(26)
	style.shadow_color = Color(0.36, 0.90, 0.16, 0.48)
	style.shadow_size = 36
	return style


func create_thin_burial_seal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.03, 0.22)
	style.border_color = Color(0.88, 1.0, 0.46, 0.82)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.58, 1.0, 0.20, 0.52)
	style.shadow_size = 28
	return style


func create_sacrifice_sigil_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.02, 0.08, 0.26)
	style.border_color = Color(1.0, 0.24, 0.34, 0.86)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.12, 0.28, 0.62)
	style.shadow_size = 38
	return style


func create_sacrifice_drain_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.16, 0.26, 0.32)
	style.border_color = Color(1.0, 0.76, 0.58, 0.88)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.28, 0.36, 0.74)
	style.shadow_size = 30
	return style


func create_sacrifice_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.50, 0.58, 0.92)
	style.border_color = Color(1.0, 0.88, 0.70, 0.76)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.16, 0.34, 0.58)
	style.shadow_size = 14
	return style


func create_reborn_halo_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.42, 0.20, 0.24)
	style.border_color = Color(0.82, 1.0, 0.48, 0.86)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.46, 1.0, 0.24, 0.60)
	style.shadow_size = 38
	return style


func create_reborn_core_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.84, 0.32, 0.74)
	style.border_color = Color(1.0, 0.98, 0.66, 0.94)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.72, 1.0, 0.30, 0.72)
	style.shadow_size = 28
	return style


func create_beastmen_survival_ring_style(is_slaughter: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_slaughter:
		style.bg_color = Color(0.34, 0.02, 0.02, 0.26)
		style.border_color = Color(1.0, 0.22, 0.10, 0.90)
		style.shadow_color = Color(0.86, 0.08, 0.02, 0.64)
		style.set_border_width_all(9)
	else:
		style.bg_color = Color(0.22, 0.08, 0.02, 0.22)
		style.border_color = Color(1.0, 0.56, 0.16, 0.88)
		style.shadow_color = Color(1.0, 0.34, 0.04, 0.54)
		style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_size = 40
	return style


func create_beastmen_survival_core_style(is_slaughter: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_slaughter:
		style.bg_color = Color(0.70, 0.04, 0.02, 0.50)
		style.border_color = Color(1.0, 0.70, 0.34, 0.88)
		style.shadow_color = Color(0.92, 0.08, 0.02, 0.70)
	else:
		style.bg_color = Color(0.78, 0.30, 0.04, 0.34)
		style.border_color = Color(1.0, 0.82, 0.42, 0.86)
		style.shadow_color = Color(1.0, 0.42, 0.06, 0.62)
	style.set_border_width_all(5)
	style.set_corner_radius_all(20)
	style.shadow_size = 28
	return style


func create_beastmen_survival_shard_style(is_slaughter: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_slaughter:
		style.bg_color = Color(0.86, 0.10, 0.04, 0.92)
		style.border_color = Color(1.0, 0.62, 0.26, 0.84)
		style.shadow_color = Color(0.92, 0.06, 0.02, 0.60)
	else:
		style.bg_color = Color(0.92, 0.34, 0.06, 0.86)
		style.border_color = Color(1.0, 0.78, 0.34, 0.76)
		style.shadow_color = Color(1.0, 0.28, 0.04, 0.46)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_size = 14
	return style


func create_beastmen_roar_shockwave_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.40, 0.06, 0.00, 0.22)
	style.border_color = Color(1.0, 0.34, 0.04, 0.92)
	style.set_border_width_all(10)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.22, 0.02, 0.62)
	style.shadow_size = 44
	return style


func create_beastmen_roar_core_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.32, 0.02, 0.58)
	style.border_color = Color(1.0, 0.82, 0.28, 0.86)
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(1.0, 0.26, 0.02, 0.72)
	style.shadow_size = 30
	return style


func create_wild_call_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.26, 0.05, 0.24)
	style.border_color = Color(0.86, 0.92, 0.28, 0.84)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.54, 0.82, 0.12, 0.50)
	style.shadow_size = 36
	return style


func create_wild_call_smoke_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.42, 0.10, 0.34)
	style.border_color = Color(1.0, 0.74, 0.20, 0.64)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.62, 0.90, 0.18, 0.42)
	style.shadow_size = 28
	return style


func create_wanmo_ritual_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.00, 0.00, 0.32)
	style.border_color = Color(1.0, 0.08, 0.02, 0.94)
	style.set_border_width_all(11)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.92, 0.02, 0.00, 0.70)
	style.shadow_size = 48
	return style


func create_wanmo_ritual_rift_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.00, 0.00, 0.62)
	style.border_color = Color(1.0, 0.28, 0.08, 0.86)
	style.set_border_width_all(6)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(1.0, 0.04, 0.00, 0.72)
	style.shadow_size = 34
	return style


func create_beastmen_spell_streak_style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = fill_color
	style.shadow_size = 16
	return style


func create_chaos_corruption_board_pulse_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.32, 0.00, 0.00, 0.18)
	style.border_color = Color(0.88, 0.04, 0.00, 0.82)
	style.set_border_width_all(16)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.72, 0.00, 0.00, 0.68)
	style.shadow_size = 72
	return style


func create_chaos_corruption_mote_style(index: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if index % 3 == 0:
		style.bg_color = Color(0.82, 0.02, 0.00, 0.90)
		style.border_color = Color(1.0, 0.22, 0.08, 0.70)
	else:
		style.bg_color = Color(0.28, 0.00, 0.00, 0.82)
		style.border_color = Color(0.90, 0.10, 0.02, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.84, 0.00, 0.00, 0.56)
	style.shadow_size = 18
	return style


func create_beast_path_segment_style(index: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var pulse := 0.04 * float(index % 2)
	style.bg_color = Color(0.30 + pulse, 0.16, 0.04, 0.42)
	style.border_color = Color(0.86, 0.52 + pulse, 0.18, 0.82)
	style.set_border_width_all(5)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.24, 0.62, 0.10, 0.42)
	style.shadow_size = 24
	return style


func create_soul_hook_snare_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.02, 0.20, 0.22)
	style.border_color = Color(1.0, 0.26, 0.62, 0.82)
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.90, 0.18, 0.68, 0.56)
	style.shadow_size = 34
	return style


func create_soul_hook_core_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.86, 0.10, 0.36, 0.30)
	style.border_color = Color(1.0, 0.78, 0.92, 0.78)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.20, 0.62, 0.58)
	style.shadow_size = 24
	return style


func create_soul_hook_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.34, 0.72, 0.90)
	style.border_color = Color(1.0, 0.82, 1.0, 0.70)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.90, 0.18, 0.70, 0.52)
	style.shadow_size = 12
	return style


func create_charm_halo_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.12, 0.64, 0.20)
	style.border_color = Color(1.0, 0.42, 0.88, 0.84)
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.22, 0.72, 0.58)
	style.shadow_size = 38
	return style


func create_charm_heart_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.24, 0.62, 0.82)
	style.border_color = Color(1.0, 0.82, 0.96, 0.94)
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.32, 0.76, 0.72)
	style.shadow_size = 24
	return style


func create_charm_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.52, 0.90, 0.88)
	style.border_color = Color(1.0, 0.88, 1.0, 0.76)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(1.0, 0.26, 0.82, 0.56)
	style.shadow_size = 12
	return style


func create_gu_trap_spore_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.42, 0.05, 0.92)
	style.border_color = Color(0.70, 1.0, 0.20, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.42, 1.0, 0.16, 0.50)
	style.shadow_size = 12
	return style


func create_gu_summon_circle_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = gu_summon_color
	style.border_color = gu_summon_glow_color
	style.set_border_width_all(8)
	style.set_corner_radius_all(999)
	style.shadow_color = gu_summon_glow_color
	style.shadow_size = 38
	return style


func create_gu_summon_coil_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.16, 0.04, 0.10)
	style.border_color = Color(0.78, 1.0, 0.28, 0.62)
	style.set_border_width_all(5)
	style.set_corner_radius_all(42)
	style.shadow_color = Color(0.36, 1.0, 0.18, 0.42)
	style.shadow_size = 30
	return style


func create_gu_summon_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.62, 1.0, 0.22, 0.92)
	style.border_color = Color(0.12, 0.30, 0.04, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.44, 1.0, 0.16, 0.56)
	style.shadow_size = 12
	return style


func create_medical_practice_mist_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.42, 0.08, 0.20)
	style.border_color = Color(0.62, 1.0, 0.34, 0.66)
	style.set_border_width_all(6)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.42, 1.0, 0.24, 0.44)
	style.shadow_size = 30
	return style


func create_medical_practice_ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.78, 0.18, 0.18)
	style.border_color = Color(0.84, 1.0, 0.52, 0.82)
	style.set_border_width_all(5)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.52, 1.0, 0.26, 0.52)
	style.shadow_size = 24
	return style


func create_medical_practice_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 1.0, 0.38, 0.94)
	style.border_color = Color(0.18, 0.42, 0.08, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.52, 1.0, 0.22, 0.58)
	style.shadow_size = 12
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


func create_full_moon_mote_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.96, 1.0, 0.94)
	style.border_color = Color(1.0, 0.98, 0.78, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(0.62, 0.82, 1.0, 0.64)
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
