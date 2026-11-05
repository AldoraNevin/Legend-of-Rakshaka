extends "res://Tests/test_coastal_physics.gd"
func routes() -> Array:
	var result: Array = []
	for branch in room.layout.branches:
		var round_trip: Array = branch.route.duplicate()
		for surface in branch.return_route:
			if surface != round_trip.back():
				round_trip.append(surface)
		result.append(round_trip)
	return result

func after_routes() -> bool:
	return true
