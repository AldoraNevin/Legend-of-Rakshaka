extends SceneTree
const ADAPTER := preload("res://Script/Save/room_checkpoint_adapter.gd")
var failures := 0
var manager: Node

func _initialize() -> void:
	call_deferred("run_test")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func wait_for_load() -> void:
	for frame in range(30):
		await process_frame
		if not manager.loading:
			break
	paused = true

func run_test() -> void:
	manager = root.get_node("CheckpointManager")
	manager.storage_path = "res://Tests/slot_test_%d.json" % OS.get_process_id()
	check(manager.list_checkpoints() == [null, null, null], "Fresh installation has three empty slots")
	change_scene_to_file("res://addons/maaacks_menus_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn")
	await scene_changed
	await process_frame
	var menu_music = current_scene.get_node("BackgroundMusicPlayer")
	check(menu_music.playing, "Menu BGM starts normally")
	check(manager.create_slot(0), "Empty slot creates a new game")
	await wait_for_load()
	check(current_scene.scene_file_path == manager.LOBBY, "New game opens lobby")
	await process_frame
	await process_frame
	check(not has_menu_music(root), "Menu BGM must stop after loading lobby")
	check(current_scene.get_node("LobbyMusic").playing, "Lobby BGM remains playing")
	check(player_data.coin == 0 and player_data.discovered_enemies.is_empty(), "New slot starts clean")
	check(not manager.create_slot(0), "Creating over an occupied slot is rejected")
	player_data.add_gold(20)
	player_data.discover_enemy("Aul")
	player_data.discover_artifact("Kujang Pusaka")
	check(player_data.buy_upgrade("sword"), "Upgrade can be purchased")
	var saved: Dictionary = manager.list_checkpoints()[0]
	check(saved.player.coin == 16 and saved.player.upgrades.sword == 1, "Gold spending and upgrades autosave together")
	check("Aul" in saved.player.enemies and "Kujang Pusaka" in saved.player.artifacts, "Discoveries autosave immediately")
	var stage = load("res://Levels/stage_graph_template.tscn").instantiate()
	stage.random_seed = 123456
	current_scene.queue_free()
	await process_frame
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	stage.node_id = 1
	stage.load_next_room()
	await process_frame
	await process_frame
	player_data.add_gold(7)
	saved = manager.list_checkpoints()[0]
	check(saved.room_id == 1 and saved.seed == 123456, "Room changes update the selected slot")
	check(saved.player.coin == 23, "Gold found mid-stage persists immediately")
	check(manager.list_checkpoints()[1] == null, "Room changes never consume another slot")
	var bad := saved.duplicate(true)
	bad.signature = "old-level-version"
	check(not manager.checkpoint_error(bad).is_empty(), "Incompatible room is rejected")
	check(manager.create_slot(1), "Second slot creates independent progress")
	await wait_for_load()
	check(player_data.coin == 0 and player_data.upgrade_levels.sword == 0, "Second slot resets gold and upgrades")
	check(player_data.discovered_enemies.is_empty() and player_data.discovered_artifacts.is_empty(), "Collections are isolated")
	player_data.add_gold(3)
	check(manager.load_checkpoint(0), "First slot loads again")
	await wait_for_load()
	check(current_scene.node_id == 1 and current_scene.stage_seed == 123456, "Load restores last room and seed")
	check(player_data.coin == 23 and player_data.upgrade_levels.sword == 1, "Load restores latest resources, not room-entry resources")
	check("Aul" in player_data.discovered_enemies and "Kujang Pusaka" in player_data.discovered_artifacts, "Load restores the selected collections")
	check(current_scene.player.sword_damage == 2, "Restored upgrade applies to player")
	check(current_scene.player.global_position.distance_to(current_scene.current_room.get_node("PlayerSpawn").global_position) < 10.0, "Load starts at room entrance")
	player_data.add_gold(1)
	check(manager.list_checkpoints()[1].player.coin == 3, "Autosave only updates the active slot")
	# Exercise the real pause Leave route, then simulate a fresh process selection.
	var pause_menu = current_scene.get_node("PauseMenu")
	paused = false
	pause_menu.open_pause()
	pause_menu.leave()
	await scene_changed
	check(manager.list_checkpoints()[0].room_id == 1, "Leaving mid-stage retains the last room")
	await process_frame
	check(current_scene.get_node("BackgroundMusicPlayer").playing, "Returning to menu restarts menu BGM")
	manager.active_slot = -1
	player_data.reset_progress()
	check(manager.load_checkpoint(0), "Progress survives a new session")
	await wait_for_load()
	check(player_data.coin == 24 and current_scene.node_id == 1, "New session restores latest progress and stage")
	await process_frame
	await process_frame
	check(not has_menu_music(root), "Menu BGM must not resume after loading a stage")
	manager.save_progress()
	var corrupt := FileAccess.open(manager.storage_path, FileAccess.WRITE)
	corrupt.store_string("broken json")
	corrupt.close()
	check(manager.list_checkpoints()[0].player.coin == 24, "Corrupt primary recovers backup")
	player_data.add_gold(2)
	check(manager.list_checkpoints()[0].player.coin == 26, "Recovered save can be updated")
	check(manager.list_checkpoints()[1].player.coin == 3, "Recovery preserves other slots")
	manager.enabled = false
	current_scene.queue_free()
	await process_frame
	paused = false
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(manager.storage_path + suffix):
			DirAccess.remove_absolute(manager.storage_path + suffix)
	print("SAVE SLOT TEST: %d failures" % failures)
	quit(1 if failures else 0)

func has_menu_music(node: Node) -> bool:
	if node is AudioStreamPlayer and node.playing and node.stream != null:
		if node.stream.resource_path.ends_with("Main Menu Themen.ogg"):
			return true
	for child in node.get_children():
		if has_menu_music(child):
			return true
	return false
