extends RefCounted
## Hand-authored profiles in 16px units, instantiated at variable positions.
const PROFILES := [
	{"name": "LORONG PASANG", "width": 576, "height": 128, "crown": 0},
	{"name": "GUA KARANG", "width": 384, "height": 256, "crown": 64},
	{"name": "GALERI OMBAK", "width": 480, "height": 192, "crown": 96},
	{"name": "RELAUNG PESISIR", "width": 416, "height": 160, "crown": 64},
	{"name": "AULA MUTIARA", "width": 544, "height": 224, "crown": 32},
]

static func regions(profile: Dictionary, origin: Vector2) -> Array[Rect2]:
	var result: Array[Rect2] = [Rect2(origin, Vector2(profile.width, profile.height))]
	if profile.crown > 0:
		result.append(Rect2(origin + Vector2(64, -profile.crown), Vector2(profile.width - 160, profile.crown)))
	return result
