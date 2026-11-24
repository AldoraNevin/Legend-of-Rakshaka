@tool
extends Node2D
## Shared courtyard composition. The paving stays aligned with world collision.
@export_group("Background Appearance")
## Scale forest, temple and trees without changing the player, camera or floor.
## 1.0 = original size; 0.7 = 70 percent. Preview updates in the editor.
@export_range(0.2, 2.0, 0.05) var background_scale := 1.0
## Move the scenery independently of the playable courtyard.
@export var background_offset := Vector2.ZERO

@export_group("Courtyard Layout")
@export var wide_lobby := false
@export var courtyard_width := 970.0
@export var floor_y := 114.0
@export var left_edge := -520.0

const SKY = preload("res://Assets/Tileset/lobby/layer 1.png")
const FOREST = preload("res://Assets/Tileset/lobby/layer 2.png")
const TEMPLE = preload("res://Assets/Tileset/lobby/layer 3.png")
const TREES = preload("res://Assets/Tileset/lobby/layer 4.png")
const COURTYARD = preload("res://Assets/Tileset/lobby/Copy of Lotus Courtyard With Turquoise Spirit Gate-6.png")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if wide_lobby:
		_draw_long_courtyard()
		return
	var factor := courtyard_width / 720.0
	var size := Vector2(720, 405) * factor
	var origin := Vector2(left_edge, floor_y - 320.0 * factor)
	var art_rect := Rect2(origin, size)
	# Resize around the floor's center so smaller scenery stays grounded.
	var background_size := size * background_scale
	var background_origin := Vector2(left_edge + courtyard_width * 0.5,
		floor_y) - Vector2(background_size.x * 0.5, 320.0 * factor * background_scale)
	background_origin += background_offset
	var travel := Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	var sky_rect := art_rect
	if camera != null and not Engine.is_editor_hint():
		var center := to_local(camera.get_screen_center_position())
		travel = center - art_rect.get_center()
		var view_size := get_viewport_rect().size / camera.zoom
		sky_rect = sky_rect.merge(Rect2(center - view_size * 0.5, view_size))
	draw_texture_rect(SKY, sky_rect, false)
	# Bounded offsets keep the single, non-tileable temple and tree frame intact.
	var textures := [FOREST, TEMPLE, TREES]
	var depths := [0.22, 0.12, -0.035]
	for i in range(textures.size()):
		var offset := Vector2(clampf(travel.x * depths[i], -32.0, 32.0),
			clampf(travel.y * depths[i] * 0.25, -8.0, 8.0))
		draw_texture_rect(textures[i], Rect2(background_origin + offset, background_size), false)
	draw_texture_rect(COURTYARD, art_rect, false)

func _draw_long_courtyard() -> void:
	# Mirror alternating panels to join the painted edges without stretching the art.
	var width := 970.0
	var factor := width / 720.0
	var center_x := left_edge + courtyard_width * 0.5
	var camera := get_viewport().get_camera_2d()
	var half_view := courtyard_width * 0.5
	if camera != null and not Engine.is_editor_hint():
		center_x = to_local(camera.get_screen_center_position()).x
		half_view = get_viewport_rect().size.x / camera.zoom.x * 0.5
	var textures := [SKY, FOREST, TEMPLE, TREES, COURTYARD]
	var motion := [0.10, 0.35, 0.60, 0.82, 1.0]
	for i in textures.size():
		var scenery := i > 0 and i < 4
		var art_scale := factor * (background_scale if scenery else 1.0)
		var panel := Vector2(720, 405) * art_scale
		var anchor := Vector2(left_edge + (center_x - left_edge) * (1.0 - float(motion[i])), floor_y - 320 * art_scale)
		if scenery:
			anchor += background_offset
		var first := floori((center_x - half_view - anchor.x) / panel.x)
		var last := floori((center_x + half_view - anchor.x) / panel.x)
		for col in range(first, last + 1):
			var mirrored := posmod(col, 2) == 1
			var x := anchor.x + panel.x * (col + int(mirrored))
			draw_set_transform(Vector2(x, anchor.y), 0, Vector2(-1 if mirrored else 1, 1))
			draw_texture_rect(textures[i], Rect2(Vector2.ZERO, panel), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
