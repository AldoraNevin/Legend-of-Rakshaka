extends SceneTree
const ADAPTER = preload("res://Script/Save/room_checkpoint_adapter.gd")
var manager: Node
func _initialize() -> void:
	call_deferred("run_test")
func wait_load() -> void:
	while manager.loading:
		await process_frame
func run_test() -> void:
	manager = root.get_node("CheckpointManager")
	manager.storage_path = "res://Tests/sukma_skill_%d.json" % OS.get_process_id()
	assert(manager.create_slot(0))
	await wait_load()
	assert(player_data.healing_capacity() == 1 and player_data.healing_cooldown() == 30)
	assert(not player_data.can_upgrade("max_life"))
	assert(not player_data.use_healing_skill())
	player_data.coin = 10000
	assert(player_data.buy_upgrade("max_life"))
	assert(player_data.max_life == 105)
	await process_frame
	current_scene.open_upgrade_panel()
	assert(paused)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	current_scene.upgrade_panel.hide()
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hud="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--hud="))
	assert(not paused)
	for key in player_data.UPGRADE_DATA:
		while player_data.can_upgrade(key):
			assert(player_data.buy_upgrade(key))
		assert(not player_data.buy_upgrade(key))
	assert(player_data.max_life == 140)
	assert(player_data.healing_capacity() == 5 and player_data.skill_charges == 5)
	assert(is_equal_approx(player_data.healing_cooldown(), 18))
	assert(is_equal_approx(player_data.melee_damage(1), 1.4))
	var enemy = load("res://Scenes/Enemies/Aul.tscn").instantiate()
	root.add_child(enemy)
	var health_before: float = enemy.health
	enemy.take_damage(player_data.melee_damage(1))
	assert(is_equal_approx(enemy.health, health_before - 1.4))
	enemy.queue_free()
	# Prevent real frame time from affecting the deterministic cooldown assertions.
	root.get_node("HealingSkill").set_process(false)
	player_data.life = 80
	assert(player_data.use_healing_skill())
	assert(player_data.life == 90 and player_data.skill_charges == 4)
	assert(not player_data.use_healing_skill())
	player_data.tick_healing_skill(2)
	assert(not player_data.use_healing_skill())
	player_data.tick_healing_skill(1.1)
	assert(player_data.use_healing_skill())
	assert(player_data.life == 100 and player_data.skill_charges == 3)
	player_data.tick_healing_skill(14.9)
	assert(player_data.skill_charges == 4)
	assert(player_data.save_to_json())
	var saved := player_data.capture_healing_skill()
	assert(manager.load_checkpoint(0))
	await wait_load()
	assert(player_data.upgrade_levels.max_life == 8 and player_data.max_life == 140)
	assert(player_data.capture_healing_skill() == saved)
	player_data.tick_healing_skill(18)
	assert(player_data.skill_charges == 5)
	player_data.life = 139
	assert(player_data.use_healing_skill() and player_data.life == 140)
	var before := player_data.skill_charges
	assert(not player_data.use_healing_skill() and player_data.skill_charges == before)
	assert(manager.create_slot(1))
	await wait_load()
	assert(player_data.skill_charges == 1 and player_data.healing_capacity() == 1 and player_data.max_life == 100)
	var legacy := ADAPTER.capture_player()
	legacy.erase("upgrade_version")
	legacy.erase("healing_skill")
	legacy.upgrades = {"max_life": 2, "sword": 1, "speed": 2, "jump": 1}
	assert(ADAPTER.player_error(legacy).is_empty())
	ADAPTER.restore_player({"player": legacy})
	assert(player_data.max_life == 110 and player_data.healing_capacity() == 3 and player_data.skill_charges == 3)
	manager.enabled = false
	current_scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(manager.storage_path + suffix):
			DirAccess.remove_absolute(manager.storage_path + suffix)
	print("SUKMA SKILL UPGRADES TEST: passed")
	quit()
