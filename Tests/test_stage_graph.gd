extends SceneTree
const Graph = preload("res://Script/Stage/stage_graph.gd")

func _initialize() -> void:
	var castle := load("res://Scenes/Rooms/Stage/room_1_castle.tscn") as PackedScene
	assert(Graph.validate_template(castle, 1).is_empty())
	assert(not Graph.validate_template(castle, 2).is_empty())
	for seed_value in range(100):
		var graph := Graph.generate(seed_value)
		assert(Graph.validate(graph).is_empty())
		assert(graph == Graph.generate(seed_value))
		assert(graph.size() == 9)
		for i in range(graph.size()):
			assert(graph[i].label == Graph.LABELS[i])
	var wrong_order := Graph.generate(12)
	wrong_order[4].kind = "combat"
	assert(not Graph.validate(wrong_order).is_empty())
	var broken := Graph.generate(12)
	broken[0].next = [0]
	assert(not Graph.validate(broken).is_empty())
	broken = Graph.generate(12)
	broken[1].next = []
	assert(not Graph.validate(broken).is_empty())
	for kind in ["start", "combat", "rest", "elite", "boss"]:
		for variant in range(2):
			var scene := load("res://Scenes/Rooms/Stage/%s_%d.tscn" % [kind, variant]) as PackedScene
			assert(Graph.validate_template(scene, 2).is_empty())
			assert(not Graph.validate_template(scene, 3).is_empty())
	print("PASS: 100 fixed-sequence graphs, exact room order, reproducible seeds, invalid edges/dead ends, 10 templates and door capacity.")
	quit()
