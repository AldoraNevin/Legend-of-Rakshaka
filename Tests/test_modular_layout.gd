extends SceneTree
const LEVEL = preload("res://Script/Stage/Modular/modular_level.gd")
const SETTINGS = preload("res://Scenes/Rooms/Modular/default_level_settings.tres")
const GRAPH = preload("res://Script/Stage/stage_graph.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var signatures := {}
	for seed_value in range(100):
		var layout := LEVEL.generate_layout(seed_value)
		var errors := LEVEL.validate_layout(layout)
		if not errors.is_empty():
			push_error("seed %d: %s" % [seed_value, errors])
			quit(1)
			return
		var treasure := 0
		var artifact := 0
		for reward in layout.rewards:
			treasure += int(reward.kind == "treasure")
			artifact += int(reward.kind == "artifact")
			assert(reward.room_id not in layout.graph.main_path)
		assert(treasure == SETTINGS.treasure_rooms and artifact == SETTINGS.artifact_rooms)
		assert(layout.bounds.size.y >= 512)
		signatures[str(layout.rooms.map(func(room): return [room.definition.id, room.position]))] = true
		if seed_value < 3:
			assert(layout == LEVEL.generate_layout(seed_value))
	assert(signatures.size() > 90)
	var small: Resource = SETTINGS.duplicate()
	small.main_rooms_min = 6
	small.main_rooms_max = 6
	small.treasure_rooms = 1
	small.artifact_rooms = 1
	small.branch_combat_min = 0
	small.branch_combat_max = 0
	for seed_value in range(5):
		var layout := LEVEL.generate_layout(seed_value, small)
		assert(LEVEL.validate_layout(layout).is_empty(), "Dense seed %d: %s" % [seed_value, LEVEL.validate_layout(layout)])
		assert(layout.rewards.size() == 2)
	var rich: Resource = SETTINGS.duplicate()
	rich.main_rooms_min = 20
	rich.main_rooms_max = 20
	rich.treasure_rooms = 4
	rich.artifact_rooms = 3
	var rich_layout := LEVEL.generate_layout(42, rich)
	assert(LEVEL.validate_layout(rich_layout).is_empty(), str(LEVEL.validate_layout(rich_layout)))
	assert(rich_layout.rewards.size() == 7)
	var invalid: Resource = SETTINGS.duplicate()
	invalid.main_rooms_min = 20
	invalid.main_rooms_max = 6
	assert(LEVEL.generate_layout(1, invalid).has("error"))
	var scene := load("res://Scenes/Rooms/Modular/modular_level.tscn") as PackedScene
	var errors := GRAPH.validate_template(scene, 1)
	assert(errors.is_empty(), str(errors))
	print("PASS: 100 connected non-overlapping seeds, reproducibility, reward branches, small/high-branch configuration, stage marker contract.")
	quit()
