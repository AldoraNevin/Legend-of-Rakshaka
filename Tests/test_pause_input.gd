extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	var lobby = load("res://Levels/lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	var pause = lobby.get_node("PauseMenu")
	# Reproduce the hidden CanvasLayer override present in the lobby.
	pause.hide()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	assert(paused and pause.owns_pause)
	assert(pause.visible and pause.menu.is_visible_in_tree())
	var button: Button = pause.menu.get_node("ContinueButton")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = button.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await process_frame
	assert(not paused and not pause.owns_pause)
	# Repeated keyboard pause/resume also works after restoring the layer.
	root.push_input(escape)
	await process_frame
	assert(paused and pause.menu.is_visible_in_tree())
	root.push_input(escape)
	await process_frame
	assert(not paused)
	lobby.queue_free()
	await process_frame
	print("PAUSE INPUT TEST: passed")
	quit()
