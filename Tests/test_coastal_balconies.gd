extends "res://Tests/test_coastal_physics.gd"

func routes() -> Array:
	var paths: Array = []
	for data in room.layout.rooms:
		for side in [-1, 1]:
			var surfaces: Array[Rect2] = []
			for platform in room.ROUTES.interior(data):
				var left: bool = platform.get_center().x < data.position.x + data.width / 2
				if left == (side < 0):
					surfaces.append(platform)
			if surfaces.is_empty():
				continue
			surfaces.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y > b.position.y)
			var x: float = data.position.x if side < 0 else data.position.x + data.width - 56
			surfaces.push_front(Rect2(x, data.floor, 24, 16))
			paths.append(surfaces)
	return paths

func after_routes() -> bool:
	return true
