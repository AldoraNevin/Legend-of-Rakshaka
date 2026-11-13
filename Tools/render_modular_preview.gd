extends SceneTree
## Render the real gameplay scene and its map for visual QA.
func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage: Node2D = load("res://Levels/modular_level_preview.tscn").instantiate()
	viewport.add_child(stage)
	await process_frame
	root.size = Vector2i(1280, 720)
	for i in range(6):
		await process_frame
	var room: Node2D = stage.current_room
	if room == null or not room.get_meta("modular_level", false):
		push_error("Preview did not load modular gameplay.")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/modular_gameplay.png")
	var map: CanvasLayer = room.get_node("CoastalMap")
	map.view.show()
	map.hint.hide()
	map.view.queue_redraw()
	for i in range(4):
		await process_frame
	map.view.queue_redraw()
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/modular_map.png")
	map.view.hide()
	var tower: Dictionary = room.layout.rooms[1]
	stage.player.position = tower.position + tower.definition.markers.PlayerSpawn
	stage.camera.snap_to_target()
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/modular_tower.png")
	print("Rendered gameplay, map and tower previews.")
	stage.queue_free()
	await process_frame
	viewport.queue_free()
	await process_frame
	quit()
