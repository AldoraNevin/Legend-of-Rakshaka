extends Node2D
var phase := 0.0
func _process(delta: float) -> void:
	phase += delta
	queue_redraw()
func _draw() -> void:
	for band in range(4):
		var points := PackedVector2Array()
		for x in range(0, 641, 8):
			points.append(Vector2(x, 180 + band * 14 + sin(x * 0.018 + phase * 1.8 + band) * 10))
		draw_polyline(points, Color(0.12, 0.52, 0.53, 0.32), 3)
	for band in range(3):
		draw_rect(Rect2(0, 52 + band * 48 + sin(phase + band) * 8, 640, 18), Color(0.45, 0.72, 0.69, 0.07))
