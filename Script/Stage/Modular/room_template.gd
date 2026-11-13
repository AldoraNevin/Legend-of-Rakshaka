@tool
extends Node2D
## Runtime never repaints Solid, Platforms, Backdrop or Decorations.
## Only SocketCaps is opened, and only at sockets chosen by the solver.
const TILE := 16
@export var room_id := "room"
@export var roles := PackedStringArray(["combat"])
@export_range(0.01, 10.0) var selection_weight := 1.0
@export var size_in_tiles := Vector2i(40, 12)

func describe() -> Dictionary:
	var sockets: Array[Dictionary] = []
	for socket in $Sockets.get_children():
		var cap_x := 0 if socket.side == "left" else size_in_tiles.x - 1
		var floor_y := roundi(socket.position.y / TILE) + 2
		var cells: Array[Vector2i] = []
		for y in range(floor_y - 4, floor_y):
			cells.append(Vector2i(cap_x, y))
		sockets.append({"id": str(socket.name), "side": socket.side,
			"position": socket.position, "caps": cells, "floor_y": floor_y})
	var markers := {}
	for marker_name in ["PlayerSpawn", "RewardSpawn"]:
		var marker := get_node_or_null(marker_name) as Marker2D
		if marker != null:
			markers[marker_name] = marker.position
	var enemies: Array[Vector2] = []
	for marker in $EnemySpawns.get_children():
		enemies.append(marker.position)
	return {"id": room_id, "roles": roles, "weight": selection_weight,
		"size": size_in_tiles, "sockets": sockets, "markers": markers,
		"enemies": enemies, "solid": cells_of($Solid), "platforms": cells_of($Platforms),
		"caps": cells_of($SocketCaps)}

static func cells_of(layer: TileMapLayer) -> Dictionary:
	var cells := {}
	for cell in layer.get_used_cells():
		cells[cell] = true
	return cells

func open_sockets(names: Array) -> void:
	for socket in describe().sockets:
		if socket.id in names:
			for cell in socket.caps:
				$SocketCaps.erase_cell(cell)

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if size_in_tiles.x < 8 or size_in_tiles.y < 7 or selection_weight <= 0 or roles.is_empty():
		errors.append(room_id + ": invalid size, selection weight or empty Roles.")
	if rotation != 0 or skew != 0 or scale != Vector2.ONE:
		errors.append(room_id + ": room root must not be rotated or scaled.")
	for child_name in ["Solid", "Platforms", "SocketCaps", "Backdrop"]:
		var layer := get_node_or_null(child_name) as TileMapLayer
		if layer == null or layer.tile_set == null:
			errors.append(room_id + ": missing TileMapLayer " + child_name)
			continue
		if layer.transform != Transform2D.IDENTITY or layer.tile_set.tile_size != Vector2i(16, 16):
			errors.append(room_id + ": layers must use 16px tiles, position 0, scale 1.")
		if child_name != "Backdrop" and (not layer.visible or not layer.collision_enabled or not layer.enabled):
			errors.append(room_id + ": collision layers must be visible and enabled.")
		if child_name == "Backdrop" and layer.collision_enabled:
			errors.append(room_id + ": Backdrop must have collision disabled.")
		for cell in layer.get_used_cells():
			if not Rect2i(Vector2i.ZERO, size_in_tiles).has_point(cell):
				errors.append(room_id + ": tile outside Size In Tiles: " + str(cell))
			if child_name == "Backdrop":
				continue
			var data := layer.get_cell_tile_data(cell)
			if data == null:
				errors.append(room_id + ": collision layers require atlas tiles.")
				continue
			if layer.tile_set.get_physics_layers_count() == 0 or layer.tile_set.get_physics_layer_collision_layer(0) != 2:
				errors.append(room_id + ": collision TileSet must use Ground/layer 2.")
				break
			if data.get_collision_polygons_count(0) == 0:
				errors.append(room_id + ": painted collision tile has no polygon: " + str(cell))
			elif data.is_collision_polygon_one_way(0, 0) != (child_name == "Platforms"):
				errors.append(room_id + ": only Platforms may use one-way collision.")
			else:
				var polygon := data.get_collision_polygon_points(0, 0)
				var full_cell := polygon.size() == 4
				for corner in [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]:
					full_cell = full_cell and corner in polygon
				if not full_cell or data.get_collision_polygons_count(0) != 1:
					errors.append(room_id + ": use full 16px block polygons; slopes need a different navigation validator.")
	if not errors.is_empty():
		return errors
	if get_node_or_null("Sockets") == null or get_node_or_null("EnemySpawns") == null:
		return PackedStringArray([room_id + ": missing Sockets/EnemySpawns."])
	for group_name in ["Sockets", "EnemySpawns"]:
		var group := get_node(group_name) as Node2D
		if group == null or group.transform != Transform2D.IDENTITY:
			errors.append(room_id + ": marker groups must have identity transforms.")
		for child in get_node(group_name).get_children():
			if not child is Marker2D:
				errors.append(room_id + ": marker groups may contain only Marker2D children.")
			elif group_name == "Sockets" and child.get("side") not in ["left", "right"]:
				errors.append(room_id + ": socket needs room_socket.gd and a left/right side.")
	if not errors.is_empty():
		return errors
	var data := describe()
	var required_sockets := 4 if "junction" in roles else (2 if "combat" in roles else 1)
	if data.sockets.size() < required_sockets:
		errors.append(room_id + ": not enough sockets for its Roles.")
	var expected_caps := {}
	for socket in data.sockets:
		var edge_x := 0 if socket.side == "left" else size_in_tiles.x * TILE
		if socket.position.x != edge_x or fposmod(socket.position.y, TILE) != 0:
			errors.append(room_id + ": socket must sit on room edge and 16px grid.")
		for cell in socket.caps:
			if expected_caps.has(cell) or data.solid.has(cell) or not data.caps.has(cell):
				errors.append(room_id + ": socket opening must contain only its four SocketCaps tiles.")
			expected_caps[cell] = true
		var inside_x := 1 if socket.side == "left" else size_in_tiles.x - 2
		for y in range(socket.floor_y - 4, socket.floor_y):
			if data.solid.has(Vector2i(inside_x, y)):
				errors.append(room_id + ": socket headroom blocked.")
		if not data.solid.has(Vector2i(inside_x, socket.floor_y)) and not data.platforms.has(Vector2i(inside_x, socket.floor_y)):
			errors.append(room_id + ": socket needs an interior landing.")
	if expected_caps.size() != data.caps.size():
		errors.append(room_id + ": SocketCaps may contain only socket openings.")
	var closed: Dictionary = data.solid.duplicate()
	closed.merge(data.caps)
	for x in range(size_in_tiles.x):
		if not closed.has(Vector2i(x, 0)) or not closed.has(Vector2i(x, size_in_tiles.y - 1)):
			errors.append(room_id + ": ceiling/floor boundary is open.")
	for y in range(size_in_tiles.y):
		if not closed.has(Vector2i(0, y)) or not closed.has(Vector2i(size_in_tiles.x - 1, y)):
			errors.append(room_id + ": side boundary is open outside a socket.")
	for point in data.markers.values() + data.enemies:
		var foot := Vector2i(floori(point.x / TILE), roundi((point.y + 32) / TILE))
		if not Rect2(Vector2.ZERO, Vector2(size_in_tiles * TILE)).has_point(point):
			errors.append(room_id + ": marker outside bounds.")
		if not data.solid.has(foot) and not data.platforms.has(foot):
			errors.append(room_id + ": markers must be 32px above a landing.")
		if closed.has(foot + Vector2i.UP) or closed.has(foot + Vector2i.UP * 2):
			errors.append(room_id + ": marker headroom is blocked.")
	for required in ["PlayerSpawn", "RewardSpawn"]:
		if not data.markers.has(required):
			errors.append(room_id + ": missing " + required)
	return errors
