extends SceneTree
## One-time authoring helper. The saved .tscn files are the runtime source of truth.
## Existing hand-edited examples are protected unless --overwrite-examples is supplied.
const DIRECTORY := "res://Scenes/Rooms/Modular/"
const TEMPLATE = preload("res://Script/Stage/Modular/room_template.gd")
const SOCKET = preload("res://Script/Stage/Modular/room_socket.gd")
const SETTINGS = preload("res://Script/Stage/Modular/level_settings.gd")
const TEXTURE = preload("res://Assets/Tileset/Sprites/coastal_ruins.png")
var solid_tiles: TileSet
var platform_tiles: TileSet
var scenes: Array[PackedScene] = []

func _initialize() -> void:
	if FileAccess.file_exists(DIRECTORY + "entrance.tscn") and "--overwrite-examples" not in OS.get_cmdline_user_args():
		push_error("Examples already exist. Edit the .tscn files directly; baking again requires --overwrite-examples.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	solid_tiles = make_tiles(false)
	platform_tiles = make_tiles(true)
	ResourceSaver.save(solid_tiles, "res://Assets/Tileset/modular_solid.tres")
	ResourceSaver.save(platform_tiles, "res://Assets/Tileset/modular_platforms.tres")
	solid_tiles = load("res://Assets/Tileset/modular_solid.tres")
	platform_tiles = load("res://Assets/Tileset/modular_platforms.tres")
	make_room("entrance", ["entrance"], Vector2i(24, 12))
	make_room("hall", ["combat"], Vector2i(36, 12))
	make_room("long_gallery", ["combat"], Vector2i(52, 14), "gallery")
	make_room("vaulted_hall", ["combat"], Vector2i(42, 16), "vault")
	make_room("tower", ["junction"], Vector2i(16, 30), "tower")
	make_room("short_tower", ["junction"], Vector2i(16, 26), "tower")
	make_room("treasure", ["treasure"], Vector2i(22, 12), "reward")
	make_room("artifact", ["artifact"], Vector2i(26, 14), "reward")
	make_room("exit", ["exit"], Vector2i(24, 12))
	var settings := SETTINGS.new()
	settings.room_templates = scenes
	ResourceSaver.save(settings, DIRECTORY + "default_level_settings.tres")
	print("Saved 9 editable room scenes, 2 collision TileSets and default settings.")
	quit()

func make_tiles(one_way: bool) -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(16, 16)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0, 2)
	tiles.set_physics_layer_collision_mask(0, 0)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TEXTURE
	atlas.texture_region_size = Vector2i(16, 16)
	for y in range(2):
		for x in range(8):
			var cell := Vector2i(x, y)
			atlas.create_tile(cell)
			var data := atlas.get_tile_data(cell, 0)
			# Assigned after adding source so TileData knows the physics layer.
			data.modulate = Color.WHITE
	tiles.add_source(atlas, 0)
	for y in range(2):
		for x in range(8):
			var data := atlas.get_tile_data(Vector2i(x, y), 0)
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
			data.set_collision_polygon_one_way(0, 0, one_way)
			data.set_collision_polygon_one_way_margin(0, 0, 1.0)
	return tiles

func add_owned(parent: Node, child: Node, root_node: Node) -> void:
	parent.add_child(child)
	child.owner = root_node

func layer(root_node: Node2D, title: String, tiles: TileSet, z: int) -> TileMapLayer:
	var result := TileMapLayer.new()
	result.name = title
	result.tile_set = tiles
	result.z_index = z
	add_owned(root_node, result, root_node)
	return result

func marker(parent: Node, root_node: Node, title: String, point: Vector2) -> void:
	var result := Marker2D.new()
	result.name = title
	result.position = point
	add_owned(parent, result, root_node)

func make_room(id: String, roles: Array, size: Vector2i, style := "hall") -> void:
	var room := Node2D.new()
	room.set_script(TEMPLATE)
	room.name = id.to_pascal_case()
	room.room_id = id
	room.roles = PackedStringArray(roles)
	room.size_in_tiles = size
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := layer(room, "Backdrop", load("res://Assets/Tileset/coastal_tileset.tres"), -8)
	backdrop.modulate = Color(0.48, 0.57, 0.65)
	backdrop.collision_enabled = false
	var solid := layer(room, "Solid", solid_tiles, 0)
	var platforms := layer(room, "Platforms", platform_tiles, 1)
	var caps := layer(room, "SocketCaps", solid_tiles, 0)
	layer(room, "Decorations", load("res://Assets/Tileset/coastal_tileset.tres"), -3).collision_enabled = false
	var sockets := Node2D.new()
	sockets.name = "Sockets"
	add_owned(room, sockets, room)
	var enemies := Node2D.new()
	enemies.name = "EnemySpawns"
	add_owned(room, enemies, room)
	for x in range(size.x):
		for y in range(size.y):
			backdrop.set_cell(Vector2i(x, y), 0, Vector2i(x % 8, 2))
			var wall := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			if style in ["gallery", "vault"] and (x < 8 or x >= size.x - 8) and y < 5:
				wall = true
			if wall:
				solid.set_cell(Vector2i(x, y), 0, Vector2i(x % 8, 0 if y == size.y - 1 else 1))
	var floors := [size.y - 1, 5] if style == "tower" else [size.y - 1]
	for floor_y in floors:
		for side in ["left", "right"]:
			var socket := Marker2D.new()
			socket.set_script(SOCKET)
			socket.side = side
			socket.name = side.to_pascal_case() + ("High" if floor_y == 5 else "Low")
			socket.position = Vector2(0 if side == "left" else size.x * 16, (floor_y - 2) * 16)
			add_owned(sockets, socket, room)
			var x := 0 if side == "left" else size.x - 1
			for y in range(floor_y - 4, floor_y):
				solid.erase_cell(Vector2i(x, y))
				caps.set_cell(Vector2i(x, y), 0, Vector2i(4, 1))
	if style == "tower":
		for x in range(1, size.x - 1):
			if x not in [7, 8]:
				platforms.set_cell(Vector2i(x, 5), 0, Vector2i(x % 8, 0))
		for y in range(7, size.y - 1, 2):
			var start := 2 if ((y - 7) / 2) % 2 == 0 else 8
			for x in range(start, start + 6):
				platforms.set_cell(Vector2i(x, y), 0, Vector2i(x % 8, 0))
	elif style in ["gallery", "vault"]:
		for x in range(11, 18):
			platforms.set_cell(Vector2i(x, size.y - 3), 0, Vector2i(x % 8, 0))
		if style == "vault":
			for x in range(19, 25):
				platforms.set_cell(Vector2i(x, size.y - 5), 0, Vector2i(x % 8, 0))
	var spawn_x := 24.0 if style == "tower" else 64.0
	marker(room, room, "PlayerSpawn", Vector2(spawn_x, (size.y - 1) * 16 - 32))
	marker(room, room, "RewardSpawn", Vector2(size.x * 16 - 24 if style == "tower" else size.x * 8, (size.y - 1) * 16 - 32))
	if "combat" in roles:
		for x in [size.x - 8, size.x - 16]:
			marker(enemies, room, "Enemy%d" % x, Vector2(x * 16 + 8, (size.y - 1) * 16 - 32))
	# Restrained, authored wall ornamentation; no giant parallax over the level.
	var decor := room.get_node("Decorations") as TileMapLayer
	for x in range(5, size.x - 4, 10):
		decor.set_cell(Vector2i(x, 6 if style in ["gallery", "vault"] else 3), 0, Vector2i(0, 3))
	var errors: PackedStringArray = room.validate()
	if not errors.is_empty():
		push_error("; ".join(errors))
		quit(1)
		return
	var packed := PackedScene.new()
	packed.pack(room)
	ResourceSaver.save(packed, DIRECTORY + id + ".tscn")
	scenes.append(load(DIRECTORY + id + ".tscn"))
	room.free()
