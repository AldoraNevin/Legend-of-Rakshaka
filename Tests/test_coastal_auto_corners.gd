extends SceneTree
const CORNERS = preload("res://Script/Stage/coastal_auto_corners.gd")
func _initialize() -> void:
	var air := {}
	for x in range(4):
		for y in range(4):
			air[Vector2i(x, y)] = true
	var corners := CORNERS.find_corners(air)
	assert(corners.size() == 4)
	assert(corners[Vector2i(0, 0)] == Vector2(1, -1))
	assert(corners[Vector2i(3, 0)] == Vector2(-1, -1))
	assert(corners[Vector2i(0, 3)] == Vector2(1, 1))
	assert(corners[Vector2i(3, 3)] == Vector2(-1, 1))
	# Opening a passage removes the former corner instead of sealing the doorway.
	air[Vector2i(-1, 0)] = true
	assert(not CORNERS.find_corners(air).has(Vector2i(0, 0)))
	var pcg = load("res://Script/Stage/coastal_room_pcg.gd")
	for seed_value in [42, 91, 1000045]:
		var layout = pcg.generate_layout(seed_value)
		var cells = pcg.rasterize(layout.regions)
		var found := CORNERS.find_corners(cells)
		assert(found.size() > 4)
		for cell in found:
			assert(cells.has(cell))
	print("PASS: four corner directions, open passages, and three generated layouts.")
	quit()
