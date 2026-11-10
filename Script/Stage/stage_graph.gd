extends RefCounted
## Fixed stage sequence after the lobby; seed selects room variants and per-combat-room layouts.
const KINDS = ["start", "combat", "combat", "combat", "elite", "combat", "combat", "combat", "boss"]
const LABELS = ["Safe", "Room 1", "Room 2", "Room 3", "Elite", "Room 4", "Room 5", "Room 6", "Boss"]

static func generate(seed_value: int) -> Array[Dictionary]:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var graph: Array[Dictionary] = []
	var combat_number := 0
	for i in range(KINDS.size()):
		if KINDS[i] == "combat":
			combat_number += 1
		graph.append({"id": i, "layer": i, "kind": KINDS[i], "label": LABELS[i],
			"room_seed": (seed_value + combat_number * 1000003) & 0x7fffffffffffffff,
			"variant": random.randi_range(0, 1), "next": [i + 1] if i < KINDS.size() - 1 else []})
	return graph

static func validate(graph: Array[Dictionary]) -> PackedStringArray:
	var errors := PackedStringArray()
	if graph.is_empty():
		return PackedStringArray(["Graph kosong."])
	if graph.size() != KINDS.size():
		errors.append("Urutan stage harus memiliki 9 ruangan setelah lobby.")
	var reached := {0: true}
	var bosses := 0
	for i in range(graph.size()):
		var room: Dictionary = graph[i]
		if i < KINDS.size():
			if room.kind != KINDS[i] or room.get("label", "") != LABELS[i]:
				errors.append("Tipe/label tidak sesuai urutan stage: %d" % i)
			var expected: Array = [i + 1] if i < KINDS.size() - 1 else []
			if room.next != expected:
				errors.append("Pintu harus menuju ruangan berikutnya: %d" % i)
		if room.id != i:
			errors.append("ID node tidak sesuai indeks: %d" % i)
		if not reached.has(i):
			errors.append("Node tidak terjangkau: %d" % i)
		if room.kind == "boss":
			bosses += 1
			if not room.next.is_empty() or i != graph.size() - 1:
				errors.append("Boss harus menjadi terminal terakhir.")
		elif room.next.is_empty():
			errors.append("Dead end sebelum boss: %d" % i)
		if room.next.size() > 2:
			errors.append("Kapasitas pintu terlampaui: %d" % i)
		var seen := {}
		for target in room.next:
			if target <= i or target >= graph.size():
				errors.append("Edge tidak valid atau siklus: %d" % i)
				continue
			if seen.has(target) or graph[target].layer != room.layer + 1:
				errors.append("Edge duplikat atau melewati layer: %d" % i)
			seen[target] = true
			if reached.has(i):
				reached[target] = true
	if graph[0].kind != "start" or bosses != 1:
		errors.append("Diperlukan satu start di awal dan satu boss.")
	return errors

static func validate_template(scene: PackedScene, door_count: int) -> PackedStringArray:
	var errors := PackedStringArray()
	var room := scene.instantiate()
	if room.has_method("prepare") and not room.prepare(1):
		room.free()
		return PackedStringArray(["Generator template gagal."])
	for path in ["PlayerSpawn", "RewardSpawn", "DoorSpawns", "EnemySpawns"]:
		if not room.get_node_or_null(path) is Node2D:
			errors.append("Marker/grup wajib tidak ditemukan: " + path)
	var doors := room.get_node_or_null("DoorSpawns")
	if doors != null and doors.get_child_count() < door_count:
		errors.append("Jumlah marker pintu kurang.")
	# Contract for these flat-floor templates: all gameplay markers share a safe corridor.
	for marker in room.find_children("*", "Marker2D", true, false):
		if marker.name in ["Entry", "Exit"] and marker.get_parent() != room.get_node_or_null("DoorSpawns"):
			continue
		if room.has_meta("playable_bounds"):
			var point := relative_position(marker, room)
			var bounds: Rect2 = room.get_meta("playable_bounds")
			if not bounds.has_point(point):
				errors.append("Marker di luar batas room: " + str(marker.name))
			var supported := false
			var clearance := Rect2(point - Vector2(10, 16), Vector2(20, 32))
			for collider in room.find_children("*", "CollisionShape2D", true, false):
				if collider.disabled or not collider.shape is RectangleShape2D:
					continue
				var size: Vector2 = collider.shape.size
				var rect := Rect2(relative_position(collider, room) - size / 2, size)
				if clearance.intersects(rect):
					errors.append("Marker bertabrakan dengan platform: " + str(marker.name))
				if point.x >= rect.position.x + 10 and point.x <= rect.end.x - 10:
					var distance := rect.position.y - point.y
					if distance >= 16 and distance <= 48:
						supported = true
			if not supported:
				errors.append("Marker tidak memiliki lantai dekat: " + str(marker.name))
		elif marker.position.x < 40 or marker.position.x > 792 or marker.position.y != 350:
			errors.append("Marker di luar koridor aman: " + str(marker.name))
	room.free()
	return errors

static func relative_position(node: Node2D, root: Node) -> Vector2:
	var point := Vector2.ZERO
	var current: Node = node
	while current != root and current != null:
		if current is Node2D:
			point = current.transform * point
		current = current.get_parent()
	return point
