extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	root.add_child(room)
	for seed_value in [42, 91]:
		assert(room.prepare(seed_value))
		for i in range(room.layout.rooms.size()):
			var data = room.layout.rooms[i]
			var floor_tiles = room.get_node("ManualDecor_%d" % i).get_child(0).get_node("FloorTiles")
			assert(floor_tiles.get_used_cells().size() > 0)
			assert(not floor_tiles.collision_enabled)
			for cell in floor_tiles.get_used_cells():
				var point = floor_tiles.to_global(floor_tiles.map_to_local(cell))
				assert(is_equal_approx(point.y, data.position.y + data.height + 8))
				if "down" in data.used_sockets:
					assert(absf(point.x - data.position.x - data.width / 2) >= 96, "Paint must not cover down socket")
			var source = load(data.template.decoration_scene).instantiate()
			assert(source.get_node("FloorTiles").get_used_cells().size() == int(data.width / 16), "Runtime trimming must not modify source")
			source.free()
	room.free()
	print("PASS: painted floors instantiated, scaled to 16px, sockets cleared, source scenes preserved.")
	quit()
