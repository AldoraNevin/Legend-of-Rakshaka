extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.size = Vector2i(1080, 608)
	var scene = load("res://Scenes/UI/pause_menu.tscn").instantiate()
	root.add_child(scene)
	scene.open_pause()
	scene.show_cheats()
	await process_frame
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	scene.queue_free()
	await process_frame
	quit()
