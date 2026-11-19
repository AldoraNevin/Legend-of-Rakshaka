extends AnimatedSprite2D
## Anchor visible feet, not the differently padded sprite-sheet rectangles.
static var bounds_cache: Dictionary = {}
var baseline := 0.0
var baseline_captured := false

func capture_authored_baseline() -> void:
	var texture := sprite_frames.get_frame_texture(&"Idle", 0)
	var half_height := texture.get_height() * 0.5 if centered else 0.0
	baseline = offset.y + visible_bounds(&"Idle", 0).end.y - half_height
	baseline_captured = true

func _ready() -> void:
	if not baseline_captured:
		capture_authored_baseline()
	animation_changed.connect(align_feet)
	frame_changed.connect(align_feet)
	align_feet()

func visible_bounds(clip: StringName, index: int) -> Rect2:
	if not bounds_cache.has(sprite_frames):
		bounds_cache[sprite_frames] = {}
	var key := str(clip) + ":" + str(index)
	var cached: Dictionary = bounds_cache[sprite_frames]
	if not cached.has(key):
		var texture := sprite_frames.get_frame_texture(clip, index)
		cached[key] = Rect2(texture.get_image().get_used_rect())
	return cached[key]

func align_feet() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	var index := mini(frame, sprite_frames.get_frame_count(animation) - 1)
	if index < 0:
		return
	var texture := sprite_frames.get_frame_texture(animation, index)
	var bounds := visible_bounds(animation, index)
	var half_height := texture.get_height() * 0.5 if centered else 0.0
	offset.y = baseline + half_height - bounds.end.y
