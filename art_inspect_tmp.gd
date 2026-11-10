extends SceneTree
func _initialize() -> void:
	call_deferred("inspect_stage")
func inspect_stage() -> void:
	var stage = load("res://Levels/room_1_preview.tscn").instantiate()
	stage.random_seed = 42
	root.add_child(stage)
	current_scene = stage
	await process_frame
	paused = true
