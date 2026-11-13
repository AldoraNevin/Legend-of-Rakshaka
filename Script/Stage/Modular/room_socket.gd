@tool
extends Marker2D
## Position is the opening center, ON the outer edge of the room bounds.
## The opening is 64px tall; its floor is position.y + 32.
@export_enum("left", "right") var side := "left"

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color(0.2, 1.0, 0.8)
	draw_line(Vector2(0, -32), Vector2(0, 32), color, 2)
	var direction := -1 if side == "left" else 1
	draw_line(Vector2.ZERO, Vector2(direction * 24, 0), color, 2)
	draw_line(Vector2(direction * 24, 0), Vector2(direction * 16, -6), color, 2)
	draw_line(Vector2(direction * 24, 0), Vector2(direction * 16, 6), color, 2)
