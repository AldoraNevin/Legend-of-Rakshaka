extends Node2D
## Screen-filling parallax: horizontal repetition, bounded vertical drift.
## A CanvasLayer keeps the composition consistent at different camera zooms.
const TEXTURES = [
	preload("res://Assets/Tileset/Environment/pantai layer1.png"),
	preload("res://Assets/Tileset/Environment/pantai layer3.png"),
	preload("res://Assets/Tileset/Environment/pantai layer2.png"),
	preload("res://Assets/Tileset/Environment/pantai layer 4.png")]
const SPEEDS = [0.025, 0.10, 0.16, 0.30]
var anchor := Vector2.ZERO
var anchored := false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var viewport := get_viewport()
	var camera := viewport.get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2.ZERO
	if not anchored:
		anchor = center
		anchored = true
	var travel := center - anchor
	var screen := viewport.get_visible_rect().size
	# Overscan prevents gaps when the camera climbs tall rooms.
	var factor := maxf(screen.x / 720.0, screen.y / 405.0) * 1.12
	var size := Vector2(720, 405) * factor
	var origin := (screen - size) * 0.5
	for i in range(TEXTURES.size()):
		var drift := Vector2(-fposmod(travel.x * SPEEDS[i] * factor, size.x), clampf(-travel.y * SPEEDS[i] * factor * 0.12, -screen.y * 0.045, screen.y * 0.045))
		for repeat in range(-1, 3):
			draw_texture_rect(TEXTURES[i], Rect2(origin + drift + Vector2(repeat * size.x, 0), size), false)
