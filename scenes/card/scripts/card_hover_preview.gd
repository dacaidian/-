extends Node

# 这个脚本是 Card 的子组件，只负责“鼠标悬浮时显示大图预览”。
# Card 本体只需要发出翻面信号，预览组件自己决定什么时候显示或隐藏。

# 鼠标悬浮时展示的大图尺寸。
@export var preview_size := Vector2(360, 504)

# 大图和 CardBoard 之间的距离。
@export var preview_gap := 16.0

# 父节点 Card。这里不写成强类型，是因为它访问的是 card.gd 自定义属性和信号。
var card

# 记录鼠标是否还停留在父卡牌上。
var is_mouse_hovering := false

# 运行时临时创建的大图节点。
var preview_rect: TextureRect

func _ready() -> void:
	# 这个组件应当挂在 Card 节点下面，所以父节点就是它服务的卡牌。
	card = get_parent()
	if card == null:
		return

	add_to_group("card_hover_previews")

	# 监听父卡牌的鼠标事件和翻面信号。
	card.mouse_entered.connect(_on_card_mouse_entered)
	card.mouse_exited.connect(_on_card_mouse_exited)
	card.face_changed.connect(_on_card_face_changed)


func _exit_tree() -> void:
	# 组件被移除时，顺手清掉可能还显示着的预览节点。
	hide_preview()


func _on_card_mouse_entered() -> void:
	is_mouse_hovering = true

	if can_show_preview():
		show_preview()


func _on_card_mouse_exited() -> void:
	is_mouse_hovering = false
	hide_preview()


func _on_card_face_changed(is_face_up: bool) -> void:
	if is_mouse_hovering and (is_face_up or can_show_preview()):
		show_preview()
	else:
		hide_preview()


func can_show_preview() -> bool:
	if card == null:
		return false
	if card.is_face_up:
		return true

	var scene := get_tree().current_scene
	if scene != null and scene.has_method("can_preview_card_front"):
		return bool(scene.can_preview_card_front(card.state))

	return false


func show_preview() -> void:
	var front_texture: Texture2D = card.get_front_texture()
	if front_texture == null:
		return

	# 根据屏幕右侧剩余空间计算实际展示尺寸。
	var display_size: Vector2 = get_preview_display_size()

	if preview_rect == null:
		# 预览图不放进 CardBoard，避免挡住棋盘内其他卡牌的交互。
		preview_rect = TextureRect.new()
		preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_rect.z_index = 1000
		get_tree().current_scene.add_child(preview_rect)

	preview_rect.texture = front_texture
	preview_rect.custom_minimum_size = display_size
	preview_rect.size = display_size
	preview_rect.global_position = get_preview_position(display_size)
	preview_rect.show()


func hide_preview() -> void:
	if preview_rect != null:
		# queue_free 会在当前帧结束后安全删除节点。
		preview_rect.queue_free()
		preview_rect = null


func get_preview_position(display_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = card.get_viewport_rect().size
	var board_rect: Rect2 = get_card_board_rect()
	var card_rect: Rect2 = card.get_global_rect()

	# 默认把大图放在整个 CardBoard 的右侧，而不是当前卡牌的右侧。
	var target_position: Vector2 = Vector2(
		board_rect.position.x + board_rect.size.x + preview_gap,
		card_rect.position.y
	)

	# 防止预览图超出屏幕边界。
	target_position.x = clampf(target_position.x, 0.0, maxf(viewport_size.x - display_size.x, 0.0))
	target_position.y = clampf(target_position.y, 0.0, maxf(viewport_size.y - display_size.y, 0.0))

	return target_position


func get_preview_display_size() -> Vector2:
	var viewport_size: Vector2 = card.get_viewport_rect().size
	var board_rect: Rect2 = get_card_board_rect()

	# CardBoard 右侧还剩多少空间，就用这个空间来决定预览图是否需要缩小。
	var available_width: float = viewport_size.x - (board_rect.position.x + board_rect.size.x + preview_gap)
	var available_height: float = viewport_size.y
	var scale_factor: float = minf(available_width / preview_size.x, available_height / preview_size.y)
	scale_factor = minf(scale_factor, 1.0)

	# 给预览保留一个最低缩放比例，避免窗口太窄时直接小到不可见。
	scale_factor = maxf(scale_factor, 0.25)
	return preview_size * scale_factor


func get_card_board_rect() -> Rect2:
	var node: Node = card

	# 从 Card 往上找 CardBoard，这样这个组件可以在任意卡槽里复用。
	while node != null:
		if node.name == "CardBoard" and node is Control:
			return (node as Control).get_global_rect()

		node = node.get_parent()

	# 如果找不到 CardBoard，就退回到当前卡牌自己的区域。
	return card.get_global_rect()
