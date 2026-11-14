extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = load("res://Assets/Tileset/pantai_modular_solid.tres")
	layer.scale = Vector2(0.25, 0.25)
	layer.set_cell(Vector2i.ZERO, 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(3, 0), 0, Vector2i(3, 4))
	root.add_child(layer)
	await physics_frame
	await physics_frame
	var world := layer.get_world_2d().direct_space_state
	var left := world.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(1, -20), Vector2(1, 30), 2))
	var right := world.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(14, -20), Vector2(14, 30), 2))
	assert(not left.is_empty() and not right.is_empty())
	assert(left.position.y > right.position.y + 4, "Ascending tile must not retain a full-box collider.")
	left = world.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(49, -20), Vector2(49, 30), 2))
	right = world.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(62, -20), Vector2(62, 30), 2))
	assert(right.position.y > left.position.y + 4, "Descending slope must follow the opposite contour.")
	var nav := load("res://Script/Stage/Modular/room_navigation.gd")
	var wall := {}
	for y in range(1, 10):
		wall[Vector2i(-1, y)] = true
	assert(nav.can_step(Rect2(0,160,64,16), Rect2(0,32,32,16), wall))
	assert(not nav.can_step(Rect2(0,160,64,16), Rect2(0,32,32,16), {}))
	layer.queue_free()
	await process_frame
	print("PASS: real scaled TileMap raycasts follow ascending/descending slopes; high routes require a continuous wall.")
	quit()
