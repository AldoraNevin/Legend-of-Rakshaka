extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run_test")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_test() -> void:
	root.size = Vector2i(1080, 608)
	var scene = load("res://Scenes/UI/pause_menu.tscn").instantiate()
	check(scene.has_node("Overlay/MenuPanel/ContinueButton"), "Buttons must exist before ready")
	root.add_child(scene)
	await process_frame
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	scene._unhandled_input(escape)
	check(paused and scene.overlay.visible, "Escape must pause gameplay")
	scene.show_options()
	check(paused and scene.options.visible and not scene.menu.visible, "Options must keep game paused")
	scene._input(escape)
	check(paused and scene.menu.visible and not scene.options.visible, "Escape returns from options")
	scene._input(escape)
	check(not paused and not scene.overlay.visible, "Escape resumes gameplay")
	paused = true
	scene._unhandled_input(escape)
	check(not scene.owns_pause, "Do not take pause from bestiary or map")
	paused = false
	scene.open_pause()
	scene.menu.get_node("ContinueButton").pressed.emit()
	check(not paused, "Continue button resumes gameplay")
	scene.open_pause()
	await process_frame
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	scene.queue_free()
	await process_frame
	check(not paused, "Removing menu must release its pause")
	change_scene_to_file("res://Levels/lobby.tscn")
	await scene_changed
	var old_scene_id := current_scene.get_instance_id()
	var lobby_pause = current_scene.get_node("PauseMenu")
	lobby_pause.open_pause()
	lobby_pause.menu.get_node("RestartButton").pressed.emit()
	await scene_changed
	check(current_scene.get_instance_id() != old_scene_id and not paused, "Restart reloads the current scene and unpauses")
	check(current_scene.scene_file_path == "res://Levels/lobby.tscn", "Restart stays in the same level")
	lobby_pause = current_scene.get_node("PauseMenu")
	lobby_pause.open_pause()
	lobby_pause.menu.get_node("LeaveButton").pressed.emit()
	await scene_changed
	check(current_scene.scene_file_path.ends_with("main_menu_with_animations.tscn") and not paused, "Leave returns to main menu and unpauses")
	await create_timer(1.0).timeout
	current_scene.queue_free()
	await process_frame
	await process_frame
	print("PAUSE TEST: %d failures" % failures)
	quit(1 if failures else 0)
