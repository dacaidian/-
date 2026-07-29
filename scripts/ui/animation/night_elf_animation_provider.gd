extends RefCounted
class_name NightElfAnimationProvider

# Stable routing facade. Skill choreography lives in the semantic VFX modules below.
const NightElfVfxFactoryScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_factory.gd"
)
const NightElfVfxRuntimeScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_runtime.gd"
)
const NightElfKineticVfxScript := preload(
	"res://scripts/ui/animation/night_elf_kinetic_vfx.gd"
)
const NightElfSupportVfxScript := preload(
	"res://scripts/ui/animation/night_elf_support_vfx.gd"
)
const NightElfCelestialVfxScript := preload(
	"res://scripts/ui/animation/night_elf_celestial_vfx.gd"
)
const NightElfTimeVfxScript := preload(
	"res://scripts/ui/animation/night_elf_time_vfx.gd"
)

const TARGETED_KEYS: Array[String] = [
	"moonblade",
	"tranquil_spring",
	"precision_shot",
	"full_moon_cover",
	"meteor_aura",
	"meteor_strike",
	"claw_strike",
	"elune_grace"
]
const RECT_KEYS: Array[String] = TARGETED_KEYS
const SOURCE_RECT_KEYS: Array[String] = [
	"moonblade",
	"tranquil_spring",
	"precision_shot",
	"full_moon_cover",
	"meteor_aura",
	"meteor_strike",
	"claw_strike"
]
const BOARD_KEYS: Array[String] = [
	"night_elf_time_transition",
	"night_elf_time_transition_sunrise",
	"night_elf_time_transition_noon",
	"night_elf_time_transition_dusk",
	"night_elf_time_transition_moonrise",
	"night_elf_time_transition_full_moon",
	"night_elf_time_transition_moonset"
]
const MULTI_RECT_KEYS: Array[String] = ["meteor_strike"]

var spell_animation_duration := 0.32

var _vfx := NightElfVfxFactoryScript.new()
var _runtime := NightElfVfxRuntimeScript.new()
var _kinetic := NightElfKineticVfxScript.new()
var _support := NightElfSupportVfxScript.new()
var _celestial := NightElfCelestialVfxScript.new()
var _time := NightElfTimeVfxScript.new()


func _init() -> void:
	_kinetic.setup(_vfx, _runtime)
	_support.setup(_vfx, _runtime)
	_celestial.setup(_vfx, _runtime)
	_time.setup(_vfx, _runtime)
	_runtime.setup(spell_animation_duration)


func setup(duration: float) -> void:
	spell_animation_duration = maxf(duration, 0.04)
	_runtime.setup(spell_animation_duration)


func register_routes(router: SpellAnimationRouter) -> void:
	if router == null:
		return
	router.register_targeted(TARGETED_KEYS, play_targeted)
	router.register_at_rect(RECT_KEYS, play_at_rect)
	router.register_from_rect(SOURCE_RECT_KEYS, play_from_rect)
	router.register_board(BOARD_KEYS, play_board)
	router.register_multi_rect(MULTI_RECT_KEYS, play_multi_rect)


func play_targeted(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card,
	animation_key: String
) -> void:
	if owner == null or effect_root == null or target_card == null:
		return

	var target_rect := target_card.get_global_rect()
	match animation_key:
		"moonblade":
			if caster_card != null:
				await _kinetic.play_moonblade_path(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_rect
				)
			else:
				await _kinetic.play_moonblade_impact(
					owner,
					effect_root,
					target_rect
				)
		"tranquil_spring":
			if caster_card != null:
				await _support.play_tranquil_spring(
					owner,
					effect_root,
					caster_card.get_global_rect(),
					target_rect
				)
			else:
				await _support.play_tranquil_spring_target(
					owner,
					effect_root,
					target_rect
				)
		"claw_strike":
			var source_rect := target_rect
			if caster_card != null:
				source_rect = caster_card.get_global_rect()
			await _kinetic.play_claw_strike(
				owner,
				effect_root,
				source_rect,
				target_rect
			)
		_:
			await play_at_rect(owner, effect_root, target_rect, animation_key)


func play_at_rect(
	owner: Node,
	effect_root: Control,
	target_rect: Rect2,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or target_rect.size == Vector2.ZERO
		or not RECT_KEYS.has(animation_key)
	):
		return

	match animation_key:
		"moonblade":
			await _kinetic.play_moonblade_impact(
				owner,
				effect_root,
				target_rect
			)
		"tranquil_spring":
			await _support.play_tranquil_spring_target(
				owner,
				effect_root,
				target_rect
			)
		"precision_shot":
			await _support.play_precision_shot(owner, effect_root, target_rect)
		"full_moon_cover":
			await _celestial.play_full_moon_cover(
				owner,
				effect_root,
				target_rect
			)
		"meteor_aura":
			await _celestial.play_meteor_aura(owner, effect_root, target_rect)
		"meteor_strike":
			await _celestial.play_meteors(owner, effect_root, [target_rect])
		"claw_strike":
			var source_rect := Rect2(
				target_rect.position
				- Vector2(target_rect.size.x, target_rect.size.y * 0.35),
				target_rect.size
			)
			await _kinetic.play_claw_strike(
				owner,
				effect_root,
				source_rect,
				target_rect
			)
		"elune_grace":
			await _support.play_elune_grace(owner, effect_root, target_rect)


func play_from_rect(
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or source_rect.size == Vector2.ZERO
		or target_card == null
	):
		return

	var target_rect := target_card.get_global_rect()
	match animation_key:
		"moonblade":
			await _kinetic.play_moonblade_path(
				owner,
				effect_root,
				source_rect,
				target_rect
			)
		"tranquil_spring":
			await _support.play_tranquil_spring(
				owner,
				effect_root,
				source_rect,
				target_rect
			)
		"claw_strike":
			await _kinetic.play_claw_strike(
				owner,
				effect_root,
				source_rect,
				target_rect
			)
		_:
			await play_at_rect(owner, effect_root, target_rect, animation_key)


func play_board(
	owner: Node,
	effect_root: Control,
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or not BOARD_KEYS.has(animation_key)
	):
		return
	await _time.play_transition(owner, effect_root, animation_key)


func play_multi_rect(
	owner: Node,
	effect_root: Control,
	target_rects: Array[Rect2],
	animation_key: String
) -> void:
	if (
		owner == null
		or effect_root == null
		or target_rects.is_empty()
		or animation_key != "meteor_strike"
	):
		return

	var valid_rects: Array[Rect2] = []
	for target_rect in target_rects:
		if target_rect.size != Vector2.ZERO:
			valid_rects.append(target_rect)
	if not valid_rects.is_empty():
		await _celestial.play_meteors(owner, effect_root, valid_rects)


func play_moonblade(
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	first_card: Card,
	second_card: Card
) -> void:
	if (
		owner == null
		or effect_root == null
		or caster_card == null
		or first_card == null
		or second_card == null
	):
		return
	await _kinetic.play_moonblade(
		owner,
		effect_root,
		caster_card.get_global_rect(),
		first_card.get_global_rect(),
		second_card.get_global_rect()
	)
