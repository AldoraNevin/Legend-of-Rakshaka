extends Node2D
## Visual art only; generated geometry owns all collisions.
const STYLE = preload("res://Assets/Tileset/coastal_style.tres")
const ART = preload("res://Script/Stage/coastal_asset_art.gd")
var layout: Dictionary = {}
var air := {}

func _ready() -> void:
	var sky := CanvasLayer.new()
	sky.name = "CoastalParallax"
	sky.layer = -100
	var art := preload("res://Script/Stage/coastal_parallax.gd").new()
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sky.add_child(art)
	add_child(sky)
	for rect in layout.regions:
		for x in range(int(rect.position.x / 16), int(rect.end.x / 16)):
			for y in range(int(rect.position.y / 16), int(rect.end.y / 16)):
				var cell := Vector2i(x, y)
				air[cell] = true
	var corners := preload("res://Script/Stage/coastal_auto_corners.gd").new()
	corners.name = "AutomaticCorners"
	corners.corners = corners.find_corners(air)
	corners.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Above shell art but behind manual decorations and player.
	corners.z_index = 1
	add_child(corners)
	var decorations := Node2D.new()
	decorations.name = "Decorations"
	add_child(decorations)
	for i in range(layout.rooms.size()):
		var room: Dictionary = layout.rooms[i]
		if not room.template.automatic_decorations:
			continue
		# Side alcoves leave the central spawn, treasure and exit readable.
		for side in [0, 1]:
			var foot: Vector2 = room.position + Vector2(48 if side == 0 else room.width - 48, room.height)
			var cell := Vector2i(floori(foot.x / 16), floori(foot.y / 16))
			if air.has(cell + Vector2i.UP) and not air.has(cell):
				decorations.add_child(ART.prop((i * 3 + side) % ART.PROPS.size(), foot))
		var banner := ART.prop(2 if i % 2 == 0 else 3, room.position + Vector2(room.width * 0.5, 72))
		decorations.add_child(banner)
	var terrain := Node2D.new()
	terrain.name = "TerrainArt"
	terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(terrain)
	terrain.draw.connect(func():
		for rect in layout.shell:
			for x in range(int(rect.position.x), int(rect.end.x), 16):
				var cell := Vector2i(x / 16, int(rect.position.y / 16))
				# Draw the solid shell, keeping door openings and manual floors intact.
				if air.has(cell + Vector2i.UP):
					var manual := false
					for room in layout.rooms:
						if room.template.manual_floor and rect.position.y == room.position.y + room.height and x >= room.position.x and x < room.position.x + room.width:
							manual = true
							break
					if manual:
						continue
					ART.draw_surface(terrain, Rect2(x, rect.position.y, 16, 16), true)
				else:
					ART.draw_surface(terrain, Rect2(x, rect.position.y, 16, 16), false)
	)
