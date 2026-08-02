extends Control

const Palette := preload("res://scripts/ui/animation/shadowmoon_vfx_palette.gd")
const Toolkit := preload("res://scripts/ui/animation/vfx_canvas_toolkit.gd")

var animation_key := ""
var source_center := Vector2.ZERO
var target_center := Vector2.ZERO
var source_card_size := Vector2(120.0, 168.0)
var target_card_size := Vector2(120.0, 168.0)
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(
	key: String,
	local_source_center: Vector2,
	local_target_center: Vector2,
	local_source_size: Vector2,
	local_target_size: Vector2
) -> void:
	animation_key = key
	source_center = local_source_center
	target_center = local_target_center
	source_card_size = local_source_size
	target_card_size = local_target_size
	queue_redraw()


func _draw() -> void:
	_draw_fel_atmosphere()
	match animation_key:
		"fel_sacrifice":
			_draw_fel_sacrifice(false)
		"fel_sacrifice_heavy":
			_draw_fel_sacrifice(true)
		"fel_infusion", "fel_infusion_transfer":
			_draw_fel_transfer(false)
		"fel_overload", "fel_overload_transfer":
			_draw_fel_transfer(true)
		"fel_infusion_settle":
			_draw_fel_settle(false)
		"fel_overload_settle":
			_draw_fel_settle(true)
		"mana_burn":
			_draw_mana_burn()
		"fel_bite":
			_draw_fel_bite()
		"life_drain":
			_draw_life_drain()
		"life_drain_receive":
			_draw_life_drain_receive()
		"curse", "curse_cast":
			_draw_curse_cast()
		"curse_mark":
			_draw_curse_mark()
		"curse_impact":
			_draw_curse_impact()
		"fel_madness", "fel_madness_chaos_orc":
			_draw_madness_response("chaos_orc")
		"fel_madness_hellhound":
			_draw_madness_response("hellhound")
		"fel_madness_succubus":
			_draw_madness_response("succubus")
		"fel_madness_wolf_rider":
			_draw_madness_response("wolf_rider")
		"fel_madness_doomguard":
			_draw_madness_response("doomguard")
		"fel_madness_warlock":
			_draw_madness_response("warlock")
		"kiljaeden_whisper", "kiljaeden_whisper_mark":
			_draw_kiljaeden_mark()
		"immolation_mark", "fire":
			_draw_immolation(false)
		"immolation_tick":
			_draw_immolation(true)
		"fel_burst", "fel_overload_detonate":
			_draw_overload_detonation()
		"fel_burst_impact":
			_draw_burst_impact()


func _draw_fel_atmosphere() -> void:
	var life := sin(progress * PI)
	if life <= 0.01:
		return
	var scale_value := _target_scale()
	var atmosphere_color := Palette.FEL_GREEN
	if animation_key.begins_with("life_drain"):
		atmosphere_color = Palette.SOUL_PURPLE
	elif animation_key.begins_with("curse") or animation_key.begins_with("kiljaeden"):
		atmosphere_color = Palette.CURSE_RED
	elif animation_key.begins_with("immolation") or animation_key == "fire":
		atmosphere_color = Palette.DEMON_ORANGE
	var breath := 0.90 + sin(progress * TAU * 2.1) * 0.10
	Toolkit.draw_soft_ellipse(
		self,
		target_center,
		Vector2(target_card_size.x * 0.42, target_card_size.y * 0.38) * breath,
		Palette.with_alpha(atmosphere_color, life * 0.095),
		Palette.with_alpha(Palette.VOID, life * 0.12),
		7,
		sin(progress * TAU) * 0.06
	)
	for mote_index in range(7):
		var angle := TAU * float(mote_index) / 7.0 + progress * (1.10 + float(mote_index % 3) * 0.16)
		var mote_center := target_center + Vector2(cos(angle) * target_card_size.x * 0.43, sin(angle) * target_card_size.y * 0.39)
		Toolkit.draw_mote(
			self,
			mote_center,
			scale_value * (0.014 + float(mote_index % 3) * 0.005),
			Palette.with_alpha(atmosphere_color, life * 0.30),
			progress * 10.0 + float(mote_index)
		)


func _draw_fel_sacrifice(is_heavy: bool) -> void:
	var scale_value := _target_scale()
	var gather := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.30))
	var drain := Palette.ease_out(Palette.phase(progress, 0.18, 0.72))
	var rupture := Palette.ease_out(Palette.phase(progress, 0.46, 0.88))
	var settle := 1.0 - Palette.phase(progress, 0.82, 1.0)
	var health_anchor := target_center + Vector2(target_card_size.x * 0.31, target_card_size.y * 0.34)
	var strength := 1.28 if is_heavy else 1.0

	for vein_index in range(7 if is_heavy else 5):
		var ratio := float(vein_index) / float(6 if is_heavy else 4)
		var start := target_center + Vector2(
			lerpf(-target_card_size.x * 0.42, target_card_size.x * 0.34, ratio),
			-target_card_size.y * (0.38 + 0.05 * sin(float(vein_index) * 2.1))
		)
		var control_a := start + Vector2(scale_value * (0.10 - ratio * 0.18), scale_value * 0.30)
		var control_b := health_anchor + Vector2(scale_value * (0.20 - ratio * 0.32), -scale_value * 0.12)
		var vein := _cubic_curve(start, control_a, control_b, health_anchor, drain, 18)
		_draw_layered_line(
			vein,
			Palette.with_alpha(Palette.VOID, 0.88 * settle),
			Palette.with_alpha(Palette.CURSE_RED if vein_index % 2 == 0 else Palette.FEL_GREEN, 0.78 * drain * settle),
			scale_value * 0.040 * strength,
			scale_value * 0.013 * strength
		)

	_draw_pressure_core(health_anchor, scale_value * 0.17 * strength, gather, rupture, settle, Palette.CURSE_RED)
	for crack_index in range(8 if is_heavy else 6):
		var angle := TAU * float(crack_index) / float(8 if is_heavy else 6) + 0.17
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(
			health_anchor,
			health_anchor + direction * scale_value * (0.22 + rupture * 0.30) * strength,
			7,
			scale_value * 0.018
		)
		_draw_safe_polyline(crack, Palette.with_alpha(Palette.VOID, 0.90 * settle), 4.6)
		_draw_safe_polyline(crack, Palette.with_alpha(Palette.ACID, 0.66 * rupture * settle), 1.5)


func _draw_fel_transfer(is_overload: bool) -> void:
	var scale_value := _target_scale()
	var charge := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.24))
	var travel := Palette.ease_out(Palette.phase(progress, 0.18, 0.70))
	var impact := Palette.ease_out(Palette.phase(progress, 0.52, 0.86))
	var settle := 1.0 - Palette.phase(progress, 0.82, 1.0)
	var direction := (target_center - source_center).normalized()
	var normal := direction.orthogonal()
	var stream_count := 5 if is_overload else 3

	_draw_broken_sigil(source_center, scale_value * 0.29, charge, settle, is_overload)
	for stream_index in range(stream_count):
		var offset_ratio := float(stream_index) - float(stream_count - 1) * 0.5
		var offset := normal * scale_value * offset_ratio * 0.055
		var bend := normal * scale_value * (0.28 + absf(offset_ratio) * 0.045) * (-1.0 if stream_index % 2 == 0 else 1.0)
		var curve := _cubic_curve(
			source_center + offset,
			source_center.lerp(target_center, 0.34) + bend,
			source_center.lerp(target_center, 0.68) - bend * 0.72,
			target_center - direction * scale_value * 0.05 + offset * 0.35,
			travel,
			28
		)
		_draw_layered_line(
			curve,
			Palette.with_alpha(Palette.VOID, 0.90 * settle),
			Palette.with_alpha(Palette.HOT_CORE if stream_index == 0 else (Palette.ACID if stream_index % 2 == 0 else Palette.SOUL_PURPLE), (0.88 - absf(offset_ratio) * 0.10) * settle),
			scale_value * (0.075 if is_overload else 0.050),
			scale_value * (0.022 if is_overload else 0.015)
		)

	_draw_target_fissure(target_center, scale_value * (0.42 if is_overload else 0.32), impact, settle, is_overload)
	for mote_index in range(7 if is_overload else 5):
		var mote_phase := fmod(travel * 1.12 + float(mote_index) * 0.13, 1.0)
		var mote_center := source_center.lerp(target_center, mote_phase) + normal * sin(float(mote_index) * 2.31) * scale_value * 0.11
		draw_circle(mote_center, scale_value * (0.020 + float(mote_index % 2) * 0.006), Palette.with_alpha(Palette.ACID, 0.82 * settle))


func _draw_fel_settle(is_overload: bool) -> void:
	var scale_value := _target_scale()
	var invade := Palette.ease_out(Palette.phase(progress, 0.0, 0.62))
	var lock_phase := Palette.ease_in_out(Palette.phase(progress, 0.36, 0.82))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var attack_anchor := target_center + Vector2(-target_card_size.x * 0.31, target_card_size.y * 0.34)
	var rect := Rect2(target_center - target_card_size * 0.48, target_card_size * 0.96)

	_draw_corroded_frame(rect, lock_phase, settle, is_overload)
	for vein_index in range(8 if is_overload else 6):
		var edge_point := _rect_perimeter_point(rect, float(vein_index) / float(8 if is_overload else 6))
		var tangent := (attack_anchor - edge_point).normalized().orthogonal()
		var curve := _cubic_curve(
			edge_point,
			edge_point.lerp(attack_anchor, 0.38) + tangent * scale_value * 0.08,
			edge_point.lerp(attack_anchor, 0.72) - tangent * scale_value * 0.05,
			attack_anchor,
			invade,
			14
		)
		_draw_layered_line(curve, Palette.with_alpha(Palette.VOID, 0.74 * settle), Palette.with_alpha(Palette.FEL_GREEN, 0.62 * settle), scale_value * 0.026, scale_value * 0.009)

	_draw_pressure_core(
		attack_anchor,
		scale_value * (0.19 if is_overload else 0.13),
		invade,
		lock_phase,
		settle,
		Palette.ACID if not is_overload else Palette.HOT_CORE
	)
	if is_overload:
		_draw_radial_cracks(target_center, scale_value * 0.50, lock_phase, settle, 10)


func _draw_mana_burn() -> void:
	var scale_value := _target_scale()
	var pin := Palette.ease_out(Palette.phase(progress, 0.0, 0.30))
	var drain := Palette.ease_in_out(Palette.phase(progress, 0.18, 0.76))
	var snap := Palette.ease_out(Palette.phase(progress, 0.62, 0.90))
	var settle := 1.0 - Palette.phase(progress, 0.84, 1.0)
	var pillar_top := target_center - Vector2(0.0, target_card_size.y * 0.66)
	var pillar := _jagged_segment(pillar_top, target_center, 12, scale_value * 0.028)
	_draw_layered_line(pillar, Palette.with_alpha(Palette.VOID, 0.92 * settle), Palette.with_alpha(Palette.HOT_CORE, 0.88 * pin * settle), scale_value * 0.12, scale_value * 0.030)

	var direction := (source_center - target_center).normalized()
	var normal := direction.orthogonal()
	for stream_index in range(3):
		var offset := normal * float(stream_index - 1) * scale_value * 0.055
		var stream := _cubic_curve(
			target_center + offset,
			target_center.lerp(source_center, 0.34) + normal * scale_value * (0.20 - float(stream_index) * 0.13),
			target_center.lerp(source_center, 0.72) - normal * scale_value * 0.11,
			source_center + offset * 0.22,
			drain,
			24
		)
		_draw_layered_line(stream, Palette.with_alpha(Palette.DEEP_PURPLE, 0.86 * settle), Palette.with_alpha(Palette.ACID, 0.84 * settle), scale_value * 0.048, scale_value * 0.014)

	_draw_demon_jaw(source_center, scale_value * 0.28, drain, settle, false)
	_draw_target_fissure(target_center, scale_value * 0.28, snap, settle, false)


func _draw_fel_bite() -> void:
	var scale_value := _target_scale()
	var close_phase := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.48))
	var tear := Palette.ease_out(Palette.phase(progress, 0.30, 0.70))
	var return_phase := Palette.ease_in_out(Palette.phase(progress, 0.42, 0.88))
	var settle := 1.0 - Palette.phase(progress, 0.84, 1.0)
	_draw_demon_jaw(target_center, scale_value * 0.48, close_phase, settle, true)

	for slash_index in range(3):
		var shift := Vector2(float(slash_index - 1) * scale_value * 0.08, float(slash_index - 1) * scale_value * 0.035)
		var slash := _jagged_segment(
			target_center + shift + Vector2(-scale_value * 0.24, scale_value * 0.18),
			target_center + shift + Vector2(scale_value * 0.20, -scale_value * 0.22) * tear,
			8,
			scale_value * 0.018
		)
		_draw_layered_line(slash, Palette.with_alpha(Palette.VOID, 0.92 * settle), Palette.with_alpha(Palette.CURSE_RED, 0.86 * settle), scale_value * 0.050, scale_value * 0.017)

	var direction := (source_center - target_center).normalized()
	var normal := direction.orthogonal()
	for droplet_index in range(5):
		var ratio := clampf(return_phase - float(droplet_index) * 0.08, 0.0, 1.0)
		var droplet_center := target_center.lerp(source_center, ratio) + normal * sin(float(droplet_index) * 1.73) * scale_value * 0.10
		draw_circle(droplet_center, scale_value * (0.025 + 0.006 * float(droplet_index % 2)), Palette.with_alpha(Palette.BLOOD_PURPLE if droplet_index % 2 == 0 else Palette.FEL_GREEN, 0.82 * settle))


func _draw_life_drain() -> void:
	var scale_value := _target_scale()
	var expose := Palette.ease_out(Palette.phase(progress, 0.0, 0.32))
	var drain := Palette.ease_in_out(Palette.phase(progress, 0.16, 0.82))
	var receive := Palette.ease_out(Palette.phase(progress, 0.58, 0.94))
	var settle := 1.0 - Palette.phase(progress, 0.88, 1.0)
	var direction := (source_center - target_center).normalized()
	var normal := direction.orthogonal()

	_draw_soul_silhouette(target_center, scale_value * 0.38, expose, settle)
	for stream_index in range(4):
		var lane := float(stream_index) - 1.5
		var bend := normal * scale_value * lane * 0.10
		var stream := _cubic_curve(
			target_center + normal * lane * scale_value * 0.025,
			target_center.lerp(source_center, 0.30) + bend,
			target_center.lerp(source_center, 0.70) - bend * 0.55,
			source_center + normal * lane * scale_value * 0.014,
			drain,
			30
		)
		_draw_layered_line(
			stream,
			Palette.with_alpha(Palette.VOID, 0.86 * settle),
			Palette.with_alpha(Palette.SOUL_PURPLE if stream_index % 2 == 0 else Palette.SOUL_BLUE, (0.78 + 0.05 * float(stream_index)) * settle),
			scale_value * 0.055,
			scale_value * 0.017
		)

	_draw_pressure_core(source_center, scale_value * 0.20, receive, receive, settle, Palette.SOUL_PURPLE)
	for mote_index in range(8):
		var mote_ratio := fmod(drain + float(mote_index) * 0.115, 1.0)
		var mote := target_center.lerp(source_center, mote_ratio) + normal * sin(float(mote_index) * 2.4) * scale_value * 0.13
		draw_circle(mote, scale_value * 0.018, Palette.with_alpha(Palette.ACID if mote_index % 3 == 0 else Palette.SOUL_BLUE, 0.78 * settle))


func _draw_life_drain_receive() -> void:
	var scale_value := _target_scale()
	var gather := Palette.ease_out(Palette.phase(progress, 0.0, 0.58))
	var pulse := Palette.ease_out(Palette.phase(progress, 0.32, 0.82))
	var settle := 1.0 - Palette.phase(progress, 0.78, 1.0)
	for ribbon_index in range(6):
		var angle := TAU * float(ribbon_index) / 6.0 + gather * 0.7
		var start := target_center + Vector2(cos(angle), sin(angle)) * scale_value * (0.50 - gather * 0.26)
		var end := target_center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * scale_value * 0.09
		draw_line(start, end, Palette.with_alpha(Palette.SOUL_PURPLE if ribbon_index % 2 == 0 else Palette.FEL_GREEN, 0.62 * settle), scale_value * 0.018, true)
	for ring_index in range(3):
		draw_arc(target_center, scale_value * (0.12 + pulse * (0.10 + float(ring_index) * 0.08)), 0.0, TAU, 48, Palette.with_alpha(Palette.SOUL_BLUE, (0.50 - float(ring_index) * 0.10) * settle), 2.4, true)


func _draw_curse_cast() -> void:
	var scale_value := _target_scale()
	var weave := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.64))
	var seal := Palette.ease_out(Palette.phase(progress, 0.42, 0.84))
	var settle := 1.0 - Palette.phase(progress, 0.82, 1.0)
	var direction := (target_center - source_center).normalized()
	var normal := direction.orthogonal()

	for thread_index in range(3):
		var side := float(thread_index - 1)
		var thread := _cubic_curve(
			source_center,
			source_center.lerp(target_center, 0.32) + normal * scale_value * side * 0.16,
			source_center.lerp(target_center, 0.68) - normal * scale_value * side * 0.11,
			target_center,
			weave,
			24
		)
		_draw_layered_line(thread, Palette.with_alpha(Palette.VOID, 0.86 * settle), Palette.with_alpha(Palette.CURSE_RED if thread_index == 1 else Palette.SOUL_PURPLE, 0.72 * settle), scale_value * 0.036, scale_value * 0.010)
	_draw_demon_eye(target_center, scale_value * 0.38, seal, settle)
	_draw_attack_shackle(target_center, scale_value, seal, settle)


func _draw_curse_mark() -> void:
	var scale_value := _target_scale()
	var carve := Palette.ease_out(Palette.phase(progress, 0.0, 0.66))
	var clamp_phase := Palette.ease_in_out(Palette.phase(progress, 0.28, 0.84))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var rect := Rect2(target_center - target_card_size * 0.47, target_card_size * 0.94)
	_draw_corroded_frame(rect, carve, settle, false, Palette.SOUL_PURPLE)
	_draw_demon_eye(target_center - Vector2(0.0, target_card_size.y * 0.08), scale_value * 0.34, clamp_phase, settle)
	_draw_attack_shackle(target_center, scale_value, clamp_phase, settle)


func _draw_curse_impact() -> void:
	var scale_value := _target_scale()
	var snap := Palette.ease_out(Palette.phase(progress, 0.0, 0.58))
	var settle := 1.0 - Palette.phase(progress, 0.64, 1.0)
	for spike_index in range(9):
		var angle := TAU * float(spike_index) / 9.0 + 0.22
		var direction := Vector2(cos(angle), sin(angle))
		var start := target_center + direction * scale_value * (0.56 - snap * 0.24)
		var tip := target_center + direction * scale_value * 0.08
		var side := direction.orthogonal() * scale_value * 0.035
		draw_colored_polygon(PackedVector2Array([start - side, tip, start + side]), Palette.with_alpha(Palette.CURSE_RED if spike_index % 2 == 0 else Palette.ACID, 0.72 * settle))
	draw_circle(target_center, scale_value * (0.08 + snap * 0.12), Palette.with_alpha(Palette.VOID, 0.72 * settle))


func _draw_madness_response(response_type: String) -> void:
	var scale_value := _target_scale()
	var mutate := Palette.ease_out(Palette.phase(progress, 0.0, 0.66))
	var pulse := Palette.ease_in_out(Palette.phase(progress, 0.22, 0.84))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var rect := Rect2(target_center - target_card_size * 0.46, target_card_size * 0.92)
	_draw_corroded_frame(rect, mutate, settle, false, Palette.BLOOD_PURPLE)

	match response_type:
		"hellhound":
			_draw_demon_jaw(target_center + Vector2(0.0, target_card_size.y * 0.12), scale_value * 0.34, pulse, settle, true)
			_draw_action_glyph(target_center + Vector2(target_card_size.x * 0.30, -target_card_size.y * 0.30), scale_value * 0.12, pulse, settle)
		"succubus":
			for loop_index in range(3):
				var radius := scale_value * (0.15 + float(loop_index) * 0.08 + pulse * 0.05)
				draw_arc(target_center, radius, -PI * 0.18 + float(loop_index) * 0.38, PI * 1.45 + float(loop_index) * 0.38, 42, Palette.with_alpha(Palette.SOUL_PURPLE, (0.68 - float(loop_index) * 0.12) * settle), 2.2, true)
			_draw_pressure_core(target_center, scale_value * 0.12, mutate, pulse, settle, Palette.CURSE_RED)
		"wolf_rider":
			_draw_demon_jaw(target_center + Vector2(0.0, target_card_size.y * 0.18), scale_value * 0.40, pulse, settle, true)
			_draw_slashes(target_center, scale_value * 0.82, mutate, settle, 2)
		"doomguard":
			_draw_horns(target_center - Vector2(0.0, target_card_size.y * 0.18), scale_value * 0.48, mutate, settle)
			for ring_index in range(2):
				draw_arc(target_center, scale_value * (0.34 + pulse * 0.12 + float(ring_index) * 0.09), PI * 0.12, PI * 0.88, 36, Palette.with_alpha(Palette.ACID, (0.54 - float(ring_index) * 0.16) * settle), 3.0, true)
		"warlock":
			_draw_demon_eye(target_center, scale_value * 0.38, pulse, settle)
			for hook_index in range(4):
				var angle := TAU * float(hook_index) / 4.0 + 0.25
				_draw_curse_hook(target_center + Vector2(cos(angle), sin(angle)) * scale_value * 0.30, angle, scale_value * 0.14, mutate, settle)
		_:
			_draw_slashes(target_center, scale_value * 0.86, mutate, settle, 3)
			_draw_pressure_core(target_center + Vector2(-target_card_size.x * 0.27, target_card_size.y * 0.32), scale_value * 0.10, mutate, pulse, settle, Palette.ACID)


func _draw_kiljaeden_mark() -> void:
	var scale_value := _target_scale()
	var whisper := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.72))
	var bind := Palette.ease_out(Palette.phase(progress, 0.30, 0.86))
	var settle := 1.0 - Palette.phase(progress, 0.82, 1.0)
	var eye_center := target_center - Vector2(0.0, target_card_size.y * 0.12)
	_draw_demon_eye(eye_center, scale_value * 0.42, whisper, settle, true)
	for wave_index in range(4):
		var radius := scale_value * (0.20 + float(wave_index) * 0.10 + bind * 0.06)
		draw_arc(eye_center, radius, PI * 0.08, PI * 0.92, 30, Palette.with_alpha(Palette.BLOOD_PURPLE if wave_index % 2 == 0 else Palette.ACID, (0.48 - float(wave_index) * 0.08) * settle), 1.8, true)
	_draw_attack_shackle(target_center, scale_value, bind, settle)


func _draw_immolation(is_tick: bool) -> void:
	var scale_value := _target_scale()
	var ignite := Palette.ease_out(Palette.phase(progress, 0.0, 0.58))
	var surge := Palette.ease_in_out(Palette.phase(progress, 0.26, 0.84))
	var settle := 1.0 - Palette.phase(progress, 0.78, 1.0)
	var ground_y := target_center.y + target_card_size.y * 0.38
	var flame_count := 9 if is_tick else 6
	for flame_index in range(flame_count):
		var ratio := float(flame_index) / float(maxi(flame_count - 1, 1))
		var base := Vector2(lerpf(target_center.x - target_card_size.x * 0.42, target_center.x + target_card_size.x * 0.42, ratio), ground_y)
		var height := scale_value * (0.18 + 0.10 * float(flame_index % 3)) * ignite * (1.45 if is_tick else 1.0)
		_draw_fel_flame(base, scale_value * 0.055, height, sin(float(flame_index) * 2.7 + progress * 7.0), settle)
	_draw_radial_cracks(Vector2(target_center.x, ground_y), scale_value * 0.44, surge, settle, 7)
	if is_tick:
		draw_arc(target_center, scale_value * (0.18 + surge * 0.30), 0.0, TAU, 52, Palette.with_alpha(Palette.DEMON_ORANGE, 0.58 * settle), 3.4, true)


func _draw_overload_detonation() -> void:
	var scale_value := _target_scale()
	var compress := Palette.ease_in_out(Palette.phase(progress, 0.0, 0.30))
	var burst := Palette.ease_out(Palette.phase(progress, 0.24, 0.72))
	var debris := Palette.ease_out(Palette.phase(progress, 0.42, 0.90))
	var settle := 1.0 - Palette.phase(progress, 0.80, 1.0)
	var core_radius := scale_value * lerpf(0.20, 0.08, compress)
	draw_circle(target_center, core_radius * 1.8, Palette.with_alpha(Palette.DEEP_PURPLE, 0.74 * settle))
	draw_circle(target_center, core_radius, Palette.with_alpha(Palette.HOT_CORE, 0.96 * settle))
	for ray_index in range(14):
		var angle := TAU * float(ray_index) / 14.0 + float(ray_index % 2) * 0.08
		var direction := Vector2(cos(angle), sin(angle))
		var start := target_center + direction * scale_value * 0.08
		var end := target_center + direction * scale_value * (0.20 + burst * (0.44 + float(ray_index % 3) * 0.08))
		var ray := _jagged_segment(start, end, 7, scale_value * 0.025)
		_draw_layered_line(ray, Palette.with_alpha(Palette.VOID, 0.90 * settle), Palette.with_alpha(Palette.ACID if ray_index % 3 != 0 else Palette.CURSE_RED, 0.84 * settle), scale_value * 0.060, scale_value * 0.016)
	for shard_index in range(10):
		var angle := TAU * float(shard_index) / 10.0 - 0.14
		var direction := Vector2(cos(angle), sin(angle))
		var shard_center := target_center + direction * scale_value * (0.20 + debris * 0.42)
		var side := direction.orthogonal() * scale_value * 0.025
		draw_colored_polygon(PackedVector2Array([shard_center - side, shard_center + direction * scale_value * 0.10, shard_center + side]), Palette.with_alpha(Palette.CHARCOAL if shard_index % 2 == 0 else Palette.SICK_YELLOW, 0.76 * settle))


func _draw_burst_impact() -> void:
	var scale_value := _target_scale()
	var hit := Palette.ease_out(Palette.phase(progress, 0.0, 0.54))
	var settle := 1.0 - Palette.phase(progress, 0.62, 1.0)
	for ring_index in range(3):
		draw_arc(target_center, scale_value * (0.10 + hit * (0.16 + float(ring_index) * 0.12)), 0.0, TAU, 44, Palette.with_alpha(Palette.FEL_GREEN if ring_index != 1 else Palette.CURSE_RED, (0.70 - float(ring_index) * 0.16) * settle), 3.0 - float(ring_index) * 0.45, true)
	_draw_radial_cracks(target_center, scale_value * 0.40, hit, settle, 8)


func _draw_pressure_core(center: Vector2, radius: float, gather: float, release: float, alpha: float, core_color: Color) -> void:
	var pulse_radius := radius * (0.62 + gather * 0.34 + sin(release * PI) * 0.20)
	Toolkit.draw_soft_disc(
		self,
		center,
		pulse_radius * 1.55,
		Palette.with_alpha(Palette.VOID, 0.72 * alpha),
		Palette.with_alpha(core_color, 0.74 * alpha),
		8
	)
	Toolkit.draw_soft_ellipse(
		self,
		center + Vector2(sin(progress * 8.0) * radius * 0.08, cos(progress * 6.0) * radius * 0.05),
		Vector2(pulse_radius * 0.92, pulse_radius * 0.70),
		Palette.with_alpha(Palette.INK_GREEN, 0.34 * alpha),
		Palette.with_alpha(core_color, 0.68 * alpha),
		6,
		progress * 0.32
	)
	Toolkit.draw_mote(self, center - Vector2(radius * 0.18, radius * 0.20), radius * 0.20, Palette.with_alpha(Palette.HOT_CORE, 0.82 * alpha), progress * 9.0)


func _draw_broken_sigil(center: Vector2, radius: float, phase_value: float, alpha: float, is_overload: bool) -> void:
	for arc_index in range(5 if is_overload else 4):
		var start_angle := -PI * 0.42 + float(arc_index) * TAU / float(5 if is_overload else 4)
		var arc_radius := radius * (0.72 + float(arc_index % 2) * 0.24 + phase_value * 0.12)
		draw_arc(center, arc_radius, start_angle, start_angle + PI * (0.42 if is_overload else 0.50), 18, Palette.with_alpha(Palette.ACID if arc_index % 2 == 0 else Palette.SOUL_PURPLE, (0.72 - float(arc_index) * 0.06) * alpha), 3.0, true)
		var notch := center + Vector2(cos(start_angle), sin(start_angle)) * arc_radius
		var tangent := Vector2(-sin(start_angle), cos(start_angle))
		draw_line(notch - tangent * radius * 0.10, notch + tangent * radius * 0.05, Palette.with_alpha(Palette.CHARCOAL, 0.84 * alpha), 4.0, true)


func _draw_target_fissure(center: Vector2, radius: float, phase_value: float, alpha: float, is_overload: bool) -> void:
	var half_height := radius * (0.34 + phase_value * 0.76)
	var half_width := radius * (0.18 + phase_value * (0.24 if is_overload else 0.15))
	var fissure := PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(half_width, -half_height * 0.36),
		center + Vector2(half_width * 0.42, 0.0),
		center + Vector2(half_width, half_height * 0.42),
		center + Vector2(0.0, half_height),
		center + Vector2(-half_width, half_height * 0.34),
		center + Vector2(-half_width * 0.36, 0.0),
		center + Vector2(-half_width, -half_height * 0.44),
	])
	draw_colored_polygon(fissure, Palette.with_alpha(Palette.VOID, 0.92 * alpha))
	var closed := fissure.duplicate()
	closed.append(fissure[0])
	Toolkit.draw_ribbon(
		self,
		closed,
		4.2 if is_overload else 3.0,
		Palette.with_alpha(Palette.ACID, 0.82 * alpha),
		Palette.with_alpha(Palette.INK_GREEN, 0.50 * alpha),
		Palette.with_alpha(Palette.HOT_CORE, 0.28 * alpha),
		8.0 if is_overload else 6.0,
		false,
		false,
		progress * 5.0
	)
	Toolkit.draw_ribbon(
		self,
		PackedVector2Array([center + Vector2(0.0, -half_height * 0.78), center + Vector2(0.0, half_height * 0.70)]),
		2.0,
		Palette.with_alpha(Palette.HOT_CORE, 0.66 * alpha),
		Palette.with_alpha(Palette.VOID, 0.40 * alpha),
		Color.TRANSPARENT,
		6.0,
		true,
		true,
		progress * 6.0
	)


func _draw_demon_jaw(center: Vector2, radius: float, close_phase: float, alpha: float, with_fangs: bool) -> void:
	var gap := radius * (0.40 - close_phase * 0.30)
	for jaw_sign_value in [-1.0, 1.0]:
		var jaw_sign: float = float(jaw_sign_value)
		var y_offset: float = jaw_sign * gap
		var jaw := _cubic_curve(
			center + Vector2(-radius * 0.72, y_offset),
			center + Vector2(-radius * 0.20, y_offset + jaw_sign * radius * 0.36),
			center + Vector2(radius * 0.24, y_offset + jaw_sign * radius * 0.34),
			center + Vector2(radius * 0.72, y_offset),
			1.0,
			20
		)
		_draw_layered_line(jaw, Palette.with_alpha(Palette.VOID, 0.90 * alpha), Palette.with_alpha(Palette.BLOOD_PURPLE, 0.82 * alpha), radius * 0.12, radius * 0.045)
		if with_fangs:
			for fang_index in range(4):
				var ratio := 0.20 + float(fang_index) * 0.20
				var fang_base := Vector2(lerpf(center.x - radius * 0.60, center.x + radius * 0.60, ratio), center.y + y_offset + jaw_sign * radius * 0.06)
				var fang_tip := fang_base - Vector2(0.0, jaw_sign * radius * (0.18 + 0.03 * float(fang_index % 2)))
				var side := Vector2(radius * 0.045, 0.0)
				draw_colored_polygon(PackedVector2Array([fang_base - side, fang_tip, fang_base + side]), Palette.with_alpha(Palette.SICK_YELLOW, 0.84 * alpha))


func _draw_soul_silhouette(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	var head_center := center - Vector2(0.0, scale_value * 0.30 * phase_value)
	draw_circle(head_center, scale_value * 0.10, Palette.with_alpha(Palette.SOUL_BLUE, 0.34 * alpha))
	var shoulders := PackedVector2Array([
		center + Vector2(-scale_value * 0.28, scale_value * 0.18),
		center + Vector2(-scale_value * 0.18, -scale_value * 0.04),
		head_center,
		center + Vector2(scale_value * 0.18, -scale_value * 0.04),
		center + Vector2(scale_value * 0.28, scale_value * 0.18),
	])
	draw_polyline(shoulders, Palette.with_alpha(Palette.SOUL_PURPLE, 0.62 * phase_value * alpha), 3.0, true)


func _draw_demon_eye(center: Vector2, radius: float, open_phase: float, alpha: float, is_whisper := false) -> void:
	var eye_height := radius * (0.12 + open_phase * 0.32)
	var left := center - Vector2(radius, 0.0)
	var right := center + Vector2(radius, 0.0)
	var upper := _quadratic_curve(left, center - Vector2(0.0, eye_height), right, 18)
	var lower := _quadratic_curve(left, center + Vector2(0.0, eye_height), right, 18)
	_draw_layered_line(upper, Palette.with_alpha(Palette.VOID, 0.90 * alpha), Palette.with_alpha(Palette.CURSE_RED if is_whisper else Palette.SOUL_PURPLE, 0.82 * alpha), radius * 0.11, radius * 0.035)
	_draw_layered_line(lower, Palette.with_alpha(Palette.VOID, 0.90 * alpha), Palette.with_alpha(Palette.CURSE_RED if is_whisper else Palette.SOUL_PURPLE, 0.82 * alpha), radius * 0.11, radius * 0.035)
	draw_circle(center, radius * 0.18 * open_phase, Palette.with_alpha(Palette.ACID, 0.86 * alpha))
	draw_circle(center, radius * 0.075 * open_phase, Palette.with_alpha(Palette.VOID, 0.96 * alpha))


func _draw_attack_shackle(center: Vector2, scale_value: float, phase_value: float, alpha: float) -> void:
	var anchor := center + Vector2(-target_card_size.x * 0.31, target_card_size.y * 0.34)
	for hook_index in range(4):
		var angle := TAU * float(hook_index) / 4.0 + phase_value * 0.35
		_draw_curse_hook(anchor + Vector2(cos(angle), sin(angle)) * scale_value * 0.13, angle, scale_value * 0.11, phase_value, alpha)
	draw_circle(anchor, scale_value * 0.055, Palette.with_alpha(Palette.CURSE_RED, 0.78 * alpha))


func _draw_action_glyph(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	draw_arc(center, radius * (0.72 + phase_value * 0.20), -PI * 0.72, PI * 0.82, 28, Palette.with_alpha(Palette.ACID, 0.78 * alpha), 3.0, true)
	var bolt := PackedVector2Array([
		center + Vector2(-radius * 0.12, -radius * 0.54),
		center + Vector2(radius * 0.18, -radius * 0.08),
		center + Vector2(-radius * 0.04, radius * 0.02),
		center + Vector2(radius * 0.14, radius * 0.52),
	])
	draw_polyline(bolt, Palette.with_alpha(Palette.HOT_CORE, 0.88 * alpha), 2.4, true)


func _draw_horns(center: Vector2, radius: float, phase_value: float, alpha: float) -> void:
	for side_sign_value in [-1.0, 1.0]:
		var side_sign: float = float(side_sign_value)
		var horn := _cubic_curve(
			center + Vector2(side_sign * radius * 0.18, radius * 0.20),
			center + Vector2(side_sign * radius * 0.80, radius * 0.10),
			center + Vector2(side_sign * radius * 0.90, -radius * 0.72),
			center + Vector2(side_sign * radius * 0.36, -radius * phase_value),
			phase_value,
			20
		)
		_draw_layered_line(horn, Palette.with_alpha(Palette.VOID, 0.90 * alpha), Palette.with_alpha(Palette.SICK_YELLOW, 0.76 * alpha), radius * 0.13, radius * 0.050)


func _draw_slashes(center: Vector2, scale_value: float, phase_value: float, alpha: float, count: int) -> void:
	for slash_index in range(count):
		var shift := Vector2(float(slash_index) - float(count - 1) * 0.5, float(slash_index % 2) - 0.5) * scale_value * 0.12
		var slash := _jagged_segment(center + shift + Vector2(-scale_value * 0.28, scale_value * 0.28), center + shift + Vector2(scale_value * 0.26, -scale_value * 0.30) * phase_value, 9, scale_value * 0.020)
		_draw_layered_line(slash, Palette.with_alpha(Palette.VOID, 0.90 * alpha), Palette.with_alpha(Palette.CURSE_RED if slash_index % 2 == 0 else Palette.FEL_GREEN, 0.82 * alpha), scale_value * 0.050, scale_value * 0.016)


func _draw_curse_hook(center: Vector2, angle: float, radius: float, phase_value: float, alpha: float) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var side := direction.orthogonal()
	var points := PackedVector2Array([
		center - direction * radius * 0.42,
		center + direction * radius * 0.20,
		center + direction * radius * 0.42 + side * radius * 0.30 * phase_value,
	])
	draw_polyline(points, Palette.with_alpha(Palette.SOUL_PURPLE, 0.72 * alpha), 2.0, true)


func _draw_fel_flame(base: Vector2, half_width: float, height: float, sway: float, alpha: float) -> void:
	if height <= 0.0:
		return
	Toolkit.draw_soft_ellipse(
		self,
		base - Vector2(0.0, height * 0.28),
		Vector2(half_width * 1.45, height * 0.52),
		Palette.with_alpha(Palette.FEL_GREEN, 0.18 * alpha),
		Palette.with_alpha(Palette.HOT_CORE, 0.12 * alpha),
		5,
		sway * 0.18
	)
	var outer := PackedVector2Array([
		base - Vector2(half_width, 0.0),
		base + Vector2(-half_width * 0.45, -height * 0.46),
		base + Vector2(sway * half_width, -height),
		base + Vector2(half_width * 0.48, -height * 0.38),
		base + Vector2(half_width, 0.0),
	])
	draw_colored_polygon(outer, Palette.with_alpha(Palette.DEMON_ORANGE, 0.60 * alpha))
	var inner := PackedVector2Array([
		base - Vector2(half_width * 0.40, 0.0),
		base + Vector2(sway * half_width * 0.44, -height * 0.70),
		base + Vector2(half_width * 0.40, 0.0),
	])
	draw_colored_polygon(inner, Palette.with_alpha(Palette.ACID, 0.86 * alpha))


func _draw_corroded_frame(rect: Rect2, phase_value: float, alpha: float, is_overload: bool, edge_color := Color()) -> void:
	var visible_phase := clampf(phase_value, 0.0, 1.0)
	if visible_phase <= 0.001:
		return
	var chosen_edge: Color = Palette.ACID if edge_color == Color() else edge_color
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for edge_index in range(4):
		var start: Vector2 = corners[edge_index]
		var finish: Vector2 = corners[(edge_index + 1) % 4]
		var edge := _jagged_segment(
			start,
			start.lerp(finish, visible_phase),
			10,
			minf(rect.size.x, rect.size.y) * (0.020 if is_overload else 0.012) * visible_phase
		)
		_draw_layered_line(edge, Palette.with_alpha(Palette.VOID, 0.84 * alpha), Palette.with_alpha(chosen_edge, (0.74 if is_overload else 0.58) * alpha), 5.0 if is_overload else 3.6, 1.5)


func _draw_radial_cracks(center: Vector2, radius: float, phase_value: float, alpha: float, count: int) -> void:
	for crack_index in range(count):
		var angle := TAU * float(crack_index) / float(count) + float(crack_index % 3) * 0.08
		var direction := Vector2(cos(angle), sin(angle))
		var crack := _jagged_segment(center + direction * radius * 0.12, center + direction * radius * (0.24 + phase_value * 0.76), 6, radius * 0.045)
		_draw_safe_polyline(crack, Palette.with_alpha(Palette.CHARCOAL, 0.88 * alpha), 4.0)
		_draw_safe_polyline(crack, Palette.with_alpha(Palette.FEL_GREEN if crack_index % 3 != 0 else Palette.DEMON_ORANGE, 0.72 * phase_value * alpha), 1.4)


func _rect_perimeter_point(rect: Rect2, ratio: float) -> Vector2:
	var wrapped := fmod(ratio, 1.0) * 4.0
	if wrapped < 1.0:
		return Vector2(lerpf(rect.position.x, rect.end.x, wrapped), rect.position.y)
	if wrapped < 2.0:
		return Vector2(rect.end.x, lerpf(rect.position.y, rect.end.y, wrapped - 1.0))
	if wrapped < 3.0:
		return Vector2(lerpf(rect.end.x, rect.position.x, wrapped - 2.0), rect.end.y)
	return Vector2(rect.position.x, lerpf(rect.end.y, rect.position.y, wrapped - 3.0))


func _target_scale() -> float:
	return maxf(minf(target_card_size.x, target_card_size.y), 42.0)


func _draw_layered_line(points: PackedVector2Array, outer: Color, inner: Color, outer_width: float, inner_width: float) -> void:
	if points.size() < 2:
		return
	Toolkit.draw_ribbon(
		self,
		points,
		maxf(inner_width, 1.0),
		inner,
		Color(outer.r, outer.g, outer.b, outer.a * 0.74),
		Palette.with_alpha(Palette.HOT_CORE, inner.a * 0.18),
		maxf(outer_width * 1.32, inner_width * 2.8),
		true,
		true,
		progress * 5.3 + float(points.size()) * 0.08
	)


func _draw_safe_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2 or not is_finite(width) or width <= 0.0:
		return
	draw_polyline(points, color, width, true)


func _jagged_segment(start_point: Vector2, end_point: Vector2, segments: int, amplitude: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not start_point.is_finite() or not end_point.is_finite() or not is_finite(amplitude):
		return points
	var direction := end_point - start_point
	var length := direction.length()
	if length < 0.05:
		return points
	var safe_segments := maxi(segments, 1)
	var safe_amplitude := minf(absf(amplitude), length * 0.35)
	var normal := direction / length
	normal = normal.orthogonal()
	for point_index in range(safe_segments + 1):
		var ratio := float(point_index) / float(safe_segments)
		var offset := sin(float(point_index) * 2.41 + ratio * 3.0) * safe_amplitude * sin(ratio * PI)
		points.append(start_point.lerp(end_point, ratio) + normal * offset)
	return points


func _cubic_curve(
	start_point: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	end_point: Vector2,
	visible_progress: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_progress := clampf(visible_progress, 0.0, 1.0)
	var visible_segments := maxi(int(ceil(float(segments) * safe_progress)), 1)
	for point_index in range(visible_segments + 1):
		var ratio := float(point_index) / float(visible_segments) * safe_progress
		var inverse := 1.0 - ratio
		points.append(
			start_point * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * ratio
			+ control_b * 3.0 * inverse * ratio * ratio
			+ end_point * ratio * ratio * ratio
		)
	return points


func _quadratic_curve(start_point: Vector2, control: Vector2, end_point: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(segments + 1):
		var ratio := float(point_index) / float(segments)
		var inverse := 1.0 - ratio
		points.append(start_point * inverse * inverse + control * 2.0 * inverse * ratio + end_point * ratio * ratio)
	return points
