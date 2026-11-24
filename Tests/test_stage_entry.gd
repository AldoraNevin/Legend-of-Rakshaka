extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	var loader := root.get_node("RoomLoading")
	for completed in [false, true]:
		player_data.tutorial_completed = completed
		assert(await loader.change_scene("res://Levels/lobby.tscn") == OK)
		current_scene.travel_to_scene("")
		await process_frame
		while loader.busy or current_scene.scene_file_path == "res://Levels/lobby.tscn":
			await process_frame
		var stage := current_scene
		assert(is_instance_valid(stage.current_room), "Stage must contain a generated room")
		assert(stage.player.is_physics_processing(), "Generation must not disable the player")
		assert(stage.node_id == (1 if completed else 0))
		stage.player.set_physics_process(false)
		for boss_variant in [0, 1]:
			var scene := load("res://Scenes/Rooms/Stage/boss_%d.tscn" % boss_variant) as PackedScene
			var room := scene.instantiate()
			root.add_child(room)
			var boss := room.get_node("NyiRoroKidul")
			assert(boss.has_method("take_damage"))
			assert(boss.health == boss.max_health)
			boss.player = stage.player
			boss.casting = true
			boss._on_animation_finished()
			var spear := boss.get_child(boss.get_child_count() - 1)
			assert(spear is Node2D and spear.get("boss") == boss)
			boss.take_damage(boss.max_health)
			assert(boss.is_dead and boss.health == 0)
			for frame in range(180):
				if not is_instance_valid(boss):
					break
				await create_timer(0.02).timeout
			assert(not is_instance_valid(boss), "Boss must leave the tree after death")
			room.queue_free()
	current_scene.queue_free()
	await process_frame
	print("STAGE ENTRY TEST: passed (new/returning player, both boss variants)")
	quit()
