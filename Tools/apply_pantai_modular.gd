extends SceneTree
## Migrate the active catalog's terrain palette without changing painted geometry.
func _initialize() -> void:
	var catalog: Resource = load("res://Scenes/Rooms/Modular/default_level_settings.tres")
	var solid_tiles: TileSet = load("res://Assets/Tileset/pantai_modular_solid.tres")
	var platform_tiles: TileSet = load("res://Assets/Tileset/pantai_modular_platforms.tres")
	for scene: PackedScene in catalog.room_templates:
		var room: Node2D = scene.instantiate()
		for layer_name in ["Solid", "SocketCaps", "Platforms"]:
			var layer := room.get_node(layer_name) as TileMapLayer
			var target := platform_tiles if layer_name == "Platforms" else solid_tiles
			if layer.tile_set == target:
				continue
			# Old atlas columns are unrelated to the coastal atlas: explicitly map
			# full stone and mossy tops, avoiding transparent edge/decorative tiles.
			var cells := layer.get_used_cells()
			var tops := {}
			for cell in cells:
				tops[cell] = layer.get_cell_atlas_coords(cell).y == 0
			layer.tile_set = target
			for cell in cells:
				layer.set_cell(cell, 0, Vector2i(2, 0) if layer_name == "Platforms" or tops[cell] else Vector2i(4, 1))
		var errors: PackedStringArray = room.validate()
		assert(errors.is_empty(), str(errors))
		var packed := PackedScene.new()
		assert(packed.pack(room) == OK)
		assert(ResourceSaver.save(packed, scene.resource_path) == OK)
		print("Pantai terrain: ", scene.resource_path)
		room.free()
	quit()
