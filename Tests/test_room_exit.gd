extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var stage = load("res://Levels/stage_graph_template.tscn").instantiate()
	stage.random_seed = 42
	stage.preview_start_node = 1
	root.add_child(stage)
	stage.set_process(false)
	stage.player.set_physics_process(false)
	assert(stage.door_root.get_child_count() == 0)
	var count: int = stage.active_enemies.size()
	assert(count > 0)
	for enemy in stage.active_enemies.duplicate():
		enemy.queue_free()
	await process_frame
	await process_frame
	assert(stage.current_state == stage.RoomState.DOOR_SELECT)
	assert(is_instance_valid(stage.active_reward))
	assert(not stage.current_room.get_node("OptionalTreasure").opened)
	assert(stage.current_room.get_node("ExitHint").text == "EXIT TERBUKA")
	assert(stage.door_root.get_child_count() == 1)
	assert(stage.door_root.get_child(0).global_position == stage.get_template_door_positions()[0])
	stage._enter_graph_door(stage.player, 2)
	await process_frame
	await process_frame
	assert(stage.node_id == 2)
	assert(stage.current_state == stage.RoomState.COMBAT)
	assert(not stage.active_enemies.is_empty())
	assert(stage.door_root.get_child_count() == 0)
	stage.queue_free()
	await process_frame
	print("PASS: clearing combat opens exit before collecting reward; exit loads next room.")
	quit()
