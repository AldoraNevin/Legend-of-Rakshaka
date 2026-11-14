extends SceneTree
## Change only collision metadata, never room cells or atlas artwork.
func _initialize() -> void:
	var path := "res://Assets/Tileset/pantai_modular_solid.tres"
	var tiles: TileSet = load(path)
	var atlas := tiles.get_source(0) as TileSetAtlasSource
	var pixels := atlas.texture.get_image()
	for x in range(8):
		var cell := Vector2i(x, 4)
		var points := PackedVector2Array([Vector2(-32, 32), Vector2(32, 32)])
		for sample_x in range(0, 65, 8):
			var top := 63
			for y in range(64):
				if pixels.get_pixel(x * 64 + mini(sample_x, 63), 256 + y).a > 0.5:
					top = y
					break
			points.append(Vector2(sample_x - 32, top - 32))
		var polygon := Geometry2D.convex_hull(points)
		if polygon[0] == polygon[polygon.size() - 1]:
			polygon.resize(polygon.size() - 1)
		for i in range(atlas.get_alternative_tiles_count(cell)):
			var data := atlas.get_tile_data(cell, atlas.get_alternative_tile_id(cell, i))
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, polygon)
	assert(ResourceSaver.save(tiles, path) == OK)
	print("Coastal slope collision updated for atlas row 4, columns 0..7 (including flip variants).")
	quit()
