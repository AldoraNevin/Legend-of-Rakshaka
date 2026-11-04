extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	Engine.physics_ticks_per_second = 60
	var room: Node2D = load("res://Scenes/Rooms/Stage/room_1_castle.tscn").instantiate()
	root.add_child(room)
	var body := CharacterBody2D.new()
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
	for seed_value in [0, 2, 42, 999]:
		assert(room.prepare(seed_value))
		await physics_frame
		var route: Array = room.layout.route
		for i in range(1, route.size()):
			var source: Rect2 = route[i - 1]
			var target: Rect2 = route[i]
			var target_x := clampf(source.get_center().x, target.position.x + 14, target.end.x - 14)
			var start_x := clampf(target_x, source.position.x + 14, source.end.x - 14)
			body.position = Vector2(start_x, source.position.y - 16.1)
			body.velocity = Vector2.ZERO
			await physics_frame
			body.velocity.y = -300 if target.position.y < source.position.y else 0
			var landed := false
			for frame in range(90):
				await physics_frame
				body.velocity.x = clampf((target_x - body.position.x) * 60, -100, 100)
				body.velocity.y += 1000.0 / 60.0
				body.move_and_slide()
				if body.is_on_floor() and frame > 5 and absf(body.position.x - target_x) < 1:
					landed = absf(body.position.y + 16 - target.position.y) < 1.0
					break
			if not landed:
				push_error("Physics hop failed seed=%d hop=%d position=%s" % [seed_value, i, body.position])
				quit(1)
				return
	print("PASS: all modular routes across 4 seeds (including descent) with Godot collisions and baseline capsule/speed/gravity.")
	quit()

