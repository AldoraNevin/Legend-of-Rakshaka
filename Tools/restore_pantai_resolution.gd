extends SceneTree
func _initialize() -> void:
	var original: TileSet = load("res://Assets/Tileset/coastal_packed.tres")
	for one_way in [false, true]:
		var tiles := TileSet.new()
		tiles.tile_size = Vector2i(64, 64)
		tiles.add_physics_layer()
		tiles.set_physics_layer_collision_layer(0, 2)
		tiles.set_physics_layer_collision_mask(0, 0)
		var atlas := original.get_source(100).duplicate(true) as TileSetAtlasSource
		tiles.add_source(atlas, 0)
		for index in range(atlas.get_tiles_count()):
			var cell := atlas.get_tile_id(index)
			for alternative_index in range(atlas.get_alternative_tiles_count(cell)):
				var alternative := atlas.get_alternative_tile_id(cell, alternative_index)
				var data := atlas.get_tile_data(cell, alternative)
				data.set_collision_polygons_count(0, 1)
				data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-32,-32), Vector2(32,-32), Vector2(32,32), Vector2(-32,32)]))
				data.set_collision_polygon_one_way(0, 0, one_way)
				data.set_collision_polygon_one_way_margin(0, 0, 4.0)
		var path := "res://Assets/Tileset/pantai_modular_platforms.tres" if one_way else "res://Assets/Tileset/pantai_modular_solid.tres"
		assert(ResourceSaver.save(tiles, path) == OK)
	var catalog: Resource = load("res://Scenes/Rooms/Modular/default_level_settings.tres")
	for scene: PackedScene in catalog.room_templates:
		var room := scene.instantiate()
		for title in ["Solid", "Platforms", "SocketCaps"]:
			room.get_node(title).scale = Vector2(0.25, 0.25)
		var packed := PackedScene.new()
		packed.pack(room)
		ResourceSaver.save(packed, scene.resource_path)
		room.free()
	print("Original 64px coastal atlas installed; gameplay grid remains 16px.")
	quit()
