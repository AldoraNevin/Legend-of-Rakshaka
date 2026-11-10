extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var stage = load("res://Levels/stage_graph_template.tscn").instantiate()
	stage.random_seed = 42
	stage.preview_start_node = 1
	root.add_child(stage)
	root.size = Vector2i(1152, 648)
	for frame in range(12):
		await physics_frame
	paused = true
	stage.snap_camera_to_player()
	assert(stage.current_room.get_node("Backdrop").z_index < stage.player.z_index)
	var sprite := stage.player.get_node("Sprite2D") as Sprite2D
	assert(sprite.is_visible_in_tree())
	await process_frame
	await RenderingServer.frame_post_draw
	var visible_frame := root.get_texture().get_image()
	visible_frame.save_png("res://Docs/coastal-player-preview.png")
	sprite.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var hidden_frame := root.get_texture().get_image()
	var before := visible_frame.get_data()
	var after := hidden_frame.get_data()
	var changed := 0
	for i in range(before.size()):
		if before[i] != after[i]:
			changed += 1
	assert(changed > 100, "Player sprite is hidden behind level geometry or outside the camera")
	sprite.show()
	paused = false
	stage.queue_free()
	await process_frame
	print("PASS: actual player changes %d rendered bytes; background cannot hide the actor." % changed)
	quit()
