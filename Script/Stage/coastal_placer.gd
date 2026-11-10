extends RefCounted
## Bounded, seeded backtracking. No global RNG, rotation of gravity, or fallback line.
const CATALOG = preload("res://Scenes/Rooms/Stage/Coastal/Templates/catalog.tres")
const OPPOSITE := {"left": "right", "right": "left", "up": "down", "down": "up"}
const DIRECTIONS := {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}
const MAX_TRIALS := 4000
var rng := RandomNumberGenerator.new()
var graph: Dictionary
var rooms: Array[Dictionary] = []
var connections: Array[Dictionary] = []
var used := {}
var trials := 0

func solve(input_graph: Dictionary, seed_value: int) -> Dictionary:
	graph = input_graph
	rng.seed = seed_value
	for template in CATALOG.room_templates:
		var errors: PackedStringArray = template.validate()
		if not errors.is_empty():
			return {"error": "; ".join(errors)}
	for attempt in range(8):
		rooms.clear()
		connections.clear()
		used.clear()
		trials = 0
		var choices := shuffled(CATALOG.room_templates)
		for template in choices:
			if "entrance" in template.allowed_kinds:
				rooms.append(make_room(0, template, Vector2.ZERO))
				break
		if rooms.is_empty():
			return {"error": "No entrance template in catalog."}
		if place_edge(0):
			return {"rooms": rooms.duplicate(true), "connections": connections.duplicate(true), "trials": trials}
	return {"error": "No non-overlapping socket layout found within the search budget."}

func shuffled(values: Array) -> Array:
	var result := values.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary = result[i]
		result[i] = result[j]
		result[j] = temporary
	return result

func make_room(id: int, template: Resource, origin: Vector2) -> Dictionary:
	return {"index": id, "kind": graph.nodes[id].kind, "template": template,
		"position": origin, "width": template.size.x, "height": template.size.y,
		"floor": origin.y + template.size.y, "bounds": Rect2(origin, template.size),
		"title": template.display_name, "used_sockets": []}

func key(id: int, side: String) -> String:
	return "%d:%s" % [id, side]

func place_edge(edge_index: int) -> bool:
	if edge_index >= graph.edges.size():
		return true
	if trials >= MAX_TRIALS:
		return false
	var edge: Dictionary = graph.edges[edge_index]
	var source: Dictionary = rooms[edge.from]
	var sides := shuffled(["left", "right", "up", "down"])
	# Prefer turning, rather than repeatedly extending one axis.
	if not connections.is_empty():
		var last: String = connections.back().direction
		if last in sides:
			sides.erase(last)
			sides.append(last)
	for side: String in sides:
		var from_socket: Resource = source.template.socket(side)
		if from_socket == null or used.has(key(edge.from, side)):
			continue
		for template in shuffled(CATALOG.room_templates):
			if graph.nodes[edge.to].kind not in template.allowed_kinds:
				continue
			var to_socket: Resource = template.socket(OPPOSITE[side])
			if to_socket == null or to_socket.opening != from_socket.opening:
				continue
			for length in shuffled([128, 192, 256]):
				trials += 1
				if trials > MAX_TRIALS:
					return false
				var start: Vector2 = source.position + from_socket.position
				var end: Vector2 = start + DIRECTIONS[side] * length
				var candidate := make_room(edge.to, template, end - to_socket.position)
				var corridor: Rect2
				if side in ["left", "right"]:
					corridor = Rect2(minf(start.x, end.x), start.y - 64, length, 128)
				else:
					corridor = Rect2(start.x - 96, minf(start.y, end.y), 192, length)
				if not fits(candidate, corridor, edge.from):
					continue
				used[key(edge.from, side)] = true
				used[key(edge.to, OPPOSITE[side])] = true
				rooms[edge.from].used_sockets.append(side)
				candidate.used_sockets.append(OPPOSITE[side])
				rooms.append(candidate)
				connections.append({"from": edge.from, "to": edge.to, "kind": edge.kind,
					"direction": side, "from_socket": side, "to_socket": OPPOSITE[side],
					"start": start, "end": end, "region": corridor})
				if place_edge(edge_index + 1):
					return true
				connections.pop_back()
				rooms.pop_back()
				rooms[edge.from].used_sockets.erase(side)
				used.erase(key(edge.from, side))
				used.erase(key(edge.to, OPPOSITE[side]))
	return false

func fits(candidate: Dictionary, corridor: Rect2, parent_id: int) -> bool:
	for other in rooms:
		if candidate.bounds.grow(16).intersects(other.bounds):
			return false
		if other.index != parent_id and corridor.grow(16).intersects(other.bounds):
			return false
	for existing in connections:
		if candidate.bounds.grow(16).intersects(existing.region) or corridor.grow(16).intersects(existing.region):
			return false
	return true
