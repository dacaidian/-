extends SceneTree

const CardTexturePreviewControllerScript := preload("res://scripts/ui/card_texture_preview_controller.gd")


func _init() -> void:
	call_deferred("run_test")


func run_test() -> void:
	var host := Control.new()
	root.add_child(host)
	var source := Control.new()
	source.position = Vector2(760, 20)
	source.size = Vector2(40, 60)
	host.add_child(source)

	var card_data := CardData.new()
	card_data.front_texture = GradientTexture2D.new()
	var controller := CardTexturePreviewControllerScript.new()
	controller.setup(host)
	await process_frame
	controller.bind_card(source, card_data)
	source.mouse_entered.emit()
	assert(controller.preview_rect != null)
	assert(controller.preview_rect.visible)
	assert(controller.preview_rect.texture == card_data.front_texture)
	assert(controller.preview_rect.global_position.x >= controller.VIEWPORT_MARGIN)

	source.mouse_exited.emit()
	assert(not controller.preview_rect.visible)
	print("CARD_TEXTURE_PREVIEW_TEST_OK")
	quit()
