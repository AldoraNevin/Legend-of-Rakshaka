extends SceneTree
const MENU := "res://addons/maaacks_menus_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn"
var failures := 0
func _initialize() -> void:
	call_deferred("run_test")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run_test() -> void:
	var manager = root.get_node("CheckpointManager")
	manager.storage_path = "res://Tests/menu_departure_%d.json" % OS.get_process_id()
	for is_new in [true, false]:
		change_scene_to_file(MENU)
		await scene_changed
		var menu = current_scene
		await process_frame
		menu.intro_done()
		await create_timer(0.6).timeout
		menu._open_load_menu()
		var slots = menu.sub_menu
		slots._load(0)
		slots._load(0)
		await process_frame
		await process_frame
		check(menu.departing and menu.sub_menu == null, "Selection returns to main menu")
		check(not manager.loading and current_scene == menu, "Scene does not load before animation")
		await create_timer(0.65).timeout
		check(menu.mata_menyala.visible, "Eyes are visible during blinking")
		check(menu.departure_fade.color.a == 0.0, "Blink precedes fade")
		for frame in range(600):
			await process_frame
			if current_scene != menu and not manager.loading:
				break
		check(current_scene != menu and current_scene.scene_file_path == manager.LOBBY, "Selection enters saved lobby")
		check(manager.active_slot == 0, "Selected slot is active")
		if is_new:
			player_data.add_gold(17)
		else:
			check(player_data.coin == 17, "Load preserves saved progress")
	manager.enabled = false
	manager.active_slot = -1
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(manager.storage_path + suffix):
			DirAccess.remove_absolute(manager.storage_path + suffix)
	print("MENU DEPARTURE TEST: %d failures" % failures)
	quit(1 if failures else 0)
