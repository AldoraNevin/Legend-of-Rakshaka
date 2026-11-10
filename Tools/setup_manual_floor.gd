extends SceneTree
func _initialize() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(64, 64)
	var texture = load("res://Assets/Tileset/Environment/tileset pantai.png")
	var regions := [Rect2(204, 37, 64, 64), Rect2(286, 37, 64, 64), Rect2(31, 37, 64, 64), Rect2(453, 37, 64, 64), Rect2(204, 124, 64, 64)]
	var names := ["Tengah A", "Tengah B", "Ujung kiri", "Ujung kanan", "Batu isi"]
	for i in range(regions.size()):
		var crop := AtlasTexture.new()
		crop.atlas = texture
		crop.region = regions[i]
		crop.filter_clip = true
		var source := TileSetAtlasSource.new()
		source.resource_name = names[i]
		source.texture = crop
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i.ZERO)
		tiles.add_source(source, i)
	assert(ResourceSaver.save(tiles, "res://Assets/Tileset/coastal_manual_floor.tres") == OK)
	var directory := DirAccess.open("res://Scenes/Rooms/Stage/Coastal/Decorations")
	for file in directory.get_files():
		if not file.ends_with(".tscn"):
			continue
		var path := "res://Scenes/Rooms/Stage/Coastal/Decorations/" + file
		var scene = load(path).instantiate()
		if scene.has_node("FloorTiles"):
			scene.free()
			continue
		var template = scene.get_node("RoomGuide").template
		var floor_tiles := TileMapLayer.new()
		floor_tiles.name = "FloorTiles"
		floor_tiles.tile_set = tiles
		floor_tiles.scale = Vector2(0.25, 0.25)
		floor_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		floor_tiles.collision_enabled = false
		floor_tiles.position = Vector2(0, template.size.y)
		for x in range(int(template.size.x / 16)):
			floor_tiles.set_cell(Vector2i(x, 0), 0, Vector2i.ZERO)
		scene.add_child(floor_tiles)
		floor_tiles.owner = scene
		var packed := PackedScene.new()
		assert(packed.pack(scene) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		template.manual_floor = true
		assert(ResourceSaver.save(template) == OK)
		scene.free()
	print("Manual floor layers created without replacing existing decoration nodes.")
	quit()
