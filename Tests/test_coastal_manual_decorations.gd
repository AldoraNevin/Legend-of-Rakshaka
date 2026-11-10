extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var catalog = load("res://Scenes/Rooms/Stage/Coastal/Templates/catalog.tres")
	for template in catalog.room_templates:
		var art = load(template.decoration_scene).instantiate()
		root.add_child(art)
		assert(art.has_node("Decorations/PillarExample"))
		assert(not art.get_node("RoomGuide").visible)
		art.free()
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	root.add_child(room)
	for seed_value in [42, 91, 42]:
		assert(room.prepare(seed_value))
		var count := 0
		for child in room.get_children():
			if str(child.name).begins_with("ManualDecor_"):
				count += 1
		assert(count == room.layout.rooms.size(), "Rebuilding must not duplicate or omit decorations")
		for i in range(room.layout.rooms.size()):
			var data: Dictionary = room.layout.rooms[i]
			var holder = room.get_node("ManualDecor_%d" % i)
			assert(holder.position == data.position)
			var art = holder.get_child(0)
			var pillar = art.get_node("Decorations/PillarExample")
			assert(pillar.global_position.is_equal_approx(data.position + Vector2(32, data.height - 26)))
			assert(not art.get_node("RoomGuide").visible)
	room.free()
	print("PASS: all catalog decoration scenes load; local placement, hidden guides and repeated generation verified.")
	quit()
