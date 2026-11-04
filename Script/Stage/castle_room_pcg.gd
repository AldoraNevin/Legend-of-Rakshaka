extends Node2D
## Seed selects and connects complete hand-authored scenes, never scatters platforms.
const DIRECTORY := "res://Scenes/Rooms/Stage/Modules/"
const SURFACE := ["gallery", "crypt", "balcony", "library", "ruins", "bridge"]
const UNDERGROUND := ["underground", "sewer", "dungeon"]
const IDS := ["entrance", "gallery", "crypt", "balcony", "ascent", "descent", "exit", "underground", "sewer", "dungeon", "library", "ruins", "bridge"]
var layout: Dictionary = {}

static func module_data(id: String) -> Dictionary:
	var scene := load(DIRECTORY + id + ".tscn") as PackedScene
	var module := scene.instantiate() as Node2D
	var route: Array[Rect2] = []
	for body in module.get_node("MainPath").get_children():
		var shape := body.get_node("Shape") as CollisionShape2D
		var rectangle := shape.shape as RectangleShape2D
		route.append(Rect2(body.position + shape.position - rectangle.size / 2, rectangle.size))
	var result := {"id": id, "entry": module.get_node("Entry").position,
		"exit": module.get_node("Exit").position, "width": module.get_meta("width"), "route": route}
	module.free()
	return result

static func generate_layout(seed_value: int) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var surface: Array = SURFACE.duplicate()
	var underground: Array = UNDERGROUND.duplicate()
	for pool in [surface, underground]:
		for i in range(pool.size() - 1, 0, -1):
			var j := random.randi_range(0, i)
			var previous: String = pool[i]
			pool[i] = pool[j]
			pool[j] = previous
	# A coherent excursion underground, then a return to the castle above.
	var sequence: Array = ["entrance", surface[0], surface[1], "descent",
		underground[0], underground[1], "ascent", surface[2], "ascent", "exit"]
	var modules: Array[Dictionary] = []
	var route: Array[Rect2] = []
	var socket := Vector2(0, 864)
	for id in sequence:
		var data := module_data(id)
		data["position"] = socket - data.entry
		for rect in data.route:
			route.append(Rect2(rect.position + data.position, rect.size))
		socket = data.position + data.exit
		modules.append(data)
	return {"seed": seed_value, "modules": modules, "route": route}

static func validate_layout(candidate: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var modules: Array = candidate.get("modules", [])
	if modules.size() != 10:
		return PackedStringArray(["Jumlah modul harus 10."])
	if modules.front().id != "entrance" or modules.back().id != "exit":
		errors.append("Modul masuk/keluar tidak sesuai.")
	if modules[3].id != "descent" or modules[6].id != "ascent" or modules[4].id not in UNDERGROUND or modules[5].id not in UNDERGROUND:
		errors.append("Rute underground harus turun, melintasi dua ruang bawah tanah, lalu naik.")
	var reconstructed: Array[Rect2] = []
	var previous_exit := Vector2(0, 864)
	for module in modules:
		if module.id not in IDS:
			return PackedStringArray(["Modul tidak dikenal."])
		var authored := module_data(module.id)
		if module.entry != authored.entry or module.exit != authored.exit or module.route != authored.route or module.width != authored.width:
			errors.append("Data tidak sesuai scene modul.")
		if module.position + module.entry != previous_exit:
			errors.append("Socket modul tidak tersambung.")
		previous_exit = module.position + module.exit
		# All modules advance right; non-overlapping x intervals prevent room overlap.
		if module.entry.x != 0 or module.exit.x != module.width:
			errors.append("Lebar modul/socket tidak sesuai.")
		for rect in authored.route:
			reconstructed.append(Rect2(rect.position + module.position, rect.size))
	if candidate.get("route", []) != reconstructed:
		errors.append("Rute tidak sesuai geometri scene.")
	for i in range(1, reconstructed.size()):
		var source: Rect2 = reconstructed[i - 1]
		var target: Rect2 = reconstructed[i]
		var rise := source.position.y - target.position.y
		if absf(rise) > 32 or not is_equal_approx(source.end.x, target.position.x):
			errors.append("Jalur tidak tersambung atau kenaikan terlalu tinggi.")
		if target.size.x < 48:
			errors.append("Pijakan terlalu sempit.")
	return errors

func prepare(seed_value: int) -> bool:
	layout = generate_layout(seed_value)
	var errors := validate_layout(layout)
	if not errors.is_empty():
		push_error("Modular castle rejected: " + "; ".join(errors))
		return false
	for child in get_children():
		remove_child(child)
		child.free()
	var modules := Node2D.new()
	modules.name = "Modules"
	add_child(modules)
	var min_y := 864.0
	var max_y := 864.0
	var names := PackedStringArray()
	for data in layout.modules:
		var module := (load(DIRECTORY + data.id + ".tscn") as PackedScene).instantiate() as Node2D
		module.position = data.position
		modules.add_child(module)
		min_y = minf(min_y, data.position.y - 32)
		max_y = maxf(max_y, data.position.y + 384)
		names.append(data.id)
	var last: Dictionary = layout.modules.back()
	var width: float = last.position.x + last.width
	set_meta("playable_bounds", Rect2(0, min_y, width, max_y - min_y))
	add_wall(-24, min_y, max_y - min_y)
	add_wall(width, min_y, max_y - min_y)
	marker(self, "PlayerSpawn", Vector2(64, 830))
	marker(self, "RewardSpawn", last.position + Vector2(last.width - 224, 222))
	var doors := Node2D.new()
	doors.name = "DoorSpawns"
	add_child(doors)
	marker(doors, "Exit", last.position + Vector2(last.width - 96, 222))
	var enemies := Node2D.new()
	enemies.name = "EnemySpawns"
	add_child(enemies)
	for data in layout.modules:
		if data.id in SURFACE or data.id in UNDERGROUND:
			marker(enemies, data.id, data.position + Vector2(data.width - 64, 222))
	print("Castle modules seed=", seed_value, " | ", " -> ".join(names))
	return true

func marker(parent: Node, marker_name: String, point: Vector2) -> void:
	var node := Marker2D.new()
	node.name = marker_name
	node.position = point
	parent.add_child(node)

func add_wall(x: float, y: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, height)
	collider.position = shape.size / 2
	collider.shape = shape
	body.add_child(collider)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2(24, 0), Vector2(24, height), Vector2(0, height)])
	visual.color = Color(0.18, 0.14, 0.22)
	body.add_child(visual)
