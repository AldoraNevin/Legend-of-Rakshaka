extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run_test")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run_test() -> void:
	root.size = Vector2i(1080, 608)
	var manager = root.get_node("CheckpointManager")
	manager.enabled = false
	manager.active_slot = -1
	var cheats = root.get_node("CheatCodes")
	check("Masukkan" in cheats.execute(""), "Empty code handled")
	check("tidak dikenal" in cheats.execute("ROOM99"), "Invalid destination rejected")
	check("lobby" in cheats.execute("ROOM2"), "No-stage jump rejected")
	var stage = load("res://Levels/stage_graph_template.tscn").instantiate()
	stage.random_seed = 123456
	paused = true
	root.add_child(stage)
	current_scene = stage
	await process_frame
	check(is_instance_valid(stage.current_room), "Real stage loads")
	var player = stage.player
	player_data.life = 100
	check("aktif" in cheats.execute(" godmode on "), "Case and whitespace accepted")
	player.is_invincible = false
	player.take_damage(10)
	check(player_data.life == 100, "God mode blocks damage")
	cheats.execute("GODMODE OFF")
	player.take_damage(10)
	check(player_data.life < 100, "Damage works again after OFF")
	player.is_invincible = false
	player.current_state = player.PlayerStates.MOVE
	cheats.execute("DOUBLEJUMP ON")
	player.jump_count = 1
	check(player.try_jump(), "Extra airborne jump works")
	check(not player.try_jump(), "No third jump")
	cheats.execute("DOUBLEJUMP OFF")
	player.refresh_jump_ability()
	check(player.max_jump == (2 if player_data.has_artifact(player.double_jump_artifact_id) else 1), "OFF restores artifact ability")
	var pause = stage.get_node("PauseMenu")
	paused = false
	pause.open_pause()
	pause.menu.get_node("CheatButton").pressed.emit()
	check(paused and pause.cheats.visible, "Cheat keeps pause")
	pause.cheats.get_node("CodeInput").text = "ROOM2"
	pause.cheats.get_node("CodeInput").text_submitted.emit("ROOM2")
	await process_frame
	await process_frame
	check(stage.node_id == 2 and is_instance_valid(stage.current_room), "Room jump via UI works")
	check(paused and pause.cheats.visible, "Room jump stays paused")
	check(player.global_position.distance_to(stage.current_room.get_node("PlayerSpawn").global_position) < 10, "Room entry spawn restored")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	pause._input(escape)
	check(paused and pause.menu.visible and not pause.cheats.visible, "Escape returns to pause")
	pause._input(escape)
	check(not paused, "Second escape resumes")
	stage.queue_free()
	await process_frame
	await process_frame
	print("CHEAT TEST: %d failures" % failures)
	quit(1 if failures else 0)
