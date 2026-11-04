extends SceneTree
const Coast = preload("res://Script/Stage/coastal_room_pcg.gd")
func _initialize() -> void:
	var sizes := {}
	var shapes := {}
	for seed_value in range(200):
		var layout := Coast.generate_layout(seed_value)
		assert(Coast.validate_layout(layout).is_empty())
		assert(layout == Coast.generate_layout(seed_value))
		for room in layout.rooms:
			sizes[Vector2(room.width, room.height)] = true
			shapes[room.profile] = true
		assert(layout.branches.size() == 2)
		for branch in layout.branches:
			assert(branch.to not in layout.graph.main_path)
		# Distinct chambers occupy disjoint horizontal slots (branches sit above).
		for i in range(layout.rooms.size()):
			var a: Dictionary = layout.rooms[i]
			for j in range(i + 1, layout.rooms.size()):
				var b: Dictionary = layout.rooms[j]
				assert(not Rect2(a.position, Vector2(a.width, a.height)).intersects(Rect2(b.position, Vector2(b.width, b.height))))
	assert(sizes.size() >= 5 and shapes.size() == 6)
	var broken := Coast.generate_layout(42)
	broken.shell.pop_back()
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.route[1].position.y -= 64
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.platforms.pop_back()
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.graph.edges.remove_at(0)
	assert(not Coast.validate_layout(broken).is_empty())
	print("PASS: 200 deterministic irregular layouts, varied profiles, disjoint rooms, physical connectivity, damaged shell/stairs/graph rejection.")
	quit()
