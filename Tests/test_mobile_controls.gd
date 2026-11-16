extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	root.push_input(event, true)
func run_test() -> void:
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	var controls = load("res://Scenes/UI/mobile_controls.tscn").instantiate()
	root.add_child(controls)
	controls.enabled = true
	controls._update_visibility()
	await process_frame
	touch(0, controls.get_node("Buttons/Left").position, true)
	touch(1, controls.get_node("Buttons/Attack").position, true)
	assert(Input.is_action_pressed("ui_left"))
	assert(Input.is_action_pressed("ui_sword"))
	touch(0, controls.get_node("Buttons/Left").position, false)
	assert(not Input.is_action_pressed("ui_left"))
	assert(Input.is_action_pressed("ui_sword"))
	paused = true
	controls._update_visibility()
	assert(not Input.is_action_pressed("ui_sword"))
	assert(not controls.get_node("Buttons").visible)
	paused = false
	controls._update_visibility()
	assert(controls.get_node("Buttons").visible)
	controls.queue_free()
	await process_frame
	print("MOBILE CONTROLS TEST: passed")
	quit()
