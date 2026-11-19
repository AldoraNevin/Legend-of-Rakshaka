extends Node2D
const GHOST_TEXTURE := preload("res://Assets/Legend of Rakshaka-20261119T045508Z-1-001/Legend of Rakshaka/Main Menu/Ghostly cyan firefly sprite sheet-4.png")
var title := "Portal"
var portal_id := ""
var unlocked := false:
	set(value):
		unlocked = value
		if is_instance_valid(ghost):
			ghost.modulate = Color.WHITE if unlocked else Color(0.55, 0.65, 0.65, 0.7)
var ghost: AnimatedSprite2D

func _ready() -> void:
	ghost = AnimatedSprite2D.new()
	ghost.name = "GhostCyan"
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.position = Vector2(0, -24)
	ghost.scale = Vector2(3, 3)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 8.0)
	frames.set_animation_loop("default", true)
	for index in range(8):
		var frame := AtlasTexture.new()
		frame.atlas = GHOST_TEXTURE
		frame.region = Rect2((index % 4) * 32, (index / 4) * 32, 32, 32)
		frames.add_frame("default", frame)
	ghost.sprite_frames = frames
	add_child(ghost)
	unlocked = unlocked
	ghost.play()
	var label := Label.new()
	label.text = "Portal"
	label.position = Vector2(-65, -62)
	label.size.x = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)
