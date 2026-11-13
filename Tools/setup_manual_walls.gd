extends SceneTree
## One-time authoring migration. Existing WallTiles and all other children are preserved.
func _initialize() -> void:
	var tiles := load("res://Assets/Tileset/coastal_manual_floor.tres") as TileSet
	var directory := DirAccess.open("res://Scenes/Rooms/Stage/Coastal/Decorations")
	for file in directory.get_files():
		if not file.ends_with(".tscn"):
			continue
		var path := "res://Scenes/Rooms/Stage/Coastal/Decorations/" + file
		var scene := load(path).instantiate() as Node2D
		if scene.has_node("WallTiles"):
			scene.free()
			continue
		var template = scene.get_node("RoomGuide").template
		var walls := TileMapLayer.new()
		walls.name = "WallTiles"
		walls.tile_set = tiles
		walls.scale = Vector2(0.25, 0.25)
		walls.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		walls.collision_enabled = false
		walls.z_as_relative = false
		walls.z_index = -11
		# Fill solid pockets and a 192px belt behind the room boundary.
		# Actual connected passages are cleared on the runtime instance.
		for x in range(-12, int(template.size.x / 16) + 12):
			for y in range(-12, int(template.size.y / 16) + 12):
				var point := Vector2(x * 16 + 8, y * 16 + 8)
				var playable := false
				for rect in template.air_regions:
					if rect.has_point(point):
						playable = true
						break
				if not playable:
					walls.set_cell(Vector2i(x, y), 4, Vector2i.ZERO)
		scene.add_child(walls)
		walls.owner = scene
		scene.move_child(walls, 0)
		var packed := PackedScene.new()
		assert(packed.pack(scene) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		scene.free()
	print("PASS: editable WallTiles created, existing paint and decorations preserved.")
	quit()
