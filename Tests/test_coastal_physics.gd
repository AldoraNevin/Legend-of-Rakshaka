extends SceneTree
var body: CharacterBody2D
var room: Node2D

func _initialize() -> void:
	call_deferred("run_test")

func routes() -> Array:
	return [room.layout.route]

func seeds() -> Array:
	return range(12)

func after_routes() -> bool:
	return await move_to(room.layout.exit.x, room.layout.exit.y + 34)

func run_test() -> void:
	Engine.physics_ticks_per_second = 60
	room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	root.add_child(room)
	body = CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 6
	capsule.height = 22
	collider.shape = capsule
	collider.position = Vector2(1, 5)
	body.add_child(collider)
	root.add_child(body)
	for seed_value in seeds():
		assert(room.prepare(seed_value))
		await physics_frame
		for route in routes():
			# One continuous traversal: only place the body at the start of a route.
			body.position = Vector2(route[0].get_center().x, route[0].position.y - 16.1)
			if route == room.layout.route:
				body.position = room.layout.spawn
			body.velocity = Vector2.ZERO
			await physics_frame
			for i in range(1, route.size()):
				var source: Rect2 = route[i - 1]
				var target: Rect2 = route[i]
				var target_x := clampf(source.get_center().x, target.position.x + 8, target.end.x - 8)
				var approach := clampf(target_x, source.position.x + 8, source.end.x - 8)
				if not await move_to(approach, source.position.y):
					fail(seed_value, i, "approach")
					return
				if target.position.y < source.position.y or (target.position.y == source.position.y and (target.position.x > source.end.x or source.position.x > target.end.x)):
					body.velocity.y = -300
				if not await move_to(target_x, target.position.y, 6):
					fail(seed_value, i, "landing")
					return
		if not await after_routes():
			fail(seed_value, -1, "return")
			return
	print("PASS: continuous traversal with baseline speed/jump and real collisions across %d layouts." % seeds().size())
	room.queue_free()
	body.queue_free()
	await process_frame
	quit()

func move_to(target_x: float, floor_y: float, minimum_frames := 0) -> bool:
	for frame in range(480):
		await physics_frame
		body.velocity.x = clampf((target_x - body.position.x) * 60, -100, 100)
		body.velocity.y += 1000.0 / 60.0
		body.move_and_slide()
		if frame >= minimum_frames and body.is_on_floor() and absf(body.position.x - target_x) < 1 and absf(body.position.y + 16 - floor_y) < 1:
			return true
	return false

func fail(seed_value: int, hop: int, phase: String) -> void:
	push_error("Coastal traversal failed seed=%d hop=%d phase=%s at %s" % [seed_value, hop, phase, body.position])
	quit(1)
