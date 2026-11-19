extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	var loader = root.get_node("RoomLoading")
	var called := [false]
	loader.change_room(func(): called[0] = true)
	assert(loader.busy and paused and not called[0])
	await create_timer(0.1).timeout
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	while loader.busy:
		await process_frame
	assert(called[0] and not paused and not loader.visible)
	await loader.change_scene("res://Levels/stage_graph_template.tscn")
	var stage = current_scene
	var old_room = stage.current_room
	stage.travel_to_room(1)
	assert(loader.busy and stage.current_room == old_room)
	while loader.busy:
		await process_frame
	assert(stage.node_id == 1 and is_instance_valid(stage.current_room) and not paused)
	paused = true
	stage.travel_to_room(2)
	while loader.busy:
		await process_frame
	assert(stage.node_id == 2 and paused)
	paused = false
	current_scene.queue_free()
	await process_frame
	print("ROOM LOADING TEST: passed")
	quit()
