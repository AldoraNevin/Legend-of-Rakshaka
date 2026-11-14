extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var manager := root.get_node("CheckpointManager")
	manager.enabled = false
	manager.storage_path = "res://Tests/checkpoint_empty_test_%d.json" % OS.get_process_id()
	change_scene_to_file("res://addons/maaacks_menus_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn")
	await scene_changed
	current_scene.intro_done()
	await create_timer(2.0).timeout
	assert(current_scene.tombol_start.text == "Start Game")
	current_scene.tombol_start.pressed.emit()
	await process_frame
	assert(is_instance_valid(current_scene.sub_menu), "Start Game opens the slot menu directly")
	for row in current_scene.sub_menu.get_node("Panel/Slots").get_children():
		assert(not row.get_node("LoadButton").disabled, "Empty slot must be clickable")
		assert(row.get_node("LoadButton").text == "Empty Save")
	var menu = current_scene.sub_menu
	var entry := {"version": 1, "scene": manager.LOBBY, "room_label": "Lobby",
		"saved_at": "2026-11-14T12:00:00", "player": manager.ADAPTER.capture_player()}
	assert(manager._write_slots([entry, entry.duplicate(true), null]))
	var other_before := JSON.stringify(manager.list_checkpoints()[1])
	assert(menu.get_node("Panel/Slots/Checkpoint1/DeleteButton").visible)
	assert(not menu.get_node("Panel/Slots/Checkpoint3/DeleteButton").visible)
	menu.get_node("Panel/Slots/Checkpoint1/DeleteButton").pressed.emit()
	assert(menu.get_node("DeleteConfirmation").visible)
	assert(manager.list_checkpoints()[0] != null, "Requesting deletion must not delete before confirmation")
	menu.get_node("DeleteConfirmation").get_cancel_button().pressed.emit()
	assert(menu.pending_delete == -1 and manager.list_checkpoints()[0] != null, "Cancel preserves save")
	manager.active_slot = 0
	manager.enabled = true
	menu.get_node("Panel/Slots/Checkpoint1/DeleteButton").pressed.emit()
	menu.get_node("DeleteConfirmation").get_ok_button().pressed.emit()
	assert(manager.list_checkpoints()[0] == null, "Confirm deletes only selected slot")
	assert(JSON.stringify(manager.list_checkpoints()[1]) == other_before, "Other save stays unchanged")
	assert(manager.active_slot == -1, "Deleted slot cannot receive autosaves")
	assert(manager.save_progress())
	assert(menu.get_node("Panel/Slots/Checkpoint1/LoadButton").text == "Empty Save")
	assert(not menu.get_node("Panel/Slots/Checkpoint1/DeleteButton").visible)
	var corrupt := FileAccess.open(manager.storage_path, FileAccess.WRITE)
	corrupt.store_string("broken json")
	corrupt.close()
	assert(manager.list_checkpoints()[0] == null, "Backup recovery must not revive deleted save")
	assert(JSON.stringify(manager.list_checkpoints()[1]) == other_before, "Recovery preserves the other save")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	current_scene.sub_menu.get_node("Panel/BackButton").pressed.emit()
	await process_frame
	assert(current_scene.sub_menu == null, "Back returns to main menu")
	await create_timer(1.0).timeout
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(manager.storage_path + suffix):
			DirAccess.remove_absolute(manager.storage_path + suffix)
	print("CHECKPOINT MENU TEST: passed")
	quit()
