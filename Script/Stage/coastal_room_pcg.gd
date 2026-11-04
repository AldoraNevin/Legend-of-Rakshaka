extends Node2D
const GRAPH = preload("res://Script/Stage/coastal_graph.gd")
const PROFILES = preload("res://Script/Stage/coastal_profiles.gd")
const BACKDROP = preload("res://Script/Stage/coastal_backdrop.gd")
const MAP = preload("res://Script/UI/coastal_map.gd")
const TREASURE = preload("res://Script/Interactables/coastal_treasure.gd")
const TILE := 16
var layout: Dictionary = {}
var exit_open := false
var return_currents: Array[Dictionary] = []

static func generate_layout(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var graph := GRAPH.generate(seed_value)
	var regions: Array[Rect2] = []
	var rooms: Array[Dictionary] = []
	var route: Array[Rect2] = []
	var platforms: Array[Rect2] = []
	var branches: Array[Dictionary] = []
	var x := 0.0
	var floor_y := 0.0
	var last_profile := -1
	for id in graph.main_path:
		var profile_index := rng.randi_range(0, PROFILES.PROFILES.size() - 1)
		if profile_index == last_profile:
			profile_index = (profile_index + 1) % PROFILES.PROFILES.size()
		last_profile = profile_index
		var profile: Dictionary = PROFILES.PROFILES[profile_index]
		var origin := Vector2(x, floor_y - profile.height)
		rooms.append({"index": id, "kind": graph.nodes[id].kind, "profile": profile_index,
			"position": origin, "floor": floor_y, "width": profile.width, "height": profile.height})
		regions.append_array(PROFILES.regions(profile, origin))
		route.append(Rect2(x, floor_y, profile.width, TILE))
		x += profile.width
		if id == graph.main_path.back():
			continue
		var steps := rng.randi_range(3, 7)
		# Alternating direction creates hills and valleys, with seeded amplitude.
		var direction := -1.0 if (id + (seed_value & 1)) % 2 == 0 else 1.0
		for step in range(steps + 1):
			var step_y := floor_y + direction * step * 32
			regions.append(Rect2(x, step_y - 128, 64, 128))
			route.append(Rect2(x, step_y, 64, TILE))
			x += 64
		floor_y += direction * steps * 32
	for edge in graph.edges:
		if edge.kind != "optional":
			continue
		var source: Dictionary = rooms[edge.from]
		var profile: Dictionary = PROFILES.PROFILES[source.profile]
		var branch_floor: float = source.position.y - profile.crown - 128
		var branch_origin: Vector2 = Vector2(source.position.x + 32, branch_floor - 160)
		var branch_width: float = source.width - 64
		var shaft_x: float = source.position.x + (source.width - 192) / 2.0
		regions.append(Rect2(branch_origin, Vector2(branch_width, 160)))
		# A real open shaft, with space beside its steps for a safe return drop.
		regions.append(Rect2(shaft_x, branch_floor - 64, 192, source.floor - branch_floor + 64))
		var branch_route: Array[Rect2] = [Rect2(shaft_x, source.floor, 192, TILE)]
		var y: float = source.floor - 32
		while y >= branch_floor:
			var step := Rect2(shaft_x + 24, y, 144, 8)
			platforms.append(step)
			branch_route.append(step)
			y -= 32
		branch_route.append(Rect2(branch_origin.x, branch_floor, shaft_x - branch_origin.x, TILE))
		var chest := Vector2(branch_origin.x + 48, branch_floor - 16)
		branches.append({"from": edge.from, "to": edge.to, "route": branch_route,
			"treasure": chest, "shaft": Rect2(shaft_x, branch_floor - 64, 192, source.floor - branch_floor + 64)})
		rooms.append({"index": edge.to, "kind": "treasure", "profile": -1,
			"position": branch_origin, "floor": branch_floor, "width": branch_width, "height": 160})
	var air := rasterize(regions)
	var shell := build_shell(air)
	var bounds := regions[0]
	for region in regions:
		bounds = bounds.merge(region)
	var first: Dictionary = rooms[0]
	var last: Dictionary = rooms[graph.main_path.back()]
	var enemies: Array[Vector2] = []
	for id in graph.main_path:
		if id > 0:
			enemies.append(Vector2(rooms[id].position.x + 64, rooms[id].floor - 34))
	return {"seed": seed_value, "graph": graph, "rooms": rooms, "regions": regions, "shell": shell,
		"platforms": platforms, "route": route, "branches": branches, "bounds": bounds.grow(TILE),
		"spawn": Vector2(first.position.x + 48, first.floor - 34),
		"exit": Vector2(last.position.x + last.width - 48, last.floor - 34),
		"reward": Vector2(last.position.x + last.width - 112, last.floor - 34), "enemies": enemies}

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
	var errors := GRAPH.validate(candidate.graph)
	var air := rasterize(candidate.regions)
	if candidate.shell != build_shell(air):
		errors.append("Shell tidak sesuai ruang terbuka.")
	# A flood fill checks actual air connectivity, independently of the graph.
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
		var cell := Vector2i(floori(point.x / TILE), floori(point.y / TILE))
		if not reached.has(cell):
			errors.append("Marker di luar ruang yang terhubung.")
	for i in range(candidate.route.size()):
		var surface: Rect2 = candidate.route[i]
		var sample := Vector2i(floori(surface.get_center().x / TILE), roundi(surface.position.y / TILE))
		if air.has(sample) or not air.has(sample + Vector2i.UP):
			errors.append("Jalur utama tidak memiliki lantai.")
		if i > 0:
			var previous: Rect2 = candidate.route[i - 1]
			if absf(surface.position.y - previous.position.y) > 32 or surface.position.x != previous.end.x:
				errors.append("Tangga utama di luar kemampuan lompat dasar.")
	for branch in candidate.branches:
		for step in branch.route.slice(1, -1):
			if step not in candidate.platforms:
				errors.append("Tangga cabang hilang.")
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
		var title := "RUANG HARTA" if data.kind == "treasure" else str(PROFILES.PROFILES[data.profile].name)
		path_label(data.position + Vector2(24, 16), title, Color(0.4, 0.7, 0.7))
	for i in range(layout.branches.size()):
		var branch: Dictionary = layout.branches[i]
		var chest := TREASURE.new()
		chest.name = "OptionalTreasure" if i == 0 else "BonusTreasure"
		chest.position = branch.treasure
		add_child(chest)
		path_label(Vector2(branch.shaft.position.x, branch.shaft.end.y - 80), "^ TREASURE\nJalur opsional", Color(1, 0.8, 0.35))
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
	var visual := Polygon2D.new()
	visual.color = Color(0.12, 0.31, 0.32) if one_way else Color(0.07, 0.22, 0.23)
	visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2(rect.size.x, 0), rect.size, Vector2(0, rect.size.y)])
	body.add_child(visual)
	var trim := Line2D.new()
	trim.points = PackedVector2Array([Vector2.ZERO, Vector2(rect.size.x, 0)])
	trim.width = 2
	trim.default_color = Color(0.3, 0.7, 0.65)
	body.add_child(trim)
