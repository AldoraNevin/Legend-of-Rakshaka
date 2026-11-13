extends SceneTree
const LEVEL = preload("res://Script/Stage/Modular/modular_level.gd")
const NAV = preload("res://Script/Stage/Modular/room_navigation.gd")
var body: CharacterBody2D
var room: Node2D
var navigation: Dictionary
var frames := 0

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	Engine.physics_ticks_per_second = 60
	room = load("res://Scenes/Rooms/Modular/modular_level.tscn").instantiate()
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
	for seed_value in [0, 1, 42]:
		if not room.prepare(seed_value):
			quit(1)
			return
		navigation = NAV.build(room.layout)
		await physics_frame
		await physics_frame
		body.position = room.layout.spawn
		body.velocity = Vector2.ZERO
		var spawn_id := NAV.surface_at(navigation, room.layout.spawn)
		if not await move_to(body.position.x, navigation.surfaces[spawn_id].position.y):
			fail("spawn")
			return
		# One continuous run: visit every optional reward and return, then reach the exit.
		var targets: Array[Vector2] = []
		for reward in room.layout.rewards:
			targets.append(reward.position)
			targets.append(room.layout.spawn)
		targets.append(room.layout.exit)
		for point in targets:
			var source := NAV.surface_at(navigation, body.position)
			var target := NAV.surface_at(navigation, point)
			var path := NAV.route(navigation, source, target)
			if path.is_empty():
				fail("no route %s -> %s" % [source, target])
				return
			for i in range(1, path.size()):
				var previous: Rect2 = navigation.surfaces[path[i - 1]]
				var next: Rect2 = navigation.surfaces[path[i]]
				var points := NAV.step_points(previous, next)
				if not await move_to(points.approach, previous.position.y):
					fail("approach %s -> %s" % [previous, next])
					return
				if next.position.y <= previous.position.y:
					body.velocity.y = -300
				if not await move_to(points.landing, next.position.y, 6):
					fail("landing %s -> %s" % [previous, next])
					return
			if not await move_to(point.x, navigation.surfaces[target].position.y):
				fail("destination " + str(point))
				return
		print("PASS: continuous real TileMap collision traversal seed %d; treasure/artifact round trips and exit." % seed_value)
	room.queue_free()
	body.queue_free()
	await process_frame
	print("Physics frames: ", frames)
	quit()

func move_to(target_x: float, floor_y: float, minimum_frames := 0) -> bool:
	for frame in range(3000):
		await physics_frame
		frames += 1
		body.velocity.x = clampf((target_x - body.position.x) * 60, -100, 100)
		body.velocity.y += 1000.0 / 60.0
		body.move_and_slide()
		if frame >= minimum_frames and body.is_on_floor() and absf(body.position.x - target_x) < 1 and absf(body.position.y + 16 - floor_y) < 1:
			return true
	return false

func fail(phase: String) -> void:
	push_error("Modular traversal seed=%d at %s: %s" % [room.layout.seed, body.position, phase])
	quit(1)
