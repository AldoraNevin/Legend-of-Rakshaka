extends "res://Tests/test_coastal_physics.gd"

func seeds() -> Array:
	return range(32)

func routes() -> Array:
	var path: Array = room.layout.route.duplicate()
	var reversed_connections: Array = room.layout.connections.duplicate()
	reversed_connections.reverse()
	for connection in reversed_connections:
		if connection.kind != "main":
			continue
		for surface in room.ROUTES.edge_route(connection, room.layout.rooms, true):
			if surface != path.back():
				path.append(surface)
	return [path]

func after_routes() -> bool:
	return await move_to(room.layout.spawn.x, room.layout.spawn.y + 34)
