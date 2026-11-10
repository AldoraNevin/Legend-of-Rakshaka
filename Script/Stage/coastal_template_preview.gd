@tool
extends Node2D
## Open coastal_template_preview.tscn and assign any catalog template here.
@export var template: Resource:
	set(value):
		template = value
		queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if template == null or not template.has_method("validate"):
		return
	for rect in template.air_regions:
		draw_rect(rect, Color(0.12, 0.25, 0.4))
	draw_rect(Rect2(Vector2.ZERO, template.size), Color(0.5, 0.5, 0.5), false, 1)
	var font := ThemeDB.fallback_font
	for socket in template.sockets:
		var tangent := Vector2.RIGHT if socket.side in ["up", "down"] else Vector2.DOWN
		draw_line(socket.position - tangent * socket.opening / 2, socket.position + tangent * socket.opening / 2, Color(0.3, 1, 0.7), 3)
		draw_circle(socket.position, 5, Color(1, 0.8, 0.3))
		draw_string(font, socket.position + Vector2(8, -10), socket.side, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_circle(template.anchor, 6, Color.WHITE)
	draw_string(font, Vector2(0, -40), template.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var errors: PackedStringArray = template.validate()
	draw_string(font, Vector2(0, template.size.y + 40), "Template valid" if errors.is_empty() else errors[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN if errors.is_empty() else Color.RED)
