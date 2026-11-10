@tool
extends Node2D
const ROUTES = preload("res://Script/Stage/coastal_routes.gd")
@export var preview_up_socket := true
@export var preview_down_socket := true
@export var show_tiles := true
## Open coastal_template_preview.tscn and assign any catalog template here.
@export var template: Resource:
	set(value):
		template = value
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if template == null or not template.has_method("validate"):
		return
	for rect in template.air_regions:
		draw_rect(rect, Color(0.12, 0.25, 0.4))
		if show_tiles:
			draw_tiles(rect, 2)
	var used: Array[String] = []
	if preview_up_socket:
		used.append("up")
	if preview_down_socket:
		used.append("down")
	var room := {"template": template, "position": Vector2.ZERO, "width": template.size.x,
		"height": template.size.y, "floor": template.size.y, "used_sockets": used}
	for platform in ROUTES.interior(room) + ROUTES.climb(room):
		draw_rect(platform, Color(0.7, 0.75, 0.6))
		if show_tiles:
			draw_tiles(platform, 0)
	draw_rect(Rect2(Vector2.ZERO, template.size), Color(0.5, 0.5, 0.5), false, 1)
	var font := ThemeDB.fallback_font
	for socket in template.sockets:
		var tangent := Vector2.RIGHT if socket.side in ["up", "down"] else Vector2.DOWN
		draw_line(socket.position - tangent * socket.opening / 2, socket.position + tangent * socket.opening / 2, Color(0.3, 1, 0.7), 3)
		draw_circle(socket.position, 5, Color(1, 0.8, 0.3))
		draw_string(font, socket.position + Vector2(8, -10), socket.side, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_circle(template.anchor, 6, Color.WHITE)
	draw_string(font, Vector2(0, -40), template.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var errors: PackedStringArray = template.validate()
	draw_string(font, Vector2(0, template.size.y + 40), "Template valid" if errors.is_empty() else errors[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN if errors.is_empty() else Color.RED)

func draw_tiles(rect: Rect2, row: int) -> void:
	if row == 0:
		preload("res://Script/Stage/coastal_asset_art.gd").draw_surface(self, rect, true, true)
		return
	var atlas := ROUTES.STYLE.tileset.get_source(0) as TileSetAtlasSource
	for x in range(0, int(rect.size.x), 16):
		for y in range(0, int(rect.size.y), 16):
			var tile_size := Vector2(minf(16, rect.size.x - x), minf(16, rect.size.y - y))
			var source := Rect2(atlas.get_tile_texture_region(Vector2i((x / 16) % 8, row)))
			source.size = tile_size
			draw_texture_rect_region(atlas.texture, Rect2(rect.position + Vector2(x, y), tile_size), source)
