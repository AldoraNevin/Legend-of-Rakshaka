extends RefCounted
## Seeded graph -> weighted handmade templates -> socket alignment -> validation.
## All rectangles and cells use world coordinates. No room is scaled or mirrored.
const TILE := 16
var rng := RandomNumberGenerator.new()
var settings: Resource
var definitions: Array[Dictionary] = []
var graph: Dictionary
var rooms: Array[Dictionary] = []
var connections: Array[Dictionary] = []
var trials := 0

func generate(seed_value: int, config: Resource) -> Dictionary:
	settings = config
	var errors: PackedStringArray = settings.validate()
	if not errors.is_empty():
		return {"error": "; ".join(errors)}
	definitions.clear()
	for scene in settings.room_templates:
		var room: Node = scene.instantiate()
		if not room.has_method("describe") or not room.has_method("validate"):
			room.free()
			return {"error": "Every catalog scene needs room_template.gd."}
		errors.append_array(room.validate())
		if not errors.is_empty():
			room.free()
			return {"error": "; ".join(errors)}
		var definition: Dictionary = room.describe()
		definition["scene"] = scene
		definitions.append(definition)
		room.free()
	if not errors.is_empty():
		return {"error": "; ".join(errors)}
	var roles := {}
	var ids := {}
	for definition in definitions:
		if ids.has(definition.id):
			return {"error": "Duplicate Room Id: " + definition.id}
		ids[definition.id] = true
		for role in definition.roles:
			roles[role] = true
	for role in ["entrance", "combat", "junction", "treasure", "artifact", "exit"]:
		if not roles.has(role):
			return {"error": "Catalog is missing role: " + role}
	rng.seed = seed_value
	graph = make_graph()
	var best := {}
	var best_aspect := INF
	for attempt in range(12):
		if attempt > 0 and attempt % 3 == 0 and best.is_empty():
			# Large multilevel rooms can trap a particular branch assignment.
			# Retry topology too, retaining the seed and requested room/reward ranges.
			graph = make_graph()
		rooms.clear()
		connections.clear()
		trials = 0
		var starts := choices("entrance")
		if starts.is_empty():
			return {"error": "Catalog has no entrance template."}
		rooms.append(make_room(0, starts[0], Vector2.ZERO))
		if place_edge(0):
			var candidate := assemble(seed_value)
			var aspect: float = candidate.bounds.size.x / candidate.bounds.size.y
			if aspect < best_aspect:
				best = candidate
				best_aspect = aspect
			if aspect <= settings.target_aspect_ratio:
				return candidate
	if not best.is_empty():
		return best
	return {"error": "Layout search exhausted. Check socket capacity, roles and catalog; seed %d." % seed_value}

func make_graph() -> Dictionary:
	var count := rng.randi_range(settings.main_rooms_min, settings.main_rooms_max)
	# Small maps with many rewards need enough four-socket junctions in the spine.
	var required_junctions := ceili((settings.treasure_rooms + settings.artifact_rooms) / 2.0)
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var main: Array[int] = []
	var forks: Array[int] = []
	for i in range(count):
		var kind := "combat"
		if i == 0:
			kind = "entrance"
		elif i == count - 1:
			kind = "exit"
		elif i % 3 == 1:
			kind = "junction"
		elif count <= required_junctions * 3 and i <= required_junctions:
			kind = "junction"
		if kind == "junction":
			# Each four-door junction has two spare doors after the main path.
			forks.append(i)
			forks.append(i)
		nodes.append({"id": i, "kind": kind})
		main.append(i)
		if i > 0:
			edges.append({"from": i - 1, "to": i, "kind": "main"})
	forks.assign(shuffled(forks))
	var rewards: Array[String] = []
	for i in range(settings.treasure_rooms):
		rewards.append("treasure")
	for i in range(settings.artifact_rooms):
		rewards.append("artifact")
	# More reward branches than spare main sockets are chained via extra junctions.
	for reward_index in range(rewards.size()):
		var kind := rewards[reward_index]
		var parent: int = forks.pop_back()
		var depth := rng.randi_range(settings.branch_combat_min, settings.branch_combat_max)
		for step in range(depth):
			var id := nodes.size()
			nodes.append({"id": id, "kind": "combat"})
			edges.append({"from": parent, "to": id, "kind": "optional"})
			parent = id
		if forks.size() < rewards.size() - reward_index - 1:
			# Ensure a place for further branches even with a small main path.
			var id := nodes.size()
			nodes.append({"id": id, "kind": "junction"})
			edges.append({"from": parent, "to": id, "kind": "optional"})
			parent = id
			forks.append(id)
			forks.append(id)
		var reward_id := nodes.size()
		nodes.append({"id": reward_id, "kind": kind})
		edges.append({"from": parent, "to": reward_id, "kind": "optional"})
	return order_branches({"nodes": nodes, "edges": edges, "main_path": main})

func order_branches(input: Dictionary) -> Dictionary:
	# Reserve side branches while their junction still has free space. Placing the
	# entire spine first boxes rewards in and makes larger catalogs hard to solve.
	var ordered := {"nodes": [input.nodes[0].duplicate()], "edges": [], "main_path": []}
	var ids := {0: 0}
	order_children(0, input, ordered, ids)
	for id in input.main_path:
		ordered.main_path.append(ids[id])
	return ordered

func order_children(parent: int, input: Dictionary, ordered: Dictionary, ids: Dictionary) -> void:
	var main_child := -1
	# Commit the main exit before optional exits so a tower always changes floor.
	for edge in input.edges:
		if edge.from == parent and edge.kind == "main":
			append_ordered_edge(edge, input, ordered, ids)
			main_child = edge.to
	for edge in input.edges:
		if edge.from == parent and edge.kind == "optional":
			append_ordered_edge(edge, input, ordered, ids)
			order_children(edge.to, input, ordered, ids)
	if main_child >= 0:
		order_children(main_child, input, ordered, ids)

func append_ordered_edge(edge: Dictionary, input: Dictionary, ordered: Dictionary, ids: Dictionary) -> void:
	var id: int = ordered.nodes.size()
	ids[edge.to] = id
	ordered.nodes.append({"id": id, "kind": input.nodes[edge.to].kind})
	ordered.edges.append({"from": ids[edge.from], "to": id, "kind": edge.kind})

func shuffled(values: Array) -> Array:
	var result := values.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary = result[i]
		result[i] = result[j]
		result[j] = temporary
	return result

func choices(kind: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for definition in definitions:
		if kind in definition.roles:
			candidates.append({"definition": definition, "score": -log(maxf(rng.randf(), 0.000001)) / definition.weight})
	candidates.sort_custom(func(a, b): return a.score < b.score)
	var result: Array[Dictionary] = []
	for entry in candidates:
		result.append(entry.definition)
	return result

func make_room(id: int, definition: Dictionary, origin: Vector2) -> Dictionary:
	return {"id": id, "kind": graph.nodes[id].kind, "definition": definition,
		"position": origin, "bounds": Rect2(origin, Vector2(definition.size * TILE)), "used_sockets": []}

func place_edge(index: int) -> bool:
	if index == graph.edges.size():
		return true
	if trials >= settings.search_budget:
		return false
	var edge: Dictionary = graph.edges[index]
	var source: Dictionary = rooms[edge.from]
	var sockets := shuffled(source.definition.sockets)
	var preferred := "right" if rng.randf() < settings.rightward_bias else "left"
	if source.kind == "junction" and edge.kind == "main" and not source.used_sockets.is_empty():
		var entry := socket_by_id(source, source.used_sockets[0])
		if rng.randf() < settings.foldback_chance:
			preferred = entry.side
		else:
			preferred = "left" if entry.side == "right" else "right"
	sockets.sort_custom(func(a, b): return a.side == preferred and b.side != preferred)
	var lengths := shuffled(range(settings.corridor_min_tiles, settings.corridor_max_tiles + 1))
	for socket in sockets:
		if socket.id in source.used_sockets:
			continue
		# Traversing a main-path tower must change altitude, producing multiple tiers.
		if source.kind == "junction" and edge.kind == "main" and not source.used_sockets.is_empty():
			var entry := socket_by_id(source, source.used_sockets[0])
			if socket.position.y == entry.position.y:
				continue
		for definition in choices(graph.nodes[edge.to].kind):
			var target_sockets := shuffled(definition.sockets)
			if graph.nodes[edge.to].kind == "junction":
				var climb: bool = rng.randf() < settings.upward_bias
				target_sockets.sort_custom(func(a, b): return a.position.y > b.position.y if climb else a.position.y < b.position.y)
			for target in target_sockets:
				if target.side == socket.side:
					continue
				for length in lengths:
					trials += 1
					if trials > settings.search_budget:
						return false
					var start: Vector2 = source.position + socket.position
					var direction := Vector2.RIGHT if socket.side == "right" else Vector2.LEFT
					var end: Vector2 = start + direction * length * TILE
					var candidate := make_room(edge.to, definition, end - target.position)
					var passage := Rect2(minf(start.x, end.x), start.y - 32, length * TILE, 64)
					var bounds := Rect2(passage.position - Vector2(0, TILE), passage.size + Vector2(0, TILE * 2))
					if not fits(candidate.bounds, bounds, edge.from):
						continue
					source.used_sockets.append(socket.id)
					candidate.used_sockets.append(target.id)
					rooms.append(candidate)
					connections.append({"from": edge.from, "to": edge.to, "kind": edge.kind,
						"from_socket": socket.id, "to_socket": target.id,
						"start": start, "end": end, "region": passage, "bounds": bounds})
					if place_edge(index + 1):
						return true
					connections.pop_back()
					rooms.pop_back()
					source.used_sockets.erase(socket.id)
	return false

static func socket_by_id(room: Dictionary, id: String) -> Dictionary:
	for socket in room.definition.sockets:
		if socket.id == id:
			return socket
	return {}

func fits(bounds: Rect2, corridor: Rect2, parent: int) -> bool:
	for other in rooms:
		if bounds.grow(TILE).intersects(other.bounds):
			return false
		if other.id != parent and corridor.grow(TILE).intersects(other.bounds):
			return false
	for connection in connections:
		if bounds.grow(TILE).intersects(connection.bounds) or corridor.grow(TILE).intersects(connection.bounds):
			return false
	return true

func assemble(seed_value: int) -> Dictionary:
	var solid := {}
	var platforms := {}
	var air := {}
	var bounds: Rect2 = rooms[0].bounds
	var enemies: Array[Vector2] = []
	var rewards: Array[Dictionary] = []
	for room in rooms:
		var offset := Vector2i(room.position / TILE)
		var cells: Dictionary = room.definition.solid.duplicate()
		cells.merge(room.definition.caps)
		for socket in room.definition.sockets:
			if socket.id in room.used_sockets:
				for cell in socket.caps:
					cells.erase(cell)
		for cell in cells:
			solid[cell + offset] = true
		for cell in room.definition.platforms:
			platforms[cell + offset] = true
		for x in range(room.definition.size.x):
			for y in range(room.definition.size.y):
				var cell := Vector2i(x, y)
				if not cells.has(cell):
					air[cell + offset] = true
		bounds = bounds.merge(room.bounds)
		if room.kind in ["combat", "junction"]:
			for point in room.definition.enemies:
				if rng.randf() < settings.enemy_spawn_chance:
					enemies.append(point + room.position)
		if room.kind in ["treasure", "artifact"]:
			rewards.append({"kind": room.kind, "room_id": room.id,
				"position": room.position + room.definition.markers.RewardSpawn + Vector2(0, 16)})
	for connection in connections:
		var rect: Rect2 = connection.region
		for x in range(roundi(rect.position.x / TILE), roundi(rect.end.x / TILE)):
			for y in range(roundi(rect.position.y / TILE), roundi(rect.end.y / TILE)):
				air[Vector2i(x, y)] = true
			solid[Vector2i(x, roundi(rect.position.y / TILE) - 1)] = true
			solid[Vector2i(x, roundi(rect.end.y / TILE))] = true
	var first: Dictionary = rooms[0]
	var last: Dictionary = rooms[graph.main_path.back()]
	return {"seed": seed_value, "graph": graph.duplicate(true), "rooms": rooms.duplicate(true),
		"connections": connections.duplicate(true), "bounds": bounds, "air": air,
		"solid": solid, "platform_cells": platforms, "regions": cell_rects(air),
		"shell": cell_rects(solid), "platforms": cell_rects(platforms),
		"spawn": first.position + first.definition.markers.PlayerSpawn,
		"exit": last.position + last.definition.markers.PlayerSpawn,
		"reward": last.position + last.definition.markers.RewardSpawn,
		"enemies": enemies, "rewards": rewards}

static func cell_rects(cells: Dictionary) -> Array[Rect2]:
	var rows := {}
	for cell: Vector2i in cells:
		if not rows.has(cell.y):
			rows[cell.y] = []
		rows[cell.y].append(cell.x)
	var result: Array[Rect2] = []
	var ys := rows.keys()
	ys.sort()
	for y in ys:
		var xs: Array = rows[y]
		xs.sort()
		var start: int = xs[0]
		var end := start
		for i in range(1, xs.size()):
			if xs[i] == end + 1:
				end = xs[i]
			else:
				result.append(Rect2(start * TILE, y * TILE, (end - start + 1) * TILE, TILE))
				start = xs[i]
				end = start
		result.append(Rect2(start * TILE, y * TILE, (end - start + 1) * TILE, TILE))
	return result

static func validate(candidate: Dictionary) -> PackedStringArray:
	if candidate.has("error"):
		return PackedStringArray([candidate.error])
	var errors := PackedStringArray()
	for i in range(candidate.rooms.size()):
		for j in range(i):
			if candidate.rooms[i].bounds.intersects(candidate.rooms[j].bounds):
				errors.append("Overlapping rooms.")
	var used := {}
	for connection in candidate.connections:
		for pair in [[connection.from, connection.from_socket], [connection.to, connection.to_socket]]:
			if used.has(str(pair)):
				errors.append("Socket used twice.")
			used[str(pair)] = true
		var source: Dictionary = candidate.rooms[connection.from]
		var target: Dictionary = candidate.rooms[connection.to]
		if connection.start != source.position + socket_by_id(source, connection.from_socket).position or connection.end != target.position + socket_by_id(target, connection.to_socket).position:
			errors.append("Misaligned socket.")
	var first := Vector2i((candidate.spawn / TILE).floor())
	var reached := {first: true}
	var pending: Array[Vector2i] = [first]
	var cursor := 0
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if candidate.air.has(next) and not reached.has(next):
				reached[next] = true
				pending.append(next)
	if reached.size() != candidate.air.size():
		errors.append("Disconnected room interior or corridor.")
	for point in [candidate.spawn, candidate.exit, candidate.reward] + candidate.enemies:
		if not reached.has(Vector2i((point / TILE).floor())):
			errors.append("Unreachable marker.")
	return errors
