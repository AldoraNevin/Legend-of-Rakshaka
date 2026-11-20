extends Control
var room: Node2D
var portal_network: Node2D
const FOG_CELL := 64.0
const SIGHT_RADIUS := 200.0
var explored: Dictionary = {}
var spotted_enemies: Dictionary = {}
var survey_timer := 0.0

func fog_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / FOG_CELL), floori(point.y / FOG_CELL))

func is_explored(point: Vector2) -> bool:
	return explored.has(fog_cell(point))

func reveal_at(point: Vector2) -> void:
	var center := fog_cell(point)
	for y in range(-3, 4):
		for x in range(-3, 4):
			var cell := center + Vector2i(x, y)
			if (Vector2(cell) * FOG_CELL + Vector2.ONE * FOG_CELL * 0.5).distance_to(point) <= SIGHT_RADIUS:
				explored[cell] = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(room) or get_tree().paused:
		return
	survey_timer -= delta
	if survey_timer > 0:
		return
	survey_timer = 0.15
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var local_player := room.to_local(player.global_position)
	reveal_at(local_player)
	reveal_exit_area()
	for enemy in get_tree().get_nodes_in_group("artifact_enemies"):
		if not enemy is Node2D or enemy.is_queued_for_deletion() or enemy.get("health") <= 0:
			continue
		if player.global_position.distance_to(enemy.global_position) > SIGHT_RADIUS:
			continue
		var ray := PhysicsRayQueryParameters2D.create(sight_position(player), sight_position(enemy), 2)
		if not room.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		# A detected target must not remain hidden by a boundary fog cell.
		explored[fog_cell(room.to_local(enemy.global_position))] = true
		spotted_enemies[enemy.get_instance_id()] = {"node": weakref(enemy), "position": room.to_local(enemy.global_position)}
	for id in spotted_enemies.keys():
		var enemy = spotted_enemies[id].node.get_ref()
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("health") <= 0:
			spotted_enemies.erase(id)
	if visible:
		queue_redraw()

var map_scale := 1.0
var map_offset := Vector2.ZERO
const MAIN := Color(0.3, 0.85, 0.8)
const GOLD := Color(1, 0.76, 0.3)

func reveal_exit_area() -> void:
	if is_instance_valid(room):
		var exit_marker := room.get_node_or_null("DoorSpawns/Exit") as Node2D
		if exit_marker != null:
			reveal_at(room.to_local(exit_marker.global_position))

func _ready() -> void:
	reveal_exit_area()
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func map_point(point: Vector2) -> Vector2:
	return map_offset + point * map_scale

func _draw() -> void:
	if room == null or room.layout.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.015, 0.035, 0.05))
	var font := ThemeDB.fallback_font
	var title := "PETA RERUNTUHAN" if room.get_meta("modular_level", false) else "PETA PESISIR"
	if portal_network != null:
		title = "PORTAL - PILIH TUJUAN"
	draw_string(font, Vector2(24, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MAIN)
	draw_string(font, Vector2(viewport_size.x - 240, 36), "SEED  %s" % room.layout.seed, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.7, 0.8))
	draw_string(font, Vector2(24, 60), ("Klik / tap lingkaran biru untuk teleport. Esc: kembali" if portal_network != null else "M / Esc: kembali bermain  |  Game dijeda"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var bounds: Rect2 = room.get_meta("playable_bounds")
	update_projection()
	# Physical space and collision geometry are copied from the built scene.
	# Graph edges are deliberately not used to draw corridors or room outlines.
	for region in room.get_meta("map_regions", []):
		draw_rect(Rect2(map_point(region.position), region.size * map_scale), Color(0.18, 0.26, 0.64))
	for surface in collect_surfaces():
		var points := PackedVector2Array()
		for point in surface.points:
			points.append(map_point(point))
		var color := Color(0.65, 0.61, 0.88) if surface.one_way else Color(0.87, 0.89, 0.95)
		draw_colored_polygon(points, color)
		if surface.one_way:
			draw_line(points[0], points[1], color, 1.5)
	draw_fog(bounds)
	map_marker(room.get_node("PlayerSpawn").position, "IN", MAIN)
	map_marker(room.get_node("DoorSpawns/Exit").position, "EXIT" if room.exit_open else "EXIT x", Color(0.5, 1, 0.5) if room.exit_open else Color(1, 0.5, 0.4), true)
	for chest_name in ["OptionalTreasure", "BonusTreasure"]:
		var chest := room.get_node_or_null(chest_name) as Node2D
		if chest != null:
			map_marker(chest.position, "Peti kosong" if chest.opened else "Treasure", GOLD)
	var rewards := room.get_node_or_null("Rewards")
	if rewards != null:
		for reward in rewards.get_children():
			var artifact: bool = reward.reward_kind == "artifact"
			map_marker(reward.position, "Diambil" if reward.opened else ("Artefak" if artifact else "Treasure"), Color(0.4, 0.85, 1) if artifact else GOLD)
	var network := room.get_node_or_null("PortalNetwork")
	if network != null:
		for portal in network.portals:
			if portal.unlocked:
				var position_on_map := map_point(room.to_local(portal.global_position))
				var is_source: bool = portal_network != null and portal == network.portals[network.source]
				var color := Color(1, 0.8, 0.2) if is_source else Color(0.25, 0.85, 1)
				draw_circle(position_on_map, 13 if portal_network != null else 6, Color(color, 0.3))
				draw_arc(position_on_map, 13 if portal_network != null else 6, 0, TAU, 24, color, 2)
				if portal_network != null:
					draw_string(font, position_on_map + Vector2(16, 28 if is_source else -12), portal.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
	for entry in spotted_enemies.values():
		if is_explored(entry.position):
			draw_circle(map_point(entry.position), 4, Color(1, 0.15, 0.15))
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var point := map_point(room.to_local(player.global_position))
		draw_circle(point, 6, Color.WHITE)
		draw_circle(point, 3, Color(0.2, 0.65, 1))
	draw_string(font, Vector2(24, viewport_size.y - 42), "Biru: ruang level   |   Putih: lantai/dinding   |   Ungu: platform", HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(24, viewport_size.y - 20), "Putih: kamu | Merah: musuh terakhir terlihat | Gelap: belum dijelajahi", HORIZONTAL_ALIGNMENT_LEFT, -1, 13)

func collect_surfaces() -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	if room.get_meta("modular_level", false):
		# These rectangles are read from the authored collision TileMaps at generation.
		for one_way in [false, true]:
			for rect: Rect2 in room.layout.platforms if one_way else room.layout.shell:
				surfaces.append({"points": PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), "one_way": one_way})
		return surfaces
	for collider in room.find_children("*", "CollisionShape2D", true, false):
		if collider.disabled or not collider.get_parent() is StaticBody2D or not collider.shape is RectangleShape2D:
			continue
		var half: Vector2 = collider.shape.size / 2.0
		var points := PackedVector2Array()
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
			points.append(room.to_local(collider.to_global(corner)))
		surfaces.append({"points": points, "one_way": collider.one_way_collision})
	return surfaces

func map_marker(point: Vector2, title: String, color: Color, always_visible := false) -> void:
	if not always_visible and not is_explored(point):
		return
	var position_on_map := map_point(point)
	draw_rect(Rect2(position_on_map - Vector2(3, 3), Vector2(6, 6)), color)
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var text_position := position_on_map + Vector2(8, -7)
	text_position.x = clampf(text_position.x, 12, get_viewport_rect().size.x - text_width - 12)
	draw_string(font, text_position, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func draw_fog(bounds: Rect2) -> void:
	var first := fog_cell(bounds.position)
	var last := fog_cell(bounds.end)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if explored.has(cell):
				continue
			var area := Rect2(Vector2(cell) * FOG_CELL, Vector2.ONE * FOG_CELL).intersection(bounds)
			draw_rect(Rect2(map_point(area.position), area.size * map_scale + Vector2.ONE), Color(0.015, 0.035, 0.05))

func sight_position(actor: Node2D) -> Vector2:
	# Body origins may sit at the feet; cast from the body's collision center.
	for child in actor.get_children():
		if child is CollisionShape2D and not child.disabled and child.shape != null:
			return child.global_position
	return actor.global_position

func update_projection() -> void:
	var viewport_size := get_viewport_rect().size
	var bounds: Rect2 = room.get_meta("playable_bounds")
	map_scale = minf((viewport_size.x - 48) / bounds.size.x, (viewport_size.y - 170) / bounds.size.y)
	map_offset = (viewport_size - bounds.size * map_scale) / 2 - bounds.position * map_scale + Vector2(0, 12)

func _gui_input(event: InputEvent) -> void:
	if portal_network == null or not visible:
		return
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	update_projection()
	var target := -1
	var nearest := 24.0
	for i in range(portal_network.portals.size()):
		var portal = portal_network.portals[i]
		if not portal.unlocked or i == portal_network.source:
			continue
		var distance := point.distance_to(map_point(room.to_local(portal.global_position)))
		if distance < nearest:
			nearest = distance
			target = i
	accept_event()
	if target >= 0:
		portal_network.teleport(target)
