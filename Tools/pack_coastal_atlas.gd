extends SceneTree
## Deterministic asset packing; never redraws the source artwork.
const OUTPUT := "res://Assets/Tileset/Sprites/coastal_packed.png"
func _initialize() -> void:
	var original := Image.load_from_file("res://Assets/Tileset/Environment/tileset pantai.png")
	var atlas := Image.create(512, 384, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var edges := [20, 108, 192, 276, 360, 445, 532, 615, 704]
	var rows := [Vector2i(30, 76), Vector2i(117, 78), Vector2i(207, 78), Vector2i(305, 46), Vector2i(368, 71), Vector2i(452, 72)]
	for y in range(6):
		for x in range(8):
			var crop := original.get_region(Rect2i(edges[x], rows[y].x, edges[x + 1] - edges[x], rows[y].y))
			var minimum := Vector2i(crop.get_width(), crop.get_height())
			var maximum := Vector2i(-1, -1)
			# Ignore nearly transparent export noise outside the actual sprite.
			for py in range(crop.get_height()):
				for px in range(crop.get_width()):
					if crop.get_pixel(px, py).a > 0.5:
						minimum = minimum.min(Vector2i(px, py))
						maximum = maximum.max(Vector2i(px, py))
			var used := Rect2i(minimum, maximum - minimum + Vector2i.ONE)
			assert(used.has_area())
			crop = crop.get_region(used)
			# Platforms keep a half-height silhouette, aligned to the top of the cell.
			var height := mini(32, roundi(64.0 * crop.get_height() / crop.get_width())) if y == 3 else 64
			crop.resize(64, height, Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(crop, Rect2i(0, 0, 64, height), Vector2i(x * 64, y * 64))
	assert(atlas.save_png(OUTPUT) == OK)
	print("PASS: 48 complete tiles packed into a transparent 8x6 atlas, each cell 64px.")
	quit()
