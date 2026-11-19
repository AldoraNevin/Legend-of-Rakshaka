extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	change_scene_to_file("res://Levels/stage_graph_template.tscn")
	await scene_changed
	await process_frame
	var pause_menu = current_scene.get_node("PauseMenu")
	player_data.life = 25
	var gold := player_data.coin
	pause_menu.open_pause()
	assert(paused)
	pause_menu.restart()
	await scene_changed
	assert(current_scene.scene_file_path == "res://Levels/lobby.tscn")
	assert(not paused and player_data.life == player_data.max_life)
	assert(player_data.coin == gold)
	current_scene.queue_free()
	await process_frame
	print("RESTART LOBBY TEST: passed")
	quit()
