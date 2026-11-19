extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	var stage = load("res://Levels/stage_graph_template.tscn").instantiate()
	stage.random_seed = 123456
	stage.preview_start_node = 1
	root.add_child(stage)
	current_scene = stage
	stage.player.set_physics_process(false)
	await process_frame
	var network = stage.current_room.get_node("PortalNetwork")
	assert(network.portals.size() == stage.current_room.layout.rewards.size() + 1)
	assert(not network.portals[0].unlocked)
	for portal in network.portals:
		assert(not portal.title.begins_with("Percabangan") and portal.title != "Pintu masuk")
	stage.player.global_position = network.portals[0].global_position
	network._process(0.1)
	assert(network.portals[0].unlocked)
	var target := 1
	stage.player.global_position = network.portals[target].global_position
	network._process(0.1)
	assert(network.portals[target].unlocked)
	var old_room = stage.current_room
	var old_coins := player_data.coin
	network.open_menu()
	assert(paused and network.owns_pause)
	await process_frame
	assert(network.menu.position.x >= 0 and network.menu.position.y >= 0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	network.menu.update_projection()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = network.menu.map_point(network.portals[0].position)
	network.menu._gui_input(click)
	assert(not paused)
	assert(stage.player.global_position == network.portals[0].global_position)
	assert(stage.player.velocity == Vector2.ZERO)
	assert(stage.current_room == old_room and player_data.coin == old_coins)
	network._process(0.1)
	network.open_menu()
	for i in range(network.portals.size()):
		if not network.portals[i].unlocked:
			network.teleport(i)
			assert(paused and stage.player.global_position == network.portals[0].global_position)
			break
	network.menu.update_projection()
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = network.menu.map_point(network.portals[target].position)
	network.menu._gui_input(tap)
	assert(not paused and stage.player.global_position == network.portals[target].global_position)
	for portal in network.portals:
		if portal.portal_id.begins_with("exit_"):
			assert(portal.position.distance_to(stage.current_room.layout.exit) > 45)
	stage.queue_free()
	await process_frame
	print("LEVEL PORTALS TEST: passed")
	quit()
