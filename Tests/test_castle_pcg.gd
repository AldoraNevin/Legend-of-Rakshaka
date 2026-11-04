extends SceneTree
const Castle = preload("res://Script/Stage/castle_room_pcg.gd")

func _initialize() -> void:
	var fingerprints := {}
	for seed_value in range(200):
		var layout := Castle.generate_layout(seed_value)
		assert(Castle.validate_layout(layout).is_empty())
		assert(layout.modules[4].position.y + layout.modules[4].entry.y > layout.modules[2].position.y + layout.modules[2].exit.y)
		assert(layout == Castle.generate_layout(seed_value))
		var ids := PackedStringArray()
		for module in layout.modules:
			ids.append(module.id)
		fingerprints["/".join(ids)] = true
	assert(fingerprints.size() > 50)
	var broken := Castle.generate_layout(42)
	broken.modules[2].position.x += 16
	assert(not Castle.validate_layout(broken).is_empty())
	broken = Castle.generate_layout(42)
	broken.route.pop_back()
	assert(not Castle.validate_layout(broken).is_empty())
	var room: Node2D = load("res://Scenes/Rooms/Stage/room_1_castle.tscn").instantiate()
	assert(room.prepare(42))
	assert(room.has_node("Modules"))
	assert(room.get_node("EnemySpawns").get_child_count() == 5)
	assert(room.prepare(43))
	assert(room.get_node("Modules").get_child_count() == room.layout.modules.size())
	room.free()
	print("PASS: 200 seeds, ", fingerprints.size(), " distinct module sequences, reproducibility, disconnected sockets, malformed routes, regeneration.")
	quit()
