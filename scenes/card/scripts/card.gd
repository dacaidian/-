extends Control
class_name Card

const CardStatusOverlayScript := preload("res://scripts/ui/card_status_overlay.gd")
const VALUE_ICON_SIZE := Vector2(40, 40)

# 玩家点击卡牌时发出的信号。
# Card 不直接修改游戏状态，而是把操作交给 GameManager。
signal clicked(card: Card)

# 鼠标进入/离开卡牌区域时发出的信号，携带 Card 引用方便外部连接。
signal mouse_entered_card(card: Card)
signal mouse_exited_card(card: Card)

# 卡牌正反面状态变化时发出的信号。它来自 CardState 的变化。
# 其他功能组件，例如悬浮预览，可以监听这个信号。
signal face_changed(is_face_up: bool)

# 卡牌正面和背面图片，可以在 Inspector 面板里拖拽设置。
@export var front_texture: Texture2D
@export var back_texture: Texture2D

# 卡牌在 UI 中的固定尺寸，TextureRect 会铺满这个区域。
@export var card_size := Vector2(180, 252)
@export var allows_empty_clicks := true

# 血量数字图片所在目录。文件名按当前生命值命名，例如 7.png。
@export var health_number_dir := "res://assets/img/血量数字"

# 护盾数字图片所在目录。文件名按当前护盾值命名，例如 6.png。
@export var shield_number_dir := "res://assets/img/护盾数字"

@export var poison_number_dir := "res://assets/img/毒性数字"
@export var fire_number_dir := "res://assets/img/火焰数字"
@export var armor_number_dir := "res://assets/img/护甲数字"
@export var status_number_icon_gap := 2

# 攻击数字图片所在子目录。实际路径会从卡牌正面图所属种族目录推导。
@export var attack_number_folder_name := "攻击数字"

# 翻牌动画总时长。动画前半段收窄，后半段展开。
@export var flip_duration := 0.32

# 交互状态的临时视觉反馈。后续可以替换为描边、浮层或操作菜单。
@export var selected_backlight_color := Color(1.0, 0.82, 0.22, 0.72)
@export var selected_backlight_size := 26
@export var selected_backlight_margin := 14
@export var current_player_backlight_color := Color(0.24, 1.0, 0.48, 0.58)
@export var current_player_backlight_size := 22
@export var current_player_backlight_margin := 12
@export var valid_target_backlight_color := Color(1.0, 1.0, 1.0, 0.70)
@export var valid_target_backlight_size := 24
@export var valid_target_backlight_margin := 12
@export var area_preview_color := Color(0.26, 0.58, 1.0, 0.52)
@export var area_preview_edge_color := Color(0.52, 0.85, 1.0, 0.88)
@export var beast_path_color := Color(0.34, 0.19, 0.06, 0.34)
@export var beast_path_edge_color := Color(0.74, 0.48, 0.18, 0.70)
@export var beast_path_glow_color := Color(0.22, 0.52, 0.10, 0.28)
@export var divine_shield_color := Color(1.0, 0.84, 0.24, 0.26)
@export var divine_shield_edge_color := Color(1.0, 0.92, 0.48, 0.82)
@export var divine_shield_glow_color := Color(1.0, 0.78, 0.18, 0.34)

# 等当前节点和子节点都准备好之后，再获取子节点引用。
@onready var texture_rect: TextureRect = $TextureRect
@onready var health_texture: TextureRect = get_node_or_null("HealthTexture") as TextureRect

# 这张卡牌绑定的运行时状态。翻开状态等数据只从这里读取。
var state: CardState
var shield_texture: TextureRect
var poison_texture: TextureRect
var fire_texture: TextureRect
var armor_texture: TextureRect
var armor_label: Label
var attack_texture: TextureRect
var status_overlay: CardStatusOverlay

# 当前是否正在播放翻牌动画，播放期间忽略新的点击。
var is_animating := false
var flip_tween: Tween
var is_content_temporarily_hidden := false

# 兼容其他组件读取 card.is_face_up，但它只是 CardState 的只读映射。
var is_face_up: bool:
	get:
		return state != null and state.is_face_up

func _ready() -> void:
	# 如果没有单独设置背面图，就把 TextureRect 的默认图片当作背面图。
	if back_texture == null:
		back_texture = texture_rect.texture

	# 设置卡牌控件尺寸，让编辑器预览和运行时保持一致。
	apply_card_size(card_size)

	# 根据初始状态刷新一次卡牌图片。
	setup_status_overlay()
	setup_health_texture()
	setup_shield_texture()
	setup_poison_texture()
	setup_fire_texture()
	setup_armor_texture()
	setup_attack_texture()
	update_card_texture()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	mouse_entered_card.emit(self)


func _on_mouse_exited() -> void:
	mouse_exited_card.emit(self)


func _gui_input(event: InputEvent) -> void:
	# Control 节点专用的输入回调。只有点击到这张卡牌区域时才会触发。
	if is_animating:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(self)
			# 标记这次点击已经被卡牌处理，避免继续传给其他 UI 节点。
			accept_event()


func bind_state(new_state: CardState) -> void:
	# 重新绑定状态时，先断开旧状态信号，避免重复刷新。
	if state != null and state.state_changed.is_connected(_on_state_changed):
		state.state_changed.disconnect(_on_state_changed)

	state = new_state

	# Card 只监听状态变化并刷新显示，不主动修改状态。
	if state != null:
		state.state_changed.connect(_on_state_changed)

	update_card_texture()


func _on_state_changed(changed_state: CardState) -> void:
	# CardState 是唯一数据源；状态变化后 Card 只负责把画面同步过去。
	update_card_texture()
	update_interaction_visual()
	face_changed.emit(changed_state.is_face_up)


func play_flip_animation(apply_state_change: Callable) -> void:
	# 翻牌动画只负责表现：先收窄，半程执行外部传入的状态修改，再展开。
	# 这样真正的 CardState 修改仍然由 GameManager 决定。
	if is_animating:
		return

	refresh_flip_pivot()
	is_animating = true

	if flip_tween != null:
		flip_tween.kill()

	var original_scale := scale
	var hidden_scale := Vector2(0.0, original_scale.y)
	var half_duration := flip_duration * 0.5

	flip_tween = create_tween()
	flip_tween.set_trans(Tween.TRANS_SINE)
	flip_tween.set_ease(Tween.EASE_IN)
	flip_tween.tween_property(self, "scale", hidden_scale, half_duration)
	await flip_tween.finished

	if apply_state_change.is_valid():
		apply_state_change.call()

	flip_tween = create_tween()
	flip_tween.set_trans(Tween.TRANS_SINE)
	flip_tween.set_ease(Tween.EASE_OUT)
	flip_tween.tween_property(self, "scale", original_scale, half_duration)
	await flip_tween.finished

	scale = original_scale
	flip_tween = null
	is_animating = false


func apply_card_size(new_card_size: Vector2) -> void:
	if new_card_size.x <= 0.0 or new_card_size.y <= 0.0:
		return

	card_size = new_card_size
	custom_minimum_size = new_card_size
	size = new_card_size
	refresh_flip_pivot()


func refresh_flip_pivot() -> void:
	var pivot_size := size
	if pivot_size.x <= 0.0 or pivot_size.y <= 0.0:
		pivot_size = card_size

	pivot_offset = pivot_size * 0.5


func update_card_texture() -> void:
	if is_content_temporarily_hidden:
		texture_rect.hide()
		hide_value_textures()
		update_status_overlay()
		queue_redraw()
		return

	texture_rect.show()

	# 空格子不显示卡背，保留 Control 区域供后续放置、召唤等逻辑使用。
	if state != null and state.is_empty():
		mouse_filter = Control.MOUSE_FILTER_STOP if allows_empty_clicks else Control.MOUSE_FILTER_IGNORE
		texture_rect.texture = null
		health_texture.hide()
		update_status_number_textures()
		update_attack_texture()
		update_status_overlay()
		update_interaction_visual()
		return

	mouse_filter = Control.MOUSE_FILTER_STOP

	# 棋盘正面优先显示 table 图；手牌、预览等仍使用原始卡图。
	if is_face_up and get_board_front_texture() != null:
		texture_rect.texture = get_board_front_texture()
	else:
		texture_rect.texture = get_back_texture()

	update_health_texture()
	update_status_number_textures()
	update_attack_texture()
	update_status_overlay()
	update_interaction_visual()


func set_content_temporarily_hidden(should_hide_content: bool) -> void:
	is_content_temporarily_hidden = should_hide_content
	update_card_texture()
	update_interaction_visual()


func get_front_texture() -> Texture2D:
	# 优先使用 CardState 中来自 JSON 的图片；没有状态时才用模板默认图。
	if state != null and state.front_texture != null:
		return state.front_texture

	return front_texture


func get_board_front_texture() -> Texture2D:
	if state != null and state.table_texture != null:
		return state.table_texture

	return get_front_texture()


func get_back_texture() -> Texture2D:
	# 背面图同样优先由运行时状态提供。
	if state != null and state.back_texture != null:
		return state.back_texture

	return back_texture


func update_health_texture() -> void:
	if health_texture == null:
		return

	# 只有翻开的棋盘单位才展示右下角血量。
	if not should_show_health():
		health_texture.hide()
		return

	var health_texture_path := "%s/%d.png" % [health_number_dir, state.current_health]
	set_value_texture(health_texture, health_texture_path, "血量")


func should_show_health() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit()


func setup_health_texture() -> void:
	if health_texture == null:
		health_texture = TextureRect.new()
		health_texture.name = "HealthTexture"
		health_texture.visible = false
		add_child(health_texture)

	configure_value_texture(health_texture)
	position_health_texture()


func setup_shield_texture() -> void:
	if shield_texture != null:
		return

	shield_texture = create_value_texture("ShieldTexture")


func setup_poison_texture() -> void:
	if poison_texture != null:
		return

	poison_texture = create_value_texture("PoisonTexture")


func setup_fire_texture() -> void:
	if fire_texture != null:
		return

	fire_texture = create_value_texture("FireTexture")


func setup_armor_texture() -> void:
	if armor_texture != null:
		return

	armor_texture = create_value_texture("ArmorTexture")
	armor_label = Label.new()
	armor_label.name = "ArmorLabel"
	armor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	armor_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	armor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	armor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	armor_label.add_theme_font_size_override("font_size", 20)
	armor_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	armor_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.08, 0.95))
	armor_label.add_theme_constant_override("shadow_offset_x", 1)
	armor_label.add_theme_constant_override("shadow_offset_y", 1)
	armor_texture.add_child(armor_label)


func setup_attack_texture() -> void:
	if attack_texture != null:
		return

	attack_texture = create_value_texture("AttackTexture")
	attack_texture.anchor_left = 0.0
	attack_texture.anchor_right = 0.0
	attack_texture.offset_left = 0.0
	attack_texture.offset_top = -VALUE_ICON_SIZE.y
	attack_texture.offset_right = VALUE_ICON_SIZE.x
	attack_texture.offset_bottom = 0.0


func setup_status_overlay() -> void:
	if status_overlay != null:
		return

	status_overlay = CardStatusOverlayScript.new() as CardStatusOverlay
	status_overlay.name = "StatusOverlay"
	status_overlay.anchor_left = 0.0
	status_overlay.anchor_top = 0.0
	status_overlay.anchor_right = 1.0
	status_overlay.anchor_bottom = 1.0
	status_overlay.offset_left = 0.0
	status_overlay.offset_top = 0.0
	status_overlay.offset_right = 0.0
	status_overlay.offset_bottom = 0.0
	status_overlay.beast_path_color = beast_path_color
	status_overlay.beast_path_edge_color = beast_path_edge_color
	status_overlay.beast_path_glow_color = beast_path_glow_color
	status_overlay.divine_shield_color = divine_shield_color
	status_overlay.divine_shield_edge_color = divine_shield_edge_color
	status_overlay.divine_shield_glow_color = divine_shield_glow_color
	status_overlay.visible = false
	add_child(status_overlay)
	move_child(status_overlay, texture_rect.get_index() + 1)


func update_status_overlay() -> void:
	if status_overlay == null:
		return

	status_overlay.set_state(null if is_content_temporarily_hidden else state)


func update_status_number_textures() -> void:
	var stack_index := 0
	stack_index = update_shield_texture(stack_index)
	stack_index = update_poison_texture(stack_index)
	stack_index = update_fire_texture(stack_index)
	update_armor_texture(stack_index)


func update_shield_texture(stack_index: int) -> int:
	if shield_texture == null:
		return stack_index

	if not should_show_shield():
		shield_texture.hide()
		return stack_index

	var shield_texture_path := "%s/%d.png" % [shield_number_dir, state.shield]
	if set_value_texture(shield_texture, shield_texture_path, "护盾"):
		position_status_number_texture(shield_texture, stack_index)
		return stack_index + 1

	return stack_index


func should_show_shield() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.shield > 0


func update_poison_texture(stack_index: int) -> int:
	if poison_texture == null:
		return stack_index

	if not should_show_poison_number():
		poison_texture.hide()
		return stack_index

	var poison_total_damage := get_poison_total_damage()
	var poison_texture_path := "%s/%d.png" % [poison_number_dir, poison_total_damage]
	if set_value_texture(poison_texture, poison_texture_path, "毒性"):
		position_status_number_texture(poison_texture, stack_index)
		return stack_index + 1

	return stack_index


func should_show_poison_number() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and get_poison_total_damage() > 0


func update_fire_texture(stack_index: int) -> int:
	if fire_texture == null:
		return stack_index

	if not should_show_fire_number():
		fire_texture.hide()
		return stack_index

	var fire_total_damage := get_fire_total_damage()
	var fire_texture_path := "%s/%d.png" % [fire_number_dir, fire_total_damage]
	if set_value_texture(fire_texture, fire_texture_path, "火焰"):
		position_status_number_texture(fire_texture, stack_index)
		return stack_index + 1

	return stack_index


func should_show_fire_number() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and get_fire_total_damage() > 0


func update_armor_texture(stack_index: int) -> int:
	if armor_texture == null:
		return stack_index

	if not should_show_armor():
		armor_texture.hide()
		return stack_index

	var armor_texture_path := "%s/%d.png" % [armor_number_dir, state.armor]
	var should_show_label := false
	if not ResourceLoader.exists(armor_texture_path):
		armor_texture_path = "%s/0.png" % armor_number_dir
		should_show_label = true

	if set_value_texture(armor_texture, armor_texture_path, "护甲"):
		update_armor_label(should_show_label)
		position_status_number_texture(armor_texture, stack_index)
		return stack_index + 1

	return stack_index


func should_show_armor() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.armor > 0


func update_armor_label(should_show_label: bool) -> void:
	if armor_label == null:
		return

	armor_label.visible = should_show_label
	armor_label.text = str(state.armor) if should_show_label and state != null else ""


func get_poison_total_damage() -> int:
	if state == null:
		return 0

	var poison_status := state.get_status(CardStatus.STATUS_POISON)
	var poison_damage := 0
	if poison_status != null:
		poison_damage = poison_status.get_poison_total_remaining_damage()

	var stored_venom_status := state.get_status(CardStatus.STATUS_STORED_VENOM)
	var stored_venom_damage := 0
	if stored_venom_status != null:
		stored_venom_damage = stored_venom_status.get_stored_venom_damage()

	return poison_damage + stored_venom_damage


func get_fire_total_damage() -> int:
	if state == null:
		return 0

	var fire_status := state.get_status(CardStatus.STATUS_FIRE)
	if fire_status == null:
		return 0

	return fire_status.get_fire_total_remaining_damage()


func position_status_number_texture(value_texture: TextureRect, stack_index: int) -> void:
	if value_texture == null:
		return

	var vertical_offset := (VALUE_ICON_SIZE.y + float(status_number_icon_gap)) * float(stack_index + 1)
	value_texture.anchor_left = health_texture.anchor_left
	value_texture.anchor_top = health_texture.anchor_top
	value_texture.anchor_right = health_texture.anchor_right
	value_texture.anchor_bottom = health_texture.anchor_bottom
	value_texture.offset_left = health_texture.offset_left
	value_texture.offset_right = health_texture.offset_right
	value_texture.offset_top = health_texture.offset_top - vertical_offset
	value_texture.offset_bottom = health_texture.offset_bottom - vertical_offset


func update_attack_texture() -> void:
	if attack_texture == null:
		return

	if not should_show_attack():
		attack_texture.hide()
		return

	var attack_texture_path := get_attack_texture_path(state.current_attack)
	if attack_texture_path == "":
		attack_texture.hide()
		return

	set_value_texture(attack_texture, attack_texture_path, "攻击")


func should_show_attack() -> bool:
	if state == null or state.data == null:
		return false

	return state.is_face_up and state.is_unit() and state.current_attack > 0


func get_attack_texture_path(attack_value: int) -> String:
	if state == null or state.data == null:
		return ""

	if state.data.front_texture_path == "":
		return ""

	var faction_image_dir := state.data.front_texture_path.get_base_dir()
	return "%s/%s/%d.png" % [faction_image_dir, attack_number_folder_name, attack_value]


func create_value_texture(node_name: String) -> TextureRect:
	if health_texture == null:
		setup_health_texture()

	var value_texture := TextureRect.new()
	value_texture.name = node_name
	value_texture.visible = false
	configure_value_texture(value_texture)
	add_child(value_texture)
	return value_texture


func configure_value_texture(value_texture: TextureRect) -> void:
	value_texture.custom_minimum_size = VALUE_ICON_SIZE
	value_texture.size = VALUE_ICON_SIZE
	value_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	value_texture.stretch_mode = TextureRect.STRETCH_SCALE
	value_texture.anchor_left = 1.0
	value_texture.anchor_top = 1.0
	value_texture.anchor_right = 1.0
	value_texture.anchor_bottom = 1.0


func position_health_texture() -> void:
	health_texture.anchor_left = 1.0
	health_texture.anchor_top = 1.0
	health_texture.anchor_right = 1.0
	health_texture.anchor_bottom = 1.0
	health_texture.offset_left = -VALUE_ICON_SIZE.x
	health_texture.offset_top = -VALUE_ICON_SIZE.y
	health_texture.offset_right = 0.0
	health_texture.offset_bottom = 0.0


func set_value_texture(value_texture: TextureRect, texture_path: String, label: String) -> bool:
	if value_texture == null:
		return false

	if not ResourceLoader.exists(texture_path):
		push_warning("找不到%s数字图片: %s" % [label, texture_path])
		value_texture.hide()
		return false

	value_texture.texture = load(texture_path) as Texture2D
	value_texture.show()
	return true


func hide_value_textures() -> void:
	if health_texture != null:
		health_texture.hide()
	if shield_texture != null:
		shield_texture.hide()
	if poison_texture != null:
		poison_texture.hide()
	if fire_texture != null:
		fire_texture.hide()
	if armor_texture != null:
		armor_texture.hide()
	if attack_texture != null:
		attack_texture.hide()


func update_interaction_visual() -> void:
	if state == null:
		self_modulate = Color.WHITE
		queue_redraw()
		return

	if state.is_selected:
		self_modulate = Color.WHITE
	elif state.is_valid_target:
		self_modulate = Color.WHITE
	else:
		self_modulate = Color.WHITE

	queue_redraw()


func _draw() -> void:
	if is_content_temporarily_hidden:
		return

	if state == null:
		return

	# 焦点态优先显示金色背光；此时不显示当前回合的绿色可操纵提示。
	if state.is_area_preview:
		draw_area_preview()

	if state.is_selected:
		draw_backlight(selected_backlight_color, selected_backlight_size, selected_backlight_margin)
		return

	if state.is_valid_target:
		draw_backlight(valid_target_backlight_color, valid_target_backlight_size, valid_target_backlight_margin)
		return

	if state.is_action_available_hint:
		draw_backlight(current_player_backlight_color, current_player_backlight_size, current_player_backlight_margin)


func draw_backlight(backlight_color: Color, backlight_size: int, backlight_margin: int) -> void:
	# 多层低透明度外扩矩形模拟柔和背光，避免变成硬边框。
	var card_rect := Rect2(Vector2.ZERO, size)
	var glow_steps := 14
	var max_grow := float(maxi(backlight_size, backlight_margin))

	for step in range(glow_steps, 0, -1):
		var grow_amount := max_grow * float(step) / float(glow_steps)
		var distance_factor := float(step) / float(glow_steps)
		var alpha := backlight_color.a * pow(1.0 - distance_factor, 1.7) * 0.26
		var glow_color := Color(
			backlight_color.r,
			backlight_color.g,
			backlight_color.b,
			alpha
		)
		draw_rect(card_rect.grow(grow_amount), glow_color, true)

	var inner_glow_color := Color(
		backlight_color.r,
		backlight_color.g,
		backlight_color.b,
		backlight_color.a * 0.10
	)
	draw_rect(card_rect.grow(float(backlight_margin) * 0.35), inner_glow_color, true)


func draw_area_preview() -> void:
	var card_rect := Rect2(Vector2.ZERO, size)
	draw_rect(card_rect, area_preview_color, true)
	draw_rect(card_rect, area_preview_edge_color, false, 4)
