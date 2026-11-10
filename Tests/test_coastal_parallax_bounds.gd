extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	root.add_child(room)
	assert(room.prepare(1000045))
	await physics_frame
	await physics_frame
	var space := root.world_2d.direct_space_state
	var checked := 0
	for rect in room.layout.shell:
		var middle: Vector2 = rect.get_center()
		var query := PhysicsRayQueryParameters2D.create(middle - Vector2(0, 32), middle + Vector2(0, 32), 2)
		assert(not space.intersect_ray(query).is_empty(), "Missing solid player boundary")
		checked += 1
	assert(room.get_node("Backdrop/CoastalParallax").layer < 0)
	assert(not room.has_node("Backdrop/BackgroundTiles"))
	print("PASS: %d shell boundaries retain collision; opaque background removed." % checked)
	room.queue_free()
	await process_frame
	quit()
