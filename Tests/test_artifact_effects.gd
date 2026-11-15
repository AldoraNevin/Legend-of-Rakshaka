extends SceneTree
const STATUS = preload("res://Script/Enemies/artifact_status.gd")
const ADAPTER = preload("res://Script/Save/room_checkpoint_adapter.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run_test")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	player_data.progress_saver = func(): return true
	player_data.reset_progress()
	check(player_data.bestiary_master.artifacts.size() == 15, "Exactly fifteen artifacts")
	var player = load("res://Scenes/Player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	player.collect_artifact("Gadha Rujakpolo")
	check(player.speed == 90 and player_data.melee_damage(4) == 7, "Gadha damage/speed")
	player.collect_artifact("Jimat Kalimasada")
	check(is_equal_approx(player.speed, 108) and player_data.max_life == 125 and player_data.life == 125, "Jimat stats and health")
	player.collect_artifact("Golok Jakasembung")
	check(player_data.melee_damage(4, 0.0) == 18, "Critical multiplication")
	player.collect_artifact("Rencong Sakti")
	player_data.life = 30
	check(player_data.melee_damage(4) == 18, "Low health damage")
	player.collect_artifact("Selendang Bidadari")
	check(player.max_jump == 2, "Double jump")
	player.collect_artifact("Tombak Baru Klinting")
	check(is_equal_approx(absf(player.sword_area.scale.x), player.sword_base_scale.x * 1.5), "Melee reach")
	player.collect_artifact("Zirah Antakusuma")
	check(player_data.incoming_damage(20) == 15 and player_data.incoming_damage(20, true) == 10, "Armor and projectile armor")
	player.collect_artifact("Mustika Merah Delima")
	player.take_damage(100)
	check(player_data.life == 30 and player_data.fatal_shield_used, "Fatal shield retains HP")
	var saved := ADAPTER.capture_player()
	player_data.fatal_shield_used = false
	ADAPTER.restore_player({"player":saved})
	check(player_data.fatal_shield_used and player_data.max_life == 125, "Checkpoint preserves shield and max HP")
	player.apply_negative_effect("poison", 5)
	player.collect_artifact("Daun Kelor")
	check(player.negative_effects.is_empty() and player_data.life == 50, "Kelor cleanses/heals")
	player.collect_artifact("Air Tirta Amerta")
	player._tick_artifacts(2)
	check(player_data.life == 51, "Regeneration")
	player.collect_artifact("Pring Pethuk")
	player_data.enemy_resource_reward(3)
	check(player_data.coin == 5, "Enemy resource bonus")
	var enemy = load("res://Scenes/Enemies/Aul.tscn").instantiate()
	root.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.health = 30
	STATUS.apply(enemy, true, true)
	check(STATUS.tick(enemy, 0.5), "Stun active")
	STATUS.tick(enemy, 0.5)
	check(enemy.health == 29, "Bleed tick")
	check(not STATUS.tick(enemy, 0.01), "Stun expires")
	STATUS.tick(enemy, 1)
	STATUS.tick(enemy, 1)
	check(enemy.health == 27, "Bleed total damage")
	player.collect_artifact("Kujang Pusaka")
	player.is_invincible = false
	player.take_damage(20, enemy)
	check(enemy.health == 22, "Reflect attacker damage")
	player.collect_artifact("Pecut Samandiman")
	enemy.global_position = player.global_position + Vector2(50, 0)
	player.is_attacking = true
	player.sword_collider.disabled = false
	player.check_sword_hits()
	check(enemy in player.sword_hit_targets and player.shockwave_left > 0, "Forward shockwave hits enemy")
	player_data.restore_life()
	check(not player_data.fatal_shield_used, "Lobby restores shield")
	player.queue_free()
	enemy.queue_free()
	await process_frame
	print("ARTIFACT EFFECTS: %d failures" % failures)
	quit(1 if failures else 0)
