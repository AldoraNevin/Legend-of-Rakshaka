extends RefCounted
## Source rectangles refer to the supplied, irregularly spaced art sheets.
const TERRAIN = preload("res://Assets/Tileset/Environment/tileset pantai.png")
const DECOR = preload("res://Assets/Tileset/Environment/tileset pantai(1).png")
const TOPS = [Rect2(28, 35, 72, 68), Rect2(116, 35, 68, 68), Rect2(201, 35, 69, 68), Rect2(283, 35, 69, 68)]
const STONE = [Rect2(116, 122, 68, 68), Rect2(201, 122, 69, 68), Rect2(283, 122, 69, 68), Rect2(369, 122, 68, 68)]
const LEDGE = Rect2(201, 308, 68, 30)
const PROPS = [Rect2(38, 4, 65, 131), Rect2(145, 43, 90, 92), Rect2(267, 32, 86, 104), Rect2(396, 8, 65, 128), Rect2(505, 184, 65, 73), Rect2(369, 290, 104, 68), Rect2(491, 310, 90, 46), Rect2(389, 379, 62, 87)]

static func draw_surface(canvas: CanvasItem, rect: Rect2, top: bool, ledge := false) -> void:
	for x in range(0, int(rect.size.x), 16):
		for y in range(0, int(rect.size.y), 16):
			var size := Vector2(minf(16, rect.size.x - x), minf(16, rect.size.y - y))
			var index := posmod(int(rect.position.x / 16) + x / 16 + y / 16, 4)
			var source: Rect2 = LEDGE if ledge else (TOPS[index] if top and y == 0 else STONE[index])
			# Crop the final partial tile without stretching its pattern.
			source.size.x *= size.x / 16.0
			canvas.draw_texture_rect_region(TERRAIN, Rect2(rect.position + Vector2(x, y), size), source)

static func prop(index: int, foot: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DECOR
	atlas.region = PROPS[index % PROPS.size()]
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.4, 0.4)
	sprite.position = foot - Vector2(0, atlas.region.size.y * 0.2)
	sprite.modulate = Color(0.8, 0.88, 0.83)
	return sprite
