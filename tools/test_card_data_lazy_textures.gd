extends SceneTree


func _init() -> void:
	var card_data := CardData.from_dictionary(
		{
			"id": "lazy_texture_test",
			"name": "Lazy Texture Test",
			"type": "minion"
		},
		{"id": "test_faction", "displayName": "Test Faction"}
	)
	card_data.front_texture_path = "res://icon.svg"
	card_data.table_texture_path = "res://icon.svg"
	card_data.back_texture_path = "res://icon.svg"

	assert(card_data._front_texture == null)
	assert(card_data._table_texture == null)
	assert(card_data._back_texture == null)
	assert(card_data.front_texture != null)
	assert(card_data._front_texture != null)
	assert(card_data.table_texture != null)
	assert(card_data._table_texture != null)
	assert(card_data.back_texture != null)
	assert(card_data._back_texture != null)
	print("CARD_DATA_LAZY_TEXTURES_TEST_OK")
	quit()
