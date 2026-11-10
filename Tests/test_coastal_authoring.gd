extends SceneTree
func _initialize() -> void:
	var style = load("res://Assets/Tileset/coastal_style.tres")
	var atlas := style.tileset.get_source(0) as TileSetAtlasSource
	assert(atlas.texture.get_size() == Vector2(128, 64))
	assert(atlas.texture_region_size == Vector2i(16, 16))
	assert(atlas.get_tiles_count() == 32)
	assert(style.tileset.get_physics_layers_count() == 0)
	var practice = load("res://Scenes/Rooms/Stage/Coastal/Templates/coastal_practice.tres")
	assert(practice.validate().is_empty(), str(practice.validate()))
	var broken = practice.duplicate(true)
	broken.extra_platforms.append(Rect2(208, 224, 96, 8))
	assert(not broken.validate().is_empty(), "Must reject a platform blocking the center shaft")
	broken = practice.duplicate(true)
	broken.extra_platforms.append(Rect2(32, 288, 80, 8))
	assert(not broken.validate().is_empty(), "Must protect the spawn/reward floor band")
	print("PASS: editable PNG atlas, visual-only tileset, manual practice platforms and authoring guards.")
	quit()
