extends Control
var room: Node2D
var map_scale := 1.0
var map_offset := Vector2.ZERO
const MAIN := Color(0.3, 0.85, 0.8)
const GOLD := Color(1, 0.76, 0.3)

func _ready() -> void:
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
	draw_string(font, Vector2(24, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MAIN)
	draw_string(font, Vector2(viewport_size.x - 240, 36), "SEED  %s" % room.layout.seed, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.7, 0.8))
	draw_string(font, Vector2(24, 60), "M / Esc: kembali bermain  |  Game dijeda", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var bounds: Rect2 = room.get_meta("playable_bounds")
	map_scale = minf((viewport_size.x - 48) / bounds.size.x, (viewport_size.y - 170) / bounds.size.y)
	map_offset = (viewport_size - bounds.size * map_scale) / 2 - bounds.position * map_scale + Vector2(0, 12)
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
	map_marker(room.get_node("PlayerSpawn").position, "IN", MAIN)
	map_marker(room.get_node("DoorSpawns/Exit").position, "EXIT" if room.exit_open else "EXIT x", Color(0.5, 1, 0.5) if room.exit_open else Color(1, 0.5, 0.4))
	for chest_name in ["OptionalTreasure", "BonusTreasure"]:
		var chest := room.get_node_or_null(chest_name) as Node2D
		if chest != null:
			map_marker(chest.position, "Peti kosong" if chest.opened else "Treasure", GOLD)
	var rewards := room.get_node_or_null("Rewards")
	if rewards != null:
		for reward in rewards.get_children():
			var artifact: bool = reward.reward_kind == "artifact"
			map_marker(reward.position, "Diambil" if reward.opened else ("Artefak" if artifact else "Treasure"), Color(0.4, 0.85, 1) if artifact else GOLD)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var point := map_point(room.to_local(player.global_position))
		draw_circle(point, 6, Color.WHITE)
		draw_circle(point, 3, Color(0.2, 0.65, 1))
	draw_string(font, Vector2(24, viewport_size.y - 42), "Biru: ruang level   |   Putih: lantai/dinding   |   Ungu: platform", HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(24, viewport_size.y - 20), "Titik putih: posisi kamu. Denah mengikuti geometri level yang sedang dimainkan.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13)

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

func map_marker(point: Vector2, title: String, color: Color) -> void:
	var position_on_map := map_point(point)
	draw_rect(Rect2(position_on_map - Vector2(3, 3), Vector2(6, 6)), color)
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var text_position := position_on_map + Vector2(8, -7)
	text_position.x = clampf(text_position.x, 12, get_viewport_rect().size.x - text_width - 12)
	draw_string(font, text_position, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
