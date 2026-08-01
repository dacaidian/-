extends RefCounted

# Shadowmoon effects share a pressurized fel palette. Bright acid is reserved for
# hot cores; charcoal and violet carry most silhouettes so cards remain readable.
const VOID := Color(0.018, 0.008, 0.026, 0.96)
const CHARCOAL := Color(0.055, 0.065, 0.052, 0.94)
const INK_GREEN := Color(0.035, 0.19, 0.075, 0.90)
const FEL_GREEN := Color(0.20, 0.82, 0.10, 0.94)
const ACID := Color(0.58, 1.0, 0.10, 0.98)
const HOT_CORE := Color(0.90, 1.0, 0.48, 1.0)
const SICK_YELLOW := Color(0.82, 0.82, 0.16, 0.92)
const DEEP_PURPLE := Color(0.13, 0.025, 0.20, 0.94)
const SOUL_PURPLE := Color(0.36, 0.12, 0.62, 0.92)
const SOUL_BLUE := Color(0.24, 0.30, 0.72, 0.88)
const BLOOD_PURPLE := Color(0.35, 0.035, 0.16, 0.92)
const CURSE_RED := Color(0.64, 0.055, 0.16, 0.94)
const DEMON_ORANGE := Color(0.75, 0.20, 0.035, 0.92)
const EMBER := Color(1.0, 0.48, 0.08, 0.96)
const ASH := Color(0.18, 0.14, 0.12, 0.70)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))


static func phase(progress: float, start: float, finish: float) -> float:
	return clampf((progress - start) / maxf(finish - start, 0.0001), 0.0, 1.0)


static func ease_out(value: float) -> float:
	var safe_value := clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - safe_value, 3.0)


static func ease_in_out(value: float) -> float:
	var safe_value := clampf(value, 0.0, 1.0)
	return safe_value * safe_value * (3.0 - 2.0 * safe_value)
