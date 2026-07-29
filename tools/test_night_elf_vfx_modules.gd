extends SceneTree

const FactoryScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_factory.gd"
)
const RuntimeScript := preload(
	"res://scripts/ui/animation/night_elf_vfx_runtime.gd"
)
const KineticScript := preload(
	"res://scripts/ui/animation/night_elf_kinetic_vfx.gd"
)
const SupportScript := preload(
	"res://scripts/ui/animation/night_elf_support_vfx.gd"
)
const CelestialScript := preload(
	"res://scripts/ui/animation/night_elf_celestial_vfx.gd"
)
const TimeScript := preload(
	"res://scripts/ui/animation/night_elf_time_vfx.gd"
)


func _initialize() -> void:
	var factory := FactoryScript.new()
	var runtime := RuntimeScript.new()
	runtime.setup(0.01)
	for module in [
		KineticScript.new(),
		SupportScript.new(),
		CelestialScript.new(),
		TimeScript.new()
	]:
		module.setup(factory, runtime)

	_assert_vector_close(
		runtime.quadratic_bezier(
			Vector2.ZERO,
			Vector2(1.0, 2.0),
			Vector2(2.0, 0.0),
			0.5
		),
		Vector2(1.0, 1.0),
		"quadratic Bezier midpoint"
	)
	if not is_equal_approx(runtime.scaled_duration(1.0, 0.10), 0.10):
		push_error("Night Elf VFX runtime did not apply the minimum duration")
		quit(1)
		return
	print("NIGHT_ELF_VFX_MODULE_TESTS_OK")
	quit()


func _assert_vector_close(
	actual: Vector2,
	expected: Vector2,
	label: String
) -> void:
	if actual.distance_to(expected) <= 0.001:
		return
	push_error("%s mismatch: %s != %s" % [label, actual, expected])
	quit(1)
