extends RefCounted
## Topology only. Spatial embedding and room shapes belong to the layout generator.
static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := rng.randi_range(6, 8)
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var main_path: Array[int] = []
	for i in range(count):
		var kind := "combat"
		if i == 0:
			kind = "entrance"
		elif i == count - 1:
			kind = "exit"
		nodes.append({"index": i, "kind": kind})
		main_path.append(i)
		if i > 0:
			edges.append({"from": i - 1, "to": i, "kind": "main"})
	var forks: Array[int] = [1, count - 3]
	for fork in forks:
		var id := nodes.size()
		nodes.append({"index": id, "kind": "treasure"})
		edges.append({"from": fork, "to": id, "kind": "optional"})
	return {"nodes": nodes, "edges": edges, "main_path": main_path, "treasure_id": count, "fork": forks[0]}

static func validate(graph: Dictionary) -> PackedStringArray:
	var nodes: Array = graph.get("nodes", [])
	var path: Array = graph.get("main_path", [])
	if nodes.is_empty() or path.size() < 2:
		return PackedStringArray(["Graph kosong."])
	var reached := {0: true}
	for edge in graph.get("edges", []):
		if edge.from < 0 or edge.to < 0 or edge.from >= nodes.size() or edge.to >= nodes.size():
			return PackedStringArray(["Koneksi tidak valid."])
	for pass_index in range(nodes.size()):
		for edge in graph.edges:
			if edge.kind == "main" and reached.has(edge.from):
				reached[edge.to] = true
	for id in path:
		if id < 0 or id >= nodes.size() or not reached.has(id) or nodes[id].kind == "treasure":
			return PackedStringArray(["Jalur utama terputus atau melewati treasure."])
	if nodes[path.front()].kind != "entrance" or nodes[path.back()].kind != "exit":
		return PackedStringArray(["Entrance/exit tidak sesuai."])
	return PackedStringArray()
