extends Node2D
const GRAPH = preload("res://Script/Stage/coastal_graph.gd")
const PLACER = preload("res://Script/Stage/coastal_placer.gd")
const ROUTES = preload("res://Script/Stage/coastal_routes.gd")
const BACKDROP = preload("res://Script/Stage/coastal_backdrop.gd")
const MAP = preload("res://Script/UI/coastal_map.gd")
const TREASURE = preload("res://Script/Interactables/coastal_treasure.gd")
const TILE := 16
var layout: Dictionary = {}
var exit_open := false
var return_currents: Array[Dictionary] = []

static func generate_layout(seed_value: int) -> Dictionary:
	var graph := GRAPH.generate(seed_value)
	var placement: Dictionary = PLACER.new().solve(graph, seed_value)
	if placement.has("error"):
		return {"error": placement.error}
	var rooms: Array = placement.rooms
	var connections: Array = placement.connections
	var regions: Array[Rect2] = []
	var platforms: Array[Rect2] = []
	var route: Array[Rect2] = []
	var branches: Array[Dictionary] = []
	for room in rooms:
		for rect in room.template.air_regions:
			regions.append(Rect2(room.position + rect.position, rect.size))
		for step in ROUTES.climb(room) + ROUTES.interior(room):
			if step not in platforms:
				platforms.append(step)
		if "down" in room.used_sockets:
			platforms.append(ROUTES.floors(room)[1])
	for connection in connections:
		regions.append(connection.region)
		for step in ROUTES.shaft_steps(connection):
			if step not in platforms:
				platforms.append(step)
		var edge_route := ROUTES.edge_route(connection, rooms)
		if connection.kind == "main":
			for surface in edge_route:
				if route.is_empty() or route.back() != surface:
					route.append(surface)
		else:
			var treasure: Vector2 = rooms[connection.to].position + rooms[connection.to].template.anchor + Vector2(0, 18)
			branches.append({"from": connection.from, "to": connection.to, "route": edge_route,
				"return_route": ROUTES.edge_route(connection, rooms, true), "treasure": treasure,
				"sign": rooms[connection.from].position + rooms[connection.from].template.anchor + Vector2(0, -64)})
	var air := rasterize(regions)
	var shell := build_shell(air)
	var bounds := regions[0]
	for rect in regions:
		bounds = bounds.merge(rect)
	var first: Dictionary = rooms[0]
	var last: Dictionary = rooms[graph.main_path.back()]
	var enemies: Array[Vector2] = []
	for id in graph.main_path:
		if id > 0:
			enemies.append(rooms[id].position + rooms[id].template.anchor)
	return {"seed": seed_value, "graph": graph, "rooms": rooms, "connections": connections,
		"regions": regions, "shell": shell, "platforms": platforms, "route": route, "branches": branches,
		"bounds": bounds.grow(TILE), "spawn": first.position + first.template.anchor,
		"exit": last.position + last.template.anchor,
		"reward": last.position + last.template.anchor + Vector2(-24, 0), "enemies": enemies}

static func rasterize(regions: Array[Rect2]) -> Dictionary:
	var air := {}
	for rect in regions:
		for x in range(roundi(rect.position.x / TILE), roundi(rect.end.x / TILE)):
			for y in range(roundi(rect.position.y / TILE), roundi(rect.end.y / TILE)):
				air[Vector2i(x, y)] = true
	return air

static func build_shell(air: Dictionary) -> Array[Rect2]:
	var rows := {}
	for cell: Vector2i in air:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var adjacent: Vector2i = cell + direction
			if air.has(adjacent):
				continue
			if not rows.has(adjacent.y):
				rows[adjacent.y] = {}
			rows[adjacent.y][adjacent.x] = true
	var result: Array[Rect2] = []
	var row_keys: Array = rows.keys()
	row_keys.sort()
	for y in row_keys:
		var xs: Array = rows[y].keys()
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

static func validate_layout(candidate: Dictionary) -> PackedStringArray:
	if candidate.has("error"):
		return PackedStringArray([candidate.error])
	var errors := GRAPH.validate(candidate.graph)
	var rooms: Array = candidate.rooms
	var connections: Array = candidate.connections
	if connections.size() != candidate.graph.edges.size():
		errors.append("Jumlah koneksi fisik tidak cocok dengan graph.")
	var used := {}
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		for j in range(i):
			if room.bounds.grow(16).intersects(rooms[j].bounds):
				errors.append("Ruangan bertumpuk.")
	for i in range(connections.size()):
		var connection: Dictionary = connections[i]
		var source: Dictionary = rooms[connection.from]
		var target: Dictionary = rooms[connection.to]
		if connection.start != source.position + source.template.socket(connection.from_socket).position or connection.end != target.position + target.template.socket(connection.to_socket).position:
			errors.append("Socket tidak sejajar.")
		for pair in [[connection.from, connection.from_socket], [connection.to, connection.to_socket]]:
			var socket_key := str(pair)
			if used.has(socket_key):
				errors.append("Socket dipakai lebih dari sekali.")
			used[socket_key] = true
		for room in rooms:
			if room.index not in [connection.from, connection.to] and connection.region.grow(16).intersects(room.bounds):
				errors.append("Koridor memotong ruangan lain.")
		for j in range(i):
			if connection.region.grow(16).intersects(connections[j].region):
				errors.append("Koridor bertabrakan.")
	var air := rasterize(candidate.regions)
	if candidate.shell != build_shell(air):
		errors.append("Shell tidak sesuai ruang terbuka.")
	var first := Vector2i(floori(candidate.spawn.x / TILE), floori(candidate.spawn.y / TILE))
	var reached := {first: true}
	var pending: Array[Vector2i] = [first]
	var head := 0
	while head < pending.size():
		var cell := pending[head]
		head += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if air.has(next) and not reached.has(next):
				reached[next] = true
				pending.append(next)
	if reached.size() != air.size():
		errors.append("Ada ruang fisik yang terputus.")
	for point in [candidate.spawn, candidate.exit, candidate.reward] + candidate.enemies:
		if not reached.has(Vector2i(floori(point.x / TILE), floori(point.y / TILE))):
			errors.append("Marker di luar ruang yang terhubung.")
	var routes: Array = [candidate.route]
	for branch in candidate.branches:
		routes.append(branch.route)
		routes.append(branch.return_route)
	for path in routes:
		for i in range(path.size()):
			var surface: Rect2 = path[i]
			var supported := false
			for ground in candidate.shell + candidate.platforms:
				if ground.position.y == surface.position.y and ground.position.x <= surface.get_center().x and ground.end.x >= surface.get_center().x:
					supported = true
			if not supported:
				errors.append("Lantai/platform jalur hilang.")
			if i > 0:
				var previous: Rect2 = path[i - 1]
				var gap := maxf(0, maxf(surface.position.x - previous.end.x, previous.position.x - surface.end.x))
				if previous.position.y - surface.position.y > 40 or gap > 24:
					errors.append("Jalur membutuhkan lompatan di luar kemampuan dasar.")
	return errors

func prepare(seed_value: int) -> bool:
	layout = generate_layout(seed_value)
	var errors := validate_layout(layout)
	if not errors.is_empty():
		push_error("Coastal ditolak: " + "; ".join(errors))
		return false
	for child in get_children():
		remove_child(child)
		child.free()
	exit_open = false
	var backdrop := BACKDROP.new()
	backdrop.name = "Backdrop"
	backdrop.layout = layout
	backdrop.z_as_relative = false
	backdrop.z_index = -10
	add_child(backdrop)
	set_meta("playable_bounds", layout.bounds)
	set_meta("map_regions", layout.regions)
	for rect in layout.shell:
		platform(rect, false)
	for rect in layout.platforms:
		platform(rect, true)
	for data in layout.rooms:
		if not data.template.decoration_scene.is_empty():
			var scene := load(data.template.decoration_scene) as PackedScene
			if scene != null:
				var decoration := scene.instantiate() as Node2D
				if decoration != null:
					var holder := Node2D.new()
					holder.name = "ManualDecor_%d" % data.id if data.has("id") else "ManualDecor_%d" % layout.rooms.find(data)
					holder.position = data.position
					holder.z_index = -5
					holder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					holder.add_child(decoration)
					add_child(holder)
					# Remove paint over an open down socket (or outside the floor).
					var floor_tiles := decoration.get_node_or_null("FloorTiles") as TileMapLayer
					if floor_tiles != null:
						floor_tiles.visible = data.template.manual_floor
						for cell in floor_tiles.get_used_cells():
							var point := floor_tiles.to_global(floor_tiles.map_to_local(cell)) - global_position
							var solid := false
							for rect in layout.shell:
								if rect.has_point(point) and is_equal_approx(point.y, data.position.y + data.height + 8):
									solid = true
									break
							if not solid:
								floor_tiles.erase_cell(cell)
		var title := "RUANG HARTA" if data.kind == "treasure" else str(data.title)
		path_label(data.position + Vector2(24, 16), title, Color(0.4, 0.7, 0.7))
	for i in range(layout.branches.size()):
		var branch: Dictionary = layout.branches[i]
		var chest := TREASURE.new()
		chest.name = "OptionalTreasure" if i == 0 else "BonusTreasure"
		chest.position = branch.treasure
		add_child(chest)
		path_label(branch.sign, "TREASURE\nLihat peta [M]", Color(1, 0.8, 0.35))
	marker(self, "PlayerSpawn", layout.spawn)
	marker(self, "RewardSpawn", layout.reward)
	var doors := Node2D.new()
	doors.name = "DoorSpawns"
	add_child(doors)
	marker(doors, "Exit", layout.exit)
	var enemies := Node2D.new()
	enemies.name = "EnemySpawns"
	add_child(enemies)
	for i in range(layout.enemies.size()):
		marker(enemies, "Enemy%d" % i, layout.enemies[i])
	path_label(layout.exit + Vector2(-96, -64), "EXIT\nKalahkan semua musuh", Color(0.4, 0.9, 0.85)).name = "ExitHint"
	var map_overlay := MAP.new()
	map_overlay.name = "CoastalMap"
	map_overlay.room = self
	add_child(map_overlay)
	return true

func path_label(point: Vector2, text: String, color: Color) -> Label:
	var label := Label.new()
	label.position = point
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	return label

func open_exit() -> void:
	exit_open = true
	$ExitHint.text = "EXIT TERBUKA"

func marker(parent: Node, marker_name: String, point: Vector2) -> void:
	var node := Marker2D.new()
	node.name = marker_name
	node.position = point
	parent.add_child(node)

func platform(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.position = rect.size / 2
	collider.shape = shape
	collider.one_way_collision = one_way
	body.add_child(collider)
	if one_way:
		var art := preload("res://Script/Stage/coastal_platform_art.gd").new()
		art.platform_size = rect.size
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.add_child(art)
