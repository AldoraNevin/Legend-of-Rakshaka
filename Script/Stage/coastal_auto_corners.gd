extends Node2D
## Decorative inner corners, fitted to the final playable area after rooms connect.
const TEXTURE = preload("res://Assets/Tileset/Sprites/coastal_packed.png")
const REGION := Rect2(320, 64, 64, 64)
var corners: Dictionary = {}

static func find_corners(air: Dictionary) -> Dictionary:
	var result := {}
	for cell: Vector2i in air:
		var left := not air.has(cell + Vector2i.LEFT)
		var right := not air.has(cell + Vector2i.RIGHT)
		var up := not air.has(cell + Vector2i.UP)
		var down := not air.has(cell + Vector2i.DOWN)
		# Exactly one wall and one horizontal surface; no narrow passage caps.
		if left == right or up == down:
			continue
		var diagonal := Vector2i(-1 if left else 1, -1 if up else 1)
		if air.has(cell + diagonal):
			continue
		# Source art has stone on the left and bottom, open toward upper right.
		result[cell] = Vector2(-1 if right else 1, -1 if up else 1)
	return result

func _draw() -> void:
	for cell: Vector2i in corners:
		draw_set_transform(Vector2(cell) * 16 + Vector2(8, 8), 0, corners[cell])
		draw_texture_rect_region(TEXTURE, Rect2(-8, -8, 16, 16), REGION)
	draw_set_transform(Vector2.ZERO)
