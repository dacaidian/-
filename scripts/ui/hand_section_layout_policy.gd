extends RefCounted
class_name HandSectionLayoutPolicy

# 手牌分区高度的纯计算策略。它不读取节点，也不修改滚动状态。
const EMPTY_SECTION_HEIGHT := 38.0
const ACTIVE_SECTION_MIN_HEIGHT := 88.0
const SECTION_CHROME_HEIGHT := 74.0
const CARD_HEIGHT := 252.0
const CARD_ROW_SEPARATION := 12.0


func allocate(
	card_types: Array[String],
	card_counts: Dictionary,
	available_height: float,
	section_separation: float,
	cards_per_row: int
) -> Dictionary:
	var allocations: Dictionary = {}
	if card_types.is_empty():
		return allocations

	var content_budget := maxf(
		available_height - section_separation * float(maxi(card_types.size() - 1, 0)),
		0.0
	)
	var preferred_heights: Dictionary = {}
	var base_total := 0.0

	for card_type in card_types:
		var card_count := maxi(int(card_counts.get(card_type, 0)), 0)
		var base_height := EMPTY_SECTION_HEIGHT if card_count == 0 else ACTIVE_SECTION_MIN_HEIGHT
		allocations[card_type] = base_height
		preferred_heights[card_type] = get_preferred_height(card_count, cards_per_row)
		base_total += base_height

	if base_total > content_budget:
		return shrink_to_budget(card_types, allocations, content_budget)

	var remaining := content_budget - base_total
	var candidates: Array[String] = []
	for card_type in card_types:
		if float(preferred_heights[card_type]) > float(allocations[card_type]):
			candidates.append(card_type)

	while remaining > 0.01 and not candidates.is_empty():
		var total_weight := 0.0
		var weights: Dictionary = {}
		for card_type in candidates:
			var weight := get_content_weight(
				int(card_counts.get(card_type, 0)),
				cards_per_row
			)
			weights[card_type] = weight
			total_weight += weight
		var saturated: Array[String] = []
		for card_type in candidates:
			var weighted_share := remaining * float(weights[card_type]) / maxf(total_weight, 1.0)
			var unmet := float(preferred_heights[card_type]) - float(allocations[card_type])
			if unmet <= weighted_share + 0.01:
				allocations[card_type] = float(preferred_heights[card_type])
				remaining -= unmet
				saturated.append(card_type)

		if saturated.is_empty():
			for card_type in candidates:
				var weighted_share := remaining * float(weights[card_type]) / maxf(total_weight, 1.0)
				allocations[card_type] = float(allocations[card_type]) + weighted_share
			remaining = 0.0
		else:
			for card_type in saturated:
				candidates.erase(card_type)

	return allocations


func get_preferred_height(card_count: int, cards_per_row: int) -> float:
	if card_count <= 0:
		return EMPTY_SECTION_HEIGHT

	var safe_cards_per_row := maxi(cards_per_row, 1)
	var row_count := ceili(float(card_count) / float(safe_cards_per_row))
	return (
		SECTION_CHROME_HEIGHT
		+ CARD_HEIGHT * float(row_count)
		+ CARD_ROW_SEPARATION * float(maxi(row_count - 1, 0))
	)


func get_content_weight(card_count: int, cards_per_row: int) -> float:
	if card_count <= 0:
		return 0.0
	var row_count := ceili(float(card_count) / float(maxi(cards_per_row, 1)))
	return sqrt(float(maxi(row_count, 1)))


func shrink_to_budget(card_types: Array[String], allocations: Dictionary, content_budget: float) -> Dictionary:
	var shrunk: Dictionary = {}
	if content_budget <= 0.0:
		for card_type in card_types:
			shrunk[card_type] = 0.0
		return shrunk

	var requested_total := 0.0
	for card_type in card_types:
		requested_total += float(allocations.get(card_type, 0.0))
	var scale_factor := content_budget / maxf(requested_total, 1.0)
	for card_type in card_types:
		shrunk[card_type] = float(allocations.get(card_type, 0.0)) * scale_factor
	return shrunk
