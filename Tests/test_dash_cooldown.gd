extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	player_data.dash_learned = true
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(2000, 32)
	shape.position.y = 16
	floor_body.add_child(shape)
	root.add_child(floor_body)
	var player = load("res://Scenes/Player/player.tscn").instantiate()
	player.position = Vector2(0, -24)
	root.add_child(player)
	await create_timer(0.5).timeout
	assert(player.is_on_floor())
	assert(player.dash_cooldown == 1.0)
	player.start_dash()
	await create_timer(player.dash_time + 0.2).timeout
	assert(player.is_on_floor() and not player.can_dash)
	player.start_dash()
	assert(player.current_state != player.PlayerStates.DASH)
	paused = true
	await create_timer(1.1).timeout
	assert(not player.can_dash, "Pause must not consume the cooldown")
	paused = false
	await create_timer(0.9).timeout
	assert(player.can_dash and not player.dash_cooldown_active)
	player.queue_free()
	floor_body.queue_free()
	await process_frame
	print("DASH COOLDOWN TEST: passed")
	quit()
