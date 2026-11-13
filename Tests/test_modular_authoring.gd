extends SceneTree
const LEVEL = preload("res://Script/Stage/Modular/modular_level.gd")
const SETTINGS = preload("res://Scenes/Rooms/Modular/default_level_settings.tres")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var template: Node2D = load("res://Scenes/Rooms/Modular/entrance.tscn").instantiate()
	var painted := Vector2i(5, template.size_in_tiles.y - 1)
	template.get_node("Solid").set_cell(painted, 0, Vector2i(7, 1))
	template.get_node("Decorations").set_cell(Vector2i(5, 5), 0, Vector2i(6, 3))
	assert(template.validate().is_empty())
	var scene := PackedScene.new()
	assert(scene.pack(template) == OK)
	var config: Resource = SETTINGS.duplicate()
	config.room_templates = SETTINGS.room_templates.duplicate()
	config.room_templates[0] = scene
	var level := LEVEL.new()
	level.settings = config
	assert(level.prepare(42))
	var instance := level.get_node("Rooms").get_child(0)
	assert(instance.get_node("Solid").get_cell_atlas_coords(painted) == Vector2i(7, 1))
	assert(instance.get_node("Decorations").get_cell_atlas_coords(Vector2i(5, 5)) == Vector2i(6, 3))
	for data in level.layout.rooms:
		var module := level.get_node("Rooms").get_child(data.id)
		for socket in data.definition.sockets:
			for cell in socket.caps:
				assert((module.get_node("SocketCaps").get_cell_source_id(cell) == -1) == (socket.id in data.used_sockets))
	# An authored obstacle at the connector is rejected, never silently erased.
	var cap: Vector2i = template.describe().sockets[0].caps[0]
	template.get_node("Solid").set_cell(cap, 0, Vector2i(1, 1))
	assert(not template.validate().is_empty())
	template.get_node("Solid").erase_cell(cap)
	# A full interior wall must fail reachability even when markers remain valid.
	for y in range(1, template.size_in_tiles.y - 1):
		template.get_node("Solid").set_cell(Vector2i(8, y), 0, Vector2i(1, 1))
	assert(template.validate().is_empty())
	var blocked := PackedScene.new()
	blocked.pack(template)
	config.room_templates[0] = blocked
	assert(not LEVEL.validate_layout(LEVEL.generate_layout(42, config)).is_empty())
	# Removing a required layer returns an authoring error instead of describing null nodes.
	template.get_node("Solid").free()
	var incomplete := PackedScene.new()
	incomplete.pack(template)
	config.room_templates[0] = incomplete
	assert(LEVEL.generate_layout(42, config).has("error"))
	level.free()
	template.free()
	print("PASS: painted Solid/Decorations preserved; only used caps open; blocked sockets and disconnected edits rejected.")
	quit()
