extends Node2D
## F6 this scene to play one hand-painted template in isolation.
@export var room_scene: PackedScene = preload("res://Scenes/Rooms/Modular/tower.tscn")
const PLAYER = preload("res://Scenes/Player/player.tscn")
const CAMERA = preload("res://Script/Control/camera.gd")

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0a101b"))
	var room := room_scene.instantiate()
	var errors: PackedStringArray = room.validate()
	if not errors.is_empty():
		push_error("; ".join(errors))
		room.free()
		return
	add_child(room)
	var player := PLAYER.instantiate() as Node2D
	player.position = room.get_node("PlayerSpawn").position
	add_child(player)
	var camera := Camera2D.new()
	camera.set_script(CAMERA)
	camera.target = player
	camera.zoom = Vector2(3, 3)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = room.size_in_tiles.x * 16
	camera.limit_bottom = room.size_in_tiles.y * 16
	add_child(camera)
