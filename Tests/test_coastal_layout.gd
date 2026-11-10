extends SceneTree
const Coast = preload("res://Script/Stage/coastal_room_pcg.gd")
func _initialize() -> void:
	var templates := {}
	var directions := {}
	var negative_positions := false
	for seed_value in range(200):
		var layout := Coast.generate_layout(seed_value)
		var errors := Coast.validate_layout(layout)
		assert(errors.is_empty(), "seed=%d: %s" % [seed_value, errors])
		assert(layout == Coast.generate_layout(seed_value))
		for room in layout.rooms:
			templates[room.template.template_id] = true
			negative_positions = negative_positions or room.position.x < 0 or room.position.y < 0
		for connection in layout.connections:
			directions[connection.direction] = true
		assert(layout.branches.size() == 2)
		for branch in layout.branches:
			assert(branch.to not in layout.graph.main_path)
	assert(templates.size() == 8 and directions.size() == 4 and negative_positions)
	var broken := Coast.generate_layout(42)
	broken.shell.pop_back()
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.platforms.clear()
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.rooms[1].bounds = broken.rooms[0].bounds
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.connections[0].end += Vector2(16, 0)
	assert(not Coast.validate_layout(broken).is_empty())
	broken = Coast.generate_layout(42)
	broken.graph.edges.remove_at(0)
	assert(not Coast.validate_layout(broken).is_empty())
	print("PASS: 200 deterministic layouts, 8 templates, all 4 directions, non-overlap, matching sockets, connected geometry and invalid layout rejection.")
	quit()
