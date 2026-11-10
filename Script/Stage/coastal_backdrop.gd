extends Node2D
## Draw scenery behind actors regardless of scene-tree sibling order.
var layout: Dictionary = {}

func _draw() -> void:
	for rect in layout.get("regions", []):
		draw_rect(rect, Color(0.018, 0.065, 0.08))
	for data in layout.get("rooms", []):
		# Non-colliding stone pillars keep the coastal identity in varied chambers.
		for x in range(32, int(data.width) - 32, 96):
			var pillar := Rect2(data.position + Vector2(x, 40), Vector2(12, data.height - 40))
			for rect in data.template.air_regions:
				var clipped := pillar.intersection(Rect2(data.position + rect.position, rect.size))
				if clipped.has_area():
					draw_rect(clipped, Color(0.04, 0.13, 0.15))

