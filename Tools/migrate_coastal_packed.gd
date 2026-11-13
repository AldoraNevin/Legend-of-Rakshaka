extends SceneTree
const MAPPING = [Vector2i(2,0),Vector2i(3,0),Vector2i(0,0),Vector2i(5,0),Vector2i(4,1),Vector2i(1,0),Vector2i(4,0),Vector2i(6,0),Vector2i(7,0),Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(5,1),Vector2i(6,1)]
func _initialize() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(64,64)
	var atlas := TileSetAtlasSource.new()
	atlas.resource_name = "Pantai - atlas 64px"
	atlas.texture = load("res://Assets/Tileset/Sprites/coastal_packed.png")
	atlas.texture_region_size = Vector2i(64,64)
	for y in range(6):
		for x in range(8):
			var cell := Vector2i(x,y)
			atlas.create_tile(cell)
			for variant in range(1,8):
				atlas.create_alternative_tile(cell,variant)
				var data := atlas.get_tile_data(cell,variant)
				data.flip_h = (variant & 1) != 0
				data.flip_v = (variant & 2) != 0
				data.transpose = (variant & 4) != 0
	tiles.add_source(atlas,100)
	assert(ResourceSaver.save(tiles,"res://Assets/Tileset/coastal_packed.tres") == OK)
	tiles.take_over_path("res://Assets/Tileset/coastal_packed.tres")
	var directory := DirAccess.open("res://Scenes/Rooms/Stage/Coastal/Decorations")
	var total := 0
	for file in directory.get_files():
		if not file.ends_with(".tscn"):
			continue
		var path := "res://Scenes/Rooms/Stage/Coastal/Decorations/" + file
		var scene = load(path).instantiate()
		for name in ["FloorTiles","WallTiles"]:
			var layer := scene.get_node_or_null(name) as TileMapLayer
			if layer == null or layer.tile_set == null:
				continue
			if layer.tile_set.resource_path == tiles.resource_path:
				continue
			var old := layer.tile_set
			var replacement := tiles.duplicate() as TileSet
			# Preserve any custom atlas sources outside the known legacy palette.
			for i in range(old.get_source_count()):
				var id := old.get_source_id(i)
				if id >= 17:
					assert(id != 100, "Source 100 already in use; stop migration")
					replacement.add_source(old.get_source(id),id)
			var cells := layer.get_used_cells()
			var saved := []
			for cell in cells:
				saved.append([cell,layer.get_cell_source_id(cell),layer.get_cell_atlas_coords(cell),layer.get_cell_alternative_tile(cell)])
			layer.tile_set = replacement
			for entry in saved:
				if entry[1] >= 0 and entry[1] < 17:
					layer.set_cell(entry[0],100,MAPPING[entry[1]],entry[3])
				else:
					layer.set_cell(entry[0],entry[1],entry[2],entry[3])
			assert(layer.get_used_cells().size() == cells.size())
			total += cells.size()
		var packed := PackedScene.new()
		assert(packed.pack(scene) == OK)
		assert(ResourceSaver.save(packed,path) == OK)
		scene.free()
	print("PASS: 48 atlas cells, 8 orientations each; migrated %d painted cells without changing placement." % total)
	quit()
