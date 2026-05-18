@tool
extends PanelContainer

# @tool 让这段脚本在编辑器里也会运行。
# 这样调整窗口或参数时，CardBoard 和卡槽尺寸能尽量接近运行时效果。

# 设计状态下的最大棋盘尺寸。屏幕足够大时使用这个尺寸。
@export var max_board_size := Vector2(980, 1340)

# 棋盘和屏幕边缘之间至少保留的距离。
@export var viewport_margin := Vector2(40, 40)

# 卡槽的宽高比例，保持和卡牌一致。
@export var slot_aspect_ratio := 180.0 / 252.0

# 棋盘内部真正负责 5 列排列的容器。
@onready var grid_container: GridContainer = $MarginContainer/GridContainer

func _ready() -> void:
	# 节点进入场景后，根据当前视窗大小计算一次棋盘尺寸。
	resize_to_viewport()


func _notification(what: int) -> void:
	# 当控件尺寸变化时重新计算，适配全屏和窗口变化。
	if what == NOTIFICATION_RESIZED:
		resize_to_viewport()


func resize_to_viewport() -> void:
	# 当前游戏视窗大小。
	var viewport_size: Vector2 = get_viewport_rect().size

	# 去掉边缘安全距离后，棋盘真正可以使用的区域。
	var available_size: Vector2 = Vector2(
		maxf(viewport_size.x - viewport_margin.x * 2.0, 1.0),
		maxf(viewport_size.y - viewport_margin.y * 2.0, 1.0)
	)

	# 按宽高里更紧张的一边缩放，最大不超过设计尺寸。
	var scale_factor: float = minf(
		available_size.x / max_board_size.x,
		available_size.y / max_board_size.y
	)
	scale_factor = minf(
		scale_factor,
		1.0
	)
	var board_size: Vector2 = max_board_size * scale_factor

	# 更新棋盘自身尺寸，再同步更新内部卡槽。
	custom_minimum_size = board_size
	size = board_size
	update_slot_sizes(board_size)


func update_slot_sizes(board_size: Vector2) -> void:
	if grid_container == null:
		return

	# 这些数值要和 card_board.tscn 里的 MarginContainer / GridContainer 间距保持一致。
	var margin: float = 16.0 * 2.0
	var gap_count: float = 4.0
	var horizontal_gap: float = 12.0
	var vertical_gap: float = 12.0
	var inner_size: Vector2 = board_size - Vector2(margin, margin)

	# 先按 5 行 5 列均分可用空间。
	var slot_width: float = (inner_size.x - horizontal_gap * gap_count) / 5.0
	var slot_height: float = (inner_size.y - vertical_gap * gap_count) / 5.0

	# 再修正为卡牌比例，避免卡槽在不同屏幕上被拉伸变形。
	if slot_width / slot_height > slot_aspect_ratio:
		slot_width = slot_height * slot_aspect_ratio
	else:
		slot_height = slot_width / slot_aspect_ratio

	# 把计算出的尺寸应用到每一个卡槽，并同步处理槽内卡牌。
	for child in grid_container.get_children():
		if child is Control:
			var slot_size := Vector2(slot_width, slot_height)
			child.custom_minimum_size = slot_size
			resize_cards_in_slot(child, slot_size)


func resize_cards_in_slot(slot: Control, slot_size: Vector2) -> void:
	# 卡牌实例放在 CardSlot 下面时，也要跟着卡槽一起缩放。
	for child in slot.get_children():
		if child is Control:
			child.custom_minimum_size = slot_size
			child.size = slot_size

			# card.gd 暴露了 card_size；用 set 可以避免这里强依赖具体脚本类型。
			child.set("card_size", slot_size)
