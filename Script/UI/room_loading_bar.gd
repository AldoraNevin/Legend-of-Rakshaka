extends Control
const ATLAS := preload("res://Legend of Rakshaka/UI HUD/Legend of Rakshaka Loading UI Atlas-4.png")
var value := 0.0:
	set(next):
		value = clampf(next, 0, 100)
		queue_redraw()
func _draw() -> void:
	var inner := Rect2(size.x * 0.061, size.y * 0.26, size.x * 0.875, size.y * 0.43)
	draw_rect(inner, Color("#101728"))
	var fill := inner
	fill.size.x *= value / 100.0
	if fill.size.x > 0:
		draw_texture_rect_region(ATLAS, fill, Rect2(150, 467, 1475 * value / 100.0, 62))
	draw_texture_rect_region(ATLAS, Rect2(Vector2.ZERO, size), Rect2(130, 322, 1515, 114))
