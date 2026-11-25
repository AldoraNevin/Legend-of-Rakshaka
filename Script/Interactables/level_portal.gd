extends Node2D
const PORTAL_TEXTURE := preload("res://Legend of Rakshaka/UI HUD/Portal.png")
var title := "Portal"
var portal_id := ""
var unlocked := false:
	set(value):
		unlocked = value
		if is_instance_valid(portal_sprite):
			portal_sprite.modulate = Color.WHITE if unlocked else Color(0.55, 0.65, 0.65, 0.7)
var portal_sprite: Sprite2D

func _ready() -> void:
	# Keep the gateway behind the player, independently of room insertion order.
	z_as_relative = false
	z_index = -1
	portal_sprite = Sprite2D.new()
	portal_sprite.name = "PortalSprite"
	portal_sprite.texture = PORTAL_TEXTURE
	portal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite_scale := 80.0 / PORTAL_TEXTURE.get_height()
	portal_sprite.scale = Vector2.ONE * sprite_scale
	portal_sprite.position = Vector2(0, -40)
	add_child(portal_sprite)
	unlocked = unlocked
	var label := Label.new()
	label.text = title
	label.position = Vector2(-65, -96)
	label.size.x = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)
