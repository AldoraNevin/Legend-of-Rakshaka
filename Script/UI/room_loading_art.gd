extends Control
const ATLAS := preload("res://Legend of Rakshaka/UI HUD/Legend of Rakshaka Loading UI Atlas-4.png")
const SCENERY := preload("res://Legend of Rakshaka/UI HUD/Pixel art banyan and temple sprite atlas.png")
const LOGO := preload("res://Legend of Rakshaka/UI HUD/Icon Logo.png")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#090e20"))
	var factor := minf(size.x / 1080.0, size.y / 608.0)
	var origin := (size - Vector2(1080, 608) * factor) * 0.5
	draw_set_transform(origin, 0, Vector2.ONE * factor)
	# Background silhouettes sit behind the center composition.
	draw_texture_rect_region(SCENERY, Rect2(-45, 310, 350, 250), Rect2(15, 40, 925, 580), Color(0.6, 0.7, 0.85, 0.55))
	draw_texture_rect_region(SCENERY, Rect2(800, 390, 310, 170), Rect2(1010, 180, 750, 435), Color(0.6, 0.7, 0.85, 0.6))
	draw_texture_rect_region(SCENERY, Rect2(0, 490, 1080, 70), Rect2(20, 710, 1740, 145), Color(0.5, 0.6, 0.8, 0.5))
	draw_texture_rect(LOGO, Rect2(450, 25, 180, 270), false)
	draw_texture_rect_region(ATLAS, Rect2(412, 338, 256, 31), Rect2(400, 208, 970, 110))
	draw_texture_rect_region(ATLAS, Rect2(345, 515, 390, 38), Rect2(145, 652, 1485, 113))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var corner := Vector2(90, 78) * factor
	var inset := 12.0 * factor
	var regions := [Rect2(230, 10, 225, 193), Rect2(593, 10, 225, 193), Rect2(955, 10, 225, 193), Rect2(1317, 10, 225, 193)]
	var positions := [Vector2(inset, inset), Vector2(size.x - inset - corner.x, inset), Vector2(inset, size.y - inset - corner.y), size - Vector2(inset, inset) - corner]
	for i in range(4):
		draw_texture_rect_region(ATLAS, Rect2(positions[i], corner), regions[i])
