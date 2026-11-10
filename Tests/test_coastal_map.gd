extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var room = load("res://Scenes/Rooms/Stage/coastal_room.tscn").instantiate()
	assert(room.prepare(42))
	root.add_child(room)
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = room.get_node("PlayerSpawn").global_position
	var overlay = room.get_node("CoastalMap")
	var original_surfaces: Array = overlay.view.collect_surfaces()
	assert(original_surfaces.size() > 20)
	assert(original_surfaces.size() == room.layout.shell.size() + room.layout.platforms.size())
	assert(room.get_meta("map_regions") == room.layout.regions)
	# Geometry must respond to a real platform, not a fabricated graph edge.
	var added := StaticBody2D.new()
	added.position = Vector2(70, 70)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(30, 10)
	added.add_child(shape)
	room.add_child(added)
	var changed_surfaces: Array = overlay.view.collect_surfaces()
	assert(changed_surfaces.size() == original_surfaces.size() + 1)
	assert(changed_surfaces.back().points[0] == Vector2(55, 65))
	added.free()
	assert(not overlay.view.visible)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	root.push_input(key)
	assert(overlay.view.visible and paused)
	if "--capture" in OS.get_cmdline_user_args():
		root.size = Vector2i(1100, 700)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Docs/coastal-map-preview.png")
	key.echo = true
	root.push_input(key)
	assert(overlay.view.visible and paused)
	key.echo = false
	root.push_input(key)
	assert(not overlay.view.visible and not paused)
	root.push_input(key)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	assert(not overlay.view.visible and not paused)
	paused = true # An unrelated pause must not be taken over by the map.
	root.push_input(key)
	assert(not overlay.view.visible and paused)
	paused = false
	root.push_input(key)
	room.queue_free()
	await process_frame
	assert(not paused)
	player.free()
	print("PASS: M toggles map, repeat ignored, Escape closes, pause restored on close/removal.")
	quit()
