extends SceneTree
const ADAPTER := preload("res://Script/Save/room_checkpoint_adapter.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_test")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	player_data.reset_progress()
	check(player_data.life == 100 and player_data.max_life == 100, "New progress starts with 100 HP")
	change_scene_to_file("res://Levels/lobby.tscn")
	await scene_changed
	paused = true
	var player = current_scene.get_node("Player")
	var gui = current_scene.get_node("GUI")
	var aul = load("res://Scenes/Enemies/Aul.tscn").instantiate()
	var kuntilanak = load("res://Script/Enemies/kuntilanak.tscn").instantiate()
	check(aul.damage == 12 and kuntilanak.contact_damage == 20, "Enemy scenes have distinct damage")
	player.take_damage(aul.damage)
	check(player_data.life == 88, "Aul removes 12 HP")
	player.take_damage(kuntilanak.contact_damage)
	check(player_data.life == 88, "Invulnerability prevents repeated damage")
	player.is_invincible = false
	player.take_damage(kuntilanak.contact_damage)
	check(player_data.life == 68, "Kuntilanak removes 20 HP")
	gui.refresh()
	check(gui.health_hud.get_node("HealthBar").value == 68, "HUD fill tracks numeric HP")
	check(gui.health_hud.get_node("HealthText").text == "HP 68 / 100", "HUD displays exact HP")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	var spike = load("res://Script/Interactables/damage_zone.gd").new()
	player.is_invincible = false
	spike._on_body_entered(player)
	check(player_data.life == 53, "Spike uses damage and hit protection")
	spike._on_body_entered(player)
	check(player_data.life == 53, "Spike cannot bypass invulnerability")
	player_data.coin = 100
	check(player_data.buy_upgrade("max_life"), "Vitality upgrade remains available")
	check(player_data.max_life == 100 and player_data.life == 100, "Vitality heals without exceeding 100 HP")
	check(player_data.incoming_damage(20) == 19, "Vitality reduces incoming damage by 5 percent")
	var saved := ADAPTER.capture_player()
	check(saved.health_version == 2 and ADAPTER.player_error(saved).is_empty(), "Point-based health saves are valid")
	saved.life = 68
	ADAPTER.restore_player({"player": saved})
	check(player_data.life == 68, "Modern saves restore exact HP")
	saved.erase("health_version")
	saved.life = 3
	saved.max_life = 4
	ADAPTER.restore_player({"player": saved})
	check(player_data.life == 75 and player_data.max_life == 100, "Old heart saves preserve HP percentage")
	player.is_invincible = false
	player.take_damage(1000)
	check(player_data.life == 0 and player.is_dead, "Lethal damage clamps HP to zero and triggers death")
	aul.free()
	kuntilanak.free()
	spike.free()
	current_scene.queue_free()
	await process_frame
	paused = false
	print("HEALTH POINT TEST: %d failures" % failures)
	quit(1 if failures else 0)
