extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run_test")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_test() -> void:
	var saved_config := PlayerConfig.config_file.encode_to_text()
	var old_events := InputMap.action_get_events("ui_sword")
	var old_msaa := root.msaa_2d
	var old_deadzone := InputMap.action_get_deadzone("ui_left")
	var old_size := root.size
	var scene = load("res://addons/maaacks_menus_template/examples/scenes/menus/options_menu/master_options_menu_with_tabs.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var actions = scene.get_node("Controls/VBoxContainer/InputMappingContainer/InputActionsList")
	check(actions.action_button_map.has("ui_sword:0"), "Controls must expose attack")
	check(actions.action_button_map.has("ui_left:0"), "Controls must expose movement")
	var new_key := InputEventKey.new()
	new_key.physical_keycode = KEY_F8
	var events: Array = [old_events[0], new_key]
	PlayerConfig.config_file.set_value("InputSettings", "ui_sword", events)
	AppSettings.set_input_from_config("ui_sword")
	check(InputMap.action_get_events("ui_sword").size() == 2, "Loading remaps must keep unchanged and changed bindings")
	for pause_state in [false, true]:
		paused = pause_state
		scene.process_mode = Node.PROCESS_MODE_ALWAYS
		scene.current_tab = 0
		actions._on_button_pressed("ui_sword", 0)
		var assignment = scene.get_node("Controls/KeyAssignmentWindow")
		await create_timer(0.4).timeout
		var assigned_key := InputEventKey.new()
		assigned_key.physical_keycode = KEY_F6 if not pause_state else KEY_F7
		assigned_key.pressed = true
		assignment._process_input_event(assigned_key)
		check(InputMap.action_has_event("ui_sword", assigned_key), "Key assignment dialog must apply bindings in main menu and pause")
		var deadzone = scene.get_node("Inputs/VBoxContainer/DeadzoneControl/HSlider")
		deadzone.value = 0.35 if not pause_state else 0.45
		check(is_equal_approx(InputMap.action_get_deadzone("ui_left"), deadzone.value), "Deadzone must apply immediately")
		var antialias = scene.get_node("Video/VBoxContainer/AntiAliasingControl/OptionButton")
		antialias.item_selected.emit(1 if not pause_state else 2)
		check(root.msaa_2d == (1 if not pause_state else 2), "Anti-aliasing must apply to the 2D viewport")
		var resolution = scene.get_node("Video/VBoxContainer/ResolutionControl/OptionButton")
		resolution.item_selected.emit(1 if not pause_state else 3)
		await process_frame
		check(root.size == (Vector2i(960, 540) if not pause_state else Vector2i(1280, 720)), "Resolution must change the game window")
	paused = false
	root.size = old_size
	root.msaa_2d = old_msaa
	InputMap.action_erase_events("ui_sword")
	for event in old_events:
		InputMap.action_add_event("ui_sword", event)
	AppSettings.apply_controller_deadzone(old_deadzone)
	PlayerConfig.config_file.clear()
	PlayerConfig.config_file.parse(saved_config)
	PlayerConfig._save_config_file()
	scene.queue_free()
	await process_frame
	print("OPTIONS TEST: %d failures" % failures)
	quit(1 if failures else 0)
