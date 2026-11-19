extends SceneTree
const AUDIO = preload("res://Script/Audio/game_audio.gd")
const ADAPTER = preload("res://Script/Save/room_checkpoint_adapter.gd")
var manager: Node
func _initialize() -> void:
	call_deferred("run_test")
func wait_load() -> void:
	while manager.loading:
		await process_frame
func run_test() -> void:
	manager = root.get_node("CheckpointManager")
	manager.storage_path = "res://Tests/tutorial_progress_%d.json" % OS.get_process_id()
	assert(manager.create_slot(0))
	await wait_load()
	assert(not player_data.tutorial_completed and not player_data.attack_learned and not player_data.dash_learned)
	var player = current_scene.get_node("Player")
	player.start_sword_attack()
	player.start_dash()
	assert(not player.is_attacking and player.can_dash)
	var lobby_track: AudioStream = current_scene.get_node("LobbyMusic").stream
	assert(lobby_track in AUDIO.LOBBY)
	current_scene.travel_to_scene("res://Levels/stage_graph_template.tscn")
	await scene_changed
	while root.get_node("RoomLoading").busy:
		await process_frame
	var stage = current_scene
	var room = stage.current_room
	player = stage.player
	assert(stage.node_id == 0)
	assert(room.get_node("TutorialMusic").stream == lobby_track)
	room.interact()
	assert(not player_data.attack_learned)
	while room.step == room.Step.DIALOGUE:
		room.advance_dialogue()
	await process_frame
	assert(player_data.attack_learned and player_data.dash_learned and not player_data.tutorial_completed)
	player.set_physics_process(false)
	player.reset_states()
	player.start_sword_attack()
	assert(player.is_attacking and player.action_sound.stream in AUDIO.SLASH)
	player.reset_states()
	player.start_dash()
	assert(player.action_sound.stream == AUDIO.DASH)
	room.hostile.queue_free()
	await process_frame
	await process_frame
	assert(room.step == room.Step.REPORT)
	room.interact()
	room.advance_dialogue()
	assert(player_data.tutorial_completed and room.can_exit())
	assert(manager.list_checkpoints()[0].player.tutorial_completed)
	assert(manager.load_checkpoint(0))
	await wait_load()
	assert(current_scene.node_id == 1)
	assert(player_data.attack_learned and player_data.dash_learned)
	assert(current_scene.current_room.get_node("RoomMusic").stream in AUDIO.STAGE)
	assert(manager.list_checkpoints()[0].room_id == 1)
	var old := ADAPTER.capture(current_scene)
	old.player.erase("tutorial_completed")
	old.player.erase("attack_learned")
	old.player.erase("dash_learned")
	old.signature = ADAPTER.signature(old.scene, old.room_scene, true)
	assert(ADAPTER.validation_error(old).is_empty())
	ADAPTER.restore_player(old)
	assert(player_data.tutorial_completed and player_data.attack_learned)
	assert(manager.create_slot(1))
	await wait_load()
	assert(not player_data.tutorial_completed and not player_data.attack_learned and not player_data.dash_learned)
	assert(manager.load_checkpoint(0))
	await wait_load()
	assert(player_data.tutorial_completed and current_scene.node_id == 1)
	current_scene.get_node("PauseMenu").open_pause()
	current_scene.get_node("PauseMenu").restart()
	await scene_changed
	current_scene.travel_to_scene("res://Levels/stage_graph_template.tscn")
	await scene_changed
	while root.get_node("RoomLoading").busy:
		await process_frame
	assert(current_scene.node_id == 1)
	manager.enabled = false
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(manager.storage_path + suffix):
			DirAccess.remove_absolute(manager.storage_path + suffix)
	print("TUTORIAL PROGRESS TEST: passed")
	quit()
