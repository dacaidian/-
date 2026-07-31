extends RefCounted
class_name TokyoGhoulAnimationProvider

# 东京喰种表现只消费 animation key 与卡牌矩形，不读取或修改规则状态。

const KaguneReleaseVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_kagune_visual.gd"
)
const FeatherNeedleVisualScript := preload(
	"res://scripts/ui/animation/tokyo_ghoul_feather_visual.gd"
)

const TARGETED_KEYS: Array[String] = [
	"feather_needle",
	"rc_forced_feeding",
	"bikaku_volley",
	"free_meal",
	"kakuja_form",
	"restore_form"
]
const RECT_KEYS: Array[String] = ["centipede_form", "dragon_form", "saint_sword_form", "bikaku_volley"]
const BOARD_KEYS: Array[String] = ["kagune_release"]

var spell_animation_duration := 0.32


func setup(duration: float) -> void:
	spell_animation_duration = duration


func register_routes(router: SpellAnimationRouter) -> void:
	if router != null:
		router.register_targeted(TARGETED_KEYS, play_targeted)
		router.register_at_rect(RECT_KEYS, play_at_rect)
		router.register_board(BOARD_KEYS, play_board)


func play_at_rect(owner: Node, effect_root: Control, target_rect: Rect2, animation_key: String) -> void:
	if owner == null or effect_root == null or target_rect.size == Vector2.ZERO:
		return
	match animation_key:
		"centipede_form":
			await play_centipede_form(owner, effect_root, target_rect)
		"dragon_form":
			await play_dragon_form(owner, effect_root, target_rect)
		"saint_sword_form":
			await play_saint_sword_form(owner, effect_root, target_rect)
		"bikaku_volley":
			await play_bikaku_volley(owner, effect_root, target_rect)


func play_centipede_form(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var shell := create_centered_panel(target_rect, "CentipedeFormShell", 1.42, create_centipede_shell_style())
	var core := create_centered_panel(target_rect, "CentipedeFormCore", 0.54, create_centipede_core_style())
	var limbs: Array[Panel] = []
	for index in range(6):
		var limb := create_centipede_limb(target_rect, index)
		effect_root.add_child(limb)
		limbs.append(limb)
	effect_root.add_child(shell)
	effect_root.add_child(core)

	var emerge := owner.create_tween()
	emerge.set_parallel(true)
	emerge.set_trans(Tween.TRANS_BACK)
	emerge.set_ease(Tween.EASE_OUT)
	emerge.tween_property(shell, "scale", Vector2.ONE, spell_animation_duration * 0.62)
	emerge.tween_property(shell, "modulate:a", 0.94, spell_animation_duration * 0.42)
	emerge.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.54)
	emerge.tween_property(core, "modulate:a", 0.92, spell_animation_duration * 0.38)
	for limb in limbs:
		emerge.tween_property(limb, "scale:x", 1.0, spell_animation_duration * 0.72)
		emerge.tween_property(limb, "modulate:a", 0.92, spell_animation_duration * 0.34)
	await emerge.finished

	var rupture := owner.create_tween()
	rupture.set_parallel(true)
	rupture.set_trans(Tween.TRANS_QUINT)
	rupture.set_ease(Tween.EASE_OUT)
	rupture.tween_property(shell, "scale", Vector2(1.36, 1.36), spell_animation_duration * 0.62)
	rupture.tween_property(shell, "rotation", 0.42, spell_animation_duration * 0.62)
	rupture.tween_property(shell, "modulate:a", 0.0, spell_animation_duration * 0.68)
	rupture.tween_property(core, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.58)
	rupture.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.54)
	for limb in limbs:
		var release_offset: Vector2 = limb.get_meta("centipede_release_offset", Vector2.ZERO)
		rupture.tween_property(limb, "global_position", limb.global_position + release_offset, spell_animation_duration * 0.66)
		rupture.tween_property(limb, "modulate:a", 0.0, spell_animation_duration * 0.58)
	await rupture.finished

	shell.queue_free()
	core.queue_free()
	for limb in limbs:
		limb.queue_free()


func create_centipede_limb(target_rect: Rect2, index: int) -> Panel:
	var limb := Panel.new()
	limb.name = "CentipedeLimb_%d" % index
	limb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	limb.size = Vector2(target_rect.size.x * 0.82, maxf(target_rect.size.y * 0.075, 7.0))
	limb.pivot_offset = Vector2(0.0, limb.size.y * 0.5)
	var side := -1.0 if index % 2 == 0 else 1.0
	var row := floorf(float(index) / 2.0) - 1.0
	limb.global_position = target_rect.get_center() + Vector2(side * target_rect.size.x * 0.08, row * target_rect.size.y * 0.19) - limb.pivot_offset
	limb.rotation = (PI if side < 0.0 else 0.0) + row * side * 0.18
	limb.scale = Vector2(0.08, 1.0)
	limb.modulate = Color(1.0, 1.0, 1.0, 0.0)
	limb.z_index = 2320 + index
	limb.set_meta("centipede_release_offset", Vector2(side * target_rect.size.x * 0.42, row * target_rect.size.y * 0.16))
	limb.add_theme_stylebox_override("panel", create_centipede_limb_style())
	return limb


func play_dragon_form(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var body := create_centered_panel(target_rect, "DragonFormBody", 1.76, create_dragon_body_style())
	var core := create_centered_panel(target_rect, "DragonFormCore", 0.62, create_dragon_core_style())
	var wings: Array[Panel] = []
	for index in range(4):
		var wing := create_dragon_wing(target_rect, index)
		effect_root.add_child(wing)
		wings.append(wing)
	effect_root.add_child(body)
	effect_root.add_child(core)

	var awaken := owner.create_tween()
	awaken.set_parallel(true)
	awaken.set_trans(Tween.TRANS_BACK)
	awaken.set_ease(Tween.EASE_OUT)
	awaken.tween_property(body, "scale", Vector2.ONE, spell_animation_duration * 0.66)
	awaken.tween_property(body, "modulate:a", 0.90, spell_animation_duration * 0.42)
	awaken.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.54)
	awaken.tween_property(core, "modulate:a", 0.96, spell_animation_duration * 0.38)
	for wing in wings:
		awaken.tween_property(wing, "scale:x", 1.0, spell_animation_duration * 0.78)
		awaken.tween_property(wing, "modulate:a", 0.88, spell_animation_duration * 0.36)
	await awaken.finished

	var surge := owner.create_tween()
	surge.set_parallel(true)
	surge.set_trans(Tween.TRANS_QUINT)
	surge.set_ease(Tween.EASE_OUT)
	surge.tween_property(body, "scale", Vector2(1.42, 1.42), spell_animation_duration * 0.72)
	surge.tween_property(body, "modulate:a", 0.0, spell_animation_duration * 0.72)
	surge.tween_property(core, "scale", Vector2(1.90, 1.90), spell_animation_duration * 0.62)
	surge.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.62)
	for wing in wings:
		var release_offset: Vector2 = wing.get_meta("dragon_release_offset", Vector2.ZERO)
		surge.tween_property(wing, "global_position", wing.global_position + release_offset, spell_animation_duration * 0.70)
		surge.tween_property(wing, "modulate:a", 0.0, spell_animation_duration * 0.62)
	await surge.finished

	body.queue_free()
	core.queue_free()
	for wing in wings:
		wing.queue_free()


func create_dragon_wing(target_rect: Rect2, index: int) -> Panel:
	var wing := Panel.new()
	wing.name = "DragonFormWing_%d" % index
	wing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wing.size = Vector2(target_rect.size.x * 1.08, maxf(target_rect.size.y * 0.13, 10.0))
	wing.pivot_offset = Vector2(0.0, wing.size.y * 0.5)
	var side := -1.0 if index % 2 == 0 else 1.0
	var vertical := -1.0 if index < 2 else 1.0
	wing.global_position = target_rect.get_center() + Vector2(side * target_rect.size.x * 0.04, vertical * target_rect.size.y * 0.20) - wing.pivot_offset
	wing.rotation = (PI if side < 0.0 else 0.0) + vertical * side * 0.34
	wing.scale = Vector2(0.06, 1.0)
	wing.modulate = Color(1.0, 1.0, 1.0, 0.0)
	wing.z_index = 2326 + index
	wing.set_meta("dragon_release_offset", Vector2(side * target_rect.size.x * 0.56, vertical * target_rect.size.y * 0.38))
	wing.add_theme_stylebox_override("panel", create_dragon_wing_style())
	return wing


func play_saint_sword_form(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var halo := create_centered_panel(target_rect, "SaintSwordHalo", 1.58, create_saint_sword_halo_style())
	var core := create_centered_panel(target_rect, "SaintSwordCore", 0.34, create_saint_sword_core_style())
	var blades: Array[Panel] = []
	for index in range(4):
		var blade := create_saint_sword_blade(target_rect, index)
		effect_root.add_child(blade)
		blades.append(blade)
	effect_root.add_child(halo)
	effect_root.add_child(core)

	var forge := owner.create_tween()
	forge.set_parallel(true)
	forge.set_trans(Tween.TRANS_BACK)
	forge.set_ease(Tween.EASE_OUT)
	forge.tween_property(halo, "scale", Vector2.ONE, spell_animation_duration * 0.58)
	forge.tween_property(halo, "modulate:a", 0.88, spell_animation_duration * 0.36)
	forge.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.48)
	forge.tween_property(core, "modulate:a", 1.0, spell_animation_duration * 0.30)
	for blade in blades:
		forge.tween_property(blade, "scale:x", 1.0, spell_animation_duration * 0.66)
		forge.tween_property(blade, "modulate:a", 0.98, spell_animation_duration * 0.30)
	await forge.finished

	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_QUINT)
	release.set_ease(Tween.EASE_OUT)
	release.tween_property(halo, "scale", Vector2(1.44, 1.44), spell_animation_duration * 0.68)
	release.tween_property(halo, "rotation", 0.56, spell_animation_duration * 0.68)
	release.tween_property(halo, "modulate:a", 0.0, spell_animation_duration * 0.68)
	release.tween_property(core, "scale", Vector2(2.10, 2.10), spell_animation_duration * 0.56)
	release.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.56)
	for blade in blades:
		var offset: Vector2 = blade.get_meta("saint_sword_release_offset", Vector2.ZERO)
		release.tween_property(blade, "global_position", blade.global_position + offset, spell_animation_duration * 0.66)
		release.tween_property(blade, "modulate:a", 0.0, spell_animation_duration * 0.56)
	await release.finished

	halo.queue_free()
	core.queue_free()
	for blade in blades:
		blade.queue_free()


func create_saint_sword_blade(target_rect: Rect2, index: int) -> Panel:
	var blade := Panel.new()
	blade.name = "SaintSwordBlade_%d" % index
	blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blade.size = Vector2(target_rect.size.x * 1.36, maxf(target_rect.size.y * 0.065, 6.0))
	blade.pivot_offset = Vector2(0.0, blade.size.y * 0.5)
	blade.global_position = target_rect.get_center() - blade.pivot_offset
	blade.rotation = PI * 0.25 + float(index) * PI * 0.5
	blade.scale = Vector2(0.04, 1.0)
	blade.modulate = Color(1.0, 1.0, 1.0, 0.0)
	blade.z_index = 2330 + index
	blade.set_meta("saint_sword_release_offset", Vector2.RIGHT.rotated(blade.rotation) * target_rect.size.length() * 0.36)
	blade.add_theme_stylebox_override("panel", create_saint_sword_blade_style())
	return blade


func play_bikaku_volley(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var core := create_centered_panel(target_rect, "BikakuVolleyCore", 0.40, create_bikaku_core_style())
	var tails: Array[Panel] = []
	for index in range(5):
		var tail := create_bikaku_tail(target_rect, index)
		effect_root.add_child(tail)
		tails.append(tail)
	effect_root.add_child(core)

	var unfurl := owner.create_tween()
	unfurl.set_parallel(true)
	unfurl.set_trans(Tween.TRANS_BACK)
	unfurl.set_ease(Tween.EASE_OUT)
	unfurl.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	unfurl.tween_property(core, "modulate:a", 0.96, spell_animation_duration * 0.30)
	for tail in tails:
		unfurl.tween_property(tail, "scale:x", 1.0, spell_animation_duration * 0.68)
		unfurl.tween_property(tail, "modulate:a", 0.92, spell_animation_duration * 0.28)
	await unfurl.finished

	var lash := owner.create_tween()
	lash.set_parallel(true)
	lash.set_trans(Tween.TRANS_QUINT)
	lash.set_ease(Tween.EASE_OUT)
	lash.tween_property(core, "scale", Vector2(1.70, 1.70), spell_animation_duration * 0.52)
	lash.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.52)
	for tail in tails:
		var release_offset: Vector2 = tail.get_meta("bikaku_release_offset", Vector2.ZERO)
		lash.tween_property(tail, "global_position", tail.global_position + release_offset, spell_animation_duration * 0.58)
		lash.tween_property(tail, "modulate:a", 0.0, spell_animation_duration * 0.50)
	await lash.finished

	core.queue_free()
	for tail in tails:
		tail.queue_free()


func create_bikaku_tail(target_rect: Rect2, index: int) -> Panel:
	var tail := Panel.new()
	tail.name = "BikakuTail_%d" % index
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.size = Vector2(target_rect.size.x * 1.08, maxf(target_rect.size.y * 0.085, 7.0))
	tail.pivot_offset = Vector2(0.0, tail.size.y * 0.5)
	var spread := float(index - 2) * 0.30
	var origin := target_rect.get_center() + Vector2(0.0, target_rect.size.y * 0.24)
	tail.global_position = origin - tail.pivot_offset
	tail.rotation = -PI * 0.5 + spread
	tail.scale = Vector2(0.06, 1.0)
	tail.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tail.z_index = 2340 + index
	tail.set_meta("bikaku_release_offset", Vector2.RIGHT.rotated(tail.rotation) * target_rect.size.length() * 0.30)
	tail.add_theme_stylebox_override("panel", create_bikaku_tail_style(index))
	return tail


func play_board(owner: Node, effect_root: Control, animation_key: String) -> void:
	if owner == null or effect_root == null:
		return
	if animation_key == "kagune_release":
		await play_kagune_release(owner, effect_root)


func play_kagune_release(owner: Node, effect_root: Control) -> void:
	var viewport_size := effect_root.size
	if viewport_size == Vector2.ZERO:
		viewport_size = effect_root.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var visual := KaguneReleaseVisualScript.new()
	visual.name = "TokyoGhoulKaguneRelease"
	visual.size = viewport_size
	visual.position = Vector2.ZERO
	visual.z_index = 2460
	effect_root.add_child(visual)
	visual.configure()

	var release_duration := maxf(spell_animation_duration * 3.2, 0.88)
	var release := owner.create_tween()
	release.set_trans(Tween.TRANS_SINE)
	release.set_ease(Tween.EASE_IN_OUT)
	release.tween_property(visual, "progress", 1.0, release_duration)
	await release.finished

	visual.queue_free()


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	match animation_key:
		"feather_needle":
			if caster_card != null:
				await play_feather_needle(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_card.get_global_rect()
				)
		"rc_forced_feeding":
			await play_forced_feeding(owner, effect_root, target_card.get_global_rect())
		"bikaku_volley":
			await play_bikaku_volley(owner, effect_root, target_card.get_global_rect())
		"free_meal":
			await play_free_meal(owner, effect_root, target_card.get_global_rect())
		"kakuja_form":
			await play_kakuja_form(owner, effect_root, target_card.get_global_rect())
		"restore_form":
			await play_restore_form(owner, effect_root, target_card.get_global_rect())


func play_free_meal(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var shelter := create_centered_panel(target_rect, "FreeMealShelter", 1.46, create_free_meal_shelter_style())
	var warmth := create_centered_panel(target_rect, "FreeMealWarmth", 0.58, create_free_meal_warmth_style())
	effect_root.add_child(shelter)
	effect_root.add_child(warmth)

	var welcome := owner.create_tween()
	welcome.set_parallel(true)
	welcome.set_trans(Tween.TRANS_BACK)
	welcome.set_ease(Tween.EASE_OUT)
	welcome.tween_property(shelter, "scale", Vector2.ONE, spell_animation_duration * 0.62)
	welcome.tween_property(shelter, "modulate:a", 0.86, spell_animation_duration * 0.38)
	welcome.tween_property(warmth, "scale", Vector2.ONE, spell_animation_duration * 0.48)
	welcome.tween_property(warmth, "modulate:a", 0.94, spell_animation_duration * 0.34)
	await welcome.finished

	var restore := owner.create_tween()
	restore.set_parallel(true)
	restore.set_trans(Tween.TRANS_QUINT)
	restore.set_ease(Tween.EASE_OUT)
	restore.tween_property(shelter, "scale", Vector2(2.35, 2.35), spell_animation_duration * 0.82)
	restore.tween_property(shelter, "modulate:a", 0.0, spell_animation_duration * 0.82)
	restore.tween_property(warmth, "scale", Vector2(1.55, 1.55), spell_animation_duration * 0.66)
	restore.tween_property(warmth, "modulate:a", 0.0, spell_animation_duration * 0.66)
	await restore.finished

	shelter.queue_free()
	warmth.queue_free()


func play_kakuja_form(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var shell := create_centered_panel(target_rect, "KakujaShell", 1.72, create_kakuja_shell_style())
	var core := create_centered_panel(target_rect, "KakujaCore", 0.48, create_kakuja_core_style())
	var feathers: Array[Panel] = []
	for index in range(8):
		var feather := create_kakuja_feather(target_rect, index)
		effect_root.add_child(feather)
		feathers.append(feather)
	effect_root.add_child(shell)
	effect_root.add_child(core)

	var emerge := owner.create_tween()
	emerge.set_parallel(true)
	emerge.set_trans(Tween.TRANS_BACK)
	emerge.set_ease(Tween.EASE_OUT)
	emerge.tween_property(shell, "scale", Vector2.ONE, spell_animation_duration * 0.68)
	emerge.tween_property(shell, "modulate:a", 0.90, spell_animation_duration * 0.42)
	emerge.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.52)
	emerge.tween_property(core, "modulate:a", 0.98, spell_animation_duration * 0.36)
	for feather in feathers:
		emerge.tween_property(feather, "scale:x", 1.0, spell_animation_duration * 0.72)
		emerge.tween_property(feather, "modulate:a", 0.94, spell_animation_duration * 0.32)
	await emerge.finished

	var mantle := owner.create_tween()
	mantle.set_parallel(true)
	mantle.set_trans(Tween.TRANS_QUINT)
	mantle.set_ease(Tween.EASE_OUT)
	mantle.tween_property(shell, "scale", Vector2(1.40, 1.40), spell_animation_duration * 0.66)
	mantle.tween_property(shell, "modulate:a", 0.0, spell_animation_duration * 0.66)
	mantle.tween_property(core, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.58)
	mantle.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.54)
	for feather in feathers:
		var release_offset: Vector2 = feather.get_meta("kakuja_release_offset", Vector2.ZERO)
		mantle.tween_property(feather, "global_position", feather.global_position + release_offset, spell_animation_duration * 0.62)
		mantle.tween_property(feather, "modulate:a", 0.0, spell_animation_duration * 0.58)
	await mantle.finished

	shell.queue_free()
	core.queue_free()
	for feather in feathers:
		feather.queue_free()


func play_restore_form(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var shell := create_centered_panel(target_rect, "RestoreFormShell", 1.55, create_kakuja_shell_style())
	var core := create_centered_panel(target_rect, "RestoreFormCore", 0.58, create_kakuja_core_style())
	shell.scale = Vector2(1.45, 1.45)
	shell.modulate.a = 0.0
	core.scale = Vector2(1.7, 1.7)
	core.modulate.a = 0.0
	effect_root.add_child(shell)
	effect_root.add_child(core)

	var gather := owner.create_tween()
	gather.set_parallel(true)
	gather.set_trans(Tween.TRANS_QUINT)
	gather.set_ease(Tween.EASE_OUT)
	gather.tween_property(shell, "scale", Vector2.ONE, spell_animation_duration * 0.62)
	gather.tween_property(shell, "modulate:a", 0.82, spell_animation_duration * 0.34)
	gather.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.48)
	gather.tween_property(core, "modulate:a", 0.92, spell_animation_duration * 0.30)
	await gather.finished

	var release := owner.create_tween()
	release.set_parallel(true)
	release.set_trans(Tween.TRANS_EXPO)
	release.set_ease(Tween.EASE_IN)
	release.tween_property(shell, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.58)
	release.tween_property(shell, "modulate:a", 0.0, spell_animation_duration * 0.54)
	release.tween_property(core, "scale", Vector2(0.08, 0.08), spell_animation_duration * 0.50)
	release.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.46)
	await release.finished

	shell.queue_free()
	core.queue_free()


func create_kakuja_feather(target_rect: Rect2, index: int) -> Panel:
	var feather := Panel.new()
	feather.name = "KakujaFeather_%d" % index
	feather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feather.size = Vector2(target_rect.size.x * 0.92, maxf(target_rect.size.y * 0.095, 8.0))
	feather.pivot_offset = Vector2(0.0, feather.size.y * 0.5)
	var angle := TAU * float(index) / 8.0
	feather.global_position = target_rect.get_center() - feather.pivot_offset
	feather.rotation = angle
	feather.scale = Vector2(0.06, 1.0)
	feather.modulate = Color(1.0, 1.0, 1.0, 0.0)
	feather.z_index = 2360 + index
	feather.set_meta("kakuja_release_offset", Vector2.RIGHT.rotated(angle) * target_rect.size.length() * 0.38)
	feather.add_theme_stylebox_override("panel", create_kakuja_feather_style(index))
	return feather


func play_feather_needle(owner: Node, effect_root: Control, source_rect: Rect2, target_rect: Rect2) -> void:
	var inverse_transform := effect_root.get_global_transform().affine_inverse()
	var source_point := inverse_transform * source_rect.get_center()
	var target_point := inverse_transform * target_rect.get_center()
	if source_point.distance_to(target_point) <= 0.01:
		return

	var visual := FeatherNeedleVisualScript.new()
	visual.name = "TokyoGhoulUkakuNeedles"
	visual.size = effect_root.size
	if visual.size == Vector2.ZERO:
		visual.size = effect_root.get_viewport_rect().size
	visual.position = Vector2.ZERO
	visual.z_index = 2462
	effect_root.add_child(visual)
	visual.configure(source_point, target_point)

	var flight_duration := maxf(spell_animation_duration * 1.55, 0.42)
	var flight := owner.create_tween()
	flight.set_trans(Tween.TRANS_QUART)
	flight.set_ease(Tween.EASE_IN_OUT)
	flight.tween_property(visual, "progress", 1.0, flight_duration)
	await flight.finished

	visual.queue_free()


func play_forced_feeding(owner: Node, effect_root: Control, target_rect: Rect2) -> void:
	var outer := create_centered_panel(target_rect, "RcFeedingOuter", 1.34, create_feeding_outer_style())
	var core := create_centered_panel(target_rect, "RcFeedingCore", 0.74, create_feeding_core_style())
	var mark := create_feeding_mark(target_rect)
	effect_root.add_child(outer)
	effect_root.add_child(core)
	effect_root.add_child(mark)

	var appear := owner.create_tween()
	appear.set_parallel(true)
	appear.set_trans(Tween.TRANS_BACK)
	appear.set_ease(Tween.EASE_OUT)
	appear.tween_property(outer, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(outer, "modulate:a", 0.92, spell_animation_duration * 0.34)
	appear.tween_property(core, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(core, "modulate:a", 0.82, spell_animation_duration * 0.34)
	appear.tween_property(mark, "scale", Vector2.ONE, spell_animation_duration * 0.42)
	appear.tween_property(mark, "modulate:a", 0.96, spell_animation_duration * 0.34)
	await appear.finished

	var consume := owner.create_tween()
	consume.set_parallel(true)
	consume.set_trans(Tween.TRANS_QUINT)
	consume.set_ease(Tween.EASE_IN)
	consume.tween_property(outer, "scale", Vector2(0.18, 0.18), spell_animation_duration * 0.72)
	consume.tween_property(outer, "rotation", 0.55, spell_animation_duration * 0.72)
	consume.tween_property(outer, "modulate:a", 0.0, spell_animation_duration * 0.72)
	consume.tween_property(core, "scale", Vector2(0.08, 0.08), spell_animation_duration * 0.72)
	consume.tween_property(core, "modulate:a", 0.0, spell_animation_duration * 0.60)
	consume.tween_property(mark, "scale", Vector2(0.24, 0.24), spell_animation_duration * 0.72)
	consume.tween_property(mark, "modulate:a", 0.0, spell_animation_duration * 0.58)
	await consume.finished

	outer.queue_free()
	core.queue_free()
	mark.queue_free()


func create_centered_panel(
	target_rect: Rect2,
	effect_name: String,
	size_multiplier: float,
	style: StyleBoxFlat
) -> Panel:
	var effect := Panel.new()
	effect.name = effect_name
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = target_rect.size * size_multiplier
	effect.pivot_offset = effect.size * 0.5
	effect.global_position = target_rect.get_center() - effect.pivot_offset
	effect.scale = Vector2(0.32, 0.32)
	effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	effect.z_index = 2318
	effect.add_theme_stylebox_override("panel", style)
	return effect


func create_feeding_mark(target_rect: Rect2) -> Label:
	var mark := Label.new()
	mark.name = "RcFeedingMark"
	mark.text = "喰"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = target_rect.size * Vector2(0.72, 0.72)
	mark.pivot_offset = mark.size * 0.5
	mark.global_position = target_rect.get_center() - mark.pivot_offset
	mark.scale = Vector2(0.32, 0.32)
	mark.modulate = Color(1.0, 1.0, 1.0, 0.0)
	mark.z_index = 2322
	mark.add_theme_font_size_override("font_size", maxi(int(target_rect.size.x * 0.34), 20))
	mark.add_theme_color_override("font_color", Color(1.0, 0.84, 0.84, 0.96))
	mark.add_theme_color_override("font_shadow_color", Color(0.20, 0.0, 0.04, 0.98))
	mark.add_theme_constant_override("shadow_offset_x", 2)
	mark.add_theme_constant_override("shadow_offset_y", 2)
	return mark


func create_feeding_outer_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.08, 0.0, 0.02, 0.58),
		Color(0.72, 0.03, 0.14, 0.90),
		7,
		999,
		Color(0.48, 0.0, 0.08, 0.64),
		34
	)


func create_feeding_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.30, 0.0, 0.06, 0.78),
		Color(1.0, 0.28, 0.36, 0.88),
		3,
		999,
		Color(0.86, 0.02, 0.16, 0.52),
		20
	)


func create_centipede_shell_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.12, 0.0, 0.025, 0.54),
		Color(0.82, 0.025, 0.11, 0.94),
		6,
		999,
		Color(0.48, 0.0, 0.08, 0.72),
		34
	)


func create_centipede_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.82, 0.02, 0.09, 0.82),
		Color(1.0, 0.72, 0.76, 0.98),
		3,
		999,
		Color(0.92, 0.01, 0.12, 0.68),
		22
	)


func create_centipede_limb_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.52, 0.0, 0.08, 0.86),
		Color(0.98, 0.22, 0.30, 0.96),
		2,
		999,
		Color(0.62, 0.0, 0.09, 0.62),
		16
	)


func create_dragon_body_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.055, 0.0, 0.018, 0.66),
		Color(0.66, 0.015, 0.08, 0.92),
		8,
		999,
		Color(0.36, 0.0, 0.055, 0.78),
		42
	)


func create_dragon_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.92, 0.035, 0.11, 0.88),
		Color(1.0, 0.82, 0.84, 0.98),
		4,
		999,
		Color(0.92, 0.01, 0.12, 0.76),
		28
	)


func create_dragon_wing_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.34, 0.0, 0.055, 0.90),
		Color(0.88, 0.08, 0.18, 0.96),
		3,
		999,
		Color(0.50, 0.0, 0.07, 0.68),
		20
	)


func create_saint_sword_halo_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.07, 0.0, 0.018, 0.58),
		Color(0.94, 0.24, 0.34, 0.94),
		5,
		999,
		Color(0.72, 0.01, 0.10, 0.76),
		36
	)


func create_saint_sword_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(1.0, 0.76, 0.78, 0.96),
		Color(1.0, 0.96, 0.96, 1.0),
		3,
		999,
		Color(0.96, 0.06, 0.16, 0.82),
		24
	)


func create_saint_sword_blade_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.96, 0.18, 0.28, 0.94),
		Color(1.0, 0.88, 0.90, 1.0),
		2,
		999,
		Color(0.86, 0.02, 0.14, 0.74),
		18
	)


func create_bikaku_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.88, 0.06, 0.18, 0.90),
		Color(1.0, 0.68, 0.74, 1.0),
		3,
		999,
		Color(0.70, 0.0, 0.10, 0.78),
		26
	)


func create_bikaku_tail_style(index: int) -> StyleBoxFlat:
	var mix_amount := float(index) / 8.0
	return create_glow_style(
		Color(0.48, 0.015, 0.10, 0.94).lerp(Color(0.78, 0.04, 0.20, 0.96), mix_amount),
		Color(1.0, 0.20, 0.36, 0.98),
		2,
		999,
		Color(0.60, 0.0, 0.08, 0.72),
		18
	)


func create_free_meal_shelter_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.18, 0.09, 0.055, 0.72),
		Color(0.96, 0.72, 0.38, 0.96),
		3,
		999,
		Color(0.32, 0.12, 0.04, 0.62),
		24
	)


func create_free_meal_warmth_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(1.0, 0.72, 0.34, 0.88),
		Color(1.0, 0.94, 0.72, 1.0),
		2,
		999,
		Color(0.84, 0.34, 0.08, 0.72),
		22
	)


func create_kakuja_shell_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.16, 0.01, 0.025, 0.84),
		Color(0.82, 0.04, 0.12, 0.98),
		4,
		999,
		Color(0.24, 0.0, 0.02, 0.82),
		32
	)


func create_kakuja_core_style() -> StyleBoxFlat:
	return create_glow_style(
		Color(0.96, 0.82, 0.74, 0.96),
		Color(1.0, 0.18, 0.24, 1.0),
		3,
		999,
		Color(0.74, 0.0, 0.06, 0.84),
		24
	)


func create_kakuja_feather_style(index: int) -> StyleBoxFlat:
	var intensity := 0.08 * float(index % 4)
	return create_glow_style(
		Color(0.30 + intensity, 0.008, 0.035, 0.96),
		Color(0.96, 0.08 + intensity, 0.16, 0.98),
		2,
		999,
		Color(0.34, 0.0, 0.025, 0.74),
		18
	)


func create_glow_style(
	background: Color,
	border: Color,
	border_width: int,
	corner_radius: int,
	shadow: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
