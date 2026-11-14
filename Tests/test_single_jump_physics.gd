extends SceneTree
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("run_test")

func block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = rect.size
	shape.position = rect.get_center()
	body.add_child(shape)
	root.add_child(body)

func step(horizontal: float = 0) -> void:
	await physics_frame
	player.velocity.x = horizontal
	player.velocity.y += 1000.0 / 60.0
	player.move_and_slide()

func run_test() -> void:
	player_data.discovered_artifacts = []
	block(Rect2(-300, 0, 600, 32))
	block(Rect2(64, -180, 16, 180))
	player = load("res://Scenes/Player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(0, -24)
	for i in range(20):
		await step()
	assert(player.is_on_floor())
	assert(player.try_jump())
	for i in range(5):
		await step()
	assert(not player.is_on_floor())
	assert(not player.try_jump())
	# Reach the real wall in midair; wall jumping remains independent of the artifact.
	player.position = Vector2(54, -70)
	player.velocity = Vector2.ZERO
	player.set_facing(1)
	for i in range(4):
		await step(100)
	assert(player.is_on_wall())
	assert(player.can_wall_jump())
	assert(player.try_jump())
	assert(player.velocity.x < 0 and player.velocity.y == -350)
	assert(player.max_jump == 1)
	# The named artifact grants one extra airborne jump, not an unlimited chain.
	player.position = Vector2(-100, -90)
	player.velocity = Vector2.ZERO
	for i in range(2):
		await step()
	player_data.discovered_artifacts = ["Selendang Bidadari"]
	player.jump_count = 1
	assert(player.try_jump())
	await step()
	assert(not player.try_jump())
	player.queue_free()
	await process_frame
	print("PASS: real player ground jump, air-jump lock, wall contact/jump, Selendang second jump and third-jump rejection.")
	quit()
