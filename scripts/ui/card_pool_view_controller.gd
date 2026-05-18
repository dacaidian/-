extends RefCounted
class_name CardPoolViewController

# CardPoolViewController 只负责公共牌池的表现：
# 固定牌堆节点、剩余数量显示、以及从牌堆飞向棋盘空格的补位动画。

var view: Control
var animation_root: Control
var count_label: Label
var back_texture: Texture2D
var fallback_back_texture: Texture2D
var fallback_view_size := Vector2(150, 210)
var fallback_view_margin := 28.0
var refill_animation_duration := 0.36


func setup(
	root: Node,
	view_path: NodePath,
	animation_root_path: NodePath,
	new_back_texture: Texture2D,
	view_size: Vector2,
	view_margin: float,
	animation_duration: float
) -> void:
	fallback_back_texture = new_back_texture
	back_texture = new_back_texture
	fallback_view_size = view_size
	fallback_view_margin = view_margin
	refill_animation_duration = animation_duration

	if root == null:
		return

	setup_animation_root(root, animation_root_path)
	setup_view(root, view_path)


func setup_animation_root(root: Node, animation_root_path: NodePath) -> void:
	var configured_root := root.get_node_or_null(animation_root_path) as Control
	if configured_root != null:
		animation_root = configured_root
		animation_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	animation_root = Control.new()
	animation_root.name = "CardPoolAnimationRoot"
	animation_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	animation_root.z_index = 2000
	root.add_child.call_deferred(animation_root)


func setup_view(root: Node, view_path: NodePath) -> void:
	var configured_view := root.get_node_or_null(view_path) as Control
	if configured_view != null:
		view = configured_view
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label = view.get_node_or_null("CountLabel") as Label
		apply_view_textures()
		return

	if animation_root == null:
		return

	view = Control.new()
	view.name = "CardPoolView"
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.custom_minimum_size = fallback_view_size
	view.size = fallback_view_size
	view.position = get_fallback_view_position(root)
	animation_root.add_child(view)

	create_stack_visual()


func apply_view_textures() -> void:
	if view == null:
		return

	for child in view.get_children():
		if child is TextureRect:
			var texture_rect := child as TextureRect
			texture_rect.texture = back_texture
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func create_stack_visual() -> void:
	if view == null:
		return

	var stack_offsets: Array[Vector2] = [
		Vector2(12.0, 12.0),
		Vector2(6.0, 6.0),
		Vector2.ZERO
	]

	for index in range(stack_offsets.size()):
		var card_back := TextureRect.new()
		card_back.name = "StackCard%d" % (index + 1)
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_back.texture = back_texture
		card_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_back.stretch_mode = TextureRect.STRETCH_SCALE
		card_back.custom_minimum_size = fallback_view_size
		card_back.size = fallback_view_size
		card_back.position = stack_offsets[index]
		card_back.modulate = Color(1.0, 1.0, 1.0, 0.72 + float(index) * 0.12)
		view.add_child(card_back)

	count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	count_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.anchor_left = 0.0
	count_label.anchor_top = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.offset_left = 0.0
	count_label.offset_top = 4.0
	count_label.offset_right = 8.0
	count_label.offset_bottom = 30.0
	view.add_child(count_label)


func update(remaining_count: int, root: Node = null, next_back_texture: Texture2D = null) -> void:
	if view == null:
		return

	set_back_texture(next_back_texture if next_back_texture != null else fallback_back_texture)

	if root != null and view.get_parent() == animation_root:
		view.position = get_fallback_view_position(root)

	view.visible = remaining_count > 0
	if count_label != null:
		count_label.text = "%d" % remaining_count


func set_back_texture(new_back_texture: Texture2D) -> void:
	if new_back_texture == null or back_texture == new_back_texture:
		return

	back_texture = new_back_texture
	apply_view_textures()


func get_fallback_view_position(root: Node) -> Vector2:
	var viewport_size := Vector2.ZERO
	if root != null:
		viewport_size = root.get_viewport().get_visible_rect().size

	return Vector2(
		fallback_view_margin,
		(viewport_size.y - fallback_view_size.y) * 0.5
	)


func play_refill_animation(owner: Node, target_card: Card, card_back_texture: Texture2D = null) -> void:
	if owner == null or target_card == null or animation_root == null or view == null:
		return

	var pool_rect: Rect2 = view.get_global_rect()
	var target_rect: Rect2 = target_card.get_global_rect()
	var flying_card := TextureRect.new()
	flying_card.name = "RefillCard"
	flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_card.texture = card_back_texture if card_back_texture != null else back_texture
	flying_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_card.stretch_mode = TextureRect.STRETCH_SCALE
	flying_card.size = pool_rect.size
	flying_card.pivot_offset = flying_card.size * 0.5
	flying_card.z_index = 2000
	animation_root.add_child(flying_card)
	flying_card.global_position = pool_rect.position

	var tween: Tween = owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flying_card, "global_position", target_rect.position, refill_animation_duration)
	tween.tween_property(flying_card, "size", target_rect.size, refill_animation_duration)
	tween.tween_property(flying_card, "rotation", 0.08, refill_animation_duration * 0.45)
	await tween.finished

	var settle_tween: Tween = owner.create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_BACK)
	settle_tween.set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(flying_card, "rotation", 0.0, 0.12)
	settle_tween.tween_property(flying_card, "scale", Vector2(1.03, 1.03), 0.06)
	settle_tween.chain().tween_property(flying_card, "scale", Vector2.ONE, 0.06)
	await settle_tween.finished

	flying_card.queue_free()
