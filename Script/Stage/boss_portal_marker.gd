@tool
extends Marker2D

const Portal := preload("res://Script/Interactables/level_portal.gd")
@export var floor_offset := Vector2(0, 34):
	set(value):
		floor_offset = value
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		var art_size := Portal.PORTAL_TEXTURE.get_size() * (80.0 / Portal.PORTAL_TEXTURE.get_height())
		var corner := floor_offset - Vector2(art_size.x * 0.5, art_size.y)
		draw_texture_rect(Portal.PORTAL_TEXTURE, Rect2(corner, art_size), false)
