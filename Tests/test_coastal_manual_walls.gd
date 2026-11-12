extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	for seed_value in [42, 91, 1000045]:
		assert(room.prepare(seed_value))
		root.add_child(room)
		var blocked = room.rasterize(room.layout.regions)
		blocked.merge(room.rasterize(room.layout.shell))
		var count := 0
		for i in range(room.layout.rooms.size()):
			var data = room.layout.rooms[i]
			var art = room.get_node("ManualDecor_%d" % i).get_child(0)
			var walls = art.get_node("WallTiles")
			assert(not walls.collision_enabled)
			assert(walls.z_index < -10)
			for cell in walls.get_used_cells():
				var point = room.to_local(walls.to_global(walls.map_to_local(cell)))
				assert(not blocked.has(Vector2i(floori(point.x / 16), floori(point.y / 16))), "Wall fill covers a passage or shell")
				count += 1
			var source = load(data.template.decoration_scene).instantiate()
			assert(source.get_node("WallTiles").get_used_cells().size() >= walls.get_used_cells().size())
			source.free()
		assert(count > 1000)
		root.remove_child(room)
	room.free()
	print("PASS: editable wall fill, passage protection and source preservation across 3 seeds.")
	quit()
