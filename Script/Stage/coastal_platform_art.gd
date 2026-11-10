extends Node2D
const ART = preload("res://Script/Stage/coastal_asset_art.gd")
var platform_size := Vector2.ZERO

func _draw() -> void:
	ART.draw_surface(self, Rect2(Vector2.ZERO, platform_size), true, true)
