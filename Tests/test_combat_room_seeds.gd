extends SceneTree
const Graph = preload("res://Script/Stage/stage_graph.gd")
const Castle = preload("res://Script/Stage/coastal_room_pcg.gd")

func _initialize() -> void:
	for main_seed in [0, 1, 42, 4294967295]:
		var graph := Graph.generate(main_seed)
		var repeated := Graph.generate(main_seed)
		var changed := Graph.generate(main_seed + 1)
		var seeds := {}
		for room in graph:
			if room.kind != "combat":
				continue
			assert(not seeds.has(room.room_seed))
			seeds[room.room_seed] = true
			assert(room.room_seed == repeated[room.id].room_seed)
			assert(room.room_seed != changed[room.id].room_seed)
			var layout := Castle.generate_layout(room.room_seed)
			assert(Castle.validate_layout(layout).is_empty())
			assert(layout == Castle.generate_layout(repeated[room.id].room_seed))
		assert(seeds.size() == 6)
	print("PASS: six distinct combat seeds per run, reproducible layouts, main-seed propagation, valid module routes.")
	quit()
