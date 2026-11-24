extends Node2D
## Camera-relative layers anchored to the center of the boss arena.
## 0 follows the camera completely; 1 stays fixed in the world.
@export_range(0.0, 1.0) var sky_motion := 0.15
@export_range(0.0, 1.0) var sea_motion := 0.4
@export_range(0.0, 1.0) var palace_motion := 0.65
@export_range(0.0, 1.0) var ruins_motion := 0.9

const ART_SIZE := Vector2(720, 405)
const EDGE_PADDING := Vector2(48, 48)

func _process(_delta: float) -> void:
	if get_viewport().get_camera_2d() == null:
		return
	# Include the room's scale, camera zoom, and camera smoothing.
	var screen_to_local := get_global_transform_with_canvas().affine_inverse()
	var viewport_size := get_viewport_rect().size
	var view_center := screen_to_local * (viewport_size * 0.5)
	var view_size := (screen_to_local * viewport_size - screen_to_local * Vector2.ZERO).abs()
	var covered_size := ART_SIZE.max(view_size) + EDGE_PADDING
	var motions: Array[float] = [sky_motion, sea_motion, palace_motion, ruins_motion]
	var layers := [$Sky, $Sea, $Palace, $Ruins]
	for index in range(layers.size()):
		var layer := layers[index] as Sprite2D
		layer.scale = covered_size / ART_SIZE
		# Mirror the artwork horizontally so near layers can scroll for the full arena.
		layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		layer.region_enabled = true
		var drift := (view_center.x - ART_SIZE.x * 0.5) * motions[index]
		layer.region_rect = Rect2(Vector2(drift / layer.scale.x, 0), ART_SIZE)
		var margin_y := (covered_size.y - view_size.y) * 0.5
		var center_y := clampf(ART_SIZE.y * 0.5 + (view_center.y - ART_SIZE.y * 0.5) * (1.0 - motions[index]), view_center.y - margin_y, view_center.y + margin_y)
		layer.position = Vector2(view_center.x, center_y) - covered_size * 0.5
