extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var stage: Node2D = load("res://Levels/modular_level_preview.tscn").instantiate()
	root.add_child(stage)
	stage.player.set_physics_process(false)
	var room: Node2D = stage.current_room
	assert(room.get_meta("modular_level", false))
	assert(stage.camera.limit_left == floori(room.layout.bounds.position.x))
	assert(stage.camera.limit_bottom == ceili(room.layout.bounds.end.y))
	var actual := {}
	for layer in room.find_children("*", "TileMapLayer", true, false):
		if layer.name not in ["Solid", "SocketCaps"]:
			continue
		for cell in layer.get_used_cells():
			actual[Vector2i((room.to_local(layer.to_global(layer.map_to_local(cell))) / 16).floor())] = true
	assert(actual == room.layout.solid)
	var overlay: CanvasLayer = room.get_node("CoastalMap")
	assert(overlay.view.collect_surfaces().size() == room.layout.shell.size() + room.layout.platforms.size())
	var key := InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	root.push_input(key)
	assert(paused and overlay.view.visible)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	assert(not paused and not overlay.view.visible)
	var interact := InputEventAction.new()
	interact.action = "ui_interact"
	interact.pressed = true
	var treasure: Node2D
	var artifact: Node2D
	for reward in room.get_node("Rewards").get_children():
		if reward.reward_kind == "artifact":
			artifact = reward
		else:
			treasure = reward
	var before := player_data.coin
	stage.player.global_position = treasure.global_position
	treasure._unhandled_input(interact)
	treasure._unhandled_input(interact)
	assert(treasure.opened and player_data.coin == before + 5)
	stage.player.global_position = artifact.global_position
	artifact._unhandled_input(interact)
	assert(artifact.opened and artifact.artifact_name in player_data.discovered_artifacts)
	var discovered := player_data.discovered_artifacts.size()
	artifact._unhandled_input(interact)
	assert(player_data.discovered_artifacts.size() == discovered)
	assert(not room.exit_open) # Optional rewards never unlock/skip combat.
	stage.queue_free()
	await process_frame
	print("PASS: active stage uses authored tiles, map matches, M/Escape pause works, camera bounds, treasure once, artifact catalog unlock.")
	quit()
