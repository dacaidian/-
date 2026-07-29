extends Button
class_name CardCollectionItem

const CardCatalogEntryScript := preload(
	"res://scripts/application/card_catalog_entry.gd"
)

signal preview_requested(entry)
signal preview_ended(entry)
signal entry_selected(entry)

const NORMAL_BORDER := Color(0.34, 0.31, 0.27, 0.86)
const HOVER_BORDER := Color(0.35, 0.67, 0.88, 1.0)
const SELECTED_BORDER := Color(0.91, 0.66, 0.28, 1.0)

@onready var image_frame: PanelContainer = %ImageFrame
@onready var card_texture: TextureRect = %CardTexture
@onready var missing_image_label: Label = %MissingImageLabel
@onready var category_badge: Label = %CategoryBadge
@onready var card_name_label: Label = %CardNameLabel
@onready var metadata_label: Label = %MetadataLabel

var entry: CardCatalogEntryScript
var is_entry_selected := false
var _hovered := false
var _mouse_hovered := false
var _focused := false
var _scale_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_on_pressed)
	resized.connect(_update_pivot)
	_update_pivot()
	_apply_entry()
	_refresh_style()


func setup(catalog_entry: CardCatalogEntryScript) -> void:
	entry = catalog_entry
	if is_node_ready():
		_apply_entry()


func set_entry_selected(selected: bool) -> void:
	is_entry_selected = selected
	if is_node_ready():
		_refresh_style()


func _apply_entry() -> void:
	if entry == null or entry.card_data == null:
		card_texture.texture = null
		missing_image_label.show()
		category_badge.hide()
		card_name_label.text = "未知卡牌"
		metadata_label.text = ""
		return

	var data := entry.card_data
	card_texture.texture = data.front_texture
	missing_image_label.visible = card_texture.texture == null
	category_badge.text = entry.get_category_label()
	category_badge.show()
	card_name_label.text = data.display_name
	metadata_label.text = "%d阶  ·  %s" % [data.level, entry.get_type_label()]
	tooltip_text = "%s · %s" % [data.display_name, entry.faction_display_name]
	_style_category_badge()


func _on_mouse_entered() -> void:
	_mouse_hovered = true
	_refresh_preview_state()


func _on_mouse_exited() -> void:
	_mouse_hovered = false
	_refresh_preview_state()


func _on_focus_entered() -> void:
	_focused = true
	_refresh_preview_state()


func _on_focus_exited() -> void:
	_focused = false
	_refresh_preview_state()


func _refresh_preview_state() -> void:
	var should_preview := _mouse_hovered or _focused
	if should_preview == _hovered or entry == null:
		return

	_hovered = should_preview
	z_index = 2 if _hovered else 0
	_refresh_style()
	if _hovered:
		preview_requested.emit(entry)
	else:
		preview_ended.emit(entry)


func _on_pressed() -> void:
	if entry != null:
		entry_selected.emit(entry)


func _refresh_style() -> void:
	var border_color := NORMAL_BORDER
	var background := Color(0.055, 0.050, 0.045, 0.96)
	if is_entry_selected:
		border_color = SELECTED_BORDER
		background = Color(0.11, 0.083, 0.047, 0.98)
	elif _hovered:
		border_color = HOVER_BORDER
		background = Color(0.055, 0.082, 0.10, 0.98)

	add_theme_stylebox_override("normal", _create_item_style(background, border_color, 2 if is_entry_selected else 1))
	add_theme_stylebox_override("hover", _create_item_style(background, border_color, 2))
	add_theme_stylebox_override("pressed", _create_item_style(background.lightened(0.04), border_color, 2))
	add_theme_stylebox_override("focus", _create_focus_style(border_color))

	if image_frame != null:
		image_frame.add_theme_stylebox_override("panel", _create_image_style(border_color))

	var target_scale := Vector2(1.018, 1.018) if _hovered else Vector2.ONE
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", target_scale, 0.11)


func _style_category_badge() -> void:
	var accent := ApplicationUiStyle.BLUE
	if entry != null:
		match entry.category:
			CardCatalogEntryScript.CATEGORY_TOKEN:
				accent = Color(0.56, 0.39, 0.78, 1.0)
			CardCatalogEntryScript.CATEGORY_STARTING_HAND:
				accent = ApplicationUiStyle.GOLD
			CardCatalogEntryScript.CATEGORY_SYSTEM:
				accent = Color(0.38, 0.67, 0.57, 1.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.91)
	style.set_corner_radius_all(4)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	category_badge.add_theme_stylebox_override("normal", style)


func _create_item_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 5
	return style


func _create_image_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.018, 0.018, 1.0)
	style.border_color = Color(border.r, border.g, border.b, 0.64)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _create_focus_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.expand_margin_left = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_bottom = 2.0
	return style


func _update_pivot() -> void:
	pivot_offset = size * 0.5
