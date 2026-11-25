extends Sprite2D

const REACH := 120.0
const FRAME_TIME := 0.042
var elapsed := 0.0

func _ready() -> void:
	texture = preload("res://Legend of Rakshaka/Main Chara/Sprites/pecut_strike.png")
	hframes = 8
	centered = false
	offset = Vector2(-4, -33)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	var next_frame := int(elapsed / FRAME_TIME)
	if next_frame >= hframes:
		queue_free()
	else:
		frame = next_frame
		if frame >= 6:
			modulate.a = 0.75 if frame == 6 else 0.42
