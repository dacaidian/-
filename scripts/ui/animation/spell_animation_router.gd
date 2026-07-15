extends RefCounted
class_name SpellAnimationRouter

# 按表现上下文注册 animation key。路由只选择处理器，不创建节点，也不读取规则状态。

var _targeted_handlers: Dictionary = {}
var _rect_handlers: Dictionary = {}
var _source_rect_handlers: Dictionary = {}
var _board_handlers: Dictionary = {}


func register_targeted(animation_keys: Array[String], handler: Callable) -> void:
	_register(_targeted_handlers, animation_keys, handler)


func register_at_rect(animation_keys: Array[String], handler: Callable) -> void:
	_register(_rect_handlers, animation_keys, handler)


func register_from_rect(animation_keys: Array[String], handler: Callable) -> void:
	_register(_source_rect_handlers, animation_keys, handler)


func register_board(animation_keys: Array[String], handler: Callable) -> void:
	_register(_board_handlers, animation_keys, handler)


func try_play_targeted(
	animation_key: String,
	owner: Node,
	effect_root: Control,
	caster_card: Card,
	target_card: Card
) -> bool:
	var handler := _get_handler(_targeted_handlers, animation_key)
	if not handler.is_valid():
		return false

	await handler.call(owner, effect_root, caster_card, target_card, animation_key)
	return true


func try_play_at_rect(
	animation_key: String,
	owner: Node,
	effect_root: Control,
	target_rect: Rect2
) -> bool:
	var handler := _get_handler(_rect_handlers, animation_key)
	if not handler.is_valid():
		return false

	await handler.call(owner, effect_root, target_rect, animation_key)
	return true


func try_play_from_rect(
	animation_key: String,
	owner: Node,
	effect_root: Control,
	source_rect: Rect2,
	target_card: Card
) -> bool:
	var handler := _get_handler(_source_rect_handlers, animation_key)
	if not handler.is_valid():
		return false

	await handler.call(owner, effect_root, source_rect, target_card, animation_key)
	return true


func try_play_board(animation_key: String, owner: Node, effect_root: Control) -> bool:
	var handler := _get_handler(_board_handlers, animation_key)
	if not handler.is_valid():
		return false

	await handler.call(owner, effect_root, animation_key)
	return true


func _register(routes: Dictionary, animation_keys: Array[String], handler: Callable) -> void:
	if not handler.is_valid():
		return
	for animation_key in animation_keys:
		if animation_key != "":
			routes[animation_key] = handler


func _get_handler(routes: Dictionary, animation_key: String) -> Callable:
	var value: Variant = routes.get(animation_key)
	if value is Callable:
		return value as Callable
	return Callable()
