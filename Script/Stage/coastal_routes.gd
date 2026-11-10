extends RefCounted
## Traversal surfaces shared by validation and continuous physics tests.
const STYLE = preload("res://Assets/Tileset/coastal_style.tres")
static func interior(room: Dictionary) -> Array[Rect2]:
	var candidates: Array[Rect2] = room.template.extra_platforms.duplicate()
	var result: Array[Rect2] = []
	var center: float = room.width / 2
	if room.template.automatic_balconies:
		candidates.append(Rect2(0, room.height - 32, 24, 8))
		candidates.append(Rect2(24, room.height - 64, center - 136, 8))
		# Right-hand footholds stay away from the socket landing and spawn.
		candidates.append(Rect2(room.width - 56, room.height - 32, 32, 8))
		candidates.append(Rect2(center + 112, room.height - 64, room.width - center - 136, 8))
		for height in range(96, int(room.height) - 24, 40):
			for x in [24.0, center + 112]:
				candidates.append(Rect2(x, room.height - height, center - 136, 8))
	for local in candidates:
		if local.size.x < 24:
			continue
		# Check the union of air regions, including headroom.
		var fits := true
		for x in range(int(local.position.x), int(local.end.x), 8):
			for y in range(int(local.position.y) - 32, int(local.end.y), 8):
				var covered := false
				for air in room.template.air_regions:
					if air.has_point(Vector2(x + 4, y + 4)):
						covered = true
				if not covered:
					fits = false
		if fits:
			result.append(Rect2(room.position + local.position, local.size))
	return result
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
	result.append(Rect2(center - 72, room.floor - 32, 144, 8))
	result.append(Rect2(center - 96, room.floor - 64, 192, 8))
	var y: float = room.floor - 64
	var index := 0
	var steps := ceili((y - room.position.y) / STYLE.climb_rise)
	var rise: float = (y - room.position.y) / steps
	for step in range(1, steps + 1):
		y = room.position.y if step == steps else room.floor - 64 - step * rise
		var width: float = 144 if y == room.position.y else STYLE.climb_width
		var offset: float = 0 if y == room.position.y else (-STYLE.climb_offset if index % 2 == 0 else STYLE.climb_offset)
		result.append(Rect2(center + offset - width / 2, y, width, 8))
		index += 1
	return result

static func shaft_steps(connection: Dictionary) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if connection.direction not in ["up", "down"]:
		return result
	var bottom: float = maxf(connection.start.y, connection.end.y)
	var top: float = minf(connection.start.y, connection.end.y)
	var y := bottom
	var index := 0
	var steps := ceili((bottom - top) / STYLE.climb_rise)
	var rise: float = (bottom - top) / steps
	for step in range(steps + 1):
		y = top if step == steps else bottom - step * rise
		var endpoint := y == bottom or y == top
		var width: float = 144 if endpoint else STYLE.climb_width
		var offset: float = 0 if endpoint else (-STYLE.climb_offset if index % 2 == 0 else STYLE.climb_offset)
		result.append(Rect2(connection.start.x + offset - width / 2, y, width, 8))
		index += 1
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








