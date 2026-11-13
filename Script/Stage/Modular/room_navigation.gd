extends RefCounted
## Conservative baseline-jump graph over the actual painted cells (16px grid).
## Used to reject disconnected edits and to drive continuous physics regression tests.
const GEOMETRY = preload("res://Script/Stage/Modular/level_layout.gd")

static func build(layout: Dictionary) -> Dictionary:
	var landings := {}
	var ground: Dictionary = layout.solid.duplicate()
	ground.merge(layout.platform_cells)
	for cell: Vector2i in ground:
		if layout.air.has(cell + Vector2i.UP) and layout.air.has(cell + Vector2i.UP * 2):
			landings[cell] = true
	var surfaces := GEOMETRY.cell_rects(landings)
	var edges: Array[Array] = []
	for i in range(surfaces.size()):
		var targets: Array[int] = []
		for j in range(surfaces.size()):
			if i != j and can_step(surfaces[i], surfaces[j], layout.solid):
				targets.append(j)
		edges.append(targets)
	return {"surfaces": surfaces, "edges": edges}

static func can_step(source: Rect2, target: Rect2, solid: Dictionary) -> bool:
	if absf(source.position.y - target.position.y) > 40:
		return false
	var gap := maxf(0, maxf(target.position.x - source.end.x, source.position.x - target.end.x))
	if gap > 24:
		return false
	# To descend from a one-way platform, walk beyond an end. No drop-through skill required.
	if target.position.y > source.position.y and target.position.x >= source.position.x and target.end.x <= source.end.x:
		return false
	var points := step_points(source, target)
	var min_x := floori(minf(points.approach, points.landing) / 16)
	var max_x := floori(maxf(points.approach, points.landing) / 16)
	var floor_y := roundi(minf(source.position.y, target.position.y) / 16)
	for x in range(min_x, max_x + 1):
		for y in range(floor_y - 2, floor_y):
			if solid.has(Vector2i(x, y)):
				return false
	return true

static func step_points(source: Rect2, target: Rect2) -> Dictionary:
	var landing := clampf(source.get_center().x, target.position.x + 8, target.end.x - 8)
	if target.position.y > source.position.y:
		if target.position.x < source.position.x:
			landing = minf(source.position.x - 8, target.end.x - 8)
		else:
			landing = maxf(source.end.x + 8, target.position.x + 8)
	return {"approach": clampf(landing, source.position.x + 8, source.end.x - 8), "landing": landing}

static func surface_at(navigation: Dictionary, point: Vector2) -> int:
	var result := -1
	var distance := INF
	for i in range(navigation.surfaces.size()):
		var surface: Rect2 = navigation.surfaces[i]
		var drop := surface.position.y - point.y
		if point.x >= surface.position.x and point.x < surface.end.x and drop >= 0 and drop <= 48 and drop < distance:
			result = i
			distance = drop
	return result

static func route(navigation: Dictionary, from: int, to: int) -> Array[int]:
	if from < 0 or to < 0:
		return []
	var previous := {from: -1}
	var pending: Array[int] = [from]
	var cursor := 0
	while cursor < pending.size():
		var id := pending[cursor]
		cursor += 1
		if id == to:
			var path: Array[int] = []
			while id != -1:
				path.push_front(id)
				id = previous[id]
			return path
		for next in navigation.edges[id]:
			if not previous.has(next):
				previous[next] = id
				pending.append(next)
	return []
