extends RefCounted
## Traversal surfaces shared by validation and continuous physics tests.
static func floors(room: Dictionary) -> Array[Rect2]:
	var x: float = room.position.x
	var y: float = room.floor
	var center: float = x + room.width / 2
	if "down" not in room.used_sockets:
		return [Rect2(x, y, room.width, 16)]
	return [Rect2(x, y, center - 96 - x, 16), Rect2(center - 72, y, 144, 8),
		Rect2(center + 96, y, x + room.width - center - 96, 16)]

static func anchor_floor(room: Dictionary) -> Rect2:
	return Rect2(room.position.x, room.floor, room.width / 2 - 96, 16)

static func walk_floors(room: Dictionary) -> Array[Rect2]:
	var result := floors(room)
	if result.size() > 1 and "up" in room.used_sockets:
		# A jump across the opening lands on the first ascending step.
		result[1] = climb(room)[0]
	return result

static func climb(room: Dictionary) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if "up" not in room.used_sockets:
		return result
	var center: float = room.position.x + room.width / 2
	var y: float = room.floor - 32
	while y >= room.position.y:
		var width := 192.0 if y == room.floor - 64 else 144.0
		result.append(Rect2(center - width / 2, y, width, 8))
		y -= 32
	return result

static func shaft_steps(connection: Dictionary) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if connection.direction not in ["up", "down"]:
		return result
	var y: float = maxf(connection.start.y, connection.end.y)
	while y >= minf(connection.start.y, connection.end.y):
		result.append(Rect2(connection.start.x - 72, y, 144, 8))
		y -= 32
	return result

static func edge_route(connection: Dictionary, rooms: Array, reverse := false) -> Array[Rect2]:
	var source: Dictionary = rooms[connection.to if reverse else connection.from]
	var target: Dictionary = rooms[connection.from if reverse else connection.to]
	var side: String = connection.to_socket if reverse else connection.from_socket
	var result: Array[Rect2] = []
	var source_floor := walk_floors(source)
	var target_floor := walk_floors(target)
	match side:
		"right":
			result.append_array(source_floor)
			result.append(Rect2(connection.region.position.x, source.floor, connection.region.size.x, 16))
			result.append(anchor_floor(target))
		"left":
			result.append(source_floor[0])
			result.append(Rect2(connection.region.position.x, source.floor, connection.region.size.x, 16))
			target_floor.reverse()
			result.append_array(target_floor)
		"up":
			result.append(source_floor[0])
			if source_floor.size() > 1:
				result.append(source_floor[1])
			result.append_array(climb(source))
			result.append_array(shaft_steps(connection))
			result.append(floors(target)[1]) # upper room's down-socket bridge
			if "up" in target.used_sockets:
				result.append(climb(target)[0])
			result.append(anchor_floor(target))
		"down":
			result.append(source_floor[0])
			# Fall beside the shaft steps onto a wide catch platform in the lower room.
			result.append(Rect2(target.position.x + target.width / 2 - 96, target.floor - 64, 192, 8))
			result.append(anchor_floor(target))
	var clean: Array[Rect2] = []
	for surface in result:
		if clean.is_empty() or surface != clean.back():
			clean.append(surface)
	return clean
