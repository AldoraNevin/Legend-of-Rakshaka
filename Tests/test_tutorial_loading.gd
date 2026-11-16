extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	change_scene_to_file("res://Levels/lobby.tscn")
	await scene_changed
	current_scene.travel_to_scene("res://Levels/stage_graph_template.tscn")
	for i in range(300):
		await create_timer(0.1).timeout
		if current_scene != null and current_scene.scene_file_path == "res://Levels/stage_graph_template.tscn":
			print("TUTORIAL LOAD: passed")
			quit()
			return
	push_error("Tutorial loading timed out")
	quit(1)
