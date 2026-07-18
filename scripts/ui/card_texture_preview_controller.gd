extends RefCounted
class_name CardTexturePreviewController

# 通用 HUD 卡图悬浮预览。只管理表现，不读取或修改规则状态。

const PREVIEW_SIZE := Vector2(240, 336)
const VIEWPORT_MARGIN := 12.0
const SOURCE_GAP := 16.0
const PREVIEW_Z_INDEX := 3400
const PREVIEW_GROUP := "hud_card_texture_previews"

var host: Control
var preview_rect: TextureRect


func setup(root: Control) -> void:
	if root == null or (preview_rect != null and is_instance_valid(preview_rect)):
		return

	host = root
	preview_rect = TextureRect.new()
	preview_rect.name = "CardTextureHoverPreview"
	preview_rect.custom_minimum_size = PREVIEW_SIZE
	preview_rect.size = PREVIEW_SIZE
	preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.z_index = PREVIEW_Z_INDEX
	preview_rect.add_to_group(PREVIEW_GROUP)
	preview_rect.hide()
	root.add_child.call_deferred(preview_rect)


func bind_card(source_control: Control, card_data: CardData) -> void:
	if source_control == null or card_data == null:
		return

	source_control.mouse_filter = Control.MOUSE_FILTER_STOP
	source_control.mouse_entered.connect(
		func(): show_preview(card_data.front_texture, source_control)
	)
	source_control.mouse_exited.connect(hide_preview)


func show_preview(texture: Texture2D, source_control: Control) -> void:
	if texture == null or source_control == null or not is_instance_valid(source_control):
		return
	if preview_rect == null or not is_instance_valid(preview_rect):
		setup(host)
	if preview_rect == null:
		return

	preview_rect.texture = texture
	preview_rect.size = PREVIEW_SIZE
	preview_rect.global_position = get_preview_position(source_control)
	preview_rect.show()


func hide_preview() -> void:
	if preview_rect == null or not is_instance_valid(preview_rect):
		return
	preview_rect.hide()
	preview_rect.texture = null


func get_preview_position(source_control: Control) -> Vector2:
	var source_rect := source_control.get_global_rect()
	var viewport_size := source_control.get_viewport_rect().size
	var x := source_rect.position.x - PREVIEW_SIZE.x - SOURCE_GAP
	if x < VIEWPORT_MARGIN:
		x = source_rect.end.x + SOURCE_GAP
	x = clampf(x, VIEWPORT_MARGIN, maxf(VIEWPORT_MARGIN, viewport_size.x - PREVIEW_SIZE.x - VIEWPORT_MARGIN))
	var y := clampf(
		source_rect.position.y,
		VIEWPORT_MARGIN,
		maxf(VIEWPORT_MARGIN, viewport_size.y - PREVIEW_SIZE.y - VIEWPORT_MARGIN)
	)
	return Vector2(x, y)
