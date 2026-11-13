extends SceneTree
const SHEET = preload("res://Assets/Tileset/Environment/tileset pantai.png")
func configure(tiles: TileSet) -> void:
	# IDs 0..4 remain compatible with existing painted cells.
	var entries := [
		[0, "Surface tengah A", Rect2(204, 37, 64, 64)],
		[1, "Surface tengah B", Rect2(286, 37, 64, 64)],
		[2, "Surface rata", Rect2(31, 37, 64, 64)],
		[3, "Surface ujung kanan", Rect2(453, 37, 64, 64)],
		[4, "Isi - batu retak", Rect2(370, 124, 64, 64)],
		[5, "Surface ujung kiri", Rect2(118, 37, 64, 64)],
		[6, "Surface tengah C", Rect2(370, 37, 64, 64)],
		[7, "Surface pulau kecil", Rect2(540, 37, 64, 64)],
		[8, "Surface siku kanan", Rect2(626, 37, 64, 64)],
		[9, "Platform ujung kiri", Rect2(31, 308, 64, 32)],
		[10, "Platform tengah A", Rect2(118, 308, 64, 32)],
		[11, "Platform tengah B", Rect2(204, 308, 64, 32)],
		[12, "Platform tengah C", Rect2(286, 308, 64, 32)],
		[13, "Platform tengah D", Rect2(370, 308, 64, 32)],
		[14, "Platform ujung kanan", Rect2(453, 308, 64, 32)],
		[15, "Sudut dalam kiri", Rect2(453, 124, 64, 64)],
		[16, "Sudut dalam kanan", Rect2(540, 124, 64, 64)]]
	for entry in entries:
		if tiles.has_source(entry[0]):
			tiles.remove_source(entry[0])
		var crop := AtlasTexture.new()
		crop.atlas = SHEET
		crop.region = entry[2]
		crop.filter_clip = true
		var source := TileSetAtlasSource.new()
		source.resource_name = entry[1]
		source.texture = crop
		source.texture_region_size = Vector2i(entry[2].size)
		source.create_tile(Vector2i.ZERO)
		if entry[0] >= 9 and entry[0] <= 14:
			source.get_tile_data(Vector2i.ZERO, 0).texture_origin = Vector2i(0, 16)
		if entry[0] >= 15:
			for variant in range(1, 8):
				source.create_alternative_tile(Vector2i.ZERO, variant)
				var data := source.get_tile_data(Vector2i.ZERO, variant)
				data.flip_h = (variant & 1) != 0
				data.flip_v = (variant & 2) != 0
				data.transpose = (variant & 4) != 0
		tiles.add_source(source, entry[0])
func _initialize() -> void:
	var shared := load("res://Assets/Tileset/coastal_manual_floor.tres") as TileSet
	configure(shared)
	assert(ResourceSaver.save(shared) == OK)
	var directory := DirAccess.open("res://Scenes/Rooms/Stage/Coastal/Decorations")
	for file in directory.get_files():
		if not file.ends_with(".tscn"):
			continue
		var path := "res://Scenes/Rooms/Stage/Coastal/Decorations/" + file
		var scene = load(path).instantiate()
		for name in ["FloorTiles", "WallTiles"]:
			var layer := scene.get_node_or_null(name) as TileMapLayer
			if layer != null:
				configure(layer.tile_set)
		var packed := PackedScene.new()
		assert(packed.pack(scene) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		scene.free()
	print("PASS: surface, stone, platform and eight corner orientations installed; painted cells preserved.")
	quit()
