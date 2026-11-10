@tool
extends Resource
## Authoring resource: edit these values in the Godot Inspector.
@export var template_id := ""
@export var display_name := ""
@export var size := Vector2(384, 256)
@export var air_regions: Array[Rect2] = []
@export var sockets: Array[Resource] = []
@export var allowed_kinds := PackedStringArray(["entrance", "combat", "exit", "treasure"])
@export var anchor := Vector2(64, 222)
@export_group("Manual decorations")
## Scene in room-local coordinates. A path avoids a resource cycle with its editor guide.
@export_file("*.tscn") var decoration_scene := ""
@export var automatic_decorations := true
## FloorTiles replaces automatic art on the bottom row; collision stays procedural.
@export var manual_floor := false
@export_group("Interior platforms")
@export var automatic_balconies := true
## Local Rect2: x/y = top-left; width = landing area; height = 8.
@export var extra_platforms: Array[Rect2] = []

func socket(side: String) -> Resource:
	for entry in sockets:
		if entry.side == side:
			return entry
	return null

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if size.x < 384 or size.y < 192 or int(size.x) % 32 != 0 or int(size.y) % 32 != 0:
		errors.append(template_id + ": size must use 32px multiples, at least 384 x 192.")
	if anchor != Vector2(64, size.y - 34):
		errors.append(template_id + ": anchor must be (64, height - 34).")
	var bounds := Rect2(Vector2.ZERO, size)
	for platform in extra_platforms:
		if platform.size.y != 8 or platform.size.x < 24 or not bounds.encloses(platform):
			errors.append(template_id + ": platform must be inside room, width >= 24, height = 8.")
		var safe_foothold := platform.position.y == size.y - 32 and (platform.end.x <= 24 or (platform.position.x >= size.x - 56 and platform.end.x <= size.x - 24))
		if (platform.position.y > size.y - 64 and not safe_foothold) or (platform.end.x > size.x / 2 - 112 and platform.position.x < size.x / 2 + 112):
			errors.append(template_id + ": custom platform must stay >= 64px above floor and outside center shaft + landing clearance.")
		for x in range(int(platform.position.x), int(platform.end.x), 8):
			for y in range(int(platform.position.y) - 32, int(platform.end.y), 8):
				var covered := false
				for air in air_regions:
					if air.has_point(Vector2(x + 4, y + 4)):
						covered = true
				if not covered:
					errors.append(template_id + ": platform needs 32px clear headroom inside air regions.")
	for rect in air_regions:
		if not bounds.encloses(rect) or rect.size.x <= 0 or rect.size.y <= 0:
			errors.append(template_id + ": air region outside bounds.")
		for value in [rect.position.x, rect.position.y, rect.size.x, rect.size.y]:
			if fposmod(value, 16.0) != 0:
				errors.append(template_id + ": air regions must align to 16px.")
	var seen := {}
	for entry in sockets:
		if seen.has(entry.side):
			errors.append(template_id + ": duplicate socket side.")
		seen[entry.side] = true
		var expected := Vector2.ZERO
		match entry.side:
			"left": expected = Vector2(0, size.y - 64)
			"right": expected = Vector2(size.x, size.y - 64)
			"up": expected = Vector2(size.x / 2, 0)
			"down": expected = Vector2(size.x / 2, size.y)
		if entry.position != expected or entry.opening != (192 if entry.side in ["up", "down"] else 128):
			errors.append(template_id + ": incompatible socket opening/position.")
	# Every template guarantees a clear floor band and center climbing shaft.
	for region in [Rect2(0, size.y - 128, size.x, 128), Rect2(size.x / 2 - 96, 0, 192, size.y)]:
		for x in range(int(region.position.x), int(region.end.x), 16):
			for y in range(int(region.position.y), int(region.end.y), 16):
				var covered := false
				for rect in air_regions:
					if rect.has_point(Vector2(x + 8, y + 8)):
						covered = true
				if not covered:
					errors.append(template_id + ": floor band or center shaft obstructed.")
	return errors
