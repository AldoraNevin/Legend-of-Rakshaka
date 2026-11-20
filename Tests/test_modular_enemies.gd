extends SceneTree
const LEVEL = preload("res://Script/Stage/Modular/modular_level.gd")
const CATALOG = preload("res://Script/Stage/Modular/enemy_catalog.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var counts := {}
	var seen := {}
	for seed_value in [42, 123, 789]:
		var layout := LEVEL.generate_layout(seed_value)
		assert(not layout.has("error"), str(layout))
		assert(LEVEL.LAYOUT.validate(layout).is_empty())
		assert(layout.encounters == LEVEL.generate_layout(seed_value).encounters)
		assert(layout.enemies.size() == layout.encounters.size())
		for room in layout.rooms:
			var entries: Array = layout.encounters.filter(func(e): return e.room_id == room.id)
			if room.definition.id in ["tower", "short_tower"] or room.definition.enemies.is_empty():
				assert(entries.is_empty())
				continue
			assert(entries.size() in [mini(2, room.definition.enemies.size()), mini(3, room.definition.enemies.size())], room.definition.id)
			counts[entries.size()] = true
			var positions := {}
			for entry in entries:
				assert(entry.species == entries[0].species)
				assert(entry.species in CATALOG.SPECIES)
				assert(room.bounds.has_point(entry.position))
				assert(not positions.has(entry.position))
				positions[entry.position] = true
				seen[entry.species] = true
	assert(counts.size() == 2)
	assert(seen.size() > 1)
	for species in CATALOG.SPECIES:
		var enemy := CATALOG.create(species)
		enemy.position = Vector2(123, 144)
		root.add_child(enemy)
		enemy.set_physics_process(false)
		assert(enemy.home_x == 123)
		for clip in [&"Idle", &"Chase", &"AttackWindUp", &"AttackActive", &"AttackRecovery", &"Hit", &"Dead"]:
			assert(enemy.anim.has_animation(clip), species + str(clip))
			enemy.anim.play(clip)
			enemy.anim.advance(0)
		enemy.take_damage(enemy.max_health)
		enemy.anim.advance(10)
		await process_frame
		assert(not is_instance_valid(enemy), species + " must finish death")
	print("PASS: seeded 2-3 same-species enemies per room, empty towers, allowed pool, combat animations and death for all species.")
	quit()
