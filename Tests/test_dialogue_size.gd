extends SceneTree
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	root.get_node("CheckpointManager").enabled = false
	var room = load("res://Scenes/Rooms/Stage/tutorial_room.tscn").instantiate()
	root.add_child(room)
	room.set_process(false)
	room.dialogue.show()
	room.body_text.text = "Halo!"
	for frame in range(5):
		room.position_dialogue()
		await process_frame
	var short_size: Vector2 = room.dialogue.size
	room.body_text.text = "Selamat datang, Rakshaka! Mari berlatih melompat dan menyerang sebelum melanjutkan perjalanan. ".repeat(3)
	for frame in range(5):
		room.position_dialogue()
		await process_frame
	assert(room.dialogue.size.x > short_size.x)
	assert(room.dialogue.size.y > short_size.y)
	assert(room.dialogue.size.x <= minf(480.0, root.get_visible_rect().size.x - 24.0))
	room.body_text.text = "Halo!"
	for frame in range(5):
		room.position_dialogue()
		await process_frame
	assert(room.dialogue.size.is_equal_approx(short_size))
	room.queue_free()
	await process_frame
	print("DIALOGUE SIZE TEST: passed")
	quit()
