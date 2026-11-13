extends "res://Tools/build_modular_examples.gd"
## Bake once; gameplay reads the saved, editable TileMap scene.
func _initialize() -> void:
	if FileAccess.file_exists(DIRECTORY + "hall_buatan.tscn"):
		push_error("hall_buatan already exists; edit the scene directly.")
		quit(1)
		return
	# Normalize the existing 64px coastal atlas to the gameplay's 16px grid.
	var pixels := load("res://Assets/Tileset/Sprites/coastal_packed.png").get_image() as Image
	pixels.resize(128, 96, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(pixels)
	ResourceSaver.save(texture, "res://Assets/Tileset/pantai_modular_texture.tres")
	for one_way in [false, true]:
		var tiles := make_tiles(one_way)
		var atlas := tiles.get_source(0) as TileSetAtlasSource
		atlas.texture = load("res://Assets/Tileset/pantai_modular_texture.tres")
		var path := "res://Assets/Tileset/pantai_modular_platforms.tres" if one_way else "res://Assets/Tileset/pantai_modular_solid.tres"
		ResourceSaver.save(tiles, path)
		if one_way:
			platform_tiles = load(path)
		else:
			solid_tiles = load(path)
	var room: Node2D = load(DIRECTORY + "hall.tscn").instantiate()
	room.name = "HallBuatan"
	room.room_id = "hall_buatan"
	room.roles = PackedStringArray(["combat", "junction"])
	room.selection_weight = 2.5
	room.size_in_tiles = Vector2i(48, 30)
	for name in ["Solid", "Platforms", "Backdrop", "Decorations", "SocketCaps"]:
		room.get_node(name).clear()
	var solid := room.get_node("Solid") as TileMapLayer
	var platforms := room.get_node("Platforms") as TileMapLayer
	var caps := room.get_node("SocketCaps") as TileMapLayer
	solid.tile_set = solid_tiles
	caps.tile_set = solid_tiles
	platforms.tile_set = platform_tiles
	for group in ["Sockets", "EnemySpawns"]:
		for child in room.get_node(group).get_children():
			child.free()
	for x in range(48):
		for y in range(30):
			room.get_node("Backdrop").set_cell(Vector2i(x, y), 0, Vector2i(x % 8, 2))
			if x == 0 or x == 47 or y == 0 or y == 29:
				solid.set_cell(Vector2i(x, y), 0, Vector2i(2 if y == 29 else 4, 0 if y == 29 else 1))
	# Two solid decks leave climbing wells on opposite sides: a traversable S route.
	for x in range(1, 37):
		solid.set_cell(Vector2i(x, 19), 0, Vector2i(2, 0))
	for x in range(11, 47):
		solid.set_cell(Vector2i(x, 9), 0, Vector2i(2, 0))
	for y in [21, 23, 25, 27]:
		paint_platform(platforms, 38 if y % 4 == 1 else 42, y, 5)
	for y in [11, 13, 15, 17]:
		paint_platform(platforms, 6 if y % 4 == 3 else 2, y, 5)
	paint_platform(platforms, 1, 9, 6)
	paint_platform(platforms, 43, 19, 4)
	# Optional low balconies enrich combat without closing the main floor.
	paint_platform(platforms, 15, 27, 7)
	paint_platform(platforms, 23, 17, 7)
	for floor_y in [29, 19, 9]:
		for side in ["left", "right"]:
			var socket := Marker2D.new()
			socket.set_script(SOCKET)
			socket.side = side
			socket.name = side.to_pascal_case() + str(floor_y)
			socket.position = Vector2(0 if side == "left" else 768, (floor_y - 2) * 16)
			add_owned(room.get_node("Sockets"), socket, room)
			var x := 0 if side == "left" else 47
			for y in range(floor_y - 4, floor_y):
				solid.erase_cell(Vector2i(x, y))
				caps.set_cell(Vector2i(x, y), 0, Vector2i(4, 1))
	room.get_node("PlayerSpawn").position = Vector2(64, 432)
	room.get_node("RewardSpawn").position = Vector2(544, 112)
	marker(room.get_node("EnemySpawns"), room, "LowerGuard", Vector2(480, 432))
	marker(room.get_node("EnemySpawns"), room, "MiddleGuard", Vector2(256, 272))
	marker(room.get_node("EnemySpawns"), room, "UpperGuard", Vector2(352, 112))
	var props := Node2D.new()
	props.name = "CoastalProps"
	props.z_index = -2
	add_owned(room, props, room)
	var art := preload("res://Script/Stage/coastal_asset_art.gd")
	for floor_y in [9, 19, 29]:
		for x in [14, 32]:
			var prop: Sprite2D = art.prop(2 if x == 14 else 4, Vector2(x * 16, floor_y * 16))
			add_owned(props, prop, room)
	var errors: PackedStringArray = room.validate()
	assert(errors.is_empty(), str(errors))
	var packed := PackedScene.new()
	packed.pack(room)
	ResourceSaver.save(packed, DIRECTORY + "hall_buatan.tscn")
	var config: Resource = load(DIRECTORY + "default_level_settings.tres")
	config.room_templates.append(load(DIRECTORY + "hall_buatan.tscn"))
	config.main_rooms_min = 12
	config.main_rooms_max = 15
	config.treasure_rooms = 3
	config.branch_combat_min = 1
	config.branch_combat_max = 2
	config.upward_bias = 0.7
	ResourceSaver.save(config, DIRECTORY + "default_level_settings.tres")
	room.free()
	print("Saved coastal hall with 3 floors, 6 sockets, editable platforms and catalog registration.")
	quit()

func paint_platform(layer_node: TileMapLayer, x: int, y: int, width: int) -> void:
	for offset in range(width):
		layer_node.set_cell(Vector2i(x + offset, y), 0, Vector2i(2, 0))
