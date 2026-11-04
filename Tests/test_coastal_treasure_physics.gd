extends "res://Tests/test_coastal_physics.gd"
func routes() -> Array:
	var result: Array = []
	for branch in room.layout.branches:
		result.append(branch.route)
	return result

func after_routes() -> bool:
	# Return through the clear strip beside each one-way staircase, without teleport.
	for branch in room.layout.branches:
		var ledge: Rect2 = branch.route.back()
		body.position = Vector2(ledge.get_center().x, ledge.position.y - 16.1)
		body.velocity = Vector2.ZERO
		await physics_frame
		if not await move_to(branch.shaft.position.x + 12, branch.shaft.end.y):
			return false
	return true
