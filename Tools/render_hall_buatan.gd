extends SceneTree
func _initialize() -> void:
	call_deferred("render_room")

func render_room() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var room: Node2D = load("res://Scenes/Rooms/Modular/hall_buatan.tscn").instantiate()
	viewport.add_child(room)
	var camera := Camera2D.new()
	camera.position = Vector2(384, 240)
	camera.zoom = Vector2(1.4, 1.4)
	viewport.add_child(camera)
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://Docs/hall-buatan-preview.png")
	viewport.queue_free()
	await process_frame
	quit()
