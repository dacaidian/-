extends RefCounted

# One controlled palette keeps Beastmen effects earthy, physical, and distinct
# from holy, arcane, fel, and nature-healing visuals.
const SOIL_BLACK := Color(0.055, 0.035, 0.022, 0.94)
const DEEP_EARTH := Color(0.16, 0.085, 0.035, 0.92)
const EARTH := Color(0.31, 0.17, 0.075, 0.88)
const DUST := Color(0.62, 0.43, 0.22, 0.78)
const DRIED_BLOOD := Color(0.45, 0.055, 0.028, 0.92)
const BLOOD_EDGE := Color(0.78, 0.13, 0.045, 0.92)
const DARK_ORANGE := Color(0.88, 0.31, 0.055, 0.94)
const EMBER := Color(1.0, 0.58, 0.13, 0.98)
const BONE := Color(0.82, 0.76, 0.60, 0.94)
const BONE_HIGHLIGHT := Color(0.96, 0.90, 0.70, 0.98)
const COPPER := Color(0.52, 0.27, 0.10, 0.92)
const DEEP_COPPER := Color(0.24, 0.105, 0.045, 0.94)
const CHAOS_PURPLE := Color(0.24, 0.045, 0.24, 0.86)
const CHAOS_GREEN := Color(0.34, 0.43, 0.085, 0.82)
const SMOKE := Color(0.10, 0.085, 0.065, 0.52)


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
