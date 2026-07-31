extends Control
class_name CardCollectionScreen

signal back_requested

const CardCatalogEntryScript := preload(
	"res://scripts/application/card_catalog_entry.gd"
)
const CardCollectionCatalogScript := preload(
	"res://scripts/application/card_collection_catalog.gd"
)
const CardCollectionItemScript := preload(
	"res://scripts/ui/card_collection_item.gd"
)

const CARD_DATA_PATH := "res://data/cards.json"
const ITEM_SCENE_PATH := "res://scenes/ui/card_collection_item.tscn"
const PAGE_SIZE := 12
const CARD_ITEM_WIDTH := 176.0
const GRID_SEPARATION := 12.0

const TYPE_OPTIONS := [
	["全部类型", ""],
	["英雄牌", CardData.ROLE_HERO],
	["随从牌", CardData.TYPE_MINION],
	["法术牌", CardData.TYPE_SPELL],
	["建筑牌", CardData.TYPE_BUILDING],
	["升级牌", CardData.TYPE_UPGRADE],
	["装备牌", CardData.TYPE_EQUIPMENT],
	["状态牌", CardData.TYPE_TIME],
]

const CATEGORY_OPTIONS := [
	["全部来源", ""],
	["常规牌池", CardCatalogEntryScript.CATEGORY_POOL],
	["默认入手", CardCatalogEntryScript.CATEGORY_STARTING_HAND],
	["衍生牌", CardCatalogEntryScript.CATEGORY_TOKEN],
	["状态展示", CardCatalogEntryScript.CATEGORY_SYSTEM],
]

const LEVEL_OPTIONS := [
	["全部阶级", 0],
	["1阶", 1],
	["2阶", 2],
	["3阶", 3],
]

const SORT_OPTIONS := [
	["默认排序", CardCollectionCatalogScript.SORT_DEFAULT],
	["按名称", CardCollectionCatalogScript.SORT_NAME],
	["按阶级", CardCollectionCatalogScript.SORT_LEVEL],
	["按类型", CardCollectionCatalogScript.SORT_TYPE],
]

@onready var back_button: Button = %BackButton
@onready var collection_count_label: Label = %CollectionCountLabel
@onready var faction_panel: PanelContainer = %FactionPanel
@onready var faction_list: VBoxContainer = %FactionList
@onready var filter_panel: PanelContainer = %FilterPanel
@onready var search_input: LineEdit = %SearchInput
@onready var reset_button: Button = %ResetButton
@onready var type_option: OptionButton = %TypeOption
@onready var category_option: OptionButton = %CategoryOption
@onready var level_option: OptionButton = %LevelOption
@onready var sort_option: OptionButton = %SortOption
@onready var results_panel: PanelContainer = %ResultsPanel
@onready var result_summary_label: Label = %ResultSummaryLabel
@onready var card_grid_scroll: ScrollContainer = %CardGridScroll
@onready var card_grid: GridContainer = %CardGrid
@onready var empty_state: CenterContainer = %EmptyState
@onready var previous_page_button: Button = %PreviousPageButton
@onready var next_page_button: Button = %NextPageButton
@onready var page_label: Label = %PageLabel
@onready var details_panel: PanelContainer = %DetailsPanel
@onready var details_texture: TextureRect = %DetailsTexture
@onready var details_missing_image: Label = %DetailsMissingImage
@onready var details_name_label: Label = %DetailsNameLabel
@onready var details_faction_label: Label = %DetailsFactionLabel
@onready var details_meta_label: Label = %DetailsMetaLabel
@onready var details_category_label: Label = %DetailsCategoryLabel
@onready var details_stats_label: Label = %DetailsStatsLabel
@onready var details_description_label: Label = %DetailsDescriptionLabel
@onready var keyword_title_label: Label = %KeywordTitleLabel
@onready var keyword_flow: HFlowContainer = %KeywordFlow
@onready var owner_hero_label: Label = %OwnerHeroLabel
@onready var collection_note_label: Label = %CollectionNoteLabel
@onready var card_id_label: Label = %CardIdLabel
@onready var search_debounce: Timer = %SearchDebounce

var card_database := CardDatabase.new()
var catalog := CardCollectionCatalogScript.new()
var item_scene: PackedScene
var current_results: Array[CardCatalogEntryScript] = []
var current_page_entries: Array[CardCatalogEntryScript] = []
var selected_entry: CardCatalogEntryScript
var preview_entry: CardCatalogEntryScript
var selected_faction_id := ""
var page_index := 0
var faction_button_group := ButtonGroup.new()
var faction_buttons: Dictionary = {}


func _ready() -> void:
	_apply_styles()
	_connect_controls()
	_populate_filter_options()

	item_scene = load(ITEM_SCENE_PATH) as PackedScene
	if item_scene == null or not card_database.load_from_json(CARD_DATA_PATH):
		_show_load_failure()
		return

	catalog.rebuild(card_database)
	_build_faction_navigation()
	_apply_filters(true)
	back_button.grab_focus.call_deferred()


func _exit_tree() -> void:
	for entry in catalog.entries:
		if entry != null and entry.card_data != null:
			entry.card_data.release_front_texture_cache()


func get_result_count() -> int:
	return current_results.size()


func get_current_page_entries() -> Array[CardCatalogEntryScript]:
	return current_page_entries.duplicate()


func _connect_controls() -> void:
	back_button.pressed.connect(func(): back_requested.emit())
	reset_button.pressed.connect(_reset_filters)
	search_input.text_changed.connect(_on_search_text_changed)
	search_debounce.timeout.connect(func(): _apply_filters(true))
	type_option.item_selected.connect(func(_index): _apply_filters(true))
	category_option.item_selected.connect(func(_index): _apply_filters(true))
	level_option.item_selected.connect(func(_index): _apply_filters(true))
	sort_option.item_selected.connect(func(_index): _apply_filters(true))
	previous_page_button.pressed.connect(func(): _change_page(-1))
	next_page_button.pressed.connect(func(): _change_page(1))
	card_grid_scroll.resized.connect(_refresh_grid_columns)


func _populate_filter_options() -> void:
	_populate_option_button(type_option, TYPE_OPTIONS)
	_populate_option_button(category_option, CATEGORY_OPTIONS)
	_populate_option_button(level_option, LEVEL_OPTIONS)
	_populate_option_button(sort_option, SORT_OPTIONS)


func _populate_option_button(option_button: OptionButton, options: Array) -> void:
	option_button.clear()
	for option in options:
		option_button.add_item(str(option[0]))
		option_button.set_item_metadata(option_button.item_count - 1, option[1])
	option_button.select(0)


func _build_faction_navigation() -> void:
	for child in faction_list.get_children():
		child.queue_free()
	faction_buttons.clear()

	_add_faction_button("", "全部卡牌", catalog.get_total_count(), null)
	for faction_id in catalog.faction_ids:
		var faction_name := card_database.get_faction_display_name(faction_id)
		_add_faction_button(
			faction_id,
			faction_name,
			catalog.get_faction_count(faction_id),
			_load_faction_logo(faction_id)
		)

	_set_faction_button_pressed("")


func _add_faction_button(
	faction_id: String,
	display_name: String,
	count: int,
	logo: Texture2D
) -> void:
	var button := Button.new()
	button.name = "AllCardsButton" if faction_id == "" else "%sButton" % faction_id.to_pascal_case()
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.text = "%s  %d" % [display_name, count]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.button_group = faction_button_group
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 15)
	if logo != null:
		button.icon = logo
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)

	_style_faction_button(button)
	button.pressed.connect(_select_faction.bind(faction_id))
	faction_list.add_child(button)
	faction_buttons[faction_id] = button


func _select_faction(faction_id: String) -> void:
	selected_faction_id = faction_id
	_set_faction_button_pressed(faction_id)
	_apply_filters(true)


func _set_faction_button_pressed(faction_id: String) -> void:
	for key in faction_buttons:
		var button := faction_buttons[key] as Button
		if button != null:
			button.set_pressed_no_signal(str(key) == faction_id)


func _apply_filters(reset_page: bool) -> void:
	if catalog == null:
		return
	if reset_page:
		page_index = 0

	var filters := {
		"faction_id": selected_faction_id,
		"type": _get_selected_metadata(type_option, ""),
		"category": _get_selected_metadata(category_option, ""),
		"level": int(_get_selected_metadata(level_option, 0)),
		"sort": _get_selected_metadata(sort_option, CardCollectionCatalogScript.SORT_DEFAULT),
		"search": search_input.text,
	}
	current_results = catalog.query(filters)

	if selected_entry != null and not current_results.has(selected_entry):
		selected_entry = null
	if selected_entry == null and not current_results.is_empty():
		selected_entry = current_results[0]

	_render_page()
	_show_details(selected_entry)
	_update_filter_state()


func _render_page() -> void:
	_release_previous_page_textures()
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	current_page_entries.clear()

	var page_count := _get_page_count()
	page_index = clampi(page_index, 0, maxi(page_count - 1, 0))
	var start_index := page_index * PAGE_SIZE
	var end_index := mini(start_index + PAGE_SIZE, current_results.size())

	for result_index in range(start_index, end_index):
		var entry := current_results[result_index]
		var item := item_scene.instantiate() as CardCollectionItemScript
		if item == null:
			continue
		card_grid.add_child(item)
		item.setup(entry)
		item.set_entry_selected(entry == selected_entry)
		item.preview_requested.connect(_preview_card)
		item.preview_ended.connect(_end_preview)
		item.entry_selected.connect(_select_entry)
		current_page_entries.append(entry)

	var has_results := not current_results.is_empty()
	card_grid_scroll.visible = has_results
	empty_state.visible = not has_results
	previous_page_button.disabled = page_index <= 0
	next_page_button.disabled = page_index >= page_count - 1
	page_label.text = "第 %d / %d 页" % [page_index + 1, maxi(page_count, 1)]
	card_grid_scroll.scroll_vertical = 0
	_refresh_grid_columns()


func _release_previous_page_textures() -> void:
	for entry in current_page_entries:
		if entry == null or entry.card_data == null:
			continue
		if entry == selected_entry or entry == preview_entry:
			continue
		entry.card_data.release_front_texture_cache()


func _refresh_grid_columns() -> void:
	if card_grid == null or card_grid_scroll == null:
		return
	var available_width := maxf(card_grid_scroll.size.x - 18.0, CARD_ITEM_WIDTH)
	var columns := int(floor(
		(available_width + GRID_SEPARATION)
		/ (CARD_ITEM_WIDTH + GRID_SEPARATION)
	))
	card_grid.columns = clampi(columns, 1, 6)


func _preview_card(entry: CardCatalogEntryScript) -> void:
	preview_entry = entry
	_show_details(entry)


func _end_preview(entry: CardCatalogEntryScript) -> void:
	if preview_entry != entry:
		return
	preview_entry = null
	_show_details(selected_entry)


func _select_entry(entry: CardCatalogEntryScript) -> void:
	if entry == null:
		return
	var previous_selection := selected_entry
	selected_entry = entry
	preview_entry = null

	for child in card_grid.get_children():
		var item := child as CardCollectionItemScript
		if item != null:
			item.set_entry_selected(item.entry == selected_entry)

	_show_details(selected_entry)
	if (
		previous_selection != null
		and previous_selection != selected_entry
		and not current_page_entries.has(previous_selection)
	):
		previous_selection.card_data.release_front_texture_cache()


func _show_details(entry: CardCatalogEntryScript) -> void:
	if entry == null or entry.card_data == null:
		_clear_details()
		return

	var data := entry.card_data
	details_texture.texture = data.front_texture
	details_missing_image.visible = details_texture.texture == null
	details_name_label.text = data.display_name
	details_faction_label.text = entry.faction_display_name
	details_meta_label.text = "%d阶  ·  %s" % [data.level, entry.get_type_label()]
	details_category_label.text = entry.get_category_label()
	details_stats_label.text = entry.get_stats_text()
	details_stats_label.visible = details_stats_label.text != ""
	details_description_label.text = data.description if data.description != "" else "暂无卡牌描述。"
	owner_hero_label.visible = entry.owner_hero_display_name != ""
	owner_hero_label.text = "英雄专属：%s" % entry.owner_hero_display_name
	collection_note_label.text = entry.get_collection_note()
	card_id_label.text = "ID  %s" % data.id
	_refresh_keyword_labels(entry)
	_style_details_category(entry.category)


func _clear_details() -> void:
	details_texture.texture = null
	details_missing_image.show()
	details_name_label.text = "未选择卡牌"
	details_faction_label.text = ""
	details_meta_label.text = ""
	details_category_label.text = ""
	details_stats_label.text = ""
	details_stats_label.hide()
	details_description_label.text = ""
	owner_hero_label.hide()
	collection_note_label.text = ""
	card_id_label.text = ""
	_refresh_keyword_labels(null)


func _refresh_keyword_labels(entry: CardCatalogEntryScript) -> void:
	for child in keyword_flow.get_children():
		child.queue_free()

	var labels: Array[String] = []
	if entry != null:
		labels = entry.get_keyword_labels()
	keyword_title_label.visible = not labels.is_empty()
	keyword_flow.visible = not labels.is_empty()

	for keyword_text in labels:
		var label := Label.new()
		label.text = keyword_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.87, 0.90, 0.91, 1.0))
		label.add_theme_stylebox_override("normal", _create_tag_style())
		keyword_flow.add_child(label)


func _change_page(offset: int) -> void:
	var next_page := clampi(page_index + offset, 0, maxi(_get_page_count() - 1, 0))
	if next_page == page_index:
		return
	page_index = next_page
	_render_page()


func _get_page_count() -> int:
	if current_results.is_empty():
		return 0
	return int(ceil(float(current_results.size()) / float(PAGE_SIZE)))


func _get_selected_metadata(option_button: OptionButton, fallback: Variant) -> Variant:
	if option_button.selected < 0:
		return fallback
	var metadata: Variant = option_button.get_item_metadata(option_button.selected)
	return metadata if metadata != null else fallback


func _on_search_text_changed(_new_text: String) -> void:
	search_debounce.start()


func _reset_filters() -> void:
	search_input.clear()
	search_debounce.stop()
	type_option.select(0)
	category_option.select(0)
	level_option.select(0)
	sort_option.select(0)
	selected_faction_id = ""
	_set_faction_button_pressed("")
	_apply_filters(true)


func _update_filter_state() -> void:
	var faction_name := "全部种族"
	if selected_faction_id != "":
		faction_name = card_database.get_faction_display_name(selected_faction_id)
	result_summary_label.text = "%s  ·  %d 张" % [faction_name, current_results.size()]
	collection_count_label.text = "收录 %d 张卡牌" % catalog.get_total_count()
	reset_button.disabled = (
		selected_faction_id == ""
		and search_input.text.is_empty()
		and type_option.selected == 0
		and category_option.selected == 0
		and level_option.selected == 0
		and sort_option.selected == 0
	)


func _show_load_failure() -> void:
	current_results.clear()
	card_grid_scroll.hide()
	empty_state.show()
	result_summary_label.text = "卡牌数据加载失败"
	collection_count_label.text = "无法读取图鉴"
	previous_page_button.disabled = true
	next_page_button.disabled = true
	_clear_details()


func _load_faction_logo(faction_id: String) -> Texture2D:
	var faction_cards := card_database.get_faction_cards(faction_id)
	if faction_cards.is_empty():
		faction_cards = card_database.get_faction_token_cards(faction_id)
	if faction_cards.is_empty():
		return null

	var card_data := faction_cards[0]
	var logo_path := "%s/logo.png" % card_data.front_texture_path.get_base_dir()
	if ResourceLoader.exists(logo_path):
		return load(logo_path) as Texture2D
	return null


func _apply_styles() -> void:
	faction_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_sidebar_panel_style(ApplicationUiStyle.GOLD)
	)
	filter_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_inset_panel_style(ApplicationUiStyle.BLUE)
	)
	results_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_drawer_panel_style(Color(0.37, 0.43, 0.44, 1.0))
	)
	details_panel.add_theme_stylebox_override(
		"panel",
		ApplicationUiStyle.create_sidebar_panel_style(ApplicationUiStyle.GOLD)
	)

	ApplicationUiStyle.style_compact_button(back_button, ApplicationUiStyle.GOLD)
	ApplicationUiStyle.style_compact_button(reset_button, ApplicationUiStyle.BLUE)
	ApplicationUiStyle.style_compact_button(previous_page_button, ApplicationUiStyle.BLUE)
	ApplicationUiStyle.style_compact_button(next_page_button, ApplicationUiStyle.BLUE)
	reset_button.custom_minimum_size = Vector2(92.0, 40.0)
	previous_page_button.custom_minimum_size = Vector2(94.0, 38.0)
	next_page_button.custom_minimum_size = Vector2(94.0, 38.0)

	_style_line_edit(search_input)
	for option_button in [type_option, category_option, level_option, sort_option]:
		_style_option_button(option_button)


func _style_faction_button(button: Button) -> void:
	ApplicationUiStyle.style_choice_button(button)


func _style_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_color_override("font_color", ApplicationUiStyle.PRIMARY_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.51, 0.50, 0.47, 1.0))
	line_edit.add_theme_font_size_override("font_size", 16)
	line_edit.add_theme_stylebox_override("normal", ApplicationUiStyle.create_field_style(false))
	line_edit.add_theme_stylebox_override("focus", ApplicationUiStyle.create_field_style(true))


func _style_option_button(option_button: OptionButton) -> void:
	option_button.add_theme_color_override("font_color", ApplicationUiStyle.PRIMARY_TEXT)
	option_button.add_theme_color_override("font_hover_color", Color.WHITE)
	option_button.add_theme_font_size_override("font_size", 14)
	option_button.add_theme_stylebox_override("normal", ApplicationUiStyle.create_field_style(false))
	option_button.add_theme_stylebox_override("hover", ApplicationUiStyle.create_field_style(true))
	option_button.add_theme_stylebox_override("pressed", ApplicationUiStyle.create_field_style(true))
	option_button.add_theme_stylebox_override(
		"focus",
		ApplicationUiStyle.create_focus_style(ApplicationUiStyle.BLUE)
	)


func _style_details_category(category: String) -> void:
	var accent := ApplicationUiStyle.BLUE
	match category:
		CardCatalogEntryScript.CATEGORY_TOKEN:
			accent = Color(0.62, 0.44, 0.80, 1.0)
		CardCatalogEntryScript.CATEGORY_STARTING_HAND:
			accent = ApplicationUiStyle.GOLD
		CardCatalogEntryScript.CATEGORY_SYSTEM:
			accent = Color(0.42, 0.72, 0.61, 1.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	details_category_label.add_theme_stylebox_override("normal", style)


func _create_tag_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.31, 0.34, 0.52)
	style.border_color = Color(0.40, 0.63, 0.69, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
