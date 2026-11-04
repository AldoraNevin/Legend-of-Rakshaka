extends Node2D
## Draw scenery behind actors regardless of scene-tree sibling order.
var layout: Dictionary = {}

func _draw() -> void:
	for rect in layout.get("regions", []):
		draw_rect(rect, Color(0.018, 0.065, 0.08))
	for data in layout.get("rooms", []):
		# Non-colliding stone pillars keep the coastal identity in varied chambers.
		for x in range(32, int(data.width) - 32, 96):
			draw_rect(Rect2(data.position + Vector2(x, 40), Vector2(12, data.height - 40)), Color(0.04, 0.13, 0.15))

